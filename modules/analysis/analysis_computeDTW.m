function [dtwDistance, alignmentPath] = analysis_computeDTW(signal1, signal2)
% ANALYSIS_COMPUTEDTW 计算两条时间序列曲线的动态时间规整(DTW)距离
% 说明:
%   这是为 CCF-B 级别论文准备的核心算法模块。通过非线性动态规划寻找两条
%   TDC（时间-密度曲线）的最优匹配路径，完美量化狭窄导致血流产生的"涡动能形态畸变"。
% 输入:
%   signal1: 近端造影剂时间密度曲线 (1D array)
%   signal2: 远端造影剂时间密度曲线 (1D array)
% 输出:
%   dtwDistance: 规整后累积最小距离(特征归一化后)
%   alignmentPath: 最佳匹配路径点集 [M x 2]

    % 确保是列向量
    signal1 = signal1(:);
    signal2 = signal2(:);
    
    % 核心：基础归一化处理
    % 统一量纲, 消除基线整体造影剂浓度的影响, 强制算法【仅比较形态的畸变】
    s1 = (signal1 - min(signal1)) / max(eps, max(signal1) - min(signal1));
    s2 = (signal2 - min(signal2)) / max(eps, max(signal2) - min(signal2));
    
    % 调用 MATLAB 官方的 dtw 函数 (需要 Signal Processing Toolbox)
    try
        [dtwDistance, ix, iy] = dtw(s1, s2);
        alignmentPath = [ix, iy];
        % 根据序列长度做个标准化，便于不同心率和不同注射时长的患者间横向比较
        dtwDistance = dtwDistance / length(ix);
    catch ME
        % 纯手写降级预案：如果不具备信号箱，则纯手写推导基础版 DTW 动态规划
        [dtwDistance, alignmentPath] = basicDTW(s1, s2);
    end
end

function [dist, path] = basicDTW(s1, s2)
    % 纯 C 风格的 O(N^2) 动态规划推导
    n = length(s1);
    m = length(s2);
    DTW = inf(n+1, m+1);
    DTW(1, 1) = 0;
    
    for i = 1:n
        for j = 1:m
            cost = abs(s1(i) - s2(j));
            DTW(i+1, j+1) = cost + min([DTW(i, j+1), DTW(i+1, j), DTW(i, j)]);
        end
    end
    dist = DTW(n+1, m+1) / max(n, m);
    
    % 回溯路径
    path = zeros(max(n,m)*2, 2);
    i = n; j = m; k = 1;
    while i > 0 && j > 0
        path(k,:) = [i, j]; k = k + 1;
        if i==1, j=j-1;
        elseif j==1, i=i-1;
        else
            [~, idx] = min([DTW(i, j+1), DTW(i+1, j), DTW(i, j)]);
            if idx == 1, i = i-1;
            elseif idx == 2, j = j-1;
            else
                i = i-1; j = j-1;
            end
        end
    end
    path = flipud(path(1:k-1, :));
end
