function vesselness = utils_frangiFilter2D(I)
% UTILS_FRANGIFILTER2D 多尺度 Frangi 血管增强滤波 (Frangi et al., 1998)
%
% 参考文献:
%   Frangi AF, et al. "Multiscale vessel enhancement filtering."
%   MICCAI 1998, LNCS 1496: 130-137.
%
% 算法核心：在多个尺度 sigma 下计算 Hessian 矩阵特征值，
% 取各尺度的管状响应最大值，同时增强细小侧支和粗大主干血管。
%
% 输入: I - 灰度图像 (DSA减影序列的单帧)
% 输出: vesselness - 血管管状响应图 [0,1]，越接近1表示越像血管

    I = double(I);
    % 全局归一化到 [0,1]
    I = (I - min(I(:))) / max(1e-6, max(I(:)) - min(I(:)));

    % ==========================================
    % 【多尺度参数】Frangi 1998 论文建议范围
    % sigma 越小 → 增强细小侧支血管 (1-2像素宽)
    % sigma 越大 → 增强粗大主干血管 (5-10像素宽)
    % DSA 图像中血管管径约 2-15 像素，sigma 取 1:2:7 覆盖主要范围
    % ==========================================
    sigmaRange = [1, 2, 4, 7];   % 4个尺度，兼顾速度和覆盖度
    beta  = 0.5;                  % 区分管状/斑状的形态参数 (Frangi 原论文默认值)

    % 汇聚所有尺度的最大响应
    vesselness = zeros(size(I));

    for sigma = sigmaRange
        % 1. 高斯平滑（尺度空间）
        I_smooth = imgaussfilt(I, sigma);

        % 2. 计算二阶偏导数（Hessian 矩阵各分量）
        % sigma² 归一化确保不同尺度响应可比（Lindeberg 尺度规范化）
        scale2 = sigma^2;
        [Gx, Gy]   = gradient(I_smooth);
        [Gxx, Gxy] = gradient(Gx);
        [~,   Gyy] = gradient(Gy);
        Gxx = scale2 * Gxx;
        Gxy = scale2 * Gxy;
        Gyy = scale2 * Gyy;

        % 3. 解析计算 Hessian 特征值 (2×2 矩阵闭合解，无需迭代)
        tmp     = sqrt((Gxx - Gyy).^2 + 4 * Gxy.^2);
        lambda1 = 0.5 * (Gxx + Gyy + tmp);
        lambda2 = 0.5 * (Gxx + Gyy - tmp);

        % 按绝对值排序：确保 |λ1| ≤ |λ2|
        swap = abs(lambda1) > abs(lambda2);
        [lambda1(swap), lambda2(swap)] = deal(lambda2(swap), lambda1(swap));

        % 4. Frangi 管状响应函数
        %    Rb: 形态比（斑状物 vs 管状物），接近 0 表示管状
        %    S:  结构强度（区分背景噪声与真实结构）
        Rb = (lambda1 ./ (lambda2 + 1e-8)).^2;
        S2 = lambda1.^2 + lambda2.^2;
        c2 = 0.5 * max(S2(:));   % 自适应背景抑制阈值
        if c2 < 1e-10, c2 = 1e-10; end

        % 管状响应：仅在 λ2 < 0（暗管状结构）时有效
        v = exp(-Rb / (2 * beta^2)) .* (1 - exp(-S2 / (2 * c2)));
        v(lambda2 >= 0) = 0;      % λ2 ≥ 0 为凸结构（背景/斑点），清零
        v(isnan(v))     = 0;

        % 5. 在各尺度取逐像素最大值（多尺度融合核心）
        vesselness = max(vesselness, v);
    end

    % 最终归一化到 [0,1]
    vMin = min(vesselness(:));
    vMax = max(vesselness(:));
    if vMax > vMin
        vesselness = (vesselness - vMin) / (vMax - vMin);
    end
end
