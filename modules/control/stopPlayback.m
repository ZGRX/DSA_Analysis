function stopPlayback(~,~)
    fig = gcf;
    playBtn = getappdata(fig, 'playBtn');
    pauseBtn = getappdata(fig, 'pauseBtn');
    timerObj = getappdata(fig, 'playTimer');
    
    if ~isempty(timerObj) && isvalid(timerObj)
        stop(timerObj);
        delete(timerObj);
    end
    
    setappdata(fig, 'isPlaying', false);
    setappdata(fig, 'playTimer', []);
    
    if ishandle(playBtn), set(playBtn, 'Enable', 'on', 'BackgroundColor', [0.2, 0.7, 0.2]); end
    if ishandle(pauseBtn), set(pauseBtn, 'Enable', 'off', 'BackgroundColor', [0.5, 0.5, 0.5]); end
    
    log_updateStatus('停止播放序列');
end
