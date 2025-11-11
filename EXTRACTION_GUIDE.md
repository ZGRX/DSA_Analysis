<<<<<<< HEAD
# 模块提取指南

## 如何从原始文件提取剩余功能

这个文档帮助您系统地将 DSA_Analysis_GUI_v5.m 中的其他函数提取到模块中。

### 提取步骤

#### 1. 帧控制模块 (FrameControl.m)

**需要提取的函数:**
- updateFrameFromSlider (行号: ~1036)
- togglePlayback (行号: ~1060)
- stopPlayback (行号: ~1090)
- advanceFrame (行号: ~1110)
- goToFirstFrame (行号: ~1130)
- goToPrevFrame (行号: ~1150)
- goToNextFrame (行号: ~1170)
- goToLastFrame (行号: ~1190)
- validateFrameInput (行号: ~1210)
- applyFrameRange (行号: ~1240)
- updateFrameDisplay (行号: ~1270)

**提取命令 (在MATLAB中):**
```matlab
% 打开原文件
edit e:\DSA\DSA_Analysis_GUI_v5.m

% 1. 复制所有上述函数
% 2. 粘贴到新文件 e:\DSA_Refactored\modules\FrameControl.m
% 3. 在文件开头添加:
%    function FrameControl()
%    % 帧控制工具集
%    end
% 4. 保存文件
```

#### 2. ROI处理模块 (ROIProcessor.m)

**需要提取的函数:**
- placeROI (行号: ~1400)
- extractTDC (行号: ~1550)
- updateROIDisplay (如果有)

**关键点:**
- 这个模块依赖 guidata() 获取图像数据
- 需要访问 mainAxes 进行绘图
- 使用 getappdata() 获取ROI状态显示句柄

#### 3. 数据导入模块 (DataImporter.m)

**需要提取的函数:**
- importDSA (行号: ~1300)
- updateUIControlsAfterImport (行号: ~1450)
- selectFrames (行号: ~1480)
- updateFrameDisplayForMain (如果有)
- updateStatusForMain (行号: ~3277)

**关键点:**
- 处理DICOM文件读取
- 图像预处理和灰度反转
- UI控件状态更新

#### 4. 分析引擎模块 (AnalysisEngine.m)

**需要提取的函数:**
- analyzeCurves (搜索关键字)
- calculatePerfusionParams (搜索关键字)
- performCurveSmoothing (搜索关键字)
- calculateTMAX (搜索关键字)
- calculateAUC (搜索关键字)

#### 5. 数据导出模块 (DataExporter.m)

**需要提取的函数:**
- exportData (搜索关键字)
- comparePrePost (搜索关键字)
- showResults (搜索关键字)
- generateReport (如果有)

### 查找函数的技巧

#### 方法1: 使用MATLAB编辑器
```matlab
% 打开文件
edit e:\DSA\DSA_Analysis_GUI_v5.m

% 使用 Ctrl+F 搜索函数名
% 例如: 搜索 "function placeROI"
```

#### 方法2: 使用命令行搜索
```matlab
% 读取文件内容
fid = fopen('e:\DSA\DSA_Analysis_GUI_v5.m', 'r');
content = fread(fid, '*char')';
fclose(fid);

% 查找函数定义
lines = strsplit(content, '\n');
funcLines = find(contains(lines, 'function '));
for i = 1:length(funcLines)
    fprintf('行 %d: %s\n', funcLines(i), lines{funcLines(i)});
end
```

#### 方法3: 使用文本编辑器
使用 VS Code 或 Notepad++ 打开文件，搜索 "function " 可以快速定位所有函数。

### 提取模板

创建新模块文件时，使用以下模板:

```matlab
function ModuleName()
    % 模块名称 - 功能说明
    % 这个类包含了XXX相关的所有函数
end

function result = mainFunction(param1, param2)
    % 主要功能函数
    % 输入:
    %   param1 - 参数1说明
    %   param2 - 参数2说明
    % 输出:
    %   result - 返回值说明
    
    % 实现代码...
end

function helperFunction()
    % 辅助函数
    % (私有函数，仅在模块内部使用)
    
    % 实现代码...
end
```

### 依赖关系处理

**数据访问模式:**
```matlab
% 获取主窗口
fig = gcf;

% 获取存储的数据
data = guidata(fig);

% 获取UI控件
control = getappdata(fig, 'controlName');

% 更新数据
guidata(fig, data);

% 更新UI
set(control, 'Property', value);
```

**调用其他模块:**
```matlab
% 更新日志
updateStatus('操作完成');
addWorkLog('详细日志信息');

% 更新显示
updateFrameDisplay();
```

### 测试提取的模块

创建测试脚本 test_modules.m:

```matlab
% 添加路径
addpath('e:\DSA_Refactored\modules');

% 测试患者信息模块
patientInfo = getPatientInformation();
if ~isempty(patientInfo)
    disp('患者信息模块工作正常');
    disp(patientInfo);
end

% 测试日志模块
fig = figure;
setappdata(fig, 'workLogData', {});
addWorkLog('测试日志1');
addWorkLog('测试日志2');
logs = getappdata(fig, 'workLogData');
disp('日志模块工作正常:');
disp(logs);
close(fig);

% 测试数据初始化
fig = figure;
guidata(fig, struct());
initializeDataContainer(fig);
data = guidata(fig);
disp('数据初始化模块工作正常:');
disp(fieldnames(data));
close(fig);
```

### 常见问题

**Q1: 函数找不到?**
A: 确保模块目录已添加到MATLAB路径:
```matlab
addpath(genpath('e:\DSA_Refactored\modules'));
```

**Q2: 回调函数无法访问数据?**
A: 使用 gcf 获取当前图形句柄，然后用 guidata 访问数据。

**Q3: 模块间如何通信?**
A: 通过共享的 guidata 和 setappdata/getappdata 机制。

**Q4: 原来的嵌套函数怎么处理?**
A: 将嵌套函数提取为独立函数，通过参数传递需要的数据。

### 优先级建议

**第一优先级 (核心功能):**
1. DataImporter.m - 没有它无法导入数据
2. ROIProcessor.m - 核心分析功能
3. AnalysisEngine.m - 数据分析

**第二优先级 (增强体验):**
4. FrameControl.m - 帧导航和播放
5. DataExporter.m - 结果导出

**第三优先级 (辅助功能):**
6. ConfigManager.m - 配置管理
7. ErrorHandler.m - 错误处理
8. TestSuite.m - 测试套件

### 完成清单

- [x] getPatientInformation.m
- [x] UIBuilder.m (部分完成)
- [x] LogManager.m
- [x] initializeDataContainer.m
- [ ] FrameControl.m
- [ ] ROIProcessor.m
- [ ] DataImporter.m
- [ ] AnalysisEngine.m
- [ ] DataExporter.m
- [ ] createInfoArea.m (UI组件)
- [ ] 所有回调函数

---

**提示**: 逐个模块提取和测试，确保每个模块都能独立工作后再继续下一个。
=======
# 模块提取指南

## 如何从原始文件提取剩余功能

这个文档帮助您系统地将 DSA_Analysis_GUI_v5.m 中的其他函数提取到模块中。

### 提取步骤

#### 1. 帧控制模块 (FrameControl.m)

**需要提取的函数:**
- updateFrameFromSlider (行号: ~1036)
- togglePlayback (行号: ~1060)
- stopPlayback (行号: ~1090)
- advanceFrame (行号: ~1110)
- goToFirstFrame (行号: ~1130)
- goToPrevFrame (行号: ~1150)
- goToNextFrame (行号: ~1170)
- goToLastFrame (行号: ~1190)
- validateFrameInput (行号: ~1210)
- applyFrameRange (行号: ~1240)
- updateFrameDisplay (行号: ~1270)

**提取命令 (在MATLAB中):**
```matlab
% 打开原文件
edit e:\DSA\DSA_Analysis_GUI_v5.m

% 1. 复制所有上述函数
% 2. 粘贴到新文件 e:\DSA_Refactored\modules\FrameControl.m
% 3. 在文件开头添加:
%    function FrameControl()
%    % 帧控制工具集
%    end
% 4. 保存文件
```

#### 2. ROI处理模块 (ROIProcessor.m)

**需要提取的函数:**
- placeROI (行号: ~1400)
- extractTDC (行号: ~1550)
- updateROIDisplay (如果有)

**关键点:**
- 这个模块依赖 guidata() 获取图像数据
- 需要访问 mainAxes 进行绘图
- 使用 getappdata() 获取ROI状态显示句柄

#### 3. 数据导入模块 (DataImporter.m)

**需要提取的函数:**
- importDSA (行号: ~1300)
- updateUIControlsAfterImport (行号: ~1450)
- selectFrames (行号: ~1480)
- updateFrameDisplayForMain (如果有)
- updateStatusForMain (行号: ~3277)

**关键点:**
- 处理DICOM文件读取
- 图像预处理和灰度反转
- UI控件状态更新

#### 4. 分析引擎模块 (AnalysisEngine.m)

**需要提取的函数:**
- analyzeCurves (搜索关键字)
- calculatePerfusionParams (搜索关键字)
- performCurveSmoothing (搜索关键字)
- calculateTMAX (搜索关键字)
- calculateAUC (搜索关键字)

#### 5. 数据导出模块 (DataExporter.m)

**需要提取的函数:**
- exportData (搜索关键字)
- comparePrePost (搜索关键字)
- showResults (搜索关键字)
- generateReport (如果有)

### 查找函数的技巧

#### 方法1: 使用MATLAB编辑器
```matlab
% 打开文件
edit e:\DSA\DSA_Analysis_GUI_v5.m

% 使用 Ctrl+F 搜索函数名
% 例如: 搜索 "function placeROI"
```

#### 方法2: 使用命令行搜索
```matlab
% 读取文件内容
fid = fopen('e:\DSA\DSA_Analysis_GUI_v5.m', 'r');
content = fread(fid, '*char')';
fclose(fid);

% 查找函数定义
lines = strsplit(content, '\n');
funcLines = find(contains(lines, 'function '));
for i = 1:length(funcLines)
    fprintf('行 %d: %s\n', funcLines(i), lines{funcLines(i)});
end
```

#### 方法3: 使用文本编辑器
使用 VS Code 或 Notepad++ 打开文件，搜索 "function " 可以快速定位所有函数。

### 提取模板

创建新模块文件时，使用以下模板:

```matlab
function ModuleName()
    % 模块名称 - 功能说明
    % 这个类包含了XXX相关的所有函数
end

function result = mainFunction(param1, param2)
    % 主要功能函数
    % 输入:
    %   param1 - 参数1说明
    %   param2 - 参数2说明
    % 输出:
    %   result - 返回值说明
    
    % 实现代码...
end

function helperFunction()
    % 辅助函数
    % (私有函数，仅在模块内部使用)
    
    % 实现代码...
end
```

### 依赖关系处理

**数据访问模式:**
```matlab
% 获取主窗口
fig = gcf;

% 获取存储的数据
data = guidata(fig);

% 获取UI控件
control = getappdata(fig, 'controlName');

% 更新数据
guidata(fig, data);

% 更新UI
set(control, 'Property', value);
```

**调用其他模块:**
```matlab
% 更新日志
updateStatus('操作完成');
addWorkLog('详细日志信息');

% 更新显示
updateFrameDisplay();
```

### 测试提取的模块

创建测试脚本 test_modules.m:

```matlab
% 添加路径
addpath('e:\DSA_Refactored\modules');

% 测试患者信息模块
patientInfo = getPatientInformation();
if ~isempty(patientInfo)
    disp('患者信息模块工作正常');
    disp(patientInfo);
end

% 测试日志模块
fig = figure;
setappdata(fig, 'workLogData', {});
addWorkLog('测试日志1');
addWorkLog('测试日志2');
logs = getappdata(fig, 'workLogData');
disp('日志模块工作正常:');
disp(logs);
close(fig);

% 测试数据初始化
fig = figure;
guidata(fig, struct());
initializeDataContainer(fig);
data = guidata(fig);
disp('数据初始化模块工作正常:');
disp(fieldnames(data));
close(fig);
```

### 常见问题

**Q1: 函数找不到?**
A: 确保模块目录已添加到MATLAB路径:
```matlab
addpath(genpath('e:\DSA_Refactored\modules'));
```

**Q2: 回调函数无法访问数据?**
A: 使用 gcf 获取当前图形句柄，然后用 guidata 访问数据。

**Q3: 模块间如何通信?**
A: 通过共享的 guidata 和 setappdata/getappdata 机制。

**Q4: 原来的嵌套函数怎么处理?**
A: 将嵌套函数提取为独立函数，通过参数传递需要的数据。

### 优先级建议

**第一优先级 (核心功能):**
1. DataImporter.m - 没有它无法导入数据
2. ROIProcessor.m - 核心分析功能
3. AnalysisEngine.m - 数据分析

**第二优先级 (增强体验):**
4. FrameControl.m - 帧导航和播放
5. DataExporter.m - 结果导出

**第三优先级 (辅助功能):**
6. ConfigManager.m - 配置管理
7. ErrorHandler.m - 错误处理
8. TestSuite.m - 测试套件

### 完成清单

- [x] getPatientInformation.m
- [x] UIBuilder.m (部分完成)
- [x] LogManager.m
- [x] initializeDataContainer.m
- [ ] FrameControl.m
- [ ] ROIProcessor.m
- [ ] DataImporter.m
- [ ] AnalysisEngine.m
- [ ] DataExporter.m
- [ ] createInfoArea.m (UI组件)
- [ ] 所有回调函数

---

**提示**: 逐个模块提取和测试，确保每个模块都能独立工作后再继续下一个。
>>>>>>> 4d5e5c9 (Initial commit)
