"""
bilstm_model.py — BiLSTM深度学习CHS风险分类器（PyTorch）
对应原 MATLAB: ai_train1DCNN.m

网络架构:
    输入: 双端TDC序列 [batch, 2, 100 timepoints]
    BiLSTM → Dropout → FC → Softmax
    输出: 二分类 (HIGH_RISK / LOW_RISK)
"""
import torch
import torch.nn as nn
import numpy as np
from torch.utils.data import Dataset, DataLoader
from typing import List, Tuple, Optional, Dict
from dataclasses import dataclass
import json
from pathlib import Path


# ── 网络定义 ────────────────────────────────────────────────────────────
class DSA_BiLSTM(nn.Module):
    """
    双向LSTM用于DSA双端血流时序分类。

    输入形状: (batch, n_channels=2, seq_len=100)
    输出形状: (batch, n_classes=2)
    """
    def __init__(self, input_size: int = 2, hidden_size: int = 32,
                 num_layers: int = 2, dropout: float = 0.4):
        super().__init__()
        self.bilstm = nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            batch_first=True,
            bidirectional=True,
            dropout=dropout if num_layers > 1 else 0.0,
        )
        lstm_out_size = hidden_size * 2  # × 2 因为是双向

        self.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(lstm_out_size, 16),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(16, 2),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: (batch, channels=2, seq_len=100) → 转为 (batch, seq_len, channels)
        x = x.permute(0, 2, 1)
        out, _ = self.bilstm(x)          # (batch, seq_len, hidden*2)
        last    = out[:, -1, :]           # 取最后时间步
        logits  = self.classifier(last)   # (batch, 2)
        return logits


# ── 数据集 ──────────────────────────────────────────────────────────────
class TDCDataset(Dataset):
    """双端TDC数据集。"""
    CLASS_MAP = {'Normal': 0, 'CHS': 1}
    IDX_MAP   = {0: 'Normal', 1: 'CHS'}

    def __init__(self, tdc_list: List[np.ndarray], labels: List[str]):
        self.X = [torch.tensor(t, dtype=torch.float32) for t in tdc_list]
        self.Y = torch.tensor([self.CLASS_MAP[l] for l in labels], dtype=torch.long)

    def __len__(self): return len(self.X)
    def __getitem__(self, idx): return self.X[idx], self.Y[idx]


# ── 数据增强 ────────────────────────────────────────────────────────────
def augment_tdc(
    tdc_list: List[np.ndarray],
    labels:   List[str],
    n_aug:    int = 20,
    noise_std: float = 0.025,
    shift_max: int = 5,
    scale_range: Tuple[float, float] = (0.88, 1.12),
) -> Tuple[List[np.ndarray], List[str]]:
    """
    对TDC曲线进行3种增强:
      ① 高斯噪声（模拟图像噪声）
      ② 时间偏移（模拟造影时间变化）
      ③ 幅度缩放（模拟造影剂剂量差异）
    """
    aug_X, aug_Y = [], []
    rng = np.random.default_rng(42)

    for tdc, label in zip(tdc_list, labels):
        for _ in range(n_aug):
            t = tdc.copy()                                        # [2, 100]
            # ① 噪声
            t = t + rng.normal(0, noise_std * rng.uniform(0.5, 1.5), t.shape)
            # ② 时间偏移
            shift = rng.integers(-shift_max, shift_max + 1)
            t = np.roll(t, shift, axis=1)
            # ③ 幅度缩放
            scale = rng.uniform(*scale_range)
            t = t * scale
            # ④ 重归一化到[0,1]
            for ch in range(2):
                v = t[ch]
                t[ch] = (v - v.min()) / max(1e-9, v.max() - v.min())
            t = np.clip(t, 0.0, 1.0)
            aug_X.append(t)
            aug_Y.append(label)

    return aug_X, aug_Y


# ── 训练器 ──────────────────────────────────────────────────────────────
class CHSTrainer:
    """BiLSTM CHS分类器训练与验证。"""

    def __init__(self, device: Optional[str] = None):
        if device is None:
            self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        else:
            self.device = device

    def train(
        self,
        tdc_list:  List[np.ndarray],
        labels:    List[str],
        n_aug:     int = 20,
        epochs:    int = 200,
        lr:        float = 1e-3,
        batch_size: int = 16,
        progress_cb=None,   # callback(epoch, loss, acc) for UI
    ) -> Tuple[DSA_BiLSTM, Dict]:
        """
        训练BiLSTM分类器（含数据增强）。

        Returns:
            (trained_net, metrics_dict)
        """
        # 数据增强
        aug_X, aug_Y = augment_tdc(tdc_list, labels, n_aug=n_aug)
        dataset = TDCDataset(aug_X, aug_Y)
        loader  = DataLoader(dataset, batch_size=min(batch_size, len(dataset)),
                             shuffle=True, drop_last=False)

        net = DSA_BiLSTM().to(self.device)
        opt = torch.optim.Adam(net.parameters(), lr=lr, weight_decay=1e-4)
        scheduler = torch.optim.lr_scheduler.StepLR(opt, step_size=80, gamma=0.5)
        criterion = nn.CrossEntropyLoss()

        history = {'loss': [], 'acc': []}
        net.train()
        for ep in range(epochs):
            epoch_loss, epoch_correct, epoch_total = 0.0, 0, 0
            for X_batch, Y_batch in loader:
                X_batch = X_batch.to(self.device)
                Y_batch = Y_batch.to(self.device)
                opt.zero_grad()
                logits = net(X_batch)
                loss   = criterion(logits, Y_batch)
                loss.backward()
                nn.utils.clip_grad_norm_(net.parameters(), max_norm=1.0)
                opt.step()

                preds = logits.argmax(dim=1)
                epoch_correct += (preds == Y_batch).sum().item()
                epoch_total   += len(Y_batch)
                epoch_loss    += loss.item() * len(Y_batch)

            scheduler.step()
            avg_loss = epoch_loss / max(1, epoch_total)
            avg_acc  = epoch_correct / max(1, epoch_total) * 100
            history['loss'].append(avg_loss)
            history['acc'].append(avg_acc)

            if progress_cb and ep % 10 == 0:
                progress_cb(ep, avg_loss, avg_acc)

        metrics = {'final_train_acc': history['acc'][-1], 'history': history}
        return net, metrics

    def loo_cross_validate(
        self,
        tdc_list:  List[np.ndarray],
        labels:    List[str],
        n_aug:     int = 20,
        epochs:    int = 150,
        progress_cb=None,
    ) -> Dict:
        """
        留一法(LOO)交叉验证，在原始(未增强)样本上评估泛化性能。

        Returns:
            {accuracy, sensitivity, specificity, confusion_matrix, predictions}
        """
        n = len(tdc_list)
        loo_preds = []
        loo_true  = []

        for leave_out in range(n):
            # 训练集：其余n-1条 + 增强
            train_X = [tdc_list[i] for i in range(n) if i != leave_out]
            train_Y = [labels[i]   for i in range(n) if i != leave_out]
            aug_X, aug_Y = augment_tdc(train_X, train_Y, n_aug=n_aug)

            net, _ = self.train(aug_X, aug_Y, n_aug=0, epochs=epochs,
                                progress_cb=None)
            net.eval()
            with torch.no_grad():
                x_test = torch.tensor(tdc_list[leave_out][np.newaxis], dtype=torch.float32).to(self.device)
                logit  = net(x_test)
                pred_idx = logit.argmax(dim=1).item()
                loo_preds.append(TDCDataset.IDX_MAP[pred_idx])
                loo_true.append(labels[leave_out])

            if progress_cb:
                progress_cb(leave_out, n)

        # 计算指标
        return _compute_metrics(loo_true, loo_preds)

    def predict(self, net: DSA_BiLSTM, tdc: np.ndarray) -> Tuple[str, float]:
        """
        对单条TDC进行推理。

        Args:
            tdc: [2, 100] 归一化双端TDC

        Returns:
            (label, confidence)
        """
        net.eval()
        with torch.no_grad():
            x = torch.tensor(tdc[np.newaxis], dtype=torch.float32).to(self.device)
            logits = net(x)
            probs  = torch.softmax(logits, dim=1).cpu().numpy()[0]
            pred   = TDCDataset.IDX_MAP[int(np.argmax(probs))]
        return pred, float(probs.max())

    def save(self, net: DSA_BiLSTM, path: str, metrics: Optional[Dict] = None) -> None:
        """保存模型权重和指标。"""
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        torch.save({
            'state_dict': net.state_dict(),
            'metrics':    metrics or {},
        }, path)

    def load(self, path: str) -> Tuple[DSA_BiLSTM, Dict]:
        """加载已保存的模型。"""
        ckpt    = torch.load(path, map_location=self.device)
        net     = DSA_BiLSTM().to(self.device)
        net.load_state_dict(ckpt['state_dict'])
        net.eval()
        return net, ckpt.get('metrics', {})


# ── 指标计算 ────────────────────────────────────────────────────────────
def _compute_metrics(true_labels: List[str], pred_labels: List[str]) -> Dict:
    n = len(true_labels)
    TP = sum(t == 'CHS'    and p == 'CHS'    for t, p in zip(true_labels, pred_labels))
    TN = sum(t == 'Normal' and p == 'Normal' for t, p in zip(true_labels, pred_labels))
    FP = sum(t == 'Normal' and p == 'CHS'    for t, p in zip(true_labels, pred_labels))
    FN = sum(t == 'CHS'    and p == 'Normal' for t, p in zip(true_labels, pred_labels))

    acc  = (TP + TN) / max(1, n) * 100
    sens = TP / max(1, TP + FN) * 100
    spec = TN / max(1, TN + FP) * 100
    ppv  = TP / max(1, TP + FP) * 100

    return {
        'accuracy':    acc,
        'sensitivity': sens,
        'specificity': spec,
        'ppv':         ppv,
        'TP': TP, 'TN': TN, 'FP': FP, 'FN': FN,
        'n_total': n,
        'predictions': list(zip(true_labels, pred_labels)),
    }
