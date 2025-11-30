function DSA_Analysis_GUI_Refactored
    % DSA脑血流灌注分析系统 - 重构版本
    % 版本: v3.0 Refactored
    % 说明: 模块化设计，功能分离到独立文件
    
    % 添加模块路径
    addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'modules')));
    % 确保 MATLAB 刷新函数缓存，避免编辑后函数不可识别的问题
    rehash;
    % 如果关键工具函数仍然不可见，再次添加并刷新（兼容交互式运行场景）
    if ~exist('utils_showMessage', 'file')
        warning('utils_showMessage 未在路径中，尝试再次添加 modules 目录并刷新路径');
        addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'modules')));
        rehash;
    end
    
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
    
    %% 7. 弹出目录选择窗口
    try
        if exist('createDirectorySelector', 'file') == 2
            createDirectorySelector(fig);
        end
    catch ME
        warning('目录选择窗口启动失败: %s', ME.message);
    end
    
    %% 8. 系统就绪
    log_updateStatus('系统就绪 - 请导入术前DSA数据');
    disp('系统初始化完成！');
end

function fig = createMainWindow()
    % 创建主窗口（全屏模式，现代医疗风格）
    screenSize = get(0, 'ScreenSize');
    
    fig = figure('Name', 'DSA脑血流灌注分析系统 v3.0 (重构版)', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Position', screenSize, ...
                'Color', [0.95, 0.97, 1], ...
                'WindowState', 'maximized', ...
                'CloseRequestFcn', @closeGUI);
end

function [controlPanel, displayPanel, infoPanel] = createLayout(fig)
    % 创建三列布局
    
    % 左侧控制面板（卡片风格）
    controlPanel = uipanel('Parent', fig, ...
                          'Title', '', ...
                          'Position', [0.01, 0.05, 0.18, 0.86], ...
                          'BackgroundColor', [1, 1, 1], ...
                          'ForegroundColor', [0.2, 0.3, 0.4], ...
                          'BorderType', 'none', ...
                          'ShadowColor', [0.85, 0.85, 0.85]);
    
    % 中间显示区域（浅色面板边框，内部图像保持深色）
    displayPanel = uipanel('Parent', fig, ...
                          'Title', '', ...
                          'Position', [0.20, 0.05, 0.58, 0.86], ...
                          'BackgroundColor', [0.96, 0.97, 0.99], ...
                          'BorderType', 'none', ...
                          'ShadowColor', [0.85, 0.85, 0.85]);
    
    % 右侧信息面板（卡片风格）
    infoPanel = uipanel('Parent', fig, ...
                       'Title', '', ...
                       'Position', [0.79, 0.05, 0.20, 0.86], ...
                       'BackgroundColor', [1, 1, 1], ...
                       'BorderType', 'none', ...
                       'ShadowColor', [0.85, 0.85, 0.85]);
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
