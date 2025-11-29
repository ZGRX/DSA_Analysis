# DSA脑血流灌注分析系统 - 模块化重构

[![MATLAB](https://img.shields.io/badge/MATLAB-R2024b-orange.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 项目概述

本项目将原 `DSA_Analysis_GUI_v5.m` (3443行) 单一文件重构为模块化架构，提高代码可维护性、可扩展性和团队协作效率。

**原始文件:** `DSA_Analysis_GUI_v5.m` (3443 行)  
**重构入口:** `DSA_Analysis_GUI_Refactored.m` (67 行)  
**模块总数:** 36 个独立文件  
**总代码行数:** ~2000 行 (模块化后代码更清晰简洁)

---


## 快速开始

```matlab
% 添加模块路径并启动系统
addpath(genpath('modules'))
DSA_Analysis_GUI_Refactored
```

---

## 目录结构

```
DSA_Analysis-main/
├── DSA_Analysis_GUI_Refactored.m    # 主入口文件 (67行)
├── DSA_Analysis_GUI_v5.m            # 原始单文件版本 (3443行)
└── modules/                          # 模块化代码目录
    ├── io/                          # 输入输出模块 (4个文件)
    ├── analysis/                    # 数据分析模块 (5个文件)
    ├── control/                     # 界面控制模块 (14个文件)
    ├── ui/                          # UI组件模块 (6个文件)
    ├── log/                         # 日志管理模块 (4个文件)
    └── utils/                       # 工具函数模块 (1个文件)
```

---

## 核心功能

### 数据分析流程

```
导入DSA数据 → 放置ROI → 提取TDC曲线 → 分析曲线 → 显示结果 → 导出数据
```

### 术前术后对比

- 🔍 **高灌注风险评估**: 自动识别血流速度增加>150%的脑叶
- 📊 **可视化对比**: 柱状图、详细参数表
- 💡 **临床建议**: 根据风险等级自动生成

---

## 模块详情

### IO模块 (`modules/io/`)

| 文件 | 行数 | 源文件行号 | 功能 |
|------|:----:|:---------:|------|
| `io_importDSA.m` | 176 | 1401-1576 | 导入DICOM格式DSA影像 |
| `io_exportData.m` | 87 | 2497-2583 | 导出分析结果(MAT/Excel/CSV) |
| `io_getPatientInformation.m` | 95 | 1171-1265 | 患者信息录入对话框 |
| `io_initializeDataContainer.m` | 36 | 1105-1140 | 数据结构初始化 |

### Analysis模块 (`modules/analysis/`)

| 文件 | 行数 | 源文件行号 | 功能 |
|------|:----:|:---------:|------|
| `analysis_placeROI.m` | 78 | 1770-1847 | ROI区域放置(12点/4脑叶) |
| `analysis_extractTDC.m` | 90 | 1911-2000 | TDC曲线提取 |
| `analysis_analyzeCurves.m` | 136 | 2167-2302 | 曲线分析，计算11个灌注参数 |
| `analysis_showResults.m` | 49 | 2386-2434 | 结果可视化显示 |
| `analysis_comparePrePost.m` | 342 | 2619-2960 | 术前术后对比分析 |

### Control模块 (`modules/control/`)

| 文件 | 行数 | 功能 |
|------|:----:|------|
| `frameNavigation.m` | 76 | 帧导航核心逻辑 |
| `selectFrames.m` | 188 | 帧范围选择器 |
| `togglePlayback.m` | 42 | 播放/暂停切换 |
| `resetAll.m` | 94 | 重置所有数据 |
| `showHelp.m` | 32 | 显示帮助信息 |

### UI模块 (`modules/ui/`)

| 文件 | 行数 | 功能 |
|------|:----:|------|
| `createTitleBar.m` | 25 | 顶部标题栏 |
| `createControlButtons.m` | 159 | 左侧功能按钮组 |
| `createDisplayArea.m` | 15 | 中央图像显示区 |
| `createInfoArea.m` | 157 | 右侧信息面板 |
| `updateParamTable.m` | 53 | 参数表格更新 |
| `showDetailedLog.m` | 36 | 详细日志窗口 |

### Log模块 (`modules/log/`)

| 文件 | 行数 | 功能 |
|------|:----:|------|
| `log_addWorkLog.m` | 25 | 添加日志条目 |
| `log_updateStatus.m` | 25 | 更新状态显示 |
| `log_clearWorkLog.m` | 14 | 清空日志 |
| `log_exportWorkLog.m` | 36 | 导出日志到文件 |

---

## 灌注参数

系统计算以下 **11个参数** × **4个脑叶**:

| 参数 | 说明 | 单位 |
|------|------|:----:|
| **TMAX** | 峰值时间 | s |
| **MTT** | 平均通过时间 | s |
| **TU** | 上升时间 | s |
| **TD** | 下降时间 | s |
| **1/2TMAX** | 半峰值时间 | s |
| **AUC** | 曲线下面积 | SI·s |
| **AUCbefore** | 峰值前面积 | SI·s |
| **AUCratio** | 面积比 | - |
| **MS** | 最大斜率 | SI/s |
| **AFS** | 平均斜率 | SI/s |
| **CBF** | 脑血流量 | SI |

---

## 命名规范

| 前缀 | 用途 | 示例 |
|------|------|------|
| `io_` | 输入输出操作 | `io_importDSA`, `io_exportData` |
| `analysis_` | 数据分析功能 | `analysis_placeROI`, `analysis_extractTDC` |
| `log_` | 日志管理 | `log_addWorkLog`, `log_updateStatus` |
| `utils_` | 工具函数 | `utils_validateFrameInput` |
| 无前缀 | UI组件和控制 | `createTitleBar`, `frameNavigation` |

---

## 重构优势

| 优势 | 说明 |
|------|------|
| ✅ **可维护性** | 单一职责原则，快速定位代码 |
| ✅ **可扩展性** | 新增功能无需修改核心代码 |
| ✅ **协作效率** | 多人并行开发，减少冲突 |
| ✅ **代码质量** | 模块化后更清晰简洁 |
| ✅ **可测试性** | 每个模块可独立测试 |

---

## 技术栈

- **语言**: MATLAB R2024b
- **图像格式**: DICOM
- **数据格式**: MAT, Excel (XLSX), CSV
- **UI框架**: MATLAB GUIDE/uicontrol
- **插值算法**: Hermite多项式
- **风险评估**: TCD标准 (>150%为高风险)

---

## 相关文档

- 📖 [完整模块文档](./MODULAR_STRUCTURE_README.md) - 详细的模块说明和源文件对应
- 🔧 [提取指南](./EXTRACTION_GUIDE.md) - 代码提取过程记录
- ✅ [重构完成报告](./REFACTORING_COMPLETION_REPORT.md) - 重构完成情况
- 🚀 [快速开始指南](./QUICK_START.md) - 快速上手教程
- 🔍 [修复报告](./FIX_REPORT.md) - 问题修复记录

---

## 版本历史

| 版本 | 日期 | 说明 |
|:----:|------|------|
| **v5.0** | 2025-11 | 原始单文件版本 (3443行) |
| **v5.1** | 2025-11-28 | 模块化重构完成 (36个文件) |

---

## 许可证

MIT License

---

## 联系方式

- **项目路径**: `f:\DSA_Analysis-main\DSA_Analysis-main\`
- **GitHub**: [suryxin001204/DSA_Analysis-main](https://github.com/suryxin001204/DSA_Analysis-main)
- **维护者**: DSA Analysis Team
- **最后更新**: 2025-11-28
