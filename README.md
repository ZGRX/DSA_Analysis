<<<<<<< HEAD
# DSA脑血流灌注分析系统 - 重构版本

## 项目说明

这是DSA_Analysis_GUI_v5.m的重构版本，将原来3000多行的单文件代码拆分成多个模块化文件，提高了代码的可维护性和可读性。

## 文件结构

```
DSA_Refactored/
│
├── DSA_Analysis_GUI_Refactored.m     # 主入口文件 (约100行)
│
└── modules/                          # 功能模块目录
    ├── getPatientInformation.m       # 患者信息输入模块
    ├── UIBuilder.m                   # UI构建模块
    ├── LogManager.m                  # 日志管理模块
    ├── initializeDataContainer.m     # 数据初始化模块
    ├── FrameControl.m                # 帧控制模块 (待创建)
    ├── ROIProcessor.m                # ROI处理模块 (待创建)
    ├── TDCExtractor.m                # TDC提取模块 (待创建)
    ├── DataImporter.m                # 数据导入模块 (待创建)
    ├── DataExporter.m                # 数据导出模块 (待创建)
    └── AnalysisEngine.m              # 分析引擎模块 (待创建)
```

## 模块功能说明

### 1. **主入口 (DSA_Analysis_GUI_Refactored.m)**
   - 初始化系统
   - 调用各个模块
   - 创建主窗口
   - 布局管理

### 2. **患者信息模块 (getPatientInformation.m)**
   - 显示患者信息输入对话框
   - 验证输入数据
   - 返回患者信息结构体

### 3. **UI构建模块 (UIBuilder.m)**
   - `createTitleBar()` - 创建标题栏
   - `createControlButtons()` - 创建控制按钮
   - `createDisplayArea()` - 创建图像显示区域
   - `createWorkLogPanel()` - 创建工作日志面板
   - `showDetailedLog()` - 显示详细日志窗口

### 4. **日志管理模块 (LogManager.m)**
   - `updateStatus()` - 更新状态显示
   - `addWorkLog()` - 添加工作日志
   - `clearWorkLog()` - 清空日志
   - `exportWorkLog()` - 导出日志到文件

### 5. **数据初始化模块 (initializeDataContainer.m)**
   - 初始化所有数据结构
   - 设置默认值
   - 定义脑叶名称和颜色

### 6. **帧控制模块 (待完善)**
   - 帧导航功能
   - 播放/暂停功能
   - 帧范围选择

### 7. **ROI处理模块 (待完善)**
   - ROI放置
   - ROI位置管理
   - ROI可视化

### 8. **TDC提取模块 (待完善)**
   - 时间密度曲线提取
   - 数据平滑处理
   - 参数计算

## 如何使用

### 运行程序

```matlab
% 方法1: 直接运行
cd('e:\DSA_Refactored')
DSA_Analysis_GUI_Refactored

% 方法2: 添加路径后运行
addpath('e:\DSA_Refactored')
DSA_Analysis_GUI_Refactored
```

### 迁移原有代码

如果您想继续使用原来的完整功能，需要从原文件中提取更多回调函数到相应模块中。

## 重构优势

### 1. **代码组织清晰**
   - 每个模块负责单一功能
   - 文件大小适中（每个文件100-300行）
   - 易于定位和修改

### 2. **可维护性提升**
   - 模块独立，修改一个不影响其他
   - 便于团队协作开发
   - 降低代码复杂度

### 3. **可扩展性增强**
   - 容易添加新功能模块
   - 方便进行单元测试
   - 支持功能复用

### 4. **性能优化**
   - 按需加载模块
   - 减少内存占用
   - 便于性能调优

## 下一步工作

### 必须完成的模块 (保证基本功能)

1. **FrameControl.m** - 帧控制功能
   - updateFrameFromSlider
   - togglePlayback
   - goToFirstFrame/Prev/Next/Last
   - selectFrames

2. **ROIProcessor.m** - ROI处理
   - placeROI
   - updateROIDisplay
   - validateROI

3. **TDCExtractor.m** - TDC提取
   - extractTDC
   - smoothTDC
   - calculateParameters

4. **DataImporter.m** - 数据导入
   - importDSA
   - readDICOM
   - preprocessImage

5. **DataExporter.m** - 数据导出
   - exportData
   - exportResults
   - generateReport

6. **AnalysisEngine.m** - 分析引擎
   - analyzeCurves
   - calculatePerfusion
   - assessRisk

### 可选优化 (进一步提升)

1. **使用面向对象设计**
   ```matlab
   classdef DSAAnalyzer < handle
       properties
           patientInfo
           imageData
           roiData
       end
       methods
           function obj = DSAAnalyzer()
               % 构造函数
           end
       end
   end
   ```

2. **添加配置文件**
   - config.json 或 config.m
   - 存储默认参数
   - 用户偏好设置

3. **单元测试**
   - 为每个模块编写测试
   - 确保代码质量
   - 自动化测试流程

4. **错误处理增强**
   - 统一的异常处理
   - 详细的错误日志
   - 用户友好的错误提示

## 注意事项

1. **路径问题**
   - 确保 modules/ 目录在 MATLAB 路径中
   - 使用 `addpath(genpath(...))` 自动添加

2. **数据共享**
   - 使用 `guidata()` 和 `setappdata()` 在模块间共享数据
   - 保持数据结构一致性

3. **回调函数**
   - 回调函数需要访问主窗口句柄
   - 使用 `gcf` 获取当前图形句柄
   - 注意回调函数的作用域

4. **兼容性**
   - 保持与原代码的接口兼容
   - 数据结构保持一致
   - 功能逻辑不变

## 联系与支持

如有问题或建议，请参考原始代码 DSA_Analysis_GUI_v5.m 中的实现细节。

---

**版本**: v3.0 Refactored
**最后更新**: 2025-11-10
=======
# DSA脑血流灌注分析系统 - 重构版本

## 项目说明

这是DSA_Analysis_GUI_v5.m的重构版本，将原来3000多行的单文件代码拆分成多个模块化文件，提高了代码的可维护性和可读性。

## 文件结构

```
DSA_Refactored/
│
├── DSA_Analysis_GUI_Refactored.m     # 主入口文件 (约100行)
│
└── modules/                          # 功能模块目录
    ├── getPatientInformation.m       # 患者信息输入模块
    ├── UIBuilder.m                   # UI构建模块
    ├── LogManager.m                  # 日志管理模块
    ├── initializeDataContainer.m     # 数据初始化模块
    ├── FrameControl.m                # 帧控制模块 (待创建)
    ├── ROIProcessor.m                # ROI处理模块 (待创建)
    ├── TDCExtractor.m                # TDC提取模块 (待创建)
    ├── DataImporter.m                # 数据导入模块 (待创建)
    ├── DataExporter.m                # 数据导出模块 (待创建)
    └── AnalysisEngine.m              # 分析引擎模块 (待创建)
```

## 模块功能说明

### 1. **主入口 (DSA_Analysis_GUI_Refactored.m)**
   - 初始化系统
   - 调用各个模块
   - 创建主窗口
   - 布局管理

### 2. **患者信息模块 (getPatientInformation.m)**
   - 显示患者信息输入对话框
   - 验证输入数据
   - 返回患者信息结构体

### 3. **UI构建模块 (UIBuilder.m)**
   - `createTitleBar()` - 创建标题栏
   - `createControlButtons()` - 创建控制按钮
   - `createDisplayArea()` - 创建图像显示区域
   - `createWorkLogPanel()` - 创建工作日志面板
   - `showDetailedLog()` - 显示详细日志窗口

### 4. **日志管理模块 (LogManager.m)**
   - `updateStatus()` - 更新状态显示
   - `addWorkLog()` - 添加工作日志
   - `clearWorkLog()` - 清空日志
   - `exportWorkLog()` - 导出日志到文件

### 5. **数据初始化模块 (initializeDataContainer.m)**
   - 初始化所有数据结构
   - 设置默认值
   - 定义脑叶名称和颜色

### 6. **帧控制模块 (待完善)**
   - 帧导航功能
   - 播放/暂停功能
   - 帧范围选择

### 7. **ROI处理模块 (待完善)**
   - ROI放置
   - ROI位置管理
   - ROI可视化

### 8. **TDC提取模块 (待完善)**
   - 时间密度曲线提取
   - 数据平滑处理
   - 参数计算

## 如何使用

### 运行程序

```matlab
% 方法1: 直接运行
cd('e:\DSA_Refactored')
DSA_Analysis_GUI_Refactored

% 方法2: 添加路径后运行
addpath('e:\DSA_Refactored')
DSA_Analysis_GUI_Refactored
```

### 迁移原有代码

如果您想继续使用原来的完整功能，需要从原文件中提取更多回调函数到相应模块中。

## 重构优势

### 1. **代码组织清晰**
   - 每个模块负责单一功能
   - 文件大小适中（每个文件100-300行）
   - 易于定位和修改

### 2. **可维护性提升**
   - 模块独立，修改一个不影响其他
   - 便于团队协作开发
   - 降低代码复杂度

### 3. **可扩展性增强**
   - 容易添加新功能模块
   - 方便进行单元测试
   - 支持功能复用

### 4. **性能优化**
   - 按需加载模块
   - 减少内存占用
   - 便于性能调优

## 下一步工作

### 必须完成的模块 (保证基本功能)

1. **FrameControl.m** - 帧控制功能
   - updateFrameFromSlider
   - togglePlayback
   - goToFirstFrame/Prev/Next/Last
   - selectFrames

2. **ROIProcessor.m** - ROI处理
   - placeROI
   - updateROIDisplay
   - validateROI

3. **TDCExtractor.m** - TDC提取
   - extractTDC
   - smoothTDC
   - calculateParameters

4. **DataImporter.m** - 数据导入
   - importDSA
   - readDICOM
   - preprocessImage

5. **DataExporter.m** - 数据导出
   - exportData
   - exportResults
   - generateReport

6. **AnalysisEngine.m** - 分析引擎
   - analyzeCurves
   - calculatePerfusion
   - assessRisk

### 可选优化 (进一步提升)

1. **使用面向对象设计**
   ```matlab
   classdef DSAAnalyzer < handle
       properties
           patientInfo
           imageData
           roiData
       end
       methods
           function obj = DSAAnalyzer()
               % 构造函数
           end
       end
   end
   ```

2. **添加配置文件**
   - config.json 或 config.m
   - 存储默认参数
   - 用户偏好设置

3. **单元测试**
   - 为每个模块编写测试
   - 确保代码质量
   - 自动化测试流程

4. **错误处理增强**
   - 统一的异常处理
   - 详细的错误日志
   - 用户友好的错误提示

## 注意事项

1. **路径问题**
   - 确保 modules/ 目录在 MATLAB 路径中
   - 使用 `addpath(genpath(...))` 自动添加

2. **数据共享**
   - 使用 `guidata()` 和 `setappdata()` 在模块间共享数据
   - 保持数据结构一致性

3. **回调函数**
   - 回调函数需要访问主窗口句柄
   - 使用 `gcf` 获取当前图形句柄
   - 注意回调函数的作用域

4. **兼容性**
   - 保持与原代码的接口兼容
   - 数据结构保持一致
   - 功能逻辑不变

## 联系与支持

如有问题或建议，请参考原始代码 DSA_Analysis_GUI_v5.m 中的实现细节。

---

**版本**: v3.0 Refactored
**最后更新**: 2025-11-10
>>>>>>> 4d5e5c9 (Initial commit)
