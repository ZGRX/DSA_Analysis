function exportData(~, ~)
    % exportData - 导出分析数据
    %
    % 功能：
    %   1. 导出MAT文件（完整数据）
    %   2. 导出Excel文件（灌注参数表 + 时间序列 + 分析信息）
    %   3. 导出CSV文件（灌注参数表）
    %   4. 询问是否进行术前术后对比分析
    %
    % 输入：
    %   无（从guidata获取数据）
    %
    % 输出：
    %   无（保存文件）
    
    fig = gcf;
    data = guidata(fig);
    
    % 验证数据
    if isempty(data.timeSeriesData)
        errordlg('没有数据可导出', '错误');
        addWorkLog('错误: 尝试导出但无可用数据');
        return;
    end
    
    addWorkLog('开始数据导出流程');
    
    % 文件保存对话框
    [file, path] = uiputfile({'*.mat', 'MAT文件 (*.mat)'; ...
                             '*.xlsx', 'Excel文件 (*.xlsx)'; ...
                             '*.csv', 'CSV文件 (*.csv)'}, ...
                            '保存分析结果');
    if isequal(file, 0)
        updateStatus('导出取消');
        return;
    end
    
    try
        fullPath = fullfile(path, file);
        [~, ~, ext] = fileparts(file);
        
        % 更新分析信息
        data.analysisInfo.timestamp = datestr(now);
        data.analysisInfo.exportTime = datestr(now);
        data.analysisInfo.fileName = file;
        
        guidata(fig, data);
        
        % 根据文件扩展名导出
        switch lower(ext)
            case '.mat'
                % 导出完整MAT文件
                save(fullPath, 'data');
                updateStatus(sprintf('成功导出MAT文件: %s', file));
                
            case {'.csv', '.xlsx'}
                % 导出灌注参数表格
                paramTable = createParameterTable(data);
                
                if strcmpi(ext, '.csv')
                    % CSV只导出参数表
                    writetable(paramTable, fullPath);
                else
                    % Excel导出多个工作表
                    writetable(paramTable, fullPath, 'Sheet', '灌注参数');
                    
                    % 导出时间序列数据
                    timeSeriesTable = createTimeSeriesTable(data);
                    writetable(timeSeriesTable, fullPath, 'Sheet', '时间序列');
                    
                    % 导出分析信息
                    infoTable = createAnalysisInfoTable(data);
                    writetable(infoTable, fullPath, 'Sheet', '分析信息');
                end
                
                updateStatus(sprintf('成功导出表格文件: %s', file));
        end
        
        % 询问是否进行术前术后对比
        choice = questdlg('数据导出成功！是否现在进行术前术后对比分析？', ...
                         '继续分析', '是', '否', '是');
        
        if strcmp(choice, '是')
            comparePrePost([], []);
        else
            msgbox('分析数据保存成功！', '完成');
        end
        
        addWorkLog(sprintf('数据导出成功: %s', file));
        
    catch ME
        errordlg(sprintf('导出失败: %s', ME.message), '错误');
        updateStatus('导出失败');
        addWorkLog(sprintf('错误: 导出失败 - %s', ME.message));
    end
end

function paramTable = createParameterTable(data)
    % createParameterTable - 创建灌注参数表格
    %
    % 输入：
    %   data - 主数据结构
    %
    % 输出：
    %   paramTable - 参数表格（4行×11列）
    
    paramNames = {'TMAX', 'MTT', 'TU', 'TD', 'halfTMAX', ...
                 'AUC', 'AUCbefore', 'AUCratio', 'MS', 'AFS', 'CBF'};
    lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    
    tableData = [];
    
    for lobe = 1:4
        params = data.perfusionParams(lobe);
        rowData = [params.TMAX, params.MTT, params.TU, params.TD, params.halfTMAX, ...
                  params.AUC, params.AUCbefore, params.AUCratio, params.MS, params.AFS, params.CBF];
        tableData = [tableData; rowData]; %#ok<AGROW>
    end
    
    paramTable = array2table(tableData, 'RowNames', lobeNames, ...
                            'VariableNames', paramNames);
end

function timeSeriesTable = createTimeSeriesTable(data)
    % createTimeSeriesTable - 创建时间序列表格
    %
    % 输入：
    %   data - 主数据结构
    %
    % 输出：
    %   timeSeriesTable - 时间序列表格（N帧×13列：时间+12个ROI）
    
    [numROIs, numFrames] = size(data.timeSeriesData);
    time = (0:numFrames-1) / data.frameRate;
    
    % 创建列名
    variableNames = {'Time'};
    for roiIdx = 1:numROIs
        lobe = ceil(roiIdx / 3);
        r = mod(roiIdx-1, 3) + 1;
        variableNames{end+1} = sprintf('%s_%d', data.lobeNames{lobe}, r); %#ok<AGROW>
    end
    
    % 创建数据矩阵
    tableData = zeros(numFrames, numROIs + 1);
    tableData(:, 1) = time';
    tableData(:, 2:end) = data.timeSeriesData';
    
    timeSeriesTable = array2table(tableData, 'VariableNames', variableNames);
end

function infoTable = createAnalysisInfoTable(data)
    % createAnalysisInfoTable - 创建分析信息表格
    %
    % 输入：
    %   data - 主数据结构
    %
    % 输出：
    %   infoTable - 分析信息表格
    
    infoFields = {'分析时间', '文件名', '总帧数', '帧率', '软件版本'};
    infoValues = {data.analysisInfo.timestamp, data.fileName, ...
                 data.totalFrames, data.frameRate, data.analysisInfo.softwareVersion};
    
    infoTable = table(infoFields', infoValues', ...
                     'VariableNames', {'参数', '值'});
end
