function updateFrameFromSlider(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data) || (isempty(data.img4D) && isempty(data.processedSeries))
        return;
    end
    
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    
    if ishandle(frameSlider)
        currentFrame = round(get(frameSlider, 'Value'));
        currentFrame = max(1, min(currentFrame, data.totalFrames));
        data.currentFrame = currentFrame;
        guidata(fig, data);
        
        if ishandle(currentFrameText)
            set(currentFrameText, 'String', num2str(currentFrame));
        end
    end
    
    updateFrameDisplay();
end
