<<<<<<< HEAD
function createControlButtons(parent)
    % 创建左侧控制按钮面板
    % 输入: parent - 父容器句柄
    
    % 面板标题
    uicontrol('Parent', parent, 'Style', 'text', ...
             'String', '分析流程控制', ...
             'Position', [10, 750, 240, 30], ...
             'FontSize', 16, 'FontWeight', 'bold', ...
             'ForegroundColor', [1, 1, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'center');
    
    % 按钮配置
    buttonWidth = 215;
    buttonHeight = 30;
    startY = 680;
    spacing = 10;
    groupSpacing = 18;
    
    % 第一组：数据准备
    createButtonGroupLabel(parent, '数据准备', 10, startY + 5);
    buttons1 = {
        {'导入DSA数据', @importDSA_placeholder, [0.2, 0.6, 0.8]}, ...
        {'选择分析帧', @selectFrames_placeholder, [0.2, 0.6, 0.8]}
    };
    createButtonGroup(parent, buttons1, startY, buttonWidth, buttonHeight, spacing);
    
    % 第二组：ROI分析
    y2 = startY - 2*(buttonHeight+spacing);
    createButtonGroupLabel(parent, 'ROI分析', 10, y2 + 5);
    buttons2 = {
        {'放置ROI', @placeROI_placeholder, [0.3, 0.7, 0.3]}, ...
        {'提取TDC', @extractTDC_placeholder, [0.8, 0.6, 0.2]}
    };
    createButtonGroup(parent, buttons2, y2, buttonWidth, buttonHeight, spacing);
    
    % 第三组：分析显示
    y3 = startY - 4*(buttonHeight+spacing) - groupSpacing;
    createButtonGroupLabel(parent, '分析显示', 10, y3 + 5);
    buttons3 = {
        {'分析曲线', @analyzeCurves_placeholder, [0.8, 0.6, 0.2]}, ...
        {'显示结果', @showResults_placeholder, [0.7, 0.5, 0.9]}
    };
    createButtonGroup(parent, buttons3, y3, buttonWidth, buttonHeight, spacing);
    
    % 第四组：数据管理
    y4 = startY - 6*(buttonHeight+spacing) - 2*groupSpacing;
    createButtonGroupLabel(parent, '数据管理', 10, y4 + 5);
    buttons4 = {
        {'导出数据', @exportData_placeholder, [0.4, 0.4, 0.6]}, ...
        {'术前术后对比', @comparePrePost_placeholder, [0.9, 0.3, 0.3]}
    };
    createButtonGroup(parent, buttons4, y4, buttonWidth, buttonHeight, spacing);
    
    % 第五组：系统操作
    y5 = startY - 8*(buttonHeight+spacing) - 3*groupSpacing;
    createButtonGroupLabel(parent, '系统操作', 10, y5 + 5);
    buttons5 = {
        {'重置所有', @resetAll_placeholder, [0.8, 0.2, 0.2]}, ...
        {'使用帮助', @showHelp_placeholder, [0.2, 0.6, 0.8]}
    };
    createButtonGroup(parent, buttons5, y5, buttonWidth, buttonHeight, spacing);
    
    % 工作日志面板
    createWorkLogPanel(parent, 10);
end

%% 辅助函数
function createButtonGroupLabel(parent, labelText, x, y)
    % 创建按钮组标签
    uicontrol('Parent', parent, 'Style', 'text', ...
             'String', labelText, ...
             'Position', [x, y, 100, 20], ...
             'FontSize', 12, 'FontWeight', 'bold', ...
             'ForegroundColor', [0.8, 0.9, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'left');
end

function createButtonGroup(parent, buttons, startY, width, height, spacing)
    % 创建一组按钮
    for i = 1:length(buttons)
        buttonInfo = buttons{i};
        yPos = startY - (i-1) * (height + spacing);
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', ...
                 'String', buttonInfo{1}, ...
                 'Position', [10, yPos, width, height], ...
                 'FontSize', 11, 'FontWeight', 'bold', ...
                 'BackgroundColor', buttonInfo{3}, ...
                 'ForegroundColor', [1, 1, 1], ...
                 'Callback', buttonInfo{2});
    end
end

function createWorkLogPanel(parent, startY)
    % 创建工作日志面板
    workLogPanel = uipanel('Parent', parent, ...
                         'Title', '操作日志', ...
                         'Units', 'pixels', ...
                         'Position', [10, startY, 215, 200], ...
                         'BackgroundColor', [0.15, 0.25, 0.35], ...
                         'ForegroundColor', [1, 1, 1], ...
                         'FontSize', 11, ...
                         'FontWeight', 'bold');
    
    workLogText = uicontrol('Parent', workLogPanel, ...
                          'Style', 'listbox', ...
                          'String', {'系统初始化完成', '欢迎使用DSA分析系统'}, ...
                          'Position', [10, 30, 195, 115], ...
                          'FontSize', 9, ...
                          'BackgroundColor', [0.05, 0.1, 0.15], ...
                          'ForegroundColor', [0.8, 0.9, 1], ...
                          'Max', 100, 'Min', 0);
    
    % 日志控制按钮
    uicontrol('Parent', workLogPanel, 'Style', 'pushbutton', ...
             'String', '清空', 'Position', [10, 5, 55, 20], ...
             'FontSize', 8, ...
             'BackgroundColor', [0.6, 0.2, 0.2], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', @clearWorkLog);
    
    uicontrol('Parent', workLogPanel, 'Style', 'pushbutton', ...
             'String', '导出', 'Position', [72, 5, 55, 20], ...
             'FontSize', 8, ...
             'BackgroundColor', [0.2, 0.5, 0.8], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', @exportWorkLog);
    
    uicontrol('Parent', workLogPanel, 'Style', 'pushbutton', ...
             'String', '详细', 'Position', [134, 5, 55, 20], ...
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
end

function showDetailedLog(~,~)
    % 显示详细日志窗口
    workLogData = getappdata(gcf, 'workLogData');
    if isempty(workLogData)
        msgbox('工作日志为空', '工作日志');
        return;
    end
    
    logFig = figure('Name', '详细工作日志', ...
                   'NumberTitle', 'off', ...
                   'Position', [300, 200, 800, 600], ...
                   'MenuBar', 'none', ...
                   'ToolBar', 'none', ...
                   'Color', [0.95, 0.95, 0.95]);
    
    uicontrol('Parent', logFig, 'Style', 'listbox', ...
              'String', workLogData, ...
              'Position', [20, 50, 760, 500], ...
              'FontSize', 10, ...
              'BackgroundColor', [1, 1, 1], ...
              'ForegroundColor', [0.1, 0.1, 0.1], ...
              'Max', 2);
    
    totalEntries = length(workLogData);
    todayEntries = sum(contains(workLogData, datestr(now, 'yyyy-mm-dd')));
    infoText = sprintf('总日志条目: %d | 今日条目: %d', totalEntries, todayEntries);
    
    uicontrol('Parent', logFig, 'Style', 'text', ...
             'String', infoText, ...
             'Position', [20, 560, 300, 25], ...
             'FontSize', 11, 'FontWeight', 'bold', ...
             'BackgroundColor', [0.95, 0.95, 0.95], ...
             'HorizontalAlignment', 'left');
    
    uicontrol('Parent', logFig, 'Style', 'pushbutton', ...
             'String', '关闭', 'Position', [690, 560, 80, 25], ...
             'FontSize', 10, ...
             'BackgroundColor', [0.8, 0.2, 0.2], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', 'delete(gcf)');
end

%% 占位回调函数（待实现）
function importDSA_placeholder(~,~)
    msgbox('此功能需要从原文件提取 importDSA 函数', '功能未实现');
end

function selectFrames_placeholder(~,~)
    msgbox('此功能需要从原文件提取 selectFrames 函数', '功能未实现');
end

function placeROI_placeholder(~,~)
    msgbox('此功能需要从原文件提取 placeROI 函数', '功能未实现');
end

function extractTDC_placeholder(~,~)
    msgbox('此功能需要从原文件提取 extractTDC 函数', '功能未实现');
end

function analyzeCurves_placeholder(~,~)
    msgbox('此功能需要从原文件提取 analyzeCurves 函数', '功能未实现');
end

function showResults_placeholder(~,~)
    msgbox('此功能需要从原文件提取 showResults 函数', '功能未实现');
end

function exportData_placeholder(~,~)
    msgbox('此功能需要从原文件提取 exportData 函数', '功能未实现');
end

function comparePrePost_placeholder(~,~)
    msgbox('此功能需要从原文件提取 comparePrePost 函数', '功能未实现');
end

function resetAll_placeholder(~,~)
    selection = questdlg('确定要重置所有数据吗？', '重置确认', '是', '否', '否');
    if strcmp(selection, '是')
        msgbox('重置功能待实现', '提示');
    end
end

function showHelp_placeholder(~,~)
    helpText = {
        'DSA脑血流灌注分析系统 使用帮助'
        ''
        '功能说明:'
        '1. 导入DSA数据 - 导入DICOM格式的DSA影像'
        '2. 选择分析帧 - 选择需要分析的帧范围'
        '3. 放置ROI - 在4个脑叶各放置3个感兴趣区域'
        '4. 提取TDC - 提取时间密度曲线'
        '5. 分析曲线 - 进行曲线分析和参数计算'
        '6. 显示结果 - 显示分析结果和风险评估'
        ''
        '注意: 当前为重构版本，部分功能需要从原文件提取'
    };
    msgbox(helpText, 'DSA分析系统帮助', 'help');
end
=======
function createControlButtons(parent)
    % 创建左侧控制按钮面板
    % 输入: parent - 父容器句柄
    
    % 面板标题
    uicontrol('Parent', parent, 'Style', 'text', ...
             'String', '分析流程控制', ...
             'Position', [10, 750, 240, 30], ...
             'FontSize', 16, 'FontWeight', 'bold', ...
             'ForegroundColor', [1, 1, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'center');
    
    % 按钮配置
    buttonWidth = 215;
    buttonHeight = 30;
    startY = 680;
    spacing = 10;
    groupSpacing = 18;
    
    % 第一组：数据准备
    createButtonGroupLabel(parent, '数据准备', 10, startY + 5);
    buttons1 = {
        {'导入DSA数据', @importDSA, [0.2, 0.6, 0.8]}, ...
        {'选择分析帧', @selectFrames, [0.2, 0.6, 0.8]}
    };
    createButtonGroup(parent, buttons1, startY, buttonWidth, buttonHeight, spacing);
    
    % 第二组：ROI分析
    y2 = startY - 2*(buttonHeight+spacing);
    createButtonGroupLabel(parent, 'ROI分析', 10, y2 + 5);
    buttons2 = {
        {'放置ROI', @placeROI, [0.3, 0.7, 0.3]}, ...
        {'提取TDC', @extractTDC, [0.8, 0.6, 0.2]}
    };
    createButtonGroup(parent, buttons2, y2, buttonWidth, buttonHeight, spacing);
    
    % 第三组：分析显示
    y3 = startY - 4*(buttonHeight+spacing) - groupSpacing;
    createButtonGroupLabel(parent, '分析显示', 10, y3 + 5);
    buttons3 = {
        {'分析曲线', @analyzeCurves, [0.8, 0.6, 0.2]}, ...
        {'显示结果', @showResults, [0.7, 0.5, 0.9]}
    };
    createButtonGroup(parent, buttons3, y3, buttonWidth, buttonHeight, spacing);
    
    % 第四组：数据管理
    y4 = startY - 6*(buttonHeight+spacing) - 2*groupSpacing;
    createButtonGroupLabel(parent, '数据管理', 10, y4 + 5);
    buttons4 = {
        {'导出数据', @exportData, [0.4, 0.4, 0.6]}, ...
        {'术前术后对比', @comparePrePost, [0.9, 0.3, 0.3]}
    };
    createButtonGroup(parent, buttons4, y4, buttonWidth, buttonHeight, spacing);
    
    % 第五组：系统操作
    y5 = startY - 8*(buttonHeight+spacing) - 3*groupSpacing;
    createButtonGroupLabel(parent, '系统操作', 10, y5 + 5);
    buttons5 = {
        {'重置所有', @resetAll_placeholder, [0.8, 0.2, 0.2]}, ...
        {'使用帮助', @showHelp_placeholder, [0.2, 0.6, 0.8]}
    };
    createButtonGroup(parent, buttons5, y5, buttonWidth, buttonHeight, spacing);
    
    % 工作日志面板
    createWorkLogPanel(parent, 10);
end

%% 辅助函数
function createButtonGroupLabel(parent, labelText, x, y)
    % 创建按钮组标签
    uicontrol('Parent', parent, 'Style', 'text', ...
             'String', labelText, ...
             'Position', [x, y, 100, 20], ...
             'FontSize', 12, 'FontWeight', 'bold', ...
             'ForegroundColor', [0.8, 0.9, 1], ...
             'BackgroundColor', [0.1, 0.2, 0.3], ...
             'HorizontalAlignment', 'left');
end

function createButtonGroup(parent, buttons, startY, width, height, spacing)
    % 创建一组按钮
    for i = 1:length(buttons)
        buttonInfo = buttons{i};
        yPos = startY - (i-1) * (height + spacing);
        
        uicontrol('Parent', parent, 'Style', 'pushbutton', ...
                 'String', buttonInfo{1}, ...
                 'Position', [10, yPos, width, height], ...
                 'FontSize', 11, 'FontWeight', 'bold', ...
                 'BackgroundColor', buttonInfo{3}, ...
                 'ForegroundColor', [1, 1, 1], ...
                 'Callback', buttonInfo{2});
    end
end

function createWorkLogPanel(parent, startY)
    % 创建工作日志面板
    workLogPanel = uipanel('Parent', parent, ...
                         'Title', '操作日志', ...
                         'Units', 'pixels', ...
                         'Position', [10, startY, 215, 200], ...
                         'BackgroundColor', [0.15, 0.25, 0.35], ...
                         'ForegroundColor', [1, 1, 1], ...
                         'FontSize', 11, ...
                         'FontWeight', 'bold');
    
    workLogText = uicontrol('Parent', workLogPanel, ...
                          'Style', 'listbox', ...
                          'String', {'系统初始化完成', '欢迎使用DSA分析系统'}, ...
                          'Position', [10, 30, 195, 115], ...
                          'FontSize', 9, ...
                          'BackgroundColor', [0.05, 0.1, 0.15], ...
                          'ForegroundColor', [0.8, 0.9, 1], ...
                          'Max', 100, 'Min', 0);
    
    % 日志控制按钮
    uicontrol('Parent', workLogPanel, 'Style', 'pushbutton', ...
             'String', '清空', 'Position', [10, 5, 55, 20], ...
             'FontSize', 8, ...
             'BackgroundColor', [0.6, 0.2, 0.2], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', @clearWorkLog);
    
    uicontrol('Parent', workLogPanel, 'Style', 'pushbutton', ...
             'String', '导出', 'Position', [72, 5, 55, 20], ...
             'FontSize', 8, ...
             'BackgroundColor', [0.2, 0.5, 0.8], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', @exportWorkLog);
    
    uicontrol('Parent', workLogPanel, 'Style', 'pushbutton', ...
             'String', '详细', 'Position', [134, 5, 55, 20], ...
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
end

function showDetailedLog(~,~)
    % 显示详细日志窗口
    workLogData = getappdata(gcf, 'workLogData');
    if isempty(workLogData)
        msgbox('工作日志为空', '工作日志');
        return;
    end
    
    logFig = figure('Name', '详细工作日志', ...
                   'NumberTitle', 'off', ...
                   'Position', [300, 200, 800, 600], ...
                   'MenuBar', 'none', ...
                   'ToolBar', 'none', ...
                   'Color', [0.95, 0.95, 0.95]);
    
    uicontrol('Parent', logFig, 'Style', 'listbox', ...
              'String', workLogData, ...
              'Position', [20, 50, 760, 500], ...
              'FontSize', 10, ...
              'BackgroundColor', [1, 1, 1], ...
              'ForegroundColor', [0.1, 0.1, 0.1], ...
              'Max', 2);
    
    totalEntries = length(workLogData);
    todayEntries = sum(contains(workLogData, datestr(now, 'yyyy-mm-dd')));
    infoText = sprintf('总日志条目: %d | 今日条目: %d', totalEntries, todayEntries);
    
    uicontrol('Parent', logFig, 'Style', 'text', ...
             'String', infoText, ...
             'Position', [20, 560, 300, 25], ...
             'FontSize', 11, 'FontWeight', 'bold', ...
             'BackgroundColor', [0.95, 0.95, 0.95], ...
             'HorizontalAlignment', 'left');
    
    uicontrol('Parent', logFig, 'Style', 'pushbutton', ...
             'String', '关闭', 'Position', [690, 560, 80, 25], ...
             'FontSize', 10, ...
             'BackgroundColor', [0.8, 0.2, 0.2], ...
             'ForegroundColor', [1, 1, 1], ...
             'Callback', 'delete(gcf)');
end

%% 占位回调函数（待实现）
function importDSA_placeholder(~,~)
    msgbox('此功能需要从原文件提取 importDSA 函数', '功能未实现');
end

function selectFrames_placeholder(~,~)
    msgbox('此功能需要从原文件提取 selectFrames 函数', '功能未实现');
end

function placeROI_placeholder(~,~)
    msgbox('此功能需要从原文件提取 placeROI 函数', '功能未实现');
end

function extractTDC_placeholder(~,~)
    msgbox('此功能需要从原文件提取 extractTDC 函数', '功能未实现');
end

function analyzeCurves_placeholder(~,~)
    msgbox('此功能需要从原文件提取 analyzeCurves 函数', '功能未实现');
end

function showResults_placeholder(~,~)
    msgbox('此功能需要从原文件提取 showResults 函数', '功能未实现');
end

function exportData_placeholder(~,~)
    msgbox('此功能需要从原文件提取 exportData 函数', '功能未实现');
end

function comparePrePost_placeholder(~,~)
    msgbox('此功能需要从原文件提取 comparePrePost 函数', '功能未实现');
end

function resetAll_placeholder(~,~)
    selection = questdlg('确定要重置所有数据吗？', '重置确认', '是', '否', '否');
    if strcmp(selection, '是')
        msgbox('重置功能待实现', '提示');
    end
end

function showHelp_placeholder(~,~)
    helpText = {
        'DSA脑血流灌注分析系统 使用帮助'
        ''
        '功能说明:'
        '1. 导入DSA数据 - 导入DICOM格式的DSA影像'
        '2. 选择分析帧 - 选择需要分析的帧范围'
        '3. 放置ROI - 在4个脑叶各放置3个感兴趣区域'
        '4. 提取TDC - 提取时间密度曲线'
        '5. 分析曲线 - 进行曲线分析和参数计算'
        '6. 显示结果 - 显示分析结果和风险评估'
        ''
        '注意: 当前为重构版本，部分功能需要从原文件提取'
    };
    msgbox(helpText, 'DSA分析系统帮助', 'help');
end
>>>>>>> 4d5e5c9 (Initial commit)
