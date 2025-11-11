function updateParamTable()
    % updateParamTable - 更新灌注参数表格显示
    %
    % 功能：
    %   在创建信息区域的参数表格中显示计算得到的灌注参数
    %
    % 输入：
    %   无（从appdata获取表格句柄，从guidata获取数据）
    %
    % 输出：
    %   无（更新UI表格）
    
    paramTable = getappdata(gcf, 'paramTable');
    data = guidata(gcf);
    
    % 验证表格句柄
    if isempty(paramTable) || ~ishandle(paramTable)
        return;
    end
    
    % 参数名称和脑叶名称
    paramNames = {'TMAX (s)', 'MTT (s)', 'TU (s)', 'TD (s)', 'AUC'};
    lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    
    % 检查是否有灌注参数数据
    if ~isfield(data, 'perfusionParams') || isempty(data.perfusionParams)
        % 如果没有数据，显示占位符
        tableData = cell(length(paramNames), length(lobeNames));
        for i = 1:length(paramNames)
            for j = 1:length(lobeNames)
                tableData{i, j} = '--';
            end
        end
        
        set(paramTable, 'Data', tableData);
        set(paramTable, 'ColumnName', lobeNames);
        set(paramTable, 'RowName', paramNames);
        set(paramTable, 'ColumnWidth', {40, 35, 35, 35});
        set(paramTable, 'ColumnEditable', false);
        return;
    end
    
    % 如果有数据，填充参数值
    tableData = cell(length(paramNames), length(lobeNames));
    
    for i = 1:length(paramNames)
        for j = 1:length(lobeNames)
            switch i
                case 1
                    tableData{i, j} = sprintf('%.3f', data.perfusionParams(j).TMAX);
                case 2
                    tableData{i, j} = sprintf('%.3f', data.perfusionParams(j).MTT);
                case 3
                    tableData{i, j} = sprintf('%.3f', data.perfusionParams(j).TU);
                case 4
                    tableData{i, j} = sprintf('%.3f', data.perfusionParams(j).TD);
                case 5
                    tableData{i, j} = sprintf('%.1f', data.perfusionParams(j).AUC);
            end
        end
    end
    
    set(paramTable, 'Data', tableData);
    set(paramTable, 'ColumnName', lobeNames);
    set(paramTable, 'RowName', paramNames);
    set(paramTable, 'ColumnWidth', {40, 35, 35, 35});
    set(paramTable, 'ColumnEditable', false);
end
