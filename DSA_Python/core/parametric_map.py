"""
parametric_map.py — 全脑像素级参数图计算
对应原 MATLAB: analysis_computeParametricMap.m

输出参数图:
    TTP_map:  达峰时间图
    AUC_map:  曲线下面积图（相对血容量）
    vessel_mask: 血管区域掩膜（大津法）
"""
import numpy as np
from scipy.ndimage import gaussian_filter
from skimage.filters import threshold_otsu
from skimage.morphology import remove_small_objects, binary_dilation, disk
from typing import Tuple, Optional
from dataclasses import dataclass


@dataclass
class ParametricMaps:
    """全脑像素级参数图集合。"""
    TTP_map:     np.ndarray   # [H, W] 达峰时间 (s)
    AUC_map:     np.ndarray   # [H, W] 曲线下面积
    vessel_mask: np.ndarray   # [H, W] bool 血管掩膜
    peak_map:    np.ndarray   # [H, W] 峰值强度图


def compute_parametric_maps(
    series: np.ndarray,
    frame_rate: float = 4.0,
    margin_ratio: float = 0.06,
    min_vessel_area: int = 30,
) -> ParametricMaps:
    """
    向量化计算全脑像素级TTP/AUC参数图。

    Args:
        series:       [H, W, nFrames] DSA序列，已反转归一化
        frame_rate:   采集帧率 (fps)
        margin_ratio: 边缘排除比例（防止DSA边框伪影）
        min_vessel_area: 最小血管连通域面积（像素），小于此值视为噪声

    Returns:
        ParametricMaps 包含TTP/AUC/vessel_mask/peak_map
    """
    H, W, nF = series.shape
    dt = 1.0 / frame_rate

    # ── 1. 基线校正（前10%帧作为基线）────────────────────────────────
    b_frames = max(2, int(nF * 0.10))
    baseline = series[:, :, :b_frames].mean(axis=2, keepdims=True)  # [H, W, 1]
    corrected = np.maximum(0.0, series - baseline)  # [H, W, nF]

    # ── 2. 向量化计算TTP（达峰时间）──────────────────────────────────
    max_idx_flat  = np.argmax(corrected, axis=2)          # [H, W]
    TTP_map       = max_idx_flat.astype(np.float32) * dt  # (s)
    peak_map      = corrected.max(axis=2)                 # [H, W]

    # ── 3. 向量化计算AUC（梯形积分）──────────────────────────────────
    # 梯形法: AUC ≈ dt/2 * (sum of f[i]+f[i+1])
    AUC_map = dt * (corrected[:, :, :-1] + corrected[:, :, 1:]).sum(axis=2) / 2.0

    # ── 4. 血管掩膜（大津法 + 形态学清洗）────────────────────────────
    vessel_mask = _compute_vessel_mask(AUC_map, peak_map, margin_ratio, min_vessel_area, H, W)

    # ── 5. 边缘像素清零（防止DSA边框污染参数图）─────────────────────
    my = max(5, int(H * margin_ratio))
    mx = max(5, int(W * margin_ratio))
    TTP_map  [:my, :]  = 0; TTP_map  [-my:, :] = 0
    TTP_map  [:, :mx]  = 0; TTP_map  [:, -mx:] = 0
    AUC_map  [:my, :]  = 0; AUC_map  [-my:, :] = 0
    AUC_map  [:, :mx]  = 0; AUC_map  [:, -mx:] = 0

    return ParametricMaps(
        TTP_map=TTP_map,
        AUC_map=AUC_map,
        vessel_mask=vessel_mask,
        peak_map=peak_map,
    )


def extract_tdc_from_roi(series: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """
    从给定的ROI掩膜中提取时间密度曲线（TDC）。

    Args:
        series: [H, W, nFrames]
        mask:   [H, W] bool

    Returns:
        tdc: [nFrames] 均值TDC
    """
    assert mask.dtype == bool or mask.max() <= 1, "mask必须是bool类型"
    mask_bool = mask.astype(bool)
    if not mask_bool.any():
        raise ValueError("ROI掩膜为空，请重新选择区域")

    # 取ROI内所有像素的均值
    n_frames = series.shape[2]
    tdc = np.zeros(n_frames)
    for f in range(n_frames):
        tdc[f] = series[:, :, f][mask_bool].mean()
    return tdc


def auto_detect_stenosis(maps: ParametricMaps) -> Tuple[int, int, int, int, int, int]:
    """
    基于TTP梯度自动检测狭窄位置，返回近端/狭窄/远端坐标。
    对应原 MATLAB: analysis_autoROI.m

    Returns:
        (stenosis_row, stenosis_col, prox_row, prox_col, dist_row, dist_col)
    """
    H, W = maps.TTP_map.shape
    margin_y = max(20, int(H * 0.06))
    margin_x = max(20, int(W * 0.06))

    # 平滑TTP图
    ttp_smooth = gaussian_filter(maps.TTP_map.astype(np.float64), sigma=3)
    ttp_smooth[~maps.vessel_mask] = 0

    # 只在高AUC血管区且排除边缘
    auc_norm = (maps.AUC_map - maps.AUC_map.min()) / max(1e-6, maps.AUC_map.max() - maps.AUC_map.min())
    auc_thresh    = np.percentile(auc_norm[auc_norm > 0], 60) if auc_norm.max() > 0 else 0.1
    strict_mask = maps.vessel_mask & (auc_norm > auc_thresh)
    strict_mask[:margin_y, :]  = False
    strict_mask[-margin_y:, :] = False
    strict_mask[:, :margin_x]  = False
    strict_mask[:, -margin_x:] = False

    # Sobel梯度
    from scipy.ndimage import sobel
    gx = sobel(ttp_smooth, axis=1)
    gy = sobel(ttp_smooth, axis=0)
    grad_mag = np.sqrt(gx**2 + gy**2)
    grad_mag[~strict_mask] = 0

    if grad_mag.max() == 0:
        # fallback: 返回图像中心及±10%偏移
        sr, sc = H // 2, W // 2
    else:
        flat_idx = np.argmax(grad_mag)
        sr, sc   = np.unravel_index(flat_idx, (H, W))

    # 梯度方向
    dx = gx[sr, sc] / max(1e-6, grad_mag[sr, sc])
    dy = gy[sr, sc] / max(1e-6, grad_mag[sr, sc])

    offset = int(min(H, W) * 0.10)
    pr = int(np.clip(sr - dy * offset, margin_y, H - margin_y))
    pc = int(np.clip(sc - dx * offset, margin_x, W - margin_x))
    dr = int(np.clip(sr + dy * offset, margin_y, H - margin_y))
    dc = int(np.clip(sc + dx * offset, margin_x, W - margin_x))

    # 确保近端TTP < 远端TTP
    if maps.TTP_map[pr, pc] > maps.TTP_map[dr, dc]:
        pr, pc, dr, dc = dr, dc, pr, pc

    return int(sr), int(sc), pr, pc, dr, dc


# ── 内部工具 ────────────────────────────────────────────────────────────
def _compute_vessel_mask(
    AUC_map: np.ndarray,
    peak_map: np.ndarray,
    margin_ratio: float,
    min_area: int,
    H: int, W: int
) -> np.ndarray:
    """大津法生成血管掩膜，并做形态学清洗。"""
    # 归一化AUC用于阈值
    auc_norm = (AUC_map - AUC_map.min()) / max(1e-6, AUC_map.max() - AUC_map.min())
    peak_norm = (peak_map - peak_map.min()) / max(1e-6, peak_map.max() - peak_map.min())

    # 联合特征（AUC + Peak）
    combined = 0.6 * auc_norm + 0.4 * peak_norm

    # 大津法阈值
    try:
        thresh = threshold_otsu(combined)
    except Exception:
        thresh = 0.05
    mask = combined > thresh

    # 边缘清除
    my = max(3, int(H * margin_ratio))
    mx = max(3, int(W * margin_ratio))
    mask[:my, :]  = False; mask[-my:, :] = False
    mask[:, :mx]  = False; mask[:, -mx:] = False

    # 连通域过滤噪点
    try:
        mask = remove_small_objects(mask, min_size=min_area)
    except Exception:
        pass

    return mask
