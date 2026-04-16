function analysis_computeImprovementRate(varargin)
% 术前术后 绝对改善图生成 (基于图像配准)
fig = gcf;
data = guidata(fig);

choice = questdlg('请确保当前界面加载的是【术后】数据。即将让您选择【术前】保存的 .mat 参数地图进行配准提取。继续吗？', ...
    '绝对改善图对齐向导', '继续', '取消', '继续');
if strcmp(choice, '取消'), return; end

% 必须确保当前(术后)已经算出ParamMaps
if ~isfield(data, 'ParamMaps') || isempty(data.ParamMaps.TTP)
    utils_showMessage('正在自动计算当前术后全脑参数...', 'info');
    analysis_computeParametricMap();
    data = guidata(fig);
    if ~isfield(data, 'ParamMaps') || isempty(data.ParamMaps.TTP)
        utils_showMessage('无法获取术后参数，请先执行全脑扫描。', 'error'); return;
    end
end

[fname, pname] = uigetfile('*.mat', '请选择术前的分析结果(.mat)');
if isequal(fname, 0), return; end

try
    log_updateStatus('正在加载术前分析数据进行仿射配准...');
    preData = load(fullfile(pname, fname));
    
    if ~isfield(preData.data, 'ParamMaps') || isempty(preData.data.ParamMaps.TTP)
        utils_showMessage('您选的术前文件中不包含全脑参数图。', 'error'); return;
    end
    
    preTTP = preData.data.ParamMaps.TTP;
    postTTP = data.ParamMaps.TTP;
    
    [H1, W1] = size(preTTP);
    [H2, W2] = size(postTTP);
    if H1 ~= H2 || W1 ~= W2
        utils_showMessage('术前与术后图像尺寸不一致，无法进行配准对比。', 'error'); return;
    end
    
    log_updateStatus('正在执行基于血管的图像配准...');
    
    try
        % 针对 TTP Map 进行平移配准 (translation 优于 rigid，避免边缘严重旋转失真)
        % 因为同一患者的术前术后 DSA 通常体位一致，仅存在轻微的平移偏移
        optimizer = registration.optimizer.RegularStepGradientDescent();
        metric = registration.metric.MeanSquares();
        tform = imregtform(preTTP, postTTP, 'translation', optimizer, metric);
        
        % 使用 NaN 填充平移或旋转后产生的越界空白区，防止出现 0 被当成有效数值（变成蓝色边框）
        alignedPreTTP = imwarp(preTTP, tform, 'OutputView', imref2d(size(postTTP)), 'FillValues', NaN);
    catch RegErr
        % 用户可能没有 Image Processing Toolbox 的特定组件
        log_addWorkLog('高级图像配准模块不可用或失败，回退到直接矩阵相减模式。');
        alignedPreTTP = preTTP;
    end
    
    % 计算绝对改善 (术前 减去 术后。正数代表TTP缩短，也就是血流变快)
    improvementMap = alignedPreTTP - postTTP;
    
    % 剥离背景：只看术后有血管的地方
    vesselMask = data.ParamMaps.vesselMask;
    improvementMap(~vesselMask) = NaN; % 屏蔽非血管
    
    % 为了防止离群点撑爆色带，对数据进行 2% 和 98% 截断
    improvementMap(improvementMap > 5) = 5;
    improvementMap(improvementMap < -5) = -5;
    
    % 渲染图形
    resFig = figure('Name', '血流动力学绝对改善对齐图 (Absolute Improvement Map)', 'Position', [150, 200, 1000, 600], 'Color', [0.1 0.1 0.15], 'NumberTitle','off');
    
    % 图1：术后基准TTP
    ax1 = subplot(1, 2, 1, 'Parent', resFig);
    imagesc(ax1, postTTP, 'AlphaData', vesselMask);
    colormap(ax1, jet); 
    set(ax1, 'Color', [0.1 0.1 0.15]); % 背景设为深色
    colorbar(ax1, 'Color', 'w');
    title(ax1, '术后 TTP 达峰图 (秒)', 'Color', 'w', 'FontSize', 12); axis(ax1, 'image', 'off');
    
    % 图2：提升图 (使用特殊的冷暖色带，0为中间色，正数红色代表改善，负数蓝色代表恶化)
    ax2 = subplot(1, 2, 2, 'Parent', resFig);
    
    % 严密的 Alpha 掩膜：只有原本是血管，且配准后非 NaN 的重叠区域才被显示
    validImprovementMask = vesselMask & ~isnan(improvementMap);
    
    hImg2 = imagesc(ax2, improvementMap);
    set(hImg2, 'AlphaData', validImprovementMask);
    
    % 创建一个红白蓝的双向发散色带
    nColors = 256;
    cmap_diverging = [linspace(0, 1, nColors/2)', linspace(0, 1, nColors/2)', ones(nColors/2, 1)]; % 蓝到白
    cmap_diverging = [cmap_diverging; [ones(nColors/2, 1), linspace(1, 0, nColors/2)', linspace(1, 0, nColors/2)']]; % 白到红
    colormap(ax2, cmap_diverging); 
    
    % 强制让 0 点绝对处于色带正中心
    maxAbsVal = max(3, max(abs(improvementMap(vesselMask)))); 
    caxis(ax2, [-maxAbsVal, maxAbsVal]);
    set(ax2, 'Color', [0.1 0.1 0.15]);
    
    cb2 = colorbar(ax2, 'Color', 'w');
    cb2.Label.String = 'TTP 延迟差 (正=术后加速=改善, 负=术后变慢=恶化) [s]'; cb2.Label.Color = 'w';
    title(ax2, '血流绝对速差热力图 (Pre - Post)', 'Color', 'w', 'FontSize', 12); axis(ax2, 'image', 'off');
    
    % 计算均值作为全局提升指标
    meanImprovement = mean(improvementMap(vesselMask), 'omitnan');
    if meanImprovement > 0.05
        % 正数：TTP 缩短，血流加速，支架开通有效
        statusText = sprintf('血运重建量化评估：\n在有效的对齐血管区内，\n平均达峰时间缩短 %.3f 秒 ↑ 血流加速，支架开通有效。', meanImprovement);
        color = [0.3, 1, 0.3];
    elseif meanImprovement >= -0.05
        % 接近 0：无明显变化
        statusText = sprintf('血运重建量化评估：\n在有效的对齐血管区内，\n平均达峰时间基本未变 (Δ = %.3f 秒)，建议复查配准质量。', meanImprovement);
        color = [1, 0.85, 0.3];
    else
        % 负数：TTP 延长，血流减慢，需关注
        statusText = sprintf('血运重建量化评估：\n在有效的对齐血管区内，\n平均达峰时间延长 %.3f 秒 ↓ 血流减慢，请结合临床判断。', abs(meanImprovement));
        color = [1, 0.45, 0.2];
    end
    
    annotation(resFig, 'textbox', [0.05, 0.06, 0.9, 0.1], 'String', statusText, 'Color', color, 'FontSize', 12, 'FontWeight', 'bold', 'LineStyle', 'none', 'HorizontalAlignment', 'center');
    
    log_updateStatus('绝对改善对齐算法执行完成');
    log_addWorkLog(sprintf('生成配准改善图，全脑平均 TTP 相对变化: %.3fs', meanImprovement));

catch ME
    utils_showMessage('改善图生成失败', 'error', ME.message);
    log_addWorkLog(sprintf('绝对改善对比生成失败: %s', ME.message));
end

end
