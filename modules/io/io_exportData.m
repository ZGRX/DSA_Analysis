function io_exportData(varargin)
% 增强型数据导出：支持从主界面或文件管理器触发，并自动定位路径
% 输入: 可选传入 targetFig 句柄

% 【修复】用 Tag 定位主窗口，避免标题字符串随版本号变动导致失效
mainFig = findobj('Type', 'figure', 'Tag', 'DSA_Main_Window');
if isempty(mainFig)
    fig = gcf;
else
    fig = mainFig(1);
end

data = guidata(fig);
if isempty(data) || ~isfield(data, 'timeSeriesData') || isempty(data.timeSeriesData)
    utils_showMessage('当前主界面暂无分析数据可导出。请先完成 ROI 放置与 TDC 提取。', 'warn');
    return;
end

% 获取患者信息，确定保存路径
dataContainer = getappdata(fig, 'dataContainer');
if ~isempty(dataContainer) && isfield(dataContainer, 'patientInfo')
    patientID = dataContainer.patientInfo.id;
    patientName = dataContainer.patientInfo.name;
else
    patientID = 'Unknown';
    patientName = '未知';
end

% 【修复】使用统一的路径管理函数
[resultsDir, dataDir, reportsDir] = utils_getPatientDir(patientID);

% 生成默认文件名（带时间戳）
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
defaultName = sprintf('Analysis_%s.xlsx', timestamp);

% 默认建议保存到 Reports
log_addWorkLog('开始数据导出流程');
[file, path] = uiputfile({'*.xlsx', 'Excel文件 (*.xlsx)'; '*.mat', 'MAT文件 (*.mat)'; '*.csv', 'CSV文件 (*.csv)'}, ...
    '保存分析结果', fullfile(reportsDir, defaultName));
if isequal(file, 0)
    log_updateStatus('导出取消');
    return;
end

try
    fullPath = fullfile(path, file);
    [~, baseName, ext] = fileparts(file);
    data.analysisInfo.timestamp = datestr(now);
    data.analysisInfo.exportTime = datestr(now);
    data.analysisInfo.fileName = file;
    guidata(fig, data);
    
    switch lower(ext)
        case '.mat'
            save(fullPath, 'data');
            log_updateStatus(sprintf('成功导出数据: %s', file));
        case {'.csv', '.xlsx'}
            % 1. 导出主报告 (Excel/CSV)
            log_updateStatus('正在生成汇总报表...');
            paramTable = createParameterTable(data);
            
            if strcmpi(ext, '.csv')
                writetable(paramTable, fullPath);
            else
                % 【性能优化】Excel 只记录摘要参数和分析信息
                % 避免写入巨大的“时间序列”表，那是导致 Excel 导出极慢的主因
                log_updateStatus('正在写入 Excel (汇总参数)...');
                writetable(paramTable, fullPath, 'Sheet', '灌注参数总结');
                
                infoTable = createAnalysisInfoTable(data);
                writetable(infoTable, fullPath, 'Sheet', '分析基本信息');
                
                % 【核心改进】如果用户需要原始曲线数据，将其导出为同名的 .csv (极速)
                [dPath, dName, ~] = fileparts(fullPath);
                seriesCsvPath = fullfile(dPath, [dName, '_原始曲线数据.csv']);
                log_updateStatus('正在导出原始曲线 (CSV 极速模式)...');
                timeSeriesTable = createTimeSeriesTable(data);
                writetable(timeSeriesTable, seriesCsvPath);
            end
            
            % 2. 【核心优化】自动同步导出 .mat 科学数据到 Data 目录
            % 【修复】使用正确的 dataDir 路径和变量名
            matFilePath = fullfile(dataDir, [baseName, '.mat']);
            log_updateStatus('正在同步科学数据 (.mat)...');
            save(matFilePath, 'data');
            
            log_updateStatus(sprintf('报告导出完成。汇总见 Excel，原始曲线见同名 CSV。'));
    end
    utils_showMessage('分析数据导出成功！', 'success');
    log_addWorkLog(sprintf('数据导出成功: %s', file));
catch ME
    utils_showMessage('数据导出失败', 'error', ME.message);
    log_updateStatus('导出失败');
    log_addWorkLog(sprintf('错误: 导出失败 - %s', ME.message));
end
end

function paramTable = createParameterTable(data)
paramNames = {'TMAX_s', 'MTT_s', 'TU_s', 'FWHM_s', 'AUC', 'Peak_Density'};
roiNames = {'狭窄近端_Proximal', '狭窄远端_Distal'};
tableData = zeros(2, length(paramNames));

for i = 1:2
    params = data.perfusionParams(i);
    % Safe extraction with fallbacks just in case
    p_TMAX = 0; if isfield(params, 'TMAX'), p_TMAX = params.TMAX; end
    p_MTT = 0; if isfield(params, 'MTT'), p_MTT = params.MTT; end
    p_TU = 0; if isfield(params, 'TU'), p_TU = params.TU; end
    p_FWHM = 0; if isfield(params, 'FWHM'), p_FWHM = params.FWHM; end
    p_AUC = 0; if isfield(params, 'AUC'), p_AUC = params.AUC; end
    p_Peak = 0; if isfield(params, 'Peak'), p_Peak = params.Peak; end
    
    tableData(i, :) = [p_TMAX, p_MTT, p_TU, p_FWHM, p_AUC, p_Peak];
end
paramTable = array2table(tableData, 'RowNames', roiNames, 'VariableNames', paramNames);
end

function timeSeriesTable = createTimeSeriesTable(data)
[numROIs, numFrames] = size(data.timeSeriesData);
time = (0:numFrames-1) / data.frameRate;
variableNames = {'Time_s'};
roiNames = {'Proximal', 'Distal'};

for roiIdx = 1:numROIs
    if roiIdx <= 2
        variableNames{end+1} = roiNames{roiIdx}; %#ok<AGROW>
    else
        variableNames{end+1} = sprintf('ROI_%d', roiIdx); %#ok<AGROW>
    end
end
tableData = zeros(numFrames, numROIs + 1);
tableData(:, 1) = time';
tableData(:, 2:end) = data.timeSeriesData';
timeSeriesTable = array2table(tableData, 'VariableNames', variableNames);
end

function infoTable = createAnalysisInfoTable(data)
infoFields = {'分析时间', '文件名', '总帧数', '帧率', '软件版本'};

fileNameStr = 'Unknown'; if isfield(data, 'fileName'), fileNameStr = data.fileName; end
totFPSstr = 'Unknown'; if isfield(data, 'totalFrames'), totFPSstr = num2str(data.totalFrames); end
rateStr = 'Unknown'; if isfield(data, 'frameRate'), rateStr = num2str(data.frameRate); end
verStr = 'v5.0'; if isfield(data.analysisInfo, 'softwareVersion'), verStr = data.analysisInfo.softwareVersion; end

infoValues = {data.analysisInfo.timestamp, fileNameStr, totFPSstr, rateStr, verStr};

% [核心升级]：将 CCF-B 级别的新增血流动力学参数导出到汇总表底部
if isfield(data.analysisInfo, 'DTW_Distance')
    infoFields{end+1} = '非线性波形形态畸变 (DTW_Distance)';
    infoValues{end+1} = num2str(data.analysisInfo.DTW_Distance, '%.4f');
end

infoTable = table(infoFields', infoValues', 'VariableNames', {'参数_Parameter', '值_Value'});
end
