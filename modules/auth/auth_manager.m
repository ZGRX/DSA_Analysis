function [isValid, doctorName] = auth_manager(username, password)
% 简单的医生账号验证模块
% 在实际生产环境中，这里应该连接数据库或加密的配置文件

isValid = false;
doctorName = '';

% 预设账号列表 (模拟数据库)
% 格式: username -> {password, DisplayName}
accounts = containers.Map();
accounts('admin') = {'admin', '系统管理员'};
accounts('doctor') = {'123456', '值班医师'};
accounts('zhangsan') = {'123', '张三主治医师'};

if isKey(accounts, username)
    userInfo = accounts(username);
    storedPassword = userInfo{1};
    displayName = userInfo{2};
    
    if strcmp(password, storedPassword)
        isValid = true;
        doctorName = displayName;
    end
end
end
