function io_savePreData(varargin)
% IO_SAVEPREDATA 明确地保存当前全脑参数图为术前参比数据 (.mat)
% 这项功能原本内含于 io_exportData 中，为了让医生操作流更直观，现在作为一个显式按钮。

% 【修复】用 Tag 定位主窗口，避免标题字符串变动导致失效
mainFig = findobj('Type', 'figure', 'Tag', 'DSA_Main_Window');
if isempty(mainFig)
    fig = gcf;
else
    fig = mainFig(1);
end


data = guidata(fig);

% 安全校验
if isempty(data) || ~isfield(data, 'ParamMaps') || isempty(data.ParamMaps.TTP)
    utils_showMessage('暂无全脑像素级参数数据！请先执行【🗺️ 像素参数图扫描】。', 'warn');
    return;
end

% 获取患者信息和存储路径
patientInfo = getappdata(fig, 'patientInfo');
if ~isempty(patientInfo) && isfield(patientInfo, 'id') && ~isempty(patientInfo.id)
    patientID   = patientInfo.id;
    patientName = patientInfo.name;
else
    patientID   = 'Unknown';
    patientName = '未知患者';
end

% 构建数据目录 (PatientData/<patientID>/Results/)
baseDir = fileparts(mfilename('fullpath'));
baseDir = fileparts(fileparts(baseDir)); % 回到项目根目录
dataDir = fullfile(baseDir, 'PatientData', patientID, 'Results');
if ~exist(dataDir, 'dir'), mkdir(dataDir); end

% 弹出保存对话框
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
defaultName = sprintf('术前参比数据_%s.mat', timestamp);

[file, path] = uiputfile('*.mat', '💾 保存为术前参比数据 (用于对比)', fullfile(dataDir, defaultName));

if isequal(file, 0)
    log_updateStatus('取消保存术前数据');
    return;
end

try
    log_updateStatus('正在保存术前参比矩阵数据...');
    fullPath = fullfile(path, file);
    
    % 更新分析时间戳
    data.analysisInfo.isPreSurgeryReference = true;
    data.analysisInfo.referenceSaveTime = datestr(now);
    
    % 保存完整的基于体素的科学数据
    save(fullPath, 'data');
    
    msg = sprintf('【术前数据保存成功】\n\n已无损保存此患者的全脑血流参数矩阵。\n\n在完成支架置入并导入术后图像后，请在相同界面点击【📊 术前/术后绝对改善对齐图】并选择此文件，即可实现对比！');
    utils_showMessage(msg, 'success');
    log_addWorkLog(sprintf('显式保存术前参比数据成功: %s', file));
    log_updateStatus('术前数据已保存');
    
catch ME
    utils_showMessage('术前数据保存失败', 'error', ME.message);
    log_updateStatus('保存失败');
    log_addWorkLog(sprintf('保存术前数据失败: %s', ME.message));
end
end
