function [resultsDir, dataDir, reportsDir] = utils_getPatientDir(patientID)
% UTILS_GETPATIENTDIR 获取患者数据的标准目录结构
% 
% 输入:
%   patientID - 患者ID字符串
%
% 输出:
%   resultsDir - 结果总目录
%   dataDir - 科学数据目录 (.mat文件)
%   reportsDir - 报告目录 (.xlsx, .pdf文件)
%
% 功能:
%   1. 统一管理所有患者数据的存储路径
%   2. 自动创建不存在的目录
%   3. 确保跨平台兼容性（使用 fullfile）
%
% 示例:
%   [resultsDir, dataDir, reportsDir] = utils_getPatientDir('P001');

% 输入验证
if nargin < 1 || isempty(patientID)
    patientID = 'Unknown';
end

% 确保 patientID 是有效的文件夹名称
patientID = matlab.lang.makeValidName(patientID);

% 获取基础目录
baseDir = pwd;

% 构建标准目录结构（使用 fullfile 确保跨平台兼容）
patientDir = fullfile(baseDir, 'PatientData', patientID);
resultsDir = fullfile(patientDir, 'Results');
dataDir = fullfile(patientDir, 'Data');
reportsDir = fullfile(patientDir, 'Reports');

% 确保所有目录存在
if ~exist(patientDir, 'dir')
    mkdir(patientDir);
end

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

if ~exist(dataDir, 'dir')
    mkdir(dataDir);
end

if ~exist(reportsDir, 'dir')
    mkdir(reportsDir);
end

end
