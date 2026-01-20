function advanceFrame(figHandle)
% 将当前帧前进一帧，并更新界面
% 输入: figHandle (可选) - 目标窗口句柄

if nargin > 0 && ishandle(figHandle)
    fig = figHandle;
else
    fig = gcf;
end

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
