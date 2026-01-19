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
    if isnan(frameRate) || frameRate <= 0
        frameRate = 4;
        if ishandle(frameRateEdit)
            set(frameRateEdit, 'String', '4');
        end
    end
    
    totalFrames = data.totalFrames;
    timeSeriesData = zeros(12, totalFrames);
    hWait = waitbar(0, '正在提取ROI时间序列数据...');
    for roiIdx = 1:12
        lobe = ceil(roiIdx / 3);
        r = mod(roiIdx-1, 3) + 1;
        currentMask = data.roiMask(:, :, lobe, r);
        for frameIdx = 1:totalFrames
            if ~isempty(data.processedSeries)
                currentFrame = data.processedSeries(:,:,frameIdx);
            else
                if ndims(data.img4D) == 4
                    frameData = data.img4D(:,:,1,frameIdx);
                else
                    frameData = data.img4D(:,:,frameIdx);
                end
                if isinteger(frameData)
                    frameData = double(frameData);
                end
                
                % 检查并归一化16位数据
                maxFrameVal = max(frameData(:));
                if maxFrameVal > 255
                    if maxFrameVal > 0
                        frameData = frameData / maxFrameVal * 255;
                    end
                end
                
                currentFrame = 255 - frameData;
            end
            roiPixels = currentFrame(currentMask);
            timeSeriesData(roiIdx, frameIdx) = mean(roiPixels(:));
        end
        waitbar(roiIdx/12, hWait, sprintf('正在提取ROI %d/12...', roiIdx));
    end
    close(hWait);
    
    % 移除之前的人工归一化 (lines 66-74)，保留真实的相对密度变化
    % 这对于比较不同脑叶的灌注差异至关重要
    data.timeSeriesData = timeSeriesData;
    
    data.timeSeriesData = timeSeriesData;
    data.frameRate = frameRate;
    data.startFrame = 1;
    data.endFrame = totalFrames;
    guidata(fig, data);
    
    startFrameEdit = getappdata(fig, 'startFrameEdit');
    endFrameEdit = getappdata(fig, 'endFrameEdit');
    if ishandle(startFrameEdit)
        set(startFrameEdit, 'String', '1');
    end
    if ishandle(endFrameEdit)
        set(endFrameEdit, 'String', num2str(totalFrames));
    end
    
    log_updateStatus(sprintf('时间序列数据提取完成 (共%d帧, %.1f秒)', totalFrames, (totalFrames-1)/frameRate));
    utils_showMessage(sprintf('TDC提取完成 (%d帧)', totalFrames), 'success');
    log_addWorkLog('时间序列数据提取完成');
    log_addWorkLog(sprintf('提取了 %d 个ROI的时间密度曲线', 12));
    log_addWorkLog(sprintf('数据归一化处理完成 (基线=50, 范围0-30)'));
catch ME
    utils_showMessage('TDC提取失败', 'error', ME.message);
    log_updateStatus('数据提取失败');
    log_addWorkLog(sprintf('TDC提取失败: %s', ME.message));
end
end
