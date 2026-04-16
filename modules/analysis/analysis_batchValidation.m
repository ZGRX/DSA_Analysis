function analysis_batchValidation(varargin)
% CHS AI 系统 — 10例临床验证汇总工具 (Competition Edition)
% ═══════════════════════════════════════════════════════════════════════
% 使用流程：
%   1. 对10例DICOM逐个完成：加载→放ROI→提取TDC→分析曲线
%   2. 每例分析完毕后，点击【记录本例结果】保存到验证表
%   3. 10例全部完成后，点击【生成验证报告】输出可视化
% ═══════════════════════════════════════════════════════════════════════

fig = findobj('Type', 'figure', 'Tag', 'DSA_Main_Window');
if isempty(fig), fig = gcf; else, fig = fig(1); end
data = guidata(fig);

% ── 初始化验证数据库（存在则继续追加）────────────────────────────────
if ~isappdata(fig, 'validationDB')
    db.cases     = {};    % 患者ID或病案编号
    db.TTS       = [];    % 跨狭窄时移 (s)
    db.peakRatio = [];    % 峰值衰减比
    db.chsScore  = [];    % AI评分 (0~1)
    db.riskTier  = {};    % 'HIGH' / 'MODERATE' / 'LOW'
    db.outcome   = {};    % 临床结局: 'CHS' / 'Normal' (后续手动填)
    db.tdcData   = {};    % 双端 TDC 曲线 [2 x nPoints] (用于BiLSTM训练)
    setappdata(fig, 'validationDB', db);
end
db = getappdata(fig, 'validationDB');
nDone = length(db.TTS);

% ── 显示验证管理窗口 ─────────────────────────────────────────────────
screenSz = get(0, 'ScreenSize');
figW = min(900, round(screenSz(3) * 0.62));
figH = min(580, round(screenSz(4) * 0.68));
figL = round((screenSz(3) - figW) / 2);
figT = round((screenSz(4) - figH) / 2);

vFig = figure('Name', sprintf('CHS AI 临床验证管理工具  [已记录 %d/10 例]', nDone), ...
    'NumberTitle', 'off', 'Position', [figL, figT, figW, figH], ...
    'Color', [0.10, 0.10, 0.15], 'Tag', 'ValidationManager', ...
    'MenuBar', 'none', 'Resize', 'off');

bgC = [0.13, 0.13, 0.20];
margin = 12;

% ── 顶部：当前病例数据读取区 ──────────────────────────────────────────
topPanel = uipanel('Parent', vFig, 'Units', 'pixels', ...
    'Position', [margin, figH-155, figW-2*margin, 140], ...
    'BackgroundColor', bgC, 'ForegroundColor', 'w', ...
    'Title', '  ① 当前病例分析结果（来自主界面）', ...
    'FontSize', 10, 'FontWeight', 'bold');

% 自动读取当前已分析的数值
hasDual = isfield(data,'perfusionParams') && length(data.perfusionParams)>=2;
if hasDual
    p1 = data.perfusionParams(1); p2 = data.perfusionParams(2);
    cur_TTS  = max(0, p2.TMAX - p1.TMAX);
    cur_PR   = p1.Peak / max(eps, p2.Peak);
    w0=-2.80; w1=1.20; w2=0.85; w3=0.10; w4=0.20;
    logit = w0 + w1*(cur_TTS/3.2) + w2*(cur_PR/2.0) + w3*0 + w4*0;
    cur_score = round(100/(1+exp(-logit)));
    if cur_TTS>=5.0, cur_tier='HIGH'; elseif cur_TTS>=3.2, cur_tier='MODERATE'; else, cur_tier='LOW'; end
    readStr = sprintf('TTS = %.3f s    |    Peak Ratio = ×%.2f    |    CHS评分 = %d%%    |    风险 = %s', ...
        cur_TTS, cur_PR, cur_score, cur_tier);
    readColor = [0.9, 0.9, 0.5];
else
    cur_TTS=NaN; cur_PR=NaN; cur_score=NaN; cur_tier='N/A';
    readStr = '⚠  尚未完成双端分析 — 请先在主界面完成【分析曲线】步骤';
    readColor = [1, 0.5, 0.5];
end

uicontrol('Parent', topPanel, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.02, 0.60, 0.96, 0.32], 'String', readStr, ...
    'ForegroundColor', readColor, 'BackgroundColor', bgC, ...
    'FontSize', 10, 'HorizontalAlignment', 'left');

% 病案编号输入框
uicontrol('Parent', topPanel, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.02, 0.30, 0.14, 0.25], 'String', '病案编号:', ...
    'ForegroundColor', 'w', 'BackgroundColor', bgC, ...
    'FontSize', 9, 'HorizontalAlignment', 'right');
caseIdEdit = uicontrol('Parent', topPanel, 'Style', 'edit', 'Units', 'normalized', ...
    'Position', [0.17, 0.30, 0.20, 0.28], ...
    'String', sprintf('CAS-%02d', nDone+1), ...
    'BackgroundColor', [0.22, 0.26, 0.35], 'ForegroundColor', 'w', ...
    'FontSize', 10, 'FontWeight', 'bold');

% 临床结局下拉
uicontrol('Parent', topPanel, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.40, 0.30, 0.14, 0.25], 'String', '临床结局:', ...
    'ForegroundColor', 'w', 'BackgroundColor', bgC, ...
    'FontSize', 9, 'HorizontalAlignment', 'right');
outcomeMenu = uicontrol('Parent', topPanel, 'Style', 'popupmenu', 'Units', 'normalized', ...
    'Position', [0.55, 0.30, 0.20, 0.28], ...
    'String', {'正常出院 (Normal)', '发生CHS (CHS)'}, ...
    'BackgroundColor', [0.22, 0.26, 0.35], 'ForegroundColor', 'w', 'FontSize', 9);

% 记录按钮
btnRecord = uicontrol('Parent', topPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.78, 0.24, 0.20, 0.38], ...
    'String', '✚  记录本例', 'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.15, 0.50, 0.28], 'ForegroundColor', 'w', ...
    'Enable', matlab.lang.OnOffSwitchState(hasDual), ...
    'Callback', @(~,~) recordCase(fig, vFig, caseIdEdit, outcomeMenu, ...
                                  cur_TTS, cur_PR, cur_score/100, cur_tier));

% ── 中部：已记录病例汇总表 ────────────────────────────────────────────
midPanel = uipanel('Parent', vFig, 'Units', 'pixels', ...
    'Position', [margin, 80, figW-2*margin, figH-155-80-2*margin], ...
    'BackgroundColor', bgC, 'ForegroundColor', 'w', ...
    'Title', '  ② 已记录病例汇总', 'FontSize', 10, 'FontWeight', 'bold');

colNames = {'病案编号','TTS(s)','Peak比','CHS得分','风险等级','临床结局'};
if nDone > 0
    tableData = buildTableData(db);
else
    tableData = repmat({'-'}, 1, 6);
end

tbl = uitable('Parent', midPanel, 'Units', 'normalized', ...
    'Position', [0.01, 0.02, 0.98, 0.95], ...
    'Data', tableData, 'ColumnName', colNames, ...
    'RowName', [], 'FontSize', 9, 'FontName', 'Microsoft YaHei', ...
    'ColumnWidth', {80, 60, 60, 70, 75, 85}, 'RowStriping', 'on');
setappdata(vFig, 'summaryTable', tbl);

% ── 底部：操作按钮 ────────────────────────────────────────────────────
btnH = 42; btnY = 18;
uicontrol('Parent', vFig, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [margin, btnY, 200, btnH], ...
    'String', '📊  生成验证报告', 'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.20, 0.45, 0.75], 'ForegroundColor', 'w', ...
    'Callback', @(~,~) generateReport(fig, vFig));

uicontrol('Parent', vFig, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [margin+210, btnY, 160, btnH], ...
    'String', '📤  导出CSV表格', 'FontSize', 10, ...
    'BackgroundColor', [0.30, 0.30, 0.42], 'ForegroundColor', 'w', ...
    'Callback', @(~,~) exportCSV(fig));

uicontrol('Parent', vFig, 'Style', 'pushbutton', ...
    'Units', 'pixels', 'Position', [margin+380, btnY, 140, btnH], ...
    'String', '🗑  清空记录', 'FontSize', 10, ...
    'BackgroundColor', [0.45, 0.15, 0.15], 'ForegroundColor', 'w', ...
    'Callback', @(~,~) clearDB(fig, vFig));

uicontrol('Parent', vFig, 'Style', 'text', 'Units', 'pixels', ...
    'Position', [margin+540, btnY, figW-margin-560, btnH], ...
    'String', sprintf('已记录 %d / 10 例   |   完成后点击【生成验证报告】', nDone), ...
    'ForegroundColor', [0.7, 0.7, 0.7], 'BackgroundColor', [0.10, 0.10, 0.15], ...
    'FontSize', 9, 'HorizontalAlignment', 'right');
end

% ════════════════════════════════════════════════════════════════
% 内部函数
% ════════════════════════════════════════════════════════════════

function recordCase(fig, vFig, caseIdEdit, outcomeMenu, TTS, PR, score, tier)
if isnan(TTS)
    utils_showMessage('当前病例尚未完成分析，无法记录', 'error'); return;
end
db = getappdata(fig, 'validationDB');
caseId  = get(caseIdEdit, 'String');
menuVal = get(outcomeMenu, 'Value');
outcome = 'Normal'; if menuVal == 2, outcome = 'CHS'; end

% 尝试去取当前TDC曲线数据（供 BiLSTM 训练用）
data = guidata(fig);
if isfield(data, 'smoothedLobeData') && ~isempty(data.smoothedLobeData) && ...
        size(data.smoothedLobeData, 1) >= 2
    tdc_raw = data.smoothedLobeData(1:2, :);
    % 归一化到 100个等间采样点（统一长度）
    tdc_norm = zeros(2, 100);
    for ch = 1:2
        v = tdc_raw(ch,:);
        v = (v - min(v)) / max(1e-6, max(v) - min(v));  % 幅度归一
        tdc_norm(ch,:) = interp1(linspace(0,1,length(v)), v, linspace(0,1,100), 'pchip');
    end
    db.tdcData{end+1} = tdc_norm;  % [2 x 100]
else
    db.tdcData{end+1} = [];  % 无TDC数据时占位
end

db.cases{end+1}     = caseId;
db.TTS(end+1)       = TTS;
db.peakRatio(end+1) = PR;
db.chsScore(end+1)  = score;
db.riskTier{end+1}  = tier;
db.outcome{end+1}   = outcome;

setappdata(fig, 'validationDB', db);
nDone = length(db.TTS);
set(vFig, 'Name', sprintf('CHS AI 临床验证管理工具  [已记录 %d/10 例]', nDone));

tbl = getappdata(vFig, 'summaryTable');
set(tbl, 'Data', buildTableData(db));

% 自动着色：CHS患者行标红（需要uistyle）
try
    for k = 1:nDone
        if strcmp(db.outcome{k}, 'CHS')
            s = uistyle('BackgroundColor',[0.5,0.1,0.1],'FontColor',[1,0.7,0.7],'FontWeight','bold');
        else
            s = uistyle('BackgroundColor',[0.08,0.35,0.12],'FontColor',[0.7,1,0.7]);
        end
        addStyle(tbl, s, 'row', k);
    end
catch, end

log_addWorkLog(sprintf('验证记录[%d]: %s | TTS=%.2fs | Score=%d%% | 结局=%s', ...
    nDone, caseId, TTS, round(score*100), outcome));
utils_showMessage(sprintf('已记录第 %d 例 (%s)', nDone, caseId), 'success');
end

function td = buildTableData(db)
n  = length(db.TTS);
td = cell(n, 6);
for i = 1:n
    td{i,1} = db.cases{i};
    td{i,2} = sprintf('%.3f', db.TTS(i));
    td{i,3} = sprintf('×%.2f', db.peakRatio(i));
    td{i,4} = sprintf('%d%%', round(db.chsScore(i)*100));
    td{i,5} = db.riskTier{i};
    td{i,6} = db.outcome{i};
end
end

function generateReport(fig, vFig)
db = getappdata(fig, 'validationDB');
n  = length(db.TTS);
if n < 1
    utils_showMessage('请先记录至少1例数据', 'error'); return;
end

% 计算临床验证指标
chsMask   = strcmp(db.outcome, 'CHS');
highMask  = strcmp(db.riskTier, 'HIGH') | strcmp(db.riskTier, 'MODERATE');

TP = sum(chsMask &  highMask);
TN = sum(~chsMask & ~highMask);
FP = sum(~chsMask &  highMask);
FN = sum(chsMask  & ~highMask);

sensitivity = TP / max(1, TP+FN) * 100;
specificity = TN / max(1, TN+FP) * 100;
ppv = TP / max(1, TP+FP) * 100;
accuracy = (TP+TN) / n * 100;

% 绘制验证报告图
screenSz = get(0, 'ScreenSize');
rFig = figure('Name', 'CHS AI 系统 — 10例临床验证报告', ...
    'NumberTitle', 'off', 'Color', [0.08,0.08,0.12], ...
    'Position', [80, 60, 1200, 700]);

bgC = [0.08,0.08,0.12];

% 左：散点图 TTS vs Peak Ratio，按结局着色
ax1 = axes('Parent', rFig, 'Position', [0.06, 0.12, 0.35, 0.76], ...
    'Color', [0.12,0.12,0.18], 'XColor','w', 'YColor','w');
hold(ax1,'on');
for i = 1:n
    if strcmp(db.outcome{i}, 'CHS')
        mk='o'; mc=[1,0.3,0.3]; ms=120;
    else
        mk='s'; mc=[0.3,0.85,0.5]; ms=100;
    end
    scatter(ax1, db.TTS(i), db.peakRatio(i), ms, mc, 'filled', mk, ...
        'MarkerEdgeColor','w', 'LineWidth',1.2);
    text(ax1, db.TTS(i)+0.05, db.peakRatio(i), db.cases{i}, ...
        'Color','w', 'FontSize',8);
end
xline(ax1, 3.2, '--', 'Color',[1,0.4,0.4], 'LineWidth',2, ...
    'Label','TTS=3.2s (Yamauchi 2017)', 'LabelColor',[1,0.6,0.6]);
yline(ax1, 2.0, '--', 'Color',[1,0.8,0.3], 'LineWidth',1.5, ...
    'Label','2.0× (Lai et al.)', 'LabelColor',[1,0.85,0.5]);
xlabel(ax1,'TTS 跨狭窄时移 (s)','Color','w');
ylabel(ax1,'Peak 衰减比 (近端/远端)','Color','w');
title(ax1,'TTS–PeakRatio 散点图 (● CHS | ■ 正常)', 'Color','w','FontSize',11,'FontWeight','bold');
legend(ax1, {'CHS 发生','正常出院'}, 'TextColor','w','Color','none','EdgeColor','none');
grid(ax1,'on'); ax1.GridAlpha=0.2;
hold(ax1,'off');

% 中：CHS评分箱线图（分组）
ax2 = axes('Parent', rFig, 'Position', [0.47, 0.12, 0.22, 0.76], ...
    'Color', [0.12,0.12,0.18], 'XColor','w', 'YColor','w');
scores_CHS  = db.chsScore(chsMask)  * 100;
scores_Norm = db.chsScore(~chsMask) * 100;
bpData = {scores_Norm(:); scores_CHS(:)};
bpLabels = {'正常','CHS'};
for gi = 1:2
    vals = bpData{gi};
    if isempty(vals), continue; end
    xCenter = gi;
    clr = [0.3,0.85,0.5]; if gi==2, clr=[1,0.3,0.3]; end
    scatter(ax2, xCenter + (rand(1,length(vals))-0.5)*0.2, vals, 80, clr, 'filled', 'o', ...
        'MarkerEdgeColor','w');
    hold(ax2,'on');
    line(ax2, [xCenter-0.2, xCenter+0.2], [mean(vals),mean(vals)], ...
        'Color','w', 'LineWidth',2.5);
end
set(ax2,'XTick',1:2,'XTickLabel',bpLabels,'YLim',[0,100]);
ylabel(ax2,'AI CHS 评分 (%)','Color','w');
title(ax2,'AI评分分组对比','Color','w','FontSize',11,'FontWeight','bold');
yline(ax2,65,'--','Color',[1,0.5,0.5],'LineWidth',1.5,'Label','65%阈值');
grid(ax2,'on'); ax2.GridAlpha=0.2;

% 右：验证指标文字面板
panelBG = [0.14,0.14,0.22];
infoPanel = uipanel('Parent',rFig, 'Units','normalized', ...
    'Position',[0.72, 0.08, 0.26, 0.84], ...
    'BackgroundColor',panelBG,'ForegroundColor','w', ...
    'Title','  临床验证指标', 'FontSize',11,'FontWeight','bold');

metrics = {
    sprintf('总病例数:  %d 例', n);
    sprintf('CHS发生:   %d 例', sum(chsMask));
    sprintf('正常出院:  %d 例', sum(~chsMask));
    '';
    sprintf('灵敏度 (Sensitivity):  %.1f%%', sensitivity);
    sprintf('特异度 (Specificity):  %.1f%%', specificity);
    sprintf('阳性预测值 (PPV):     %.1f%%', ppv);
    sprintf('总体准确率:            %.1f%%', accuracy);
    '';
    sprintf('真阳性 (TP):  %d', TP);
    sprintf('真阴性 (TN):  %d', TN);
    sprintf('假阳性 (FP):  %d', FP);
    sprintf('假阴性 (FN):  %d', FN);
};

metricsStr = strjoin(metrics, '\n');
uicontrol('Parent',infoPanel,'Style','text','Units','normalized', ...
    'Position',[0.05,0.35,0.90,0.62],'String',metricsStr, ...
    'ForegroundColor',[0.95,0.95,0.95],'BackgroundColor',panelBG, ...
    'FontSize',11,'FontName','Consolas','HorizontalAlignment','left');

% 结论
if accuracy >= 70
    conColor = [0.3,1,0.5]; conStr = '✅  系统验证通过 — 具有临床辅助价值';
else
    conColor = [1,0.8,0.3]; conStr = '⚠️  需进一步优化阈值';
end
uicontrol('Parent',infoPanel,'Style','text','Units','normalized', ...
    'Position',[0.03,0.16,0.94,0.16],'String',conStr, ...
    'ForegroundColor',conColor,'BackgroundColor',panelBG, ...
    'FontSize',11,'FontWeight','bold','HorizontalAlignment','center');

uicontrol('Parent',infoPanel,'Style','text','Units','normalized', ...
    'Position',[0.03,0.02,0.94,0.12], ...
    'String','基于 Yamauchi 2017 文献阈值\nTTS>3.2s 判定为高风险', ...
    'ForegroundColor',[0.6,0.6,0.6],'BackgroundColor',panelBG, ...
    'FontSize',8,'HorizontalAlignment','center');

log_addWorkLog(sprintf('生成验证报告: N=%d, Sens=%.1f%%, Spec=%.1f%%, Acc=%.1f%%', ...
    n, sensitivity, specificity, accuracy));
end

function exportCSV(fig)
db = getappdata(fig, 'validationDB');
if isempty(db.TTS)
    utils_showMessage('暂无数据可导出', 'error'); return;
end
[fname, pname] = uiputfile('*.csv','保存验证数据CSV', 'CHS_Validation_Results.csv');
if isequal(fname,0), return; end
fid = fopen(fullfile(pname,fname),'w','n','UTF-8');
fprintf(fid,'病案编号,TTS(s),Peak衰减比,CHS评分(%%),风险等级,临床结局\n');
for i = 1:length(db.TTS)
    fprintf(fid,'%s,%.3f,%.2f,%d,%s,%s\n', ...
        db.cases{i}, db.TTS(i), db.peakRatio(i), ...
        round(db.chsScore(i)*100), db.riskTier{i}, db.outcome{i});
end
fclose(fid);
utils_showMessage(sprintf('已导出 %d 例数据到 %s', length(db.TTS), fname), 'success');
end

function clearDB(fig, vFig)
choice = questdlg('确定清空所有验证记录？', '确认', '清空', '取消', '取消');
if strcmp(choice,'清空')
    db.cases={}; db.TTS=[]; db.peakRatio=[]; db.chsScore=[]; db.riskTier={}; db.outcome={};
    setappdata(fig, 'validationDB', db);
    set(vFig,'Name','CHS AI 临床验证管理工具  [已记录 0/10 例]');
    tbl = getappdata(vFig,'summaryTable');
    set(tbl,'Data',repmat({'-'},1,6));
end
end
