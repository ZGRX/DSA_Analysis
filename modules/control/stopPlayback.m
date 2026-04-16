function stopPlayback(varargin)
% 停止播放并重置UI按钮状态
% 支持 (src, event) 这种回调调用，也支持 stopPlayback() 这种直接调用

if nargin > 0 && ~isempty(varargin{1}) && ishandle(varargin{1})
    if strcmp(get(varargin{1}, 'Type'), 'figure')
        fig = varargin{1};
    else
        fig = ancestor(varargin{1}, 'figure');
    end
else
    fig = gcbf;
    if isempty(fig), fig = gcf; end
end

% 获取 UI 句柄
playBtn = getappdata(fig, 'playBtn');
pauseBtn = getappdata(fig, 'pauseBtn');
timerObj = getappdata(fig, 'playTimer');

% 核心：停止并销毁定时器
if ~isempty(timerObj) && isvalid(timerObj)
    try
        stop(timerObj);
        delete(timerObj);
    catch
    end
end
setappdata(fig, 'playTimer', []);
setappdata(fig, 'isPlaying', false);

% 更新按钮外观
if ishandle(playBtn), set(playBtn, 'Enable', 'on', 'BackgroundColor', [0.35, 0.75, 0.45], 'String', '播放'); end
if ishandle(pauseBtn), set(pauseBtn, 'Enable', 'off', 'BackgroundColor', [0.6, 0.6, 0.6]); end

% 核心：触发一次 UI 刷新以恢复导航按钮的 Enable 状态 (边界逻辑)
updateFrameDisplay(fig);

log_updateStatus('停止播放序列');
end
