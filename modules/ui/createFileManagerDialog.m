function createFileManagerDialog(varargin)
% 创建双开门式文件管理器（类似PANDA）
% 左侧：原始病人数据（DICOM影像等）
% 右侧：系统生成的分析结果文件

% 获取主窗口
mainFig = gcf;

% 获取或创建数据根目录
dataContainer = getappdata(mainFig, 'dataContainer');
if isempty(dataContainer) || ~isfield(dataContainer, 'patientInfo')
    patientID = 'Unknown';
    patientName = '未录入';
else
    patientID = getFieldOrDefault(dataContainer.patientInfo, 'id', 'Unknown');
    patientName = getFieldOrDefault(dataContainer.patientInfo, 'name', '未录入');
end

% 创建对话框窗口
screenSize = get(0, 'ScreenSize');
dialogWidth = 1200;
dialogHeight = 700;
dialogX = (screenSize(3) - dialogWidth) / 2;
dialogY = (screenSize(4) - dialogHeight) / 2;

dlg = figure('Name', sprintf('文件管理器 - 患者: %s (%s)', patientName, patientID), ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'Position', [dialogX, dialogY, dialogWidth, dialogHeight], ...
    'Color', [0.95, 0.97, 1], ...
    'Resize', 'on', ...
    'WindowStyle', 'normal');

% 顶部标题栏
titlePanel = uipanel('Parent', dlg, ...
    'Position', [0, 0.92, 1, 0.08], ...
    'BackgroundColor', [0.2, 0.6, 0.95], ...
    'BorderType', 'none');

uicontrol('Parent', titlePanel, ...
    'Style', 'text', ...
    'String', '📂 文件管理器', ...
    'Units', 'normalized', ...
    'Position', [0.01, 0.2, 0.98, 0.6], ...
    'FontSize', 18, ...
    'FontWeight', 'bold', ...
    'ForegroundColor', [1, 1, 1], ...
    'BackgroundColor', [0.2, 0.6, 0.95], ...
    'HorizontalAlignment', 'center');

% ===== 左侧面板：原始病人数据 =====
leftPanel = uipanel('Parent', dlg, ...
    'Title', '📥 原始病人数据', ...
    'Position', [0.02, 0.05, 0.47, 0.85], ...
    'BackgroundColor', [1, 1, 1], ...
    'ForegroundColor', [0.2, 0.5, 0.7], ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'BorderType', 'line', ...
    'BorderWidth', 2);

% 左侧工具栏
uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', '📥 导入DSA数据', ...
    'Units', 'normalized', ...
    'Position', [0.03, 0.92, 0.18, 0.06], ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.3, 0.65, 0.92], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)importDICOMCallback(dlg));

uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', '➡️ 导入选中文件', ...
    'Units', 'normalized', ...
    'Position', [0.22, 0.92, 0.20, 0.06], ...
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.95, 0.65, 0.25], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)loadToSystemCallback(dlg));

uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', '刷新', ...
    'Units', 'normalized', ...
    'Position', [0.43, 0.92, 0.12, 0.06], ...
    'FontSize', 9, ...
    'BackgroundColor', [0.35, 0.75, 0.45], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)refreshLeftPanel(dlg));

uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', '打开文件夹', ...
    'Units', 'normalized', ...
    'Position', [0.56, 0.92, 0.18, 0.06], ...
    'FontSize', 9, ...
    'BackgroundColor', [0.65, 0.45, 0.85], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)openLeftFolder(dlg));

uicontrol('Parent', leftPanel, ...
    'Style', 'pushbutton', ...
    'String', '清空', ...
    'Units', 'normalized', ...
    'Position', [0.75, 0.92, 0.12, 0.06], ...
    'FontSize', 9, ...
    'BackgroundColor', [0.92, 0.4, 0.4], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)clearLeftFolder(dlg));

% 左侧文件信息面板
uicontrol('Parent', leftPanel, ...
    'Style', 'text', ...
    'String', '文件列表', ...
    'Units', 'normalized', ...
    'Position', [0.03, 0.88, 0.45, 0.03], ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'ForegroundColor', [0.3, 0.5, 0.7], ...
    'BackgroundColor', [1, 1, 1], ...
    'HorizontalAlignment', 'left');

leftInfoText = uicontrol('Parent', leftPanel, ...
    'Style', 'text', ...
    'String', '0 个文件', ...
    'Units', 'normalized', ...
    'Position', [0.50, 0.88, 0.47, 0.03], ...
    'FontSize', 9, ...
    'ForegroundColor', [0.5, 0.5, 0.5], ...
    'BackgroundColor', [1, 1, 1], ...
    'HorizontalAlignment', 'right');

% 左侧文件列表（支持多选）
leftListBox = uicontrol('Parent', leftPanel, ...
    'Style', 'listbox', ...
    'Units', 'normalized', ...
    'Position', [0.03, 0.02, 0.94, 0.85], ...
    'FontSize', 10, ...
    'BackgroundColor', [0.98, 0.99, 1], ...
    'Max', 2, ...
    'Min', 0, ...
    'Callback', @(~,~)updateLeftFileInfo(dlg));

% ===== 右侧面板：系统生成文件 =====
rightPanel = uipanel('Parent', dlg, ...
    'Title', '📤 系统生成结果', ...
    'Position', [0.51, 0.05, 0.47, 0.85], ...
    'BackgroundColor', [1, 1, 1], ...
    'ForegroundColor', [0.8, 0.4, 0.2], ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'BorderType', 'line', ...
    'BorderWidth', 2);

% 右侧工具栏
uicontrol('Parent', rightPanel, ...
    'Style', 'pushbutton', ...
    'String', '导出分析结果', ...
    'Units', 'normalized', ...
    'Position', [0.03, 0.92, 0.25, 0.06], ...
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.95, 0.65, 0.25], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)exportResultCallback(dlg));

uicontrol('Parent', rightPanel, ...
    'Style', 'pushbutton', ...
    'String', '刷新', ...
    'Units', 'normalized', ...
    'Position', [0.30, 0.92, 0.15, 0.06], ...
    'FontSize', 10, ...
    'BackgroundColor', [0.35, 0.75, 0.45], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)refreshRightPanel(dlg));

uicontrol('Parent', rightPanel, ...
    'Style', 'pushbutton', ...
    'String', '打开', ...
    'Units', 'normalized', ...
    'Position', [0.47, 0.92, 0.12, 0.06], ...
    'FontSize', 10, ...
    'BackgroundColor', [0.65, 0.45, 0.85], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)openRightFile(dlg));

uicontrol('Parent', rightPanel, ...
    'Style', 'pushbutton', ...
    'String', '删除', ...
    'Units', 'normalized', ...
    'Position', [0.60, 0.92, 0.12, 0.06], ...
    'FontSize', 10, ...
    'BackgroundColor', [0.92, 0.4, 0.4], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)deleteRightFile(dlg));

uicontrol('Parent', rightPanel, ...
    'Style', 'pushbutton', ...
    'String', '⚖️ 术前术后对比', ...
    'Units', 'normalized', ...
    'Position', [0.73, 0.92, 0.24, 0.06], ...
    'FontSize', 10, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.3, 0.55, 0.85], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)compareAnalysisCallback(dlg));

% 右侧文件信息面板
uicontrol('Parent', rightPanel, ...
    'Style', 'text', ...
    'String', '生成文件列表', ...
    'Units', 'normalized', ...
    'Position', [0.03, 0.88, 0.45, 0.03], ...
    'FontSize', 9, ...
    'FontWeight', 'bold', ...
    'ForegroundColor', [0.8, 0.4, 0.2], ...
    'BackgroundColor', [1, 1, 1], ...
    'HorizontalAlignment', 'left');

rightInfoText = uicontrol('Parent', rightPanel, ...
    'Style', 'text', ...
    'String', '0 个文件', ...
    'Units', 'normalized', ...
    'Position', [0.50, 0.88, 0.47, 0.03], ...
    'FontSize', 9, ...
    'ForegroundColor', [0.5, 0.5, 0.5], ...
    'BackgroundColor', [1, 1, 1], ...
    'HorizontalAlignment', 'right');

% 右侧文件列表（支持多选）
rightListBox = uicontrol('Parent', rightPanel, ...
    'Style', 'listbox', ...
    'Units', 'normalized', ...
    'Position', [0.03, 0.02, 0.94, 0.85], ...
    'FontSize', 10, ...
    'BackgroundColor', [1, 0.99, 0.97], ...
    'Max', 2, ...
    'Min', 0, ...
    'Callback', @(~,~)updateRightFileInfo(dlg));

% 底部状态栏
statusText = uicontrol('Parent', dlg, ...
    'Style', 'text', ...
    'String', '就绪', ...
    'Units', 'normalized', ...
    'Position', [0.02, 0.01, 0.65, 0.03], ...
    'FontSize', 9, ...
    'ForegroundColor', [0.3, 0.5, 0.7], ...
    'BackgroundColor', [0.95, 0.97, 1], ...
    'HorizontalAlignment', 'left');


uicontrol('Parent', dlg, ...
    'Style', 'pushbutton', ...
    'String', '关闭', ...
    'Units', 'normalized', ...
    'Position', [0.85, 0.01, 0.13, 0.03], ...
    'FontSize', 10, ...
    'BackgroundColor', [0.85, 0.3, 0.3], ...
    'ForegroundColor', [1, 1, 1], ...
    'Callback', @(~,~)close(dlg));

% 存储控件句柄
setappdata(dlg, 'leftListBox', leftListBox);
setappdata(dlg, 'rightListBox', rightListBox);
setappdata(dlg, 'leftInfoText', leftInfoText);
setappdata(dlg, 'rightInfoText', rightInfoText);
setappdata(dlg, 'statusText', statusText);
setappdata(dlg, 'patientID', patientID);
setappdata(dlg, 'patientName', patientName);

% 初始化文件路径
initializeFilePaths(dlg);

% 加载文件列表
refreshLeftPanel(dlg);
refreshRightPanel(dlg);
end

%% ========== 初始化文件路径 ==========
function initializeFilePaths(dlg)
% 创建数据目录结构
baseDir = pwd;
dataDir = fullfile(baseDir, 'PatientData');

patientID = getappdata(dlg, 'patientID');
patientFolder = fullfile(dataDir, patientID);

% 左侧：原始数据目录
rawDataDir = fullfile(patientFolder, 'RawData');
if ~exist(rawDataDir, 'dir')
    mkdir(rawDataDir);
end

% 右侧：分析结果目录
resultsDir = fullfile(patientFolder, 'Results');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

setappdata(dlg, 'rawDataDir', rawDataDir);
setappdata(dlg, 'resultsDir', resultsDir);
% 当前浏览目录（用于文件夹导航）
setappdata(dlg, 'currentBrowseDir', rawDataDir);

updateStatus(dlg, sprintf('数据目录: %s', patientFolder));
end

%% ========== 左侧面板刷新 ==========
function refreshLeftPanel(dlg)
leftListBox = getappdata(dlg, 'leftListBox');
rawDataDir = getappdata(dlg, 'rawDataDir');

% 获取当前浏览目录，如果没有则使用根目录
currentDir = getappdata(dlg, 'currentBrowseDir');
if isempty(currentDir)
    currentDir = rawDataDir;
    setappdata(dlg, 'currentBrowseDir', currentDir);
end

if ~exist(currentDir, 'dir')
    set(leftListBox, 'String', {'目录不存在'});
    return;
end

% 扫描所有文件和文件夹
items = dir(currentDir);
fileList = {};
filePaths = {};

% 如果不在根目录，添加返回上级选项
if ~strcmp(currentDir, rawDataDir)
    fileList{end+1} = '⬆️ .. [返回上级目录]';
    filePaths{end+1} = '..';  % 特殊标记
end

for i = 1:length(items)
    % 跳过 . 和 ..
    if strcmp(items(i).name, '.') || strcmp(items(i).name, '..')
        continue;
    end
    
    itemPath = fullfile(currentDir, items(i).name);
    
    if items(i).isdir
        % 文件夹：显示文件夹图标和包含的文件数量
        fileCount = countFilesRecursive(itemPath);
        dateStr = items(i).date;
        displayName = sprintf('📁 %s  [%d 个文件, %s]', items(i).name, fileCount, dateStr);
        fileList{end+1} = displayName;
        filePaths{end+1} = itemPath;
    else
        % 文件：正常显示
        sizeStr = formatFileSize(items(i).bytes);
        dateStr = items(i).date;
        displayName = sprintf('📄 %s  [%s, %s]', items(i).name, sizeStr, dateStr);
        fileList{end+1} = displayName;
        filePaths{end+1} = itemPath;
    end
end

if isempty(fileList)
    fileList = {'(空) 暂无原始数据文件'};
    filePaths = {''};
end

set(leftListBox, 'String', fileList, 'Value', []);
setappdata(dlg, 'leftFilePaths', filePaths);

% 更新文件计数和路径显示
leftInfoText = getappdata(dlg, 'leftInfoText');
if ~isempty(leftInfoText) && ishandle(leftInfoText)
    % 显示当前路径
    [~, currentFolderName] = fileparts(currentDir);
    if strcmp(currentDir, rawDataDir)
        pathDisplay = '根目录';
    else
        pathDisplay = currentFolderName;
    end
    actualCount = length(filePaths);
    if strcmp(currentDir, rawDataDir)
        % 根目录不算 ".." 项
    else
        actualCount = actualCount - 1;  % 减去 ".." 项
    end
    if actualCount < 0
        actualCount = 0;
    end
    set(leftInfoText, 'String', sprintf('📂 %s | %d 项', pathDisplay, actualCount));
end

updateStatus(dlg, sprintf('当前目录: %s', currentDir));
end

%% ========== 右侧面板刷新 ==========
function refreshRightPanel(dlg)
rightListBox = getappdata(dlg, 'rightListBox');
resultsDir = getappdata(dlg, 'resultsDir');

if ~exist(resultsDir, 'dir')
    set(rightListBox, 'String', {'目录不存在'});
    return;
end

% 扫描所有文件
files = dir(resultsDir);
fileList = {};
filePaths = {};

for i = 1:length(files)
    if ~files(i).isdir
        fileInfo = files(i);
        sizeStr = formatFileSize(fileInfo.bytes);
        dateStr = fileInfo.date;
        
        % 根据文件类型添加图标
        [~, ~, ext] = fileparts(fileInfo.name);
        if strcmpi(ext, '.mat')
            icon = '💾';
        elseif any(strcmpi(ext, {'.xls', '.xlsx', '.csv'}))
            icon = '📊';
        elseif any(strcmpi(ext, {'.png', '.jpg', '.jpeg', '.bmp'}))
            icon = '🖼️';
        elseif any(strcmpi(ext, {'.txt', '.log', '.md'}))
            icon = '📝';
        else
            icon = '📄';
        end
        
        displayName = sprintf('%s %s  [%s, %s]', icon, fileInfo.name, sizeStr, dateStr);
        fileList{end+1} = displayName;
        filePaths{end+1} = fullfile(resultsDir, fileInfo.name);
    end
end

if isempty(fileList)
    fileList = {'(空) 暂无分析结果文件'};
    filePaths = {''};
end

set(rightListBox, 'String', fileList, 'Value', []);
setappdata(dlg, 'rightFilePaths', filePaths);

% 更新文件计数
rightInfoText = getappdata(dlg, 'rightInfoText');
if ~isempty(rightInfoText) && ishandle(rightInfoText)
    actualCount = length(filePaths);
    if actualCount == 1 && isempty(filePaths{1})
        actualCount = 0;
    end
    set(rightInfoText, 'String', sprintf('共 %d 个文件', actualCount));
end

updateStatus(dlg, sprintf('右侧: 找到 %d 个分析结果文件', length(filePaths)));
end

%% ========== 加载到系统回调 ==========
function loadToSystemCallback(dlg)
% 从左侧选择的文件加载到主系统进行分析
leftListBox = getappdata(dlg, 'leftListBox');
leftFilePaths = getappdata(dlg, 'leftFilePaths');

idx = get(leftListBox, 'Value');
if isempty(idx) || idx > length(leftFilePaths) || isempty(leftFilePaths{idx})
    updateStatus(dlg, '请先选择要加载的DICOM文件');
    msgbox('请先在左侧列表中选择要加载的DICOM文件', '提示', 'warn');
    return;
end

filePath = leftFilePaths{idx};
[~, name, ext] = fileparts(filePath);

% 检查文件是否存在
if ~exist(filePath, 'file') && ~exist(filePath, 'dir')
    updateStatus(dlg, '错误: 文件不存在');
    msgbox('选中的文件不存在或已被删除', '错误', 'error');
    return;
end

% 查找主窗口
mainFig = findobj('Type', 'figure', 'Name', 'DSA脑血流灌注分析系统 v3.0 (重构版)');
if isempty(mainFig)
    updateStatus(dlg, '错误: 找不到主窗口');
    msgbox('找不到主窗口，请先打开主界面', '错误', 'error');
    return;
end

% 确保 mainFig 是单个句柄
if length(mainFig) > 1
    mainFig = mainFig(1);
end

% 确定加载路径（如果是文件夹则加载文件夹，如果是文件则加载该文件）
if isfolder(filePath)
    loadFolder = filePath;
    loadType = 'folder';
else
    loadFolder = filePath;  % 直接使用文件路径
    loadType = 'file';
end

updateStatus(dlg, sprintf('正在加载: %s%s ...', name, ext));

% 关闭文件管理器对话框，切换到主窗口
close(dlg);
figure(mainFig);

try
    % 根据类型处理
    if strcmp(loadType, 'file')
        % 单个文件：直接传递文件路径
        setappdata(mainFig, 'autoLoadFile', loadFolder);
        setappdata(mainFig, 'autoLoadType', 'file');
    else
        % 文件夹：递归获取所有DICOM文件（包括子文件夹）
        dicomFiles = findDicomFilesRecursive(loadFolder);
        
        if isempty(dicomFiles)
            msgbox('该文件夹中未找到DICOM文件', '错误', 'error');
            return;
        end
        
        setappdata(mainFig, 'autoLoadFolder', loadFolder);
        setappdata(mainFig, 'autoLoadFiles', dicomFiles);  % 传递找到的所有文件路径
        setappdata(mainFig, 'autoLoadType', 'folder');
    end
    
    % 调用io_importDSA进行导入
    io_importDSA();
    
    % 清除临时数据
    if isappdata(mainFig, 'autoLoadFile')
        rmappdata(mainFig, 'autoLoadFile');
    end
    if isappdata(mainFig, 'autoLoadFolder')
        rmappdata(mainFig, 'autoLoadFolder');
    end
    if isappdata(mainFig, 'autoLoadType')
        rmappdata(mainFig, 'autoLoadType');
    end
    
catch ME
    msgbox(sprintf('加载失败: %s', ME.message), '错误', 'error');
    fprintf('加载错误详情:\n%s\n', ME.getReport());
end
end

%% ========== 导入DICOM回调 ==========
function importDICOMCallback(dlg)
rawDataDir = getappdata(dlg, 'rawDataDir');

% 选择DICOM文件或文件夹
choice = questdlg('请选择导入方式', 'DICOM导入', ...
    '单个文件', '整个文件夹', '取消', '整个文件夹');

if strcmp(choice, '取消') || isempty(choice)
    return;
end

if strcmp(choice, '单个文件')
    [file, path] = uigetfile({'*.dcm;*.dicom', 'DICOM文件 (*.dcm, *.dicom)'; ...
        '*.*', '所有文件 (*.*)'}, ...
        '选择DICOM文件', 'MultiSelect', 'on');
    if isequal(file, 0)
        return;
    end
    
    if ischar(file)
        file = {file};
    end
    
    for i = 1:length(file)
        srcFile = fullfile(path, file{i});
        dstFile = fullfile(rawDataDir, file{i});
        if exist(dstFile, 'file')
            % 如果文件已存在，询问是否覆盖
            choice = questdlg(sprintf('文件 %s 已存在，是否覆盖？', file{i}), ...
                '文件冲突', '覆盖', '跳过', '覆盖');
            if strcmp(choice, '覆盖')
                copyfile(srcFile, dstFile, 'f');
            end
        else
            copyfile(srcFile, dstFile);
        end
    end
    
    updateStatus(dlg, sprintf('已导入 %d 个DICOM文件', length(file)));
else
    srcFolder = uigetdir('', '选择DICOM文件夹');
    if isequal(srcFolder, 0)
        return;
    end
    
    % 获取源文件夹名称，在目标位置创建同名文件夹
    [~, folderName] = fileparts(srcFolder);
    dstFolder = fullfile(rawDataDir, folderName);
    
    % 递归复制整个文件夹（包括子文件夹和所有文件）
    try
        if exist(dstFolder, 'dir')
            % 如果目标文件夹已存在，询问是否覆盖
            overwriteChoice = questdlg(sprintf('文件夹 "%s" 已存在，是否覆盖？', folderName), ...
                '文件夹冲突', '覆盖', '取消', '取消');
            if strcmp(overwriteChoice, '取消')
                return;
            end
            % 删除旧文件夹后复制
            rmdir(dstFolder, 's');
        end
        
        % 使用 copyfile 递归复制整个文件夹
        copyfile(srcFolder, dstFolder);
        
        % 统计复制的文件数量
        count = countFilesRecursive(dstFolder);
        updateStatus(dlg, sprintf('已导入文件夹 "%s"，包含 %d 个文件', folderName, count));
    catch ME
        updateStatus(dlg, sprintf('导入失败: %s', ME.message));
        msgbox(sprintf('导入文件夹失败:\n%s', ME.message), '错误', 'error');
        return;
    end
end

refreshLeftPanel(dlg);

% 显示导入成功提示
msgbox('导入成功！', '提示', 'help');
end

%% ========== 导出结果回调 ==========
function exportResultCallback(dlg)
resultsDir = getappdata(dlg, 'resultsDir');

% 从主窗口获取分析结果
mainFig = findobj('Type', 'figure', 'Name', 'DSA脑血流灌注分析系统 v3.0 (重构版)');
if isempty(mainFig)
    updateStatus(dlg, '错误: 找不到主窗口');
    msgbox('请先打开主界面并完成数据分析', '提示', 'warn');
    return;
end

% 检查是否有分析数据
data = guidata(mainFig);
if isempty(data) || isempty(data.timeSeriesData)
    updateStatus(dlg, '错误: 暂无数据可导出');
    msgbox('请先完成ROI放置和数据分析', '提示', 'warn');
    return;
end

try
    % 生成时间戳和文件名
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    patientName = getappdata(dlg, 'patientName');
    
    % 导出MAT文件
    matFile = fullfile(resultsDir, sprintf('Analysis_%s_%s.mat', patientName, timestamp));
    save(matFile, 'data');
    
    % 导出Excel文件（如果有参数）
    if ~isempty(data.perfusionParams)
        xlsFile = fullfile(resultsDir, sprintf('Parameters_%s_%s.xlsx', patientName, timestamp));
        exportParamsToExcel(data, xlsFile);
    end
    
    updateStatus(dlg, sprintf('✓ 结果已导出: %s', timestamp));
    msgbox(sprintf('分析结果已保存:\n\nMAT文件: %s\nExcel文件: %s', ...
        matFile, xlsFile), '导出成功', 'help');
    
    % 刷新右侧列表显示新文件
    refreshRightPanel(dlg);
    
catch ME
    updateStatus(dlg, sprintf('导出失败: %s', ME.message));
    msgbox(sprintf('导出失败:\n%s', ME.message), '错误', 'error');
end
end

%% ========== 打开左侧文件夹 ==========
function openLeftFolder(dlg)
rawDataDir = getappdata(dlg, 'rawDataDir');
if exist(rawDataDir, 'dir')
    winopen(rawDataDir);
end
end

%% ========== 打开右侧文件 ==========
function openRightFile(dlg)
rightListBox = getappdata(dlg, 'rightListBox');
rightFilePaths = getappdata(dlg, 'rightFilePaths');

idx = get(rightListBox, 'Value');
if isempty(idx) || idx > length(rightFilePaths)
    updateStatus(dlg, '请先选择一个文件');
    return;
end

filePath = rightFilePaths{idx};
if exist(filePath, 'file')
    winopen(filePath);
    updateStatus(dlg, sprintf('已打开: %s', filePath));
else
    updateStatus(dlg, '文件不存在');
end
end

%% ========== 删除左侧文件 ==========
function clearLeftFolder(dlg)
    % 清空左侧（原始数据）文件夹
    rawDataDir = getappdata(dlg, 'rawDataDir');
    
    if ~exist(rawDataDir, 'dir')
        updateStatus(dlg, '原始数据目录不存在');
        return;
    end
    
    files = dir(rawDataDir);
    % 排除 . 和 ..
    files = files(~ismember({files.name}, {'.', '..'}));
    
    if isempty(files)
        updateStatus(dlg, '原始数据目录已经是空的');
        return;
    end
    
    % 确认删除
    choice = questdlg('确定要清空所有原始病人数据吗？此操作不可恢复。', ...
        '清空确认', '清空', '取消', '取消');
        
    if strcmp(choice, '清空')
        try
            % 遍历删除
            for i = 1:length(files)
                fullPath = fullfile(rawDataDir, files(i).name);
                if files(i).isdir
                    rmdir(fullPath, 's');
                else
                    delete(fullPath);
                end
            end
            updateStatus(dlg, '原始数据已清空');
            refreshLeftPanel(dlg);
        catch ME
            updateStatus(dlg, sprintf('清空失败: %s', ME.message));
        end
    end
end

%% ========== 删除右侧文件 ==========
function deleteRightFile(dlg)
rightListBox = getappdata(dlg, 'rightListBox');
rightFilePaths = getappdata(dlg, 'rightFilePaths');

idx = get(rightListBox, 'Value');
if isempty(idx) || (length(idx) == 1 && (idx > length(rightFilePaths) || isempty(rightFilePaths{idx})))
    updateStatus(dlg, '请先选择要删除的文件');
    return;
end

% 过滤有效的索引
validIdx = idx(idx <= length(rightFilePaths));
validIdx = validIdx(~cellfun(@isempty, rightFilePaths(validIdx)));

if isempty(validIdx)
    updateStatus(dlg, '请先选择要删除的文件');
    return;
end

% 构建删除确认消息
numItems = length(validIdx);
if numItems == 1
    filePath = rightFilePaths{validIdx(1)};
    [~, name, ext] = fileparts(filePath);
    confirmMsg = sprintf('确定要删除吗？\n\n%s%s', name, ext);
else
    confirmMsg = sprintf('确定要删除选中的 %d 个文件吗？', numItems);
end

choice = questdlg(confirmMsg, '确认删除', '删除', '取消', '取消');

if strcmp(choice, '删除')
    deletedCount = 0;
    for i = 1:length(validIdx)
        filePath = rightFilePaths{validIdx(i)};
        try
            delete(filePath);
            deletedCount = deletedCount + 1;
        catch
            % 忽略删除失败的文件
        end
    end
    updateStatus(dlg, sprintf('已删除 %d 个文件', deletedCount));
    refreshRightPanel(dlg);
end
end

%% ========== 对比分析回调 ==========
function compareAnalysisCallback(dlg)
    rightListBox = getappdata(dlg, 'rightListBox');
    rightFilePaths = getappdata(dlg, 'rightFilePaths');
    
    idx = get(rightListBox, 'Value');
    if length(idx) ~= 2
        updateStatus(dlg, '请精确选择 2 个结果文件进行对比');
        msgbox({'请在右侧列表中选择两个 MAT 文件进行对比分析：', '', ...
                '操作方法：按住 Ctrl 键依次点击两个文件', ...
                '  • 第一个选中的文件 = 术前数据', ...
                '  • 第二个选中的文件 = 术后数据'}, '术前术后对比', 'help');
        return;
    end
    
    file1 = rightFilePaths{idx(1)};
    file2 = rightFilePaths{idx(2)};
    
    [~, name1, ext1] = fileparts(file1);
    [~, name2, ext2] = fileparts(file2);
    
    if ~strcmpi(ext1, '.mat') || ~strcmpi(ext2, '.mat')
        msgbox('只能对比 MAT 格式的分析结果文件', '格式错误', 'error');
        return;
    end
    
    % 验证文件是否包含有效分析数据
    try
        d1 = load(file1);
        d2 = load(file2);
        if ~isfield(d1, 'data') || ~isfield(d2, 'data')
            msgbox('选中的文件不包含有效的分析数据 (缺少 data 字段)', '数据无效', 'error');
            return;
        end
    catch
        msgbox('无法读取选中的文件，请确认文件未损坏', '读取失败', 'error');
        return;
    end
    
    % 确认顺序
    choice = questdlg({sprintf('即将进行术前术后对比分析：'), '', ...
                       sprintf('  术前数据: %s', name1), ...
                       sprintf('  术后数据: %s', name2), '', ...
                       '顺序是否正确？'}, ...
                      '确认对比顺序', '确认', '交换顺序', '取消', '确认');
    
    if strcmp(choice, '取消') || isempty(choice)
        return;
    elseif strcmp(choice, '交换顺序')
        tmp = file1; file1 = file2; file2 = tmp;
    end
    
    % 调用对比分析模块
    try
        updateStatus(dlg, '正在启动对比分析...');
        analysis_comparePrePost(file1, file2);
    catch ME
        msgbox(['启动对比分析失败: ' ME.message], '错误', 'error');
        updateStatus(dlg, '对比分析启动失败');
    end
end

%% ========== 文件信息更新 ==========
function updateLeftFileInfo(dlg)
% 检查是否双击
if strcmp(get(dlg, 'SelectionType'), 'open')
    leftListBox = getappdata(dlg, 'leftListBox');
    leftFilePaths = getappdata(dlg, 'leftFilePaths');
    idx = get(leftListBox, 'Value');
    
    if ~isempty(idx) && idx <= length(leftFilePaths)
        selectedPath = leftFilePaths{idx};
        
        % 检查是否是返回上级目录
        if strcmp(selectedPath, '..')
            currentDir = getappdata(dlg, 'currentBrowseDir');
            parentDir = fileparts(currentDir);
            rawDataDir = getappdata(dlg, 'rawDataDir');
            
            % 确保不会超出根目录
            if contains(parentDir, rawDataDir) || strcmp(parentDir, rawDataDir)
                setappdata(dlg, 'currentBrowseDir', parentDir);
            else
                setappdata(dlg, 'currentBrowseDir', rawDataDir);
            end
            refreshLeftPanel(dlg);
            return;
        end
        
        % 检查是否是文件夹
        if isfolder(selectedPath)
            % 进入文件夹
            setappdata(dlg, 'currentBrowseDir', selectedPath);
            refreshLeftPanel(dlg);
            return;
        else
            % 文件：加载到系统
            loadToSystemCallback(dlg);
            return;
        end
    end
    return;
end

leftListBox = getappdata(dlg, 'leftListBox');
leftInfoText = getappdata(dlg, 'leftInfoText');
leftFilePaths = getappdata(dlg, 'leftFilePaths');

if isempty(leftFilePaths) || (length(leftFilePaths) == 1 && isempty(leftFilePaths{1}))
    return;
end

idx = get(leftListBox, 'Value');
numFiles = length(leftFilePaths);
numSelected = length(idx);

if numSelected == 0
    set(leftInfoText, 'String', sprintf('共 %d 个文件', numFiles));
elseif numSelected == 1
    % 显示单个文件详细信息
    filePath = leftFilePaths{idx};
    if exist(filePath, 'file')
        fileInfo = dir(filePath);
        [~, name, ext] = fileparts(filePath);
        sizeStr = formatFileSize(fileInfo.bytes);
        set(leftInfoText, 'String', sprintf('%s%s | %s', name, ext, sizeStr));
    end
else
    % 多选显示
    totalSize = 0;
    for i = 1:numSelected
        if exist(leftFilePaths{idx(i)}, 'file')
            fileInfo = dir(leftFilePaths{idx(i)});
            totalSize = totalSize + fileInfo.bytes;
        end
    end
    totalSizeStr = formatFileSize(totalSize);
    set(leftInfoText, 'String', sprintf('已选 %d 个 | 总计 %s', numSelected, totalSizeStr));
end
end

function updateRightFileInfo(dlg)
rightListBox = getappdata(dlg, 'rightListBox');
rightInfoText = getappdata(dlg, 'rightInfoText');
rightFilePaths = getappdata(dlg, 'rightFilePaths');

if isempty(rightFilePaths) || (length(rightFilePaths) == 1 && isempty(rightFilePaths{1}))
    return;
end

idx = get(rightListBox, 'Value');
numFiles = length(rightFilePaths);
numSelected = length(idx);

if numSelected == 0
    set(rightInfoText, 'String', sprintf('共 %d 个文件', numFiles));
elseif numSelected == 1
    % 显示单个文件详细信息
    filePath = rightFilePaths{idx};
    if exist(filePath, 'file')
        fileInfo = dir(filePath);
        [~, name, ext] = fileparts(filePath);
        sizeStr = formatFileSize(fileInfo.bytes);
        set(rightInfoText, 'String', sprintf('%s%s | %s', name, ext, sizeStr));
    end
else
    % 多选显示
    totalSize = 0;
    for i = 1:numSelected
        if exist(rightFilePaths{idx(i)}, 'file')
            fileInfo = dir(rightFilePaths{idx(i)});
            totalSize = totalSize + fileInfo.bytes;
        end
    end
    totalSizeStr = formatFileSize(totalSize);
    set(rightInfoText, 'String', sprintf('已选 %d 个 | 总计 %s', numSelected, totalSizeStr));
end
end

%% ========== 辅助函数 ==========
function updateStatus(dlg, message)
statusText = getappdata(dlg, 'statusText');
if ~isempty(statusText) && ishandle(statusText)
    set(statusText, 'String', sprintf('[%s] %s', datestr(now, 'HH:MM:SS'), message));
end
end

function sizeStr = formatFileSize(bytes)
if bytes < 1024
    sizeStr = sprintf('%d B', bytes);
elseif bytes < 1024^2
    sizeStr = sprintf('%.1f KB', bytes/1024);
elseif bytes < 1024^3
    sizeStr = sprintf('%.1f MB', bytes/1024^2);
else
    sizeStr = sprintf('%.1f GB', bytes/1024^3);
end
end

function value = getFieldOrDefault(struct, fieldName, defaultValue)
if isfield(struct, fieldName) && ~isempty(struct.(fieldName))
    value = struct.(fieldName);
else
    value = defaultValue;
end
end

function exportParamsToExcel(data, filename)
% 导出完整分析数据到Excel
try
    % Sheet 1: 灌注参数
    if ~isempty(data.perfusionParams)
        params = data.perfusionParams;
        if isstruct(params) && ~isempty(fieldnames(params))
            lobes = fieldnames(params);
            excelData = {};
            excelData{1,1} = '参数';
            for i = 1:length(lobes)
                excelData{1, i+1} = lobes{i};
            end
            
            paramNames = fieldnames(params.(lobes{1}));
            for i = 1:length(paramNames)
                excelData{i+1, 1} = paramNames{i};
                for j = 1:length(lobes)
                    value = params.(lobes{j}).(paramNames{i});
                    if isnumeric(value)
                        excelData{i+1, j+1} = value;
                    else
                        excelData{i+1, j+1} = '';
                    end
                end
            end
            
            xlswrite(filename, excelData, '灌注参数');
        end
    end
    
    % Sheet 2: 时间密度曲线
    if ~isempty(data.timeSeriesData)
        frames = (1:length(data.timeSeriesData))';
        intensity = data.timeSeriesData(:);
        curveData = [frames, intensity];
        xlswrite(filename, {'帧号', '强度值'}, '时间密度曲线', 'A1');
        xlswrite(filename, curveData, '时间密度曲线', 'A2');
    end
    
catch ME
    warning('DSA:ExcelExport', '导出Excel失败: %s', ME.message);
end
end

%% ========== 切换病人回调 ==========
function switchPatientCallback(dlg)
% 询问确认
choice = questdlg('确定要切换病人吗？当前未保存的工作可能会丢失。', ...
    '切换病人', '确定', '取消', '取消');
if strcmp(choice, '取消') || isempty(choice)
    return;
end

% 关闭当前对话框
delete(dlg);

% 关闭所有图形窗口
close all;

% 重新启动主程序
% 优先尝试重构版
if exist('DSA_Analysis_GUI_Refactored', 'file')
    DSA_Analysis_GUI_Refactored();
elseif exist('DSA_Analysis_GUI_v5', 'file')
    DSA_Analysis_GUI_v5();
else
    msgbox('无法找到主程序入口，请手动重启。', '错误', 'error');
end
end

%% ========== 递归统计文件数量 ==========
function count = countFilesRecursive(folderPath)
% 递归统计文件夹中的所有文件数量（包括子文件夹中的文件）
count = 0;

if ~exist(folderPath, 'dir')
    return;
end

items = dir(folderPath);
for i = 1:length(items)
    if strcmp(items(i).name, '.') || strcmp(items(i).name, '..')
        continue;
    end
    
    fullPath = fullfile(folderPath, items(i).name);
    if items(i).isdir
        % 递归统计子文件夹
        count = count + countFilesRecursive(fullPath);
    else
        % 计数文件
        count = count + 1;
    end
end
end

%% ========== 递归查找DICOM文件 ==========
function dicomFiles = findDicomFilesRecursive(folderPath)
% 递归查找文件夹中的所有DICOM文件（包括子文件夹）
dicomFiles = {};

if ~exist(folderPath, 'dir')
    return;
end

items = dir(folderPath);
for i = 1:length(items)
    if strcmp(items(i).name, '.') || strcmp(items(i).name, '..')
        continue;
    end
    
    fullPath = fullfile(folderPath, items(i).name);
    if items(i).isdir
        % 递归搜索子文件夹
        subFiles = findDicomFilesRecursive(fullPath);
        dicomFiles = [dicomFiles, subFiles];
    else
        % 检查是否是DICOM文件
        [~, ~, ext] = fileparts(items(i).name);
        if any(strcmpi(ext, {'.dcm', '.dicom', ''}))
            % 没有扩展名的文件也可能是DICOM
            if isempty(ext)
                % 尝试读取DICOM信息来验证
                try
                    info = dicominfo(fullPath);
                    if ~isempty(info)
                        dicomFiles{end+1} = fullPath;
                    end
                catch
                    % 不是有效的DICOM文件，跳过
                end
            else
                dicomFiles{end+1} = fullPath;
            end
        end
    end
end
end
