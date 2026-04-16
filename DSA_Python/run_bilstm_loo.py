"""
run_bilstm_loo.py
=================
功能：
  1. 加载 data/cases/bilstm_dataset.npz
  2. 执行 LOO（留一法）交叉验证
  3. 输出 Accuracy / Sensitivity / Specificity / AUC
  4. 自动生成并保存：
     - 混淆矩阵图（confusion_matrix.png）
     - ROC 曲线图（roc_curve.png）
     - 训练损失曲线图（training_curves.png）
     - 指标汇总 JSON（loo_results.json）

用法：
  python run_bilstm_loo.py
"""

import sys
import json
import numpy as np
from pathlib import Path

# 添加项目根目录到 sys.path
ROOT = Path(__file__).parent
sys.path.insert(0, str(ROOT))

from ai.bilstm_model import CHSTrainer, augment_tdc, DSA_BiLSTM, TDCDataset
import torch

# ── 配置 ──────────────────────────────────────────────────────────────────
DATA_FILE   = ROOT / "data" / "cases" / "bilstm_dataset.npz"
OUTPUT_DIR  = ROOT / "data" / "models"
EPOCHS      = 150
N_AUG       = 20
SEED        = 42

# ── 尝试导入绘图库 ────────────────────────────────────────────────────────
try:
    import matplotlib
    matplotlib.use("Agg")   # 非交互后端（服务器/无界面环境）
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    MATPLOTLIB_OK = True
except ImportError:
    MATPLOTLIB_OK = False
    print("[警告] 未安装 matplotlib，跳过图表生成。pip install matplotlib")

# ── 辅助：ROC 曲线（不依赖 sklearn）────────────────────────────────────────
def compute_roc_auc(true_labels, pred_probs_chs):
    """手动计算 ROC 曲线和 AUC（梯形法则）。"""
    y = np.array([1 if l == "CHS" else 0 for l in true_labels])
    p = np.array(pred_probs_chs)
    thresholds = np.linspace(0, 1, 101)[::-1]
    tpr_list, fpr_list = [], []
    for thr in thresholds:
        pred = (p >= thr).astype(int)
        tp = np.sum((pred == 1) & (y == 1))
        fp = np.sum((pred == 1) & (y == 0))
        fn = np.sum((pred == 0) & (y == 1))
        tn = np.sum((pred == 0) & (y == 0))
        tpr = tp / max(1, tp + fn)
        fpr = fp / max(1, fp + tn)
        tpr_list.append(tpr)
        fpr_list.append(fpr)
    auc = float(np.trapz(tpr_list, fpr_list) * -1)  # FPR 递增方向
    return np.array(fpr_list), np.array(tpr_list), auc


# ── 图表生成 ──────────────────────────────────────────────────────────────
def plot_confusion_matrix(TP, TN, FP, FN, save_path, acc):
    if not MATPLOTLIB_OK:
        return
    fig, ax = plt.subplots(figsize=(5, 4))
    cm = np.array([[TN, FP], [FN, TP]])
    im = ax.imshow(cm, cmap="Blues")
    ax.set_xticks([0, 1]); ax.set_yticks([0, 1])
    ax.set_xticklabels(["Pred: Normal", "Pred: CHS"], fontsize=11)
    ax.set_yticklabels(["True: Normal", "True: CHS"], fontsize=11)
    for i in range(2):
        for j in range(2):
            ax.text(j, i, str(cm[i, j]), ha="center", va="center",
                    fontsize=18, fontweight="bold",
                    color="white" if cm[i, j] > cm.max()/2 else "black")
    ax.set_title(f"Confusion Matrix  (Accuracy = {acc:.1f}%)", fontsize=12, pad=12)
    plt.colorbar(im, ax=ax, shrink=0.8)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  📊 混淆矩阵已保存: {save_path.name}")


def plot_roc_curve(fpr, tpr, auc, save_path):
    if not MATPLOTLIB_OK:
        return
    fig, ax = plt.subplots(figsize=(5, 5))
    ax.plot(fpr, tpr, color="#2196F3", lw=2.5, label=f"BiLSTM (AUC = {auc:.3f})")
    ax.plot([0, 1], [0, 1], "k--", lw=1.2, label="Random Classifier")
    ax.fill_between(fpr, tpr, alpha=0.15, color="#2196F3")
    ax.set_xlabel("False Positive Rate (1 - Specificity)", fontsize=12)
    ax.set_ylabel("True Positive Rate (Sensitivity)", fontsize=12)
    ax.set_title("ROC Curve — CHS Risk Classification\n(LOO Cross-Validation)", fontsize=12)
    ax.legend(loc="lower right", fontsize=11)
    ax.set_xlim([-0.02, 1.02]); ax.set_ylim([-0.02, 1.02])
    ax.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  📈 ROC曲线已保存: {save_path.name}")


def plot_training_summary(all_histories, save_path):
    """绘制所有 LOO 折叠的平均损失曲线。"""
    if not MATPLOTLIB_OK or not all_histories:
        return
    max_len = max(len(h['loss']) for h in all_histories)
    loss_matrix = np.full((len(all_histories), max_len), np.nan)
    acc_matrix  = np.full((len(all_histories), max_len), np.nan)
    for i, h in enumerate(all_histories):
        n = len(h['loss'])
        loss_matrix[i, :n] = h['loss']
        acc_matrix[i, :n]  = h['acc']

    mean_loss = np.nanmean(loss_matrix, axis=0)
    mean_acc  = np.nanmean(acc_matrix, axis=0)

    fig, axes = plt.subplots(1, 2, figsize=(10, 4))
    epochs = np.arange(1, max_len + 1)

    axes[0].plot(epochs, mean_loss, color="#E53935", lw=2)
    axes[0].fill_between(epochs,
                          np.nanmin(loss_matrix, axis=0),
                          np.nanmax(loss_matrix, axis=0),
                          alpha=0.2, color="#E53935")
    axes[0].set_title("Training Loss (LOO Mean ± Range)", fontsize=12)
    axes[0].set_xlabel("Epoch"); axes[0].set_ylabel("Cross-Entropy Loss")
    axes[0].grid(alpha=0.3)

    axes[1].plot(epochs, mean_acc, color="#43A047", lw=2)
    axes[1].fill_between(epochs,
                          np.nanmin(acc_matrix, axis=0),
                          np.nanmax(acc_matrix, axis=0),
                          alpha=0.2, color="#43A047")
    axes[1].set_title("Training Accuracy (LOO Mean ± Range)", fontsize=12)
    axes[1].set_xlabel("Epoch"); axes[1].set_ylabel("Accuracy (%)")
    axes[1].set_ylim([0, 105])
    axes[1].grid(alpha=0.3)

    plt.suptitle("BiLSTM CHS Risk Classifier — Training Curves", fontsize=13, y=1.02)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  📉 训练曲线已保存: {save_path.name}")


# ── 主流程 ────────────────────────────────────────────────────────────────
def main():
    print("=" * 55)
    print("  BiLSTM CHS分类器 — LOO交叉验证")
    print("=" * 55)

    if not DATA_FILE.exists():
        print(f"[错误] 数据集不存在，请先运行 prepare_bilstm_data.py")
        print(f"  期望路径: {DATA_FILE}")
        return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 加载数据
    dataset  = np.load(DATA_FILE, allow_pickle=True)
    tdc_arr  = dataset['tdc']            # [N, 2, seq_len]
    labels   = dataset['labels'].tolist()
    patients = dataset['patients'].tolist()
    sources  = dataset['sources'].tolist()

    n = len(labels)
    print(f"\n数据集: {n} 名患者")
    print(f"CHS: {labels.count('CHS')}  |  Normal: {labels.count('Normal')}")
    data_src_note = f"真实TDC: {sources.count('real')}  |  合成TDC: {sources.count('synthetic')}"
    print(data_src_note)
    print()

    tdc_list = [tdc_arr[i] for i in range(n)]

    trainer      = CHSTrainer()
    loo_preds    = []
    loo_true     = labels[:]
    loo_probs    = []   # CHS 置信度（用于 ROC）
    all_histories = []

    for leave_out in range(n):
        pid = patients[leave_out]
        print(f"[第{leave_out+1}/{n}折] 留出 {pid} ({labels[leave_out]})", end=" ... ")

        # 训练集
        train_X = [tdc_list[i] for i in range(n) if i != leave_out]
        train_Y = [labels[i]   for i in range(n) if i != leave_out]
        aug_X, aug_Y = augment_tdc(train_X, train_Y, n_aug=N_AUG)

        net, metrics = trainer.train(
            aug_X, aug_Y,
            n_aug=0, epochs=EPOCHS,
            batch_size=16,
        )
        all_histories.append(metrics['history'])

        # 推理
        net.eval()
        with torch.no_grad():
            x_test = torch.tensor(
                tdc_list[leave_out][np.newaxis], dtype=torch.float32
            ).to(trainer.device)
            logits = net(x_test)
            probs  = torch.softmax(logits, dim=1).cpu().numpy()[0]
            pred_idx = int(np.argmax(probs))
            pred_label = TDCDataset.IDX_MAP[pred_idx]
            chs_prob   = float(probs[1])   # CHS 类概率

        loo_preds.append(pred_label)
        loo_probs.append(chs_prob)

        correct = "✅" if pred_label == labels[leave_out] else "❌"
        print(f"预测={pred_label} (CHS概率={chs_prob:.2f}) {correct}")

    # ── 计算指标 ─────────────────────────────────────────────────────────
    TP = sum(t == "CHS"    and p == "CHS"    for t, p in zip(loo_true, loo_preds))
    TN = sum(t == "Normal" and p == "Normal" for t, p in zip(loo_true, loo_preds))
    FP = sum(t == "Normal" and p == "CHS"    for t, p in zip(loo_true, loo_preds))
    FN = sum(t == "CHS"    and p == "Normal" for t, p in zip(loo_true, loo_preds))

    acc  = (TP + TN) / n * 100
    sens = TP / max(1, TP + FN) * 100
    spec = TN / max(1, TN + FP) * 100
    ppv  = TP / max(1, TP + FP) * 100

    fpr, tpr, auc = compute_roc_auc(loo_true, loo_probs)

    # ── 输出结果 ─────────────────────────────────────────────────────────
    print("\n" + "=" * 55)
    print("  LOO 交叉验证结果")
    print("=" * 55)
    print(f"  Accuracy    : {acc:.1f}%")
    print(f"  Sensitivity : {sens:.1f}%  (检测率)")
    print(f"  Specificity : {spec:.1f}%  (特异性)")
    print(f"  Precision   : {ppv:.1f}%")
    print(f"  AUC-ROC     : {auc:.3f}")
    print(f"  TP={TP}  TN={TN}  FP={FP}  FN={FN}  (N={n})")
    print(f"\n  数据来源: {data_src_note}")
    print("=" * 55)

    # ── 生成图表 ─────────────────────────────────────────────────────────
    print("\n生成可视化图表...")
    plot_confusion_matrix(TP, TN, FP, FN,
                          OUTPUT_DIR / "confusion_matrix.png", acc)
    plot_roc_curve(fpr, tpr, auc,
                   OUTPUT_DIR / "roc_curve.png")
    plot_training_summary(all_histories,
                          OUTPUT_DIR / "training_curves.png")

    # ── 保存 JSON 结果 ────────────────────────────────────────────────────
    results = {
        "method":      "BiLSTM LOO Cross-Validation",
        "n_patients":  n,
        "data_source": data_src_note,
        "metrics": {
            "accuracy_pct":    round(acc, 1),
            "sensitivity_pct": round(sens, 1),
            "specificity_pct": round(spec, 1),
            "precision_pct":   round(ppv, 1),
            "auc_roc":         round(auc, 3),
        },
        "confusion_matrix": {"TP": TP, "TN": TN, "FP": FP, "FN": FN},
        "per_patient": [
            {"patient": p, "true": t, "pred": pr, "chs_prob": round(prob, 3)}
            for p, t, pr, prob in zip(patients, loo_true, loo_preds, loo_probs)
        ],
    }
    json_path = OUTPUT_DIR / "loo_results.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print(f"  💾 指标汇总已保存: {json_path.name}")
    print("\n✅ 全部完成！图表在:", OUTPUT_DIR)


if __name__ == "__main__":
    main()
