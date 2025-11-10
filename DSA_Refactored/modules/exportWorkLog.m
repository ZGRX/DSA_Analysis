function exportWorkLog()
    % 导出工作日志到文件
    fig = gcf;
    if ~ishandle(fig)
        return;
    end
    
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
