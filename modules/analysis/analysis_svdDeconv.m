function [CBF, CBV, MTT, TTP] = analysis_svdDeconv(fullTDC, frameRate, varargin)
% ANALYSIS_SVDDECONV Perform SVD-based deconvolution on full-pixel TDC.
%   fullTDC   : (Npix x Nframes) matrix of time‑density curves.
%   frameRate : frames per second.
%   Optional name‑value pairs:
%       'AIFFrames'   - number of initial frames to compute AIF (default 5).
%       'Lambda'      - Tikhonov regularization parameter (default 0.01).
%   Returns pixel‑wise perfusion maps (CBF, CBV, MTT, TTP) each of size Npix.

p = inputParser;
addParameter(p, 'AIFFrames', 5, @(x) isnumeric(x) && x>0);
addParameter(p, 'Lambda', 0.01, @(x) isnumeric(x) && x>=0);
parse(p, varargin{:});
AIFFrames = p.Results.AIFFrames;
lambda = p.Results.Lambda;

% Ensure data is double precision for SVD to prevent underlying elmat errors
fullTDC = double(fullTDC);

% --- 自动检测动脉输入函数 (AIF) ---
% 【医学修正】AIF 应源自大脑主供血动脉（如颈内动脉/大脑中动脉），
% 而非全脑平均（会混入静脉、脑实质、脑脊液，导致CBF/CBV系统性偏差）。
%
% 动脉像素的两个关键特征：
%   1. 高峰值强度（早期高对比度摄取）
%   2. 早期达峰（Tpeak 靠前，即造影剂最先到达动脉）
%
[~, nFrames] = size(fullTDC);
t = (0:nFrames-1) / frameRate;

% 步骤1: 计算每个像素的峰值强度与达峰帧
peakIntensity = max(fullTDC, [], 2);          % [Npix x 1]
[~, peakFrame]  = max(fullTDC, [], 2);          % [Npix x 1]

% 步骤2: 筛选"动脉候选"像素
%   条件A: 峰值强度 > 全局75百分位数 (高浓度区域)
%   条件B: 达峰帧 < 全帧数的40%         (早峰，动脉优先到达)
intensityThreshold = prctile(peakIntensity, 75);
earlyPeakThreshold = nFrames * 0.40;

arterialMask = (peakIntensity > intensityThreshold) & (peakFrame < earlyPeakThreshold);

% 步骤3: 至少需要10个候选像素，否则逐步放宽条件
if sum(arterialMask) < 10
    intensityThreshold = prctile(peakIntensity, 60);
    arterialMask = (peakIntensity > intensityThreshold) & (peakFrame < earlyPeakThreshold * 1.5);
end

% 步骤4: 最终安全阀 - 若仍不足则回退到全局平均（降级模式）
if sum(arterialMask) < 5
    warning('DSA:AIF', 'AIF自动检测失败（候选像素不足5个），已回退至全局平均模式。');
    AIF = mean(fullTDC, 1)';
else
    AIF = mean(fullTDC(arterialMask, :), 1)'; % [nFrames x 1]，仅用动脉候选区均值
end



% 【性能优化】用 MATLAB 内置 toeplitz() 替换手写 for 循环
% 构建下三角 Toeplitz 卷积矩阵（因果系统，仅下半部分有效）
H = toeplitz(AIF, [AIF(1); zeros(nFrames-1, 1)]);

% Regularized SVD
[U, S, V] = svd(H, 'econ');
S_reg = diag(S) ./ (diag(S).^2 + lambda^2);
H_inv = V * diag(S_reg) * U';

% Deconvolve each pixel (vectorized)
% fullTDC' is Nframes x Npix, multiply by H_inv (Nframes x Nframes)
residue = (H_inv * fullTDC')'; % Npix x Nframes

% Compute perfusion parameters per pixel
% CBF approximated as max of residue (peak of impulse response)
CBF = max(residue, [], 2);
% CBV as area under residue curve
CBV = trapz(t, residue, 2);
% MTT = CBV / CBF (avoid division by zero)
MTT = CBV ./ max(CBF, eps);
% TTP = time to peak of original TDC (not deconvolved) for visualization
[~, idxPeak] = max(fullTDC, [], 2);
TTP = (idxPeak-1) / frameRate;

end
