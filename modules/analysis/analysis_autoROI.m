function analysis_autoROI(varargin)
% 自动ROI定位 — 基于TTP参数图的狭窄检测与双端ROI自动建议
% ════════════════════════════════════════════════════════════════════════
% 算法原理:
%   1. 读取已计算的TTP参数图（Parametric Map）
%   2. 在血管掩膜内寻找TTP最大梯度区域 → 狭窄位置
%   3. 在狭窄点沿向量方向自动外推 → 近端/远端ROI建议落点
%   4. 展示建议位置，用户一键确认或手动微调
%
% 临床依据:
%   狭窄处远端TTP显著高于近端（Yamauchi 2017），
%   TTP梯度最大点对应狭窄位置，可用于自动定位。
% ════════════════════════════════════════════════════════════════════════

fig = findobj('Type','figure','Tag','DSA_Main_Window');
if isempty(fig), fig = gcf; else, fig = fig(1); end
data = guidata(fig);

% ── 1. 检查参数图是否可用 ─────────────────────────────────────────────
if ~isfield(data,'ParamMaps') || isempty(data.ParamMaps.TTP)
    choice = questdlg('需要先计算全脑参数图，是否立即计算？', ...
        '自动ROI定位', '是', '否', '是');
    if strcmp(choice,'是')
        analysis_computeParametricMap();
        data = guidata(fig);
        if ~isfield(data,'ParamMaps') || isempty(data.ParamMaps.TTP)
            utils_showMessage('参数图计算失败', 'error'); return;
        end
    else
        return;
    end
end

log_updateStatus('正在进行自动狭窄定位...');

try
    TTP_map    = data.ParamMaps.TTP;
    AUC_map    = data.ParamMaps.AUC;
    vesselMask = data.ParamMaps.vesselMask;
    [H, W]     = size(TTP_map);

    % ── 2. 计算血管内TTP梯度图 ──────────────────────────────────────
    % 先平滑TTP图（减少噪声影响）
    TTP_smooth = imgaussfilt(TTP_map, 3);
    TTP_smooth(~vesselMask) = 0;

    % Sobel梯度
    [Gx, Gy]    = imgradientxy(TTP_smooth, 'sobel');
    gradMag     = sqrt(Gx.^2 + Gy.^2);
    gradMag(~vesselMask) = 0;

    % ── 3. 找到最大TTP梯度点 → 狭窄位置 ────────────────────────────
    % 只在血管高AUC区域（排除边缘噪声）
    AUC_norm     = (AUC_map - min(AUC_map(:))) / max(1e-6, max(AUC_map(:)) - min(AUC_map(:)));
    strictMask   = vesselMask & AUC_norm > prctile(AUC_norm(AUC_norm>0), 60);

    % 边缘排除（防止边框伪影）
    marginX = max(20, round(W*0.07));
    marginY = max(20, round(H*0.05));
    edgeMask = false(H, W);
    edgeMask(marginY:H-marginY, marginX:W-marginX) = true;
    strictMask = strictMask & edgeMask;

    gradMag_masked = gradMag;
    gradMag_masked(~strictMask) = NaN;

    [~, maxGradIdx] = max(gradMag_masked(:), [], 'omitnan');
    if isnan(maxGradIdx) || isempty(maxGradIdx)
        utils_showMessage('未能自动检测到明显狭窄位置，请手动放置ROI', 'warn');
        return;
    end

    [stenosisR, stenosisC] = ind2sub([H,W], maxGradIdx);

    % ── 4. 沿TTP梯度方向推算近端/远端ROI位置 ────────────────────────
    % 梯度方向 = 从低TTP (近端) 到 高TTP (远端)
    gx_at = Gx(stenosisR, stenosisC);
    gy_at = Gy(stenosisR, stenosisC);
    grad_norm = sqrt(gx_at^2 + gy_at^2);

    if grad_norm < 1e-6
        % 梯度方向不明确，改用TTP均值方向
        [~, minTTPIdx] = min(TTP_map(strictMask));
        gx_at = 0; gy_at = -1;  % 默认向下为近端方向
        grad_norm = 1;
    end

    % 单位向量：指向高TTP（远端）
    dx = gx_at / grad_norm;
    dy = gy_at / grad_norm;

    % ROI偏移距离（像素）：沿梯度方向移动约8%图像宽度
    roiOffset = round(min(H, W) * 0.10);

    % 近端ROI：梯度反方向（低TTP侧）
    proxR = round(stenosisR - dy * roiOffset);
    proxC = round(stenosisC - dx * roiOffset);

    % 远端ROI：梯度正方向（高TTP侧）
    distR = round(stenosisR + dy * roiOffset);
    distC = round(stenosisC + dx * roiOffset);

    % 边界检查
    proxR = max(marginY, min(H-marginY, proxR));
    proxC = max(marginX, min(W-marginX, proxC));
    distR = max(marginY, min(H-marginY, distR));
    distC = max(marginX, min(W-marginX, distC));

    % 验证近端确实TTP低于远端
    if TTP_map(proxR, proxC) > TTP_map(distR, distC)
        [proxR, proxC, distR, distC] = deal(distR, distC, proxR, proxC);
    end

    % ── 5. 显示定位结果并请求确认 ───────────────────────────────────
    screenSz = get(0, 'ScreenSize');
    figW = min(900, round(screenSz(3)*0.58));
    figH = min(700, round(screenSz(4)*0.72));
    figL = round((screenSz(3)-figW)/2);
    figT = round((screenSz(4)-figH)/2);

    roiFig = figure('Name','自动ROI定位建议 — 请确认或微调','NumberTitle','off',...
        'Position',[figL,figT,figW,figH],'Color',[0.1,0.1,0.15],'MenuBar','none');

    ax = axes('Parent',roiFig,'Position',[0.05,0.18,0.90,0.78]);

    % 显示TTP伪彩色图
    TTP_display = TTP_map; TTP_display(~vesselMask) = min(TTP_map(:));
    imagesc(ax, TTP_display, 'AlphaData', vesselMask);
    colormap(ax, jet); axis(ax,'image','off');
    cb = colorbar(ax,'Color','w');
    cb.Label.String = 'TTP 达峰时间 (s)'; cb.Label.Color = 'w';
    hold(ax,'on');

    % 标注狭窄点
    plot(ax, stenosisC, stenosisR, 'w+', 'MarkerSize',20, 'LineWidth',3);
    text(ax, stenosisC+8, stenosisR, '⚡狭窄位置', 'Color','w', 'FontSize',10,'FontWeight','bold');

    % 标注近端ROI
    roiSz = 20;
    rectangle(ax,'Position',[proxC-roiSz/2, proxR-roiSz/2, roiSz, roiSz],...
        'EdgeColor',[1,0.4,0.4],'LineWidth',3);
    text(ax, proxC+roiSz/2+3, proxR,'近端 (Proximal)','Color',[1,0.5,0.5],'FontSize',10,'FontWeight','bold');

    % 标注远端ROI
    rectangle(ax,'Position',[distC-roiSz/2, distR-roiSz/2, roiSz, roiSz],...
        'EdgeColor',[0.4,0.8,1],'LineWidth',3);
    text(ax, distC+roiSz/2+3, distR,'远端 (Distal)','Color',[0.5,0.85,1],'FontSize',10,'FontWeight','bold');

    % 绘制梯度方向箭头（狭窄走向）
    quiver(ax, stenosisC, stenosisR, dx*roiOffset*0.8, dy*roiOffset*0.8, ...
        'Color','y','LineWidth',2,'MaxHeadSize',0.5);

    title(ax,'自动狭窄定位 — TTP梯度法（Yamauchi 2017算法原理）',...
        'Color','w','FontSize',11,'FontWeight','bold');
    hold(ax,'off');

    % TTP值参考
    ttp_prox = TTP_map(proxR, proxC);
    ttp_dist = TTP_map(distR, distC);
    tts_est  = max(0, ttp_dist - ttp_prox);

    infoStr = sprintf('近端TTP=%.2fs  |  远端TTP=%.2fs  |  预估TTS=%.2fs', ...
        ttp_prox, ttp_dist, tts_est);
    uicontrol('Parent',roiFig,'Style','text','Units','normalized',...
        'Position',[0.05,0.12,0.90,0.05],'String',infoStr,...
        'ForegroundColor',[1,0.95,0.5],'BackgroundColor',[0.1,0.1,0.15],...
        'FontSize',10,'HorizontalAlignment','center');

    % ── 6. 操作按钮 ──────────────────────────────────────────────────
    uicontrol('Parent',roiFig,'Style','pushbutton','Units','normalized',...
        'Position',[0.08,0.02,0.38,0.08],...
        'String','✔  确认并应用此ROI位置','FontSize',11,'FontWeight','bold',...
        'BackgroundColor',[0.15,0.55,0.25],'ForegroundColor','w',...
        'Callback',@(~,~) applyAutoROI(fig, roiFig, proxR, proxC, distR, distC, roiSz));

    uicontrol('Parent',roiFig,'Style','pushbutton','Units','normalized',...
        'Position',[0.54,0.02,0.38,0.08],...
        'String','✕  关闭（手动放置）','FontSize',11,...
        'BackgroundColor',[0.40,0.15,0.15],'ForegroundColor','w',...
        'Callback',@(~,~) close(roiFig));

    log_updateStatus(sprintf('自动定位完成: 狭窄[%d,%d] | 近端TTP=%.2fs | 远端TTP=%.2fs', ...
        stenosisR, stenosisC, ttp_prox, ttp_dist));
    log_addWorkLog(sprintf('自动ROI: 狭窄(%d,%d) | 近端(%d,%d) | 远端(%d,%d) | 预估TTS=%.2fs', ...
        stenosisR,stenosisC, proxR,proxC, distR,distC, tts_est));

catch ME
    utils_showMessage('自动ROI定位失败', 'error', ME.message);
    log_addWorkLog(sprintf('自动ROI失败: %s', ME.message));
end
end

% ════════════════════════════════════════════════════════════════════════
function applyAutoROI(fig, roiFig, proxR, proxC, distR, distC, roiSz)
% 将自动定位结果写入主系统数据结构，触发后续分析
data = guidata(fig);

% 构建2个ROI掩膜
[H, W] = size(data.img2D);
mask1 = false(H, W); mask2 = false(H, W);
r1 = max(1,proxR-round(roiSz/2)):min(H,proxR+round(roiSz/2));
c1 = max(1,proxC-round(roiSz/2)):min(W,proxC+round(roiSz/2));
r2 = max(1,distR-round(roiSz/2)):min(H,distR+round(roiSz/2));
c2 = max(1,distC-round(roiSz/2)):min(W,distC+round(roiSz/2));
mask1(r1, c1) = true;
mask2(r2, c2) = true;

% 存储ROI位置
if ~isfield(data,'roiMasks'), data.roiMasks = {}; end
data.roiMasks{1} = mask1;
data.roiMasks{2} = mask2;
data.roiPositions = [proxR, proxC; distR, distC];
data.roiNames = {'近端 (Proximal)', '远端 (Distal)'};

% 在主图上显示ROI标记
mainAxes = getappdata(fig, 'mainAxes');
if ishandle(mainAxes)
    hold(mainAxes,'on');
    rectangle(mainAxes,'Position',[proxC-roiSz/2,proxR-roiSz/2,roiSz,roiSz],...
        'EdgeColor',[1,0.4,0.4],'LineWidth',2.5);
    rectangle(mainAxes,'Position',[distC-roiSz/2,distR-roiSz/2,roiSz,roiSz],...
        'EdgeColor',[0.4,0.8,1],'LineWidth',2.5);
    plot(mainAxes,proxC,proxR,'r+','MarkerSize',12,'LineWidth',2);
    plot(mainAxes,distC,distR,'c+','MarkerSize',12,'LineWidth',2);
    hold(mainAxes,'off');
end

guidata(fig, data);
close(roiFig);

utils_showMessage('自动ROI已应用！请继续点击【提取TDC】。', 'success');
log_updateStatus('自动ROI定位完成，可继续提取TDC');
log_addWorkLog('自动ROI已成功应用到主系统');
end
