% 代码重构对比分析
% 这个脚本分析重构前后的代码结构变化

fprintf('=== DSA分析系统代码重构对比 ===\n\n');

%% 原始文件分析
originalFile = 'e:\DSA\DSA_Analysis_GUI_v5.m';
if exist(originalFile, 'file')
    fid = fopen(originalFile, 'r');
    originalContent = fread(fid, '*char')';
    fclose(fid);
    
    originalLines = strsplit(originalContent, '\n');
    totalLines = length(originalLines);
    
    % 统计函数数量
    funcPattern = '^function\s+';
    funcCount = sum(~cellfun(@isempty, regexp(originalLines, funcPattern)));
    
    % 统计注释行
    commentCount = sum(startsWith(strtrim(originalLines), '%'));
    
    % 统计空行
    emptyCount = sum(cellfun(@isempty, strtrim(originalLines)));
    
    % 代码行数
    codeLines = totalLines - commentCount - emptyCount;
    
    fprintf('【原始文件】DSA_Analysis_GUI_v5.m\n');
    fprintf('  总行数: %d\n', totalLines);
    fprintf('  函数数量: %d\n', funcCount);
    fprintf('  代码行数: %d\n', codeLines);
    fprintf('  注释行数: %d\n', commentCount);
    fprintf('  空行数: %d\n', emptyCount);
    fprintf('  文件大小: %.2f KB\n\n', length(originalContent)/1024);
else
    fprintf('警告: 找不到原始文件 %s\n\n', originalFile);
end

%% 重构文件分析
refactoredDir = 'e:\DSA_Refactored';
fprintf('【重构后结构】\n');

% 主文件
mainFile = fullfile(refactoredDir, 'DSA_Analysis_GUI_Refactored.m');
if exist(mainFile, 'file')
    fid = fopen(mainFile, 'r');
    mainContent = fread(fid, '*char')';
    fclose(fid);
    mainLines = length(strsplit(mainContent, '\n'));
    fprintf('  主文件: DSA_Analysis_GUI_Refactored.m (%d 行)\n', mainLines);
else
    fprintf('  主文件: 未创建\n');
    mainLines = 0;
end

% 模块文件
modulesDir = fullfile(refactoredDir, 'modules');
if exist(modulesDir, 'dir')
    moduleFiles = dir(fullfile(modulesDir, '*.m'));
    totalModuleLines = 0;
    
    fprintf('\n  模块文件:\n');
    for i = 1:length(moduleFiles)
        filePath = fullfile(modulesDir, moduleFiles(i).name);
        fid = fopen(filePath, 'r');
        content = fread(fid, '*char')';
        fclose(fid);
        lineCount = length(strsplit(content, '\n'));
        totalModuleLines = totalModuleLines + lineCount;
        fprintf('    %s (%d 行)\n', moduleFiles(i).name, lineCount);
    end
    
    fprintf('\n  模块总行数: %d\n', totalModuleLines);
    fprintf('  模块数量: %d\n', length(moduleFiles));
else
    fprintf('  模块目录: 未创建\n');
    totalModuleLines = 0;
end

%% 对比分析
fprintf('\n=== 重构效果分析 ===\n');

if exist(originalFile, 'file')
    % 平均每个模块的行数
    if exist(modulesDir, 'dir') && length(moduleFiles) > 0
        avgModuleLines = totalModuleLines / length(moduleFiles);
        fprintf('  平均模块大小: %.0f 行/文件\n', avgModuleLines);
    end
    
    % 代码组织改进
    fprintf('  代码组织: 从单文件 -> %d个模块文件\n', length(moduleFiles) + 1);
    
    % 可维护性评分 (简化指标)
    originalMaintainability = 100 - (totalLines / 100);  % 行数越多越难维护
    refactoredMaintainability = 100 - (avgModuleLines / 10);  % 模块越小越易维护
    
    fprintf('  可维护性提升: %.1f%%\n', ...
            (refactoredMaintainability - originalMaintainability) / originalMaintainability * 100);
end

%% 重构建议
fprintf('\n=== 下一步工作 ===\n');
fprintf('  1. 继续提取剩余功能到模块中\n');
fprintf('  2. 完善以下关键模块:\n');
fprintf('     - FrameControl.m (帧控制)\n');
fprintf('     - ROIProcessor.m (ROI处理)\n');
fprintf('     - DataImporter.m (数据导入)\n');
fprintf('     - AnalysisEngine.m (分析引擎)\n');
fprintf('     - DataExporter.m (数据导出)\n');
fprintf('  3. 添加createInfoArea相关UI函数\n');
fprintf('  4. 测试所有功能模块\n');
fprintf('  5. 编写单元测试\n');

%% 文件结构树
fprintf('\n=== 推荐的最终文件结构 ===\n');
fprintf('DSA_Refactored/\n');
fprintf('│\n');
fprintf('├── DSA_Analysis_GUI_Refactored.m     [主入口，约100行]\n');
fprintf('├── README.md                         [使用说明]\n');
fprintf('├── EXTRACTION_GUIDE.md               [提取指南]\n');
fprintf('├── comparison_report.m               [本文件]\n');
fprintf('│\n');
fprintf('└── modules/                          [功能模块目录]\n');
fprintf('    ├── getPatientInformation.m       [✓ 已完成]\n');
fprintf('    ├── UIBuilder.m                   [✓ 已完成]\n');
fprintf('    ├── LogManager.m                  [✓ 已完成]\n');
fprintf('    ├── initializeDataContainer.m     [✓ 已完成]\n');
fprintf('    ├── FrameControl.m                [待提取]\n');
fprintf('    ├── ROIProcessor.m                [待提取]\n');
fprintf('    ├── DataImporter.m                [待提取]\n');
fprintf('    ├── AnalysisEngine.m              [待提取]\n');
fprintf('    ├── DataExporter.m                [待提取]\n');
fprintf('    ├── InfoPanelBuilder.m            [待提取]\n');
fprintf('    └── CallbackHandlers.m            [待提取]\n');

fprintf('\n完成分析！\n');
