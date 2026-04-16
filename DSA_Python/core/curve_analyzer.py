"""
curve_analyzer.py — TDC曲线拟合与灌注参数计算
对应原 MATLAB: analysis_analyzeCurves.m

计算指标:
    TTP  (Time To Peak)         达峰时间
    MTT  (Mean Transit Time)    平均通过时间
    TU   (Time of Upslope)      造影剂到达时间
    FWHM (Full Width Half Max)  半峰宽（波形弥散度）
    AUC  (Area Under Curve)     曲线下面积（相对血容量）
    Peak (Max Intensity)        峰值浓度
    WFD  (Waveform Form Distortion) 波形失真指数 (原DTW)
    TTS  (Time To Stenosis)     跨狭窄时移 = distal.TTP - proximal.TTP
"""
import numpy as np
from scipy.interpolate import PchipInterpolator
from scipy.integrate import trapezoid
from dataclasses import dataclass
from typing import Tuple, Optional


@dataclass
class PerfusionParams:
    """单端TDC的灌注参数。"""
    TTP:  float   # 达峰时间 (s)
    MTT:  float   # 平均通过时间 (s)
    TU:   float   # 造影剂到达时间 (s)
    FWHM: float   # 半峰宽 (s)
    AUC:  float   # 曲线下面积
    Peak: float   # 峰值强度


@dataclass
class DualEndpointResult:
    """双端分析结果（狭窄近端 + 远端）。"""
    proximal:   PerfusionParams
    distal:     PerfusionParams
    TTS:        float   # 跨狭窄时移 (s) = distal.TTP - proximal.TTP
    peak_ratio: float   # 近端/远端峰值衰减比
    WFD:        float   # 波形失真指数 (DTW距离)
    fwhm_inv:   bool    # FWHM是否倒置（近端>远端，提示严重狭窄）
    t_highres:  np.ndarray   # 高分辨率时间轴
    curves:     np.ndarray   # 平滑后双端曲线 [2, nPoints]


def analyze_curves(
    time_series: np.ndarray,
    frame_rate: float = 4.0,
    n_interp: int = 500
) -> DualEndpointResult:
    """
    对双端TDC时间序列进行高阶PCHIP插值拟合，计算所有灌注参数。

    Args:
        time_series: [2, nFrames] 双端TDC原始数据，行0=近端，行1=远端
        frame_rate:  采集帧率 (fps)
        n_interp:    PCHIP高分辨率插值点数

    Returns:
        DualEndpointResult 双端完整参数
    """
    assert time_series.shape[0] == 2, "time_series必须是2行(近端/远端)"
    n_frames = time_series.shape[1]
    t_raw = np.arange(n_frames) / frame_rate
    t_hi  = np.linspace(t_raw[0], t_raw[-1], n_interp)

    params_list = []
    curves_hi   = np.zeros((2, n_interp))

    for i in range(2):
        raw = time_series[i].astype(np.float64)
        # PCHIP单调保形插值（保留波形局部特征，防止龙格现象）
        pchip = PchipInterpolator(t_raw, raw)
        curve = pchip(t_hi)
        curves_hi[i] = curve
        params_list.append(_compute_single_params(curve, t_hi))

    # WFD（波形失真指数）= 归一化DTW距离
    wfd = _compute_dtw(curves_hi[0], curves_hi[1])

    tts        = max(0.0, params_list[1].TTP - params_list[0].TTP)
    peak_ratio = params_list[0].Peak / max(1e-9, params_list[1].Peak)
    fwhm_inv   = params_list[0].FWHM > params_list[1].FWHM

    return DualEndpointResult(
        proximal=params_list[0],
        distal=params_list[1],
        TTS=tts,
        peak_ratio=peak_ratio,
        WFD=wfd,
        fwhm_inv=fwhm_inv,
        t_highres=t_hi,
        curves=curves_hi,
    )


def classify_risk(result: DualEndpointResult) -> Tuple[str, str, float]:
    """
    基于Yamauchi 2017阈值进行TTS三级风险分层。

    Returns:
        (risk_tier, risk_label, chs_prob_pct)
        risk_tier: 'HIGH' | 'MODERATE' | 'LOW'
    """
    TTS = result.TTS
    PR  = result.peak_ratio

    # Logistic评分（Yamauchi 2017 + Lai et al. 参数）
    w0, w1, w2 = -2.80, 1.20, 0.85
    logit = w0 + w1 * (TTS / 3.2) + w2 * (PR / 2.0)
    prob  = 1.0 / (1.0 + np.exp(-logit))

    if TTS >= 5.0:
        tier  = 'HIGH'
        label = f'🔴 极高风险 | TTS={TTS:.2f}s | CHS概率 {prob*100:.0f}%'
    elif TTS >= 3.2:
        tier  = 'MODERATE'
        label = f'🟡 中高风险 | TTS={TTS:.2f}s | CHS概率 {prob*100:.0f}%'
    else:
        tier  = 'LOW'
        label = f'🟢 低风险   | TTS={TTS:.2f}s | CHS概率 {prob*100:.0f}%'

    return tier, label, prob * 100.0


# ── 内部函数 ────────────────────────────────────────────────────────────
def _compute_single_params(curve: np.ndarray, t: np.ndarray) -> PerfusionParams:
    """计算单端TDC的所有灌注参数。"""
    max_val = curve.max()
    max_idx = int(np.argmax(curve))
    TTP = t[max_idx]

    # 基线（前10%帧均值）
    b_end = max(2, int(len(curve) * 0.10))
    baseline = curve[:b_end].mean()

    # TU（造影剂上升阈值：baseline + 10%峰）
    thresh = baseline + 0.10 * max(1.0, max_val - baseline)
    tu_candidates = np.where(curve > thresh)[0]
    TU = t[tu_candidates[0]] if len(tu_candidates) > 0 else TTP

    # AUC（基线校正后梯形积分）
    c_corr = np.maximum(0, curve - baseline)
    AUC = float(trapezoid(c_corr, t))

    # MTT（累积AUC中位置时间）
    cum_auc = np.cumsum(c_corr) * (t[1] - t[0])
    total_auc = cum_auc[-1]
    if total_auc > 0:
        mtt_candidates = np.where(cum_auc >= total_auc / 2)[0]
        MTT = t[mtt_candidates[0]] if len(mtt_candidates) > 0 else TTP
    else:
        MTT = TTP

    # FWHM（全距半峰宽）
    half_peak = baseline + (max_val - baseline) / 2.0
    left_candidates  = np.where(curve[:max_idx+1] >= half_peak)[0]
    right_candidates = np.where(curve[max_idx:] <= half_peak)[0]
    left_idx  = left_candidates[0]  if len(left_candidates)  > 0 else 0
    right_idx = right_candidates[0] + max_idx if len(right_candidates) > 0 else len(curve)-1
    FWHM = float(t[right_idx] - t[left_idx])

    return PerfusionParams(TTP=float(TTP), MTT=float(MTT), TU=float(TU),
                           FWHM=max(0.0, FWHM), AUC=AUC, Peak=float(max_val))


def _compute_dtw(seq1: np.ndarray, seq2: np.ndarray) -> float:
    """
    计算DTW（动态时间规整）距离作为WFD波形失真指数。
    使用O(n)空间优化的动态规划实现。
    """
    n, m = len(seq1), len(seq2)
    # 归一化到[0,1]
    def norm(s): return (s - s.min()) / max(1e-9, s.max() - s.min())
    a, b = norm(seq1), norm(seq2)

    prev = np.full(m + 1, np.inf)
    prev[0] = 0.0
    for i in range(1, n + 1):
        curr = np.full(m + 1, np.inf)
        for j in range(1, m + 1):
            cost = abs(a[i-1] - b[j-1])
            curr[j] = cost + min(prev[j], curr[j-1], prev[j-1])
        prev = curr
    return float(prev[m]) / max(n, m)  # 归一化至[0,1]范围
