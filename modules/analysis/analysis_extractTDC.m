function analysis_extractTDC(varargin)
% 提取时间密度曲线(TDC) - 已迁移到 modules/analysis
fig = gcf;
data = guidata(fig);

if isempty(data.roiMask) || isempty(data.img4D)
    utils_showMessage('请先放置ROI并确保有多帧数据', 'error');
    log_addWorkLog('错误: 尝试提取TDC但ROI或数据不完整');
    return;
end

log_updateStatus('正在提取时间序列数据...');
log_addWorkLog('开始提取时间序列数据(TDC)');

try
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    if ishandle(frameRateEdit)
        frameRate = str2double(get(frameRateEdit, 'String'));
    else
        frameRate = 4;
    end
    if isnan(frameRate) || frameRate <= 0, frameRate = 4; end
    
    totalFrames = data.totalFrames;
    if totalFrames < 2
        error('图像帧数过少（至少需要2帧）进行TDC分析。');
    end
    
    % 初始化原始强度数据容器
    rawIntensityData = zeros(12, totalFrames);
    
    hWait = waitbar(0, '正在提取ROI原始强度数据...');
    for roiIdx = 1:12
        lobe = ceil(roiIdx / 3);
        r = mod(roiIdx-1, 3) + 1;
        currentMask = data.roiMask(:, :, lobe, r);
        
        for frameIdx = 1:totalFrames
            if ~isempty(data.processedSeries)
                frameData = data.processedSeries(:,:,frameIdx);
            else
                if ndims(data.img4D) == 4
                    frameData = data.img4D(:,:,1,frameIdx);
                else
                    frameData = data.img4D(:,:,frameIdx);
                end
            end
            
            if isinteger(frameData), frameData = double(frameData); end
            
            roiPixels = frameData(currentMask);
            if isempty(roiPixels)
                rawIntensityData(roiIdx, frameIdx) = 0;
            else
                rawIntensityData(roiIdx, frameIdx) = mean(roiPixels(:));
            end
        end
        waitbar(roiIdx/12, hWait, sprintf('正在提取ROI %d/12...', roiIdx));
    end
    
    % --- 科学算法核心转换 ---
    % 1. 自动识别基线强度 (造影剂到达前的背景值)
    % 取前 5 帧或总帧数的 10%
    baselineEnd = min(5, max(1, floor(totalFrames * 0.1)));
    baselineIntensities = mean(rawIntensityData(:, 1:baselineEnd), 2);
    
    % 2. 应用对数密度转换 (Beer-Lambert Law: Density = k * ln(Io/I))
    % k 设为 100 左右以匹配显示动态范围
    densityData = zeros(12, totalFrames);
    for i = 1:12
        Io = max(0.1, baselineIntensities(i)); % 确保 Io 为正
        for j = 1:totalFrames
            It = max(0.1, rawIntensityData(i, j)); % 确保 It 为正
            densityData(i, j) = 100 * (log(Io) - log(It));
        end
    end
    
    % 3. 基线重置 (确保从 0 点附近开始)
    baselineMean = mean(densityData(:, 1:baselineEnd), 2);
    densityData = bsxfun(@minus, densityData, baselineMean);
    densityData(densityData < 0) = 0; % 密度不应为负
    
    % 4. 预处理平滑处理 (3点移动平均)
    smoothedData = zeros(12, totalFrames);
    for i = 1:12
        smoothedData(i, :) = movmean(densityData(i, :), 3);
    end
    
    % --- 保存结果 ---
    data.timeSeriesData = smoothedData;
    data.frameRate = frameRate;
    data.startFrame = 1;
    data.endFrame = totalFrames;
    guidata(fig, data);
    
    % 更新界面
    startFrameEdit = getappdata(fig, 'startFrameEdit');
    endFrameEdit = getappdata(fig, 'endFrameEdit');
    if ishandle(startFrameEdit), set(startFrameEdit, 'String', '1'); end
    if ishandle(endFrameEdit), set(endFrameEdit, 'String', num2str(totalFrames)); end
    
    if ishandle(hWait), close(hWait); end
    log_updateStatus(sprintf('TDC提取完成 (帧数: %d)', totalFrames));
    utils_showMessage('TDC提取完成', 'success');
    log_addWorkLog('时间序列数据提取完成：已应用 Beer-Lambert 对数转换与平滑滤波');
catch ME
    if exist('hWait', 'var') && ishandle(hWait), close(hWait); end
    utils_showMessage('TDC提取失败', 'error', ME.message);
    log_updateStatus('数据提取失败');
    log_addWorkLog(sprintf('TDC提取失败: %s', ME.message));
end
end
