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
    stopPlayback(fig);
    return;
end

% 安全防御：若已被暂停但定时器回调仍在队列中，立即退出
isPlaying = getappdata(fig, 'isPlaying');
if isempty(isPlaying) || ~isPlaying
    return;
end

frameSlider = getappdata(fig, 'frameSlider');
currentFrameText = getappdata(fig, 'currentFrameText');

nextFrame = data.currentFrame + 1;

% 核心逻辑：到达最后一帧自动回绕到第一帧开始（实现连续滚动播放）
if nextFrame > data.totalFrames
    nextFrame = 1;
end

data.currentFrame = nextFrame;
guidata(fig, data);

if ishandle(frameSlider), set(frameSlider, 'Value', nextFrame); end
if ishandle(currentFrameText), set(currentFrameText, 'String', num2str(nextFrame)); end

% 显式传递句柄
updateFrameDisplay(fig);
end
