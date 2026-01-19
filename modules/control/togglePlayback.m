function togglePlayback(~,~)
    fig = gcf;
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
        if ishandle(playBtn), set(playBtn, 'Enable', 'off', 'BackgroundColor', [0.5, 0.5, 0.5]); end
        if ishandle(pauseBtn), set(pauseBtn, 'Enable', 'on', 'BackgroundColor', [0.8, 0.6, 0.2]); end
        
        frameRateEdit = getappdata(fig, 'frameRateEdit');
        if ishandle(frameRateEdit)
            frameRate = str2double(get(frameRateEdit, 'String'));
        else
            frameRate = 4;
        end
        if isnan(frameRate) || frameRate <= 0
            frameRate = 4;
            if ishandle(frameRateEdit)
                set(frameRateEdit, 'String', '4');
            end
        end
        interval = 1 / frameRate;
        
        timerObj = timer('ExecutionMode', 'fixedRate', ...
                        'Period', interval, ...
                        'TimerFcn', @(~,~) advanceFrame());
        setappdata(fig, 'playTimer', timerObj);
        start(timerObj);
        
        log_updateStatus(sprintf('开始播放序列 (%.1f fps)', frameRate));
    end
end
