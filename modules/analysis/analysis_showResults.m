function analysis_showResults(varargin)
% 显示双端狭窄分析完整结果 (适配双端分析架构，2-endpoint 模式)
fig = gcf;
data = guidata(fig);

% 数据完整性检查（兼容双端模式：timeSeriesData 2行）
if isempty(data.timeSeriesData) || size(data.timeSeriesData, 1) < 2
    utils_showMessage('请先完成双端ROI放置、TDC提取和曲线分析', 'error');
    return;
end

if isempty(data.perfusionParams) || length(data.perfusionParams) < 2
    utils_showMessage('请先完成【分析曲线】步骤以获取灌注参数', 'error');
    return;
end

log_updateStatus('正在显示双端分析结果...');

try
    resultFig = figure('Name', 'DSA双端狭窄血流动力学分析结果', ...
        'NumberTitle', 'off', ...
        'Position', [80, 60, 1300, 820], ...
        'Color', [0.12, 0.12, 0.18]);

    roiLabels = {'近端 (Proximal)', '远端 (Distal)'};
    colors = {[1, 0.4, 0.4], [0.4, 0.8, 1]};

    % ——— 子图1：原始双端 TDC 对比 ———
    ax1 = subplot(2, 2, 1);
    set(ax1, 'Color', [0.15, 0.15, 0.2], 'XColor', 'w', 'YColor', 'w');
    t_orig = (0:size(data.timeSeriesData, 2)-1) / data.frameRate;
    hold(ax1, 'on');
    for i = 1:2
        plot(ax1, t_orig, data.timeSeriesData(i,:), ...
            'Color', colors{i}, 'LineWidth', 1.8, 'DisplayName', roiLabels{i});
    end
    xlabel(ax1, '时间 (s)', 'Color', 'w');
    ylabel(ax1, '相对造影剂密度', 'Color', 'w');
    title(ax1, '原始双端 TDC 曲线', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    legend(ax1, 'TextColor', 'w', 'Color', 'none', 'EdgeColor', 'none');
    grid(ax1, 'on'); ax1.GridAlpha = 0.2;
    hold(ax1, 'off');

    % ——— 子图2：高阶插值平滑曲线对比 ———
    ax2 = subplot(2, 2, 2);
    set(ax2, 'Color', [0.15, 0.15, 0.2], 'XColor', 'w', 'YColor', 'w');
    hold(ax2, 'on');
    for i = 1:2
        curve = data.smoothedLobeData(i,:);
        plot(ax2, data.t_highres, curve, ...
            'Color', colors{i}, 'LineWidth', 2.5, 'DisplayName', roiLabels{i});
        [maxVal, maxIdx] = max(curve);
        plot(ax2, data.t_highres(maxIdx), maxVal, 'o', ...
            'MarkerSize', 9, 'MarkerFaceColor', colors{i}, ...
            'MarkerEdgeColor', 'w', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        % 标注 TMAX
        text(ax2, data.t_highres(maxIdx), maxVal * 1.05, ...
            sprintf('TTP=%.2fs', data.t_highres(maxIdx)), ...
            'Color', colors{i}, 'FontSize', 9, 'HorizontalAlignment', 'center');
    end
    xlabel(ax2, '时间 (s)', 'Color', 'w');
    ylabel(ax2, '相对造影剂密度', 'Color', 'w');
    title(ax2, '平滑插值曲线 (PCHIP) 及达峰点', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    legend(ax2, 'TextColor', 'w', 'Color', 'none', 'EdgeColor', 'none');
    grid(ax2, 'on'); ax2.GridAlpha = 0.2;
    hold(ax2, 'off');

    % ——— 子图3：关键参数双端对比柱状图 ———
    ax3 = subplot(2, 2, 3);
    set(ax3, 'Color', [0.15, 0.15, 0.2], 'XColor', 'w', 'YColor', 'w');
    paramLabels = {'TTP (s)', 'MTT (s)', 'TU (s)', 'FWHM (s)'};
    p1 = data.perfusionParams(1);
    p2 = data.perfusionParams(2);
    vals = [p1.TMAX, p1.MTT, p1.TU, p1.FWHM;
            p2.TMAX, p2.MTT, p2.TU, p2.FWHM];
    b = bar(ax3, vals', 'grouped');
    b(1).FaceColor = colors{1}; b(1).DisplayName = roiLabels{1};
    b(2).FaceColor = colors{2}; b(2).DisplayName = roiLabels{2};
    set(ax3, 'XTick', 1:4, 'XTickLabel', paramLabels, 'FontSize', 10);
    ylabel(ax3, '时间 (s)', 'Color', 'w');
    title(ax3, '双端关键灌注参数对比', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    legend(ax3, 'TextColor', 'w', 'Color', 'none', 'EdgeColor', 'none', 'Location', 'northwest');
    grid(ax3, 'on'); ax3.GridAlpha = 0.2;

    % ——— 子图4：TTS + Peak Attenuation 文献阈值双指标展示 ———
    % 替代原 D-HSS 储备指数（自创公式无文献依据，已废弃）
    % 现基于: Yamauchi 2017 (TTS > 3.2s) | Lai et al. (VBI ≥ 2.0)
    ax4 = subplot(2, 2, 4);
    set(ax4, 'Color', [0.15, 0.15, 0.2], 'XColor', 'w', 'YColor', 'w');

    TTS       = max(0, p2.TMAX - p1.TMAX);
    peakRatio = p1.Peak / max(eps, p2.Peak);

    % 绘制 TTS 参考线（上方）
    hold(ax4, 'on');

    % 背景色块：危险区
    fill(ax4, [3.2 5 5 3.2], [0 0 1 1], [0.5 0.1 0.1], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    fill(ax4, [0 3.2 3.2 0], [0 0 1 1], [0.1 0.3 0.1], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % TTS 箭头指示
    if TTS <= 5
        plot(ax4, TTS, 0.5, 'v', 'MarkerSize', 16, 'MarkerFaceColor', [1 0.7 0.2], ...
            'MarkerEdgeColor', 'w', 'LineWidth', 2);
        text(ax4, TTS, 0.62, sprintf('TTS = %.2fs', TTS), ...
            'Color', [1 0.9 0.4], 'FontSize', 10, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');
    end

    % 阈值线
    xline(ax4, 3.2, '--', 'Color', [1 0.4 0.4], 'LineWidth', 2, 'DisplayName', 'Yamauchi 3.2s');
    text(ax4, 3.3, 0.15, '3.2s (Yamauchi 2017)', 'Color', [1 0.5 0.5], 'FontSize', 8);

    set(ax4, 'XLim', [0, 5], 'YLim', [0, 1], 'YTick', []);
    xlabel(ax4, 'TTS — 跨狭窄时延 (s)', 'Color', 'w');

    if TTS >= 3.2
        tts_verdict = '🔴 高风险 | CHS 风险显著升高 (Yamauchi 2017)';
        tColor = [1 0.5 0.5];
    else
        tts_verdict = '🟢 低风险 | TTS 在安全范围内';
        tColor = [0.5 1 0.6];
    end

    if peakRatio >= 2.0
        pa_verdict = sprintf('Peak Attn ×%.2f  🔴 ≥ 2.0× (Lai)', peakRatio);
    else
        pa_verdict = sprintf('Peak Attn ×%.2f  🟢 < 2.0×', peakRatio);
    end

    title(ax4, sprintf('%s\n%s', tts_verdict, pa_verdict), ...
        'Color', tColor, 'FontSize', 10, 'FontWeight', 'bold');
    grid(ax4, 'on'); ax4.GridAlpha = 0.15;
    hold(ax4, 'off');

    % 统一美化背景
    set(resultFig, 'Units', 'normalized');

    log_updateStatus('双端分析结果显示完成');
    tts_lbl = '低风险'; if TTS >= 3.2, tts_lbl = '高风险'; end
    pa_lbl  = '低风险'; if peakRatio >= 2.0, pa_lbl = '高风险'; end
    log_addWorkLog(sprintf('显示结果: TTS=%.2fs [%s] | PeakAttn=×%.2f [%s]', TTS, tts_lbl, peakRatio, pa_lbl));

catch ME
    utils_showMessage('结果显示失败', 'error', ME.message);
    log_updateStatus('结果显示失败');
    log_addWorkLog(sprintf('错误: 结果显示失败 - %s', ME.message));
end
end
