function analysis_runComparison(varargin)
% analysis_runComparison  术前术后双端 TDC 对比分析 GUI 入口
% 从 PatientData 里选取术前/术后 .mat 文件，运行完整对比流程，
% 并将文献阈值判定结果回写到右侧面板，显示临床报告。
%
% 已更新：移除无科学依据的 CHS Sigmoid 评分 + 雷达图 + DTW 瀑布图
% 现在基于 Yamauchi 2017 (TTS) 和 Lai et al. (VBI) 两个有文献支撑的独立指标。

fig = gcf;
data = guidata(fig);

%% 1. 选择术前数据文件
[preFname, prePname] = uigetfile('*.mat', '请选择【术前】分析结果 (.mat)');
if isequal(preFname, 0), return; end

%% 2. 选择术后数据文件
[postFname, postPname] = uigetfile('*.mat', '请选择【术后】分析结果 (.mat)');
if isequal(postFname, 0), return; end

log_updateStatus('正在加载术前/术后数据进行对比...');

try
    preLoaded  = load(fullfile(prePname,  preFname));
    postLoaded = load(fullfile(postPname, postFname));

    if ~isfield(preLoaded, 'data') || ~isfield(postLoaded, 'data')
        utils_showMessage('文件格式错误：.mat 文件中必须包含 "data" 变量', 'error');
        return;
    end

    preOpData  = preLoaded.data;
    postOpData = postLoaded.data;

    %% 3. 调用核心对比算法
    results = analysis_computeComparison(preOpData, postOpData);

    %% 4. 根据文献阈值判定回写右侧面板
    riskResultText = getappdata(fig, 'riskResultText');
    if ishandle(riskResultText)
        if contains(results.warningLevel, '高危')
            set(riskResultText, 'String', sprintf('🔴 %s', results.warningLevel), ...
                'ForegroundColor', [0.9, 0.2, 0.2]);
        elseif contains(results.warningLevel, '中危')
            set(riskResultText, 'String', sprintf('🟠 %s', results.warningLevel), ...
                'ForegroundColor', [0.9, 0.6, 0.1]);
        else
            set(riskResultText, 'String', sprintf('🟢 %s', results.warningLevel), ...
                'ForegroundColor', [0.2, 0.7, 0.3]);
        end
    end

    %% 5. 弹出临床报告窗口（文献阈值 + 建议 + TDC 对比曲线）
    screenSize = get(0, 'ScreenSize');
    resFig = figure('Name', '术前术后血流动力学对比报告', ...
        'NumberTitle', 'off', ...
        'Position', [(screenSize(3)-1300)/2, (screenSize(4)-820)/2, 1300, 820], ...
        'Color', [0.12, 0.12, 0.18]);

    %--- 顶部：预警横幅 ---
    bannerColor = [0.25 0.08 0.08];
    textColor   = [1.00 0.75 0.75];
    if contains(results.warningLevel, '低风险')
        bannerColor = [0.08 0.25 0.10]; textColor = [0.75 1.00 0.80];
    elseif contains(results.warningLevel, '中危')
        bannerColor = [0.25 0.18 0.04]; textColor = [1.00 0.92 0.60];
    end
    annotation(resFig, 'textbox', [0, 0.955, 1, 0.045], ...
        'String', results.warningText, ...
        'FontSize', 13, 'FontWeight', 'bold', ...
        'Color', textColor, 'BackgroundColor', bannerColor, ...
        'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

    %--- 左上：术前 vs 术后 远端 TDC 对比 ---
    ax1 = axes('Parent', resFig, 'Units', 'normalized', 'Position', [0.05, 0.55, 0.42, 0.37]);
    set(ax1, 'Color', [0.15 0.15 0.2], 'XColor', 'w', 'YColor', 'w');
    try
        t_pre  = (0:size(preOpData.timeSeriesData, 2)-1) / preOpData.frameRate;
        t_post = (0:size(postOpData.timeSeriesData, 2)-1) / postOpData.frameRate;
        plot(ax1, t_pre,  preOpData.timeSeriesData(2,:),  'Color', [0.9 0.5 0.3], 'LineWidth', 2, 'DisplayName', '术前 远端');
        hold(ax1, 'on');
        plot(ax1, t_post, postOpData.timeSeriesData(2,:), 'Color', [0.4 0.8 1.0], 'LineWidth', 2, 'DisplayName', '术后 远端');
        
        % 添加结束点标记，防止被误解为“线条断裂”
        plot(ax1, t_pre(end), preOpData.timeSeriesData(2,end), 'o', 'Color', [0.9 0.5 0.3], 'MarkerFaceColor', [0.9 0.5 0.3], 'MarkerSize', 5, 'HandleVisibility', 'off');
        plot(ax1, t_post(end), postOpData.timeSeriesData(2,end), 's', 'Color', [0.4 0.8 1.0], 'MarkerFaceColor', [0.4 0.8 1.0], 'MarkerSize', 5, 'HandleVisibility', 'off');
        
        legend(ax1, 'TextColor', 'w', 'Color', 'none', 'EdgeColor', 'none', 'Location', 'northeast');
    catch; end
    xlabel(ax1, '时间 (s)', 'Color', 'w');
    ylabel(ax1, '相对造影剂密度', 'Color', 'w');
    title(ax1, '远端 TDC 术前/术后对比', 'Color', 'w', 'FontWeight', 'bold');
    grid(ax1, 'on'); ax1.GridAlpha = 0.2;

    %--- 右上：关键参数改善量条形图 ---
    ax2 = axes('Parent', resFig, 'Units', 'normalized', 'Position', [0.55, 0.55, 0.40, 0.37]);
    set(ax2, 'Color', [0.15 0.15 0.2], 'XColor', 'w', 'YColor', 'w', ...
        'GridColor', [0.4 0.4 0.4], 'GridAlpha', 0.3, 'XGrid', 'on', 'YGrid', 'on');

    % 只展示两个有文献支撑的指标（TTS 和 Peak Attenuation）
    metricNames = {'TTS (s)', 'Peak Atten (×)'};
    preVals2  = [results.preTTS,      results.prePeakRatio];
    postVals2 = [results.postTTS,     results.postPeakRatio];

    barData = [preVals2; postVals2]';
    b = bar(ax2, barData, 'grouped');
    b(1).FaceColor = [0.9 0.5 0.3]; b(1).EdgeColor = 'none'; b(1).DisplayName = '术前';
    b(2).FaceColor = [0.4 0.8 1.0]; b(2).EdgeColor = 'none'; b(2).DisplayName = '术后';

    set(ax2, 'XTickLabel', metricNames, 'FontSize', 10);

    % 在柱顶标注数值
    for k = 1:2
        text(ax2, b(1).XEndPoints(k), b(1).YEndPoints(k) + 0.05, ...
            sprintf('%.2f', preVals2(k)), 'HorizontalAlignment','center', ...
            'Color','w', 'FontSize', 8, 'FontWeight', 'bold');
        text(ax2, b(2).XEndPoints(k), b(2).YEndPoints(k) + 0.05, ...
            sprintf('%.2f', postVals2(k)), 'HorizontalAlignment','center', ...
            'Color','w', 'FontSize', 8, 'FontWeight', 'bold');
    end

    % 标注阈值线
    yline(ax2, 3.2, '--', 'TTS阈值3.2s', 'Color', [1,0.4,0.4], 'LineWidth', 1.2, ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'Alpha', 0.8);
    yline(ax2, 2.0, '--', 'PA阈值2.0×', 'Color', [1,0.8,0.2], 'LineWidth', 1.2, ...
        'LabelHorizontalAlignment', 'left', 'FontSize', 8, 'Alpha', 0.8);

    legend(ax2, 'TextColor', 'w', 'Color', [0.15 0.15 0.2], 'EdgeColor', [0.4 0.4 0.4]);
    title(ax2, '关键指标术前/术后对比', 'Color', 'w', 'FontWeight', 'bold');


    %--- 底部：文献阈值判定 + 建议 ---
    advicePanel = uipanel('Parent', resFig, 'Units', 'normalized', ...
        'Position', [0.03, 0.03, 0.94, 0.48], ...
        'BackgroundColor', [0.15, 0.15, 0.22], ...
        'Title', '📋 临床文献阈值判定与建议 (Yamauchi 2017 | Lai et al.)', ...
        'ForegroundColor', [0.8, 0.9, 1], 'FontSize', 11, 'FontWeight', 'bold');

    % 文献阈值表格
    tableData = {
        'TTS (术前)', sprintf('%.2f s', results.preTTS), '> 3.2s = 高风险', results.tts_risk;
        'TTS (术后)', sprintf('%.2f s', results.postTTS), '改善目标 < 1.5s', sprintf('改善 %.2f s', results.TTS_Improvement);
        'Peak Atten (术前)', sprintf('×%.2f', results.prePeakRatio), '≥ 2.0× = 高风险 (Lai)', results.pa_risk;
        'Peak Atten (术后)', sprintf('×%.2f', results.postPeakRatio), '改善目标 < 1.3×', sprintf('改善 ×%.2f', results.PA_Improvement);
        'DTW 波形变化', sprintf('%.4f', results.DTW_longitudinal), '0=完全恢复，越小越好', '纵向波形相似度';
    };
    uitable('Parent', advicePanel, 'Data', tableData, ...
        'Units', 'normalized', 'Position', [0.01, 0.45, 0.98, 0.52], ...
        'ColumnName', {'指标', '数值', '文献阈值依据', '判定'}, ...
        'ColumnWidth', {150, 100, 220, 180}, ...
        'RowName', [], 'FontSize', 11);

    adviceStr = strjoin(results.advice, newline);
    uicontrol('Parent', advicePanel, 'Style', 'text', ...
        'String', adviceStr, ...
        'Units', 'normalized', 'Position', [0.02, 0.02, 0.96, 0.40], ...
        'FontSize', 11, 'HorizontalAlignment', 'left', ...
        'ForegroundColor', [0.9, 0.95, 1], ...
        'BackgroundColor', [0.15, 0.15, 0.22]);

    log_updateStatus(sprintf('对比分析完成 | %s', results.warningLevel));
    log_addWorkLog(sprintf('术前/术后对比: preTTS=%.2fs, postTTS=%.2fs, PA=×%.2f→×%.2f', ...
        results.preTTS, results.postTTS, results.prePeakRatio, results.postPeakRatio));

catch ME
    utils_showMessage('对比分析失败', 'error', ME.message);
    fprintf('对比分析错误:\n%s\n', ME.getReport());
    log_updateStatus('对比分析失败');
end
end
