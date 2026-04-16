function analysis_performOneDSim(varargin)
% [已废弃 DEPRECATED] 1D FFR 血流动力学仿真
%
% 废弃原因：
%   FFR（血流储备分数）的物理模型基于冠状动脉生理——冠脉自动调节能力有限，
%   跨狭窄压差可直接反映心肌缺血。
%
%   脑血管具有强大的自动调节机制（Cerebrovascular Autoregulation），
%   在轻度压力下降时可主动扩张血管代偿，因此简单的 1D Poiseuille 流体方程
%   无法反映脑血管真实的功能状态。
%
%   替代方案：使用【跨狭窄血流动力学评估】功能，
%   该模块基于 TTS（ΔCCT）和 Peak Attenuation 两个有文献支撑的指标。
%
% 参考文献：
%   - Yamauchi et al., J Neurosurg, 2017 (ΔCCT > 3.2s)
%   - Lai et al. (VBI ≥ 2.0)

msgbox({...
    '⚠️  此功能已废弃', ...
    '', ...
    '1D FFR 仿真使用冠脉生理模型，不适用于有自动调节机制的脑血管。', ...
    '', ...
    '请使用：【跨狭窄血流动力学评估 (TTS & Peak Attenuation)】', ...
    '该功能基于 Yamauchi 2017 和 Lai 等文献阈值，具有临床依据。'}, ...
    '功能已废弃', 'warn');
end


log_updateStatus('正在准备 1D 血流动力学仿真...');

% ========== 2. 生成血管掩膜 (自动，不依赖 CC-DSA) ==========
[numFrames, H, W] = size(dsaData);

% 2a. 计算 MIP (Maximum Intensity Projection)
mip = squeeze(max(dsaData, [], 1));  % [H x W]
mip = double(mip);

% 2b. 自适应阈值分割血管
mip_norm = (mip - min(mip(:))) / (max(mip(:)) - min(mip(:)) + eps);

% 使用 Otsu 或百分位数阈值
threshold = graythresh(mip_norm); % Otsu
vesselMask = mip_norm > max(threshold, 0.15); % 至少 15% 亮度

% 形态学清理
vesselMask = bwareaopen(vesselMask, 50);   % 去除小噪点
se = strel('disk', 1);
vesselMask = imclose(vesselMask, se);       % 填充小间隙

% ========== 3. 让用户选择血管段 ==========
% 显示 MIP 和掩膜叠加
hFig = figure('Name', '1D FFR 仿真 - 请选择血管段', ...
    'NumberTitle', 'off', ...
    'Position', [100, 100, 900, 700], ...
    'Color', 'k');

% 显示减影后的 MIP
imagesc(mip_norm);
colormap(gray);
axis image off;
hold on;

% 用半透明红色显示掩膜边界
boundary = bwperim(vesselMask);
redOverlay = cat(3, ones(H,W), zeros(H,W), zeros(H,W));
hOverlay = imshow(redOverlay);
set(hOverlay, 'AlphaData', boundary * 0.5);

title({'请依次点击：[1] 起点 (上游/近心端)  [2] 终点 (下游/远心端)'; ...
       '点应该在红色血管轮廓内'}, ...
    'Color', 'w', 'FontSize', 14);

% 交互输入
try
    [xPts, yPts] = ginput(2);
catch
    close(hFig);
    return;
end

startPt = round([xPts(1), yPts(1)]);
endPt   = round([xPts(2), yPts(2)]);

% 边界裁剪
startPt = max(1, min([W, H], startPt));
endPt   = max(1, min([W, H], endPt));

% 如果点不在掩膜内，找最近的掩膜点
if ~vesselMask(startPt(2), startPt(1))
    startPt = findNearestMaskPoint(vesselMask, startPt);
end
if ~vesselMask(endPt(2), endPt(1))
    endPt = findNearestMaskPoint(vesselMask, endPt);
end

% 显示选择的点
plot(startPt(1), startPt(2), 'go', 'MarkerSize', 15, 'LineWidth', 3);
plot(endPt(1), endPt(2), 'rs', 'MarkerSize', 15, 'LineWidth', 3);
text(startPt(1)+10, startPt(2), 'START', 'Color', 'g', 'FontSize', 12, 'FontWeight', 'bold');
text(endPt(1)+10, endPt(2), 'END', 'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
drawnow;

log_updateStatus('正在提取血管路径...');

% ========== 4. 提取 Geodesic 路径 ==========
try
    geoDist = bwdistgeodesic(vesselMask, startPt(1), startPt(2), 'quasi-euclidean');
    distToEnd = geoDist(endPt(2), endPt(1));

    if isinf(distToEnd) || isnan(distToEnd)
        errordlg('起点和终点之间没有连通路径！请重新选择。', '路径错误');
        close(hFig);
        return;
    end

    % 回溯路径 (Gradient Descent)
    pathPts = [endPt(1), endPt(2)];
    curr = endPt;
    maxIter = H * W; % 防止无限循环
    iter = 0;
    
    while norm(curr - startPt) > 1.5 && iter < maxIter
        iter = iter + 1;
        minD = inf;
        nextPt = curr;
        
        for di = -1:1
            for dj = -1:1
                if di==0 && dj==0, continue; end
                ny = curr(2) + di;
                nx = curr(1) + dj;
                if ny<1 || ny>H || nx<1 || nx>W, continue; end
                
                d = geoDist(ny, nx);
                if d < minD && ~isnan(d) && ~isinf(d)
                    minD = d;
                    nextPt = [nx, ny];
                end
            end
        end
        
        % 防止原地踏步
        if isequal(nextPt, curr), break; end
        
        pathPts = [pathPts; nextPt];
        curr = nextPt;
    end
    pathPts = flipud(pathPts); % 从起点到终点

catch ME
    errordlg(['路径提取失败: ' ME.message], '错误');
    close(hFig);
    return;
end

% 在图上画出路径
plot(pathPts(:,1), pathPts(:,2), 'c-', 'LineWidth', 2);
title(sprintf('路径已提取: %d 个采样点', size(pathPts,1)), 'Color', 'w', 'FontSize', 14);
drawnow;

log_updateStatus(sprintf('路径提取完成 (%d 点)，正在计算压力降...', size(pathPts,1)));

% ========== 5. 提取沿路径的直径 ==========
distMap = bwdist(~vesselMask);
pathLen = size(pathPts, 1);

if pathLen < 10
    errordlg(sprintf('路径点数太少 (%d)，无法进行有效仿真。\n请选取更长的血管段。', pathLen), '路径过短');
    return;
end

diameter_px = zeros(pathLen, 1);
arcLen_px = zeros(pathLen, 1);
cumLen = 0;

for k = 1:pathLen
    px = round(pathPts(k, 1));
    py = round(pathPts(k, 2));
    px = max(1, min(W, px));
    py = max(1, min(H, py));
    diameter_px(k) = distMap(py, px) * 2; % 直径 = 2 * 到边界的距离
    
    if k > 1
        stepLen = norm(pathPts(k,:) - pathPts(k-1,:));
        cumLen = cumLen + stepLen;
    end
    arcLen_px(k) = cumLen;
end

% 平滑直径 (去除像素锯齿)
smoothWindow = max(3, round(pathLen / 20));
diameter_px = movmean(diameter_px, smoothWindow);

% ========== 6. 像素转物理单位 ==========
% DSA 典型分辨率: 0.3 mm/pixel (可根据 DICOM 信息调整)
pixelSize_mm = 0.3;

diameter_mm = diameter_px * pixelSize_mm;   % mm
arcLen_mm = arcLen_px * pixelSize_mm;       % mm

% ========== 7. 计算压力降 ==========
[pressure, FFR] = analysis_computePressureDrop(diameter_mm, arcLen_mm);

% ========== 8. 可视化结果 ==========
close(hFig); % 关闭选择窗口

simFig = figure('Name', 'Non-invasive FFR Simulation Results', ...
    'NumberTitle', 'off', ...
    'Position', [150, 100, 900, 750], ...
    'Color', 'w');

% --- 子图 1: 血管直径 ---
ax1 = subplot(3, 1, 1);
area(arcLen_mm, diameter_mm, 'FaceColor', [0.7, 0.85, 1], 'EdgeColor', [0.2, 0.4, 0.8], 'LineWidth', 1.5);
title('Vessel Diameter Profile (血管直径剖面)');
ylabel('Diameter (mm)');
grid on;
set(ax1, 'FontSize', 11);

% 标注最窄处
[minD, minIdx] = min(diameter_mm);
hold on;
plot(arcLen_mm(minIdx), minD, 'rv', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
text(arcLen_mm(minIdx), minD + 0.2, sprintf('Min: %.1f mm', minD), ...
    'Color', 'r', 'FontSize', 10, 'FontWeight', 'bold');

% 标注狭窄率
maxD = max(diameter_mm);
stenosisRate = (1 - minD/maxD) * 100;
text(arcLen_mm(end)*0.7, maxD*0.9, sprintf('Stenosis: %.0f%%', stenosisRate), ...
    'Color', [0.8, 0, 0], 'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [1,1,0.8]);

% --- 子图 2: 压力曲线 ---
ax2 = subplot(3, 1, 2);
plot(arcLen_mm, pressure, 'k-', 'LineWidth', 2);
hold on;
plot(arcLen_mm(minIdx), pressure(minIdx), 'rv', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
title('Pressure Profile (压力剖面)');
ylabel('Pressure (mmHg)');
grid on;
set(ax2, 'FontSize', 11);

% 标注压力降
totalDrop = pressure(1) - pressure(end);
text(arcLen_mm(end)*0.5, mean(pressure), sprintf('\\DeltaP = %.1f mmHg', totalDrop), ...
    'Color', [0.8, 0, 0], 'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [1,1,0.8]);

% --- 子图 3: FFR ---
ax3 = subplot(3, 1, 3);
plot(arcLen_mm, FFR, 'r-', 'LineWidth', 2.5);
hold on;
yline(0.80, 'g--', 'LineWidth', 2);
yline(0.75, 'm:', 'LineWidth', 1.5);

% 填充缺血区域
fill([arcLen_mm(1), arcLen_mm(end), arcLen_mm(end), arcLen_mm(1)], ...
     [0, 0, 0.80, 0.80], 'r', 'FaceAlpha', 0.08, 'EdgeColor', 'none');

ffrValue = FFR(end);
if ffrValue >= 0.80
    ffrColor = [0, 0.6, 0]; % 绿色 = 正常
    ffrText = 'Normal (正常)';
elseif ffrValue >= 0.75
    ffrColor = [0.9, 0.6, 0]; % 橙色 = 边界
    ffrText = 'Borderline (边界)';
else
    ffrColor = [0.8, 0, 0]; % 红色 = 缺血
    ffrText = 'Ischemia (缺血)';
end

title(sprintf('FFR = %.3f  —  %s', ffrValue, ffrText), ...
    'Color', ffrColor, 'FontSize', 14, 'FontWeight', 'bold');
ylabel('FFR');
xlabel('Distance along vessel (mm)');
grid on;
set(ax3, 'FontSize', 11);
ylim([min(0.5, ffrValue-0.1), 1.05]);

% 图例
legend({'FFR', 'Ischemia (< 0.80)', 'Severe (< 0.75)'}, 'Location', 'southwest');

% 总标题
sgtitle(sprintf('1D Hemodynamic Simulation | Stenosis %.0f%% | \\DeltaP = %.1f mmHg | FFR = %.3f', ...
    stenosisRate, totalDrop, ffrValue), 'FontSize', 13, 'FontWeight', 'bold');

linkaxes([ax1, ax2, ax3], 'x');

log_updateStatus(sprintf('仿真完成: 狭窄 %.0f%%, FFR=%.3f, ΔP=%.1f mmHg', stenosisRate, ffrValue, totalDrop));
log_addWorkLog(sprintf('完成 1D 仿真: 狭窄率=%.0f%%, FFR=%.3f', stenosisRate, ffrValue));

end

% ========== 辅助函数: 找最近的掩膜点 ==========
function nearPt = findNearestMaskPoint(mask, pt)
    [yy, xx] = find(mask);
    dists = (xx - pt(1)).^2 + (yy - pt(2)).^2;
    [~, minIdx] = min(dists);
    nearPt = [xx(minIdx), yy(minIdx)];
end
