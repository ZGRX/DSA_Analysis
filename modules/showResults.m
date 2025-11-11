function showResults(~, ~)
    % showResults - 显示完整分析结果
    %
    % 功能：
    %   1. 显示原始TDC曲线
    %   2. 显示平滑后TDC曲线
    %   3. 显示参数对比柱状图
    %   4. 显示TMAX与MTT相关性散点图
    %
    % 输入：
    %   无（从guidata获取数据）
    %
    % 输出：
    %   无（显示图形窗口）
    
    fig = gcf;
    data = guidata(fig);
    
    % 验证数据
    if isempty(data.smoothedLobeData)
        errordlg('请先分析数据', '错误');
        return;
    end
    
    updateStatus('正在显示分析结果...');
    
    try
        % 创建结果窗口
        resultFig = figure('Name', 'DSA灌注分析完整结果', ...
                          'NumberTitle', 'off', ...
                          'Position', [100, 50, 1400, 900], ...
                          'Color', [0.95 0.95 0.95]);
        
        % 颜色方案
        colors = lines(4);
        
        % ===== 子图1：原始TDC曲线 =====
        subplot(2, 2, 1);
        hold on;
        
        % 计算每个脑叶的平均TDC
        lobeAvgData = zeros(4, size(data.timeSeriesData, 2));
        for lobe = 1:4
            lobe_indices = (lobe-1)*3+1:lobe*3;
            lobeAvgData(lobe, :) = mean(data.timeSeriesData(lobe_indices, :), 1);
        end
        
        % 原始时间轴
        t_original = (0:size(data.timeSeriesData, 2)-1) / data.frameRate;
        
        % 绘制原始曲线
        for lobe = 1:4
            plot(t_original, lobeAvgData(lobe, :), ...
                'Color', colors(lobe, :), 'LineWidth', 2, ...
                'DisplayName', data.lobeNames{lobe});
        end
        
        xlabel('时间 (秒)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('灰度值', 'FontSize', 12, 'FontWeight', 'bold');
        title('原始脑叶TDC曲线', 'FontSize', 14, 'FontWeight', 'bold');
        grid on;
        legend('show', 'Location', 'best');
        set(gca, 'FontSize', 11);
        hold off;
        
        % ===== 子图2：平滑后TDC曲线 =====
        subplot(2, 2, 2);
        hold on;
        
        % 绘制平滑曲线并标注峰值
        for lobe = 1:4
            plot(data.t_highres, data.smoothedLobeData(lobe, :), ...
                'Color', colors(lobe, :), 'LineWidth', 3, ...
                'DisplayName', sprintf('%s (平滑后)', data.lobeNames{lobe}));
            
            % 标注峰值点
            [maxVal, maxIdx] = max(data.smoothedLobeData(lobe, :));
            plot(data.t_highres(maxIdx), maxVal, 'o', ...
                'MarkerSize', 8, 'MarkerFaceColor', colors(lobe, :), ...
                'MarkerEdgeColor', 'k', 'LineWidth', 1.5, ...
                'HandleVisibility', 'off');
        end
        
        xlabel('时间 (秒)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('灰度值', 'FontSize', 12, 'FontWeight', 'bold');
        title('平滑后脑叶TDC曲线（三阶Hermite插值）', 'FontSize', 14, 'FontWeight', 'bold');
        grid on;
        legend('show', 'Location', 'best');
        set(gca, 'FontSize', 11);
        hold off;
        
        % ===== 子图3：参数对比柱状图 =====
        subplot(2, 2, 3);
        
        % 提取关键参数
        paramNames = {'TMAX', 'MTT', 'TU', 'TD', 'AUC'};
        paramValues = zeros(4, 5);
        
        for i = 1:4
            paramValues(i, 1) = data.perfusionParams(i).TMAX;
            paramValues(i, 2) = data.perfusionParams(i).MTT;
            paramValues(i, 3) = data.perfusionParams(i).TU;
            paramValues(i, 4) = data.perfusionParams(i).TD;
            paramValues(i, 5) = data.perfusionParams(i).AUC / 1000; % 缩放便于显示
        end
        
        % 绘制分组柱状图
        barHandle = bar(paramValues, 'grouped');
        colormap(jet(5));
        
        set(gca, 'XTick', 1:4, 'XTickLabel', data.lobeNames, 'FontSize', 11);
        ylabel('参数值', 'FontSize', 12, 'FontWeight', 'bold');
        title('脑叶灌注参数详细对比', 'FontSize', 14, 'FontWeight', 'bold');
        legend(paramNames, 'Location', 'northoutside', 'Orientation', 'horizontal');
        grid on;
        set(gca, 'FontSize', 10, 'FontWeight', 'bold');
        
        % ===== 子图4：TMAX与MTT相关性 =====
        subplot(2, 2, 4);
        
        % 提取TMAX和MTT值
        tmaxValues = [data.perfusionParams.TMAX];
        mttValues = [data.perfusionParams.MTT];
        
        % 绘制散点图
        scatter(tmaxValues, mttValues, 100, 'filled', 'MarkerFaceColor', [0.2 0.6 0.8]);
        hold on;
        
        % 添加脑叶标签
        for i = 1:4
            text(tmaxValues(i), mttValues(i), data.lobeNames{i}, ...
                'FontSize', 12, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
        end
        
        % 线性拟合
        p = polyfit(tmaxValues, mttValues, 1);
        xFit = linspace(min(tmaxValues), max(tmaxValues), 100);
        yFit = polyval(p, xFit);
        plot(xFit, yFit, 'r-', 'LineWidth', 2);
        
        % 计算相关系数
        correlation = corrcoef(tmaxValues, mttValues);
        rValue = correlation(1, 2);
        
        xlabel('TMAX (s)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('MTT (s)', 'FontSize', 12, 'FontWeight', 'bold');
        title(sprintf('TMAX vs MTT 相关性 (r = %.3f)', rValue), 'FontSize', 14, 'FontWeight', 'bold');
        grid on;
        set(gca, 'FontSize', 11);
        hold off;
        
        % 调整窗口大小
        set(resultFig, 'Units', 'normalized');
        set(resultFig, 'Position', [0.05, 0.05, 0.9, 0.85]);
        
        % 更新状态
        updateStatus('分析结果显示完成');
        addWorkLog('显示分析结果图表完成');
        
    catch ME
        errordlg(sprintf('结果显示失败: %s', ME.message), '错误');
        updateStatus('结果显示失败');
        addWorkLog(sprintf('错误: 结果显示失败 - %s', ME.message));
    end
end
