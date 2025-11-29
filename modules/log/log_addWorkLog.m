function log_addWorkLog(message)
    % log_addWorkLog - 内部日志实现（已迁移到 modules/log）
    fig = gcf;
    if ~ishandle(fig)
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
