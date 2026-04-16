function WorkflowGUI(mainFig)
% WORKFLOWGUI 三段式导航诊断流界面
% 这个新UI模式将14个分散的按钮整合为3个逻辑诊断阶段
%
% 设计理念：
%   •一键诊断→精细分析→报告生成 (医学诊断流，不是工具箱)
%   •医生只做最后的诊断确认，其他全由算法自动化
%   •状态机控制防止逻辑错误和并发操作
%
% 用法:
%   WorkflowGUI(mainFig)  % 创建三段式导航面板
%   WorkflowGUI('advanced')  % 切换到高级模式（显示原有14按钮）

if nargin < 1
    mainFig = gcf;
end

if ischar(mainFig) && strcmp(mainFig, 'advanced')
    % 切换回高级模式（原有14按钮）
    switchToAdvancedMode();
    return;
end

% ======= 初始化状态机 =======
% 定义UI状态枚举
UIState.IDLE = 0;           % 就绪，等待用户操作
UIState.SCANNING = 1;       % 执行全脑扫描中
UIState.ANALYZING = 2;      % 执行精细分析中
UIState.EXPORTING = 3;      % 导出报告中
setappdata(mainFig, 'workflowState', UIState.IDLE);

log_updateStatus('诊断流系统已初始化');
log_addWorkLog('启动三段式导航工作流 (v3.2 Workflow Mode)');

% ======= 获取或创建工作流面板 =======
existingWorkflowPanel = findobj(mainFig, 'Tag', 'workflowMainPanel');
if ~isempty(existingWorkflowPanel)
    delete(existingWorkflowPanel);
end

% 使用已创建的左侧控制面板
leftPanel = getappdata(mainFig, 'controlPanel');
if isempty(leftPanel)
    % 如果没有controlPanel，创建左侧面板
    leftPanel = uipanel('Parent', mainFig, ...
        'Units', 'normalized', ...
        'Position', [0, 0, 0.2, 1], ...
        'Tag', 'leftControlPanel', ...
        'BackgroundColor', [1, 1, 1]);
end

% ======= 创建三个逻辑诊断区域 =======

% 区域1：全脑扫描入口 (45% 面板高度)
createFullBrainScanSection(mainFig, leftPanel, 0.95, 0.52);

% 区域2：精细分析 (30% 面板高度)
createInteractiveAnalysisSection(mainFig, leftPanel, 0.50, 0.20);

% 区域3：报告生成 (20% 面板高度)
createReportGenerationSection(mainFig, leftPanel, 0.18, 0.02);

% 标记主面板已创建
setappdata(mainFig, 'workflowModeActive', true);

end

% ======================================================================
% 第一阶段：全脑扫描入口
% ======================================================================
function createFullBrainScanSection(mainFig, parentPanel, top, bottom)

% 创建容器面板
scanPanel = uipanel('Parent', parentPanel, ...
    'Title', '【第一阶段】一键全脑诊断', ...
    'Units', 'normalized', ...
    'Position', [0.02, bottom, 0.96, top - bottom], ...
    'BackgroundColor', [0.95, 0.98, 0.95], ...
    'ForegroundColor', [0.1, 0.4, 0.1], ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'BorderType', 'line');

% 说明文字（修复：移除 VerticalAlignment 属性）
infoText = uicontrol('Parent', scanPanel, ...
    'Style', 'text', ...
    'String', sprintf(['自动执行：\n' ...
                      '1️⃣ 导入DICOM数据\n' ...
                      '2️⃣ 全像素TDC提取\n' ...
                      '3️⃣ 血流参数计算\n' ...
                      '4️⃣ 自动标注最危险点\n\n' ...
                      '耗时：约 5-10 秒']), ...
    'Units', 'normalized', ...
    'Position', [0.05, 0.45, 0.9, 0.40], ...
    'FontSize', 9, ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', [0.95, 0.98, 0.95], ...
    'ForegroundColor', [0.2, 0.5, 0.2]);

% 主按钮：一键全脑诊断
scanButton = uicontrol('Parent', scanPanel, ...
    'Style', 'pushbutton', ...
    'String', '🟢 一键全脑诊断', ...
    'Units', 'normalized', ...
    'Position', [0.05, 0.08, 0.9, 0.35], ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.2, 0.8, 0.3], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', {@workflow_fullBrainScan_callback, mainFig});

setappdata(mainFig, 'scanButton', scanButton);
setappdata(mainFig, 'scanPanel', scanPanel);

end

% ======================================================================
% 第二阶段：精细分析区域
% ======================================================================
function createInteractiveAnalysisSection(mainFig, parentPanel, top, bottom)

% 创建容器面板
analysisPanel = uipanel('Parent', parentPanel, ...
    'Title', '【第二阶段】交互式精细分析', ...
    'Units', 'normalized', ...
    'Position', [0.02, bottom, 0.96, top - bottom], ...
    'BackgroundColor', [0.95, 0.97, 1], ...
    'ForegroundColor', [0.1, 0.3, 0.5], ...
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'BorderType', 'line');

% 说明文字（修复：移除 VerticalAlignment 属性）
infoText = uicontrol('Parent', analysisPanel, ...
    'Style', 'text', ...
    'String', sprintf('在右侧彩图上点击任意区域\n→ 实时显示该点TDC曲线\n→ 自动分类：正常/半暗带/核心'), ...
    'Units', 'normalized', ...
    'Position', [0.05, 0.55, 0.9, 0.38], ...
    'FontSize', 8, ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', [0.95, 0.97, 1], ...
    'ForegroundColor', [0.2, 0.3, 0.5]);

% 启用交互分析按钮
interactButton = uicontrol('Parent', analysisPanel, ...
    'Style', 'togglebutton', ...
    'String', '🔵 启用点击分析', ...
    'Units', 'normalized', ...
    'Position', [0.05, 0.15, 0.9, 0.35], ...
    'FontSize', 11, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.2, 0.6, 0.8], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', {@workflow_interactiveAnalysis_callback, mainFig});

setappdata(mainFig, 'interactButton', interactButton);
setappdata(mainFig, 'analysisPanel', analysisPanel);

end

% ======================================================================
% 第三阶段：报告生成区域
% ======================================================================
function createReportGenerationSection(mainFig, parentPanel, top, bottom)

% 创建容器面板
reportPanel = uipanel('Parent', parentPanel, ...
    'Title', '【第三阶段】量化报告', ...
    'Units', 'normalized', ...
    'Position', [0.02, bottom, 0.96, top - bottom], ...
    'BackgroundColor', [1, 0.98, 0.95], ...
    'ForegroundColor', [0.5, 0.3, 0.1], ...
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'BorderType', 'line');

% 两个并排子按钮
% 按钮1：对比报告
compareBtn = uicontrol('Parent', reportPanel, ...
    'Style', 'pushbutton', ...
    'String', '比较报告', ...
    'Units', 'normalized', ...
    'Position', [0.05, 0.10, 0.43, 0.75], ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.8, 0.6, 0.2], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', {@workflow_generateReport_callback, mainFig, 'compare'});

% 按钮2：诊断报告
reportBtn = uicontrol('Parent', reportPanel, ...
    'Style', 'pushbutton', ...
    'String', '诊断报告', ...
    'Units', 'normalized', ...
    'Position', [0.52, 0.10, 0.43, 0.75], ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.7, 0.5, 0.3], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', {@workflow_generateReport_callback, mainFig, 'diagnosis'});

setappdata(mainFig, 'reportPanel', reportPanel);

end

% ======================================================================
% 回调函数
% ======================================================================

function workflow_fullBrainScan_callback(src, ~, mainFig)
% 一键全脑诊断回调
% 执行：导入 → 参数计算 → Tmax检测 → 曲线预览

try
    % 设置状态为扫描中
    setappdata(mainFig, 'workflowState', 1);  % SCANNING
    disableAllWorkflowButtons(mainFig);
    
    % 调用工作流函数
    workflow_fullBrainScan(mainFig);
    
    % 恢复状态为就绪
    setappdata(mainFig, 'workflowState', 0);  % IDLE
    enableAllWorkflowButtons(mainFig);
    
catch ME
    setappdata(mainFig, 'workflowState', 0);
    enableAllWorkflowButtons(mainFig);
    utils_showMessage('诊断流错误', 'error', ME.message);
    log_addWorkLog(sprintf('错误: 全脑扫描失败 - %s', ME.message));
end

end

function workflow_interactiveAnalysis_callback(src, ~, mainFig)
% 交互式分析回调
% 点击图像，实时显示TDC曲线

try
    isEnabled = get(src, 'Value');
    
    if isEnabled
        set(src, 'String', '🔵 分析中... (点击图像)', ...
                 'BackgroundColor', [0.1, 0.5, 0.8]);
        
        workflow_interactiveAnalysis(mainFig);
        
        set(src, 'String', '🔵 启用点击分析', ...
                 'BackgroundColor', [0.2, 0.6, 0.8]);
    else
        set(src, 'String', '🔵 启用点击分析', ...
                 'BackgroundColor', [0.2, 0.6, 0.8]);
    end
    
catch ME
    set(src, 'Value', 0);
    set(src, 'String', '🔵 启用点击分析', ...
             'BackgroundColor', [0.2, 0.6, 0.8]);
    utils_showMessage('交互分析错误', 'error', ME.message);
end

end

function workflow_generateReport_callback(src, ~, mainFig, reportType)
% 报告生成回调
% reportType: 'compare' 或 'diagnosis'

try
    setappdata(mainFig, 'workflowState', 3);  % EXPORTING
    disableAllWorkflowButtons(mainFig);
    
    workflow_generateReport(mainFig, reportType);
    
    setappdata(mainFig, 'workflowState', 0);  % IDLE
    enableAllWorkflowButtons(mainFig);
    
catch ME
    setappdata(mainFig, 'workflowState', 0);
    enableAllWorkflowButtons(mainFig);
    utils_showMessage('报告生成错误', 'error', ME.message);
end

end

% ======================================================================
% 辅助函数：状态机控制
% ======================================================================

function disableAllWorkflowButtons(mainFig)
% 禁用所有工作流按钮
scanBtn = getappdata(mainFig, 'scanButton');
interactBtn = getappdata(mainFig, 'interactButton');

if ~isempty(scanBtn) && ishandle(scanBtn)
    set(scanBtn, 'Enable', 'off', 'ForegroundColor', [0.6, 0.6, 0.6]);
end

if ~isempty(interactBtn) && ishandle(interactBtn)
    set(interactBtn, 'Enable', 'off', 'ForegroundColor', [0.6, 0.6, 0.6]);
end
end

function enableAllWorkflowButtons(mainFig)
% 启用所有工作流按钮
scanBtn = getappdata(mainFig, 'scanButton');
interactBtn = getappdata(mainFig, 'interactButton');

if ~isempty(scanBtn) && ishandle(scanBtn)
    set(scanBtn, 'Enable', 'on', 'ForegroundColor', [1, 1, 1]);
end

if ~isempty(interactBtn) && ishandle(interactBtn)
    set(interactBtn, 'Enable', 'on', 'ForegroundColor', [1, 1, 1]);
end
end

function switchToAdvancedMode()
% 切换回高级模式（原有14按钮）
warning('高级模式尚未实现，请使用createControlButtons()');
end
