function DSA_Analysis_GUI_Refactored
    % DSA脑血流灌注分析系统 - 重构版本
    % 版本: v3.0 Refactored
    % 说明: 模块化设计，功能分离到独立文件
    
    % 添加模块路径
    addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'modules')));
    
    %% 1. 清理工作区
    clear variables;
    clc;
    
    disp('=== DSA脑血流灌注分析系统 v3.0 (重构版) ===');
    disp('正在初始化系统...');
    
    %% 2. 获取患者信息
    patientInfo = io_getPatientInformation();
    if isempty(patientInfo)
        disp('用户取消了患者信息输入');
        return;
    end
    
    %% 3. 创建主窗口
    fig = createMainWindow();
    setappdata(fig, 'patientInfo', patientInfo);
    
    %% 4. 创建UI布局
    [controlPanel, displayPanel, infoPanel] = createLayout(fig);
    
    %% 5. 构建UI元素
    createTitleBar(fig);
    createControlButtons(controlPanel);
    createDisplayArea(displayPanel);
    createInfoArea(infoPanel, patientInfo);
    
    %% 6. 初始化数据容器
    io_initializeDataContainer(fig);
    
    %% 7. 系统就绪
    log_updateStatus('系统就绪 - 请导入术前DSA数据');
    disp('系统初始化完成！');
end

function fig = createMainWindow()
    % 创建主窗口
    screenSize = get(0, 'ScreenSize');
    screenWidth = screenSize(3);
    screenHeight = screenSize(4);
    
    windowWidth = 1400;
    windowHeight = 850;
    windowX = round((screenWidth - windowWidth) / 2);
    windowY = round((screenHeight - windowHeight) / 2);
    
    fig = figure('Name', 'DSA脑血流灌注分析系统 v3.0 (重构版)', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Position', [windowX, windowY, windowWidth, windowHeight], ...
                'Color', [0.07, 0.15, 0.25], ...
                'Resize', 'off', ...
                'CloseRequestFcn', @closeGUI);
end

function [controlPanel, displayPanel, infoPanel] = createLayout(fig)
    % 创建三列布局
    
    % 左侧控制面板
    controlPanel = uipanel('Parent', fig, ...
                          'Title', '', ...
                          'Position', [0.01, 0.05, 0.18, 0.86], ...
                          'BackgroundColor', [0.1, 0.2, 0.3], ...
                          'ForegroundColor', [1, 1, 1], ...
                          'BorderType', 'line', ...
                          'HighlightColor', [0, 0.6, 0.8]);
    
    % 中间显示区域
    displayPanel = uipanel('Parent', fig, ...
                          'Title', '', ...
                          'Position', [0.20, 0.05, 0.58, 0.86], ...
                          'BackgroundColor', [0.05, 0.1, 0.15], ...
                          'BorderType', 'line', ...
                          'HighlightColor', [0, 0.6, 0.8]);
    
    % 右侧信息面板
    infoPanel = uipanel('Parent', fig, ...
                       'Title', '', ...
                       'Position', [0.79, 0.05, 0.20, 0.86], ...
                       'BackgroundColor', [0.1, 0.2, 0.3], ...
                       'BorderType', 'line', ...
                       'HighlightColor', [0, 0.6, 0.8]);
end

function closeGUI(src, ~)
    % 关闭GUI回调
    selection = questdlg('确定要关闭系统吗？', ...
                        '退出确认', ...
                        '是', '否', '否');
    if strcmp(selection, '是')
        delete(src);
    end
end
