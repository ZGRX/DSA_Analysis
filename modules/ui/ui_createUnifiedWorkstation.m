function ui_createUnifiedWorkstation(hObject, ~, varargin)
% UI_CREATEUNIFIEDWORKSTATION 一站式术前术后对比分析报告
% 融合文件管理、多参数对比、TDC 曲线拆分视图、临床指导建议
% 输入: (hObject, ~, preData, postData) 可选

%% 1. 环境准备
mainFig = ancestor(hObject, 'figure');
if isempty(mainFig), mainFig = gcf; end
mainData = guidata(mainFig);

% 检查是否有传入数据
inputPre = [];
inputPost = [];
if nargin > 2, inputPre = varargin{1}; end
if nargin > 3, inputPost = varargin{2}; end

% 窗口尺寸 (全屏专业感)
screenSize = get(0, 'ScreenSize');
wsFig = figure('Name', '术前术后对比分析报告', ...
    'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
    'Position', [50, 50, screenSize(3)-100, screenSize(4)-150], ...
    'Color', [0.98, 0.98, 0.99]);

%% 2. 核心布局 (20% 病例库边栏 + 80% 核心报告区)
sidebar = uipanel('Parent', wsFig, 'Units', 'normalized', 'Position', [0, 0, 0.2, 1], ...
    'BackgroundColor', [0.15, 0.18, 0.25], 'BorderType', 'none');

reportArea = uipanel('Parent', wsFig, 'Units', 'normalized', 'Position', [0.2, 0, 0.8, 1], ...
    'BackgroundColor', 'w', 'BorderType', 'none');

%% 3. 左侧边栏：病例与操作
uicontrol('Parent', sidebar, 'Style', 'text', 'String', '📂 历史病例库', ...
    'Units', 'normalized', 'Position', [0.1, 0.93, 0.8, 0.04], ...
    'FontSize', 12, 'FontWeight', 'bold', 'ForegroundColor', 'w', 'BackgroundColor', [0.15, 0.18, 0.25]);

fileListBox = uicontrol('Parent', sidebar, 'Style', 'listbox', ...
    'Units', 'normalized', 'Position', [0.05, 0.45, 0.9, 0.45], ...
    'BackgroundColor', [0.22, 0.25, 0.32], 'ForegroundColor', 'w', 'FontSize', 10);

% 对比配置按钮
uicontrol('Parent', sidebar, 'Style', 'pushbutton', 'String', '📘 设为术前 (Baseline)', ...
    'Units', 'normalized', 'Position', [0.1, 0.34, 0.8, 0.06], ...
    'BackgroundColor', [0.2, 0.5, 0.8], 'ForegroundColor', 'w', ...
    'Callback', @(s,e) setFile(wsFig, 'pre'));

uicontrol('Parent', sidebar, 'Style', 'pushbutton', 'String', '📕 设为术后 (Follow-up)', ...
    'Units', 'normalized', 'Position', [0.1, 0.26, 0.8, 0.06], ...
    'BackgroundColor', [0.8, 0.4, 0.3], 'ForegroundColor', 'w', ...
    'Callback', @(s,e) setFile(wsFig, 'post'));

uicontrol('Parent', sidebar, 'Style', 'pushbutton', 'String', '🚀 重新生成报告', ...
    'Units', 'normalized', 'Position', [0.1, 0.08, 0.8, 0.1], ...
    'BackgroundColor', [0.3, 0.7, 0.5], 'ForegroundColor', 'w', 'FontWeight', 'bold', 'FontSize', 11, ...
    'Callback', @(s,e) updateReport(wsFig));

%% 4. 右侧报告区：基于截图美学设计

% (A) 顶部：标题与警示横幅
headerPanel = uipanel('Parent', reportArea, 'Units', 'normalized', 'Position', [0, 0.88, 1, 0.12], ...
    'BackgroundColor', 'w', 'BorderType', 'none');

uicontrol('Parent', headerPanel, 'Style', 'text', 'String', '术前术后对比分析报告', ...
    'Units', 'normalized', 'Position', [0.05, 0.7, 0.4, 0.25], ...
    'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'BackgroundColor', 'w');

% 自动生成的风险横幅 [Warning Banner]
banner = uipanel('Parent', headerPanel, 'Units', 'normalized', 'Position', [0.03, 0.15, 0.7, 0.45], ...
    'BackgroundColor', [1, 0.92, 0.92], 'BorderType', 'none', 'Visible', 'off');
bannerText = uicontrol('Parent', banner, 'Style', 'text', 'String', '', ...
    'Units', 'normalized', 'Position', [0.05, 0.1, 0.9, 0.8], ...
    'FontSize', 15, 'FontWeight', 'bold', 'ForegroundColor', [0.7, 0.1, 0.1], 'BackgroundColor', [1, 0.92, 0.92]);

% 导出按钮 (Top Right)
uicontrol('Parent', headerPanel, 'Style', 'pushbutton', 'String', '📥 导出对比报告', ...
    'Units', 'normalized', 'Position', [0.78, 0.2, 0.18, 0.6], ...
    'BackgroundColor', [0.35, 0.75, 0.45], 'ForegroundColor', 'w', 'FontSize', 12, 'FontWeight', 'bold');

% (B) 中部核心区：MS对比表与柱状图
mainContentPanel = uipanel('Parent', reportArea, 'Units', 'normalized', 'Position', [0, 0.45, 1, 0.43], ...
    'BackgroundColor', 'w', 'BorderType', 'none');

% 样式表格
table = uitable('Parent', mainContentPanel, 'Units', 'normalized', 'Position', [0.05, 0.1, 0.45, 0.85], ...
    'BackgroundColor', [1, 1, 1; 0.98, 0.98, 1], 'FontSize', 10, ...
    'ColumnName', {'脑叶', '术前 MS', '术后 MS', '增加比', '风险评价'}, ...
    'ColumnWidth', {60, 80, 80, 80, 100}, 'RowName', []);

% 对比柱状图
axMS = axes('Parent', mainContentPanel, 'Position', [0.58, 0.2, 0.35, 0.65], 'Color', 'w');

% (C) TDC 深度互信区 (Suggestion 2 from suggestion box)
curveArea = uipanel('Parent', reportArea, 'Units', 'normalized', 'Position', [0, 0.22, 1, 0.23], ...
    'BackgroundColor', [0.98, 0.98, 1], 'BorderType', 'none');

axCurvePre = axes('Parent', curveArea, 'Position', [0.05, 0.15, 0.42, 0.7], 'Color', [0.97, 0.97, 0.99]);
axCurvePost = axes('Parent', curveArea, 'Position', [0.53, 0.15, 0.42, 0.7], 'Color', [0.99, 0.97, 0.97]);
title(axCurvePre, '术前原始 TDC 曲线 (Baseline Data)', 'FontSize', 9, 'Color', [0.3, 0.5, 0.7]);
title(axCurvePost, '术后复查 TDC 曲线 (Patient Evidence)', 'FontSize', 9, 'Color', [0.7, 0.3, 0.3]);

% (D) 底部：临床指导建议
guidanceArea = uipanel('Parent', reportArea, 'Units', 'normalized', 'Position', [0.02, 0.02, 0.96, 0.18], ...
    'BackgroundColor', [0.96, 0.97, 1], 'BorderType', 'line', 'HighlightColor', [0.8, 0.8, 1]);

uicontrol('Parent', guidanceArea, 'Style', 'text', 'String', '🧠 临床指导建议', ...
    'Units', 'normalized', 'Position', [0.02, 0.78, 0.2, 0.15], ...
    'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.96, 0.97, 1], 'HorizontalAlignment', 'left');

guidanceText = uicontrol('Parent', guidanceArea, 'Style', 'text', 'String', '等待数据加载与比对分析...', ...
    'Units', 'normalized', 'Position', [0.05, 0.05, 0.9, 0.7], ...
    'FontSize', 11, 'BackgroundColor', [0.96, 0.97, 1], 'HorizontalAlignment', 'left');

%% 5. 数据联动初始化
wsData = struct();
wsData.fileListBox = fileListBox;
wsData.banner = banner;
wsData.bannerText = bannerText;
wsData.table = table;
wsData.axMS = axMS;
wsData.axCurvePre = axCurvePre;
wsData.axCurvePost = axCurvePost;
wsData.guidanceText = guidanceText;
wsData.preData = inputPre;   % 使用传入数据
wsData.postData = inputPost; % 使用传入数据
wsData.patientID = 'P001';

% 加载当前病人文件列表 (边栏保留作为备选)
try
    if isfield(mainData, 'dataContainer') && isfield(mainData.dataContainer, 'patientInfo')
        wsData.patientID = mainData.dataContainer.patientInfo.id;
    end
    dataDir = fullfile(pwd, 'PatientData', wsData.patientID, 'Results', 'Data');
    if exist(dataDir, 'dir')
        mats = dir(fullfile(dataDir, '*.mat'));
        if ~isempty(mats)
            set(fileListBox, 'String', {mats.name});
        end
    end
catch
    set(fileListBox, 'String', {'(无可用分析数据)'});
end

guidata(wsFig, wsData);

% 如果传入了数据，立即运行分析
if ~isempty(wsData.preData) && ~isempty(wsData.postData)
    updateReport(wsFig);
end

%% ========== 内部功能回调 ==========

function setFile(hFig, type)
    wsData = guidata(hFig);
    idx = get(wsData.fileListBox, 'Value');
    list = get(wsData.fileListBox, 'String');
    if isempty(idx) || isempty(list) || strcmp(list{1}, '(无可用分析数据)'), return; end
    
    filename = list{idx};
    dataDir = fullfile(pwd, 'PatientData', wsData.patientID, 'Results', 'Data');
    try
        loaded = load(fullfile(dataDir, filename));
        if isfield(loaded, 'data')
            if strcmp(type, 'pre')
                wsData.preData = loaded.data;
            else
                wsData.postData = loaded.data;
            end
            guidata(hFig, wsData);
            % 自动提示状态
            fprintf('已同步【%s】: %s\n', type, filename);
        end
    catch ME
        errordlg(['加载失败: ' ME.message]);
    end
end

function updateReport(hFig)
    wsData = guidata(hFig);
    if isempty(wsData.preData) || isempty(wsData.postData)
        msgbox('请先在左侧选择术前与术后病例文件。', '提示');
        return;
    end
    
    pre = wsData.preData.perfusionParams;
    post = wsData.postData.perfusionParams;
    lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    
    % 1. 核心计算 (MS 密度增长率)
    tData = cell(4, 5);
    preMS = zeros(4, 1);
    postMS = zeros(4, 1);
    riskCount = 0;
    
    for i = 1:4
        preMS(i) = pre(i).MS;
        postMS(i) = post(i).MS;
        ratio = (postMS(i) - preMS(i)) / max(0.1, preMS(i)) * 100;
        
        tData{i,1} = lobeNames{i};
        tData{i,2} = sprintf('%.3f', preMS(i));
        tData{i,3} = sprintf('%.3f', postMS(i));
        tData{i,4} = sprintf('%+.1f%%', ratio);
        
        if ratio > 150
            tData{i,5} = '高风险 🔥';
            riskCount = riskCount + 1;
        elseif ratio > 30
            tData{i,5} = '中风险 ⚠️';
        else
            tData{i,5} = '低风险 ✅';
        end
    end
    set(wsData.table, 'Data', tData);
    
    % 2. 应用截图中的风险横幅风格
    if riskCount > 0
        set(wsData.banner, 'Visible', 'on');
        set(wsData.bannerText, 'String', sprintf('高灌注风险: %d 个脑叶血流速度(MS)增加超过 150%%', riskCount));
    else
        set(wsData.banner, 'Visible', 'off');
    end
    
    % 3. 绘制对比图 (MS)
    cla(wsData.axMS);
    bh = bar(wsData.axMS, [preMS, postMS], 'grouped');
    set(bh(1), 'FaceColor', [0.35, 0.65, 0.85], 'DisplayName', '术前');
    set(bh(2), 'FaceColor', [0.85, 0.35, 0.35], 'DisplayName', '术后');
    set(wsData.axMS, 'XTickLabel', lobeNames, 'FontSize', 9);
    legend(wsData.axMS, 'Location', 'northeast');
    ylabel(wsData.axMS, 'MS (密度/s)');
    title(wsData.axMS, '术前 vs 术后 MS 对比分析', 'FontSize', 11);
    grid(wsData.axMS, 'on');
    
    % 4. 绘制原曲线 (Evidence)
    drawEvidence(wsData.axCurvePre, wsData.preData);
    drawEvidence(wsData.axCurvePost, wsData.postData);
    
    % 5. 临床指导建议 (匹配截图内容)
    if riskCount > 0
        advice = {
            '高风险灌注建议:';
            '● 密切监测神经功能状态，预防高灌注综合征';
            '● 控制收缩压在较低水平，防止脑血流激增';
            '● 考虑预防性抗水肿药物治疗（如甘露醇、激素等）';
            '● 术后24-48小时内复查影像学状态'
        };
    else
        advice = {
            '基准期灌注建议:';
            '● 术后整体灌注趋于稳定，临床表现良好';
            '● 继续常规抗血小板或改善微循环治疗';
            '● 定期复诊监控 TDC 曲线峰值变化'
        };
    end
    set(wsData.guidanceText, 'String', strjoin(advice, '\n'));
end

function drawEvidence(ax, data)
    cla(ax);
    if isfield(data, 'smoothedLobeData') && isfield(data, 't_highres')
        plot(ax, data.t_highres, data.smoothedLobeData', 'LineWidth', 2);
        grid(ax, 'on');
        set(ax, 'FontSize', 8);
    end
end

end
