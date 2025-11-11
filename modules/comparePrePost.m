function comparePrePost(~, ~)
    % comparePrePost - 术前术后对比分析
    %
    % 功能：
    %   1. 导入术前和术后分析数据
    %   2. 基于最大斜率(MS)计算血流速度增加比例
    %   3. 根据TCD标准判断高灌注风险（增加>150%为高风险）
    %   4. 显示详细参数对比和临床建议
    %   5. 导出对比分析结果
    %
    % 输入：
    %   无（从guidata获取数据，或通过UI导入）
    %
    % 输出：
    %   无（显示对比窗口）
    
    addWorkLog('开始术前术后对比分析');
    fig = gcf;
    data = guidata(fig);
    
    % 数据完整性检查
    if isempty(data.perfusionParams)
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
                if isempty(data.timeSeriesData)
                    errordlg('请先完成数据导入、ROI放置和时间序列提取', '错误');
                    return;
                else
                    analyzeCurves([], []);
                    drawnow;
                    data = guidata(fig);
                end
            case '导入已有数据'
                % 继续执行原有的导入逻辑
            case '取消'
                return;
        end
    end
    
    % 创建对比分析窗口
    compFig = figure('Name', '术前术后灌注对比分析', ...
                    'NumberTitle', 'off', ...
                    'Position', [200, 50, 1400, 900], ...
                    'MenuBar', 'none', ...
                    'Color', [0.95, 0.95, 0.95]);
    
    % 说明文本
    uicontrol('Parent', compFig, ...
             'Style', 'text', ...
             'String', '高灌注风险预警 (TCD标准: 术后血流速度增加 > 150%)', ...
             'Position', [50, 850, 1300, 30], ...
             'FontSize', 16, 'FontWeight', 'bold', ...
             'BackgroundColor', [0.9, 0.9, 0.9], ...
             'HorizontalAlignment', 'center');
    
    % 按钮区域
    btnPanel = uipanel(compFig, 'Title', '数据导入', ...
                      'Position', [0.05, 0.88, 0.9, 0.1], ...
                      'BackgroundColor', [0.9, 0.9, 0.9], ...
                      'FontWeight', 'bold');
    
    % 导入术前数据按钮
    uicontrol('Parent', btnPanel, ...
             'Style', 'pushbutton', ...
             'String', '导入术前数据', ...
             'Units', 'normalized', ...
             'Position', [0.05, 0.2, 0.2, 0.6], ...
             'FontSize', 12, ...
             'BackgroundColor', [0.8, 0.9, 0.8], ...
             'Callback', @importPreOpData);
    
    % 导入术后数据按钮
    uicontrol('Parent', btnPanel, ...
             'Style', 'pushbutton', ...
             'String', '导入术后数据', ...
             'Units', 'normalized', ...
             'Position', [0.3, 0.2, 0.2, 0.6], ...
             'FontSize', 12, ...
             'BackgroundColor', [0.8, 0.9, 0.8], ...
             'Callback', @importPostOpData);
    
    % 分析对比按钮
    analyzeBtn = uicontrol('Parent', btnPanel, ...
             'Style', 'pushbutton', ...
             'String', '分析对比', ...
             'Units', 'normalized', ...
             'Position', [0.55, 0.2, 0.2, 0.6], ...
             'FontSize', 12, ...
             'BackgroundColor', [0.8, 0.8, 1], ...
             'Callback', @analyzeComparison, ...
             'Enable', 'off');
    
    % 导出对比结果按钮
    uicontrol('Parent', btnPanel, ...
             'Style', 'pushbutton', ...
             'String', '导出对比结果', ...
             'Units', 'normalized', ...
             'Position', [0.8, 0.2, 0.15, 0.6], ...
             'FontSize', 12, ...
             'BackgroundColor', [0.8, 1, 0.8], ...
             'Callback', @exportComparison);
    
    % 结果显示区域
    resultsPanel = uipanel(compFig, 'Title', '对比分析结果', ...
                          'Position', [0.05, 0.05, 0.9, 0.8], ...
                          'BackgroundColor', [1, 1, 1], ...
                          'FontWeight', 'bold', ...
                          'FontSize', 12);
    
    % 初始化对比数据
    compData.preOpData = [];
    compData.postOpData = [];
    compData.preOpFile = '';
    compData.postOpFile = '';
    guidata(compFig, compData);
    
    %% 嵌套函数：导入术前数据
    function importPreOpData(~, ~)
        [fname, pname] = uigetfile({'*.mat', 'MAT文件 (*.mat)'}, ...
                                  '选择术前分析数据');
        if isequal(fname, 0), return; end
        
        try
            preData = load(fullfile(pname, fname));
            compData = guidata(compFig);
            compData.preOpData = preData.data;
            compData.preOpFile = fname;
            guidata(compFig, compData);
            
            % 更新按钮状态
            if ~isempty(compData.preOpData) && ~isempty(compData.postOpData)
                set(analyzeBtn, 'Enable', 'on');
            end
            
            msgbox(sprintf('成功导入术前数据: %s', fname), '成功');
        catch ME
            errordlg(sprintf('导入失败: %s', ME.message), '错误');
        end
    end
    
    %% 嵌套函数：导入术后数据
    function importPostOpData(~, ~)
        [fname, pname] = uigetfile({'*.mat', 'MAT文件 (*.mat)'}, ...
                                  '选择术后分析数据');
        if isequal(fname, 0), return; end
        
        try
            postData = load(fullfile(pname, fname));
            compData = guidata(compFig);
            compData.postOpData = postData.data;
            compData.postOpFile = fname;
            guidata(compFig, compData);
            
            % 更新按钮状态
            if ~isempty(compData.preOpData) && ~isempty(compData.postOpData)
                set(analyzeBtn, 'Enable', 'on');
            end
            
            msgbox(sprintf('成功导入术后数据: %s', fname), '成功');
        catch ME
            errordlg(sprintf('导出失败: %s', ME.message), '错误');
        end
    end
    
    %% 嵌套函数：分析对比
    function analyzeComparison(~, ~)
        compData = guidata(compFig);
        
        if isempty(compData.preOpData) || isempty(compData.postOpData)
            errordlg('请先导入术前和术后数据', '错误');
            return;
        end
        
        % 清除之前的结果
        delete(get(resultsPanel, 'Children'));
        
        % 计算血流速度指标（基于MS - 最大斜率）
        preParams = compData.preOpData.perfusionParams;
        postParams = compData.postOpData.perfusionParams;
        
        % 计算各脑叶的血流速度增加比例
        lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
        increaseRatios = zeros(1, 4);
        riskLevels = cell(1, 4);
        
        for lobe = 1:4
            % 基于最大斜率(MS)计算血流速度增加比例
            preMS = preParams(lobe).MS;
            postMS = postParams(lobe).MS;
            
            if preMS > 0
                increaseRatios(lobe) = (postMS / preMS) * 100;
            else
                increaseRatios(lobe) = 0;
            end
            
            % 判断风险等级
            if increaseRatios(lobe) >= 150
                riskLevels{lobe} = '高风险';
            elseif increaseRatios(lobe) >= 120
                riskLevels{lobe} = '中风险';
            else
                riskLevels{lobe} = '低风险';
            end
        end
        
        % 显示结果表格
        tableData = cell(4, 5);
        for i = 1:4
            tableData{i, 1} = lobeNames{i};
            tableData{i, 2} = sprintf('%.3f', preParams(i).MS);
            tableData{i, 3} = sprintf('%.3f', postParams(i).MS);
            tableData{i, 4} = sprintf('%.1f%%', increaseRatios(i));
            tableData{i, 5} = riskLevels{i};
        end
        
        uitable(resultsPanel, ...
           'Data', tableData, ...
           'Position', [50, 550, 600, 150], ...
           'ColumnName', {'脑叶', '术前MS', '术后MS', '增加比例', '风险等级'}, ...
           'ColumnWidth', {80, 100, 100, 100, 120}, ...
           'RowName', [], ...
           'FontSize', 12, ...
           'FontWeight', 'bold');
        
        % 显示风险预警
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
        
        % 保存对比结果
        compData.increaseRatios = increaseRatios;
        compData.riskLevels = riskLevels;
        compData.warningLevel = warningLevel;
        guidata(compFig, compData);
        
        updateStatus('术前术后对比分析完成');
        addWorkLog('术前术后对比分析完成');
    end
    
    %% 嵌套函数：导出对比结果
    function exportComparison(~, ~)
        compData = guidata(compFig);
        
        [file, path] = uiputfile({'*.xlsx', 'Excel文件 (*.xlsx)'; ...
                                 '*.csv', 'CSV文件 (*.csv)'}, ...
                                '保存对比分析结果');
        if isequal(file, 0)
            return;
        end
        
        try
            fullPath = fullfile(path, file);
            
            % 检查必要的数据是否存在
            if ~isfield(compData, 'increaseRatios') || isempty(compData.increaseRatios)
                errordlg('请先进行对比分析再导出结果！', '错误');
                return;
            end
            
            % 创建对比结果表格
            lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
            tableData = table();
            
            for i = 1:4
                tableData.Lobe{i} = lobeNames{i};
                tableData.PreOp_MS(i) = compData.preOpData.perfusionParams(i).MS;
                tableData.PostOp_MS(i) = compData.postOpData.perfusionParams(i).MS;
                tableData.IncreaseRatio(i) = compData.increaseRatios(i);
                tableData.RiskLevel{i} = compData.riskLevels{i};
            end
            
            % 根据文件扩展名导出
            [~, ~, ext] = fileparts(file);
            if strcmpi(ext, '.xlsx')
                writetable(tableData, fullPath, 'Sheet', '对比结果');
            else
                writetable(tableData, fullPath);
            end
            
            msgbox('对比结果导出成功！', '成功');
            addWorkLog(sprintf('对比结果导出成功: %s', file));
            
        catch ME
            errordlg(sprintf('导出失败: %s', ME.message), '错误');
        end
    end
    
    addWorkLog('术前术后对比分析窗口已打开');
end
