function DSA_Analysis_GUI_v3
    % ---------- 1. 清理工作区 ----------
    clear variables; 
    clc;
    
    % 显示欢迎信息
    disp('=== DSA脑血流灌注分析系统 v3.0 ===');
    disp('正在初始化系统...');
    
    % ---------- 2. 显示患者信息输入对话框 ----------
    patientInfo = getPatientInformation();
    if isempty(patientInfo)
        disp('用户取消了患者信息输入');
        return; 
    end
    
    % ---------- 3. 创建主窗口 ----------
    screenSize = get(0, 'ScreenSize');
    screenWidth = screenSize(3);
    screenHeight = screenSize(4);
    
    % 设置窗口大小和位置
    windowWidth = 1400;
    windowHeight = 850;
    windowX = round((screenWidth - windowWidth) / 2);
    windowY = round((screenHeight - windowHeight) / 2);
    
    fig = figure('Name', 'DSA脑血流灌注分析系统 v3.0', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Position', [windowX, windowY, windowWidth, windowHeight], ...
                'Color', [0.07, 0.15, 0.25], ...
                'Resize', 'off', ...
                'CloseRequestFcn', @closeGUI);

    % 存储患者信息
    setappdata(fig, 'patientInfo', patientInfo);
    
    % ---------- 4. 顶部标题栏 ----------
    createTitleBar(fig);
    
    % ---------- 5. 左侧控制面板 ----------
    controlPanel = uipanel('Parent', fig, ...
                          'Title', '', ...
                          'Position', [0.01, 0.05, 0.18, 0.86], ...
                          'BackgroundColor', [0.1, 0.2, 0.3], ...
                          'ForegroundColor', [1, 1, 1], ...
                          'BorderType', 'line', ...
                          'HighlightColor', [0, 0.6, 0.8]);
    
    % ---------- 6. 中间显示区域 ----------
    displayPanel = uipanel('Parent', fig, ...
                          'Title', '', ...
                          'Position', [0.20, 0.05, 0.58, 0.86], ...
                          'BackgroundColor', [0.05, 0.1, 0.15], ...
                          'BorderType', 'line', ...
                          'HighlightColor', [0, 0.6, 0.8]);
    
    % ---------- 7. 右侧信息面板 ----------
    infoPanel = uipanel('Parent', fig, ...
                       'Title', '', ...
                       'Position', [0.79, 0.05, 0.20, 0.86], ...
                       'BackgroundColor', [0.1, 0.2, 0.3], ...
                       'BorderType', 'line', ...
                       'HighlightColor', [0, 0.6, 0.8]);
    
    % ---------- 8. 创建各区域内容 ----------
    createControlButtons(controlPanel);
    createDisplayArea(displayPanel);
    createInfoArea(infoPanel, patientInfo);
    
    % ---------- 9. 数据容器 ----------
    initializeDataContainer(fig);
    
    % 初始化界面状态
    updateStatus('系统就绪 - 请导入术前DSA数据');
end

%% ========== 患者信息输入函数 ==========
function patientInfo = getPatientInformation()
    patientInfo = [];
    
    dlg = dialog('Name', '患者信息录入', ...
                'WindowStyle', 'normal', ...
                'Position', [500, 400, 400, 400], ...
                'Color', [0.9, 0.95, 1], ...
                'Resize', 'off');
    
    % 标题
    uicontrol('Parent', dlg, ...
             'Style', 'text', ...
             'String', '患者基本信息录入', ...
             'Position', [50, 350, 300, 30], ...
             'FontSize', 16, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [0.1, 0.3, 0.6], ...
             'BackgroundColor', [0.9, 0.95, 1], ...
             'HorizontalAlignment', 'center');
    
    % 患者姓名
    uicontrol('Parent', dlg, ...
             'Style', 'text', ...
             'String', '患者姓名:', ...
             'Position', [50, 300, 80, 25], ...
             'FontSize', 11, ...
             'FontWeight', 'bold', ...
             'HorizontalAlignment', 'left', ...
             'BackgroundColor', [0.9, 0.95, 1]);
    
    nameEdit = uicontrol('Parent', dlg, ...
                        'Style', 'edit', ...
                        'Position', [140, 300, 200, 25], ...
                        'FontSize', 11, ...
                        'BackgroundColor', [1, 1, 1]);
    
    % 患者ID
    uicontrol('Parent', dlg, ...
             'Style', 'text', ...
             'String', '病历号:', ...
             'Position', [50, 260, 80, 25], ...
             'FontSize', 11, ...
             'FontWeight', 'bold', ...
             'HorizontalAlignment', 'left', ...
             'BackgroundColor', [0.9, 0.95, 1]);
    
    idEdit = uicontrol('Parent', dlg, ...
                      'Style', 'edit', ...
                      'Position', [140, 260, 200, 25], ...
                      'FontSize', 11, ...
                      'BackgroundColor', [1, 1, 1]);
    
    % 年龄
    uicontrol('Parent', dlg, ...
             'Style', 'text', ...
             'String', '年龄:', ...
             'Position', [50, 220, 80, 25], ...
             'FontSize', 11, ...
             'FontWeight', 'bold', ...
             'HorizontalAlignment', 'left', ...
             'BackgroundColor', [0.9, 0.95, 1]);
    
    ageEdit = uicontrol('Parent', dlg, ...
                       'Style', 'edit', ...
                       'Position', [140, 220, 80, 25], ...
                       'FontSize', 11, ...
                       'BackgroundColor', [1, 1, 1]);
    
    % 性别
    uicontrol('Parent', dlg, ...
             'Style', 'text', ...
             'String', '性别:', ...
             'Position', [50, 180, 80, 25], ...
             'FontSize', 11, ...
             'FontWeight', 'bold', ...
             'HorizontalAlignment', 'left', ...
             'BackgroundColor', [0.9, 0.95, 1]);
    
    genderPopup = uicontrol('Parent', dlg, ...
                           'Style', 'popupmenu', ...
                           'String', {'男', '女'}, ...
                           'Position', [140, 180, 80, 25], ...
                           'FontSize', 11, ...
                           'BackgroundColor', [1, 1, 1]);
    
    % 临床诊断
    uicontrol('Parent', dlg, ...
             'Style', 'text', ...
             'String', '临床诊断:', ...
             'Position', [50, 140, 80, 25], ...
             'FontSize', 11, ...
             'FontWeight', 'bold', ...
             'HorizontalAlignment', 'left', ...
             'BackgroundColor', [0.9, 0.95, 1]);
    
    diagnosisEdit = uicontrol('Parent', dlg, ...
                             'Style', 'edit', ...
                             'Position', [140, 140, 200, 25], ...
                             'FontSize', 11, ...
                             'BackgroundColor', [1, 1, 1]);
    
    % 检查日期
    uicontrol('Parent', dlg, ...
             'Style', 'text', ...
             'String', '检查日期:', ...
             'Position', [50, 100, 80, 25], ...
             'FontSize', 11, ...
             'FontWeight', 'bold', ...
             'HorizontalAlignment', 'left', ...
             'BackgroundColor', [0.9, 0.95, 1]);
    
    dateEdit = uicontrol('Parent', dlg, ...
                        'Style', 'edit', ...
                        'String', datestr(now, 'yyyy-mm-dd'), ...
                        'Position', [140, 100, 120, 25], ...
                        'FontSize', 11, ...
                        'BackgroundColor', [1, 1, 1]);
    
    % 按钮
    uicontrol('Parent', dlg, ...
             'Style', 'pushbutton', ...
             'String', '确认', ...
             'Position', [120, 40, 80, 30], ...
             'FontSize', 12, ...
             'FontWeight', 'bold', ...
             'BackgroundColor', [0.2, 0.7, 0.2], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', @confirmCallback);
    
    uicontrol('Parent', dlg, ...
             'Style', 'pushbutton', ...
             'String', '取消', ...
             'Position', [220, 40, 80, 30], ...
             'FontSize', 12, ...
             'BackgroundColor', [0.8, 0.2, 0.2], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', 'delete(gcf)');
    
    % 等待用户输入
    uiwait(dlg);
    
    function confirmCallback(~,~)
        patientInfo.Name = get(nameEdit, 'String');
        patientInfo.ID = get(idEdit, 'String');
        patientInfo.Age = get(ageEdit, 'String');
        genderOptions = get(genderPopup, 'String');
        patientInfo.Gender = genderOptions{get(genderPopup, 'Value')};
        patientInfo.Diagnosis = get(diagnosisEdit, 'String');
        patientInfo.StudyDate = get(dateEdit, 'String');
        patientInfo.InputTime = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        
        % 验证必填字段
        if isempty(patientInfo.Name) || isempty(patientInfo.ID)
            errordlg('患者姓名和病历号为必填项！', '输入错误');
            return;
        end
        
        % 验证年龄
        if ~isempty(patientInfo.Age)
            ageNum = str2double(patientInfo.Age);
            if isnan(ageNum) || ageNum < 0 || ageNum > 150
                errordlg('请输入有效的年龄！', '输入错误');
                return;
            end
        end
        
        delete(dlg);
    end
end

%% ========== 界面创建函数 ==========
function createTitleBar(fig)
    titlePanel = uipanel('Parent', fig, ...
                        'Position', [0, 0.92, 1, 0.08], ...
                        'BackgroundColor', [0, 0.3, 0.5], ...
                        'BorderType', 'none');
    
    uicontrol('Parent', titlePanel, ...
             'Style', 'text', ...
             'String', 'DSA脑血流灌注分析系统', ...
             'Position', [0, 5, 1400, 50], ...
             'FontSize', 26, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [1, 1, 1], ...
             'BackgroundColor', [0, 0.3, 0.5], ...
             'HorizontalAlignment', 'center');
    
    uicontrol('Parent', titlePanel, ...
             'Style', 'text', ...
             'String', '基于TDC标准的高灌注风险评估系统', ...
             'Position', [0, -15, 1400, 30], ...
             'FontSize', 10, ...
             'ForegroundColor', [0.8, 0.9, 1], ...
             'BackgroundColor', [0, 0.3, 0.5], ...
             'HorizontalAlignment', 'center');
end

function createControlButtons(parent)
    % 面板标题
    uicontrol('Parent', parent, ...
             'Style', 'text', ...
             'String', '分析流程控制', ...
             'Position', [10, 750, 240, 30], ...
             'FontSize', 16, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [1, 1, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'center');
    
    % 按钮参数 - 调整按钮高度和间距以腾出空间
    buttonWidth = 215;   % 稍微减小宽度
    buttonHeight = 30;   % 稍微减小高度
    startY = 680;
    spacing = 10;       % 减小间距
    groupSpacing = 18;  % 减小组间距
    
    % 第一组：数据导入和准备
    uicontrol('Parent', parent, ...
             'Style', 'text', ...
             'String', '数据准备', ...
             'Position', [10, startY + 5, 100, 20], ...  % 调整位置
             'FontSize', 12, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [0.8, 0.9, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'left');
    
    buttonsGroup1 = {
        {'导入DSA数据', @importDSA, [0.2, 0.6, 0.8]}, ...
        {'选择分析帧', @selectFrames, [0.2, 0.6, 0.8]}
    };
    
    createButtonGroup(parent, buttonsGroup1, startY, buttonWidth, buttonHeight, spacing);
    
    % 第二组：ROI操作
    uicontrol('Parent', parent, ...
             'Style', 'text', ...
             'String', 'ROI分析', ...
             'Position', [10, startY - 2*(buttonHeight+spacing) + 5, 100, 20], ...
             'FontSize', 12, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [0.8, 0.9, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'left');
    
    buttonsGroup2 = {
        {'放置ROI', @placeROI, [0.3, 0.7, 0.3]}, ...
        {'提取TDC', @extractTDC, [0.8, 0.6, 0.2]}
    };
    
    createButtonGroup(parent, buttonsGroup2, startY - 2*(buttonHeight+spacing), buttonWidth, buttonHeight, spacing);
    
    % 第三组：分析和结果显示
    uicontrol('Parent', parent, ...
             'Style', 'text', ...
             'String', '分析显示', ...
             'Position', [10, startY - 4*(buttonHeight+spacing) - groupSpacing + 5, 100, 20], ...
             'FontSize', 12, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [0.8, 0.9, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'left');
    
    buttonsGroup3 = {
        {'分析曲线', @analyzeCurves, [0.8, 0.6, 0.2]}, ...
        {'显示结果', @showResults, [0.7, 0.5, 0.9]}
    };
    
    createButtonGroup(parent, buttonsGroup3, startY - 4*(buttonHeight+spacing) - groupSpacing, buttonWidth, buttonHeight, spacing);
    
    % 第四组：数据管理
    uicontrol('Parent', parent, ...
             'Style', 'text', ...
             'String', '数据管理', ...
             'Position', [10, startY - 6*(buttonHeight+spacing) - 2*groupSpacing + 5, 100, 20], ...
             'FontSize', 12, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [0.8, 0.9, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'left');
    
    buttonsGroup4 = {
        {'导出数据', @exportData, [0.4, 0.4, 0.6]}, ...
        {'术前术后对比', @comparePrePost, [0.9, 0.3, 0.3]}
    };
    
    createButtonGroup(parent, buttonsGroup4, startY - 6*(buttonHeight+spacing) - 2*groupSpacing, buttonWidth, buttonHeight, spacing);
    
    % 第五组：系统操作 - 调整位置，为工作日志腾出空间
    uicontrol('Parent', parent, ...
             'Style', 'text', ...
             'String', '系统操作', ...
             'Position', [10, startY - 8*(buttonHeight+spacing) - 3*groupSpacing + 5, 100, 20], ...
             'FontSize', 12, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [0.8, 0.9, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'left');
    
    buttonsGroup5 = {
        {'重置所有', @resetAll, [0.8, 0.2, 0.2]}, ...
        {'使用帮助', @showHelp, [0.2, 0.6, 0.8]}
    };
    
    createButtonGroup(parent, buttonsGroup5, startY - 8*(buttonHeight+spacing) - 3*groupSpacing, buttonWidth, buttonHeight, spacing);
    
    % 添加工作日志面板 - 调整到最底部（不使用系统状态面板）
    createWorkLog(parent, 10);
end

function createButtonGroup(parent, buttons, startY, width, height, spacing)
    for i = 1:length(buttons)
        buttonInfo = buttons{i};
        yPos = startY - (i-1) * (height + spacing);
        
        uicontrol('Parent', parent, ...
                 'Style', 'pushbutton', ...
                 'String', buttonInfo{1}, ...
                 'Position', [10, yPos, width, height], ...
                 'FontSize', 11, ...
                 'FontWeight', 'bold', ...
                 'BackgroundColor', buttonInfo{3}, ...
                 'ForegroundColor', [1, 1, 1], ...
                 'Callback', buttonInfo{2});
    end
end

function createWorkLog(parent, startY)
    % 工作日志面板 - 调整位置和大小，延伸到底部
    workLogPanel = uipanel('Parent', parent, ...
                         'Title', '操作日志', ...
                         'Units', 'pixels', ...
                         'Position', [10, startY, 215, 200], ...  % 增加高度到底部
                         'BackgroundColor', [0.15, 0.25, 0.35], ...
                         'ForegroundColor', [1, 1, 1], ...
                         'FontSize', 11, ...
                         'FontWeight', 'bold');
    
    % 工作日志文本框 - 保持原有位置和大小
    workLogText = uicontrol('Parent', workLogPanel, ...
                          'Style', 'listbox', ...
                          'String', {'系统初始化完成', '欢迎使用DSA分析系统'}, ...
                          'Position', [10, 30, 195, 115], ...  % 保持原有位置和大小
                          'FontSize', 9, ...  % 增大字体
                          'BackgroundColor', [0.05, 0.1, 0.15], ...
                          'ForegroundColor', [0.8, 0.9, 1], ...
                          'Max', 100, ...
                          'Min', 0);
    
    % 日志控制按钮 - 调整位置
    uicontrol('Parent', workLogPanel, ...
             'Style', 'pushbutton', ...
             'String', '清空', ...
             'Position', [10, 5, 55, 20], ...
             'FontSize', 8, ...
             'BackgroundColor', [0.6, 0.2, 0.2], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', @clearWorkLog);
    
    uicontrol('Parent', workLogPanel, ...
             'Style', 'pushbutton', ...
             'String', '导出', ...
             'Position', [72, 5, 55, 20], ...
             'FontSize', 8, ...
             'BackgroundColor', [0.2, 0.5, 0.8], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', @exportWorkLog);
    
    uicontrol('Parent', workLogPanel, ...
             'Style', 'pushbutton', ...
             'String', '详细', ...
             'Position', [134, 5, 55, 20], ...
             'FontSize', 8, ...
             'BackgroundColor', [0.2, 0.6, 0.3], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', @showDetailedLog);
    
    % 存储工作日志句柄
    setappdata(gcf, 'workLogText', workLogText);
    
    % 初始化工作日志数据
    workLogData = {
        sprintf('[%s] 系统初始化完成', datestr(now, 'HH:MM:SS'))
        sprintf('[%s] 欢迎使用DSA脑血流灌注分析系统 v3.0', datestr(now, 'HH:MM:SS'))
    };
    setappdata(gcf, 'workLogData', workLogData);
    
    % 清空日志回调函数
    function clearWorkLog(~,~)
        setappdata(gcf, 'workLogData', {});
        set(workLogText, 'String', {});
        addWorkLog('工作日志已清空');
    end
    
    % 导出日志回调函数
    function exportWorkLog(~,~)
        workLogData = getappdata(gcf, 'workLogData');
        if isempty(workLogData)
            errordlg('工作日志为空，无法导出');
            return;
        end
        
        [file, path] = uiputfile({'*.txt','文本文件 (*.txt)'; ...
                                 '*.log','日志文件 (*.log)'}, ...
                                '导出工作日志');
        if isequal(file, 0)
            return;
        end
        
        try
            fullPath = fullfile(path, file);
            fid = fopen(fullPath, 'w');
            if fid == -1
                error('无法创建文件');
            end
            
            % 写入日志头信息
            fprintf(fid, 'DSA脑血流灌注分析系统 - 工作日志\n');
            fprintf(fid, '导出时间: %s\n', datestr(now));
            fprintf(fid, '========================================\n\n');
            
            % 写入日志内容
            for i = 1:length(workLogData)
                fprintf(fid, '%s\n', workLogData{i});
            end
            
            fclose(fid);
            addWorkLog(sprintf('工作日志已导出: %s', file));
            msgbox('工作日志导出成功！', '成功');
            
        catch ME
            errordlg(sprintf('导出失败: %s', ME.message));
        end
    end
    
    % 显示详细日志回调函数
    function showDetailedLog(~,~)
        workLogData = getappdata(gcf, 'workLogData');
        if isempty(workLogData)
            msgbox('工作日志为空', '工作日志');
            return;
        end
        
        % 创建详细日志窗口
        logFig = figure('Name', '详细工作日志', ...
                       'NumberTitle', 'off', ...
                       'Position', [300, 200, 800, 600], ...
                       'MenuBar', 'none', ...
                       'ToolBar', 'none', ...
                       'Color', [0.95, 0.95, 0.95]);
        
        % 日志显示区域
        logText = uicontrol('Parent', logFig, ...
                          'Style', 'listbox', ...
                          'String', workLogData, ...
                          'Position', [20, 50, 760, 500], ...
                          'FontSize', 10, ...
                          'BackgroundColor', [1, 1, 1], ...
                          'ForegroundColor', [0.1, 0.1, 0.1], ...
                          'Max', 2);
        
        % 统计信息
        totalEntries = length(workLogData);
        todayEntries = sum(contains(workLogData, datestr(now, 'yyyy-mm-dd')));
        
        infoText = sprintf('总日志条目: %d | 今日条目: %d', totalEntries, todayEntries);
        
        uicontrol('Parent', logFig, ...
                 'Style', 'text', ...
                 'String', infoText, ...
                 'Position', [20, 560, 300, 25], ...
                 'FontSize', 11, ...
                 'FontWeight', 'bold', ...
                 'BackgroundColor', [0.95, 0.95, 0.95], ...
                 'HorizontalAlignment', 'left');
        
        % 控制按钮
        uicontrol('Parent', logFig, ...
                 'Style', 'pushbutton', ...
                 'String', '导出日志', ...
                 'Position', [600, 560, 80, 25], ...
                 'FontSize', 10, ...
                 'BackgroundColor', [0.2, 0.5, 0.8], ...
                 'ForegroundColor', [1, 1, 1], ...
                 'Callback', @exportWorkLog);
        
        uicontrol('Parent', logFig, ...
                 'Style', 'pushbutton', ...
                 'String', '关闭', ...
                 'Position', [690, 560, 80, 25], ...
                 'FontSize', 10, ...
                 'BackgroundColor', [0.8, 0.2, 0.2], ...
                 'ForegroundColor', [1, 1, 1], ...
                 'Callback', 'delete(gcf)');
    end
end

function createStatusIndicator(parent)
    % 系统状态 - 调整到最底部
    statusPanel = uipanel('Parent', parent, ...
                         'Title', '系统状态', ...
                         'Position', [10, 10, 220, 80], ...  % 减小高度
                         'BackgroundColor', [0.15, 0.25, 0.35], ...
                         'ForegroundColor', [1, 1, 1], ...
                         'FontSize', 11, ...
                         'FontWeight', 'bold');
    
    % 状态指示灯
    uicontrol('Parent', statusPanel, ...
             'Style', 'text', ...
             'String', '状态:', ...
             'Position', [10, 45, 40, 20], ...
             'FontSize', 10, ...
             'ForegroundColor', [1, 1, 1], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'left');
    
    statusLight = uicontrol('Parent', statusPanel, ...
                          'Style', 'text', ...
                          'String', '●', ...
                          'Position', [55, 45, 30, 20], ...
                          'FontSize', 18, ...
                          'ForegroundColor', [0, 1, 0], ...
                          'BackgroundColor', [0.15, 0.25, 0.35], ...
                          'HorizontalAlignment', 'center');
    
    % 操作日志
    uicontrol('Parent', statusPanel, ...
             'Style', 'text', ...
             'String', '操作日志:', ...
             'Position', [10, 20, 60, 20], ...
             'FontSize', 10, ...
             'ForegroundColor', [1, 1, 1], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'left');
    
    resultsText = uicontrol('Parent', statusPanel, ...
                          'Style', 'listbox', ...
                          'String', {'系统初始化完成', '就绪...'}, ...
                          'Position', [10, 5, 200, 15], ...  % 减小高度
                          'FontSize', 8, ...
                          'BackgroundColor', [0.05, 0.1, 0.15], ...
                          'ForegroundColor', [0.8, 0.9, 1]);
    
    % 存储句柄
    setappdata(gcf, 'resultsText', resultsText);
    setappdata(gcf, 'statusLight', statusLight);
end

function createDisplayArea(parent)
    % 主图像显示
    mainAxes = axes('Parent', parent, ...
                   'Position', [0.05, 0.05, 0.9, 0.9], ...
                   'Color', [0.05, 0.1, 0.15], ...
                   'XColor', [0.8, 0.9, 1], ...
                   'YColor', [0.8, 0.9, 1]);
    axis(mainAxes, 'image');
    colormap(mainAxes, 'gray');
    title(mainAxes, 'DICOM影像显示区域', 'Color', [1, 1, 1], 'FontSize', 14);
    
    % 存储句柄
    setappdata(gcf, 'mainAxes', mainAxes);
end
%% ========== 界面创建函数 ==========
function createInfoArea(parent, patientInfo)
    % 患者信息面板 - 调整高度和位置
    patientPanel = uipanel('Parent', parent, ...
                          'Title', '患者信息', ...
                          'Position', [0.05, 0.75, 0.9, 0.24], ...
                          'BackgroundColor', [0.15, 0.25, 0.35], ...
                          'ForegroundColor', [1, 1, 1], ...
                          'FontSize', 11, ...
                          'FontWeight', 'bold');
    
    % 帧控制面板 - 调整高度和位置
    framePanel = uipanel('Parent', parent, ...
                        'Title', '帧控制', ...
                        'Position', [0.05, 0.55, 0.9, 0.19], ...  % 调整位置和高度
                        'BackgroundColor', [0.15, 0.25, 0.35], ...
                        'ForegroundColor', [1, 1, 1], ...
                        'FontSize', 11, ...
                        'FontWeight', 'bold');
    
    % 分析参数面板 - 调整高度和位置
    paramPanel = uipanel('Parent', parent, ...
                        'Title', '灌注参数', ...
                        'Position', [0.05, 0.36, 0.9, 0.19], ...  % 调整位置，确保不重叠
                        'BackgroundColor', [0.15, 0.25, 0.35], ...
                        'ForegroundColor', [1, 1, 1], ...
                        'FontSize', 11, ...
                        'FontWeight', 'bold');
    
    % 风险评估面板 - 整体下移，高度保持不变
    riskPanel = uipanel('Parent', parent, ...
                       'Title', '高灌注风险评估', ...
                       'Position', [0.05, 0.05, 0.9, 0.30], ...  % 整体下移，高度保持不变
                       'BackgroundColor', [0.15, 0.25, 0.35], ...
                       'ForegroundColor', [1, 1, 1], ...
                       'FontSize', 11, ...
                       'FontWeight', 'bold');
    
    % 初始化各面板内容
    initPatientInfo(patientPanel, patientInfo);
    initFrameControl(framePanel);
    initParamDisplay(paramPanel);
    initRiskDisplay(riskPanel);
end

function initPatientInfo(panel, patientInfo)
    % 患者信息表格布局 - 增加行间距
    infoFields = {'姓名:', '病历号:', '年龄:', '性别:', '诊断:', '检查日期:'};
    infoValues = {patientInfo.Name, patientInfo.ID, patientInfo.Age, ...
                 patientInfo.Gender, patientInfo.Diagnosis, patientInfo.StudyDate};
    
    for i = 1:length(infoFields)
        yPos = 160 - (i-1)*22;  % 增加行间距从15到22
        
        uicontrol('Parent', panel, ...
                 'Style', 'text', ...
                 'String', infoFields{i}, ...
                 'Position', [10, yPos, 50, 18], ...
                 'FontSize', 10, ...
                 'ForegroundColor', [1, 1, 1], ...
                 'BackgroundColor', [0.15, 0.25, 0.35], ...
                 'HorizontalAlignment', 'left');
        
        uicontrol('Parent', panel, ...
                 'Style', 'text', ...
                 'String', infoValues{i}, ...
                 'Position', [65, yPos, 160, 18], ...
                 'FontSize', 10, ...
                 'ForegroundColor', [0.8, 0.9, 1], ...
                 'BackgroundColor', [0.15, 0.25, 0.35], ...
                 'HorizontalAlignment', 'left', ...
                 'Tag', ['patientInfo_' num2str(i)]);
    end
    
    % 数据状态 - 调整位置
    uicontrol('Parent', panel, ...
             'Style', 'text', ...
             'String', '数据状态:', ...
             'Position', [10, 30, 50, 18], ...
             'FontSize', 10, ...
             'ForegroundColor', [1, 1, 1], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'left');
    
    uicontrol('Parent', panel, ...
             'Style', 'text', ...
             'String', '术前:未加载 术后:未加载', ...
             'Position', [65, 30, 160, 18], ...
             'FontSize', 10, ...
             'ForegroundColor', [1, 0.8, 0.8], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'left', ...
             'Tag', 'dataStatus');
end

function initFrameControl(panel)
    % 当前帧显示 - 调整位置
    uicontrol('Parent', panel, ...
              'Style', 'text', ...
              'String', '当前帧:', ...
              'Position', [10, 130, 50, 22], ...  % 调整Y坐标
              'FontSize', 11, ...
              'ForegroundColor', [1, 1, 1], ...
              'BackgroundColor', [0.15, 0.25, 0.35], ...
              'HorizontalAlignment', 'left');

    currentFrameText = uicontrol('Parent', panel, ...
                                'Style', 'text', ...
                                'String', '1', ...
                                'Position', [65, 130, 35, 22], ...
                                'FontSize', 11, ...
                                'FontWeight', 'bold', ...
                                'ForegroundColor', [1, 1, 1], ...
                                'BackgroundColor', [0.2, 0.4, 0.6], ...
                                'HorizontalAlignment', 'center');

    uicontrol('Parent', panel, ...
              'Style', 'text', ...
              'String', '/', ...
              'Position', [105, 130, 10, 22], ...
              'FontSize', 11, ...
              'ForegroundColor', [1, 1, 1], ...
              'BackgroundColor', [0.15, 0.25, 0.35], ...
              'HorizontalAlignment', 'center');

    totalFramesText = uicontrol('Parent', panel, ...
                               'Style', 'text', ...
                               'String', '1', ...
                               'Position', [120, 130, 35, 22], ...
                               'FontSize', 11, ...
                               'ForegroundColor', [1, 1, 1], ...
                               'BackgroundColor', [0.15, 0.25, 0.35], ...
                               'HorizontalAlignment', 'center');

    % 帧数滑块 - 调整位置
    frameSlider = uicontrol('Parent', panel, ...
                           'Style', 'slider', ...
                           'Position', [10, 100, 200, 22], ...  % 调整Y坐标
                           'Min', 1, 'Max', 100, 'Value', 1, ...
                           'SliderStep', [0.01, 0.1], ...
                           'Enable', 'off', ...
                           'Callback', @updateFrameFromSlider);

    % 播放控制按钮 - 调整位置
    playBtn = uicontrol('Parent', panel, ...
                       'Style', 'pushbutton', ...
                       'String', '播放', ...
                       'Position', [10, 65, 50, 28], ...  % 调整Y坐标
                       'FontSize', 11, ...
                       'BackgroundColor', [0.2, 0.7, 0.2], ...
                       'ForegroundColor', [1, 1, 1], ...
                       'Enable', 'off', ...
                       'Callback', @togglePlayback);

    pauseBtn = uicontrol('Parent', panel, ...
                        'Style', 'pushbutton', ...
                        'String', '暂停', ...
                        'Position', [65, 65, 50, 28], ...
                        'FontSize', 11, ...
                        'BackgroundColor', [0.8, 0.6, 0.2], ...
                        'ForegroundColor', [1, 1, 1], ...
                        'Enable', 'off', ...
                        'Callback', @stopPlayback);

    % 帧导航按钮 - 调整位置，确保不超出面板
    firstFrameBtn = uicontrol('Parent', panel, ...
              'Style', 'pushbutton', ...
              'String', '<<', ...
              'Position', [115, 65, 30, 28], ...
              'FontSize', 9, ...
              'BackgroundColor', [0.3, 0.5, 0.7], ...
              'ForegroundColor', [1, 1, 1], ...
              'Enable', 'off', ...
              'Callback', @goToFirstFrame);

    prevFrameBtn = uicontrol('Parent', panel, ...
              'Style', 'pushbutton', ...
              'String', '<', ...
              'Position', [150, 65, 28, 28], ...
              'FontSize', 9, ...
              'BackgroundColor', [0.3, 0.5, 0.7], ...
              'ForegroundColor', [1, 1, 1], ...
              'Enable', 'off', ...
              'Callback', @goToPrevFrame);

    nextFrameBtn = uicontrol('Parent', panel, ...
              'Style', 'pushbutton', ...
              'String', '>', ...
              'Position', [182, 65, 28, 28], ...
              'FontSize', 9, ...
              'BackgroundColor', [0.3, 0.5, 0.7], ...
              'ForegroundColor', [1, 1, 1], ...
              'Enable', 'off', ...
              'Callback', @goToNextFrame);

    lastFrameBtn = uicontrol('Parent', panel, ...
              'Style', 'pushbutton', ...
              'String', '>>', ...
              'Position', [214, 65, 30, 28], ...
              'FontSize', 9, ...
              'BackgroundColor', [0.3, 0.5, 0.7], ...
              'ForegroundColor', [1, 1, 1], ...
              'Enable', 'off', ...
              'Callback', @goToLastFrame);

    % 帧范围选择 - 调整位置
    uicontrol('Parent', panel, ...
              'Style', 'text', ...
              'String', '分析范围:', ...
              'Position', [10, 30, 60, 22], ...  % 调整Y坐标
              'FontSize', 10, ...
              'ForegroundColor', [1, 1, 1], ...
              'BackgroundColor', [0.15, 0.25, 0.35], ...
              'HorizontalAlignment', 'left');

    startFrameEdit = uicontrol('Parent', panel, 'Style', 'edit', ...
                              'String', '1', ...
                              'Position', [75, 30, 35, 22], ...
                              'FontSize', 10, ...
                              'BackgroundColor', [1, 1, 1], ...
                              'Enable', 'off', ...
                              'Callback', @validateFrameInput);

    uicontrol('Parent', panel, ...
              'Style', 'text', ...
              'String', '-', ...
              'Position', [115, 30, 10, 22], ...
              'FontSize', 10, ...
              'ForegroundColor', [1, 1, 1], ...
              'BackgroundColor', [0.15, 0.25, 0.35], ...
              'HorizontalAlignment', 'center');

    endFrameEdit = uicontrol('Parent', panel, 'Style', 'edit', ...
                            'String', '1', ...
                            'Position', [130, 30, 35, 22], ...
                            'FontSize', 10, ...
                            'BackgroundColor', [1, 1, 1], ...
                            'Enable', 'off', ...
                            'Callback', @validateFrameInput);

    applyRangeBtn = uicontrol('Parent', panel, 'Style', 'pushbutton', ...
              'String', '应用', ...
              'Position', [170, 30, 40, 22], ...
              'Callback', @applyFrameRange, ...
              'BackgroundColor', [0.2, 0.7, 0.2], ...
              'ForegroundColor', [1, 1, 1], ...
              'FontSize', 9, ...
              'Enable', 'off');

    % 存储句柄
    setappdata(gcf, 'frameSlider', frameSlider);
    setappdata(gcf, 'currentFrameText', currentFrameText);
    setappdata(gcf, 'totalFramesText', totalFramesText);
    setappdata(gcf, 'playBtn', playBtn);
    setappdata(gcf, 'pauseBtn', pauseBtn);
    setappdata(gcf, 'firstFrameBtn', firstFrameBtn);
    setappdata(gcf, 'prevFrameBtn', prevFrameBtn);
    setappdata(gcf, 'nextFrameBtn', nextFrameBtn);
    setappdata(gcf, 'lastFrameBtn', lastFrameBtn);
    setappdata(gcf, 'startFrameEdit', startFrameEdit);
    setappdata(gcf, 'endFrameEdit', endFrameEdit);
    setappdata(gcf, 'applyRangeBtn', applyRangeBtn);
    
    % 初始化播放状态
    setappdata(gcf, 'isPlaying', false);
    setappdata(gcf, 'playTimer', []);
end

function initParamDisplay(panel)
    % 创建参数显示表格 - 调整大小以适应面板
    paramTable = uitable('Parent', panel, ...
                        'Position', [5, 5, 255, 115], ...  % 调整位置和大小
                        'FontSize', 9, ...  % 减小字体以便更多内容可见
                        'BackgroundColor', [0.1, 0.2, 0.3], ...
                        'ForegroundColor', [1, 1, 1]);
    
    setappdata(gcf, 'paramTable', paramTable);
    
    % 初始化表格数据
    updateParamTable(); % 调用更新函数来初始化表格
end

function initRiskDisplay(panel)
    % 高灌注风险评估显示 - 调整位置和大小
    
    uicontrol('Parent', panel, ...
             'Style', 'text', ...
             'String', '风险评估结果:', ...
             'Position', [10, 170, 90, 22], ...  % 下移以完整显示
             'FontSize', 11, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [1, 1, 1], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'left');
    
    riskResultText = uicontrol('Parent', panel, ...
             'Style', 'text', ...
             'String', '未评估', ...
             'Position', [105, 170, 100, 22], ...  % 下移以完整显示
             'FontSize', 11, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [1, 1, 0], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'center');
    setappdata(gcf, 'riskResultText', riskResultText);
    
    % ROI状态显示 - 下移避免被截断
    uicontrol('Parent', panel, ...
             'Style', 'text', ...
             'String', 'ROI状态:', ...
             'Position', [10, 143, 60, 22], ...  % 下移以完整显示
             'FontSize', 10, ...
             'ForegroundColor', [1, 1, 1], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'left');
    
    preOpROIStatus = uicontrol('Parent', panel, ...
             'Style', 'text', ...
             'String', '术前:未标定', ...
             'Position', [75, 143, 70, 22], ...  % 下移以完整显示
             'FontSize', 9, ...
             'ForegroundColor', [1, 0.8, 0.8], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'left');
    setappdata(gcf, 'preOpROIStatus', preOpROIStatus);
    
    postOpROIStatus = uicontrol('Parent', panel, ...
             'Style', 'text', ...
             'String', '术后:未标定', ...
             'Position', [150, 143, 70, 22], ...  % 下移以完整显示
             'FontSize', 9, ...
             'ForegroundColor', [1, 0.8, 0.8], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'left');
    setappdata(gcf, 'postOpROIStatus', postOpROIStatus);
    
    % 风险等级说明 - 下移确保完整显示
    riskText = {
        '风险评估标准:'
        '高风险: ≥150%'
        '中风险: 120-149%' 
        '低风险: 100-119%'
        '无风险: < 100%'
    };
    
    uicontrol('Parent', panel, ...
             'Style', 'text', ...
             'String', riskText, ...
             'Position', [10, 40, 240, 95], ...  % 下移确保完整显示
             'FontSize', 9, ...
             'ForegroundColor', [0.8, 0.9, 1], ...
             'BackgroundColor', [0.15, 0.25, 0.35], ...
             'HorizontalAlignment', 'left');
end

% initLogDisplay 函数已移除 - 操作日志现在在左侧面板的 workLog 中

%% ========== 日志更新函数 ==========
function updateLog(message)
    % 日志现在通过 addWorkLog 更新到左侧面板
    addWorkLog(message);
end

%% ========== 系统状态更新函数 ==========
function updateStatus(message)
    resultsText = getappdata(gcf, 'resultsText');
    if isempty(resultsText) || ~ishandle(resultsText)
        return;
    end
    
    currentText = get(resultsText, 'String');
    if ischar(currentText)
        currentText = {currentText};
    end
    
    timestamp = datestr(now, 'HH:MM:SS');
    newMessage = sprintf('[%s] %s', timestamp, message);
    
    newText = [currentText; {newMessage}];
    
    if length(newText) > 15
        newText = newText(end-14:end);
    end
    
    set(resultsText, 'String', newText);
    set(resultsText, 'Value', length(newText)); % 滚动到底部
    
    % 同时记录到工作日志（重要操作）
    if contains(message, {'导入', '导出', '完成', '失败', '错误', '分析', '提取', '放置', '重置', '对比'})
        addWorkLog(message);
    end
    drawnow;
end
%% ========== 帧控制相关回调函数 ==========
function updateFrameFromSlider(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        return;
    end
    
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    
    if ishandle(frameSlider)
        currentFrame = round(get(frameSlider, 'Value'));
        currentFrame = max(1, min(currentFrame, data.totalFrames));
        data.currentFrame = currentFrame;
        guidata(fig, data);
        
        % 更新当前帧显示
        if ishandle(currentFrameText)
            set(currentFrameText, 'String', num2str(currentFrame));
        end
    end
    
    updateFrameDisplay();
end

function togglePlayback(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        return;
    end
    
    isPlaying = getappdata(fig, 'isPlaying');
    playBtn = getappdata(fig, 'playBtn');
    pauseBtn = getappdata(fig, 'pauseBtn');
    
    if isPlaying
        % 停止播放
        stopPlayback();
    else
        % 开始播放
        setappdata(fig, 'isPlaying', true);
        set(playBtn, 'Enable', 'off', 'BackgroundColor', [0.5, 0.5, 0.5]);
        set(pauseBtn, 'Enable', 'on', 'BackgroundColor', [0.8, 0.6, 0.2]);
        
        % 创建定时器
        frameRateEdit = getappdata(fig, 'frameRateEdit');
        if ishandle(frameRateEdit)
            frameRate = str2double(get(frameRateEdit, 'String'));
        else
            frameRate = 4;
        end
        interval = 1 / frameRate;
        
        timerObj = timer('ExecutionMode', 'fixedRate', ...
                        'Period', interval, ...
                        'TimerFcn', @(~,~) advanceFrame());
        setappdata(fig, 'playTimer', timerObj);
        start(timerObj);
        
        updateStatus(sprintf('开始播放序列 (%.1f fps)', frameRate));
    end
end

function stopPlayback(~,~)
    fig = gcf;
    playBtn = getappdata(fig, 'playBtn');
    pauseBtn = getappdata(fig, 'pauseBtn');
    timerObj = getappdata(fig, 'playTimer');
    
    if ~isempty(timerObj) && isvalid(timerObj)
        stop(timerObj);
        delete(timerObj);
    end
    
    setappdata(fig, 'isPlaying', false);
    setappdata(fig, 'playTimer', []);
    
    set(playBtn, 'Enable', 'on', 'BackgroundColor', [0.2, 0.7, 0.2]);
    set(pauseBtn, 'Enable', 'off', 'BackgroundColor', [0.5, 0.5, 0.5]);
    
    updateStatus('停止播放序列');
end

function advanceFrame()
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        stopPlayback();
        return;
    end
    
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    
    % 前进到下一帧，如果到达最后一帧则回到第一帧
    nextFrame = data.currentFrame + 1;
    if nextFrame > data.totalFrames
        nextFrame = 1;
    end
    
    data.currentFrame = nextFrame;
    guidata(fig, data);
    
    if ishandle(frameSlider)
        set(frameSlider, 'Value', nextFrame);
    end
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', num2str(nextFrame));
    end
    
    updateFrameDisplay();
end

function goToFirstFrame(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        return;
    end
    
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    
    data.currentFrame = 1;
    guidata(fig, data);
    
    if ishandle(frameSlider)
        set(frameSlider, 'Value', 1);
    end
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', '1');
    end
    
    updateFrameDisplay();
    updateStatus('跳转到第一帧');
end

function goToPrevFrame(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        return;
    end
    
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    
    prevFrame = max(1, data.currentFrame - 1);
    data.currentFrame = prevFrame;
    guidata(fig, data);
    
    if ishandle(frameSlider)
        set(frameSlider, 'Value', prevFrame);
    end
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', num2str(prevFrame));
    end
    
    updateFrameDisplay();
    updateStatus(sprintf('跳转到前一帧: %d', prevFrame));
end

function goToNextFrame(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        return;
    end
    
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    
    nextFrame = min(data.totalFrames, data.currentFrame + 1);
    data.currentFrame = nextFrame;
    guidata(fig, data);
    
    if ishandle(frameSlider)
        set(frameSlider, 'Value', nextFrame);
    end
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', num2str(nextFrame));
    end
    
    updateFrameDisplay();
    updateStatus(sprintf('跳转到后一帧: %d', nextFrame));
end

function goToLastFrame(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        return;
    end
    
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    
    data.currentFrame = data.totalFrames;
    guidata(fig, data);
    
    if ishandle(frameSlider)
        set(frameSlider, 'Value', data.totalFrames);
    end
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', num2str(data.totalFrames));
    end
    
    updateFrameDisplay();
    updateStatus(sprintf('跳转到最后一帧: %d', data.totalFrames));
end

function validateFrameInput(~,~)
    fig = gcf;
    data = guidata(fig);
    
    startFrameEdit = getappdata(fig, 'startFrameEdit');
    endFrameEdit = getappdata(fig, 'endFrameEdit');
    
    if ishandle(startFrameEdit)
        startFrame = str2double(get(startFrameEdit, 'String'));
    else
        return;
    end
    if ishandle(endFrameEdit)
        endFrame = str2double(get(endFrameEdit, 'String'));
    else
        return;
    end
    
    if isnan(startFrame) || startFrame < 1
        set(startFrameEdit, 'String', '1');
    elseif startFrame > data.totalFrames
        set(startFrameEdit, 'String', num2str(data.totalFrames));
    end
    
    if isnan(endFrame) || endFrame < 1
        set(endFrameEdit, 'String', '1');
    elseif endFrame > data.totalFrames
        set(endFrameEdit, 'String', num2str(data.totalFrames));
    end
end

function applyFrameRange(~,~)
    fig = gcf;
    data = guidata(fig);
    
    try
        startFrameEdit = getappdata(fig, 'startFrameEdit');
        endFrameEdit = getappdata(fig, 'endFrameEdit');
        frameSlider = getappdata(fig, 'frameSlider');
        currentFrameText = getappdata(fig, 'currentFrameText');
        
        if ishandle(startFrameEdit)
            startFrame = str2double(get(startFrameEdit, 'String'));
        else
            return;
        end
        if ishandle(endFrameEdit)
            endFrame = str2double(get(endFrameEdit, 'String'));
        else
            return;
        end
        
        if isnan(startFrame) || isnan(endFrame) || startFrame < 1 || endFrame > data.totalFrames || startFrame > endFrame
            errordlg('请输入有效的帧范围');
            return;
        end
        
        data.startFrame = startFrame;
        data.endFrame = endFrame;
        data.currentFrame = startFrame;
        guidata(fig, data);
        
        if ishandle(frameSlider)
            set(frameSlider, 'Value', startFrame);
        end
        if ishandle(currentFrameText)
            set(currentFrameText, 'String', num2str(startFrame));
        end
        
        updateFrameDisplay();
        updateStatus(sprintf('已应用帧范围: %d-%d', startFrame, endFrame));
        
    catch ME
        errordlg(sprintf('应用帧范围失败: %s', ME.message));
    end
end

function updateFrameDisplay()
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        return;
    end
    
    currentFrame = data.currentFrame;
    
    % 获取当前帧图像
    if ~isempty(data.processedSeries)
        % 使用processedSeries
        currentImg = data.processedSeries(:,:,currentFrame);
    elseif ~isempty(data.img4D)
        % 从原始4D数据中提取并反转
        if ndims(data.img4D) == 4
            frameData = data.img4D(:,:,1,currentFrame);
        else
            frameData = data.img4D(:,:,currentFrame);
        end
        if isinteger(frameData)
            frameData = double(frameData);
        end
        currentImg = 255 - frameData;
    else
        return;
    end
    
    % 更新显示
    mainAxes = getappdata(fig, 'mainAxes');
    if ishandle(mainAxes)
        axes(mainAxes);
        imagesc(currentImg); 
        colormap(gray); 
        axis image;
        caxis([min(currentImg(:)) max(currentImg(:))]);
        
        % 如果已经放置了ROI，重新绘制ROI
        if isfield(data, 'roiPositions') && ~isempty(data.roiPositions)
            hold on;
            for i = 1:size(data.roiPositions, 1)
                pos = data.roiPositions(i,:);
                lobe = ceil(i/3);
                r = mod(i-1,3)+1;
                color = data.colors(lobe,:);
                rectangle('Position', pos, 'EdgeColor', color, 'LineWidth', 2);
                text(pos(1)+2, pos(2)-8, sprintf('%s-%d', data.lobeNames{lobe}, r),...
                     'Color', color, 'FontWeight', 'bold', 'BackgroundColor', 'white',...
                     'FontSize', 8);
            end
            hold off;
        end
        
        title(sprintf('%s - 帧 %d/%d', data.fileName, currentFrame, data.totalFrames), 'Color', 'white', 'Interpreter', 'none');
    end
    
    % 更新帧数文本
    currentFrameText = getappdata(fig, 'currentFrameText');
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', num2str(currentFrame));
    end
    
    drawnow;
end

%% ========== 主要功能回调函数 ==========
function importDSA(~,~)
    fig = gcf;
    data = guidata(fig);
    
    updateStatus('正在选择DICOM文件...');
    addWorkLog('开始导入DSA数据...');
    
    [fname, pname] = uigetfile({'*.dcm;*.DCM;*.ima;*.IMA','DICOM文件 (*.dcm,*.ima)';...
                               '*.*','所有文件'},...
                              '选择DSA DICOM文件');
    if isequal(fname, 0)
        updateStatus('已取消选择');
        addWorkLog('用户取消了DSA数据导入');
        return; 
    end
    
    fullName = fullfile(pname, fname);
    
    try
        updateStatus('正在读取DICOM文件...');
        info = dicominfo(fullName);
        img = dicomread(fullName);
        
        dims = size(img);
        fprintf('图像维度: %s\n', mat2str(dims));
        
        if ndims(img) == 4
            totalFrames = size(img, 4);
            img2D = img(:,:,1,1);
            img4D = img;
        elseif ndims(img) == 3
            if size(img, 3) > 10
                totalFrames = size(img, 3);
                img2D = img(:,:,1);
                img4D = img;
            else
                totalFrames = 1;
                img2D = img(:,:,1);
                img4D = [];
                warndlg('检测到可能是多切片数据，将作为单帧处理');
            end
        else
            totalFrames = 1;
            img2D = img;
            img4D = [];
            warndlg('检测到单帧2D数据，无法进行时间序列分析');
        end
        
        % 灰度反转（按照张叙论文方法）
        if isinteger(img2D)
            img2D = double(img2D);
        end
        img2D = 255 - img2D;
        
        % 处理整个序列的灰度反转
        processedSeries = [];
        if ~isempty(img4D)
            if ndims(img4D) == 4
                processedSeries = zeros(size(img4D,1), size(img4D,2), size(img4D,4));
                for i = 1:size(img4D, 4)
                    frameData = img4D(:,:,1,i);
                    if isinteger(frameData)
                        frameData = double(frameData);
                    end
                    processedSeries(:,:,i) = 255 - frameData;
                end
            else
                processedSeries = zeros(size(img4D,1), size(img4D,2), size(img4D,3));
                for i = 1:size(img4D, 3)
                    frameData = img4D(:,:,i);
                    if isinteger(frameData)
                        frameData = double(frameData);
                    end
                    processedSeries(:,:,i) = 255 - frameData;
                end
            end
        end
        
        % 更新数据
        data.img2D = img2D;
        data.img4D = img4D;
        data.processedSeries = processedSeries;
        data.info = info;
        data.totalFrames = totalFrames;
        data.currentFrame = 1;
        data.startFrame = 1;
        data.endFrame = totalFrames;
        data.fileName = fname;
        data.filePath = pname;
        data.analysisInfo.timestamp = datestr(now);
        guidata(fig, data);
        
        % 更新UI控件
        updateUIControlsAfterImport(fig, totalFrames);
        
        % 显示图像
        mainAxes = getappdata(fig, 'mainAxes');
        if ishandle(mainAxes)
            axes(mainAxes);
            imagesc(data.img2D); 
            colormap(gray); 
            axis image;
            caxis([min(data.img2D(:)) max(data.img2D(:))]);
            title(sprintf('%s - 帧 1/%d', fname, totalFrames), 'Color', 'white', 'FontSize', 14, 'Interpreter', 'none');
        end
        
        updateStatus(sprintf('成功导入: %s (%d帧)', fname, totalFrames));
        
    catch ME
        errordlg(sprintf('DICOM读取失败: %s', ME.message));
        updateStatus('导入失败');
    end
    % 在成功导入后添加日志
    addWorkLog(sprintf('成功导入DSA数据: %s', fname));
    addWorkLog(sprintf('图像维度: %s', mat2str(dims)));
    addWorkLog(sprintf('总帧数: %d', totalFrames));
end

function updateUIControlsAfterImport(fig, totalFrames)
    % 获取所有控件句柄
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    totalFramesText = getappdata(fig, 'totalFramesText');
    playBtn = getappdata(fig, 'playBtn');
    pauseBtn = getappdata(fig, 'pauseBtn');
    firstFrameBtn = getappdata(fig, 'firstFrameBtn');
    prevFrameBtn = getappdata(fig, 'prevFrameBtn');
    nextFrameBtn = getappdata(fig, 'nextFrameBtn');
    lastFrameBtn = getappdata(fig, 'lastFrameBtn');
    startFrameEdit = getappdata(fig, 'startFrameEdit');
    endFrameEdit = getappdata(fig, 'endFrameEdit');
    applyRangeBtn = getappdata(fig, 'applyRangeBtn');
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    
    % 启用所有帧控制控件
    if totalFrames > 1
        if ishandle(frameSlider)
            set(frameSlider, 'Min', 1, 'Max', totalFrames, 'Value', 1,...
                'SliderStep', [1/max(1,totalFrames-1), 10/max(1,totalFrames-1)],...
                'Enable', 'on');
        end
        if ishandle(playBtn)
            set(playBtn, 'Enable', 'on');
        end
        
        % 启用导航按钮
        if ishandle(firstFrameBtn)
            set(firstFrameBtn, 'Enable', 'on');
        end
        if ishandle(prevFrameBtn)
            set(prevFrameBtn, 'Enable', 'on');
        end
        if ishandle(nextFrameBtn)
            set(nextFrameBtn, 'Enable', 'on');
        end
        if ishandle(lastFrameBtn)
            set(lastFrameBtn, 'Enable', 'on');
        end
    end
    
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', '1');
    end
    if ishandle(totalFramesText)
        set(totalFramesText, 'String', num2str(totalFrames));
    end
    if ishandle(startFrameEdit)
        set(startFrameEdit, 'String', '1', 'Enable', 'on');
    end
    if ishandle(endFrameEdit)
        set(endFrameEdit, 'String', num2str(totalFrames), 'Enable', 'on');
    end
    if ishandle(applyRangeBtn)
        set(applyRangeBtn, 'Enable', 'on');
    end
    if ishandle(frameRateEdit)
        set(frameRateEdit, 'Enable', 'on');
    end
end

function selectFrames(~,~)
    fig = gcf;  % 主界面图形句柄
    data = guidata(fig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        errordlg('没有多帧数据可用');
        return;
    end
    
    updateStatus('正在打开帧选择界面...');
    
    % 创建帧选择窗口
    figSelect = figure('Name','帧数选择',...
                      'NumberTitle','off',...
                      'Position',[400,300,600,500],...
                      'MenuBar','none',...
                      'ToolBar','none',...
                      'Color',[0.95 0.95 0.95]);
    
    % 存储主界面句柄到选择窗口的appdata中
    setappdata(figSelect, 'mainFigure', fig);
    setappdata(figSelect, 'mainData', data);
    
    % 显示第一帧和最后一帧的预览
    subplot(2,2,1);
    if ~isempty(data.processedSeries)
        imgToShow = data.processedSeries(:,:,1);
    else
        if ndims(data.img4D) == 4
            frameData = data.img4D(:,:,1,1);
        else
            frameData = data.img4D(:,:,1);
        end
        if isinteger(frameData)
            frameData = double(frameData);
        end
        imgToShow = 255 - frameData;
    end
    imagesc(imgToShow); colormap(gray); axis image; axis off;
    caxis([min(imgToShow(:)) max(imgToShow(:))]);
    title('第一帧');
    
    subplot(2,2,2);
    if ~isempty(data.processedSeries)
        imgToShow = data.processedSeries(:,:,data.totalFrames);
    else
        if ndims(data.img4D) == 4
            frameData = data.img4D(:,:,1,data.totalFrames);
        else
            frameData = data.img4D(:,:,data.totalFrames);
        end
        if isinteger(frameData)
            frameData = double(frameData);
        end
        imgToShow = 255 - frameData;
    end
    imagesc(imgToShow); colormap(gray); axis image; axis off;
    caxis([min(imgToShow(:)) max(imgToShow(:))]);
    title('最后一帧');
    
    % 帧范围选择面板
    uipanel('Parent',figSelect,'Title','帧范围选择',...
           'Position',[0.1 0.4 0.8 0.25],...
           'BackgroundColor',[0.9 0.9 0.9]);
    
    uicontrol(figSelect,'Style','text','String','起始帧:',...
             'Position',[50,150,60,20],'HorizontalAlignment','left');
    
    startEdit = uicontrol(figSelect,'Style','edit','String','1',...
                         'Position',[120,150,60,25],'BackgroundColor',[1,1,1]);
    
    uicontrol(figSelect,'Style','text','String','结束帧:',...
             'Position',[200,150,60,20],'HorizontalAlignment','left');
    
    endEdit = uicontrol(figSelect,'Style','edit','String',num2str(data.totalFrames),...
                       'Position',[270,150,60,25],'BackgroundColor',[1,1,1]);
    
    uicontrol(figSelect,'Style','text','String',sprintf('总帧数: %d', data.totalFrames),...
             'Position',[350,150,100,20],'HorizontalAlignment','left');
    
    % 预览按钮
    uicontrol(figSelect,'Style','pushbutton','String','预览当前帧',...
             'Position',[150,100,100,30],...
             'Callback',@previewCurrentFrame);
    
    % 确定按钮
    uicontrol(figSelect,'Style','pushbutton','String','确定',...
             'Position',[270,100,80,30],...
             'Callback',@confirmFrameSelection);
    
    % 取消按钮
    uicontrol(figSelect,'Style','pushbutton','String','取消',...
             'Position',[360,100,80,30],...
             'Callback',@(~,~) delete(figSelect));
    
    % 嵌套函数：预览当前帧
    function previewCurrentFrame(~,~)
        try
            % 从选择窗口获取主界面数据
            mainFig = getappdata(figSelect, 'mainFigure');
            mainData = getappdata(figSelect, 'mainData');
            
            startFrame = str2double(get(startEdit, 'String'));
            endFrame = str2double(get(endEdit, 'String'));
            
            if isnan(startFrame) || isnan(endFrame) || startFrame < 1 || endFrame > mainData.totalFrames || startFrame > endFrame
                errordlg('请输入有效的帧范围');
                return;
            end
            
            midFrame = round((startFrame + endFrame) / 2);
            if ~isempty(mainData.processedSeries)
                previewImg = mainData.processedSeries(:,:,midFrame);
            else
                if ndims(mainData.img4D) == 4
                    previewImg = mainData.img4D(:,:,1,midFrame);
                else
                    previewImg = mainData.img4D(:,:,midFrame);
                end
                if isinteger(previewImg)
                    previewImg = double(previewImg);
                end
                previewImg = 255 - previewImg;
            end
            
            previewFig = figure('Name','帧预览');
            imagesc(previewImg); colormap(gray); axis image;
            caxis([min(previewImg(:)) max(previewImg(:))]);
            title(sprintf('预览帧 %d (范围: %d-%d)', midFrame, startFrame, endFrame));
            colorbar;
            
        catch ME
            errordlg(sprintf('预览失败: %s', ME.message));
        end
    end

    % 嵌套函数：确认帧选择
    function confirmFrameSelection(~,~)
        try
            % 从选择窗口获取主界面句柄和数据
            mainFig = getappdata(figSelect, 'mainFigure');
            mainData = getappdata(figSelect, 'mainData');
            
            startFrame = str2double(get(startEdit, 'String'));
            endFrame = str2double(get(endEdit, 'String'));
            
            if isnan(startFrame) || isnan(endFrame) || startFrame < 1 || endFrame > mainData.totalFrames || startFrame > endFrame
                errordlg('请输入有效的帧范围');
                return;
            end
            
            % 更新主界面数据
            mainData.startFrame = startFrame;
            mainData.endFrame = endFrame;
            mainData.currentFrame = startFrame;
            guidata(mainFig, mainData);
            
            % 更新主界面控件
            startFrameEdit = getappdata(mainFig, 'startFrameEdit');
            endFrameEdit = getappdata(mainFig, 'endFrameEdit');
            frameSlider = getappdata(mainFig, 'frameSlider');
            currentFrameText = getappdata(mainFig, 'currentFrameText');
            
            if ishandle(startFrameEdit)
                set(startFrameEdit, 'String', num2str(startFrame));
            end
            if ishandle(endFrameEdit)
                set(endFrameEdit, 'String', num2str(endFrame));
            end
            if ishandle(frameSlider)
                set(frameSlider, 'Value', startFrame);
            end
            if ishandle(currentFrameText)
                set(currentFrameText, 'String', num2str(startFrame));
            end
            
            % 更新显示
            updateFrameDisplayForMain(mainFig);
            
            % 更新状态并关闭选择窗口
            updateStatusForMain(mainFig, sprintf('已选择帧范围: %d-%d', startFrame, endFrame));
            delete(figSelect);
            
        catch ME
            errordlg(sprintf('帧选择失败: %s', ME.message));
        end
    end
end

function placeROI(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img2D)
        errordlg('请先导入图像');
        addWorkLog('错误: 尝试放置ROI但未导入图像');
        return;
    end
    
    updateStatus('请为4个脑叶各选择3个ROI中心点（共12个点）');
    addWorkLog('开始ROI放置流程');
    imageSize = size(data.img2D);
    roiMask = false(imageSize(1), imageSize(2), 4, 3);
    roiPositions = zeros(12, 4);
    
    mainAxes = getappdata(fig, 'mainAxes');
    if ~ishandle(mainAxes), return; end
    
    axes(mainAxes);
    
    % 获取当前帧图像
    if ~isempty(data.processedSeries)
        currentImg = data.processedSeries(:,:,data.currentFrame);
    elseif ~isempty(data.img4D)
        if ndims(data.img4D) == 4
            frameData = data.img4D(:,:,1,data.currentFrame);
        else
            frameData = data.img4D(:,:,data.currentFrame);
        end
        if isinteger(frameData)
            frameData = double(frameData);
        end
        currentImg = 255 - frameData;
    else
        currentImg = data.img2D;
    end
    
    imagesc(currentImg); 
    colormap(gray); 
    axis image;
    caxis([min(currentImg(:)) max(currentImg(:))]);
    title('请依次为4个脑叶选择ROI中心点', 'Color', 'white');
    hold on;
    
    text(10, 30, '操作说明:', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 12, 'BackgroundColor', 'black');
    text(10, 60, '1. 依次为额叶、顶叶、颞叶、枕叶各选3个点', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
    text(10, 90, '2. 尽量避开血管，选择脑实质区域', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
    text(10, 120, '3. 点击后程序会自动创建5x5 ROI', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
    
    roiCount = 1;
    for lobe = 1:4
        for r = 1:3
            currentText = text(imageSize(2)/2, 30, ...
                sprintf('请为 %s 选择第 %d/3 个ROI中心点', data.lobeNames{lobe}, r), ...
                'Color', data.colors(lobe,:), 'FontWeight', 'bold', 'FontSize', 14, ...
                'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
            
            try
                % 设置十字交叉光标
                set(fig, 'Pointer', 'crosshair');
                
                [x, y] = ginput(1);
                x = round(x); y = round(y);
                
                x = max(3, min(x, imageSize(2)-3));
                y = max(3, min(y, imageSize(1)-3));
                
                x_start = x - 2; y_start = y - 2;
                w = 5; h = 5;
                
                if x_start < 1, x_start = 1; end
                if y_start < 1, y_start = 1; end
                if x_start + w > imageSize(2), x_start = imageSize(2) - w; end
                if y_start + h > imageSize(1), y_start = imageSize(1) - h; end
                
                roiPositions(roiCount, :) = [x_start, y_start, w, h];
                roiMask(y_start:y_start+h-1, x_start:x_start+w-1, lobe, r) = true;
                
                rectangle('Position', [x_start, y_start, w, h], ...
                         'EdgeColor', data.colors(lobe,:), 'LineWidth', 2);
                text(x_start+2, y_start-8, sprintf('%s-%d', data.lobeNames{lobe}, r), ...
                     'Color', data.colors(lobe,:), 'FontWeight', 'bold', 'BackgroundColor', 'white');
                
                plot(x, y, 'r+', 'MarkerSize', 15, 'LineWidth', 2);
                
                roiCount = roiCount + 1;
                
            catch
                % 如果用户取消或出错，使用默认位置
                x_start = 50 + (lobe-1)*80 + (r-1)*20;
                y_start = 50 + (lobe-1)*80 + (r-1)*20;
                w = 5; h = 5;
                
                if x_start < 1, x_start = 1; end
                if y_start < 1, y_start = 1; end
                if x_start + w > imageSize(2), x_start = imageSize(2) - w; end
                if y_start + h > imageSize(1), y_start = imageSize(1) - h; end
                
                roiPositions(roiCount, :) = [x_start, y_start, w, h];
                roiMask(y_start:y_start+h-1, x_start:x_start+w-1, lobe, r) = true;
                
                rectangle('Position', [x_start, y_start, w, h], ...
                         'EdgeColor', data.colors(lobe,:), 'LineWidth', 2, 'LineStyle', '--');
                text(x_start+2, y_start-8, sprintf('%s-%d(D)', data.lobeNames{lobe}, r), ...
                     'Color', data.colors(lobe,:), 'FontWeight', 'bold');
                
                roiCount = roiCount + 1;
            end
            
            % 恢复默认光标
            set(fig, 'Pointer', 'arrow');
            
            if exist('currentText', 'var') && isvalid(currentText)
                delete(currentText);
            end
            pause(0.2);
        end
    end
    
    hold off;
    
    data.roiMask = roiMask;
    data.roiPositions = roiPositions;
    guidata(fig, data);
    
    % 更新ROI状态显示
    preOpROIStatus = getappdata(fig, 'preOpROIStatus');
    if ishandle(preOpROIStatus)
        set(preOpROIStatus, 'String', '术前:已标定', 'ForegroundColor', [0.8, 1, 0.8]);
    end
    
    updateStatus('ROI放置完成');
    if ishandle(mainAxes)
        title('ROI放置完成', 'Color', 'white');
    end
    % 在ROI放置完成后添加日志
    addWorkLog('ROI放置完成');
    addWorkLog(sprintf('共放置 %d 个ROI (4个脑叶各3个)', 12));
end

function extractTDC(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.roiMask) || isempty(data.img4D)
        errordlg('请先放置ROI并确保有多帧数据');
        addWorkLog('错误: 尝试提取TDC但ROI或数据不完整');
        return;
    end
    
    updateStatus('正在提取时间序列数据...');
    addWorkLog('开始提取时间序列数据(TDC)');
    
    try
        frameRateEdit = getappdata(fig, 'frameRateEdit');
        
        if ishandle(frameRateEdit)
            frameRate = str2double(get(frameRateEdit, 'String'));
        else
            frameRate = 4;
        end
        if isnan(frameRate) || frameRate <= 0
            frameRate = 4;
            if ishandle(frameRateEdit)
                set(frameRateEdit, 'String', '4');
            end
        end
        
        totalFrames = data.totalFrames;
        timeSeriesData = zeros(12, totalFrames);
        
        hWait = waitbar(0, '正在提取ROI时间序列数据...');
        for roiIdx = 1:12
            lobe = ceil(roiIdx / 3);
            r = mod(roiIdx-1, 3) + 1;
            currentMask = data.roiMask(:, :, lobe, r);
            
            for frameIdx = 1:totalFrames
                if ~isempty(data.processedSeries)
                    currentFrame = data.processedSeries(:,:,frameIdx);
                else
                    if ndims(data.img4D) == 4
                        frameData = data.img4D(:,:,1,frameIdx);
                    else
                        frameData = data.img4D(:,:,frameIdx);
                    end
                    if isinteger(frameData)
                        frameData = double(frameData);
                    end
                    currentFrame = 255 - frameData;
                end
                
                roiPixels = currentFrame(currentMask);
                timeSeriesData(roiIdx, frameIdx) = mean(roiPixels(:));
            end
            waitbar(roiIdx/12, hWait, sprintf('正在提取ROI %d/12...', roiIdx));
        end
        close(hWait);
        
        % ===== 归一化处理 =====
        for roiIdx = 1:12
            curve = timeSeriesData(roiIdx, :);

            % 平移到从0开始
            curve = curve - min(curve);

            % 归一化到 0–30
            if max(curve) > 0
                curve = curve / max(curve) * 30;
            end

            % 平移到基线 = 50
            curve = curve + 50;

            timeSeriesData(roiIdx, :) = curve;
        end

        data.timeSeriesData = timeSeriesData;
        data.frameRate = frameRate;
        data.startFrame = 1;
        data.endFrame = totalFrames;
        guidata(fig, data);
        
        startFrameEdit = getappdata(fig, 'startFrameEdit');
        endFrameEdit = getappdata(fig, 'endFrameEdit');
        
        if ishandle(startFrameEdit)
            set(startFrameEdit, 'String', '1');
        end
        if ishandle(endFrameEdit)
            set(endFrameEdit, 'String', num2str(totalFrames));
        end
        
        updateStatus(sprintf('时间序列数据提取完成 (共%d帧, %.1f秒)', totalFrames, (totalFrames-1)/frameRate));
        
        % 显示简单的成功提示弹窗
        showTDCSuccessMessage(data);
        
    catch ME
        errordlg(sprintf('数据提取失败: %s', ME.message));
        updateStatus('数据提取失败');
    end
    % 在TDC提取完成后添加日志
    addWorkLog('时间序列数据提取完成');
    addWorkLog(sprintf('提取了 %d 个ROI的时间密度曲线', 12));
    addWorkLog(sprintf('数据归一化处理完成 (基线=50, 范围0-30)'));
end

function showTDCSuccessMessage(data)
    % 创建简单的成功提示窗口
    successFig = figure('Name', 'TDC提取成功', ...
                       'NumberTitle', 'off', ...
                       'Position', [500, 400, 500, 300], ...
                       'MenuBar', 'none', ...
                       'ToolBar', 'none', ...
                       'Color', [0.95, 0.95, 0.95], ...
                       'Resize', 'off');
    
    % 成功图标和文字
    uicontrol('Parent', successFig, ...
             'Style', 'text', ...
             'String', '✓', ...
             'Position', [230, 200, 40, 40], ...
             'FontSize', 24, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [0, 0.7, 0], ...
             'BackgroundColor', [0.95, 0.95, 0.95]);
    
    uicontrol('Parent', successFig, ...
             'Style', 'text', ...
             'String', 'TDC提取成功！', ...
             'Position', [100, 160, 300, 30], ...
             'FontSize', 16, ...
             'FontWeight', 'bold', ...
             'ForegroundColor', [0, 0.5, 0], ...
             'BackgroundColor', [0.95, 0.95, 0.95], ...
             'HorizontalAlignment', 'center');
    
    % 详细信息
    infoText = {
        sprintf('成功提取了 %d 个ROI的时间序列数据', 12)
        sprintf('总帧数: %d, 持续时间: %.1f秒', data.totalFrames, (data.totalFrames-1)/data.frameRate)
        sprintf('帧率: %.1f Hz', data.frameRate)
        '数据已准备好进行下一步分析'
    };
    
    uicontrol('Parent', successFig, ...
             'Style', 'text', ...
             'String', infoText, ...
             'Position', [100, 80, 300, 80], ...
             'FontSize', 11, ...
             'ForegroundColor', [0.3, 0.3, 0.3], ...
             'BackgroundColor', [0.95, 0.95, 0.95], ...
             'HorizontalAlignment', 'center');
    
    % 确定按钮
    uicontrol('Parent', successFig, ...
             'Style', 'pushbutton', ...
             'String', '确定', ...
             'Position', [210, 30, 80, 30], ...
             'FontSize', 12, ...
             'FontWeight', 'bold', ...
             'BackgroundColor', [0.2, 0.6, 0.2], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', 'delete(gcf)');
end

function showTDCWindow(data)
    % 创建TDC曲线显示窗口
    tdcFig = figure('Name', 'TDC曲线分析', ...
                   'NumberTitle', 'off', ...
                   'Position', [200, 100, 1000, 700], ...
                   'MenuBar', 'none', ...
                   'Color', [0.95, 0.95, 0.95]);
    
    % 原始TDC曲线
    subplot(2,2,1);
    hold on;
    colors = lines(4);
    
    lobeAvgData = zeros(4, size(data.timeSeriesData, 2));
    for lobe = 1:4
        lobe_indices = (lobe-1)*3+1:lobe*3;
        lobeAvgData(lobe, :) = mean(data.timeSeriesData(lobe_indices, :), 1);
    end

    t_original = (0:size(data.timeSeriesData,2)-1) / data.frameRate;

    for lobe = 1:4
        plot(t_original, lobeAvgData(lobe, :),...
            'Color', colors(lobe,:), 'LineWidth', 2,...
            'DisplayName', data.lobeNames{lobe});
    end

    xlabel('时间 (秒)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('灰度值', 'FontSize', 12, 'FontWeight', 'bold');
    title('原始脑叶TDC曲线', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('show', 'Location', 'best');
    set(gca, 'FontSize', 11);
    hold off;
    
    % 单个ROI的TDC曲线
    subplot(2,2,2);
    hold on;
    for roiIdx = 1:12
        lobe = ceil(roiIdx/3);
        r = mod(roiIdx-1,3)+1;
        plot(t_original, data.timeSeriesData(roiIdx, :),...
            'Color', colors(lobe,:), 'LineWidth', 1,...
            'DisplayName', sprintf('%s-%d', data.lobeNames{lobe}, r));
    end
    xlabel('时间 (秒)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('灰度值', 'FontSize', 12, 'FontWeight', 'bold');
    title('单个ROI TDC曲线', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    legend('show', 'Location', 'best', 'NumColumns', 2);
    set(gca, 'FontSize', 10);
    hold off;
    
    % 参数显示
    subplot(2,2,3);
    axis off;
    
    paramText = {'TDC曲线特征参数:'};
    
    for lobe = 1:4
        lobe_indices = (lobe-1)*3+1:lobe*3;
        lobeData = mean(data.timeSeriesData(lobe_indices, :), 1);
        
        peakValue = max(lobeData);
        baseline = mean(lobeData(1:min(5, length(lobeData))));
        timeToPeak = find(lobeData == peakValue, 1) / data.frameRate;
        auc = trapz(lobeData) / data.frameRate;
        
        paramText{end+1} = sprintf('%s:', data.lobeNames{lobe});
        paramText{end+1} = sprintf('  峰值: %.1f, 基线: %.1f', peakValue, baseline);
        paramText{end+1} = sprintf('  达峰时间: %.2fs, AUC: %.1f', timeToPeak, auc);
        paramText{end+1} = '';
    end
    
    text(0.1, 0.9, paramText, 'FontSize', 10, 'VerticalAlignment', 'top', ...
         'FontName', 'Monospaced', 'Interpreter', 'none');
    
    % 关闭按钮
    uicontrol('Parent', tdcFig, ...
             'Style', 'pushbutton', ...
             'String', '关闭', ...
             'Position', [450, 20, 100, 30], ...
             'FontSize', 12, ...
             'FontWeight', 'bold', ...
             'BackgroundColor', [0.8, 0.2, 0.2], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', 'delete(gcf)');
end

function analyzeCurves(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.timeSeriesData)
        errordlg('请先提取时间序列数据');
        addWorkLog('错误: 尝试分析曲线但无时间序列数据');
        return;
    end
    
    updateStatus('正在分析TDC曲线...');
    addWorkLog('开始TDC曲线分析');
    
    try
        frameRateEdit = getappdata(fig, 'frameRateEdit');
        
        if ishandle(frameRateEdit)
            frameRate = str2double(get(frameRateEdit, 'String'));
        else
            frameRate = 4;
        end
        if isnan(frameRate) || frameRate <= 0
            frameRate = 4;
            if ishandle(frameRateEdit)
                set(frameRateEdit, 'String', '4');
            end
        end
        
        lobeAvgData = zeros(4, size(data.timeSeriesData, 2));
        for lobe = 1:4
            lobe_indices = (lobe-1)*3+1:lobe*3;
            lobeAvgData(lobe, :) = mean(data.timeSeriesData(lobe_indices, :), 1);
        end
        
        t = (0:size(data.timeSeriesData,2)-1) / frameRate;
        t_highres = linspace(t(1), t(end), length(t)*10);
        
        smoothedLobeData = zeros(4, length(t_highres));
        
        hWait = waitbar(0, '正在进行Hermite多项式插值平滑...');
        for lobe = 1:4
            smoothedLobeData(lobe, :) = pchip(t, lobeAvgData(lobe, :), t_highres);
            waitbar(lobe/4, hWait, sprintf('正在处理%s...', data.lobeNames{lobe}));
        end
        close(hWait);
        
        perfusionParams = struct();
        
        for lobe = 1:4
            curve = smoothedLobeData(lobe, :);
            time = t_highres;
            
            [maxVal, maxIdx] = max(curve);
            TMAX = time(maxIdx);
            
            baseline = mean(curve(1:min(5, length(curve))));
            threshold = baseline + 0.1 * (maxVal - baseline);
            tuIdx = find(curve > threshold, 1, 'first');
            if isempty(tuIdx)
                tuIdx = 1;
            end
            TU = time(tuIdx);

            TD = TMAX - TU;

            cumulative_auc = cumtrapz(time, curve - baseline);
            half_auc = cumulative_auc(end) / 2;
            mttIdx = find(cumulative_auc >= half_auc, 1, 'first');
            if isempty(mttIdx)
                MTT = TMAX;
            else
                MTT = time(mttIdx);
            end

            halfMaxVal = baseline + (maxVal - baseline) / 2;
            halfMaxIdx = find(curve(1:maxIdx) >= halfMaxVal, 1, 'first');
            if isempty(halfMaxIdx)
                halfTMAX = TU;
            else
                halfTMAX = time(halfMaxIdx);
            end

            AUC = trapz(time, curve - baseline);
            AUCbefore = trapz(time(1:maxIdx), curve(1:maxIdx) - baseline);
            AUCratio = AUCbefore / AUC;

            dCurve = diff(curve) ./ diff(time);
            timeRangeForSlope = (time >= TU) & (time <= TMAX);
            timeRangeForSlope(end) = [];
            if any(timeRangeForSlope)
                MS = max(dCurve(timeRangeForSlope));
            else
                MS = max(dCurve);
            end

            curveValueAtTU = curve(tuIdx);
            AFS = (maxVal - curveValueAtTU) / TD;
            CBF = AUC / MTT;
            
            perfusionParams(lobe).TMAX = TMAX;
            perfusionParams(lobe).MTT = MTT;
            perfusionParams(lobe).TU = TU;
            perfusionParams(lobe).TD = TD;
            perfusionParams(lobe).halfTMAX = halfTMAX;
            perfusionParams(lobe).AUC = AUC;
            perfusionParams(lobe).AUCbefore = AUCbefore;
            perfusionParams(lobe).AUCratio = AUCratio;
            perfusionParams(lobe).MS = MS;
            perfusionParams(lobe).AFS = AFS;
            perfusionParams(lobe).CBF = CBF;
        end
        
        data.perfusionParams = perfusionParams;
        data.smoothedLobeData = smoothedLobeData;
        data.t_highres = t_highres;
        guidata(fig, data);
        updateParamTable();
        showPerfusionParams(perfusionParams, data.lobeNames);
        updateStatus('TDC曲线分析完成');
        msgbox('TDC曲线分析完成！', '完成');
        
    catch ME
        errordlg(sprintf('曲线分析失败: %s', ME.message));
        updateStatus('曲线分析失败');
    end
    % 在曲线分析完成后添加日志
    addWorkLog('TDC曲线分析完成');
    addWorkLog('使用Hermite多项式插值进行曲线平滑');
    addWorkLog('计算了TMAX, MTT, AUC等灌注参数');
end

function showPerfusionParams(params, lobeNames)
    paramFig = figure('Name', '脑叶灌注参数表', ...
                     'NumberTitle', 'off', ...
                     'Position', [200, 200, 1000, 400],...
                     'MenuBar', 'none', ...
                     'Color', [0.95, 0.95, 0.95]);
    
    paramNames = {
        'TMAX (s)', 'MTT (s)', 'TU (s)', 'TD (s)', '1/2TMAX (s)', ...
        'AUC', 'AUCbefore', 'AUCbefore/AUC', 'MS (SI/s)', 'AFS (SI/s)', 'CBF (SI)'
    };
    
    tableData = cell(12, 6);
    tableData{1,1} = '参数';
    tableData{1,2} = '单位';
    for i = 1:4
        tableData{1,i+2} = lobeNames{i};
    end
    
    for i = 1:11
        tableData{i+1,1} = paramNames{i};
        
        switch i
            case {1,2,3,4,5}
                tableData{i+1,2} = 's';
            case {6,7}
                tableData{i+1,2} = 'SI*s';
            case 8
                tableData{i+1,2} = '';
            case {9,10}
                tableData{i+1,2} = 'SI/s';
            case 11
                tableData{i+1,2} = 'SI';
        end
        
        for j = 1:4
            switch i
                case 1
                    tableData{i+1,j+2} = sprintf('%.3f', params(j).TMAX);
                case 2
                    tableData{i+1,j+2} = sprintf('%.3f', params(j).MTT);
                case 3
                    tableData{i+1,j+2} = sprintf('%.3f', params(j).TU);
                case 4
                    tableData{i+1,j+2} = sprintf('%.3f', params(j).TD);
                case 5
                    tableData{i+1,j+2} = sprintf('%.3f', params(j).halfTMAX);
                case 6
                    tableData{i+1,j+2} = sprintf('%.1f', params(j).AUC);
                case 7
                    tableData{i+1,j+2} = sprintf('%.1f', params(j).AUCbefore);
                case 8
                    tableData{i+1,j+2} = sprintf('%.3f', params(j).AUCratio);
                case 9
                    tableData{i+1,j+2} = sprintf('%.3f', params(j).MS);
                case 10
                    tableData{i+1,j+2} = sprintf('%.3f', params(j).AFS);
                case 11
                    tableData{i+1,j+2} = sprintf('%.3f', params(j).CBF);
            end
        end
    end
    
    uitable('Parent', paramFig, ...
            'Data', tableData, ...
            'Position', [20, 20, 960, 350], ...
            'ColumnWidth', {100, 50, 80, 80, 80, 80}, ...
            'RowName', [], ...
            'ColumnName', {'参数', '单位', '额叶', '顶叶', '颞叶', '枕叶'});
end

function showResults(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.smoothedLobeData)
        errordlg('请先分析数据');
        return;
    end
    
    updateStatus('正在显示分析结果...');
    
    try
        resultFig = figure('Name','DSA灌注分析完整结果',...
                          'NumberTitle','off',...
                          'Position',[100, 50, 1400, 900],...
                          'Color',[0.95 0.95 0.95]);
        
        subplot(2,2,1);
        hold on;
        colors = lines(4);

        lobeAvgData = zeros(4, size(data.timeSeriesData, 2));
        for lobe = 1:4
            lobe_indices = (lobe-1)*3+1:lobe*3;
            lobeAvgData(lobe, :) = mean(data.timeSeriesData(lobe_indices, :), 1);
        end

        t_original = (0:size(data.timeSeriesData,2)-1) / data.frameRate;

        for lobe = 1:4
            plot(t_original, lobeAvgData(lobe, :),...
                'Color', colors(lobe,:), 'LineWidth', 2,...
                'DisplayName', data.lobeNames{lobe});
        end

        xlabel('时间 (秒)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('灰度值', 'FontSize', 12, 'FontWeight', 'bold');
        title('原始脑叶TDC曲线', 'FontSize', 14, 'FontWeight', 'bold');
        grid on;
        legend('show', 'Location', 'best');
        set(gca, 'FontSize', 11);
        hold off;
        
        subplot(2,2,2);
        hold on;
        for lobe = 1:4
            plot(data.t_highres, data.smoothedLobeData(lobe, :),...
                'Color', colors(lobe,:), 'LineWidth', 3,...
                'DisplayName', sprintf('%s (平滑后)', data.lobeNames{lobe}));
            
            [maxVal, maxIdx] = max(data.smoothedLobeData(lobe, :));
            plot(data.t_highres(maxIdx), maxVal, 'o',...
                'MarkerSize', 8, 'MarkerFaceColor', colors(lobe,:),...
                'MarkerEdgeColor', 'k', 'LineWidth', 1.5,...
                'HandleVisibility', 'off');
        end
        
        xlabel('时间 (秒)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('灰度值', 'FontSize', 12, 'FontWeight', 'bold');
        title('平滑后脑叶TDC曲线（三阶Hermite插值）', 'FontSize', 14, 'FontWeight', 'bold');
        grid on;
        legend('show', 'Location', 'best');
        set(gca, 'FontSize', 11);
        hold off;
        
        subplot(2,2,3);
        
        paramNames = {'TMAX', 'MTT', 'TU', 'TD', 'AUC'};
        paramValues = zeros(4, 5);
        
        for i = 1:4
            paramValues(i,1) = data.perfusionParams(i).TMAX;
            paramValues(i,2) = data.perfusionParams(i).MTT;
            paramValues(i,3) = data.perfusionParams(i).TU;
            paramValues(i,4) = data.perfusionParams(i).TD;
            paramValues(i,5) = data.perfusionParams(i).AUC / 1000;
        end
        
        barHandle = bar(paramValues, 'grouped');
        colormap(jet(5));
        
        set(gca, 'XTick', 1:4, 'XTickLabel', data.lobeNames, 'FontSize', 11);
        ylabel('参数值', 'FontSize', 12, 'FontWeight', 'bold');
        title('脑叶灌注参数详细对比', 'FontSize', 14, 'FontWeight', 'bold');
        legend(paramNames, 'Location', 'northoutside', 'Orientation', 'horizontal');
        grid on;
        set(gca, 'FontSize', 10, 'FontWeight', 'bold');
        
        subplot(2,2,4);
        
        tmaxValues = [data.perfusionParams.TMAX];
        mttValues = [data.perfusionParams.MTT];
        
        scatter(tmaxValues, mttValues, 100, 'filled', 'MarkerFaceColor', [0.2 0.6 0.8]);
        hold on;
        
        for i = 1:4
            text(tmaxValues(i), mttValues(i), data.lobeNames{i},...
                'FontSize', 12, 'FontWeight', 'bold',...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
        end
        
        p = polyfit(tmaxValues, mttValues, 1);
        xFit = linspace(min(tmaxValues), max(tmaxValues), 100);
        yFit = polyval(p, xFit);
        plot(xFit, yFit, 'r-', 'LineWidth', 2);
        
        correlation = corrcoef(tmaxValues, mttValues);
        rValue = correlation(1,2);
        
        xlabel('TMAX (s)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('MTT (s)', 'FontSize', 12, 'FontWeight', 'bold');
        title(sprintf('TMAX vs MTT 相关性 (r = %.3f)', rValue), 'FontSize', 14, 'FontWeight', 'bold');
        grid on;
        set(gca, 'FontSize', 11);
        hold off;
        
        set(resultFig, 'Units', 'normalized');
        set(resultFig, 'Position', [0.05, 0.05, 0.9, 0.85]);
        
        updateStatus('分析结果显示完成');
        
    catch ME
        errordlg(sprintf('结果显示失败: %s', ME.message));
        updateStatus('结果显示失败');
    end
end

function exportData(~,~)
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.timeSeriesData)
        errordlg('没有数据可导出');
        addWorkLog('错误: 尝试导出但无可用数据');
        return;
    end
    addWorkLog('开始数据导出流程');
    [file, path] = uiputfile({'*.mat','MAT文件 (*.mat)';...
                             '*.xlsx','Excel文件 (*.xlsx)';...
                             '*.csv','CSV文件 (*.csv)'},...
                            '保存分析结果');
    if isequal(file, 0)
        updateStatus('导出取消');
        return;
    end

    try
        fullPath = fullfile(path, file);
        [~,~,ext] = fileparts(file);

        % 更新分析信息
        data.analysisInfo.timestamp = datestr(now);
        data.analysisInfo.exportTime = datestr(now);
        data.analysisInfo.fileName = file;
        
        guidata(fig, data);

        switch lower(ext)
            case '.mat'
                save(fullPath, 'data');
                updateStatus(sprintf('成功导出MAT文件: %s', file));

            case {'.csv', '.xlsx'}
                % 导出灌注参数表格
                paramTable = createParameterTable(data);
                if strcmpi(ext, '.csv')
                    writetable(paramTable, fullPath);
                else
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
            comparePrePost([],[]);
        else
            msgbox('分析数据保存成功！', '完成');
        end

    catch ME
        errordlg(sprintf('导出失败: %s', ME.message));
        updateStatus('导出失败');
    end
    % 在导出完成后添加日志
    addWorkLog(sprintf('数据导出成功: %s', file));
end

function paramTable = createParameterTable(data)
    % 创建参数表格
    paramNames = {'TMAX', 'MTT', 'TU', 'TD', 'halfTMAX', ...
                 'AUC', 'AUCbefore', 'AUCratio', 'MS', 'AFS', 'CBF'};
    lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    
    tableData = [];
    
    for lobe = 1:4
        params = data.perfusionParams(lobe);
        rowData = [params.TMAX, params.MTT, params.TU, params.TD, params.halfTMAX, ...
                  params.AUC, params.AUCbefore, params.AUCratio, params.MS, params.AFS, params.CBF];
        tableData = [tableData; rowData];
    end
    
    paramTable = array2table(tableData, 'RowNames', lobeNames, ...
                            'VariableNames', paramNames);
end

function timeSeriesTable = createTimeSeriesTable(data)
    % 创建时间序列数据表格
    [numROIs, numFrames] = size(data.timeSeriesData);
    time = (0:numFrames-1) / data.frameRate;
    
    % 创建列名
    variableNames = {'Time'};
    for roiIdx = 1:numROIs
        lobe = ceil(roiIdx / 3);
        r = mod(roiIdx-1, 3) + 1;
        variableNames{end+1} = sprintf('%s_%d', data.lobeNames{lobe}, r);
    end
    
    % 创建数据矩阵
    tableData = zeros(numFrames, numROIs + 1);
    tableData(:, 1) = time';
    tableData(:, 2:end) = data.timeSeriesData';
    
    timeSeriesTable = array2table(tableData, 'VariableNames', variableNames);
end

function infoTable = createAnalysisInfoTable(data)
    % 创建分析信息表格
    infoFields = {'分析时间', '文件名', '总帧数', '帧率', '软件版本'};
    infoValues = {data.analysisInfo.timestamp, data.fileName, ...
                 data.totalFrames, data.frameRate, data.analysisInfo.softwareVersion};
    
    infoTable = table(infoFields', infoValues', ...
                     'VariableNames', {'参数', '值'});
end

function comparePrePost(~,~)
addWorkLog('开始术前术后对比分析');
    % 术前术后对比分析函数
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
                    errordlg('请先完成数据导入、ROI放置和时间序列提取');
                    return;
                else
                    % 执行分析流程
                    analyzeCurves([],[]);
                    % 等待分析完成
                    drawnow;
                    % 重新获取数据
                    data = guidata(fig);
                end
            case '导入已有数据'
                % 继续执行原有的导入逻辑
            case '取消'
                return;
        end
    end
    
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

    % 存储对比数据
    compData.preOpData = [];
    compData.postOpData = [];
    compData.preOpFile = '';
    compData.postOpFile = '';
    guidata(compFig, compData);
    
    function importPreOpData(~,~)
        [fname, pname] = uigetfile({'*.mat','MAT文件 (*.mat)'}, ...
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
            errordlg(sprintf('导入失败: %s', ME.message));
        end
    end

    function importPostOpData(~,~)
        [fname, pname] = uigetfile({'*.mat','MAT文件 (*.mat)'}, ...
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
            errordlg(sprintf('导入失败: %s', ME.message));
        end
    end

    function analyzeComparison(~,~)
        compData = guidata(compFig);
        
        if isempty(compData.preOpData) || isempty(compData.postOpData)
            errordlg('请先导入术前和术后数据');
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
            tableData{i,1} = lobeNames{i};
            tableData{i,2} = sprintf('%.3f', preParams(i).MS);
            tableData{i,3} = sprintf('%.3f', postParams(i).MS);
            tableData{i,4} = sprintf('%.1f%%', increaseRatios(i));
            tableData{i,5} = riskLevels{i};
        end
        
        resultTable = uitable(resultsPanel, ...
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

        % 绘制柱状图对比
        axes('Parent', resultsPanel, 'Position', [0.65, 0.45, 0.3, 0.4]);
        
        barData = [increaseRatios; ones(1,4)*100]';
        h = bar(barData, 'grouped');
        set(h(1), 'FaceColor', [0.2 0.6 0.8]);
        set(h(2), 'FaceColor', [0.8 0.8 0.8]);
        
        % 添加风险阈值线
        hold on;
        plot([0,5], [150, 150], 'r--', 'LineWidth', 3);
        text(5.2, 150, '高风险阈值 (150%)', 'Color', 'r', 'FontWeight', 'bold', 'FontSize', 11);
        plot([0,5], [120, 120], 'y--', 'LineWidth', 3);
        text(5.2, 120, '中风险阈值 (120%)', 'Color', [0.8 0.6 0], 'FontWeight', 'bold', 'FontSize', 11);
        
        set(gca, 'XTickLabel', lobeNames, 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('血流速度增加比例 (%)', 'FontSize', 13, 'FontWeight', 'bold');
        title('术前术后血流速度对比 (基于MS参数)', 'FontSize', 14, 'FontWeight', 'bold');
        legend('增加比例', '基线(100%)', 'Location', 'northwest', 'FontSize', 11);
        grid on;
        
        % 在柱子上添加数值
        for i = 1:4
            text(i, increaseRatios(i)+8, sprintf('%.1f%%', increaseRatios(i)), ...
                 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11, ...
                 'BackgroundColor', 'white', 'EdgeColor', 'black', 'Margin', 2);
        end
        
        % 显示详细参数对比
        paramPanel = uipanel(resultsPanel, 'Title', '详细参数对比', ...
                            'Position', [0.05, 0.05, 0.55, 0.35], ...
                            'BackgroundColor', [0.95 0.95 0.95], ...
                            'FontWeight', 'bold', ...
                            'FontSize', 12);
        
        paramNames = {'TMAX (s)', 'MTT (s)', 'AUC'};
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
        
        detailedTable = uitable(paramPanel, ...
            'Data', paramData, ...
            'Position', [10, 10, 530, 120], ...
            'ColumnName', {'脑叶', '术前TMAX', '术后TMAX', '术前MTT', '术后MTT', '术前AUC', '术后AUC'}, ...
            'ColumnWidth', {60, 80, 80, 80, 80, 80, 80}, ...
            'RowName', [], ...
            'FontSize', 10);
        
        % 显示临床建议
        advicePanel = uipanel(resultsPanel, 'Title', '临床建议', ...
                             'Position', [0.65, 0.05, 0.3, 0.35], ...
                             'BackgroundColor', [0.95 0.95 0.95], ...
                             'FontWeight', 'bold', ...
                             'FontSize', 12);
        
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
        
        % 保存对比结果
        compData.increaseRatios = increaseRatios;
        compData.riskLevels = riskLevels;
        compData.warningLevel = warningLevel;
        guidata(compFig, compData);
        
        updateStatus('术前术后对比分析完成');
    end

    function exportComparison(~,~)
        compData = guidata(compFig);
        
        [file, path] = uiputfile({'*.xlsx','Excel文件 (*.xlsx)'; ...
                                 '*.csv','CSV文件 (*.csv)'}, ...
                                '保存对比分析结果');
        if isequal(file, 0)
            return;
        end
        
        try
            fullPath = fullfile(path, file);
            

            % 检查必要的数据是否存在
            if ~isfield(compData, 'increaseRatios') || isempty(compData.increaseRatios)
                errordlg('请先进行对比分析再导出结果！');
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
                tableData.PreOp_TMAX(i) = compData.preOpData.perfusionParams(i).TMAX;
                tableData.PostOp_TMAX(i) = compData.postOpData.perfusionParams(i).TMAX;
                tableData.PreOp_MTT(i) = compData.preOpData.perfusionParams(i).MTT;
                tableData.PostOp_MTT(i) = compData.postOpData.perfusionParams(i).MTT;
                tableData.PreOp_AUC(i) = compData.preOpData.perfusionParams(i).AUC;
                tableData.PostOp_AUC(i) = compData.postOpData.perfusionParams(i).AUC;
            end
            
            % 添加总结信息
            summaryTable = table();
            summaryTable.AnalysisDate = {datestr(now)};
            summaryTable.PreOpFile = {compData.preOpFile};
            summaryTable.PostOpFile = {compData.postOpFile};
            summaryTable.OverallRiskLevel = {compData.warningLevel};
            summaryTable.HighRiskLobes = {sum(compData.increaseRatios >= 150)};
            summaryTable.MediumRiskLobes = {sum(compData.increaseRatios >= 120 & compData.increaseRatios < 150)};
            
            % 使用兼容性更好的文件扩展名判断
            [~, ~, ext] = fileparts(file);
            if strcmpi(ext, '.xlsx')
                writetable(tableData, fullPath, 'Sheet', '详细参数');
                writetable(summaryTable, fullPath, 'Sheet', '分析总结');
            else
                writetable(tableData, fullPath);
            end
            
            msgbox('对比结果导出成功！', '成功');
            
        catch ME
            errordlg(sprintf('导出失败: %s', ME.message));
        end
    end
% 在对比分析完成后添加日志
    addWorkLog('术前术后对比分析完成');
end

%% ========== 系统工具函数 ==========
function resetAll(~,~)
    fig = gcf;
    data = guidata(fig);
    
    choice = questdlg('确定要重置所有数据吗？', '重置确认', '是', '否', '否');
    if strcmp(choice, '否')
        return;
    end
    
    % 停止播放定时器
    stopPlayback();
    
    data.img2D = [];
    data.img4D = [];
    data.info = [];
    data.roiMask = [];
    data.roiPositions = [];
    data.timeSeriesData = [];
    data.currentFrame = 1;
    data.totalFrames = 1;
    data.frameRate = 4;
    data.startFrame = 1;
    data.endFrame = 1;
    data.processedSeries = [];
    data.smoothedLobeData = [];
    data.TMAX_times = [];
    data.AUC_values = [];
    data.t_highres = [];
    data.perfusionParams = [];
    data.fileName = '';
    data.filePath = '';
    data.roiBaselines = [];
    data.analysisInfo.timestamp = '';
    
    guidata(fig, data);
    
    % 重置所有控件
    resetUIControls(fig);
    
    updateStatus('已重置所有数据 - 请导入DSA数据');
end

function resetUIControls(fig)
    % 获取所有控件句柄
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');
    totalFramesText = getappdata(fig, 'totalFramesText');
    playBtn = getappdata(fig, 'playBtn');
    pauseBtn = getappdata(fig, 'pauseBtn');
    firstFrameBtn = getappdata(fig, 'firstFrameBtn');
    prevFrameBtn = getappdata(fig, 'prevFrameBtn');
    nextFrameBtn = getappdata(fig, 'nextFrameBtn');
    lastFrameBtn = getappdata(fig, 'lastFrameBtn');
    startFrameEdit = getappdata(fig, 'startFrameEdit');
    endFrameEdit = getappdata(fig, 'endFrameEdit');
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    applyRangeBtn = getappdata(fig, 'applyRangeBtn');
    preOpROIStatus = getappdata(fig, 'preOpROIStatus');
    postOpROIStatus = getappdata(fig, 'postOpROIStatus');
    riskResultText = getappdata(fig, 'riskResultText');
    mainAxes = getappdata(fig, 'mainAxes');
    paramTable = getappdata(fig, 'paramTable');
    
    % 重置所有控件
    if ishandle(frameSlider)
        set(frameSlider, 'Value', 1, 'Enable', 'off');
    end
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', '1');
    end
    if ishandle(totalFramesText)
        set(totalFramesText, 'String', '1');
    end
    if ishandle(playBtn)
        set(playBtn, 'Enable', 'off', 'BackgroundColor', [0.2, 0.7, 0.2]);
    end
    if ishandle(pauseBtn)
        set(pauseBtn, 'Enable', 'off', 'BackgroundColor', [0.5, 0.5, 0.5]);
    end
    if ishandle(firstFrameBtn)
        set(firstFrameBtn, 'Enable', 'off');
    end
    if ishandle(prevFrameBtn)
        set(prevFrameBtn, 'Enable', 'off');
    end
    if ishandle(nextFrameBtn)
        set(nextFrameBtn, 'Enable', 'off');
    end
    if ishandle(lastFrameBtn)
        set(lastFrameBtn, 'Enable', 'off');
    end
    if ishandle(startFrameEdit)
        set(startFrameEdit, 'String', '1', 'Enable', 'off');
    end
    if ishandle(endFrameEdit)
        set(endFrameEdit, 'String', '1', 'Enable', 'off');
    end
    if ishandle(frameRateEdit)
        set(frameRateEdit, 'String', '4', 'Enable', 'off');
    end
    if ishandle(applyRangeBtn)
        set(applyRangeBtn, 'Enable', 'off');
    end
    if ishandle(preOpROIStatus)
        set(preOpROIStatus, 'String', '术前:未标定', 'ForegroundColor', [1, 0.8, 0.8]);
    end
    if ishandle(postOpROIStatus)
        set(postOpROIStatus, 'String', '术后:未标定', 'ForegroundColor', [1, 0.8, 0.8]);
    end
    if ishandle(riskResultText)
        set(riskResultText, 'String', '未评估', 'ForegroundColor', [1, 1, 0]);
    end
    
    % 重置参数表格
    if ishandle(paramTable)
        paramNames = {'TMAX (s)', 'MTT (s)', 'AUC', '变化率%'};
        lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
        
        tableData = cell(length(paramNames), length(lobeNames));
        for i = 1:length(paramNames)
            for j = 1:length(lobeNames)
                tableData{i,j} = '--';
            end
        end
        
        set(paramTable, 'Data', tableData);
    end
    
    if ishandle(mainAxes)
        axes(mainAxes);
        cla;
        title('DICOM影像显示区域', 'Color', [1, 1, 1], 'FontSize', 14);
    end
end

function showHelp(~,~)
    helpText = {
        'DSA灌注分析系统使用说明：'
        ''
        '1. 导入DSA - 选择DICOM格式的DSA图像文件'
        '2. 选择帧数 - 指定要分析的时间帧范围'
        '3. 放置ROI - 为4个脑叶各选择3个ROI区域'
        '4. 提取TDC - 提取时间密度曲线数据'
        '5. 分析曲线 - 计算灌注参数并进行曲线分析'
        '6. 显示结果 - 查看分析结果和图表'
        '7. 导出数据 - 保存分析结果'
        '8. 术前术后对比 - 比较术前术后灌注变化，预警高灌注风险'
        ''
        '高灌注风险预警标准 (TCD标准):'
        '- 高风险: 血流速度增加 ≥ 150%'
        '- 中风险: 血流速度增加 120%-150%'
        '- 低风险: 血流速度增加 < 120%'
        ''
        '帧数控制功能：'
        '- 使用滑块快速浏览不同帧'
        '- 播放按钮动态查看序列'
        '- 导航按钮快速跳转帧'
        ''
        '注意事项：'
        '- 确保DSA图像包含足够的时间帧'
        '- ROI放置时应避开大血管，选择脑实质区域'
        '- 帧率设置应与实际采集帧率一致'
        '- 术前术后对比需要分别分析并保存数据'
        '- 建议先导出当前数据，再进行对比分析'
    };
    
    helpdlg(helpText, '使用帮助');
end

function closeGUI(~,~)
    % 停止播放定时器
    stopPlayback();
    
    choice = questdlg('确定要退出DSA分析系统吗？', '退出确认', '是', '否', '否');
    if strcmp(choice, '是')
        delete(gcf);
    end
end

%% ========== 辅助函数 ==========
function updateFrameDisplayForMain(mainFig)
    data = guidata(mainFig);
    
    if isempty(data.img4D) && isempty(data.processedSeries)
        return;
    end
    
    currentFrame = data.currentFrame;
    
    % 获取当前帧图像
    if ~isempty(data.processedSeries)
        currentImg = data.processedSeries(:,:,currentFrame);
    elseif ~isempty(data.img4D)
        if ndims(data.img4D) == 4
            frameData = data.img4D(:,:,1,currentFrame);
        else
            frameData = data.img4D(:,:,currentFrame);
        end
        if isinteger(frameData)
            frameData = double(frameData);
        end
        currentImg = 255 - frameData;
    else
        return;
    end
    
    % 更新显示
    mainAxes = getappdata(mainFig, 'mainAxes');
    if ishandle(mainAxes)
        axes(mainAxes);
        imagesc(currentImg); 
        colormap(gray); 
        axis image;
        caxis([min(currentImg(:)) max(currentImg(:))]);
        
        % 如果已经放置了ROI，重新绘制ROI
        if isfield(data, 'roiPositions') && ~isempty(data.roiPositions)
            hold on;
            for i = 1:size(data.roiPositions, 1)
                pos = data.roiPositions(i,:);
                lobe = ceil(i/3);
                r = mod(i-1,3)+1;
                color = data.colors(lobe,:);
                rectangle('Position', pos, 'EdgeColor', color, 'LineWidth', 2);
                text(pos(1)+2, pos(2)-8, sprintf('%s-%d', data.lobeNames{lobe}, r),...
                     'Color', color, 'FontWeight', 'bold', 'BackgroundColor', 'white',...
                     'FontSize', 8);
            end
            hold off;
        end
        
        title(sprintf('%s - 帧 %d/%d', data.fileName, currentFrame, data.totalFrames), 'Color', 'white', 'Interpreter', 'none');
    end
    
    % 更新帧数文本
    currentFrameText = getappdata(mainFig, 'currentFrameText');
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', num2str(currentFrame));
    end
    
    drawnow;
end

function updateStatusForMain(mainFig, message)
    resultsText = getappdata(mainFig, 'resultsText');
    if isempty(resultsText) || ~ishandle(resultsText)
        return;
    end
    
    currentText = get(resultsText, 'String');
    if ischar(currentText)
        currentText = {currentText};
    end
    
    timestamp = datestr(now, 'HH:MM:SS');
    newMessage = sprintf('[%s] %s', timestamp, message);
    
    newText = [currentText; {newMessage}];
    
    if length(newText) > 15
        newText = newText(end-14:end);
    end
    
    set(resultsText, 'String', newText);
    set(resultsText, 'Value', length(newText)); % 滚动到底部
    drawnow;
end

function initializeDataContainer(fig)
    % 初始化数据容器
    data = guidata(fig);
    
    % 基本数据结构
    data.img2D = [];
    data.img4D = [];
    data.info = [];
    data.roiMask = [];
    data.roiPositions = [];
    data.timeSeriesData = [];
    data.currentFrame = 1;
    data.totalFrames = 1;
    data.frameRate = 4;
    data.startFrame = 1;
    data.endFrame = 1;
    data.processedSeries = [];
    data.smoothedLobeData = [];
    data.TMAX_times = [];
    data.AUC_values = [];
    data.t_highres = [];
    data.perfusionParams = [];
    data.fileName = '';
    data.filePath = '';
    data.roiBaselines = [];
    
    % 脑叶名称
    data.lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    
    % ROI颜色
    data.colors = [
        0.3, 0.6, 0.9;  % 额叶 - 蓝色
        0.9, 0.6, 0.3;  % 顶叶 - 橙色
        0.3, 0.9, 0.6;  % 颞叶 - 绿色
        0.9, 0.3, 0.6   % 枕叶 - 粉色
    ];
    
    % 分析信息
    data.analysisInfo = struct();
    data.analysisInfo.timestamp = datestr(now);
    data.analysisInfo.softwareVersion = 'v3.0';
    
    % 存储数据
    guidata(fig, data);
    
    % 初始化工作日志
    addWorkLog('系统初始化完成');
end

function addWorkLog(message)
    % 添加到左侧面板的工作日志
    workLogText = getappdata(gcf, 'workLogText');
    workLogData = getappdata(gcf, 'workLogData');
    
    if isempty(workLogText) || ~ishandle(workLogText)
        return;
    end
    
    % 创建带时间戳的日志条目
    timestamp = datestr(now, 'HH:MM:SS');
    logEntry = sprintf('[%s] %s', timestamp, message);
    
    % 更新日志数据
    if isempty(workLogData)
        workLogData = {logEntry};
    else
        workLogData = [workLogData; {logEntry}];
    end
    
    % 限制日志条目数量（保留最近20条）
    if length(workLogData) > 20
        workLogData = workLogData(end-19:end);
    end
    
    % 更新显示
    set(workLogText, 'String', workLogData);
    set(workLogText, 'Value', length(workLogData)); % 滚动到底部
    
    % 保存更新后的数据
    setappdata(gcf, 'workLogData', workLogData);
    
    drawnow;
end

function updateParamTable()
    % 更新灌注参数表格显示
    paramTable = getappdata(gcf, 'paramTable');
    data = guidata(gcf);
    
    if isempty(paramTable) || ~ishandle(paramTable)
        return;
    end
    
    % 检查是否有灌注参数数据
    if ~isfield(data, 'perfusionParams') || isempty(data.perfusionParams)
        % 如果没有数据，显示占位符
        paramNames = {'TMAX (s)', 'MTT (s)', 'TU (s)', 'TD (s)', 'AUC'};
        lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
        
        tableData = cell(length(paramNames), length(lobeNames));
        for i = 1:length(paramNames)
            for j = 1:length(lobeNames)
                tableData{i,j} = '--';
            end
        end
        
        set(paramTable, 'Data', tableData);
        set(paramTable, 'ColumnName', lobeNames);
        set(paramTable, 'RowName', paramNames);
        set(paramTable, 'ColumnWidth', {40, 35, 35, 35}); % 设置列宽避免文字被切断
        set(paramTable, 'ColumnEditable', false); % 禁止编辑
        return;
    end
    
    % 如果有数据，填充参数值
    paramNames = {'TMAX (s)', 'MTT (s)', 'TU (s)', 'TD (s)', 'AUC'};
    lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    tableData = cell(length(paramNames), length(lobeNames));
    
    for i = 1:length(paramNames)
        for j = 1:length(lobeNames)
            switch i
                case 1
                    tableData{i,j} = sprintf('%.3f', data.perfusionParams(j).TMAX);
                case 2
                    tableData{i,j} = sprintf('%.3f', data.perfusionParams(j).MTT);
                case 3
                    tableData{i,j} = sprintf('%.3f', data.perfusionParams(j).TU);
                case 4
                    tableData{i,j} = sprintf('%.3f', data.perfusionParams(j).TD);
                case 5
                    tableData{i,j} = sprintf('%.1f', data.perfusionParams(j).AUC);
            end
        end
    end
    
    set(paramTable, 'Data', tableData);
    set(paramTable, 'ColumnName', lobeNames);
    set(paramTable, 'RowName', paramNames);
    set(paramTable, 'ColumnWidth', {40, 35, 35, 35}); % 设置列宽避免文字被切断
    set(paramTable, 'ColumnEditable', false); % 禁止编辑
end