function [isValid, doctorName] = auth_manager(username, password)
% 简单的医生账号验证模块
% 在实际生产环境中，这里应该连接数据库或加密的配置文件

isValid = false;
doctorName = '';

% 从配置文件读取账号列表
configFile = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'config', 'doctors.json');

if exist(configFile, 'file')
    try
        raw = fileread(configFile);
        % MATLAB 内置 jsondecode (R2016b+)
        doctors = jsondecode(raw);
        if isstruct(doctors), doctors = num2cell(doctors); end
        for k = 1:numel(doctors)
            d = doctors{k};
            if strcmp(d.username, username) && strcmp(d.password, password)
                isValid = true;
                doctorName = d.name;
                return;
            end
        end
        return; % 文件存在但未匹配
    catch
        % JSON解析失败，回退到硬编码
    end
end

% 兜底硬编码账号（在 config/doctors.json 缺失时保证系统可用）
accounts = containers.Map();
accounts('admin')   = {'admin',  '系统管理员'};
accounts('doctor')  = {'123456', '值班医师'};
accounts('zhangsan')= {'123',    '张三主治医师'};

if isKey(accounts, username)
    userInfo = accounts(username);
    if strcmp(password, userInfo{1})
        isValid = true;
        doctorName = userInfo{2};
    end
end
end
