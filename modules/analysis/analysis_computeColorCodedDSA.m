function analysis_computeColorCodedDSA(varargin)
% ANALYSIS_COMPUTECOLORCODEDDSA 生成彩色编码 DSA (CC-DSA)
%
% 算法严格按照文献实现，不使用 SVD 去卷积:
%   Strother CM, et al. "Parametric Color Coding of Digital Subtraction
%   Angiography." AJNR Am J Neuroradiol 31:919-24, May 2010.
%
% 渲染参数:
%   Hue        = TTP × (240/360)   → 红(早到达) ~ 蓝(延迟)
%   Saturation = 0.9 (常数)
%   Value      = I_max (归一化最大增强强度)

fig  = gcf;
data = guidata(fig);

if isempty(data.processedSeries)
    utils_showMessage('请先导入并处理DSA数据', 'error');
    return;
end

log_updateStatus('正在生成 CC-DSA (Strother 2010 算法)...');
log_addWorkLog('开始生成 CC-DSA 彩色编码图像');

try
    imgSeq = data.processedSeries;  % [H, W, nFrames]，减影后序列
    [H, W, nFrames] = size(imgSeq);
    imgSeq = double(imgSeq);

    % ── 获取帧率 ───────────────────────────────────────────────────────
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    if ishandle(frameRateEdit)
        frameRate = str2double(get(frameRateEdit, 'String'));
    else
        frameRate = 4;
    end
    if isnan(frameRate) || frameRate <= 0, frameRate = 4; end

    % CC-DSA直接使用原始帧（跳过运动配准：与参数图同理，动态造影干扰强度优化器）
    meanDisp = 0;

    % ── 步骤2：构建有效像素掩膜（排除准直器/边缘伪影）──────────────────
    % 左右各 6%、上下各 3% 切除（准直器、运动配准重灾区）
    borderX = round(W * 0.06);
    borderY = round(H * 0.03);
    edgeMask = true(H, W);
    edgeMask(:, 1:borderX)             = false;
    edgeMask(:, end-borderX+1:end)     = false;
    edgeMask(1:borderY, :)             = false;
    edgeMask(end-borderY+1:end, :)     = false;

    % ── 步骤3：生成血管掩膜（用于 Alpha 软混合背景）────────────────────
    mipImg  = max(imgSeq, [], 3);           % 时间维最大投影
    mipNorm = mat2gray(mipImg);
    mipSmooth = imgaussfilt(mipNorm, 2);

    thresh = graythresh(mipSmooth(edgeMask));
    vesselMask = imbinarize(mipSmooth, max(0.02, thresh * 0.45));
    vesselMask = vesselMask & edgeMask;
    vesselMask = imopen(vesselMask, strel('disk', 2));
    minArea    = round(H * W * 0.0005);
    vesselMask = bwareaopen(vesselMask, minArea);

    % 保留最多5个最大连通域，兜底避免碎片化
    try
        cc = bwconncomp(vesselMask);
        if cc.NumObjects > 0
            numPix  = cellfun(@numel, cc.PixelIdxList);
            [~, si] = sort(numPix, 'descend');
            keepN   = min(5, cc.NumObjects);
            cleanedMask = false(H, W);
            for k = 1:keepN
                cleanedMask(cc.PixelIdxList{si(k)}) = true;
            end
            vesselMask = cleanedMask;
        end
    catch
    end

    % 轻度膨胀，弥合断裂血管段
    vesselMask  = imdilate(vesselMask, strel('disk', 5));

    % ── 步骤4：调用文献算法渲染 CC-DSA ──────────────────────────────────
    %   Hue = TTP × 240/360  |  Saturation = 0.9  |  Value = I_max_norm
    log_updateStatus('正在按 Strother 2010 算法渲染 CC-DSA...');
    rgbImg = analysis_renderCCDSA(imgSeq, frameRate, edgeMask);

    % ── 步骤5：Alpha 软混合——血管区显色，背景深色 ───────────────────────
    vesselAlpha = imfilter(double(vesselMask), fspecial('gaussian', [15 15], 4));
    % 用 I_max（Value 通道，即 rgbImg 的亮度）进一步调制 Alpha
    valueChannel = max(rgbImg, [], 3);   % 近似亮度
    vesselAlpha  = vesselAlpha .* min(1, valueChannel * 2.5);

    bgRGB = [0.04, 0.04, 0.06];   % 深蓝黑背景
    for c = 1:3
        ch = rgbImg(:,:,c);
        ch = ch .* vesselAlpha + bgRGB(c) .* (1 - vesselAlpha);
        rgbImg(:,:,c) = ch;
    end

    % ── 步骤6：保存参数供导出使用 ───────────────────────────────────────
    % 重新计算并保存 TTP/I_max 参数图（供导出或进一步分析）
    [I_peak_map, peakIdx] = max(imgSeq, [], 3);
    I_mask_map = mean(imgSeq(:,:,1:max(1, round(nFrames*0.1))), 3);
    I_max_map  = max(0, I_peak_map - I_mask_map);
    TTP_map    = (double(peakIdx) - 1) / frameRate;

    data.ParamMaps.TTP   = TTP_map;
    data.ParamMaps.Imax  = I_max_map;
    data.ParamMaps.MIP   = mipImg;
    guidata(fig, data);

    % ── 步骤7：显示结果 ─────────────────────────────────────────────────
    screenSz = get(0, 'ScreenSize');
    figW = min(820, round(screenSz(3) * 0.55));
    figH = min(720, round(screenSz(4) * 0.70));
    figL = round((screenSz(3) - figW) / 2);
    figT = round((screenSz(4) - figH) / 2);

    resultFig = figure('Name', 'CC-DSA 彩色编码参数图', ...
        'NumberTitle', 'off', ...
        'Position', [figL, figT, figW, figH], ...
        'Color', [0.06, 0.06, 0.08], ...
        'MenuBar', 'figure', ...
        'ToolBar', 'figure');

    % 主图
    ax = axes('Parent', resultFig, 'Position', [0.07, 0.10, 0.78, 0.84]);
    imshow(rgbImg, 'Parent', ax);
    ax.Visible = 'on';

    title(ax, ...
        'CC-DSA  彩色编码数字减影血管造影', ...
        'Color', [0.92 0.92 0.92], 'FontSize', 12, ...
        'FontName', 'Microsoft YaHei', 'FontWeight', 'bold', 'Interpreter', 'none');

    % Colorbar  ── 仅表示 TTP 颜色区间（红=早到达，蓝=延迟）
    cMap = hsv(256);
    % 文献 Hue 范围：0→0.667，对应 HSV 色环 0°~240°，即红→黄→绿→蓝
    cMap = cMap(round(linspace(1, 171, 256)), :);   % 红(1) → 蓝(171)
    colormap(ax, cMap);

    prc_TTP = prctile(TTP_map(edgeMask), [2, 98]);
    cb = colorbar(ax, 'Location', 'eastoutside');
    caxis(ax, [prc_TTP(1), prc_TTP(2)]);
    cb.Label.String   = 'TTP (Time to Peak)  [s]';
    cb.Label.Color    = [0.88, 0.88, 0.88];
    cb.Color          = [0.88, 0.88, 0.88];
    cb.FontSize       = 10;
    nTick = 5;
    cb.Ticks          = linspace(prc_TTP(1), prc_TTP(2), nTick);
    cb.TickLabels     = arrayfun(@(v) sprintf('%.1fs', v), cb.Ticks, 'UniformOutput', false);

    % 图注（系统信息）
    annotation(resultFig, 'textbox', [0.07, 0.01, 0.85, 0.06], ...
        'String', sprintf('帧率: %.1f fps  |  帧数: %d  |  色彩编码: 色调=TTP · 亮度=Imax', frameRate, nFrames), ...
        'Color', [0.50 0.50 0.50], 'FontSize', 8, ...
        'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
        'Interpreter', 'none', 'FitBoxToText', 'off');

    % 保存图像供导出
    setappdata(fig, 'CCDSA_Image', rgbImg);

    log_updateStatus('CC-DSA 渲染完成 (Strother 2010)');
    log_addWorkLog(sprintf('CC-DSA 生成成功 | frameRate=%.1f fps | 帧数=%d | 有效像素=%.1f%%', ...
        frameRate, nFrames, 100*sum(edgeMask(:))/(H*W)));
    utils_showMessage('CC-DSA 彩色编码参数图已生成', 'success');

catch ME
    utils_showMessage('CC-DSA 计算失败', 'error', ME.message);
    log_updateStatus('CC-DSA 计算失败');
    log_addWorkLog(sprintf('CC-DSA 错误: %s (位置: %s 第%d行)', ...
        ME.message, ME.stack(1).name, ME.stack(1).line));
    disp(ME.getReport());
end
end
