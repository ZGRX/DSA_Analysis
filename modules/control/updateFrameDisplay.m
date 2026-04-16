function updateFrameDisplay(figHandle)
% 更新主图像显示区域
% 输入: figHandle (可选) - 目标窗口句柄，如果不提供则使用 gcf

if nargin > 0 && ishandle(figHandle)
    fig = figHandle;
else
    fig = gcf;
end

data = guidata(fig);
if isempty(data) || (isempty(data.img4D) && isempty(data.processedSeries))
    return;
end

currentFrame = data.currentFrame;

if ~isempty(data.processedSeries)
    currentImg = data.processedSeries(:,:,currentFrame);
elseif ~isempty(data.img4D)
    % 原始透射数据处理
    if ndims(data.img4D) == 4
        frameData = data.img4D(:,:,1,currentFrame);
    else
        frameData = data.img4D(:,:,currentFrame);
    end
    if isinteger(frameData), frameData = double(frameData); end
    currentImg = 255 - frameData;
else
    return;
end

% 确保图像是严格的2D平面（舍弃冗余的单维度），防止 imshow/imagesc 报错！
currentImg = squeeze(currentImg);

mainAxes = getappdata(fig, 'mainAxes');
if ishandle(mainAxes)
    hImg = findobj(mainAxes, 'Type', 'image');
    if isempty(hImg)
        imagesc(currentImg, 'Parent', mainAxes);
        colormap(mainAxes, gray);
        axis(mainAxes, 'image');
    else
        set(hImg, 'CData', currentImg);
    end
    
    % 防崩溃：安全设置对比度映射
    cMin = min(currentImg(:), [], 'omitnan');
    cMax = max(currentImg(:), [], 'omitnan');
    if isempty(cMin) || isnan(cMin) || cMin >= cMax
        caxis(mainAxes, 'auto');
    else
        caxis(mainAxes, [cMin, cMax]);
    end
    
    % 清理旧的图形标记（防止内存爆炸和闪烁）
    delete(findobj(mainAxes, 'Type', 'rectangle'));
    delete(findobj(mainAxes, 'Type', 'text'));
    
    if isfield(data, 'roiPositions') && ~isempty(data.roiPositions)
        hold on;
        for i = 1:size(data.roiPositions, 1)
            pos = data.roiPositions(i,:);
            % 新版双端分析或者兼容旧版
            if isfield(data, 'roiColors') && size(data.roiPositions, 1) <= 2
                color = data.roiColors(i,:);
                name = data.roiNames{i};
                rectangle('Position', pos, 'EdgeColor', color, 'LineWidth', 2);
                text(pos(1)+2, pos(2)-8, name, 'Color', color, 'FontWeight', 'bold', 'BackgroundColor', 'black', 'FontSize', 10);
            else
                % 旧版 4脑叶兼容 (12个ROI)
                lobe = ceil(i/3);
                % 安全防越界
                if lobe > size(data.colors, 1), lobe = size(data.colors, 1); end
                color = data.colors(lobe,:);
                rectangle('Position', pos, 'EdgeColor', color, 'LineWidth', 2);
                text(pos(1)+2, pos(2)-8, sprintf('%s-%d', data.lobeNames{lobe}, mod(i-1,3)+1), ...
                    'Color', color, 'FontWeight', 'bold', 'BackgroundColor', 'white', 'FontSize', 8);
            end
        end
        hold off;
    end
    
    title(mainAxes, sprintf('%s - 帧 %d/%d', data.fileName, currentFrame, data.totalFrames), 'Color', [0.2, 0.2, 0.2], 'Interpreter', 'none', 'FontName', 'Microsoft YaHei');
end

% 更新按钮使能状态 (仅在静止状态下根据边界逻辑更新)
isPlaying = getappdata(fig, 'isPlaying');
if isempty(isPlaying) || ~isPlaying
    totalFrames = data.totalFrames;
    firstBtn = getappdata(fig, 'firstFrameBtn');
    prevBtn = getappdata(fig, 'prevFrameBtn');
    nextBtn = getappdata(fig, 'nextFrameBtn');
    lastBtn = getappdata(fig, 'lastFrameBtn');
    slider = getappdata(fig, 'frameSlider');
    sEdit = getappdata(fig, 'startFrameEdit');
    eEdit = getappdata(fig, 'endFrameEdit');
    
    if totalFrames > 1
        % 恢复/更新导航按钮状态
        if currentFrame <= 1
            if ishandle(firstBtn), set(firstBtn, 'Enable', 'off', 'BackgroundColor', [0.7, 0.7, 0.7]); end
            if ishandle(prevBtn), set(prevBtn, 'Enable', 'off', 'BackgroundColor', [0.7, 0.7, 0.7]); end
        else
            if ishandle(firstBtn), set(firstBtn, 'Enable', 'on', 'BackgroundColor', [0.3, 0.65, 0.92]); end
            if ishandle(prevBtn), set(prevBtn, 'Enable', 'on', 'BackgroundColor', [0.3, 0.65, 0.92]); end
        end
        
        if currentFrame >= totalFrames
            if ishandle(nextBtn), set(nextBtn, 'Enable', 'off', 'BackgroundColor', [0.7, 0.7, 0.7]); end
            if ishandle(lastBtn), set(lastBtn, 'Enable', 'off', 'BackgroundColor', [0.7, 0.7, 0.7]); end
        else
            if ishandle(nextBtn), set(nextBtn, 'Enable', 'on', 'BackgroundColor', [0.3, 0.65, 0.92]); end
            if ishandle(lastBtn), set(lastBtn, 'Enable', 'on', 'BackgroundColor', [0.3, 0.65, 0.92]); end
        end
        
        % 恢复滑块与输入框
        if ishandle(slider), set(slider, 'Enable', 'on'); end
        if ishandle(sEdit), set(sEdit, 'Enable', 'on'); end
        if ishandle(eEdit), set(eEdit, 'Enable', 'on'); end
    end
end

% 始终更新进度条位置和文本
frameSlider = getappdata(fig, 'frameSlider');
if ishandle(frameSlider), set(frameSlider, 'Value', currentFrame); end

currentFrameText = getappdata(fig, 'currentFrameText');
if ishandle(currentFrameText), set(currentFrameText, 'String', num2str(currentFrame)); end
drawnow;
end
