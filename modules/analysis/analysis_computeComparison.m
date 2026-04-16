function results = analysis_computeComparison(preOpData, postOpData)
% analysis_computeComparison  执行术前术后狭窄双端血流动力学对比计算
% 输入:
%   preOpData, postOpData - 从 .mat 文件加载的 data 结构体
% 输出:
%   results - 包含代偿恢复率、高灌注预警判断以及用于机器学习特征的结构体

if isempty(preOpData) || isempty(postOpData)
    error('DSA:Compare:MissingData', '缺少对比数据（术前或术后）');
end

preParams = preOpData.perfusionParams;
postParams = postOpData.perfusionParams;

% 必须包含至少2个区（近端与远端）
if length(preParams) < 2 || length(postParams) < 2
    error('DSA:Compare:InsufficientROI', '数据不包含完整的狭窄双端(近端/远端)分析结果');
end

roiNames = {'狭窄近端 (Proximal)', '狭窄远端 (Distal)'};

%% 1. 核心参数提取与恢复率计算 (基于远端 Distal)
preDistal = preParams(2);
postDistal = postParams(2);

% TMAX 短缩量 (秒，负数代表提前，即改善)
TMAX_Shift = postDistal.TMAX - preDistal.TMAX;

% Peak 峰值提升幅度 (%)
if preDistal.Peak > 0
    Peak_Increase_Ratio = ((postDistal.Peak - preDistal.Peak) / preDistal.Peak) * 100;
else
    Peak_Increase_Ratio = 0;
end

% AUC 血容量提升幅度 (%)
if preDistal.AUC > 0
    AUC_Increase_Ratio = ((postDistal.AUC - preDistal.AUC) / preDistal.AUC) * 100;
else
    AUC_Increase_Ratio = 0;
end

% MTT 平均通过时间缩短 (%)
if preDistal.MTT > 0
    MTT_Improvement = ((preDistal.MTT - postDistal.MTT) / preDistal.MTT) * 100;
else
    MTT_Improvement = 0;
end

%% 2. 跨狭窄改善评估 — 术前 vs 术后
% 术前 TTS（近远端时延差）
preTTS  = max(0, preParams(2).TMAX  - preParams(1).TMAX);
% 术后 TTS
postTTS = max(0, postParams(2).TMAX - postParams(1).TMAX);
% TTS 改善量（正值 = 支架放完后延迟缩短 = 改善）
TTS_Improvement = preTTS - postTTS;

% 术前 Peak Attenuation（近端峰值/远端峰值）
prePeakRatio  = preParams(1).Peak  / max(eps, preParams(2).Peak);
postPeakRatio = postParams(1).Peak / max(eps, postParams(2).Peak);
% 峰值衰减改善（正值 = 近远端差异缩小 = 改善）
PeakRatio_Improvement = prePeakRatio - postPeakRatio;

%% 3. 【DTW 纵向对比】术前 vs 术后 远端 TDC 波形相似度
% 正确用法：DTW 衡量同一位置（远端 Distal）在手术前后的波形形态变化
% 距离越小 → 术后波形越接近正常单峰形态 → 血流越改善
% (DTW 横向比较近端 vs 远端意义弱，已移除)
DTW_longitudinal = NaN;
try
    if isfield(preOpData, 'smoothedLobeData') && isfield(postOpData, 'smoothedLobeData')
        preCurve2  = preOpData.smoothedLobeData(2,:);
        postCurve2 = postOpData.smoothedLobeData(2,:);
        preCurve2_norm  = preCurve2  / max(eps, max(preCurve2));
        postCurve2_norm = postCurve2 / max(eps, max(postCurve2));
        minLen = min(length(preCurve2_norm), length(postCurve2_norm));
        [DTW_longitudinal, ~] = analysis_computeDTW(...
            preCurve2_norm(1:minLen), postCurve2_norm(1:minLen));
    end
catch
    DTW_longitudinal = NaN;
end

%% 4. 文献阈值判定 — 场使用已验证切点，不用自创 Sigmoid
% 参考: Yamauchi 2017 [J Neurosurg]: preTTS > 3.2s → CHS 高风险
% 参考: Lai et al.: VBI ≥ 2.0 → 显著血流动力学障碍
% 注意：此处用术前 TTS 和 Peak Ratio 评估术前犹如陈山之势

if preTTS >= 3.2
    tts_risk = '🔴 高风险 (术前TTS ≥ 3.2s)';
    tts_ref  = 'Yamauchi 2017: ΔCCT > 3.2s → CHS Specificity 100%';
elseif preTTS >= 1.5
    tts_risk = '🟡 中等风险';
    tts_ref  = '介于 1.5-3.2s，密切观察';
else
    tts_risk = '🟢 低风险 (术前TTS < 1.5s)';
    tts_ref  = '术前时延较小，狭窄功能学意义弱';
end

if prePeakRatio >= 2.0
    pa_risk = '🔴 高风险 (术前衰减 ≥ 2.0×)';
    pa_ref  = 'Lai et al.: VBI ≥ 2.0';
elseif prePeakRatio >= 1.3
    pa_risk = '🟡 中等风险';
    pa_ref  = '衰减存在但低于 Lai 阈值';
else
    pa_risk = '🟢 低风险 (衰减 < 1.3×)';
    pa_ref  = '近远端峰值趋于一致，狭窄功能学意义弱';
end

if contains(tts_risk, '🔴') || contains(pa_risk, '🔴')
    warningLevel = '高危 (CHS红色预警)';
    warningText  = sprintf('⚠️ CHS 高风险: 术前TTS=%.2fs [%s] | 衰减=×%.2f [%s]', ...
        preTTS, tts_risk, prePeakRatio, pa_risk);
elseif contains(tts_risk, '🟡') || contains(pa_risk, '🟡')
    warningLevel = '中危 (密切观察)';
    warningText  = sprintf('⚠️ CHS 中等风险: TTS=%.2fs | 衰减=×%.2f，建议密切观察', preTTS, prePeakRatio);
else
    warningLevel = '低风险 (良性代偿)';
    warningText  = sprintf('✅ 血流动力学改善良好: TTS=%.2fs | 衰减=×%.2f', postTTS, postPeakRatio);
end

advice = {...
    sprintf('█ 术前 TTS: %.2fs   %s', preTTS, tts_ref), ...
    sprintf('  改善: TTS 缩短 %.2fs (术前 %.2fs → 术后 %.2fs)', TTS_Improvement, preTTS, postTTS), ...
    sprintf('█ 术前 Peak Attenuation: ×%.2f   %s', prePeakRatio, pa_ref), ...
    sprintf('  改善: 衰减减小 ×%.2f (术前 ×%.2f → 术后 ×%.2f)', PeakRatio_Improvement, prePeakRatio, postPeakRatio), ...
    sprintf('█ DTW 纵向波形变化: %.4f  (0=完全恢复，越小越好)', DTW_longitudinal), ...
};

%% 5. 数据收集接口 — 为将来逻辑回归验证 D-HSS 准备
% 每个病例的关键参数结构化存储，配合 CHS 临床结局（需手动录入）
% 积累 20-30 例后，可用逻辑回归确定各参数的真实权重
dataRecord = struct();
dataRecord.timestamp            = datestr(now, 'yyyy-mm-dd HH:MM:SS');
dataRecord.preTTS               = preTTS;
dataRecord.postTTS              = postTTS;
dataRecord.TTS_Improvement      = TTS_Improvement;
dataRecord.prePeakRatio         = prePeakRatio;
dataRecord.postPeakRatio        = postPeakRatio;
dataRecord.PA_Improvement       = PeakRatio_Improvement;
dataRecord.DTW_longitudinal     = DTW_longitudinal;
dataRecord.AUC_Change_pct       = AUC_Increase_Ratio;
dataRecord.MTT_Change_pct       = MTT_Improvement;
% CHS_Outcome: 需医生在系统外录入临床结局
%   0 = 无CHS, 1 = 轻度CHS, 2 = 严重CHS
dataRecord.CHS_Outcome          = NaN;  % 待填写
dataRecord.warningLevel         = warningLevel;

%% 6. 组装输出
results = struct();
results.roiNames            = roiNames;
results.preTTS              = preTTS;
results.postTTS             = postTTS;
results.TTS_Improvement     = TTS_Improvement;
results.prePeakRatio        = prePeakRatio;
results.postPeakRatio       = postPeakRatio;
results.PA_Improvement      = PeakRatio_Improvement;
results.DTW_longitudinal    = DTW_longitudinal;
results.AUC_Increase_Ratio  = AUC_Increase_Ratio;
results.MTT_Improvement     = MTT_Improvement;

results.warningLevel        = warningLevel;
results.warningText         = warningText;
results.advice              = advice;
results.tts_risk            = tts_risk;
results.pa_risk             = pa_risk;

results.preParams           = preParams;
results.postParams          = postParams;
results.dataRecord          = dataRecord;

try
    results.preCurve        = preOpData.smoothedLobeData;
    results.postCurve       = postOpData.smoothedLobeData;
    results.t_highres_pre   = preOpData.t_highres;
    results.t_highres_post  = postOpData.t_highres;
catch
end
