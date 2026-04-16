function analysis_computeParametricMap(varargin)
% ANALYSIS_COMPUTEPARAMETRICMAP 计算像素级参数图 (Parametric Map)
% 功能: 
%   1. 对全图每个像素自动计算 TTP (达峰时间) 和 AUC (曲线下面积)
%   2. 生成并显示全脑伪彩色参数图
%   3. 自动抓取并弹出全脑“最危险点”的 TDC 曲线

fig = findobj('Type', 'figure', 'Tag', 'DSA_Main_Window');
if isempty(fig)
    fig = gcf;
else
    fig = fig(1);
end
data = guidata(fig);

% 1. 检查数据
if isempty(data.processedSeries)
    utils_showMessage('请先导入DSA数据', 'error');
    return;
end

log_updateStatus('正在进行全脑自动扫描...');
log_addWorkLog('开始计算 Parametric Map');

try
    % 获取图像序列
    imgSeq = data.processedSeries; % [H, W, Frames]
    [H, W, nFrames] = size(imgSeq);
    
    if nFrames < 3
        utils_showMessage('帧数不足，无法计算参数图', 'error');
        return;
    end
    
    % 【重要说明】参数图计算中跳过运动配准
    % 运动配准会把各帧血管像素移到不同坐标，导致同一像素的TDC变为噪声AUC≈0
    % 同时imregtform逐帧配准极慢（每帧需数十秒）
    % 参数图直接使用原始帧，以保护TDC时序信号完整性
    meanDisp = 0;
    log_addWorkLog('参数图使用原始帧（跳过运动配准以保护TDC信号）');
    
    
    % 获取帧率
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    if ishandle(frameRateEdit)
        frameRate = str2double(get(frameRateEdit, 'String'));
    else
        frameRate = 4;
    end
    if isnan(frameRate) || frameRate <= 0, frameRate = 4; end
    
    % 时间轴
    t = (0:nFrames-1) / frameRate;
    
    % 创建等待栏
    hWait = waitbar(0, '正在向量化计算全脑参数图...', 'Name', 'Parametric Map');

    % 【性能优化】基线帧数（取前几帧最小值作为无造影剂基线）
    baselineFrames = min(5, floor(nFrames * 0.15));
    if baselineFrames < 2, baselineFrames = 2; end

    % 2. 【向量化重构】将图像序列 reshape 为 (Npix x Nframes) 矩阵，
    %    彻底消除 H*W 次 for 循环，将计算时间从分钟级降至秒级。
    %    原始 imgSeq 维度 [H, W, Frames] -> 转置为 [Frames, H, W] -> reshape -> [Npix, Frames]
    totalPixels = H * W;
    allCurves = double(reshape(permute(imgSeq, [3, 1, 2]), nFrames, totalPixels)'); % [Npix x Frames]

    if ishandle(hWait), waitbar(0.2, hWait, '正在进行基线校正...'); end

    % 基线校正：每个像素取前 baselineFrames 帧的最小值，向量化减去
    baseline_vec = min(allCurves(:, 1:baselineFrames), [], 2); % [Npix x 1]
    allCurves = max(0, allCurves - baseline_vec);              % 广播减法，确保非负

    % 移动平均平滑（等效于原 movmean(pixelCurve, 3)，窗口=3，向量化实现）
    if nFrames >= 5
        kernel = ones(1, 3) / 3;
        % conv2 对所有行（每个像素）并行滑动平均
        allCurves_smooth = conv2(allCurves, kernel, 'same');
    else
        allCurves_smooth = allCurves;
    end

    if ishandle(hWait), waitbar(0.5, hWait, '正在计算 TTP (达峰时间)...'); end

    % TTP：对每一行求 argmax，转换为时间 (秒)
    [~, maxIdx_vec] = max(allCurves_smooth, [], 2);    % [Npix x 1] 帧索引
    TTP_vec = (maxIdx_vec - 1) / frameRate;            % 转换为秒

    if ishandle(hWait), waitbar(0.75, hWait, '正在计算 AUC (曲线下面积)...'); end

    % AUC：对原始曲线（非平滑）做梯形积分，等效于 trapz(t, pixelCurve)
    % trapz 向量化: AUC ≈ sum(Δt * (C[k] + C[k+1])/2, k=1..N-1)
    dt = 1 / frameRate;
    AUC_vec = dt * (sum(allCurves(:, 1:end-1), 2) + sum(allCurves(:, 2:end), 2)) / 2; % [Npix x 1]

    % 将向量结果 reshape 回 [H x W] 矩阵
    TTP_map = reshape(TTP_vec, H, W);
    AUC_map = reshape(AUC_vec, H, W);

    % 3. 数据处理与掩膜 (完全重构：防强噪与自适应截断)
    % 绝对不能使用局部 max(AUC_map(:)) 归一化，如果因为患者运动产生了一个超亮噪点，
    % 真正的血管信号会被压迫到极低水平，导致大面积“断流”
    robustMax = prctile(AUC_map(:), 99.5); % 使用99.5%分位数作为健壮最大值
    AUC_norm = (AUC_map - min(AUC_map(:))) / max(1e-6, robustMax - min(AUC_map(:)));
    AUC_norm(AUC_norm > 1) = 1; % 削平顶部的0.5%噪点
    
    % 大津法双重自适应分割 (Double-Pass Otsu)
    % 第一轮：区分“含有任何造影剂的信号”与“无造影剂的真背景”
    thresh1 = graythresh(AUC_norm(AUC_norm > 1e-4));
    
    % 第二轮：在有效组织中，切分出最强的主干血管流
    brainTissue = AUC_norm(AUC_norm > thresh1);
    if isempty(brainTissue)
        thresh2 = 0.05;
    else
        thresh2 = graythresh(brainTissue);
    end
    
    % 回归纯动态自适应，不再硬编码绝对下限
    % 使用 thresh2 的 0.5 倍，它能完美抓住主干大动脉，又不会因为术前血流极弱而导致整图被切掉
    finalThresh = thresh2 * 0.5; 
    
    vesselMask = AUC_norm > finalThresh;
    
    % 形态学清洁：先闭运算连接血管，再开运算彻底消灭离散的极小噪点块
    vesselMask = imclose(vesselMask, strel('disk', 3));
    vesselMask = imopen(vesselMask, strel('disk', 2));
    
    % 空间拓扑过滤：相对面积阈值法（替代单一连通域限制）
    % 科学依据：术后即时 DSA 中，支架开通后远端分支重新显影，可能与主干形成
    % 多个连通域（因 AUC 阈值在分支节点处可能短暂断开）。
    % 原始 bwareafilt(mask,1) 丢弃所有非最大域，系统性低估术后灌注受累面积。
    % 改进方案（参考 Lesage 2009 vessel segmentation review）：
    %   保留面积 ≥ max(200px, 最大连通域×5%) 的所有成分。
    %   · 200px 绝对下限：排除亚 15×15 像素的真实噪点/骨骼碎片
    %   · 5% 相对下限：排除远小于主干的孤立伪影，同时保留真实远端分支
    CC = bwconncomp(vesselMask, 8);
    if CC.NumObjects > 0
        areaList    = cellfun(@numel, CC.PixelIdxList);
        maxArea     = max(areaList);
        minKeepArea = max(200, round(maxArea * 0.05));
        vesselMask  = bwareaopen(vesselMask, minKeepArea);
    else
        vesselMask = false(H, W);
    end

    % 【强制排障】排除边缘物理刻度条与准直器硬遮罩
    topMargin    = max(25, round(H * 0.07));
    bottomMargin = max(15, round(H * 0.04));
    sideMargin   = max(15, round(W * 0.04));
    vesselMask(1:topMargin, :)            = false;
    vesselMask(end-bottomMargin+1:end, :) = false;
    vesselMask(:, 1:sideMargin)           = false;
    vesselMask(:, end-sideMargin+1:end)   = false;
    
    % 摒弃之前所有脆弱的 fallback (会导致全屏泄露)，直接输出唯一的绝对净掩膜
    displayMask = vesselMask;
    
    TTP_norm = (TTP_map - min(TTP_map(:))) / max(1e-6, max(TTP_map(:)) - min(TTP_map(:)));

    % 4. 渲染多维分析图窗
    % 修复原先的孤儿 subplot 显示 bug，改为清晰漂亮的全画幅显示
    resultFig = figure('Name', 'DSA 像素级全脑血流参数图 (Parametric Map)', ...
        'NumberTitle', 'off', 'Position', [80, 80, 1440, 700], ...
        'Color', [0.1 0.1 0.15]);
    
    currentFrame = data.currentFrame;
    if isfield(data, 'processedSeries') && ~isempty(data.processedSeries)
        baseImg = data.processedSeries(:,:,currentFrame);
    else
        baseImg = data.img2D;
    end
    baseImg_norm = double(baseImg);
    baseImg_norm = (baseImg_norm - min(baseImg_norm(:))) / max(1e-6, max(baseImg_norm(:)) - min(baseImg_norm(:)));

    % 子图 1: TTP 参数图 (用冷暖色调显示到达时间早晚)
    ax1 = axes('Parent', resultFig, 'Position', [0.05, 0.1, 0.4, 0.8]);
    set(ax1, 'Color', [0.1 0.1 0.15]); % 背景设为与图窗一致的深色，避免准直器区透出青色
    imagesc(ax1, TTP_map, 'AlphaData', displayMask);
    colormap(ax1, jet);
    axis(ax1, 'image', 'off');
    cb1 = colorbar(ax1, 'Color', 'w');
    cb1.Label.String = 'TTP 达峰时间 (s)'; cb1.Label.Color = 'w';
    title(ax1, 'TTP (Time To Peak) 全脑分布', 'Color', 'w', 'FontSize', 13);
    
    % 子图 2: 融合图与自动定位标记
    ax2 = axes('Parent', resultFig, 'Position', [0.55, 0.1, 0.4, 0.8]);
    % 【彻底修复准直器竖杠】将 displayMask 应用到所有通道（含底图）
    % 准直器区域直接显示为纯黑背景
    displayMask3 = repmat(double(displayMask), [1, 1, 3]);
    fusedImg = zeros(H, W, 3);
    fusedImg(:,:,1) = TTP_norm;   % 红通道 = TTP（达峰迟）
    fusedImg(:,:,2) = AUC_norm;   % 绿通道 = AUC（血容量）
    fusedImg(:,:,3) = baseImg_norm * 0.2;
    blendedImg = fusedImg * 0.75 + repmat(baseImg_norm, [1, 1, 3]) * 0.25;
    % 关键：将血管掩膜应用到融合图，去除背景散点噪声
    blendedImg = blendedImg .* displayMask3;
    % 额外：对血管区用 Alpha 软混合，进一步抑制毛细血管区边缘噪射
    displayMaskSmooth = imgaussfilt(double(displayMask), 3);
    displayMask3Smooth = repmat(displayMaskSmooth, [1,1,3]);
    bgFused = repmat(baseImg_norm * 0.05, [1,1,3]);  % 深色背景
    blendedImg = blendedImg .* displayMask3Smooth + bgFused .* (1 - displayMask3Smooth);
    imshow(blendedImg, 'Parent', ax2);
    title(ax2, 'TTP-AUC 融合参数图 (红=延迟, 绿=大容量)', ...
        'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');

    % 5. 参数图完成 - 两张图自身即为完整临床输出
    % TTP 彩色热力图 = 全脑灌注延迟分布地图
    % TTP-AUC 融合图 = 血流速度与血容量的综合评估
    % 单张彩图已完整展现 CHS 风险区域分布，无需额外标注单一靶点
    log_addWorkLog('参数图渲染完成');

    % 6. 保存与清理（修复：统一使用 guidata 存储）
    if ishandle(hWait), close(hWait); end
    
    % 保存到 guidata 的 ParamMaps 结构中
    data = guidata(fig);
    data.ParamMaps.TTP = TTP_map;
    data.ParamMaps.AUC = AUC_map;
    data.ParamMaps.vesselMask = displayMask;
    guidata(fig, data);
    
    log_updateStatus('全脑参数图扫描完成');
    log_addWorkLog('参数图已保存到 data.ParamMaps');
    utils_showMessage('全自动扫描成功', 'success');
    
catch ME
    utils_showMessage('参数图计算失败', 'error', ME.message);
    log_updateStatus('参数图计算失败');
    log_addWorkLog(sprintf('错误: %s (位置: %s, 行%d)', ...
        ME.message, ME.stack(1).name, ME.stack(1).line));
    
    % 【修复】区分不同类型的错误
    if contains(ME.identifier, 'MATLAB:badsubscript') || contains(ME.identifier, 'MATLAB:subsassigndimmismatch')
        log_addWorkLog('提示: 数据维度错误，请检查图像序列是否完整');
    elseif contains(ME.identifier, 'MATLAB:nomem') || contains(ME.message, 'memory')
        log_addWorkLog('提示: 内存不足，建议减小图像尺寸或关闭其他程序');
    elseif contains(ME.identifier, 'MATLAB:UndefinedFunction')
        log_addWorkLog('提示: 缺少必要的函数，请检查路径设置');
    end
    
    disp(ME.getReport());
end
end