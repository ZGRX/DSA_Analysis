function togglePlayback(src, ~)
if nargin > 0 && ishandle(src)
    fig = ancestor(src, 'figure');
else
    fig = gcbf;
    if isempty(fig), fig = gcf; end
end

data = guidata(fig);
if isempty(data) || (isempty(data.img4D) && isempty(data.processedSeries))
    return;
end

isPlaying = getappdata(fig, 'isPlaying');
if isempty(isPlaying), isPlaying = false; end % 安全防御

playBtn = getappdata(fig, 'playBtn');
pauseBtn = getappdata(fig, 'pauseBtn');

if isPlaying
    stopPlayback(fig);
    return;
end

% 开始播放逻辑
setappdata(fig, 'isPlaying', true);

% 按钮外观切换：播放变灰，暂停变亮
if ishandle(playBtn), set(playBtn, 'Enable', 'off', 'BackgroundColor', [0.6, 0.6, 0.6]); end
if ishandle(pauseBtn), set(pauseBtn, 'Enable', 'on', 'BackgroundColor', [0.8, 0.4, 0.2], 'String', '暂停'); end

% 播放时禁用所有手动导航控件（符合医疗影像操作规范：动时不调）
navBtns = {'firstFrameBtn', 'prevFrameBtn', 'nextFrameBtn', 'lastFrameBtn', 'frameSlider', 'startFrameEdit', 'endFrameEdit'};
for i = 1:length(navBtns)
    h = getappdata(fig, navBtns{i});
    if ishandle(h), set(h, 'Enable', 'off'); end
end

frameRateEdit = getappdata(fig, 'frameRateEdit');
frameRate = 4;
if ishandle(frameRateEdit)
    val = str2double(get(frameRateEdit, 'String'));
    if ~isnan(val) && val > 0
        frameRate = val;
    end
end

interval = 1 / frameRate;
timerObj = timer('ExecutionMode', 'fixedDelay', ...
    'Period', interval, ...
    'TimerFcn', @(~,~) advanceFrame(fig));
setappdata(fig, 'playTimer', timerObj);
start(timerObj);

log_updateStatus(sprintf('开始播放序列 (%.1f fps)', frameRate));
end
