function addWorkLog(message)
    % 添加工作日志
    % 输入: message - 日志消息字符串
    
    fig = gcf;
    if ~ishandle(fig)
        % 如果没有图形窗口，输出到命令行
        fprintf('[LOG %s] %s\n', datestr(now, 'HH:MM:SS'), message);
        return;
    end
    
    workLogText = getappdata(fig, 'workLogText');
    workLogData = getappdata(fig, 'workLogData');
    
    if isempty(workLogData)
        workLogData = {};
    end
    
    timestamp = datestr(now, 'HH:MM:SS');
    logEntry = sprintf('[%s] %s', timestamp, message);
    workLogData = [workLogData; {logEntry}];
    
    % 限制日志条目数量
    if length(workLogData) > 100
        workLogData = workLogData(end-99:end);
    end
    
    setappdata(fig, 'workLogData', workLogData);
    
    if ishandle(workLogText)
        set(workLogText, 'String', workLogData);
        set(workLogText, 'Value', length(workLogData));
    end
    
    drawnow;
end
