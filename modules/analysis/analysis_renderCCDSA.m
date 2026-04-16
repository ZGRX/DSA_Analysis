function rgbImg = analysis_renderCCDSA(imgSeq, frameRate, edgeMask)
% ANALYSIS_RENDERCCDSA  严格按文献实现彩色编码 DSA (CC-DSA)
%
% 算法来源:
%   Strother CM, et al. "Parametric Color Coding of Digital Subtraction
%   Angiography." AJNR Am J Neuroradiol 31:919-24, May 2010.
%   DOI: 10.3174/ajnr.A2020
%
% 文献原文映射公式 (Methods 节):
%   Hue        = TTP × (240/360)     ← TTP归一化后映射到色环0°~240°
%   Saturation = constant (0.9)      ← 文献明确：饱和度为常数
%   Value      = I_max               ← 最大增强强度，归一化到[0,1]
%
%   其中:
%     I_mask = mask帧像素强度（造影剂到达前）
%     I_max  = I_peak - I_mask（最大增强）
%     I_max  再全图归一化: I_max_norm = I_max / max(I_max_all)
%     TTP    = 从时间序列中直接找峰值帧对应时间（秒）
%
% 输入:
%   imgSeq    - [H, W, nFrames] 减影后时间序列（double）
%   frameRate - 帧率 (fps)
%   edgeMask  - [H, W] 逻辑掩膜，true=有效像素，false=准直器/边缘
%
% 输出:
%   rgbImg    - [H, W, 3] RGB 图像，值域 [0,1]

[H, W, nFrames] = size(imgSeq);
imgSeq = double(imgSeq);

% ── 1. 确定 mask 帧（造影剂到达前的帧）────────────────────────────────
% 策略：取前 N 帧均值，N 由检测首帧显著上升点决定；若无法检测则默认第1帧
nMaskFrames = detectMaskFrameCount(imgSeq, edgeMask);
if nMaskFrames < 1, nMaskFrames = 1; end

% I_mask: 每个像素在 mask 帧期间的平均强度（代表本底/背景）
I_mask = mean(imgSeq(:,:,1:nMaskFrames), 3);   % [H, W]

% ── 2. 计算每像素 I_max 和 TTP ─────────────────────────────────────────
% I_peak: 时间维度最大值
[I_peak, peakFrameIdx] = max(imgSeq, [], 3);    % [H, W]

% I_max = I_peak - I_mask（最大增强强度，文献公式）
I_max = max(0, I_peak - I_mask);               % [H, W]

% TTP（秒）= (峰值帧序号 - 1) / frameRate
TTP_map = (double(peakFrameIdx) - 1) / frameRate;   % [H, W]

% ── 3. 全局归一化 I_max（文献: "normalized against the maximal I_max
%       among all the pixels in the image"）───────────────────────────────
% 仅在有效掩膜内计算归一化基准，防止边缘噪声拉偏
if nargin >= 3 && ~isempty(edgeMask)
    validVals = I_max(edgeMask);
else
    validVals = I_max(:);
    edgeMask  = true(H, W);
end
I_max_global_peak = max(validVals(:));
I_max_norm = I_max / (I_max_global_peak + eps);      % [H, W], 范围 [0,1]
I_max_norm = min(1, max(0, I_max_norm));

% ── 4. TTP 归一化──────────────────────────────────────────────────────
% 用 2%~98% 百分位数做鲁棒归一化（避免异常像素拉偏色谱）
ttp_valid = TTP_map(edgeMask & I_max_norm > 0.05);
if isempty(ttp_valid)
    ttp_valid = TTP_map(:);
end
prc = prctile(ttp_valid, [2, 98]);
if prc(2) <= prc(1), prc(2) = prc(1) + eps; end

TTP_norm = (TTP_map - prc(1)) / (prc(2) - prc(1));
TTP_norm = min(1, max(0, TTP_norm));                  % [H, W], 范围 [0,1]

% ── 5. HSV 映射（严格遵循文献公式）──────────────────────────────────────
%
%   Strother 2010 原文:
%     "Hue = TTP × 240/360"   → 0(红,早到达) ~ 0.667(蓝,延迟)
%     "Saturation = constant"  → 取 0.9
%     "Value = I_max"          → 归一化峰值增强强度
%
H_ch = TTP_norm * (240/360);    % Hue:  0(红)→0.667(蓝)
S_ch = ones(H, W) * 0.9;       % Saturation: 常数 0.9（文献定义）
V_ch = I_max_norm;              % Value: 归一化 I_max（文献定义）

% 轻度 gamma 增强 Value 通道对比度（不改变映射逻辑，仅视觉优化）
V_ch = V_ch .^ 0.75;

% ── 6. 背景抑制──────────────────────────────────────────────────────────
% I_max 极低的像素（非血管区）降低亮度和饱和度至 0（黑色背景）
bg_thresh = 0.04;   % I_max < 4% 视为背景
bg_mask = (I_max_norm < bg_thresh) | (~edgeMask);
S_ch(bg_mask) = 0;
V_ch(bg_mask) = 0;

% ── 7. HSV → RGB ─────────────────────────────────────────────────────────
hsvImg = cat(3, H_ch, S_ch, V_ch);
rgbImg = hsv2rgb(hsvImg);

end

% =========================================================================
% 辅助函数：自动检测 mask 帧数量
% 策略：找到全图平均强度首次显著上升的帧，之前的帧作为 mask 帧
% =========================================================================
function nMask = detectMaskFrameCount(imgSeq, edgeMask)
    [H, W, nFrames] = size(imgSeq);
    if nargin < 2 || isempty(edgeMask)
        edgeMask = true(H, W);
    end
    
    % 计算每帧在有效区域内的平均强度
    meanPerFrame = zeros(1, nFrames);
    edgeVec = edgeMask(:);
    for f = 1:nFrames
        frame = imgSeq(:,:,f);
        meanPerFrame(f) = mean(frame(edgeVec));
    end
    
    % 计算帧间差分，找到首次显著上升点
    baseline = mean(meanPerFrame(1:max(1, floor(nFrames*0.15))));
    stdBaseline = std(meanPerFrame(1:max(2, floor(nFrames*0.15))));
    threshold = baseline + max(2*stdBaseline, 0.05 * (max(meanPerFrame) - baseline));
    
    riseIdx = find(meanPerFrame > threshold, 1, 'first');
    
    if isempty(riseIdx) || riseIdx <= 1
        nMask = 1;
    else
        nMask = max(1, riseIdx - 1);
    end
end
