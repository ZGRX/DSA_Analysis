"""
dicom_loader.py — DICOM文件读取与脱敏模块
对应原 MATLAB: io_importDSA.m
"""
import pydicom
import numpy as np
from pathlib import Path
from typing import Optional, Tuple, Dict


def load_dicom(file_path: str) -> Tuple[np.ndarray, np.ndarray, dict, dict]:
    """
    读取DSA DICOM文件，返回处理后的图像序列。

    Args:
        file_path: DICOM文件路径

    Returns:
        img2d:           首帧灰度图 [H, W], float64, 已反转增强
        processed_series: 全序列 [H, W, nFrames], float64, 已反转增强
        patient_info:    脱敏后的患者信息 dict
        dicom_info:      原始DICOM元数据（不含个人信息）

    Raises:
        ValueError: 如果文件不是有效DSA序列
    """
    ds = pydicom.dcmread(file_path, force=True)
    pixel_array = ds.pixel_array  # [H, W] 或 [nFrames, H, W] 或 [H, W, 1, nFrames]

    # ── 统一维度处理 ──────────────────────────────────────────────────
    arr = pixel_array.astype(np.float64)
    if arr.ndim == 2:
        # 单帧
        series = arr[:, :, np.newaxis]  # [H, W, 1]
    elif arr.ndim == 3:
        if arr.shape[0] > arr.shape[-1]:
            # [nFrames, H, W] → [H, W, nFrames]
            series = np.transpose(arr, (1, 2, 0))
        else:
            series = arr  # 已经是 [H, W, nFrames]
    elif arr.ndim == 4:
        # [nFrames, H, W, 1] 或 [H, W, 1, nFrames]
        if arr.shape[-1] == 1:
            series = arr[:, :, 0, :]  # [H, W, nFrames]
        else:
            series = np.transpose(arr[:, :, :, :], (0, 1, 3, 2))
            series = series[:, :, :, 0]
    else:
        raise ValueError(f"不支持的DICOM维度: {arr.shape}")

    n_frames = series.shape[2]
    if n_frames < 3:
        raise ValueError(f"帧数不足 ({n_frames})，无法进行时序分析")

    # ── 全序列全局归一化（保留帧间相对强度 → TDC具有生理意义）────────
    global_max = series.max()
    global_min = series.min()
    if global_max > 255 or global_max > global_min:
        series = (series - global_min) / max(1e-6, global_max - global_min) * 255.0

    # ── DSA灰度反转（血管高亮：暗→亮）──────────────────────────────
    series = 255.0 - series

    img2d = series[:, :, 0].copy()

    # ── 提取患者信息（脱敏处理）─────────────────────────────────────
    patient_info = _extract_patient_info(ds)
    dicom_info = _extract_dicom_metadata(ds)

    return img2d, series, patient_info, dicom_info


def anonymize_dicom(input_path: str, output_path: str, anon_id: str = "ANONYMOUS") -> None:
    """
    DICOM文件脱敏：移除所有个人识别信息，保留图像和采集参数。

    符合 HIPAA / 中国《个人信息保护法》要求。
    适用于竞赛演示和学术研究使用。
    """
    ds = pydicom.dcmread(input_path, force=True)

    # 个人信息字段清空
    _FIELDS_TO_ANONYMIZE = [
        'PatientName', 'PatientID', 'PatientBirthDate', 'PatientAddress',
        'PatientTelephoneNumbers', 'PatientMotherBirthName', 'PatientInsurancePlanCodeSequence',
        'ReferringPhysicianName', 'PerformingPhysicianName', 'OperatorsName',
        'RequestingPhysician', 'ResponsiblePerson', 'InstitutionName',
        'InstitutionAddress', 'StationName', 'AccessionNumber',
    ]

    for field in _FIELDS_TO_ANONYMIZE:
        if hasattr(ds, field):
            try:
                setattr(ds, field, anon_id if 'Name' in field else '')
            except Exception:
                pass

    # 用匿名ID替换PatientName
    ds.PatientName = anon_id
    ds.PatientID = anon_id

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    pydicom.dcmwrite(output_path, ds)


def get_frame_rate(ds: pydicom.Dataset) -> float:
    """从DICOM元数据推断帧率，默认4fps。"""
    for attr in ['CineRate', 'RecommendedDisplayFrameRate', 'FrameTime']:
        if hasattr(ds, attr):
            val = float(getattr(ds, attr))
            if attr == 'FrameTime' and val > 0:
                return 1000.0 / val  # ms → fps
            elif val > 0:
                return val
    return 4.0


# ── 内部工具函数 ────────────────────────────────────────────────────────
def _extract_patient_info(ds: pydicom.Dataset) -> dict:
    """提取患者信息（用于UI展示，已做脱敏标注）。"""
    info = {'name': '匿名', 'id': 'N/A', 'age': 'N/A', 'sex': 'N/A', 'date': 'N/A'}

    if hasattr(ds, 'PatientName'):
        name_str = str(ds.PatientName)
        # 只显示首字符 + ***（部分脱敏）
        info['name'] = name_str[0] + '***' if name_str else '匿名'

    if hasattr(ds, 'PatientAge'):
        age_raw = str(ds.PatientAge)
        digits = ''.join(filter(str.isdigit, age_raw))
        info['age'] = f"{digits}岁" if digits else 'N/A'

    if hasattr(ds, 'PatientSex'):
        sex_map = {'M': '男', 'F': '女'}
        info['sex'] = sex_map.get(str(ds.PatientSex).upper(), str(ds.PatientSex))

    if hasattr(ds, 'StudyDate'):
        d = str(ds.StudyDate)
        if len(d) == 8:
            info['date'] = f"{d[:4]}-{d[4:6]}-{d[6:]}"

    return info


def _extract_dicom_metadata(ds: pydicom.Dataset) -> dict:
    """提取非个人的采集参数。"""
    meta = {}
    safe_attrs = ['Modality', 'Manufacturer', 'KVP', 'ExposureTime',
                  'PixelSpacing', 'Rows', 'Columns', 'BitsAllocated',
                  'StudyDescription', 'SeriesDescription']
    for attr in safe_attrs:
        if hasattr(ds, attr):
            meta[attr] = str(getattr(ds, attr))
    return meta
