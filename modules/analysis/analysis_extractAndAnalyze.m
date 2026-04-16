function analysis_extractAndAnalyze(varargin)
    % 合并功能：提取TDC并立即分析曲线
    % 如果任一步骤失败，显示具体错误原因
    % 【修复】正确处理回调函数参数
    
    % 忽略 MATLAB 回调传递的 hObject 和 eventdata 参数
    % 回调格式: callback(hObject, eventdata)
    % 直接调用格式: callback() 或 callback(fig)
    
    fig = gcf;
    data = guidata(fig);
    
    % 步骤1：提取TDC
    try
        log_updateStatus('正在提取TDC数据...');
        analysis_extractTDC();
        
        % 等待提取完成并刷新数据
        drawnow;
        data = guidata(fig);
        
    catch ME
        utils_showMessage('TDC提取失败', 'error', sprintf('原因: %s\n位置: %s', ME.message, ME.stack(1).name));
        log_updateStatus('TDC提取失败');
        log_addWorkLog(sprintf('错误: TDC提取失败 - %s', ME.message));
        return;
    end
    
    % 检查提取是否成功
    if isempty(data.timeSeriesData)
        utils_showMessage('TDC提取未成功', 'error', '时间序列数据为空，无法继续分析');
        return;
    end
    
    % 步骤2：分析曲线
    try
        log_updateStatus('正在分析TDC曲线...');
        analysis_analyzeCurves();
        
    catch ME
        utils_showMessage('曲线分析失败', 'error', sprintf('原因: %s\n位置: %s', ME.message, ME.stack(1).name));
        log_updateStatus('曲线分析失败');
        log_addWorkLog(sprintf('错误: 曲线分析失败 - %s', ME.message));
        return;
    end
    
    % 全部成功（参数表已在 analysis_analyzeCurves 内部刷新）
    log_updateStatus('TDC提取与分析完成');
end
