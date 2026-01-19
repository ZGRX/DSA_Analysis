function updateFrameDisplay()
fig = gcf;
data = guidata(fig);
if isempty(data) || (isempty(data.img4D) && isempty(data.processedSeries))
    return;
end

currentFrame = data.currentFrame;

if ~isempty(data.processedSeries)
    currentImg = data.processedSeries(:,:,currentFrame);
elseif ~isempty(data.img4D)
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

mainAxes = getappdata(fig, 'mainAxes');
if ishandle(mainAxes)
    axes(mainAxes);
    imagesc(currentImg);
    colormap(gray);
    axis image;
    caxis([min(currentImg(:)) max(currentImg(:))]);
    
    if isfield(data, 'roiPositions') && ~isempty(data.roiPositions)
        hold on;
        for i = 1:size(data.roiPositions, 1)
            pos = data.roiPositions(i,:);
            lobe = ceil(i/3);
            color = data.colors(lobe,:);
            rectangle('Position', pos, 'EdgeColor', color, 'LineWidth', 2);
            text(pos(1)+2, pos(2)-8, sprintf('%s-%d', data.lobeNames{lobe}, mod(i-1,3)+1), ...
                'Color', color, 'FontWeight', 'bold', 'BackgroundColor', 'white', 'FontSize', 8);
        end
        hold off;
    end
    
    title(sprintf('%s - 帧 %d/%d', data.fileName, currentFrame, data.totalFrames), 'Color', [0.2, 0.2, 0.2], 'Interpreter', 'none', 'FontName', 'Microsoft YaHei');
end

currentFrameText = getappdata(fig, 'currentFrameText');
if ishandle(currentFrameText), set(currentFrameText, 'String', num2str(currentFrame)); end
drawnow;
end
