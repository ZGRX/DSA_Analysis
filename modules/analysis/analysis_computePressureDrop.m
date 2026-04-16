function analysis_computePressureDrop(varargin)
% 跨狭窄血流动力学严重程度评估 — 基于文献阈值的独立双指标报告
%
% 保留指标（有文献依据）：
%   ① TTS (Transit Time Shift) → 对应 ΔCCT, 参考 Yamauchi 2017 [J Neurosurg]
%   ② Peak Attenuation (峰值衰减比) → 对应 VBI 原理, Lai et al.
%
% 移除指标：
%   → WFD 波形失真指数（原DTW横向对比，已重命名并迁移至 analysis_analyzeCurves 展示）
%   ✗ D-HSS综合评分（自创加权公式，无文献验证）

fig = gcf;
data = guidata(fig);

if ~isfield(data, 'perfusionParams') || length(data.perfusionParams) ~= 2
    utils_showMessage('请先完成【狭窄双端ROI放置】并【提取双端传导特性】', 'error');
    return;
end

log_updateStatus('正在计算跨狭窄血流动力学指标 (TTS / Peak Attenuation)...');
log_addWorkLog('开始计算跨狭窄血流动力学评估');

try
    p1 = data.perfusionParams(1); % Proximal (近端)
    p2 = data.perfusionParams(2); % Distal   (远端)

    % ── ① TTS: Transit Time Shift (时延) ─────────────────────────────
    % 生理意义：狭窄造成远端造影剂达峰时间延迟
    % 文献阈值：> 3.2 s → 高风险 CHS (Yamauchi 2017, Specificity=100%)
    TTS = max(0, p2.TMAX - p1.TMAX);

    % ── ② Peak Attenuation: 近端/远端峰值衰减倍数 ────────────────────
    % 生理意义：狭窄导致远端灌注压下降，峰值降低
    % 文献阈值：VBI ≥ 2.0 → 显著受损 (Lai et al.)
    peakRatio = p1.Peak / max(eps, p2.Peak);

    % ── 读取用户自定义阈值（存在则用，否则用文献默认值）─────────────────
    cfg = getappdata(fig, 'hemodynamicThresholds');
    if isempty(cfg)
        cfg = struct('TTS_warning', 3.2, 'TTS_critical', 5.0, ...
                     'Peak_warning', 2.0, 'Peak_critical', 4.0);
    end

    % ── 分级判断 ─────────────────────────────────────────────────────
    % TTS 分级
    if TTS >= cfg.TTS_critical
        tts_level = 3; tts_color = [1.0, 0.25, 0.25]; tts_text = '🔴 严重延迟';
        tts_ref   = sprintf('> %.1fs 为极高风险 [文献参考阈值]', cfg.TTS_critical);
    elseif TTS >= cfg.TTS_warning
        tts_level = 2; tts_color = [1.0, 0.75, 0.15]; tts_text = '🟡 中等延迟';
        tts_ref   = sprintf('> %.1fs (Yamauchi 2017, Spec 100%%)', cfg.TTS_warning);
    else
        tts_level = 1; tts_color = [0.35, 0.9, 0.45]; tts_text = '🟢 正常范围';
        tts_ref   = sprintf('< %.1fs 为低风险', cfg.TTS_warning);
    end

    % Peak Attenuation 分级
    if peakRatio >= cfg.Peak_critical
        pa_level = 3; pa_color = [1.0, 0.25, 0.25]; pa_text = '🔴 显著衰减';
        pa_ref   = sprintf('≥ %.1f 倍为极高风险 [文献参考阈值]', cfg.Peak_critical);
    elseif peakRatio >= cfg.Peak_warning
        pa_level = 2; pa_color = [1.0, 0.75, 0.15]; pa_text = '🟡 中等衰减';
        pa_ref   = sprintf('≥ %.1f 倍 (Lai et al., VBI原理)', cfg.Peak_warning);
    else
        pa_level = 1; pa_color = [0.35, 0.9, 0.45]; pa_text = '🟢 代偿良好';
        pa_ref   = sprintf('< %.1f 倍为低风险', cfg.Peak_warning);
    end

    % ── 自适应窗口 ─────────────────────────────────────────────────────
    screenSz = get(0, 'ScreenSize');
    figW = min(760, round(screenSz(3) * 0.50));
    figH = min(580, round(screenSz(4) * 0.60));
    figL = round((screenSz(3) - figW) / 2);
    figT = round((screenSz(4) - figH) / 2);

    resFig = figure('Name', '跨狭窄血流动力学评估 (TTS & Peak Attenuation)', ...
        'NumberTitle', 'off', 'Position', [figL, figT, figW, figH], ...
        'MenuBar', 'none', 'Resize', 'on', 'Color', [0.1, 0.1, 0.15]);

    % ── 上半：双端归一化曲线 ───────────────────────────────────────────
    ax1 = axes('Parent', resFig, 'Position', [0.10, 0.42, 0.82, 0.50], ...
        'Color', [0.15, 0.15, 0.2]);

    timeLine = data.t_highres;
    curve1   = data.smoothedLobeData(1,:);
    curve2   = data.smoothedLobeData(2,:);
    c1_norm  = curve1 / max(eps, max(curve1));
    c2_norm  = curve2 / max(eps, max(curve2));

    % ── 使用 perfusionParams 中已验证的 TMAX 定位圆圈标记 ────────────────
    % 科学依据：可视化标注必须与 CHS 评分使用完全相同的数据源。
    % 原方案在截断曲线(前65%)中重新找峰，与 perfusionParams.TMAX 来源不同，
    % 导致 TTS_plot 与真实 TTS 不一致（如本例出现 0.0s vs 0.75s 的偏差）。
    % 修正方案：直接在 timeLine 中找最近 p1.TMAX / p2.TMAX 对应的索引。
    [~, ttp1_fp] = min(abs(timeLine - p1.TMAX));
    [~, ttp2_fp] = min(abs(timeLine - p2.TMAX));
    t_ttp1 = timeLine(ttp1_fp);
    t_ttp2 = timeLine(ttp2_fp);
    TTS_plot = TTS;   % 与 CHS 评分完全一致，消除视觉歧义

    h1 = plot(ax1, timeLine, c1_norm, 'LineWidth', 2.2, 'Color', [1, 0.4, 0.4]); hold on;
    h2 = plot(ax1, timeLine, c2_norm, 'LineWidth', 2.2, 'Color', [0.4, 0.8, 1]);

    % ── TTP 标记点 ──────────────────────────────────────────────────────
    plot(ax1, t_ttp1, c1_norm(ttp1_fp), 'o', 'MarkerSize', 9, ...
        'MarkerEdgeColor', [1,0.4,0.4], 'MarkerFaceColor', 'w', 'LineWidth', 2);
    plot(ax1, t_ttp2, c2_norm(ttp2_fp), 'o', 'MarkerSize', 9, ...
        'MarkerEdgeColor', [0.4,0.8,1], 'MarkerFaceColor', 'w', 'LineWidth', 2);

    % ── TTS 延迟箭头标注 ─────────────────────────────────────────────────
    arrowY = 0.88;
    plot(ax1, [t_ttp1, t_ttp2], [arrowY, arrowY], '-', ...
        'Color', [1,0.85,0.3], 'LineWidth', 1.5);
    plot(ax1, [t_ttp1, t_ttp1], [arrowY-0.04, arrowY+0.04], '-', ...
        'Color', [1,0.85,0.3], 'LineWidth', 1.5);
    plot(ax1, [t_ttp2, t_ttp2], [arrowY-0.04, arrowY+0.04], '-', ...
        'Color', [1,0.85,0.3], 'LineWidth', 1.5);
    text(ax1, (t_ttp1+t_ttp2)/2, arrowY+0.06, ...
        sprintf('TTS = %.2f s', TTS_plot), ...
        'Color', [1,0.85,0.3], 'FontSize', 10, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');

    % ── 峰值衰减比标注（原始峰值之比，非归一化）────────────────────────
    rawPeakRatio = p1.Peak / max(eps, p2.Peak);
    ytext = 0.35;
    text(ax1, timeLine(end)*0.98, ytext, ...
        sprintf('Peak Ratio = ×%.2f', rawPeakRatio), ...
        'Color', [0.9,0.6,0.9], 'FontSize', 9, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'BackgroundColor', [0.15,0.15,0.2]);

    plotHandles  = [h1, h2];
    legendLabels = {'近端 Proximal ROI', '远端 Distal ROI'};

    % 术前参比叠印（保留此功能，有实际临床价值）
    choice = questdlg('是否叠加【术前远端波形】进行疗效对比？', '可选：术前参比叠印', '是', '否', '否');
    if strcmp(choice, '是')
        [fname, pname] = uigetfile('*.mat', '选择术前参比数据.mat');
        if ~isequal(fname, 0)
            try
                preDataFile = load(fullfile(pname, fname));
                if isfield(preDataFile.data, 'smoothedLobeData') && ...
                        size(preDataFile.data.smoothedLobeData, 1) >= 2
                    pre_c2      = preDataFile.data.smoothedLobeData(2,:);
                    pre_t       = preDataFile.data.t_highres;
                    pre_c2_norm = pre_c2 / max(eps, max(pre_c2));
                    h3 = plot(ax1, pre_t, pre_c2_norm, '--', 'LineWidth', 1.8, ...
                        'Color', [0.65, 0.65, 0.65]);
                    plotHandles(end+1)  = h3;
                    legendLabels{end+1} = '术前远端参比 (Pre-Op Distal)';
                    log_addWorkLog('已叠加术前远端参比波形');
                end
            catch
                utils_showMessage('读取术前参比数据失败', 'warn');
            end
        end
    end

    grid on; ax1.GridAlpha = 0.15; ax1.GridColor = [0.5 0.5 0.5];
    legend(ax1, plotHandles, legendLabels, 'TextColor', 'w', ...
        'Color', [0.12,0.12,0.18], 'EdgeColor', [0.4,0.4,0.4], 'Location', 'northeast');
    title(ax1, '狭窄双端归一化灌注曲线 — ○标记为一过渡期TTP', ...
        'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(ax1, '时间 (s)', 'Color', [0.8 0.8 0.8]);
    ylabel(ax1, '归一化造影剂浓度', 'Color', [0.8 0.8 0.8]);
    ax1.XColor = [0.7 0.7 0.7]; ax1.YColor = [0.7 0.7 0.7];
    ylim(ax1, [-0.05, 1.15]);



    % ── 下半：两个独立指标面板 ─────────────────────────────────────────
    % 指标①：TTS
    panelTTS = uipanel('Parent', resFig, ...
        'Position', [0.05, 0.03, 0.43, 0.36], ...
        'BackgroundColor', [0.15 0.15 0.2], ...
        'ForegroundColor', 'w', ...
        'Title', '① TTS  Transit Time Shift', ...
        'FontSize', 10, 'FontWeight', 'bold');

    uicontrol('Parent', panelTTS, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.05, 0.60, 0.90, 0.30], ...
        'String', sprintf('%.3f  秒', TTS), ...
        'ForegroundColor', tts_color, 'BackgroundColor', [0.15 0.15 0.2], ...
        'FontSize', 18, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    uicontrol('Parent', panelTTS, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.05, 0.36, 0.90, 0.22], ...
        'String', tts_text, ...
        'ForegroundColor', tts_color, 'BackgroundColor', [0.15 0.15 0.2], ...
        'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    uicontrol('Parent', panelTTS, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.05, 0.02, 0.90, 0.30], ...
        'String', tts_ref, ...
        'ForegroundColor', [0.75 0.75 0.75], 'BackgroundColor', [0.15 0.15 0.2], ...
        'FontSize', 8, 'HorizontalAlignment', 'center');

    % 指标②：Peak Attenuation
    panelPA = uipanel('Parent', resFig, ...
        'Position', [0.52, 0.03, 0.43, 0.36], ...
        'BackgroundColor', [0.15 0.15 0.2], ...
        'ForegroundColor', 'w', ...
        'Title', '② Peak Attenuation  峰值衰减比', ...
        'FontSize', 10, 'FontWeight', 'bold');

    uicontrol('Parent', panelPA, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.05, 0.60, 0.90, 0.30], ...
        'String', sprintf('× %.2f', peakRatio), ...
        'ForegroundColor', pa_color, 'BackgroundColor', [0.15 0.15 0.2], ...
        'FontSize', 18, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    uicontrol('Parent', panelPA, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.05, 0.36, 0.90, 0.22], ...
        'String', pa_text, ...
        'ForegroundColor', pa_color, 'BackgroundColor', [0.15 0.15 0.2], ...
        'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    uicontrol('Parent', panelPA, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.05, 0.02, 0.90, 0.30], ...
        'String', pa_ref, ...
        'ForegroundColor', [0.75 0.75 0.75], 'BackgroundColor', [0.15 0.15 0.2], ...
        'FontSize', 8, 'HorizontalAlignment', 'center');

    % ── 阈值设置按钮（医生可调整）────────────────────────────────────────
    uicontrol('Parent', resFig, 'Style', 'pushbutton', ...
        'String', '⚙ 修改阈值设置 (Threshold Settings)', ...
        'Units', 'normalized', 'Position', [0.25, 0.005, 0.50, 0.04], ...
        'FontSize', 9, 'BackgroundColor', [0.25 0.35 0.5], 'ForegroundColor', 'w', ...
        'Callback', @(~,~) openThresholdEditor(fig, resFig, cfg));

    log_addWorkLog(sprintf('跨狭窄评估完成: TTS=%.2fs [%s], PeakAtten=x%.2f [%s]', ...
        TTS, tts_text, peakRatio, pa_text));
    log_updateStatus('跨狭窄血流动力学评估完成');

catch ME
    utils_showMessage('评估计算失败', 'error', ME.message);
    log_addWorkLog(sprintf('评估失败: %s', ME.message));
end
end

% ============================================================
% 阈值设置编辑器（医生手动修改，附文献来源说明）
% ============================================================
function openThresholdEditor(mainFig, resFig, cfg)

edFig = figure('Name', '阈值设置 — 请参考文献来源修改', ...
    'NumberTitle', 'off', 'Position', [400, 300, 460, 360], ...
    'MenuBar', 'none', 'Color', [0.13, 0.13, 0.18], 'Resize', 'off');

labels = {
    'TTS 中等风险阈值 (s)',  '(默认 3.2s, Yamauchi 2017, J Neurosurg)';
    'TTS 严重风险阈值 (s)',  '(默认 5.0s, 超出此值极高风险)';
    'Peak Atten 中等阈值 (×)', '(默认 2.0, Lai et al. VBI原理)';
    'Peak Atten 严重阈值 (×)', '(默认 4.0, 超出此值极高风险)';
};
fields  = {'TTS_warning', 'TTS_critical', 'Peak_warning', 'Peak_critical'};
edits   = zeros(1, 4);

for i = 1:4
    yPos = 0.83 - (i-1) * 0.19;
    uicontrol('Parent', edFig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.04, yPos + 0.06, 0.60, 0.08], ...
        'String', labels{i,1}, 'ForegroundColor', 'w', ...
        'BackgroundColor', [0.13 0.13 0.18], 'FontSize', 9, ...
        'HorizontalAlignment', 'left');
    uicontrol('Parent', edFig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.04, yPos- 0.01, 0.92, 0.07], ...
        'String', labels{i,2}, 'ForegroundColor', [0.55 0.75 0.95], ...
        'BackgroundColor', [0.13 0.13 0.18], 'FontSize', 7.5, ...
        'HorizontalAlignment', 'left');
    edits(i) = uicontrol('Parent', edFig, 'Style', 'edit', 'Units', 'normalized', ...
        'Position', [0.66, yPos + 0.04, 0.28, 0.10], ...
        'String', num2str(cfg.(fields{i})), ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.22 0.26 0.35], 'ForegroundColor', 'w', ...
        'HorizontalAlignment', 'center');
end

uicontrol('Parent', edFig, 'Style', 'pushbutton', 'Units', 'normalized', ...
    'Position', [0.15, 0.04, 0.70, 0.10], ...
    'String', '✓ 保存并重新计算', 'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2 0.55 0.35], 'ForegroundColor', 'w', ...
    'Callback', @(~,~) saveAndRerun(mainFig, edFig, resFig, edits, fields));
end

function saveAndRerun(mainFig, edFig, resFig, edits, fields)
newCfg = struct();
for i = 1:4
    val = str2double(get(edits(i), 'String'));
    if isnan(val) || val <= 0
        utils_showMessage('阈值必须为正数', 'error'); return;
    end
    newCfg.(fields{i}) = val;
end
% 简单合理性检查
if newCfg.TTS_warning >= newCfg.TTS_critical || newCfg.Peak_warning >= newCfg.Peak_critical
    utils_showMessage('中等风险阈值必须小于严重风险阈值', 'error'); return;
end
setappdata(mainFig, 'hemodynamicThresholds', newCfg);
close(edFig);
if ishandle(resFig), close(resFig); end
analysis_computePressureDrop();  % 用新阈值重新计算
end
