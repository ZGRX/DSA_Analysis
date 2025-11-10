function updateStatus(message)
    % 更新系统状态显示
    % 输入: message - 状态消息字符串
    
    fig = gcf;
    if ~ishandle(fig)
        return;
    end
    
    resultsText = getappdata(fig, 'resultsText');
    if isempty(resultsText) || ~ishandle(resultsText)
        % 如果没有resultsText，直接输出到命令行
        fprintf('[%s] %s\n', datestr(now, 'HH:MM:SS'), message);
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
        addWorkLog(message);
    end
    drawnow;
end
