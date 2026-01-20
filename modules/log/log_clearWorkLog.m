function log_clearWorkLog()
    % 清空工作日志（已迁移到 modules/log）
    fig = gcf;
    if ~ishandle(fig)
        return;
    end

    workLogText = getappdata(fig, 'workLogText');
    setappdata(fig, 'workLogData', {});
    if ishandle(workLogText)
        set(workLogText, 'String', {});
    end
    % 使用 wrapper 保持行为一致（外部接口仍为 addWorkLog）
    log_addWorkLog('工作日志已清空');
end
