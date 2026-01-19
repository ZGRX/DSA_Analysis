function analysis_comparePrePost(varargin)
% 术前术后对比分析 - migrated to modules/analysis with full visualization
log_addWorkLog('开始术前术后对比分析');
fig = gcf;
data = guidata(fig);

% 数据完整性检查
% 数据完整性检查
hasParams = false;
if ~isempty(data) && isstruct(data) && isfield(data, 'perfusionParams') && ~isempty(data.perfusionParams)
    hasParams = true;
end

if ~hasParams
    choice = questdlg({
        '术前术后对比需要完整的数据分析。'
        '当前会话没有完整的分析数据。'
        ''
        '请选择：'
        '• "分析当前数据" - 如果这是术前数据'
        '• "导入已有数据" - 如果已有分析结果'
        '• "取消" - 返回主界面'
        }, '数据准备', '分析当前数据', '导入已有数据', '取消', '分析当前数据');
    
    switch choice
        case '分析当前数据'
            if isempty(data) || ~isstruct(data)
                utils_showMessage('当前未加载任何数据，请先导入数据', 'error');
                return;
            end
            
            if ~isfield(data, 'timeSeriesData') || isempty(data.timeSeriesData)
                utils_showMessage('请先完成数据导入、ROI放置和时间序列提取', 'error');
                return;
            else
                analysis_analyzeCurves([],[]);
                drawnow;
                data = guidata(fig);
            end
        case '导入已有数据'
            % 继续执行，打开对比窗口
        case '取消'
            return;
        otherwise
            return;
    end
end

compFig = figure('Name', '术前术后灌注对比分析', ...
    'NumberTitle', 'off', ...
    'Position', [200, 50, 1400, 900], ...
    'MenuBar', 'none', ...
    'Color', [0.95, 0.95, 0.95]);

uicontrol('Parent', compFig, 'Style', 'text', ...
    'String', '高灌注风险预警 (TCD标准: 术后血流速度增加 > 150%)', ...
    'Position', [50, 850, 1300, 30], ...
    'FontSize', 16, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'HorizontalAlignment', 'center');

btnPanel = uipanel(compFig, 'Title', '数据导入', ...
    'Position', [0.05, 0.88, 0.9, 0.1], ...
    'BackgroundColor', [0.9, 0.9, 0.9], ...
    'FontWeight', 'bold');

uicontrol('Parent', btnPanel, 'Style', 'pushbutton', ...
    'String', '导入术前数据', 'Units', 'normalized', ...
    'Position', [0.05, 0.2, 0.2, 0.6], 'FontSize', 12, ...
    'BackgroundColor', [0.8, 0.9, 0.8], ...
    'Callback', @importPreOpData);

uicontrol('Parent', btnPanel, 'Style', 'pushbutton', ...
    'String', '导入术后数据', 'Units', 'normalized', ...
    'Position', [0.3, 0.2, 0.2, 0.6], 'FontSize', 12, ...
    'BackgroundColor', [0.8, 0.9, 0.8], ...
    'Callback', @importPostOpData);

analyzeBtn = uicontrol('Parent', btnPanel, 'Style', 'pushbutton', ...
    'String', '分析对比', 'Units', 'normalized', ...
    'Position', [0.55, 0.2, 0.2, 0.6], 'FontSize', 12, ...
    'BackgroundColor', [0.8, 0.8, 1], ...
    'Callback', @analyzeComparison, 'Enable', 'off');

uicontrol('Parent', btnPanel, 'Style', 'pushbutton', ...
    'String', '导出对比结果', 'Units', 'normalized', ...
    'Position', [0.70, 0.2, 0.14, 0.6], 'FontSize', 12, ...
    'BackgroundColor', [0.8, 1, 0.8], ...
    'Callback', @exportComparison);

uicontrol('Parent', btnPanel, 'Style', 'pushbutton', ...
    'String', '科研数据集导出', 'Units', 'normalized', ...
    'Position', [0.85, 0.2, 0.14, 0.6], 'FontSize', 11, ...
    'BackgroundColor', [1, 0.9, 0.7], ...
    'Callback', @appendResearchData);

resultsPanel = uipanel(compFig, 'Title', '对比分析结果', ...
    'Position', [0.05, 0.05, 0.9, 0.8], ...
    'BackgroundColor', [1, 1, 1], ...
    'FontWeight', 'bold', 'FontSize', 12);

% --- 科研数据集导出函数 ---
    function appendResearchData(~,~)
        compData = guidata(compFig);
        if ~isfield(compData, 'increaseRatios') || isempty(compData.increaseRatios)
            utils_showMessage('请先进行“分析对比”再导出科研数据！', 'error');
            return;
        end
        
        researchFile = fullfile(pwd, 'PatientData', 'Research_Dataset_Summary.xlsx');
        try
            lobeNames = {'Frontal', 'Parietal', 'Temporal', 'Occipital'};
            patientID = 'Unknown';
            if isfield(compData.preOpData, 'patientInfo'), patientID = compData.preOpData.patientInfo.id; end
            
            rows = cell(4, 7);
            for i = 1:4
                rows{i,1} = datestr(now, 'yyyy-mm-dd HH:MM');
                rows{i,2} = patientID;
                rows{i,3} = lobeNames{i};
                rows{i,4} = compData.preOpData.perfusionParams(i).MS;
                rows{i,5} = compData.postOpData.perfusionParams(i).MS;
                rows{i,6} = compData.increaseRatios(i);
                rows{i,7} = compData.riskLevels{i};
            end
            
            newTable = cell2table(rows, 'VariableNames', ...
                {'Timestamp', 'PatientID', 'Lobe', 'PreOp_MS', 'PostOp_MS', 'Increase_Ratio', 'RiskLevel'});
            
            if exist(researchFile, 'file')
                oldTable = readtable(researchFile);
                finalTable = [oldTable; newTable];
            else
                finalTable = newTable;
            end
            
            writetable(finalTable, researchFile);
            utils_showMessage('科研数据已成功追加至: Research_Dataset_Summary.xlsx', 'success');
        catch ME
            utils_showMessage('科研导出失败', 'error', ME.message);
        end
    end

compData.preOpData = [];
compData.postOpData = [];
compData.preOpFile = '';
compData.postOpFile = '';
guidata(compFig, compData);

    function importPreOpData(~,~)
        % 默认从Results目录读取
        baseDir = pwd;
        resultsDir = fullfile(baseDir, 'PatientData');
        if ~exist(resultsDir, 'dir')
            resultsDir = pwd;
        end
        
        [fname, pname] = uigetfile({'*.mat','MAT文件 (*.mat)'}, '选择术前分析数据', resultsDir);
        if isequal(fname, 0), return; end
        
        try
            preData = load(fullfile(pname, fname));
            compData = guidata(compFig);
            compData.preOpData = preData.data;
            compData.preOpFile = fname;
            guidata(compFig, compData);
            
            if ~isempty(compData.preOpData) && ~isempty(compData.postOpData)
                set(analyzeBtn, 'Enable', 'on');
            end
            
            utils_showMessage(sprintf('成功导入术前数据: %s', fname), 'success');
        catch ME
            utils_showMessage('导入失败', 'error', ME.message);
        end
    end

    function importPostOpData(~,~)
        % 默认从Results目录读取
        baseDir = pwd;
        resultsDir = fullfile(baseDir, 'PatientData');
        if ~exist(resultsDir, 'dir')
            resultsDir = pwd;
        end
        
        [fname, pname] = uigetfile({'*.mat','MAT文件 (*.mat)'}, '选择术后分析数据', resultsDir);
        if isequal(fname, 0), return; end
        
        try
            postData = load(fullfile(pname, fname));
            compData = guidata(compFig);
            compData.postOpData = postData.data;
            compData.postOpFile = fname;
            guidata(compFig, compData);
            
            if ~isempty(compData.preOpData) && ~isempty(compData.postOpData)
                set(analyzeBtn, 'Enable', 'on');
            end
            
            utils_showMessage(sprintf('成功导入术后数据: %s', fname), 'success');
        catch ME
            utils_showMessage('导入失败', 'error', ME.message);
        end
    end

    function analyzeComparison(~,~)
        compData = guidata(compFig);
        
        if isempty(compData.preOpData) || isempty(compData.postOpData)
            utils_showMessage('请先导入术前和术后数据', 'error');
            return;
        end
        
        delete(get(resultsPanel, 'Children'));
        
        preParams = compData.preOpData.perfusionParams;
        postParams = compData.postOpData.perfusionParams;
        
        lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
        increaseRatios = zeros(1, 4);
        riskLevels = cell(1, 4);
        
        for lobe = 1:4
            preMS = preParams(lobe).MS;
            postMS = postParams(lobe).MS;
            
            if preMS > 0
                increaseRatios(lobe) = (postMS / preMS) * 100;
            else
                increaseRatios(lobe) = 0;
            end
            
            if increaseRatios(lobe) >= 150
                riskLevels{lobe} = '高风险';
            elseif increaseRatios(lobe) >= 120
                riskLevels{lobe} = '中风险';
            else
                riskLevels{lobe} = '低风险';
            end
        end
        
        tableData = cell(4, 5);
        for i = 1:4
            tableData{i,1} = lobeNames{i};
            tableData{i,2} = sprintf('%.3f', preParams(i).MS);
            tableData{i,3} = sprintf('%.3f', postParams(i).MS);
            tableData{i,4} = sprintf('%.1f%%', increaseRatios(i));
            tableData{i,5} = riskLevels{i};
        end
        
        uitable(resultsPanel, 'Data', tableData, ...
            'Position', [50, 550, 600, 150], ...
            'ColumnName', {'脑叶', '术前MS', '术后MS', '增加比例', '风险等级'}, ...
            'ColumnWidth', {80, 100, 100, 100, 120}, ...
            'RowName', [], 'FontSize', 12, 'FontWeight', 'bold');
        
        highRiskCount = sum(increaseRatios >= 150);
        mediumRiskCount = sum(increaseRatios >= 120 & increaseRatios < 150);
        
        if highRiskCount > 0
            warningText = sprintf('高灌注风险预警: %d个脑叶血流速度增加超过150%%', highRiskCount);
            warningColor = [1 0.5 0.5];
            warningLevel = '高风险';
        elseif mediumRiskCount > 0
            warningText = sprintf('中灌注风险提示: %d个脑叶血流速度增加120%%-150%%', mediumRiskCount);
            warningColor = [1 0.9 0.5];
            warningLevel = '中风险';
        else
            warningText = '无高灌注风险';
            warningColor = [0.5 1 0.5];
            warningLevel = '低风险';
        end
        
        uicontrol(resultsPanel, 'Style', 'text', ...
            'String', warningText, ...
            'Position', [50, 500, 600, 40], ...
            'FontSize', 16, 'FontWeight', 'bold', ...
            'BackgroundColor', warningColor, ...
            'HorizontalAlignment', 'center');
        
        % 绘制柱状图对比
        axes('Parent', resultsPanel, 'Position', [0.65, 0.45, 0.3, 0.4]);
        
        barData = [increaseRatios; ones(1,4)*100]';
        h = bar(barData, 'grouped');
        set(h(1), 'FaceColor', [0.2 0.6 0.8]);
        set(h(2), 'FaceColor', [0.8 0.8 0.8]);
        
        hold on;
        plot([0,5], [150, 150], 'r--', 'LineWidth', 3);
        text(5.2, 150, '高风险', 'Color', 'r', 'FontWeight', 'bold', 'FontSize', 11);
        plot([0,5], [120, 120], 'y--', 'LineWidth', 3);
        text(5.2, 120, '中风险', 'Color', [0.8 0.6 0], 'FontWeight', 'bold', 'FontSize', 11);
        
        set(gca, 'XTickLabel', lobeNames, 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('血流速度增加比例 (%)', 'FontSize', 13, 'FontWeight', 'bold');
        title('术前术后血流速度对比 (基于MS参数)', 'FontSize', 14, 'FontWeight', 'bold');
        legend('增加比例', '基线(100%)', 'Location', 'northwest', 'FontSize', 11);
        grid on;
        
        for i = 1:4
            text(i, increaseRatios(i)+8, sprintf('%.1f%%', increaseRatios(i)), ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11, ...
                'BackgroundColor', 'white', 'EdgeColor', 'black', 'Margin', 2);
        end
        
        % 显示详细参数对比
        paramPanel = uipanel(resultsPanel, 'Title', '详细参数对比', ...
            'Position', [0.05, 0.05, 0.55, 0.35], ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'FontWeight', 'bold', 'FontSize', 12);
        
        paramData = cell(4, 7);
        for i = 1:4
            paramData{i,1} = lobeNames{i};
            paramData{i,2} = sprintf('%.3f', preParams(i).TMAX);
            paramData{i,3} = sprintf('%.3f', postParams(i).TMAX);
            paramData{i,4} = sprintf('%.3f', preParams(i).MTT);
            paramData{i,5} = sprintf('%.3f', postParams(i).MTT);
            paramData{i,6} = sprintf('%.1f', preParams(i).AUC);
            paramData{i,7} = sprintf('%.1f', postParams(i).AUC);
        end
        
        uitable(paramPanel, 'Data', paramData, ...
            'Position', [10, 10, 530, 120], ...
            'ColumnName', {'脑叶', '术前TMAX', '术后TMAX', '术前MTT', '术后MTT', '术前AUC', '术后AUC'}, ...
            'ColumnWidth', {60, 80, 80, 80, 80, 80, 80}, ...
            'RowName', [], 'FontSize', 10);
        
        % 显示临床建议
        advicePanel = uipanel(resultsPanel, 'Title', '临床建议', ...
            'Position', [0.65, 0.05, 0.3, 0.35], ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'FontWeight', 'bold', 'FontSize', 12);
        
        switch warningLevel
            case '高风险'
                adviceText = {'高风险灌注建议:', ...
                    '• 密切监测神经功能状态', ...
                    '• 控制血压在较低水平', ...
                    '• 考虑预防性药物治疗', ...
                    '• 必要时进行影像学复查', ...
                    '• 避免血压剧烈波动'};
                adviceColor = [1 0.8 0.8];
            case '中风险'
                adviceText = {'中风险灌注建议:', ...
                    '• 定期监测血压', ...
                    '• 观察神经症状变化', ...
                    '• 避免血压剧烈波动', ...
                    '• 适当控制液体入量'};
                adviceColor = [1 1 0.8];
            case '低风险'
                adviceText = {'低风险灌注建议:', ...
                    '• 常规术后观察', ...
                    '• 维持血压稳定', ...
                    '• 正常康复治疗', ...
                    '• 定期随访'};
                adviceColor = [0.8 1 0.8];
        end
        
        uicontrol(advicePanel, 'Style', 'text', ...
            'String', adviceText, ...
            'Position', [10, 10, 350, 120], ...
            'FontSize', 11, ...
            'BackgroundColor', adviceColor, ...
            'HorizontalAlignment', 'left');
        
        compData.increaseRatios = increaseRatios;
        compData.riskLevels = riskLevels;
        compData.warningLevel = warningLevel;
        guidata(compFig, compData);
        
        log_updateStatus('术前术后对比分析完成');
        log_addWorkLog('术前术后对比分析完成');
    end

    function exportComparison(~,~)
        compData = guidata(compFig);
        
        % 默认保存到Results目录
        baseDir = pwd;
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        defaultName = sprintf('Comparison_%s.xlsx', timestamp);
        
        % 尝试从数据中获取患者ID
        if ~isempty(compData.preOpData) && isfield(compData.preOpData, 'patientInfo')
            patientID = compData.preOpData.patientInfo.id;
        else
            patientID = 'Unknown';
        end
        
        resultsDir = fullfile(baseDir, 'PatientData', patientID, 'Results');
        if ~exist(resultsDir, 'dir')
            mkdir(resultsDir);
        end
        
        [file, path] = uiputfile({'*.xlsx','Excel文件 (*.xlsx)'; '*.csv','CSV文件 (*.csv)'}, ...
            '保存对比分析结果', fullfile(resultsDir, defaultName));
        if isequal(file, 0), return; end
        
        try
            fullPath = fullfile(path, file);
            
            if ~isfield(compData, 'increaseRatios') || isempty(compData.increaseRatios)
                utils_showMessage('请先进行对比分析再导出结果！', 'error');
                return;
            end
            
            lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
            tableData = table();
            
            for i = 1:4
                tableData.Lobe{i} = lobeNames{i};
                tableData.PreOp_MS(i) = compData.preOpData.perfusionParams(i).MS;
                tableData.PostOp_MS(i) = compData.postOpData.perfusionParams(i).MS;
                tableData.IncreaseRatio(i) = compData.increaseRatios(i);
                tableData.RiskLevel{i} = compData.riskLevels{i};
                tableData.PreOp_TMAX(i) = compData.preOpData.perfusionParams(i).TMAX;
                tableData.PostOp_TMAX(i) = compData.postOpData.perfusionParams(i).TMAX;
                tableData.PreOp_MTT(i) = compData.preOpData.perfusionParams(i).MTT;
                tableData.PostOp_MTT(i) = compData.postOpData.perfusionParams(i).MTT;
                tableData.PreOp_AUC(i) = compData.preOpData.perfusionParams(i).AUC;
                tableData.PostOp_AUC(i) = compData.postOpData.perfusionParams(i).AUC;
            end
            
            summaryTable = table();
            summaryTable.AnalysisDate = {datestr(now)};
            summaryTable.PreOpFile = {compData.preOpFile};
            summaryTable.PostOpFile = {compData.postOpFile};
            summaryTable.OverallRiskLevel = {compData.warningLevel};
            summaryTable.HighRiskLobes = {sum(compData.increaseRatios >= 150)};
            summaryTable.MediumRiskLobes = {sum(compData.increaseRatios >= 120 & compData.increaseRatios < 150)};
            
            [~, ~, ext] = fileparts(file);
            if strcmpi(ext, '.xlsx')
                writetable(tableData, fullPath, 'Sheet', '详细参数');
                writetable(summaryTable, fullPath, 'Sheet', '分析总结');
            else
                writetable(tableData, fullPath);
            end
            
            utils_showMessage('对比结果导出成功！', 'success');
            log_addWorkLog(sprintf('对比结果导出成功: %s', file));
        catch ME
            utils_showMessage('对比结果导出失败', 'error', ME.message);
        end
    end

log_addWorkLog('术前术后对比分析窗口已打开');
end
