function analysis_analyzeCurves(varargin)
% 对狭窄双端的曲线进行高阶拟合，并计算核心时移参数
fig = gcf; data = guidata(fig);
if isempty(data.timeSeriesData) || size(data.timeSeriesData, 1) ~= 2
    utils_showMessage('请先成功提取双端时间序列数据', 'error'); return;
end
log_updateStatus('正在拟合双端TDC曲线...');
try
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    if ishandle(frameRateEdit), frameRate = str2double(get(frameRateEdit, 'String')); else, frameRate = 4; end
    if isnan(frameRate), frameRate = 4; end
    
    tsData = double(data.timeSeriesData); % 2 x nFrames
    [~, nFrames] = size(tsData);
    t = (0:nFrames-1) / frameRate;
    
    nSteps = max(100, nFrames * 10);
    t_highres = linspace(t(1), t(end), nSteps);
    smoothedData = zeros(2, length(t_highres));
    perfusionParams = struct();
    
    for i = 1:2
        smoothedData(i, :) = pchip(t, tsData(i, :), t_highres);
        curve = smoothedData(i, :);
        
        [maxVal, maxIdx] = max(curve);
        TMAX = t_highres(maxIdx);
        bEnd = max(2, floor(length(curve) * 0.1));
        baseline = mean(curve(1:bEnd));
        
        batThresh = baseline + 0.1 * max(1.0, (maxVal - baseline));
        tuIdx = find(curve > batThresh, 1, 'first');
        if isempty(tuIdx), tuIdx = 1; end
        TU = t_highres(tuIdx);
        
        cCorr = max(0, curve - baseline);
        AUC = trapz(t_highres, cCorr);
        cumA = cumtrapz(t_highres, cCorr);
        tAUC = cumA(end);
        
        if tAUC > 0
            mIdx = find(cumA >= tAUC/2, 1, 'first');
            if isempty(mIdx), MTT = TMAX; else, MTT = t_highres(mIdx); end
        else, MTT = TMAX; end
        
        % 计算 FWHM (全距半峰宽) 用于后续色散分析
        halfPeak = baseline + (maxVal - baseline) / 2;
        leftIdx = find(curve(1:maxIdx) >= halfPeak, 1, 'first');
        rightIdx = find(curve(maxIdx:end) <= halfPeak, 1, 'first') + maxIdx - 1;
        if isempty(leftIdx), leftIdx = 1; end
        if isempty(rightIdx), rightIdx = length(curve); end
        FWHM = t_highres(rightIdx) - t_highres(leftIdx);
        
        perfusionParams(i).TMAX = TMAX;
        perfusionParams(i).MTT = MTT;
        perfusionParams(i).TU = TU;
        perfusionParams(i).AUC = AUC;
        perfusionParams(i).FWHM = FWHM;
        perfusionParams(i).Peak = maxVal;
    end
    
    data.perfusionParams = perfusionParams;
    data.smoothedLobeData = smoothedData; % Reuse this struct field name for backward compatibility
    data.t_highres = t_highres;
    data.frameRate = frameRate;
    
    % 【升级】在这里提前计算一次 DTW，用于在表格中直接展示
    try
        [dtwDist, ~] = analysis_computeDTW(smoothedData(1,:), smoothedData(2,:));
    catch
        dtwDist = 0;
    end
    data.analysisInfo.DTW_Distance = dtwDist; % 顺便存入供导出
    guidata(fig, data);
    
    showPerfusionParams(perfusionParams, data.roiNames, dtwDist);
    log_updateStatus('双端曲线拟合成功 (含DTW计算)');
catch ME
    utils_showMessage('曲线分析失败', 'error', ME.message);
    log_updateStatus('曲线分析失败');
end
end

function showPerfusionParams(params, roiNames, dtwDist)
% ── 自适应窗口尺寸 ──────────────────────────────────────────────────────
screenSz = get(0, 'ScreenSize');
figW    = min(860, round(screenSz(3) * 0.58));
bannerH = 72;    % 底部风险横幅高度(px)
margin  = 10;
rowH    = 22;    % 每行大约高度
nRows   = 8;     % 现为8行（新增 TTS 行）
tableMinH = rowH * (nRows + 1) + 8;   % 表头+8行数据
figH    = tableMinH + bannerH + margin * 3;
figH    = max(figH, 360);
figH    = min(figH, round(screenSz(4) * 0.55));
figL    = round((screenSz(3) - figW) / 2);
figT    = round((screenSz(4) - figH) / 2);

paramFig = figure('Name', '狭窄双端血流参数表', ...
    'NumberTitle', 'off', ...
    'Position', [figL, figT, figW, figH], ...
    'MenuBar', 'none', ...
    'Resize', 'on', ...
    'Color', [0.13, 0.13, 0.18]);   % 深色背景，更专业

% ── 衍生指标计算 ────────────────────────────────────────────────────────
TTS       = max(0, params(2).TMAX - params(1).TMAX);
peakRatio = params(1).Peak / max(eps, params(2).Peak);
fwhm_inv  = params(1).FWHM > params(2).FWHM;   % 近端>远端 = 波形压缩

% FWHM 标注：倒置时在近端值旁加警告符号
fwhm1_str = sprintf('%.3f', params(1).FWHM);
fwhm2_str = sprintf('%.3f', params(2).FWHM);
if fwhm_inv
    fwhm1_str = [fwhm1_str, '  ⚠'];   % 提示近端半峰宽异常偏大
end

% ── 构建8行参数表 ───────────────────────────────────────────────────────
paramNames = {
    'TTP  达峰时间 (s)';
    'MTT  平均通过时间 (s)';
    'TU   造影剂到达时 (s)';
    'FWHM 半峰宽 (s)';
    'AUC  曲线下面积';
    'Peak 最大浓度';
    'WFD  波形失真指数';      % 原DTW，重命名为更准确的英文缩写
    'TTS  跨狭窄时移 (s)';    % 新增：Yamauchi 2017 核心指标
};

tableData = cell(8, 3);
for i = 1:8
    tableData{i, 1} = paramNames{i};
    switch i
        case 1
            tableData{i,2} = sprintf('%.3f', params(1).TMAX);
            tableData{i,3} = sprintf('%.3f', params(2).TMAX);
        case 2
            tableData{i,2} = sprintf('%.3f', params(1).MTT);
            tableData{i,3} = sprintf('%.3f', params(2).MTT);
        case 3
            tableData{i,2} = sprintf('%.3f', params(1).TU);
            tableData{i,3} = sprintf('%.3f', params(2).TU);
        case 4
            tableData{i,2} = fwhm1_str;
            tableData{i,3} = fwhm2_str;
        case 5
            tableData{i,2} = sprintf('%.1f', params(1).AUC);
            tableData{i,3} = sprintf('%.1f', params(2).AUC);
        case 6
            tableData{i,2} = sprintf('%.1f', params(1).Peak);
            tableData{i,3} = sprintf('%.1f', params(2).Peak);
        case 7
            tableData{i,2} = sprintf('%.4f', dtwDist);
            tableData{i,3} = '-';
        case 8   % TTS —— 双端之间的时移，第3列放文献参考阈值说明
            tableData{i,2} = sprintf('%.3f', TTS);
            tableData{i,3} = '>3.2s=高风险 (Yamauchi 2017)';
    end
end

% ── 风险等级判定 ────────────────────────────────────────────────────────
if TTS >= 5.0
    riskLabel  = '  🔴  极高风险  CHS 风险极高';
    riskColor  = [1.00, 0.28, 0.28];
    riskDetail = sprintf('TTS = %.2f s  ( ≥ 5.0 s 极高风险 )    |    Peak 衰减 × %.2f', TTS, peakRatio);
elseif TTS >= 3.2
    riskLabel  = '  🟡  中高风险  建议临床关注';
    riskColor  = [1.00, 0.72, 0.08];
    riskDetail = sprintf('TTS = %.2f s  ( ≥ 3.2 s, Yamauchi 2017, Spec 100%% )    |    Peak 衰减 × %.2f', TTS, peakRatio);
else
    riskLabel  = '  🟢  低风险  TTS 在安全范围内';
    riskColor  = [0.25, 0.88, 0.42];
    riskDetail = sprintf('TTS = %.2f s  ( < 3.2 s 安全范围 )    |    Peak 衰减 × %.2f', TTS, peakRatio);
end

% ── 布局：上方表格 + 下方风险横幅 ──────────────────────────────────────
tableW = figW - margin * 2;
tableH = figH - bannerH - margin * 3;

col1 = round(tableW * 0.42);
col2 = round(tableW * 0.26);
col3 = tableW - col1 - col2 - 2;

tbl = uitable('Parent', paramFig, ...
    'Data', tableData, ...
    'Units', 'pixels', ...
    'Position', [margin, bannerH + margin * 2, tableW, tableH], ...
    'ColumnWidth', {col1, col2, col3}, ...
    'RowName', [], ...
    'ColumnName', {'参数', '近端 ROI', '远端 ROI'}, ...
    'FontSize', 10, ...
    'FontName', 'Microsoft YaHei', ...
    'RowStriping', 'on');

% ── 行级颜色高亮（MATLAB R2020a+ 的 uistyle，旧版自动跳过）────────────
try
    % 第8行：TTS 按风险分级着色
    if TTS >= 5.0
        s_tts = uistyle('BackgroundColor',[0.55,0.10,0.10],'FontColor',[1,0.8,0.8],'FontWeight','bold');
    elseif TTS >= 3.2
        s_tts = uistyle('BackgroundColor',[0.50,0.35,0.02],'FontColor',[1,0.95,0.6],'FontWeight','bold');
    else
        s_tts = uistyle('BackgroundColor',[0.08,0.38,0.12],'FontColor',[0.7,1,0.7],'FontWeight','bold');
    end
    addStyle(tbl, s_tts, 'row', 8);

    % 第6行：Peak 衰减 ≥2× 时橙色提示
    if peakRatio >= 2.0
        s_peak = uistyle('BackgroundColor',[0.45,0.28,0.03],'FontColor',[1,0.90,0.55]);
        addStyle(tbl, s_peak, 'row', 6);
    end

    % 第4行：FWHM 倒置时黄色提示
    if fwhm_inv
        s_fwhm = uistyle('BackgroundColor',[0.40,0.35,0.02],'FontColor',[1,0.95,0.5]);
        addStyle(tbl, s_fwhm, 'row', 4);
    end
catch
    % uistyle 在当前 MATLAB 版本不可用，跳过，不影响功能
end

% ── 风险横幅（底部彩色面板）────────────────────────────────────────────
panelBG = riskColor * 0.18 + [0.07, 0.07, 0.07];  % 深色变体背景

riskPanel = uipanel('Parent', paramFig, ...
    'Units', 'pixels', ...
    'Position', [margin, margin, figW - margin*2, bannerH], ...
    'BackgroundColor', panelBG, ...
    'BorderType', 'line', ...
    'HighlightColor', riskColor, ...
    'Title', '');

uicontrol('Parent', riskPanel, 'Style', 'text', ...
    'Units', 'normalized', 'Position', [0.01, 0.50, 0.99, 0.44], ...
    'String', riskLabel, ...
    'ForegroundColor', riskColor, ...
    'BackgroundColor', panelBG, ...
    'FontSize', 13, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

uicontrol('Parent', riskPanel, 'Style', 'text', ...
    'Units', 'normalized', 'Position', [0.01, 0.04, 0.99, 0.44], ...
    'String', riskDetail, ...
    'ForegroundColor', [0.88, 0.88, 0.88], ...
    'BackgroundColor', panelBG, ...
    'FontSize', 9, ...
    'HorizontalAlignment', 'center');

% ── FWHM 倒置提示（仅在异常时出现）────────────────────────────────────
if fwhm_inv
    utils_showMessage( ...
        sprintf(['FWHM 检测: 近端半峰宽 (%.2fs) > 远端 (%.2fs)\n', ...
                 '这提示远端灌注不足导致波形压缩，是狭窄后灌注受损的特征表现。'], ...
                 params(1).FWHM, params(2).FWHM), 'info');
end

% ── 窗口 Resize 自动拉伸 ─────────────────────────────────────────────
set(paramFig, 'ResizeFcn', @(src,~) resizeParamFig(src, tbl, riskPanel, margin, bannerH));
end

function resizeParamFig(fig, tbl, riskPanel, margin, bannerH)
% 窗口 Resize 时同步更新表格和风险横幅的尺寸
pos  = getpixelposition(fig);
figW = pos(3);
figH = pos(4);

newTableW = figW - margin * 2;
newTableH = figH - bannerH - margin * 3;
set(tbl, 'Position', [margin, bannerH + margin * 2, newTableW, newTableH]);

col1 = round(newTableW * 0.42);
col2 = round(newTableW * 0.26);
col3 = newTableW - col1 - col2 - 2;
set(tbl, 'ColumnWidth', {col1, col2, col3});

set(riskPanel, 'Position', [margin, margin, figW - margin*2, bannerH]);
end
