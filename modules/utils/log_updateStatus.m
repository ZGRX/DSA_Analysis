function log_updateStatus(message)
    % LOG_UPDATESTATUS 更新系统状态日志
    % 该函数用于在控制台输出日志信息，替代可能丢失的GUI状态更新功能
    
    timestamp = datestr(now, 'HH:MM:SS');
    fprintf('[%s] %s\n', timestamp, message);
    
    % 尝试在主窗口的状态栏显示（如果有）
    % 这里只是一个简单的 fallback
end
