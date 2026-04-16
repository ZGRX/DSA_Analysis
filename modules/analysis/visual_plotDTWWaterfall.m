function ax = visual_plotDTWWaterfall(parentPanel, results)
% visual_plotDTWWaterfall  绘制 DTW 对齐后的跨狭窄延迟阴影图
%
% 学术说明:
%   真正的 DTW Shadow Volume 是将术前/术后的 Proximal-Distal 两条曲线
%   经过动态时间规整(DTW)对齐到统一时间轴后，再求"残差阴影面积"。
%   该面积代表跨狭窄血流从扭曲形态向正常形态的恢复程度。
%   (Ref: 源自 fMRI/CTP 的 DTW-Based Hemodynamic Delay Quantification)

    if isempty(parentPanel)
        f = figure('Name', '跨狭窄 DTW 阴影对比图', 'Color', [0.12 0.12 0.18]);
        ax = axes(f);
    else
        ax = axes('Parent', parentPanel);
    end

    hold(ax, 'on');
    set(ax, 'Color', [0.15 0.15 0.2], 'XColor', 'w', 'YColor', 'w');
    grid(ax, 'on'); ax.GridAlpha = 0.15;

    if ~isfield(results, 'preCurve') || ~isfield(results, 'postCurve')
        text(ax, 0.5, 0.5, '缺少高保真曲线数据', 'HorizontalAlignment', 'center', 'Color', 'w');
        hold(ax, 'off');
        return;
    end

    % --- 1. 归一化曲线（消除绝对浓度差异，仅比较形态）---
    normCurve = @(c) (c - min(c)) / max(eps, max(c) - min(c));

    pre_prox  = normCurve(results.preCurve(1, :));
    pre_dist  = normCurve(results.preCurve(2, :));
    post_prox = normCurve(results.postCurve(1, :));
    post_dist = normCurve(results.postCurve(2, :));

    t_pre  = results.t_highres_pre;
    t_post = results.t_highres_post;

    % --- 2. DTW 对齐: 将远端曲线对齐到近端时间轴 ---
    % 对术前和术后分别执行 DTW，得到对齐后的远端在近端时间轴上的版本
    [pre_dist_aligned,  t_pre]  = dtwAlign(pre_prox,  pre_dist,  t_pre);
    [post_dist_aligned, t_post] = dtwAlign(post_prox, post_dist, t_post);

    % --- 3. 绘制 DTW 对齐阴影面积 ---
    % 术前阴影：在对齐后的近端与远端曲线之间着色（灰色 = 延迟/扭曲残存）
    x_pre  = [t_pre,  fliplr(t_pre)];
    y_pre  = [pre_prox, fliplr(pre_dist_aligned)];
    fill(ax, x_pre, y_pre, [0.7 0.7 0.7], 'FaceAlpha', 0.45, ...
        'EdgeColor', 'none', 'DisplayName', '术前 DTW 延迟阴影');

    % 术后阴影：阴影明显缩小代表压降恢复（蓝绿色 = 血运重建成效）
    x_post = [t_post, fliplr(t_post)];
    y_post = [post_prox, fliplr(post_dist_aligned)];
    fill(ax, x_post, y_post, [0.2 0.6 0.85], 'FaceAlpha', 0.5, ...
        'EdgeColor', 'none', 'DisplayName', '术后 DTW 压降演变');

    % --- 4. 绘制原始曲线边界 ---
    plot(ax, t_pre,  pre_prox,  '--', 'Color', [0.75 0.75 0.75], 'LineWidth', 1.2, 'DisplayName', '术前 近端');
    plot(ax, t_pre,  pre_dist_aligned,  '-',  'Color', [0.5  0.5  0.5 ], 'LineWidth', 1.5, 'DisplayName', '术前 远端(DTW)');
    plot(ax, t_post, post_prox, '--', 'Color', [0.4  0.8  1.0 ], 'LineWidth', 1.5, 'DisplayName', '术后 近端');
    plot(ax, t_post, post_dist_aligned, '-',  'Color', [0.1  0.4  0.9 ], 'LineWidth', 2.0, 'DisplayName', '术后 远端(DTW)');

    % --- 5. 计算并标注阴影面积差（量化改善程度）---
    area_pre  = trapz(t_pre,  abs(pre_prox  - pre_dist_aligned));
    area_post = trapz(t_post, abs(post_prox - post_dist_aligned));
    improvement_pct = (area_pre - area_post) / max(eps, area_pre) * 100;

    annotation_str = sprintf('延迟面积改善: %.1f%%\n术前: %.4f  →  术后: %.4f', ...
        improvement_pct, area_pre, area_post);
    text(ax, 0.02, 0.95, annotation_str, 'Units', 'normalized', ...
        'Color', [1 0.9 0.4], 'FontSize', 10, 'FontWeight', 'bold', ...
        'VerticalAlignment', 'top');

    xlabel(ax, '时间 (s)', 'Color', 'w', 'FontWeight', 'bold');
    ylabel(ax, '归一化造影剂浓度', 'Color', 'w', 'FontWeight', 'bold');
    title(ax, '跨狭窄血流时序延迟修复图 (DTW Shadow Volume)', ...
        'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    legend(ax, 'TextColor', 'w', 'Color', 'none', 'EdgeColor', [0.4 0.4 0.4], ...
        'Location', 'northeast', 'FontSize', 8);

    hold(ax, 'off');
end

%% ---- 内部辅助函数：DTW对齐 ----
function [dist_aligned, t_ref] = dtwAlign(ref_curve, dist_curve, t_ref)
% 将 dist_curve 按 DTW 路径重采样到 ref_curve 的时间轴长度

    n = length(ref_curve);
    m = length(dist_curve);

    % 计算 DTW 累积代价矩阵
    D = inf(n+1, m+1);
    D(1,1) = 0;
    for i = 1:n
        for j = 1:m
            cost = abs(ref_curve(i) - dist_curve(j));
            D(i+1, j+1) = cost + min([D(i,j+1), D(i+1,j), D(i,j)]);
        end
    end

    % 回溯对齐路径
    i = n; j = m;
    pathI = zeros(n+m, 1);
    pathJ = zeros(n+m, 1);
    k = 0;
    while i > 0 && j > 0
        k = k + 1;
        pathI(k) = i; pathJ(k) = j;
        if i == 1
            j = j - 1;
        elseif j == 1
            i = i - 1;
        else
            [~, idx] = min([D(i,j+1), D(i+1,j), D(i,j)]);
            if idx == 1, i = i-1;
            elseif idx == 2, j = j-1;
            else, i = i-1; j = j-1;
            end
        end
    end
    pathI = pathI(1:k);
    pathJ = pathJ(1:k);

    % 按照对齐路径，将 dist 重采样到 ref 的时间轴
    % 对每个 ref 时间点 i，取所有匹配到它的 dist_j 的均值
    dist_aligned = zeros(1, n);
    for i = 1:n
        matched_j = pathJ(pathI == i);
        if ~isempty(matched_j)
            dist_aligned(i) = mean(dist_curve(matched_j));
        else
            dist_aligned(i) = dist_curve(min(round(i * m / n), m));
        end
    end
end
