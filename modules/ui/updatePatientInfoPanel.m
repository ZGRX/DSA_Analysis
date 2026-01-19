function updatePatientInfoPanel(fig, patientInfo)
% 更新主界面上的患者信息面板
% fig: 主窗口句柄
% patientInfo: 患者信息结构体

% 获取 InfoPanel 的句柄 (我们在 createInfoArea 中需要存储它，或者重新查找)
% 为了简单起见，我们假设 createInfoArea 已经将文本控件的句柄存储在了 appdata 中
% 所以我们需要先修改 createInfoArea.m 来存储这个句柄

infoTextControl = getappdata(fig, 'patientInfoTextControl');

if ishandle(infoTextControl)
    if isempty(patientInfo) || ~isstruct(patientInfo)
        infoText = {'患者信息: 未录入'};
    else
        % 辅助函数处理空值
        val = @(f) getFieldOrEmpty(patientInfo, f);
        
        infoText = {
            sprintf('姓名: %s', val('name'))
            sprintf('性别: %s', val('gender'))
            sprintf('年龄: %s', val('age'))
            sprintf('住院号: %s', val('id'))
            sprintf('手术日期: %s', val('date'))
            };
    end
    
    set(infoTextControl, 'String', infoText);
end

% 同时更新 appdata 中的 patientInfo
setappdata(fig, 'patientInfo', patientInfo);
end

function str = getFieldOrEmpty(s, f)
if isfield(s, f) && ~isempty(s.(f))
    if isnumeric(s.(f))
        str = num2str(s.(f));
    else
        str = s.(f);
    end
else
    str = '未录入';
end
end
