function ax = visual_plotRadar(parentPanel, results)
% visual_plotRadar  绘制 5 维血流动力学雷达图
% 输入:
%   parentPanel - 绘图所在的 uipanel 或 figure
%   results     - analysis_computeComparison 返回的结果结构体
% 输出:
%   ax - 坐标系句柄

    if isempty(parentPanel)
        f = figure('Name', '高维血流动力学特征 - 雷达图', 'Color', 'w');
        ax = axes(f);
    else
        ax = axes(parentPanel);
    end

    % 提取五维特征并做归一化 [0, 1] 区间以便雷达图展示
    % 参数1: TMAX 同步率 (预期提前, 所以取负)
    val_TMAX = min(1, max(0, -results.TMAX_Shift) / 2.0); 
    % 参数2: Peak 恢复度
    val_Peak = min(1, max(0, results.Peak_Increase_Ratio) / 150.0);
    % 参数3: D-HSS 压降恢复指数 (Delay Reduction)
    val_DHSS = min(1, max(0, results.Delay_Reduction) / 2.0);
    % 参数4: AUC 提升
    val_AUC  = min(1, max(0, results.AUC_Increase_Ratio) / 100.0);
    % 参数5: MTT 正常化
    val_MTT  = min(1, max(0, results.MTT_Improvement) / 50.0);
    
    data = [val_TMAX, val_Peak, val_DHSS, val_AUC, val_MTT];
    labels = {'TMAX 同步', 'Peak 恢复', 'D-HSS 压降', 'AUC 提升', 'MTT 正常化'};
    
    N = length(data);
    theta = linspace(0, 2*pi, N+1);
    data_closed = [data, data(1)]; % 闭合多边形
    
    % 决定颜色
    if isfield(results, 'CHS_Risk_Score')
        risk = results.CHS_Risk_Score;
        if risk > 0.75
            colorFill = [0.9 0.2 0.2]; % 红
        elseif risk >= 0.4
            colorFill = [0.9 0.6 0.2]; % 黄
        else
            colorFill = [0.2 0.7 0.3]; % 绿
        end
    else
        colorFill = [0.2 0.6 0.8]; % 默认蓝
    end

    % 纯直角坐标系仿雷达图 (兼容所有 MATLAB 版本)
    ax = axes('Parent', parentPanel);
    hold(ax, 'on');
    axis(ax, 'equal');
    axis(ax, [-1.2 1.2 -1.2 1.2]);
    axis(ax, 'off'); % 隐藏直角坐标刻度
    
    % 画网格线
    for r = [0.2 0.4 0.6 0.8 1.0]
        [gx, gy] = pol2cart(linspace(0, 2*pi, 100), r);
        plot(ax, gx, gy, '-', 'Color', [0.85 0.85 0.85]);
    end
    
    % 画轴线与文字
    for i = 1:N
        [ax_x, ax_y] = pol2cart(theta(i), 1.0);
        plot(ax, [0 ax_x], [0 ax_y], '-', 'Color', [0.7 0.7 0.7]);
        
        [txt_x, txt_y] = pol2cart(theta(i), 1.15);
        text(ax, txt_x, txt_y, labels{i}, 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    end
    
    % 画数据多边形
    [dx, dy] = pol2cart(theta, data_closed);
    fill(ax, dx, dy, colorFill, 'FaceAlpha', 0.4, 'EdgeColor', colorFill, 'LineWidth', 2);
    
    title(ax, '血流动力学多维恢复特征', 'FontSize', 12, 'FontWeight', 'bold');
    hold(ax, 'off');
    
end
