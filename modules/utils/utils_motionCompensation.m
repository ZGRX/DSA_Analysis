function [registeredSeq, meanDisplacement] = utils_motionCompensation(imgSeq, varargin)
% UTILS_MOTIONCOMPENSATION 执行时间维度的运动伪影补偿 (Motion Compensation)
% 将DSA图像序列中的每一帧对齐到一个基准帧，以消除患者轻微运动(如呼吸、吞咽)带来的像素不对齐
%
% 输入:
%   - imgSeq: 原始图像序列 [H, W, Frames]
% 可选参数 (Name-Value):
%   - 'Method': 配准方法，可眩 'translation' (平移，速度快，抗噪好) 或 'rigid' (刚性变换)
%   - 'RefFrame': 基准帧的索引。如果为0则自动选取对比度最强的充盈帧作为基准。默认自动选取。
%   - 'Enable': 是否开启，传 false 仅返回原图像。用于全局一键开关。
%
% 输出:
%   - registeredSeq: 配准后的图像序列 [H, W, Frames]
%   - meanDisplacement: 平均偏移像素绝对值量级 (标量)，可以用于评估运动幅度

p = inputParser;
addRequired(p, 'imgSeq', @(x) isnumeric(x) && ndims(x) == 3);
addParameter(p, 'Method', 'translation', @(x) ischar(x));
addParameter(p, 'RefFrame', 0, @(x) isnumeric(x));
addParameter(p, 'Enable', true, @(x) islogical(x));
parse(p, imgSeq, varargin{:});

method = p.Results.Method;
refIdx = p.Results.RefFrame;
enable = p.Results.Enable;

[H, W, nFrames] = size(imgSeq);
registeredSeq = imgSeq;
meanDisplacement = 0;

if ~enable || nFrames < 2
    return;
end

% 自动寻找基准帧 (选取图像全局灰度方差最大的帧，通常造影剂充盈最满)
if refIdx <= 0 || refIdx > nFrames
    variances = zeros(1, nFrames);
    for f = 1:nFrames
        frame = double(imgSeq(:,:,f));
        variances(f) = var(frame(:));
    end
    [~, refIdx] = max(variances);
end

refFrame = imgSeq(:,:,refIdx);

% 配置优化器和目标函数 (单模态，因为都是 DSA 图像)
[optimizer, metric] = imregconfig('monomodal');
% 调优提速：减少迭代次数和步长适应
optimizer.MaximumIterations = 50; 
optimizer.MinimumStepLength = 1e-4;

displacementSum = 0;
totalRegs = 0;

% 建立进度条环境（如果已存在 waitbar 则可能无法直接调用，因此这里默默计算不打扰主UI操作）
% 建议外部调用前先打 log_updateStatus
for f = 1:nFrames
    if f == refIdx
        continue;
    end
    
    moving = imgSeq(:,:,f);
    
    % 执行图像配准变换求解
    try
        tform = imregtform(moving, refFrame, method, optimizer, metric, 'DisplayOptimization', false);
        
        % 计算偏移量级 (对于位移，取 translation 参数)
        if contains(method, 'translation')
            dx = tform.T(3,1);
            dy = tform.T(3,2);
            displacementSum = displacementSum + sqrt(dx^2 + dy^2);
            totalRegs = totalRegs + 1;
        end
        
        % 应用仿射/平移变换
        registeredFrame = imwarp(moving, tform, 'OutputView', imref2d([H, W]));
        registeredSeq(:,:,f) = registeredFrame;
    catch
        % 如果配准失败，保持原帧
        registeredSeq(:,:,f) = moving;
    end
end

if totalRegs > 0
    meanDisplacement = displacementSum / totalRegs;
end

end
