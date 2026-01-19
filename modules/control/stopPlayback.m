function stopPlayback(varargin)
% 停止播放并重置UI按钮状态
% 支持 (src, event) 这种回调调用，也支持 stopPlayback() 这种直接调用

if nargin > 0 && ishandle(varargin{1})
    fig = ancestor(varargin{1}, 'figure');
else
    fig = gcbf;
    if isempty(fig), fig = gcf; end
end

playBtn = getappdata(fig, 'playBtn');
pauseBtn = getappdata(fig, 'pauseBtn');
timerObj = getappdata(fig, 'playTimer');

if ~isempty(timerObj) && isvalid(timerObj)
    stop(timerObj);
    delete(timerObj);
end

setappdata(fig, 'isPlaying', false);
setappdata(fig, 'playTimer', []);

if ishandle(playBtn), set(playBtn, 'Enable', 'on', 'BackgroundColor', [0.35, 0.75, 0.45]); end
if ishandle(pauseBtn), set(pauseBtn, 'Enable', 'off', 'BackgroundColor', [0.6, 0.6, 0.6]); end

log_updateStatus('停止播放序列');
end
