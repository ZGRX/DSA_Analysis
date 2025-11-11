<<<<<<< HEAD
% 测试脚本 - 验证重构后的代码
fprintf('=== 开始测试重构后的DSA系统 ===\n\n');

try
    % 添加路径
    addpath(genpath('modules'));
    fprintf('✓ 模块路径已添加\n');
    
    % 测试各个模块函数是否存在
    fprintf('\n检查模块文件:\n');
    modules = {
        'getPatientInformation'
        'createTitleBar'
        'createDisplayArea'
        'createControlButtons'
        'createInfoArea'
        'initializeDataContainer'
        'updateStatus'
        'addWorkLog'
        'clearWorkLog'
        'exportWorkLog'
    };
    
    for i = 1:length(modules)
        if exist(modules{i}, 'file')
            fprintf('  ✓ %s.m\n', modules{i});
        else
            fprintf('  ✗ %s.m 未找到\n', modules{i});
        end
    end
    
    fprintf('\n所有必需模块检查完成！\n');
    fprintf('现在可以运行: DSA_Analysis_GUI_Refactored\n');
    
catch ME
    fprintf('\n错误: %s\n', ME.message);
    fprintf('位置: %s (行 %d)\n', ME.stack(1).name, ME.stack(1).line);
end
=======
% 测试脚本 - 验证重构后的代码
fprintf('=== 开始测试重构后的DSA系统 ===\n\n');

try
    % 添加路径
    addpath(genpath('modules'));
    fprintf('✓ 模块路径已添加\n');
    
    % 测试各个模块函数是否存在
    fprintf('\n检查模块文件:\n');
    modules = {
        'getPatientInformation'
        'createTitleBar'
        'createDisplayArea'
        'createControlButtons'
        'createInfoArea'
        'initializeDataContainer'
        'updateStatus'
        'addWorkLog'
        'clearWorkLog'
        'exportWorkLog'
    };
    
    for i = 1:length(modules)
        if exist(modules{i}, 'file')
            fprintf('  ✓ %s.m\n', modules{i});
        else
            fprintf('  ✗ %s.m 未找到\n', modules{i});
        end
    end
    
    fprintf('\n所有必需模块检查完成！\n');
    fprintf('现在可以运行: DSA_Analysis_GUI_Refactored\n');
    
catch ME
    fprintf('\n错误: %s\n', ME.message);
    fprintf('位置: %s (行 %d)\n', ME.stack(1).name, ME.stack(1).line);
end
>>>>>>> 4d5e5c9 (Initial commit)
