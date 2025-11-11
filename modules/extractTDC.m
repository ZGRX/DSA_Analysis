function extractTDC(~,~)
    % 提取时间密度曲线(TDC)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.roiMask) || isempty(data.img4D)
        errordlg('请先放置ROI并确保有多帧数据');
        addWorkLog('错误: 尝试提取TDC但ROI或数据不完整');
        return;
    end
    
    updateStatus('正在提取时间序列数据...');
    addWorkLog('开始提取时间序列数据(TDC)');
    
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
                    currentFrame = 255 - frameData;
                end
                
                roiPixels = currentFrame(currentMask);
                timeSeriesData(roiIdx, frameIdx) = mean(roiPixels(:));
            end
            waitbar(roiIdx/12, hWait, sprintf('正在提取ROI %d/12...', roiIdx));
        end
        close(hWait);
        
        % 归一化处理
        for roiIdx = 1:12
            curve = timeSeriesData(roiIdx, :);
            curve = curve - min(curve);
            if max(curve) > 0
                curve = curve / max(curve) * 30;
            end
            curve = curve + 50;
            timeSeriesData(roiIdx, :) = curve;
        end

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
        
        updateStatus(sprintf('时间序列数据提取完成 (共%d帧, %.1f秒)', totalFrames, (totalFrames-1)/frameRate));
        
        % 显示简单的成功提示
        msgbox(sprintf('TDC提取成功！\n\n共提取12个ROI的时间密度曲线\n数据已归一化处理(基线=50, 范围0-30)\n总帧数: %d\n采样率: %.1f fps', ...
               totalFrames, frameRate), 'TDC提取成功', 'help');
        
        addWorkLog('时间序列数据提取完成');
        addWorkLog(sprintf('提取了 %d 个ROI的时间密度曲线', 12));
        addWorkLog(sprintf('数据归一化处理完成 (基线=50, 范围0-30)'));
        
    catch ME
        errordlg(sprintf('数据提取失败: %s', ME.message));
        updateStatus('数据提取失败');
        addWorkLog(sprintf('TDC提取失败: %s', ME.message));
    end
end
