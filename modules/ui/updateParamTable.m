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
        
        tableData{1, lobe+1} = sprintf('%.3f', params(lobe).TMAX);
        tableData{2, lobe+1} = sprintf('%.3f', params(lobe).MTT);
        tableData{3, lobe+1} = sprintf('%.3f', params(lobe).TU);
        tableData{4, lobe+1} = sprintf('%.3f', params(lobe).TD);
        tableData{5, lobe+1} = sprintf('%.3f', params(lobe).halfTMAX);
        tableData{6, lobe+1} = sprintf('%.1f', params(lobe).AUC);
        tableData{7, lobe+1} = sprintf('%.1f', params(lobe).AUCbefore);
        tableData{8, lobe+1} = sprintf('%.3f', params(lobe).AUCratio);
        tableData{9, lobe+1} = sprintf('%.3f', params(lobe).MS);
        tableData{10, lobe+1} = sprintf('%.3f', params(lobe).AFS);
        tableData{11, lobe+1} = sprintf('%.3f', params(lobe).CBF);
    end
    
    % 更新表格
    set(paramTable, 'Data', tableData);
end
