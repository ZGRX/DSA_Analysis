function updateParamTable()
    % 更新主界面右侧的灌注参数表格
    fig = gcf;
    data = guidata(fig);
    
    % 获取参数表格句柄
    paramTable = getappdata(fig, 'paramTable');
    if ~ishandle(paramTable)
        return;
    end
    
    % 检查是否有灌注参数数据
    if isempty(data) || ~isfield(data, 'perfusionParams') || isempty(data.perfusionParams)
        % 显示空表格
        emptyData = cell(11, 5);
        emptyData(:,1) = {'TMAX (s)', 'MTT (s)', 'TU (s)', 'TD (s)', '1/2TMAX (s)', ...
                         'AUC', 'AUCbefore', 'AUCbefore/AUC', 'MS (SI/s)', 'AFS (SI/s)', 'CBF (SI)'};
        set(paramTable, 'Data', emptyData);
        return;
    end
    
    % 准备表格数据
    params = data.perfusionParams;
    paramNames = {'TMAX (s)', 'MTT (s)', 'TU (s)', 'TD (s)', '1/2TMAX (s)', ...
                  'AUC', 'AUCbefore', 'AUCbefore/AUC', 'MS (SI/s)', 'AFS (SI/s)', 'CBF (SI)'};
    
    tableData = cell(11, 5);
    
    % 第一列是参数名称
    tableData(:,1) = paramNames';
    
    % 填充四个脑叶的数据
    for lobe = 1:4
        if lobe > length(params)
            continue;
        end
        
        % 辅助函数：安全格式化数值，避免 Inf/NaN 显示
        formatValue = @(val, fmt) formatSafeValue(val, fmt);
        
        tableData{1, lobe+1} = formatValue(params(lobe).TMAX, '%.3f');
        tableData{2, lobe+1} = formatValue(params(lobe).MTT, '%.3f');
        tableData{3, lobe+1} = formatValue(params(lobe).TU, '%.3f');
        tableData{4, lobe+1} = formatValue(params(lobe).TD, '%.3f');
        tableData{5, lobe+1} = formatValue(params(lobe).halfTMAX, '%.3f');
        tableData{6, lobe+1} = formatValue(params(lobe).AUC, '%.1f');
        tableData{7, lobe+1} = formatValue(params(lobe).AUCbefore, '%.1f');
        tableData{8, lobe+1} = formatValue(params(lobe).AUCratio, '%.3f');
        tableData{9, lobe+1} = formatValue(params(lobe).MS, '%.3f');
        tableData{10, lobe+1} = formatValue(params(lobe).AFS, '%.3f');
        tableData{11, lobe+1} = formatValue(params(lobe).CBF, '%.3f');
    end
    
    % 更新表格
    set(paramTable, 'Data', tableData);
end

function str = formatSafeValue(value, format)
    % 安全格式化数值，处理 Inf、-Inf、NaN
    if isnan(value)
        str = 'N/A';
    elseif isinf(value)
        if value > 0
            str = '+Inf';
        else
            str = '-Inf';
        end
    else
        str = sprintf(format, value);
    end
end
