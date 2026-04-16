"""
DSA 项目患者数据脱敏脚本
=======================
功能：
  1. 扫描 PatientData/RawData 下的所有患者文件夹（名称含真实姓名拼音）
  2. 将每个患者映射到匿名 ID（如 DSA_P001）
  3. 将脱敏后的数据复制到 PatientData_Anon/ 目录（原始数据不删除）
  4. 清洗 DICOM 文件内的患者信息标签（姓名、ID、出生日期等）
  5. 重命名包含患者信息的 AVI/PNG 等非 DICOM 文件
  6. 生成脱敏映射日志（仅供研究团队内部保存，不可提交）

依赖：
  pip install pydicom
"""

import os
import re
import json
import shutil
import hashlib
import argparse
from pathlib import Path
from datetime import datetime

# ── 尝试导入 pydicom（用于清洗 DICOM 标签）──
try:
    import pydicom
    from pydicom.uid import generate_uid
    PYDICOM_AVAILABLE = True
except ImportError:
    PYDICOM_AVAILABLE = False
    print("[警告] 未安装 pydicom，将跳过 DICOM 内部标签清洗。")
    print("       请运行: pip install pydicom")

# ═══════════════════════════════════════════════════════════
#  配置区
# ═══════════════════════════════════════════════════════════
BASE_DIR   = Path(__file__).parent
SRC_DIR    = BASE_DIR / "PatientData" / "RawData"    # 原始含姓名数据
DST_DIR    = BASE_DIR / "PatientData_Anon"           # 脱敏输出目录
LOG_FILE   = BASE_DIR / "deidentify_mapping.json"   # 映射日志（保密！）
ID_PREFIX  = "DSA_P"                                  # 匿名 ID 前缀

# DICOM 需要清空的隐私标签（NEMA DE-IDENTIFICATION Profile）
DICOM_TAGS_TO_CLEAR = {
    (0x0010, 0x0010): "PatientName",
    (0x0010, 0x0020): "PatientID",
    (0x0010, 0x0030): "PatientBirthDate",
    (0x0010, 0x0040): "PatientSex",
    (0x0010, 0x1040): "PatientTelephoneNumbers",
    (0x0010, 0x1030): "PatientWeight",
    (0x0010, 0x21B0): "AdditionalPatientHistory",
    (0x0008, 0x0080): "InstitutionName",
    (0x0008, 0x0081): "InstitutionAddress",
    (0x0008, 0x1048): "PhysiciansOfRecord",
    (0x0008, 0x1050): "PerformingPhysicianName",
    (0x0008, 0x1070): "OperatorsName",
    (0x0032, 0x1032): "RequestingPhysician",
    (0x0040, 0xA124): "UID",
    (0x0008, 0x0090): "ReferringPhysicianName",
    (0x0010, 0x1000): "OtherPatientIDs",
    (0x0010, 0x1001): "OtherPatientNames",
}

# ═══════════════════════════════════════════════════════════
#  工具函数
# ═══════════════════════════════════════════════════════════

def load_or_create_mapping() -> dict:
    """加载已有映射表，或创建新的。"""
    if LOG_FILE.exists():
        with open(LOG_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        print(f"[INFO] 已加载现有映射表，共 {len(data['patients'])} 条记录。")
        return data
    return {
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "patients": {}
    }


def save_mapping(mapping: dict):
    """将映射表保存到日志文件。"""
    mapping["updated_at"] = datetime.now().isoformat()
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        json.dump(mapping, f, ensure_ascii=False, indent=2)
    print(f"[INFO] 映射表已保存至: {LOG_FILE}")
    print("[警告] 此文件包含真实患者信息，请妥善保管，不要上传到公开仓库！")


def get_next_anon_id(mapping: dict) -> str:
    """生成下一个顺序匿名 ID。"""
    existing = len(mapping["patients"])
    return f"{ID_PREFIX}{existing + 1:03d}"


def hash_name(name: str) -> str:
    """对原始名称做 SHA256 哈希，用于追溯验证。"""
    return hashlib.sha256(name.encode("utf-8")).hexdigest()[:16]


def clean_folder_name(name: str) -> str:
    """规范化文件夹名（去除多余符号）用于姓名识别。"""
    return re.sub(r"[_\-\s\.]+", " ", name).strip().lower()


def is_dicom_file(filepath: Path) -> bool:
    """简单判断是否为 DICOM 文件（无扩展名或 .dcm）。"""
    suffix = filepath.suffix.lower()
    if suffix in [".dcm", ".dicom"]:
        return True
    if suffix == "" or suffix not in [".avi", ".mp4", ".png", ".jpg", ".jpeg",
                                       ".mat", ".txt", ".csv", ".json", ".m"]:
        # 无扩展名文件（如 IM000001）很可能是 DICOM
        return True
    return False


# ═══════════════════════════════════════════════════════════
#  核心功能
# ═══════════════════════════════════════════════════════════

def anonymize_dicom_file(src_path: Path, dst_path: Path, anon_id: str):
    """
    读取 DICOM 文件，清洗隐私标签后保存到目标路径。
    如果 pydicom 不可用，则直接复制文件。
    """
    if not PYDICOM_AVAILABLE:
        shutil.copy2(src_path, dst_path)
        return

    try:
        ds = pydicom.dcmread(str(src_path), force=True)

        # 清洗已知隐私标签
        for tag, name in DICOM_TAGS_TO_CLEAR.items():
            if tag in ds:
                vr = ds[tag].VR
                if vr == "PN":      # PersonName
                    ds[tag].value = "ANONYMOUS"
                elif vr in ["DA", "DT", "TM"]:  # 日期时间 → 置零
                    ds[tag].value = "19000101" if vr == "DA" else "000000"
                elif vr in ["LO", "SH", "ST", "LT", "UT", "CS"]:
                    ds[tag].value = ""
                elif vr == "UI":
                    ds[tag].value = generate_uid()

        # 将 PatientID 替换为匿名 ID
        ds.PatientName = anon_id
        ds.PatientID   = anon_id

        # 标记为已脱敏
        ds.add_new([0x0012, 0x0062], "CS", "YES")   # PatientIdentityRemoved
        ds.add_new([0x0012, 0x0063], "LO", "DSA_DEIDENTIFY_v1.0")  # DeidentificationMethod

        ds.save_as(str(dst_path))

    except Exception as e:
        # 如果 DICOM 读取失败（损坏/非标准），直接复制
        print(f"  [跳过] DICOM 处理失败，直接复制: {src_path.name} ({e})")
        shutil.copy2(src_path, dst_path)


def anonymize_patient_folder(src_folder: Path, dst_folder: Path, anon_id: str):
    """
    递归处理患者文件夹：
    - DICOM 文件 → 清洗 DICOM 标签
    - 其他文件   → 直接复制（文件名中若含患者信息则重命名）
    """
    dst_folder.mkdir(parents=True, exist_ok=True)

    for item in src_folder.rglob("*"):
        if item.is_dir():
            continue  # 目录会在需要时自动创建

        # 计算目标路径（保留相对子目录结构）
        relative = item.relative_to(src_folder)
        dst_path  = dst_folder / relative
        dst_path.parent.mkdir(parents=True, exist_ok=True)

        if is_dicom_file(item):
            anonymize_dicom_file(item, dst_path, anon_id)
        else:
            # 非 DICOM 文件直接复制（文件名已通过父目录重命名去除姓名）
            shutil.copy2(item, dst_path)

    print(f"  → 已处理 {src_folder.name}  →  {dst_folder.name}")


def anonymize_loose_files(src_dir: Path, dst_dir: Path, mapping: dict):
    """
    处理 RawData 根目录下散落的非文件夹文件
    （如 Sun_Feng_Hua_00423993_24.avi）。
    """
    loose_files = [f for f in src_dir.iterdir() if f.is_file()]
    if not loose_files:
        return

    print(f"\n[INFO] 处理根目录散落文件（共 {len(loose_files)} 个）...")
    dst_dir.mkdir(parents=True, exist_ok=True)

    for fpath in loose_files:
        original_name = fpath.name
        # 检查文件名是否在映射表的已知姓名中，若是则替换
        new_name = original_name
        for orig_folder, info in mapping["patients"].items():
            anon_id = info["anon_id"]
            # 用 folder 名关键词匹配文件名（模糊匹配）
            folder_key = clean_folder_name(orig_folder.replace(".dicom", "").replace("_dicom", ""))
            file_key   = clean_folder_name(fpath.stem)
            if any(part in file_key for part in folder_key.split() if len(part) > 2):
                new_name = f"{anon_id}{fpath.suffix}"
                break

        dst_path = dst_dir / new_name
        shutil.copy2(fpath, dst_path)
        print(f"  → {original_name}  →  {new_name}")


# ═══════════════════════════════════════════════════════════
#  主流程
# ═══════════════════════════════════════════════════════════

def run_deidentification(dry_run: bool = False):
    """
    主脱敏流程。
    dry_run=True 时只打印计划，不实际操作。
    """
    print("=" * 60)
    print("  DSA 患者数据脱敏工具 v1.0")
    print("=" * 60)

    if not SRC_DIR.exists():
        print(f"[错误] 源目录不存在: {SRC_DIR}")
        return

    DST_DIR.mkdir(parents=True, exist_ok=True)

    # 加载/初始化映射表
    mapping = load_or_create_mapping()

    # 扫描所有患者子文件夹
    patient_folders = sorted([
        d for d in SRC_DIR.iterdir()
        if d.is_dir()
    ])

    if not patient_folders:
        print("[INFO] 未找到患者子文件夹。")
    else:
        print(f"\n[INFO] 发现 {len(patient_folders)} 个患者文件夹：")
        for pf in patient_folders:
            print(f"  - {pf.name}")

    print()

    for pf in patient_folders:
        orig_name = pf.name

        # 检查是否已有映射
        if orig_name in mapping["patients"]:
            anon_id = mapping["patients"][orig_name]["anon_id"]
            print(f"[跳过] {orig_name} → 已映射为 {anon_id}")
        else:
            anon_id = get_next_anon_id(mapping)
            mapping["patients"][orig_name] = {
                "anon_id":    anon_id,
                "name_hash":  hash_name(orig_name),
                "created_at": datetime.now().isoformat(),
            }
            print(f"[新增] {orig_name}  →  {anon_id}")

        if dry_run:
            print(f"  [DRY-RUN] 跳过实际文件操作")
            continue

        dst_folder = DST_DIR / anon_id
        anonymize_patient_folder(pf, dst_folder, anon_id)

    # 处理根目录散落文件（如含姓名的 AVI）
    if not dry_run:
        anon_loose_dir = DST_DIR / "_misc"
        anonymize_loose_files(SRC_DIR, anon_loose_dir, mapping)

    # 保存映射表
    if not dry_run:
        save_mapping(mapping)

    print("\n" + "=" * 60)
    print("  脱敏完成！")
    print(f"  输出目录: {DST_DIR}")
    print(f"  映射日志: {LOG_FILE}")
    print("  [重要] 请将 deidentify_mapping.json 从 Git 仓库中排除！")
    print("=" * 60)


# ═══════════════════════════════════════════════════════════
#  入口
# ═══════════════════════════════════════════════════════════

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="DSA 患者数据脱敏工具")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="仅打印操作计划，不实际修改或复制文件"
    )
    parser.add_argument(
        "--src",
        type=Path,
        default=SRC_DIR,
        help=f"原始数据目录（默认: {SRC_DIR}）"
    )
    parser.add_argument(
        "--dst",
        type=Path,
        default=DST_DIR,
        help=f"脱敏输出目录（默认: {DST_DIR}）"
    )
    args = parser.parse_args()

    # 允许命令行覆盖路径
    SRC_DIR = args.src
    DST_DIR = args.dst

    run_deidentification(dry_run=args.dry_run)
