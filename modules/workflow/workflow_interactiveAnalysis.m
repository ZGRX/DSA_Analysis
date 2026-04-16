function workflow_interactiveAnalysis(mainFig)
% WORKFLOW_INTERACTIVEANALYSIS 交互式精细分析
% 医生在参数图上点击任意区域 → 实时显示该点TDC曲线 → 自动分类
%
% 功能：
%   1. 在TTP参数图上启用鼠标点击事件
%   2. 实时提取该点的TDC曲线（零延迟查询缓存）
%   3. 自动分类：正常/半暗带/核心梗死
%   4. 弹出分析窗口

if nargin < 1
    mainFig = gcf;
end

fig = mainFig;
data = guidata(fig);

log_updateStatus('【第二阶段】启用交互式分析...');

try
    % ======= 检查前置条件 =======
    TTP_map = getappdata(fig, 'TTP_map');
    AUC_map = getappdata(fig, 'AUC_map');
    
    if isempty(TTP_map) || isempty(AUC_map)
        utils_showMessage('缺少前置数据', 'warn', '请先执行"一键诊断"');
        return;
    end
    
    % ======= 获取或创建全脑TDC缓存 =======
    fullTDC_data = getappdata(fig, 'fullTDC_cached');
    
    if isempty(fullTDC_data)
        log_addWorkLog('首次提取全脑TDC矩阵用于交互分析');
        log_updateStatus('正在缓存全脑TDC数据...');
        
        imgSeq = data.processedSeries;
        [H, W, nFrames] = size(imgSeq);
        
        fullTDC_data = zeros(H*W, nFrames, 'double');
        for f = 1:nFrames
            frame = double(imgSeq(:,:,f));
            fullTDC_data(:, f) = frame(:);
        end
        
        setappdata(fig, 'fullTDC_cached', fullTDC_data);
    end
    
    % ======= 创建交互窗口 =======
    [H, W] = size(TTP_map);
    baseImg = getappdata(fig, 'currentFrameDisplay');
    if isempty(baseImg)
        if ~isempty(data.processedSeries)
            baseImg = data.processedSeries(:,:,data.currentFrame);
        else
            baseImg = zeros(H, W);
        end
    end
    
    % 提取参数图中位数用于诊断阈值
    TTP_median = median(TTP_map(TTP_map > 0));
    AUC_median = median(AUC_map(AUC_map > 0));
    
    % 创建交互分析窗口
    interactFig = figure('Name', '【交互式分析】点击图像查看详细参数', ...
        'NumberTitle', 'off', ...
        'Position', [100, 100, 1400, 800], ...
        'Color', [0.95, 0.95, 0.95], ...
        'MenuBar', 'figure', 'ToolBar', 'figure');
    
    % ========== 左侧：参数地图（可点击） ==========
    ax_main = axes('Parent', interactFig, 'Position', [0.05, 0.1, 0.5, 0.85]);
    
    imagesc(TTP_map, 'Parent', ax_main);
    colormap(ax_main, hot);
    axis(ax_main, 'image');
    
    title(ax_main, 'TTP 参数图（点击任意点查看详细信息）', ...
        'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
    
    cb = colorbar(ax_main, 'Location', 'southoutside');
    cb.Label.String = 'TTP (秒)';
    
    % ========== 右侧上：TDC曲线显示区 ==========
    ax_tdc = axes('Parent', interactFig, 'Position', [0.58, 0.52, 0.38, 0.38]);
    set(ax_tdc, 'Color', [0.98, 0.98, 0.98]);
    
    text(ax_tdc, 0.5, 0.5, '请点击左侧图像选择分析点', ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', 14, ...
        'Color', [0.5, 0.5, 0.5]);
    axis(ax_tdc, 'off');
    
    % ========== 右侧下：参数显示区 ==========
    ax_info = axes('Parent', interactFig, 'Position', [0.58, 0.05, 0.38, 0.42]);
    axis(ax_info, 'off');
    
    % 保存UI组件到appdata供回调使用
    setappdata(interactFig, 'ax_tdc', ax_tdc);
    setappdata(interactFig, 'ax_info', ax_info);
    setappdata(interactFig, 'TTP_map', TTP_map);
    setappdata(interactFig, 'AUC_map', AUC_map);
    setappdata(interactFig, 'fullTDC_data', fullTDC_data);
    setappdata(interactFig, 'mainFig', fig);
    setappdata(interactFig, 'H', H);
    setappdata(interactFig, 'W', W);
    setappdata(interactFig, 'TTP_median', TTP_median);
    setappdata(interactFig, 'AUC_median', AUC_median);
    
    % 获取帧率
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    if ishandle(frameRateEdit)
        frameRate = str2double(get(frameRateEdit, 'String'));
    else
        frameRate = 4;
    end
    if isnan(frameRate) || frameRate <= 0, frameRate = 4; end
    
    nFrames = size(fullTDC_data, 2);
    setappdata(interactFig, 'frameRate', frameRate);
    setappdata(interactFig, 'nFrames', nFrames);
    
    % ======= 配置鼠标点击事件 =======
    set(interactFig, 'WindowButtonDownFcn', ...
        {@mouseClickCallback, ax_main, interactFig});
    
    log_updateStatus('交互式分析已启用，点击图像开始分析');
    log_addWorkLog('交互式分析窗口已打开，等待用户点击');
    
catch ME
    log_updateStatus('交互式分析启用失败');
    log_addWorkLog(sprintf('错误: %s', ME.message));
    rethrow(ME);
end

end

% ======================================================================
% 鼠标点击回调函数
% ======================================================================

function mouseClickCallback(figHandle, ~, ax_main, interactFig)
% 处理图像上的鼠标点击事件

try
    % 获取点击位置
    currentPoint = get(ax_main, 'CurrentPoint');
    x_click = round(currentPoint(1, 1));
    y_click = round(currentPoint(1, 2));
    
    % 获取数据
    TTP_map = getappdata(interactFig, 'TTP_map');
    AUC_map = getappdata(interactFig, 'AUC_map');
    fullTDC_data = getappdata(interactFig, 'fullTDC_data');
    H = getappdata(interactFig, 'H');
    W = getappdata(interactFig, 'W');
    frameRate = getappdata(interactFig, 'frameRate');
    nFrames = getappdata(interactFig, 'nFrames');
    TTP_median = getappdata(interactFig, 'TTP_median');
    AUC_median = getappdata(interactFig, 'AUC_median');
    ax_tdc = getappdata(interactFig, 'ax_tdc');
    ax_info = getappdata(interactFig, 'ax_info');
    
    % ======= 边界检查 =======
    if x_click < 1 || x_click > W || y_click < 1 || y_click > H
        return;  % 点击在图像外
    end
    
    % ======= 提取点击位置的数据 =======
    TTP_value = TTP_map(y_click, x_click);
    AUC_value = AUC_map(y_click, x_click);
    
    % 获取TDC曲线（从缓存）
    pixel_idx = sub2ind([H, W], y_click, x_click);
    TDC_curve = fullTDC_data(pixel_idx, :);
    
    % 计算时间轴
    t = (0:nFrames-1) / frameRate;
    
    % ======= 自动分类：正常/半暗带/核心 =======
    % 基于TTP和AUC进行分类
    TTP_threshold = TTP_median * 1.5;      % TTP延迟阈值
    AUC_low_threshold = AUC_median * 0.6;  % AUC低阈值
    AUC_normal_threshold = AUC_median * 0.8;  % AUC正常阈值
    
    if TTP_value <= TTP_threshold
        classification = '正常';
        classColor = [0.2, 0.8, 0.2];  % 绿色
    elseif AUC_value >= AUC_normal_threshold
        classification = '缺血半暗带（可救治）';
        classColor = [1, 0.8, 0.2];  % 黄色
    elseif AUC_value >= AUC_low_threshold
        classification = '半暗带进展中（高风险）';
        classColor = [1, 0.5, 0.2];  % 橙色
    else
        classification = '梗死核心（不可逆转）';
        classColor = [1, 0.2, 0.2];  % 红色
    end
    
    % ======= 在左侧图上标记点击位置 =======
    hold(ax_main, 'on');
    
    % 清除之前的标记
    oldMarks = findobj(ax_main, 'Tag', 'clickMark');
    if ~isempty(oldMarks)
        delete(oldMarks);
    end
    
    % 绘制新标记
    plot(ax_main, x_click, y_click, 'o', 'Color', classColor, ...
        'LineWidth', 3, 'MarkerSize', 15, 'Tag', 'clickMark');
    plot(ax_main, x_click, y_click, 'w+', 'LineWidth', 2, ...
        'MarkerSize', 12, 'Tag', 'clickMark');
    
    hold(ax_main, 'off');
    
    % ======= 绘制TDC曲线 =======
    cla(ax_tdc);
    
    plot(ax_tdc, t, TDC_curve, 'LineWidth', 2.5, 'Color', classColor);
    grid(ax_tdc, 'on', 'alpha', 0.3);
    xlabel(ax_tdc, '时间 (秒)', 'FontSize', 10, 'FontWeight', 'bold');
    ylabel(ax_tdc, '信号强度', 'FontSize', 10, 'FontWeight', 'bold');
    title(ax_tdc, sprintf('点击位置 (%.0f, %.0f) 的 TDC 曲线', x_click, y_click), ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', classColor);
    
    set(ax_tdc, 'Color', [0.98, 0.98, 0.98]);
    
    % ======= 显示参数信息 =======
    cla(ax_info);
    axis(ax_info, 'off');
    
    % 计算额外参数
    AUC_point = trapz(t, TDC_curve);
    if AUC_point > 0
        MTT_point = trapz(t, t .* TDC_curve) / AUC_point;
    else
        MTT_point = 0;
    end
    
    % 计算CBF（脑血流）相对值
    CBF_relative = (AUC_value / AUC_median) * 100;
    
    infoStr = sprintf(['【交互式分析结果】\n' ...
                      '\n' ...
                      '━━ 位置信息 ━━\n' ...
                      'X坐标: %.0f px\n' ...
                      'Y坐标: %.0f px\n' ...
                      '\n' ...
                      '━━ 灌注参数 ━━\n' ...
                      'TTP:  %.2f 秒\n' ...
                      '      (阈值: %.2f)\n' ...
                      'AUC:  %.0f\n' ...
                      '      (正常值: %.0f)\n' ...
                      'MTT:  %.2f 秒\n' ...
                      'CBF:  %.1f%% (相对)\n' ...
                      '\n' ...
                      '━━ 诊断分类 ━━\n' ...
                      '%s\n' ...
                      '\n' ...
                      '────────────────\n' ...
                      '✓ 执行四象限分层获\n' ...
                      '  得精确诊断建议'], ...
                      x_click, y_click, ...
                      TTP_value, TTP_median * 1.5, ...
                      AUC_value, AUC_median, ...
                      MTT_point, CBF_relative, ...
                      classification);
    
    text(ax_info, 0.05, 0.95, infoStr, ...
        'Units', 'normalized', ...
        'FontName', 'Courier', ...
        'FontSize', 9, ...
        'VerticalAlignment', 'top', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [classColor(1)*0.7+0.3, ...
                           classColor(2)*0.7+0.3, ...
                           classColor(3)*0.7+0.3], ...
        'EdgeColor', classColor, ...
        'LineWidth', 2, ...
        'Margin', 8);
    
    % ======= 记录日志 =======
    log_addWorkLog(sprintf('用户点击: (%d, %d) → 分类: %s (TTP=%.2f, AUC=%.0f)', ...
        x_click, y_click, classification, TTP_value, AUC_value));
    
catch ME
    warning('点击处理错误: %s', ME.message);
end

end
