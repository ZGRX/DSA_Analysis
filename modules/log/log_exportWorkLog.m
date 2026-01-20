function log_exportWorkLog()
    % 导出工作日志（已迁移到 modules/log）
    fig = gcf;
    if ~ishandle(fig)
        return;
    end

    workLogData = getappdata(fig, 'workLogData');
    if isempty(workLogData)
        utils_showMessage('工作日志为空，无法导出', 'error');
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
        log_addWorkLog(sprintf('工作日志已导出: %s', file));
        utils_showMessage('工作日志导出成功！', 'success');

    catch ME
        utils_showMessage('工作日志导出失败', 'error', ME.message);
    end
end
