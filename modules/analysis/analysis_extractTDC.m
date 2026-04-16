function analysis_extractTDC(varargin)
% 提取时间密度曲线(TDC) - 适配双端分析
fig = gcf; data = guidata(fig);
if isempty(data.roiMask) || size(data.roiMask, 3) ~= 2 || isempty(data.img4D)
    utils_showMessage('请先放置双端ROI并确保有多帧数据', 'error');
    log_addWorkLog('错误: 尝试提取TDC但ROI或数据不完整');
    return;
end
log_updateStatus('正在提取狭窄两端时间序列数据...');
log_addWorkLog('开始提取双端时间序列数据(TDC)');
try
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    if ishandle(frameRateEdit), frameRate = str2double(get(frameRateEdit, 'String')); else, frameRate = 4; end
    if isnan(frameRate) || frameRate <= 0, frameRate = 4; end
    totalFrames = data.totalFrames;
    if totalFrames < 2, error('图像帧数过少。'); end
    % 【向量化重构】消除双重 for 循环，大幅提升帧数较多时的性能
    % 将图像序列展平为 [totalFrames × Npix] 矩阵，一次性完成 ROI 均值提取
    hWait = waitbar(0, '正在准备图像数据矩阵...');
    % 必须使用经过背景去除的 processedSeries（包含纯造影剂正偏信号）
    % 将 [H, W, Frames] -> [Frames, H*W]
    imgFlat = double(reshape(permute(data.processedSeries, [3,1,2]), totalFrames, []));

    if ishandle(hWait), waitbar(0.3, hWait, '正在向量化提取双端ROI强度...'); end

    rawTransmissionData = zeros(2, totalFrames);
    for roiIdx = 1:2
        % 将 [H×W] 的 mask 展平，用列均值一次性计算所有帧
        maskFlat = data.roiMask(:,:,roiIdx);
        maskFlat = maskFlat(:)';                         % [1 × Npix]
        pixelCount = sum(maskFlat);
        if pixelCount == 0
            rawTransmissionData(roiIdx, :) = 0.1;
        else
            rawTransmissionData(roiIdx, :) = (imgFlat * maskFlat') / pixelCount; % [Frames×1]
        end
        if ishandle(hWait), waitbar(0.3 + roiIdx*0.15, hWait, sprintf('ROI %d/2 提取完成', roiIdx)); end
    end

    % 由于 processedSeries 已经是 (背景-当前帧) 的正差值，其幅度直接正比于造影剂浓度
    % 不需要再做对数转换，直接减去基线偏移以对齐 0 轴
    baselineEnd = min(5, max(1, floor(totalFrames * 0.1)));
    baselineOffsets = sum(rawTransmissionData(:, 1:baselineEnd), 2) / baselineEnd;
    
    densityData = bsxfun(@minus, rawTransmissionData, baselineOffsets);
    densityData = max(0, densityData); % 保证非负
    
    smoothedData = zeros(2, totalFrames);
    for i = 1:2, smoothedData(i, :) = movmean(densityData(i, :), 3); end
    data.timeSeriesData = smoothedData;
    data.frameRate = frameRate; data.startFrame = 1; data.endFrame = totalFrames;
    guidata(fig, data);
    startFrameEdit = getappdata(fig, 'startFrameEdit'); endFrameEdit = getappdata(fig, 'endFrameEdit');
    if ishandle(startFrameEdit), set(startFrameEdit, 'String', '1'); end
    if ishandle(endFrameEdit), set(endFrameEdit, 'String', num2str(totalFrames)); end
    if ishandle(hWait), close(hWait); end
    log_updateStatus(sprintf('双端TDC提取完成 (帧数: %d)', totalFrames));
    utils_showMessage('双端TDC提取完成', 'success');
catch ME
    if exist('hWait', 'var') && ishandle(hWait), close(hWait); end
    utils_showMessage('TDC提取失败', 'error', ME.message);
    log_addWorkLog(sprintf('TDC提取失败: %s', ME.message));
end
end
