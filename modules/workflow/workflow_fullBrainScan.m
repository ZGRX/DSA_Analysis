function workflow_fullBrainScan(mainFig)
% WORKFLOW_FULLBRAINSCAN 一键全脑诊断的完整自动化流程
%
% 功能：
%   1. 检查数据（如未导入则自动导入）
%   2. 执行全脑参数计算 (TTP/AUC)
%   3. 自动检测Tmax最长的点（最危险点）
%   4. 弹出该点的TDC曲线预览
%   5. 自动触发四象限风险分层
%
% 调用：
%   workflow_fullBrainScan(mainFig)

if nargin < 1
    mainFig = gcf;
end

fig = mainFig;

% 【修复】添加状态机保护，防止并发操作
currentState = getappdata(fig, 'workflowState');
if isempty(currentState)
    % 初始化状态
    UIState.IDLE = 0;
    UIState.SCANNING = 1;
    UIState.ANALYZING = 2;
    UIState.EXPORTING = 3;
    setappdata(fig, 'UIState', UIState);
    currentState = UIState.IDLE;
end

% 检查是否正忙
if currentState ~= 0  % 0 = IDLE
    utils_showMessage('系统正忙', 'warn', '请等待当前操作完成后再试');
    log_addWorkLog('警告: 尝试启动全脑扫描但系统正忙');
    return;
end

% 设置为扫描状态
UIState = getappdata(fig, 'UIState');
setappdata(fig, 'workflowState', UIState.SCANNING);

data = guidata(fig);

log_updateStatus('【第一阶段】开始一键全脑诊断...');
log_addWorkLog('步骤1: 验证数据完整性');

try
    % ======= 步骤1：检查数据 =======
    if isempty(data.processedSeries)
        log_addWorkLog('警告: 未检测到DSA数据，自动触发导入流程');
        log_updateStatus('正在导入DICOM数据...');
        
        ans_import = questdlg('未检测到DSA数据，是否导入？', ...
            '数据检查', '导入', '取消', '导入');
        
        if strcmp(ans_import, '取消')
            log_updateStatus('诊断流已取消');
            return;
        end
        
        createFileManagerDialog();
        drawnow;
        
        % 重新刷新数据
        data = guidata(fig);
        if isempty(data.processedSeries)
            utils_showMessage('数据导入失败', 'error', '请手动导入DICOM文件');
            return;
        end
    end
    
    % ======= 步骤2：维度检查 =======
    log_addWorkLog('步骤2: 进行维度和数据质量检查');
    log_updateStatus('验证数据维度...');
    
    imgSeq = data.processedSeries;
    [H, W, nFrames] = size(imgSeq);
    
    validateInputDimensions(H, W, nFrames);
    log_addWorkLog(sprintf('✓ 数据验证通过: %d×%d×%d', H, W, nFrames));
    
    % ======= 步骤3：全脑参数计算 =======
    log_addWorkLog('步骤3: 执行全脑像素参数计算');
    log_updateStatus('计算全脑 TTP/AUC 参数 (5-10秒)...');
    
    % 【修复】检查是否已缓存（从 guidata 读取）
    data = guidata(fig);
    if isfield(data, 'ParamMaps') && ~isempty(data.ParamMaps.TTP) && ~isempty(data.ParamMaps.AUC)
        cachedTTP = data.ParamMaps.TTP;
        cachedAUC = data.ParamMaps.AUC;
        log_addWorkLog('✓ 使用缓存的参数数据');
    else
        % 进行计算
        analysis_computeParametricMap();
        
        % 重新读取
        data = guidata(fig);
        if ~isfield(data, 'ParamMaps') || isempty(data.ParamMaps.TTP) || isempty(data.ParamMaps.AUC)
            error('参数计算失败：ParamMaps 为空');
        end
        cachedTTP = data.ParamMaps.TTP;
        cachedAUC = data.ParamMaps.AUC;
    end
    
    log_updateStatus('参数计算完成');
    
    % ======= 步骤4：自动检测最危险点 =======
    log_addWorkLog('步骤4: 自动检测Tmax最长的点');
    log_updateStatus('分析全脑灌注，定位最危险点...');
    
    % 应用血管掩膜，只在真实的脑血管区域内寻找最危险点
    vesselMask = data.ParamMaps.vesselMask;
    validTTP = cachedTTP;
    validTTP(~vesselMask) = -1;  % 过滤背景像素
    
    % 找到血管内 TTP 最大的点（延迟最严重）
    [maxTTP, maxIdx] = max(validTTP(:));
    [max_y, max_x] = ind2sub(size(validTTP), maxIdx);
    
    % 对应的AUC值
    maxAUC = cachedAUC(max_y, max_x);
    
    log_addWorkLog(sprintf('✓ 最危险点位置: (%d, %d), TTP=%.2fs, AUC=%.0f', ...
        max_x, max_y, maxTTP, maxAUC));
    
    % ======= 步骤5：提取最危险点的TDC曲线 =======
    log_addWorkLog('步骤5: 提取最危险点的TDC曲线');
    log_updateStatus('提取TDC曲线...');
    
    % 获取或创建全脑TDC矩阵（缓存）
    fullTDC_data = getappdata(fig, 'fullTDC_cached');
    
    if isempty(fullTDC_data)
        % 需要重新提取 - 这会花费2-3秒
        log_addWorkLog('首次提取全脑TDC矩阵...');
        
        % 从processedSeries提取
        fullTDC_data = zeros(H*W, nFrames, 'double');
        for f = 1:nFrames
            frame = double(imgSeq(:,:,f));
            fullTDC_data(:, f) = frame(:);
        end
        
        setappdata(fig, 'fullTDC_cached', fullTDC_data);
        log_addWorkLog('✓ 全脑TDC矩阵已缓存');
    end
    
    % 获取该像素的TDC曲线
    pixel_idx = sub2ind([H, W], max_y, max_x);
    TDC_maxPoint = fullTDC_data(pixel_idx, :);
    
    % ======= 步骤6：计算该点的关键参数 =======
    log_addWorkLog('步骤6: 计算该点的血流参数');
    
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    if ishandle(frameRateEdit)
        frameRate = str2double(get(frameRateEdit, 'String'));
    else
        frameRate = 4;
    end
    if isnan(frameRate) || frameRate <= 0, frameRate = 4; end
    
    t = (0:nFrames-1) / frameRate;
    
    % 【重构】使用统一的参数计算函数
    [~, AUC_point, MTT_point] = utils_computePerfusionParams(TDC_maxPoint, frameRate, 'Smooth', false);
    
    % ======= 步骤7：弹出结果窗口 =======
    log_addWorkLog('步骤7: 创建诊断结果窗口');
    log_updateStatus('生成诊断结果...');
    
    createDiagnosisWindow(fig, cachedTTP, data.ParamMaps.vesselMask, TDC_maxPoint, max_x, max_y, ...
        maxTTP, maxAUC, MTT_point, t, H, W);
    
    % ======= 步骤8：自动触发四象限风险分层 =======
    log_addWorkLog('步骤8: 自动触发四象限医学诊断');
    log_updateStatus('执行四象限风险分层...');
    
    try
        analysis_perfusionRiskClassification();
        log_addWorkLog('✓ 四象限风险分层已完成');
    catch ME
        log_addWorkLog(sprintf('警告: 四象限分层失败 - %s', ME.message));
    end
    
    % ======= 完成 =======
    log_updateStatus('✅ 一键全脑诊断完成！');
    log_addWorkLog('✓ 一键诊断流程全部完成');
    
    % 【修复】恢复状态为 IDLE
    UIState = getappdata(fig, 'UIState');
    setappdata(fig, 'workflowState', UIState.IDLE);
    
    utils_showMessage('诊断完成', 'success', ...
        sprintf(['✓ 全脑扫描完成\n\n' ...
                '最危险点信息:\n' ...
                '  位置: (%d, %d)\n' ...
                '  TTP: %.2f 秒\n' ...
                '  AUC: %.0f\n' ...
                '  MTT: %.2f 秒\n\n' ...
                '→ 请查看右侧诊断结果窗口'], ...
                max_x, max_y, maxTTP, maxAUC, MTT_point));
    
catch ME
    % 【修复】错误时也要恢复状态
    UIState = getappdata(fig, 'UIState');
    if ~isempty(UIState)
        setappdata(fig, 'workflowState', UIState.IDLE);
    end
    
    log_updateStatus('❌ 诊断流失败');
    log_addWorkLog(sprintf('严重错误: %s\n堆栈: %s (行%d)', ...
        ME.message, ME.stack(1).name, ME.stack(1).line));
    
    % 【修复】提供更详细的错误信息
    if contains(ME.identifier, 'MATLAB:badsubscript')
        utils_showMessage('诊断失败', 'error', '数据维度错误，请检查图像序列');
    elseif contains(ME.identifier, 'MATLAB:nomem')
        utils_showMessage('诊断失败', 'error', '内存不足，请关闭其他程序后重试');
    else
        utils_showMessage('诊断失败', 'error', ME.message);
    end
    
    rethrow(ME);
end

end

% ======================================================================
% 辅助函数
% ======================================================================

function validateInputDimensions(H, W, nFrames)
% 验证输入数据的有效性

errorMsg = {};

if H < 256 || H > 2048
    errorMsg{end+1} = sprintf('图像高度异常: %d (应为256-2048)', H);
end

if W < 256 || W > 2048
    errorMsg{end+1} = sprintf('图像宽度异常: %d (应为256-2048)', W);
end

if nFrames < 10 || nFrames > 200
    errorMsg{end+1} = sprintf('帧数异常: %d (应为10-200)', nFrames);
end

if nFrames <= 3
    errorMsg{end+1} = '帧数不足以计算TTP（需要至少4帧）';
end

if ~isempty(errorMsg)
    error(strjoin(errorMsg, '\n'));
end

end

function createDiagnosisWindow(fig, TTP_map, vesselMask, TDC_curve, point_x, point_y, ...
                               maxTTP, maxAUC, MTT_value, t, H, W)
% 创建一键诊断的结果窗口

baseImg = getappdata(fig, 'currentFrameDisplay');
if isempty(baseImg)
    data = guidata(fig);
    if ~isempty(data.processedSeries)
        baseImg = data.processedSeries(:,:,data.currentFrame);
    else
        baseImg = zeros(H, W);
    end
end

baseImg_norm = (baseImg - min(baseImg(:))) / max(1e-6, max(baseImg(:)) - min(baseImg(:)));

% 创建诊断窗口
diagFig = figure('Name', '【诊断结果】一键全脑诊断 - 最危险点分析', ...
    'NumberTitle', 'off', ...
    'Position', [200, 100, 1200, 700], ...
    'Color', [0.95, 0.95, 0.95], ...
    'MenuBar', 'none', 'ToolBar', 'figure');

% ========== 左侧：TTP参数地图 ==========
ax1 = axes('Parent', diagFig, 'Position', [0.05, 0.05, 0.45, 0.9]);

% 应用血管掩膜：背景像素设为NaN，只显示血管区域
if isempty(vesselMask) || ~isequal(size(vesselMask), [H, W])
    vesselMask = true(H, W);
end
TTP_masked = TTP_map;
TTP_masked(~vesselMask) = NaN;

% 显示TTP（背景为深色，NaN区域显示为黑色）
imagesc(TTP_masked, 'Parent', ax1);
set(ax1, 'Color', [0.05, 0.05, 0.08]);
colormap(ax1, hot);
axis(ax1, 'image');
hold(ax1, 'on');

% 标记最危险点
plot(ax1, point_x, point_y, 'g+', 'LineWidth', 3, 'MarkerSize', 20);
plot(ax1, point_x, point_y, 'go', 'LineWidth', 2, 'MarkerSize', 20);

title(ax1, sprintf('TTP 参数图\n最危险点: (%.0f, %.0f)', point_x, point_y), ...
    'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');

hold(ax1, 'off');
cb1 = colorbar(ax1, 'Location', 'southoutside');
cb1.Label.String = 'TTP (秒)';
cb1.Label.Color = 'w';

% ========== 右侧上：TDC曲线 ==========
ax2 = axes('Parent', diagFig, 'Position', [0.55, 0.52, 0.4, 0.43]);

plot(ax2, t, TDC_curve, 'LineWidth', 2.5, 'Color', [0.8, 0.2, 0.2]);
grid(ax2, 'on');
xlabel(ax2, '时间 (秒)', 'FontSize', 10);
ylabel(ax2, '集度值', 'FontSize', 10);
title(ax2, '最危险点 TDC 曲线', 'FontSize', 12, 'FontWeight', 'bold');
set(ax2, 'Color', [0.98, 0.98, 0.98]);

% ========== 右侧下：参数统计 ==========
ax3 = axes('Parent', diagFig, 'Position', [0.55, 0.05, 0.4, 0.43]);
axis(ax3, 'off');

% 参数文字
paramText = sprintf(['【最危险点诊断信息】\n' ...
                     '\n' ...
                     '━━━━━━━━━━━━━━━━━\n' ...
                     '位置坐标\n' ...
                     '  X = %d px\n' ...
                     '  Y = %d px\n' ...
                     '\n' ...
                     '━━━━━━━━━━━━━━━━━\n' ...
                     '灌注参数\n' ...
                     '  TTP   = %.2f 秒  (达峰时间)\n' ...
                     '  AUC   = %.0f      (曲线下面积)\n' ...
                     '  MTT   = %.2f 秒  (通过时间)\n' ...
                     '\n' ...
                     '━━━━━━━━━━━━━━━━━\n' ...
                     '临床判断\n' ...
                     '  • TTP严重延迟 → 缺血可能性极高\n' ...
                     '  • AUC值 → 判断是否核心梗死\n' ...
                     '  • 需进行四象限风险分层\n' ...
                     '    确定是否需要干预\n'], ...
                    round(point_x), round(point_y), maxTTP, maxAUC, MTT_value);

text(ax3, 0.05, 0.95, paramText, ...
     'Units', 'normalized', ...
     'FontName', 'Courier', ...
     'FontSize', 9, ...
     'VerticalAlignment', 'top', ...
     'HorizontalAlignment', 'left', ...
     'BackgroundColor', [0.98, 0.95, 0.92], ...
     'EdgeColor', [0.5, 0.5, 0.5], ...
     'Margin', 5);

% 保存数据到诊断窗口
setappdata(diagFig, 'diagnosisData', struct(...
    'pointX', point_x, ...
    'pointY', point_y, ...
    'TTP_map', TTP_map, ...
    'TDC_curve', TDC_curve, ...
    't', t, ...
    'maxTTP', maxTTP, ...
    'maxAUC', maxAUC, ...
    'MTT', MTT_value));

end
