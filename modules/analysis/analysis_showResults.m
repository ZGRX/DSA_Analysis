function analysis_showResults(varargin)
    fig = gcf;
    data = guidata(fig);
    if isempty(data.smoothedLobeData)
        utils_showMessage('请先分析数据', 'error');
        return;
    end
    log_updateStatus('正在显示分析结果...');
    try
        resultFig = figure('Name', 'DSA灌注分析完整结果', 'NumberTitle', 'off', 'Position', [100, 50, 1400, 900], 'Color', [0.95 0.95 0.95]);
        colors = lines(4);
        subplot(2, 2, 1); hold on;
        lobeAvgData = zeros(4, size(data.timeSeriesData, 2));
        for lobe = 1:4, lobe_indices = (lobe-1)*3+1:lobe*3; lobeAvgData(lobe, :) = mean(data.timeSeriesData(lobe_indices, :), 1); end
        t_original = (0:size(data.timeSeriesData, 2)-1) / data.frameRate;
        for lobe = 1:4
            plot(t_original, lobeAvgData(lobe, :), 'Color', colors(lobe, :), 'LineWidth', 2, 'DisplayName', data.lobeNames{lobe});
        end
        xlabel('时间 (秒)'); ylabel('灰度值'); title('原始脑叶TDC曲线'); grid on; legend('show'); hold off;
        subplot(2, 2, 2); hold on;
        for lobe = 1:4
            plot(data.t_highres, data.smoothedLobeData(lobe, :), 'Color', colors(lobe, :), 'LineWidth', 3, 'DisplayName', sprintf('%s (平滑后)', data.lobeNames{lobe}));
            [maxVal, maxIdx] = max(data.smoothedLobeData(lobe, :));
            plot(data.t_highres(maxIdx), maxVal, 'o', 'MarkerSize', 8, 'MarkerFaceColor', colors(lobe, :), 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        end
        xlabel('时间 (秒)'); ylabel('灰度值'); title('平滑后脑叶TDC曲线（三阶Hermite插值）'); grid on; legend('show'); hold off;
        subplot(2, 2, 3);
        paramNames = {'TMAX', 'MTT', 'TU', 'TD', 'AUC'}; paramValues = zeros(4, 5);
        for i = 1:4
            paramValues(i, 1) = data.perfusionParams(i).TMAX;
            paramValues(i, 2) = data.perfusionParams(i).MTT;
            paramValues(i, 3) = data.perfusionParams(i).TU;
            paramValues(i, 4) = data.perfusionParams(i).TD;
            paramValues(i, 5) = data.perfusionParams(i).AUC / 1000;
        end
        bar(paramValues, 'grouped'); colormap(jet(5)); set(gca, 'XTick', 1:4, 'XTickLabel', data.lobeNames); ylabel('参数值'); title('脑叶灌注参数详细对比'); legend(paramNames, 'Location', 'northoutside', 'Orientation', 'horizontal'); grid on;
        subplot(2, 2, 4);
        tmaxValues = [data.perfusionParams.TMAX]; mttValues = [data.perfusionParams.MTT];
        scatter(tmaxValues, mttValues, 100, 'filled', 'MarkerFaceColor', [0.2 0.6 0.8]); hold on;
        for i = 1:4, text(tmaxValues(i), mttValues(i), data.lobeNames{i}, 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom'); end
        p = polyfit(tmaxValues, mttValues, 1); xFit = linspace(min(tmaxValues), max(tmaxValues), 100); yFit = polyval(p, xFit); plot(xFit, yFit, 'r-', 'LineWidth', 2);
        correlation = corrcoef(tmaxValues, mttValues); rValue = correlation(1, 2);
        xlabel('TMAX (s)'); ylabel('MTT (s)'); title(sprintf('TMAX vs MTT 相关性 (r = %.3f)', rValue)); grid on; hold off;
        set(resultFig, 'Units', 'normalized'); set(resultFig, 'Position', [0.05, 0.05, 0.9, 0.85]);
        log_updateStatus('分析结果显示完成'); log_addWorkLog('显示分析结果图表完成');
    catch ME
        utils_showMessage('结果显示失败', 'error', ME.message); log_updateStatus('结果显示失败'); log_addWorkLog(sprintf('错误: 结果显示失败 - %s', ME.message));
    end
end
