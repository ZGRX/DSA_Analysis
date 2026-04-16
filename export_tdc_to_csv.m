%% export_tdc_to_csv.m
% 功能：从已脱敏的真实DICOM序列中提取近端/远端TDC，导出为CSV
% 供Python端AI模块读取，替换合成数据，实现真实临床数据验证闭环
%
% 使用方法：在MATLAB中运行此脚本
%   1. 先用GUI系统正常打开一个病例并完成ROI放置（近端+远端）
%   2. 或直接运行此脚本自动批量处理（需要analysis_batchValidation中的数据）
%
% 输出：DSA_Python/data/cases/DSA_P00X_tdc.csv
%       格式：time,proximal,distal（每行一帧）

clear; clc;
fprintf('=== TDC导出脚本 ===\n');
fprintf('将真实DICOM分析结果导出为Python可读CSV\n\n');

% ── 路径配置 ──────────────────────────────────────────────────────────────
rootDir    = 'C:\Users\4MR84K3\Desktop\DSA_Analysis-main';
patDataDir = fullfile(rootDir, 'PatientData_Anon');
outputDir  = fullfile(rootDir, 'DSA_Python', 'data', 'cases');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% ── 患者列表与临床标签 ────────────────────────────────────────────────────
% 请根据真实临床记录确认标签
patients = struct();
patients(1).id    = 'DSA_P001'; patients(1).label = 'Normal';
patients(2).id    = 'DSA_P003'; patients(2).label = 'Normal';
patients(3).id    = 'DSA_P004'; patients(3).label = 'CHS';
patients(4).id    = 'DSA_P005'; patients(4).label = 'CHS';
patients(5).id    = 'DSA_P006'; patients(5).label = 'Normal';
patients(6).id    = 'DSA_P007'; patients(6).label = 'Normal';
patients(7).id    = 'DSA_P008'; patients(7).label = 'Normal';
patients(8).id    = 'DSA_P009'; patients(8).label = 'Normal';
patients(9).id    = 'DSA_P010'; patients(9).label = 'Normal';

nPatients = length(patients);
successCount = 0;

for i = 1:nPatients
    pid    = patients(i).id;
    label  = patients(i).label;
    dcmDir = fullfile(patDataDir, pid);
    
    fprintf('[%s] 标签: %s\n', pid, label);
    
    if ~exist(dcmDir, 'dir')
        fprintf('  ⚠️  目录不存在，跳过: %s\n', dcmDir);
        continue;
    end
    
    % ── 读取DICOM序列 ─────────────────────────────────────────────────────
    try
        files = dir(fullfile(dcmDir, 'IM*'));
        if isempty(files)
            files = dir(fullfile(dcmDir, '*.dcm'));
        end
        
        if isempty(files)
            fprintf('  ⚠️  未找到DICOM文件，跳过\n');
            continue;
        end
        
        fprintf('  发现 %d 个DICOM文件，扫描多帧序列...\n', length(files));
        
        % 找帧数最多的文件（最可能是主DSA序列）
        bestFile = '';
        bestNFrames = 0;
        bestH = 0; bestW = 0;
        
        for f = 1:length(files)
            fpath = fullfile(dcmDir, files(f).name);
            try
                raw = dicomread(fpath);
                sz  = size(raw);          % H×W×C×T or H×W×T or H×W
                if numel(sz) == 4
                    nF = sz(4);           % 4D: H×W×1×T
                elseif numel(sz) == 3
                    nF = sz(3);           % 3D: H×W×T
                else
                    nF = 1;               % 2D单帧
                end
                if nF > bestNFrames
                    bestNFrames = nF;
                    bestFile    = fpath;
                    bestH = sz(1); bestW = sz(2);
                end
            catch
                % 跳过无法读取的文件
            end
        end
        
        if bestNFrames < 5
            fprintf('  ⚠️  有效帧数不足(%d帧)，跳过\n', bestNFrames);
            continue;
        end
        
        fprintf('  主序列: %s (%d×%d, %d帧)\n', ...
                fileparts(bestFile), bestH, bestW, bestNFrames); % only basename needed
        
        % 读取主序列
        raw = double(dicomread(bestFile));
        sz  = size(raw);
        if numel(sz) == 4
            imgRaw = squeeze(raw);        % => H×W×T
        elseif numel(sz) == 3
            imgRaw = raw;
        else
            imgRaw = raw;                 % single frame fallback
        end

        [H, W, nFrames] = size(imgRaw);
        fprintf('  影像尺寸: %d×%d, %d帧\n', H, W, nFrames);

        % ── 执行真正的 DSA 背景减影 ──────────────────────────────────────
        % DICOM 反色: DSA图像通常是负像（血管黑，背景白）
        % 经过反色后: 血管白（亮度高），背景黑
        globalMax = double(max(imgRaw(:)));
        if globalMax > 0
            imgRaw = imgRaw / globalMax * 255;
        end
        imgRaw = 255 - imgRaw;

        % 取前 15% 的帧作为无造影剂背景掩膜
        nMask = max(1, min(3, floor(nFrames * 0.15)));
        mask3D = double(mean(imgRaw(:,:,1:nMask), 3));
        
        imgSeq = zeros(size(imgRaw));
        for frameIdx = 1:nFrames
            dsaFrame = mask3D - double(imgRaw(:,:,frameIdx));
            % 反色减影后造影剂区域为正差值
            imgSeq(:,:,frameIdx) = max(0, dsaFrame);
        end

        
        % ── 时间轴构建 ──────────────────────────────────────────────────
        tRaw = linspace(0, 20, nFrames);
        
        % ── 自动选取ROI：近端（脑底动脉环附近）和远端（大脑皮层区） ────
        % 简化策略：基于TTP图自动找峰值到达时间最早（近端）和最晚（远端）的区域
        
        % 计算每像素TTP
        ttpMap = zeros(H, W);
        aucMap = zeros(H, W);
        
        for r = 1:H
            for c = 1:W
                curve = squeeze(imgSeq(r, c, :))';
                if max(curve) - min(curve) > 0.05 * max(curve(:))
                    ttpMap(r, c) = find(curve == max(curve), 1);
                    aucMap(r, c) = trapz(curve);
                end
            end
        end
        
        % 近端ROI：TTP最早的前5%像素的中心
        validMask = ttpMap > 0;
        ttpVals   = ttpMap(validMask);
        ttpThresh = prctile(ttpVals, 5);  % 最早到达的5%
        proxMask  = (ttpMap > 0) & (ttpMap <= ttpThresh);
        
        % 远端ROI：TTP最晚的前20%像素（排除近端）
        ttpThreshDist = prctile(ttpVals, 80);
        distMask  = (ttpMap >= ttpThreshDist);
        
        % 提取曲线（ROI内像素平均）
        proxPixels = reshape(imgSeq, H*W, nFrames);
        proxMaskVec = proxMask(:);
        distMaskVec = distMask(:);
        
        if sum(proxMaskVec) < 3 || sum(distMaskVec) < 3
            fprintf('  ⚠️  ROI像素不足，跳过\n');
            continue;
        end
        
        proxTDC = mean(proxPixels(proxMaskVec, :), 1);  % [1, nFrames]
        distTDC = mean(proxPixels(distMaskVec, :), 1);
        
        % ── PCHIP插值到100个点 ──────────────────────────────────────────
        t100    = linspace(0, 20, 100);
        proxInterp = pchip(tRaw, proxTDC, t100);
        distInterp = pchip(tRaw, distTDC, t100);
        
        % 归一化到[0,1]
        proxInterp = (proxInterp - min(proxInterp)) / max(eps, max(proxInterp) - min(proxInterp));
        distInterp = (distInterp - min(distInterp)) / max(eps, max(distInterp) - min(distInterp));
        
        proxInterp = max(0, min(1, proxInterp));
        distInterp = max(0, min(1, distInterp));
        
        % ── 导出CSV ─────────────────────────────────────────────────────
        csvPath = fullfile(outputDir, sprintf('%s_tdc.csv', pid));
        fid = fopen(csvPath, 'w');
        fprintf(fid, 'time,proximal,distal\n');
        for k = 1:100
            fprintf(fid, '%.4f,%.6f,%.6f\n', t100(k), proxInterp(k), distInterp(k));
        end
        fclose(fid);
        
        fprintf('  ✅ 导出成功: %s_tdc.csv (%d行)\n', pid, 100);
        successCount = successCount + 1;
        
    catch ME
        fprintf('  ❌ 处理失败: %s\n', ME.message);
    end
    
    fprintf('\n');
end

fprintf('=================================\n');
fprintf('导出完成: %d/%d 个病例成功\n', successCount, nPatients);
fprintf('CSV文件路径: %s\n', outputDir);
fprintf('\n下一步：在Python端运行 prepare_bilstm_data.py 重新生成数据集\n');
fprintf('然后运行 run_bilstm_loo_numpy.py 进行真实数据验证\n');
