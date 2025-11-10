function clearWorkLog()
    % 清空工作日志
    fig = gcf;
    if ~ishandle(fig)
        return;
    end
    
    workLogText = getappdata(fig, 'workLogText');
    setappdata(fig, 'workLogData', {});
    if ishandle(workLogText)
        set(workLogText, 'String', {});
    end
    addWorkLog('工作日志已清空');
end
