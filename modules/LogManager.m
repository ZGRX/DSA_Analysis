<<<<<<< HEAD
function LogManager()
    % 日志管理工具类 - 提供统一的状态和日志记录接口
end

function updateStatus(message)
    % 更新系统状态显示
    % 输入: message - 状态消息字符串
    
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
        addWorkLog(message);
    end
    drawnow;
end

function addWorkLog(message)
    % 添加工作日志
    % 输入: message - 日志消息字符串
    
    fig = gcf;
    if ~ishandle(fig)
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

function clearWorkLog()
    % 清空工作日志
    fig = gcf;
    workLogText = getappdata(fig, 'workLogText');
    setappdata(fig, 'workLogData', {});
    if ishandle(workLogText)
        set(workLogText, 'String', {});
    end
    addWorkLog('工作日志已清空');
end

function exportWorkLog()
    % 导出工作日志到文件
    fig = gcf;
    workLogData = getappdata(fig, 'workLogData');
    if isempty(workLogData)
        errordlg('工作日志为空，无法导出');
        return;
    end
    
    [file, path] = uiputfile({'*.txt','文本文件 (*.txt)'; ...
                             '*.log','日志文件 (*.log)'}, ...
                            '导出工作日志');
    if isequal(file, 0)
        return;
    end
    
    try
        fullPath = fullfile(path, file);
        fid = fopen(fullPath, 'w');
        if fid == -1
            error('无法创建文件');
        end
        
        fprintf(fid, 'DSA脑血流灌注分析系统 - 工作日志\n');
        fprintf(fid, '导出时间: %s\n', datestr(now));
        fprintf(fid, '========================================\n\n');
        
        for i = 1:length(workLogData)
            fprintf(fid, '%s\n', workLogData{i});
        end
        
        fclose(fid);
        addWorkLog(sprintf('工作日志已导出: %s', file));
        msgbox('工作日志导出成功！', '成功');
        
    catch ME
        errordlg(sprintf('导出失败: %s', ME.message));
    end
end
=======
function LogManager()
    % 日志管理工具类 - 提供统一的状态和日志记录接口
end

function updateStatus(message)
    % 更新系统状态显示
    % 输入: message - 状态消息字符串
    
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
        addWorkLog(message);
    end
    drawnow;
end

function addWorkLog(message)
    % 添加工作日志
    % 输入: message - 日志消息字符串
    
    fig = gcf;
    if ~ishandle(fig)
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

function clearWorkLog()
    % 清空工作日志
    fig = gcf;
    workLogText = getappdata(fig, 'workLogText');
    setappdata(fig, 'workLogData', {});
    if ishandle(workLogText)
        set(workLogText, 'String', {});
    end
    addWorkLog('工作日志已清空');
end

function exportWorkLog()
    % 导出工作日志到文件
    fig = gcf;
    workLogData = getappdata(fig, 'workLogData');
    if isempty(workLogData)
        errordlg('工作日志为空，无法导出');
        return;
    end
    
    [file, path] = uiputfile({'*.txt','文本文件 (*.txt)'; ...
                             '*.log','日志文件 (*.log)'}, ...
                            '导出工作日志');
    if isequal(file, 0)
        return;
    end
    
    try
        fullPath = fullfile(path, file);
        fid = fopen(fullPath, 'w');
        if fid == -1
            error('无法创建文件');
        end
        
        fprintf(fid, 'DSA脑血流灌注分析系统 - 工作日志\n');
        fprintf(fid, '导出时间: %s\n', datestr(now));
        fprintf(fid, '========================================\n\n');
        
        for i = 1:length(workLogData)
            fprintf(fid, '%s\n', workLogData{i});
        end
        
        fclose(fid);
        addWorkLog(sprintf('工作日志已导出: %s', file));
        msgbox('工作日志导出成功！', '成功');
        
    catch ME
        errordlg(sprintf('导出失败: %s', ME.message));
    end
end
>>>>>>> 4d5e5c9 (Initial commit)
