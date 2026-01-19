%%将当前帧前进一帧（循环到第一帧），并更新滑块与界面显示
function advanceFrame()
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data) || (isempty(data.img4D) && isempty(data.processedSeries))
        stopPlayback();
        return;
    end
    
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    
    nextFrame = data.currentFrame + 1;
    if nextFrame > data.totalFrames
        nextFrame = 1;
    end
    data.currentFrame = nextFrame;
    guidata(fig, data);
    
    if ishandle(frameSlider), set(frameSlider, 'Value', nextFrame); end
    if ishandle(currentFrameText), set(currentFrameText, 'String', num2str(nextFrame)); end
    
    updateFrameDisplay();
end
