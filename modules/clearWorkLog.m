<<<<<<< HEAD
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
=======
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
>>>>>>> 4d5e5c9 (Initial commit)
