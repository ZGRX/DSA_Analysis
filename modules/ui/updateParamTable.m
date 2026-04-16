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
        emptyData = cell(6, 5);
        emptyData(:,1) = {'TMAX 达峰(s)', 'MTT 平均(s)', 'TU 到达(s)', 'FWHM 展宽(s)', 'AUC 流量', 'Peak 峰宽'};
        set(paramTable, 'Data', emptyData);
        return;
    end
    
    % 准备表格数据 (双端: 近端 + 远端，3列)
    params = data.perfusionParams;
    paramNames = {'TMAX 达峰(s)', 'MTT 平均(s)', 'TU 到达(s)', 'FWHM 展宽(s)', 'AUC 流量', 'Peak 峰值'};

    tableData = cell(6, 3);
    tableData(:,1) = paramNames';

    % 第2列: 近端 (Proximal, index 1)
    % 第3列: 远端 (Distal,   index 2)
    for roi = 1:min(2, length(params))
        fmtV = @(v, f) formatSafeValue(v, f);
        tableData{1, roi+1} = fmtV(params(roi).TMAX, '%.3f');
        tableData{2, roi+1} = fmtV(params(roi).MTT,  '%.3f');
        tableData{3, roi+1} = fmtV(params(roi).TU,   '%.3f');
        if isfield(params(roi), 'FWHM')
            tableData{4, roi+1} = fmtV(params(roi).FWHM, '%.3f');
        else
            tableData{4, roi+1} = '-';
        end
        tableData{5, roi+1} = fmtV(params(roi).AUC, '%.1f');
        if isfield(params(roi), 'Peak')
            tableData{6, roi+1} = fmtV(params(roi).Peak, '%.1f');
        else
            tableData{6, roi+1} = '-';
        end
    end

    % 更新表格与强制结构同步
    set(paramTable, 'ColumnName', {'参数指标', '近端(Proximal)', '远端(Distal)'});
    set(paramTable, 'ColumnWidth', {110, 80, 80});
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
