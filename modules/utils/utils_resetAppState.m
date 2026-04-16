function utils_resetAppState(fig)
% utils_resetAppState  重置所有分析状态和UI界面
% 用于重新导入文件时，清理旧的 ROI、曲线数据和结果表格

if nargin < 1 || isempty(fig)
    fig = gcf;
end

% 1. 获取当前数据
data = guidata(fig);
if isempty(data), return; end

% 1.5 停止任何正在进行的播放
stopPlayback(fig);

% 2. 清理核心分析数据
data.roiMask = [];
data.roiPositions = [];
data.timeSeriesData = [];
data.perfusionParams = [];
data.smoothedLobeData = [];
data.t_highres = [];
data.currentFrame = 1;

% 3. 清理患者信息（保留框架）
data.patientInfo = struct('name', '', 'gender', '', 'age', '', 'id', '', 'date', '');

% 保存更新后的数据
guidata(fig, data);

% 4. 重置 UI 显示
% A. 清除主绘图区
mainAxes = getappdata(fig, 'mainAxes');
if ishandle(mainAxes)
    cla(mainAxes);
    title(mainAxes, '等待数据导入...', 'FontName', 'Microsoft YaHei');
end

% B. 重置参数表格
updateParamTable();

% C. 清载入信息
updatePatientInfoPanel(fig, data.patientInfo);

log_updateStatus('应用状态已重置，准备载入新数据');
log_addWorkLog('重置应用状态：已清理旧的 ROI、TDC 曲线及灌注参数');

end
