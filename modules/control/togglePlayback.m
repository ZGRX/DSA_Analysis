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
playBtn = getappdata(fig, 'playBtn');
pauseBtn = getappdata(fig, 'pauseBtn');

if isPlaying
    stopPlayback();
else
    setappdata(fig, 'isPlaying', true);
    if ishandle(playBtn), set(playBtn, 'Enable', 'off', 'BackgroundColor', [0.6, 0.6, 0.6]); end
    if ishandle(pauseBtn), set(pauseBtn, 'Enable', 'on', 'BackgroundColor', [0.8, 0.6, 0.2]); end
    
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    frameRate = 4;
    if ishandle(frameRateEdit)
        val = str2double(get(frameRateEdit, 'String'));
        if ~isnan(val) && val > 0
            frameRate = val;
        end
    end
    
    interval = 1 / frameRate;
    timerObj = timer('ExecutionMode', 'fixedRate', ...
        'Period', interval, ...
        'TimerFcn', @(~,~) advanceFrame(fig));
    setappdata(fig, 'playTimer', timerObj);
    start(timerObj);
    
    log_updateStatus(sprintf('开始播放序列 (%.1f fps)', frameRate));
end
end
