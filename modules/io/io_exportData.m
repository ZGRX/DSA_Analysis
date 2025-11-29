function io_exportData(varargin)
    % 已迁移的 exportData 实现，前缀为 io_
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.timeSeriesData)
        errordlg('没有数据可导出', '错误');
        log_addWorkLog('错误: 尝试导出但无可用数据');
        return;
    end
    
    log_addWorkLog('开始数据导出流程');
    [file, path] = uiputfile({'*.mat', 'MAT文件 (*.mat)'; '*.xlsx', 'Excel文件 (*.xlsx)'; '*.csv', 'CSV文件 (*.csv)'}, '保存分析结果');
    if isequal(file, 0)
        log_updateStatus('导出取消');
        return;
    end
    
    try
        fullPath = fullfile(path, file);
        [~, ~, ext] = fileparts(file);
        data.analysisInfo.timestamp = datestr(now);
        data.analysisInfo.exportTime = datestr(now);
        data.analysisInfo.fileName = file;
        guidata(fig, data);
        
        switch lower(ext)
            case '.mat'
                save(fullPath, 'data');
                log_updateStatus(sprintf('成功导出MAT文件: %s', file));
            case {'.csv', '.xlsx'}
                paramTable = createParameterTable(data);
                if strcmpi(ext, '.csv')
                    writetable(paramTable, fullPath);
                else
                    writetable(paramTable, fullPath, 'Sheet', '灌注参数');
                    timeSeriesTable = createTimeSeriesTable(data);
                    writetable(timeSeriesTable, fullPath, 'Sheet', '时间序列');
                    infoTable = createAnalysisInfoTable(data);
                    writetable(infoTable, fullPath, 'Sheet', '分析信息');
                end
                log_updateStatus(sprintf('成功导出表格文件: %s', file));
        end
        
        choice = questdlg('数据导出成功！是否现在进行术前术后对比分析？', '继续分析', '是', '否', '是');
        if strcmp(choice, '是')
            analysis_comparePrePost([], []);
        else
            msgbox('分析数据保存成功！', '完成');
        end
        log_addWorkLog(sprintf('数据导出成功: %s', file));
    catch ME
        errordlg(sprintf('导出失败: %s', ME.message), '错误');
        log_updateStatus('导出失败');
        log_addWorkLog(sprintf('错误: 导出失败 - %s', ME.message));
    end
end

function paramTable = createParameterTable(data)
    paramNames = {'TMAX', 'MTT', 'TU', 'TD', 'halfTMAX', 'AUC', 'AUCbefore', 'AUCratio', 'MS', 'AFS', 'CBF'};
    lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    tableData = [];
    for lobe = 1:4
        params = data.perfusionParams(lobe);
        rowData = [params.TMAX, params.MTT, params.TU, params.TD, params.halfTMAX, params.AUC, params.AUCbefore, params.AUCratio, params.MS, params.AFS, params.CBF];
        tableData = [tableData; rowData]; %#ok<AGROW>
    end
    paramTable = array2table(tableData, 'RowNames', lobeNames, 'VariableNames', paramNames);
end

function timeSeriesTable = createTimeSeriesTable(data)
    [numROIs, numFrames] = size(data.timeSeriesData);
    time = (0:numFrames-1) / data.frameRate;
    variableNames = {'Time'};
    for roiIdx = 1:numROIs
        lobe = ceil(roiIdx / 3);
        r = mod(roiIdx-1, 3) + 1;
        variableNames{end+1} = sprintf('%s_%d', data.lobeNames{lobe}, r); %#ok<AGROW>
    end
    tableData = zeros(numFrames, numROIs + 1);
    tableData(:, 1) = time';
    tableData(:, 2:end) = data.timeSeriesData';
    timeSeriesTable = array2table(tableData, 'VariableNames', variableNames);
end

function infoTable = createAnalysisInfoTable(data)
    infoFields = {'分析时间', '文件名', '总帧数', '帧率', '软件版本'};
    infoValues = {data.analysisInfo.timestamp, data.fileName, data.totalFrames, data.frameRate, data.analysisInfo.softwareVersion};
    infoTable = table(infoFields', infoValues', 'VariableNames', {'参数', '值'});
end
