function [TTP, AUC, MTT] = utils_computePerfusionParams(pixelCurve, frameRate, varargin)
% UTILS_COMPUTEPERFUSIONPARAMS 统一的灌注参数计算函数
%
% 输入:
%   pixelCurve - 像素的时间密度曲线 (1 x nFrames 或 nFrames x 1)
%   frameRate - 帧率 (fps)
%   可选参数:
%     'Smooth' - 是否平滑曲线 (默认: true)
%     'BaselineCorrection' - 是否进行基线校正 (默认: false)
%     'Baseline' - 基线值 (如果 BaselineCorrection=true)
%
% 输出:
%   TTP - Time To Peak (达峰时间, 秒)
%   AUC - Area Under Curve (曲线下面积)
%   MTT - Mean Transit Time (平均通过时间, 秒)
%
% 示例:
%   [TTP, AUC, MTT] = utils_computePerfusionParams(curve, 4);
%   [TTP, AUC, MTT] = utils_computePerfusionParams(curve, 4, 'Smooth', true);

% 解析可选参数
p = inputParser;
addParameter(p, 'Smooth', true, @islogical);
addParameter(p, 'BaselineCorrection', false, @islogical);
addParameter(p, 'Baseline', 0, @isnumeric);
parse(p, varargin{:});

doSmooth = p.Results.Smooth;
doBaselineCorrection = p.Results.BaselineCorrection;
baseline = p.Results.Baseline;

% 确保是行向量
if size(pixelCurve, 1) > size(pixelCurve, 2)
    pixelCurve = pixelCurve';
end

% 转换为 double
pixelCurve = double(pixelCurve);

nFrames = length(pixelCurve);
if nFrames < 2
    error('曲线长度不足，至少需要2个点');
end

% 时间轴
t = (0:nFrames-1) / frameRate;

% 基线校正
if doBaselineCorrection
    pixelCurve = max(0, pixelCurve - baseline);
end

% 平滑处理（减少噪声影响）
if doSmooth && nFrames >= 5
    smoothedCurve = movmean(pixelCurve, 3);
else
    smoothedCurve = pixelCurve;
end

% 计算 TTP (Time To Peak)
[~, maxIdx] = max(smoothedCurve);
TTP = t(maxIdx);

% 计算 AUC (Area Under Curve)
AUC = trapz(t, pixelCurve);  % 使用原始曲线计算面积

% 计算 MTT (Mean Transit Time)
% MTT = ∫t·C(t)dt / ∫C(t)dt
if AUC > eps
    MTT = trapz(t, t .* pixelCurve) / AUC;
else
    MTT = 0;
end

end
