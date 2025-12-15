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

**推荐工作流程:**
1. 点击 **📁 文件管理器** 按钮打开文件浏览器
2. 在左侧导入DICOM文件，点击 **⚡加载到系统**
3. 在主界面进行ROI分析、参数计算
4. 回到文件管理器，点击 **📤导出结果**
5. 右侧Results目录自动保存所有分析成果

---

## 目录结构

```
DSA_Analysis-main/
├── DSA_Analysis_GUI_Refactored.m    # 主入口文件 (67行)
├── DSA_Analysis_GUI_v5.m            # 原始单文件版本 (3443行)
├── modules/                          # 模块化代码目录
│   ├── io/                          # 输入输出模块 (4个文件)
│   ├── analysis/                    # 数据分析模块 (5个文件)
│   ├── control/                     # 界面控制模块 (14个文件)
│   ├── ui/                          # UI组件模块 (7个文件) 🆕
│   ├── log/                         # 日志管理模块 (4个文件)
│   └── utils/                       # 工具函数模块 (1个文件)
└── PatientData/                     # 患者数据目录 (自动创建)
    └── [PatientID]/                 # 患者ID命名的文件夹
        ├── RawData/                 # 原始DICOM数据
        └── Results/                 # 分析结果输出
```

---

## 核心功能

### 🎨 现代化医疗界面设计

- **医疗级配色方案**: 清新的浅蓝白色调，符合医疗软件审美
- **高对比度显示**: 优化的文字和按钮配色，减少视觉疲劳
- **直观的交互设计**: 大按钮、清晰图标、友好的反馈提示

### 📁 PANDA风格双面板文件管理器

```
┌─────────────────────┬─────────────────────┐
│   📂 原始数据        │   📊 分析结果        │
│   (RawData/)        │   (Results/)        │
│   ├─ patient001.dcm │   ├─ Analysis_xxx.mat│
│   ├─ patient002.dcm │   ├─ Parameters_xxx.xlsx│
│   └─ ...            │   └─ Comparison_xxx.xlsx│
│   [⚡加载到系统]     │   [📤导出结果]       │
└─────────────────────┴─────────────────────┘
```

**文件管理器特性:**
- 📥 **智能加载**: 点击文件直接加载到主系统，无需重复选择
- 📂 **双目录管理**: 左侧存放原始DICOM，右侧存放分析结果
- 🔄 **自动导出集成**: 所有导出操作自动保存到Results目录
- 📊 **文件预览**: 显示文件大小、修改日期、Emoji图标
- 🎯 **一站式工作流**: 从数据导入到结果导出全流程管理

### 🔬 数据分析流程

```
导入DSA数据 → 放置ROI → 提取TDC曲线 → 分析曲线 → 显示结果 → 导出数据
```

### 📈 术前术后对比分析

- 🔍 **高灌注风险评估**: 自动识别血流速度增加>150%的脑叶
- 📊 **可视化对比**: 柱状图、详细参数表
- 💡 **临床建议**: 根据风险等级自动生成
- 💾 **自动保存**: 对比结果自动保存到文件管理器Results目录

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
| `createTitleBar.m` | 25 | 医疗蓝标题栏 (现代化设计) |
| `createControlButtons.m` | 159 | 左侧功能按钮组 (浅色主题) |
| `createDisplayArea.m` | 15 | 中央图像显示区 (浅灰背景) |
| `createInfoArea.m` | 157 | 右侧信息面板 (白色卡片式) |
| `createFileManagerDialog.m` | 813 | 🆕 PANDA双面板文件管理器 |
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
| **v5.2** | 2025-11-30 | 🎨 UI现代化 + 📁 文件管理器 |
| **v5.3** | 2025-12-15 | 🔄 切换病人功能 + 👥 团队协作更新 |

### v5.3 更新内容 (2025-12-15)

#### ✨ 新增功能
- **🔄 切换病人**: 在文件管理器底部新增"切换病人"按钮
  - 点击后自动关闭当前会话
  - 重启系统回到患者信息录入界面
  - 方便连续处理多个病例，无需手动重启MATLAB

#### 👥 团队协作更新
- 同步团队最新代码提交
- 优化播放控制模块 (`createPlaybackControls.m`)
- 修复帧范围应用逻辑 (`applyFrameRange.m`)
- 改进重置功能 (`resetAll.m`)

### v5.2 更新内容 (2025-11-30)

#### 🎨 界面现代化改造
- **医疗级配色**: 从深蓝色主题改为浅蓝白色调 `[0.95, 0.97, 1]`
- **标题栏优化**: 医疗蓝 `[0.2, 0.6, 0.95]`，字体加大到28px
- **按钮美化**: 柔和配色，蓝色 `[0.3, 0.65, 0.92]`，绿色 `[0.35, 0.75, 0.45]`
- **图像区域**: 浅灰背景 `[0.93, 0.93, 0.93]`，更好的对比度
- **信息面板**: 纯白背景 `[1, 1, 1]`，卡片式设计

#### 📁 PANDA双面板文件管理器
- **左侧面板**: 原始DICOM数据管理
  - 📥 导入DICOM文件到RawData目录
  - ⚡ 一键加载文件到主系统
  - 🗑️ 删除不需要的文件
  - 📊 显示文件大小和修改时间
  
- **右侧面板**: 分析结果管理
  - 📤 导出当前分析结果
  - 📊 查看历史分析数据
  - 🗑️ 清理过期结果
  - 📈 支持MAT、Excel多种格式

#### 🔄 工作流集成
- **智能导入**: `io_importDSA.m` 支持从文件管理器直接加载指定文件
- **自动导出**: `io_exportData.m` 默认保存到 `PatientData/[ID]/Results/`
- **对比分析**: `analysis_comparePrePost.m` 导入/导出路径集成到文件管理器
- **时间戳命名**: 所有导出文件自动添加患者名和时间戳

#### 🐛 Bug修复
- 修复文件管理器选择文件后总是加载同一个的问题
- 优化文件加载逻辑，区分单文件和文件夹加载
- 修复Excel导出参数传递错误
- 修复formatFileSize输出参数过多的问题

---

## 许可证

MIT License

---

## 截图预览

### 主界面 (v5.2)
- 🎨 现代化浅色医疗主题
- 📊 清晰的信息展示面板
- 🖼️ 优化的图像显示区域

### 文件管理器
- 📁 左右双面板设计
- 🔄 一站式数据管理
- 📊 详细的文件信息显示

---

## 联系方式

- **项目路径**: `f:\DSA_Analysis-main\DSA_Analysis\`
- **维护者**: DSA Analysis Team
- **最后更新**: 2025-12-15

