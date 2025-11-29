function log_updateStatus(message)
    % 更新系统状态并在必要时记录到工作日志（已迁移到 modules/log）
    fig = gcf;
    resultsText = getappdata(fig, 'resultsText');
    if isempty(resultsText) || ~ishandle(resultsText)
        return;
    end

    currentText = get(resultsText, 'String');
    if ischar(currentText)
        currentText = {currentText};
    end

    timestamp = datestr(now, 'HH:MM:SS');
    newMessage = sprintf('[%s] %s', timestamp, message);
    newText = [currentText; {newMessage}];

    if length(newText) > 15
        newText = newText(end-14:end);
    end

    set(resultsText, 'String', newText);
    set(resultsText, 'Value', length(newText));

    % 同时记录到工作日志（重要操作）
    if contains(message, {'导入', '导出', '完成', '失败', '错误', '分析', '提取', '放置', '重置', '对比'})
        log_addWorkLog(message);
    end
    drawnow;
end
