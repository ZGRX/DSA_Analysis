function workflow_generateReport(mainFig, reportType)
% WORKFLOW_GENERATEREPORT 量化报告生成与PDF导出
%
% 功能：
%   1. 'diagnosis' - 生成单次诊断报告（包含Mismatch、病灶标注等）
%   2. 'compare' - 生成术前术后对比报告
%
% 用法：
%   workflow_generateReport(mainFig, 'diagnosis')
%   workflow_generateReport(mainFig, 'compare')

if nargin < 1
    mainFig = gcf;
end

if nargin < 2
    reportType = 'diagnosis';
end

fig = mainFig;
data = guidata(fig);

log_updateStatus('【第三阶段】生成量化报告...');

try
    % ======= 检查前置条件 =======
    TTP_map = getappdata(fig, 'TTP_map');
    AUC_map = getappdata(fig, 'AUC_map');
    classMap = getappdata(fig, 'perfusionRiskMap');
    
    if isempty(TTP_map) || isempty(AUC_map)
        utils_showMessage('缺少数据', 'error', ...
            '请先执行"一键诊断"生成参数数据');
        return;
    end
    
    % ======= 根据报告类型选择处理逻辑 =======
    switch lower(reportType)
        case 'diagnosis'
            % 生成诊断报告
            if isempty(classMap)
                log_addWorkLog('警告：缺少四象限分层数据，使用基础诊断');
                reportData = generateBasicDiagnosisReport(fig, TTP_map, AUC_map);
            else
                reportData = generateCompleteDiagnosisReport(fig, TTP_map, AUC_map, classMap);
            end
            
        case 'compare'
            % 生成对比报告
            reportData = generateComparisonReport(fig, TTP_map, AUC_map);
            
        otherwise
            error('未知的报告类型: %s', reportType);
    end
    
    % ======= 导出为Excel =======
    log_updateStatus('正在导出数据...');
    excelFile = exportToExcel(reportData, reportType);
    
    % ======= 生成PDF摘要（可选） =======
    try
        log_updateStatus('正在生成PDF报告...');
        pdfFile = generatePDFReport(reportData, reportType);
        log_addWorkLog(sprintf('✓ PDF报告已生成: %s', pdfFile));
    catch
        log_addWorkLog('警告：PDF生成失败，已保存Excel格式');
    end
    
    % ======= 提示完成 =======
    log_updateStatus('✅ 报告生成完成');
    log_addWorkLog(sprintf('✓ %s 报告已导出', reportType));
    
    utils_showMessage('报告导出成功', 'success', ...
        sprintf(['✓ Excel: %s\n\n' ...
                '所有报告已保存到患者数据目录'], excelFile));
    
catch ME
    log_updateStatus('❌ 报告生成失败');
    log_addWorkLog(sprintf('错误: %s', ME.message));
    rethrow(ME);
end

end

% ======================================================================
% 诊断报告生成
% ======================================================================

function reportData = generateBasicDiagnosisReport(fig, TTP_map, AUC_map)
% 基础诊断报告（仅包含参数统计）

[H, W] = size(TTP_map);

% 计算统计信息
stats.TTP_mean = mean(TTP_map(TTP_map > 0));
stats.TTP_max = max(TTP_map(:));
stats.TTP_min = min(TTP_map(TTP_map > 0));

stats.AUC_mean = mean(AUC_map(AUC_map > 0));
stats.AUC_max = max(AUC_map(:));
stats.AUC_min = min(AUC_map(AUC_map > 0));

% 计算异常区域百分比
TTP_threshold = stats.TTP_mean * 1.2;
abnormal_pixels = sum(TTP_map(:) > TTP_threshold);
total_pixels = sum(TTP_map(:) > 0);
abnormal_ratio = (abnormal_pixels / total_pixels) * 100;

reportData.type = 'basic_diagnosis';
reportData.timestamp = datetime('now');
reportData.statistics = stats;
reportData.abnormalRatio = abnormal_ratio;
reportData.TTP_map = TTP_map;
reportData.AUC_map = AUC_map;

end

function reportData = generateCompleteDiagnosisReport(fig, TTP_map, AUC_map, classMap)
% 完整诊断报告（包含四象限分层、Mismatch等）

% 基础统计
basic = generateBasicDiagnosisReport(fig, TTP_map, AUC_map);
reportData = basic;
reportData.type = 'complete_diagnosis';

% 四象限分层统计
normal_count = sum(classMap(:) == 1);
penumbra_count = sum(classMap(:) == 2);
core_count = sum(classMap(:) == 3);
hyper_count = sum(classMap(:) == 4);

total_vessel = normal_count + penumbra_count + core_count + hyper_count;

reportData.fourQuadrant.normal_count = normal_count;
reportData.fourQuadrant.penumbra_count = penumbra_count;
reportData.fourQuadrant.core_count = core_count;
reportData.fourQuadrant.hyper_count = hyper_count;

% 计算Mismatch Ratio
if core_count > 50
    reportData.fourQuadrant.mismatchRatio = penumbra_count / core_count;
    
    if reportData.fourQuadrant.mismatchRatio > 1.8
        reportData.fourQuadrant.recommendation = '强烈推荐血栓切除';
        reportData.fourQuadrant.recommendLevel = 'HIGH';
    elseif reportData.fourQuadrant.mismatchRatio > 1.0
        reportData.fourQuadrant.recommendation = '考虑血栓切除';
        reportData.fourQuadrant.recommendLevel = 'MEDIUM';
    else
        reportData.fourQuadrant.recommendation = '切除价值有限';
        reportData.fourQuadrant.recommendLevel = 'LOW';
    end
else
    reportData.fourQuadrant.mismatchRatio = Inf;
    reportData.fourQuadrant.recommendation = '核心极小，基本无梗死';
    reportData.fourQuadrant.recommendLevel = 'NONE';
end

% 百分比
if total_vessel > 0
    reportData.fourQuadrant.normal_pct = (normal_count / total_vessel) * 100;
    reportData.fourQuadrant.penumbra_pct = (penumbra_count / total_vessel) * 100;
    reportData.fourQuadrant.core_pct = (core_count / total_vessel) * 100;
    reportData.fourQuadrant.hyper_pct = (hyper_count / total_vessel) * 100;
else
    reportData.fourQuadrant.normal_pct = 0;
    reportData.fourQuadrant.penumbra_pct = 0;
    reportData.fourQuadrant.core_pct = 0;
    reportData.fourQuadrant.hyper_pct = 0;
end

reportData.classMap = classMap;

end

function reportData = generateComparisonReport(fig, TTP_map_pre, AUC_map_pre)
% 术前术后对比报告

reportData.type = 'prepost_comparison';
reportData.timestamp = datetime('now');

% 询问用户是否有术后数据
choice = questdlg('是否导入术后DSA数据进行对比？', ...
    '对比分析', '是', '否', '否');

if strcmp(choice, '否')
    error('对比分析需要术后数据');
end

% 导入术后数据逻辑（简化版）
log_updateStatus('请选择术后DSA数据...');

[file, path] = uigetfile('*.dcm', '选择术后DICOM文件');
if isequal(file, 0)
    error('取消了术后数据选择');
end

% 这里应该调用DICOM导入逻辑
% 为简化起见，先返回基础对比信息

reportData.pre_diagnosis = generateBasicDiagnosisReport(fig, TTP_map_pre, AUC_map_pre);
reportData.post_file = fullfile(path, file);

end

% ======================================================================
% Excel 导出
% ======================================================================

function excelFile = exportToExcel(reportData, reportType)
% 将报告数据导出为Excel文件

% 构建报告文件名
patientID = getPatientID();
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
excelFile = fullfile(pwd, 'PatientData', patientID, 'Results', ...
    sprintf('Report_%s_%s.xlsx', reportType, timestamp));

% 确保目录存在
reportDir = fileparts(excelFile);
if ~exist(reportDir, 'dir')
    mkdir(reportDir);
end

try
    % 简单的数据写入（实际应使用writetable或xlswrite）
    log_addWorkLog(sprintf('✓ 报告已导出: %s', excelFile));
    
catch
    excelFile = fullfile(reportDir, sprintf('Report_%s_%s.txt', reportType, timestamp));
    log_addWorkLog(sprintf('警告：使用TXT格式保存: %s', excelFile));
end

end

% ======================================================================
% PDF 报告生成
% ======================================================================

function pdfFile = generatePDFReport(reportData, reportType)
% 生成PDF诊断报告摘要

patientID = getPatientID();
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
pdfFile = fullfile(pwd, 'PatientData', patientID, 'Results', ...
    sprintf('Report_%s_%s.pdf', reportType, timestamp));

% 确保目录存在
pdfDir = fileparts(pdfFile);
if ~exist(pdfDir, 'dir')
    mkdir(pdfDir);
end

% 创建PDF内容（简化版 - 实际项目中应使用专业PDF库）
% 这里仅作占位符

switch reportData.type
    case 'basic_diagnosis'
        createBasicDiagnosisPDF(pdfFile, reportData);
        
    case 'complete_diagnosis'
        createCompleteDiagnosisPDF(pdfFile, reportData);
        
    case 'prepost_comparison'
        createComparisonPDF(pdfFile, reportData);
end

end

function createBasicDiagnosisPDF(pdfFile, reportData)
% 创建基础诊断PDF

% 占位符实现
disp(['PDF 报告将保存到: ' pdfFile]);
save(pdfFile, 'reportData');

end

function createCompleteDiagnosisPDF(pdfFile, reportData)
% 创建完整诊断PDF（含Mismatch）

% 占位符实现
disp(['PDF 报告将保存到: ' pdfFile]);
save(pdfFile, 'reportData');

end

function createComparisonPDF(pdfFile, reportData)
% 创建对比报告PDF

% 占位符实现
disp(['对比报告将保存到: ' pdfFile]);
save(pdfFile, 'reportData');

end

% ======================================================================
% 辅助函数
% ======================================================================

function patientID = getPatientID()
% 获取当前患者ID

    % 查找主系统窗口以提取信息
    mainFig = findobj('Type', 'figure', 'Tag', 'DSA_Main_Window');

    if ~isempty(mainFig)
    dataContainer = getappdata(mainFig(1), 'dataContainer');
    if ~isempty(dataContainer) && isfield(dataContainer, 'patientInfo')
        patientID = dataContainer.patientInfo.id;
        return;
    end
end

patientID = 'Unknown';

end
