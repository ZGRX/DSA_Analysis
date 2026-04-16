function io_importDSA(varargin)
% 原 importDSA 的实现，已迁移到 modules/io，函数名改为 io_importDSA
% 保持原有行为，参数采用 varargin 以兼容 wrapper 调用
fig = gcf;
data = guidata(fig);

% 检查是否从文件管理器自动加载
if isappdata(fig, 'autoLoadFile')
    % 从文件管理器加载单个文件
    fullName = getappdata(fig, 'autoLoadFile');
    [pname, fname, ext] = fileparts(fullName);
    fname = [fname, ext];
    log_updateStatus(sprintf('正在从文件管理器加载: %s', fname));
    log_addWorkLog(sprintf('从文件管理器加载文件: %s', fname));
elseif isappdata(fig, 'autoLoadFolder')
    % 从文件管理器加载文件夹
    pname = getappdata(fig, 'autoLoadFolder');
    
    % 优先使用递归搜索到的文件列表
    if isappdata(fig, 'autoLoadFiles')
        dicomFileList = getappdata(fig, 'autoLoadFiles');
        rmappdata(fig, 'autoLoadFiles');  % 清理
        if ~isempty(dicomFileList)
            fullName = dicomFileList{1};
            [pname, fname, ext] = fileparts(fullName);
            fname = [fname, ext];
        else
            utils_showMessage('未找到DICOM文件', 'error');
            return;
        end
    else
        % 兼容旧逻辑：在顶层文件夹中搜索
        dicomFiles = dir(fullfile(pname, '*.dcm'));
        if isempty(dicomFiles)
            dicomFiles = dir(fullfile(pname, '*.dicom'));
        end
        if isempty(dicomFiles)
            dicomFiles = dir(fullfile(pname, '*.DCM'));
        end
        if isempty(dicomFiles)
            utils_showMessage('未找到DICOM文件', 'error');
            return;
        end
        fname = dicomFiles(1).name;
        fullName = fullfile(pname, fname);
    end
    log_updateStatus('正在从文件管理器加载DICOM数据...');
    log_addWorkLog('从文件管理器加载DSA数据...');
else
    % 正常用户选择文件
    log_updateStatus('正在选择DICOM文件...');
    log_addWorkLog('开始导入DSA数据...');
    
    [fname, pname] = uigetfile({'*.dcm;*.DCM;*.ima;*.IMA','DICOM文件 (*.dcm,*.ima)';...
        '*.*','所有文件'},...
        '选择DSA DICOM文件');
    if isequal(fname, 0)
        log_updateStatus('已取消选择');
        log_addWorkLog('用户取消了DSA数据导入');
        return;
    end
    fullName = fullfile(pname, fname);
    % 重新导入前先清空旧状态
    utils_resetAppState(fig);
end

try
    log_updateStatus('正在读取DICOM文件...');
    info = dicominfo(fullName);
    img = dicomread(fullName);
    
    dims = size(img);
    fprintf('图像维度: %s\n', mat2str(dims));
    
    if ndims(img) == 4
        totalFrames = size(img, 4);
        img2D = img(:,:,1,1);
        img4D = img;
    elseif ndims(img) == 3
        if size(img, 3) > 10
            totalFrames = size(img, 3);
            img2D = img(:,:,1);
            img4D = img;
        else
            totalFrames = 1;
            img2D = img(:,:,1);
            img4D = [];
            warndlg('检测到可能是多切片数据，将作为单帧处理');
        end
    else
        totalFrames = 1;
        img2D = img;
        img4D = [];
        warndlg('检测到单帧2D数据，无法进行时间序列分析');
    end
    
    % 灰度反转和位深归一化
    % 如果是16位数据或最大值超过255，先归一化到0-255
    is16Bit = max(img2D(:)) > 255 || (isfield(info, 'BitDepth') && info.BitDepth > 8);
    
    % 【医学修正】使用全序列全局最大值统一归一化，
    % 保留帧间相对强度关系，确保 TDC 曲线具备生理学意义
    if is16Bit
        maxVal = double(max(img(:)));
        if maxVal > 0
            img2D = double(img2D) / maxVal * 255;
        end
        log_addWorkLog('检测到高位深图像，已用全序列全局最大值归一化到8位范围');
    end
    
    % 反转灰度 (DSA: 血管黑->白，背景白->黑)
    % 原理: 染色越深(灰度越小) -> 反转后值越大(密度越高)
    img2D = 255 - img2D;
    
    % 【DSA减影核心修复】
    % 原来的方案（全局归一化）会把造影剂信号压缩到仅2-6个计数，AUC接近零
    % 正确做法：用前几帧作为掩膜帧，做DSA减影，提取纯造影剂信号
    processedSeries = [];
    if ~isempty(img4D)
        if ndims(img4D) == 4
            nF = size(img4D, 4);
            processedSeries = zeros(size(img4D,1), size(img4D,2), nF, 'double');
            % 用前3帧（或15%帧数）取均值作为背景掩膜（无造影剂的纯解剖结构）
            nMask = max(1, min(3, floor(nF * 0.15)));
            mask4D = double(mean(img4D(:,:,1,1:nMask), 4));
            for i = 1:nF
                frameData = double(img4D(:,:,1,i));
                % DSA减影：掩膜-当前帧（碘剂区X射线吸收↑→像素值↓→差值为正）
                dsaFrame = mask4D - frameData;
                processedSeries(:,:,i) = max(0, dsaFrame);
            end
            % 全序列归一化到0-255以便显示
            globalPeak = max(processedSeries(:));
            if globalPeak > 0
                processedSeries = processedSeries / globalPeak * 255;
            end
            log_addWorkLog(sprintf('DSA减影完成: 掩膜帧=%d, 总帧=%d', nMask, nF));
        else
            nF = size(img4D, 3);
            processedSeries = zeros(size(img4D,1), size(img4D,2), nF, 'double');
            nMask = max(1, min(3, floor(nF * 0.15)));
            mask3D = double(mean(img4D(:,:,1:nMask), 3));
            for i = 1:nF
                frameData = double(img4D(:,:,i));
                dsaFrame = mask3D - frameData;
                processedSeries(:,:,i) = max(0, dsaFrame);
            end
            globalPeak = max(processedSeries(:));
            if globalPeak > 0
                processedSeries = processedSeries / globalPeak * 255;
            end
            log_addWorkLog(sprintf('DSA减影完成: 掩膜帧=%d, 总帧=%d', nMask, nF));
        end
    end

    
    % --- 核心要求：重置 ROI 与分析数据 (确保新图像不携带旧数据) ---
    data.roiMask = [];
    data.roiPositions = [];
    data.timeSeriesData = [];
    data.perfusionParams = [];
    
    % 更新 UI 状态
    preStatus = getappdata(fig, 'preOpROIStatus');
    if ishandle(preStatus), set(preStatus, 'String', '术前:无', 'ForegroundColor', [0.9, 0.3, 0.3]); end
    
    postStatus = getappdata(fig, 'postOpROIStatus');
    if ishandle(postStatus), set(postStatus, 'String', '术后:无', 'ForegroundColor', [0.9, 0.3, 0.3]); end
    
    riskText = getappdata(fig, 'riskResultText');
    if ishandle(riskText), set(riskText, 'String', '未评估', 'ForegroundColor', [0.9, 0.5, 0.1]); end
    
    pTable = getappdata(fig, 'paramTable');
    if ishandle(pTable), set(pTable, 'Data', []); end
    
    data.analysisInfo.timestamp = char(datetime('now'));
    
    % 更新基础图像数据
    data.img2D = img2D;
    data.img4D = img4D;
    data.processedSeries = processedSeries;
    data.info = info;
    data.totalFrames = totalFrames;
    data.currentFrame = 1;
    data.startFrame = 1;
    data.endFrame = totalFrames;
    data.fileName = fname;
    data.filePath = pname;
    
    % --- 自动提取患者信息 ---
    extractedInfo = struct('name', '', 'gender', '', 'age', '', 'id', '', 'date', '');
    
    % 姓名
    if isfield(info, 'PatientName')
        if isstruct(info.PatientName) && isfield(info.PatientName, 'FamilyName')
            extractedInfo.name = info.PatientName.FamilyName;
        else
            extractedInfo.name = char(info.PatientName); % 也是为了安全转换
        end
    end
    
    % ID
    if isfield(info, 'PatientID')
        extractedInfo.id = char(info.PatientID);
    end
    
    % 性别
    if isfield(info, 'PatientSex')
        rawSex = char(info.PatientSex);
        if strcmpi(rawSex, 'M')
            extractedInfo.gender = '男';
        elseif strcmpi(rawSex, 'F')
            extractedInfo.gender = '女';
        else
            extractedInfo.gender = rawSex;
        end
    end
    
    % 年龄
    if isfield(info, 'PatientAge')
        rawAge = char(info.PatientAge);
        % DICOM年龄通常是 '062Y', 去掉前导0和Y，加上'岁'
        ageNum = regexp(rawAge, '\d+', 'match');
        if ~isempty(ageNum)
            extractedInfo.age = [ageNum{1}, '岁'];
        else
            extractedInfo.age = rawAge;
        end
    elseif isfield(info, 'PatientBirthDate')
        % 尝试计算年龄
        try
            bd = info.PatientBirthDate;
            birthYear = str2double(bd(1:4));
            currentYear = year(datetime('now'));
            extractedInfo.age = sprintf('%d岁', currentYear - birthYear);
        catch
        end
    end
    
    % 日期
    if isfield(info, 'StudyDate')
        dStr = char(info.StudyDate);
    elseif isfield(info, 'SeriesDate')
        dStr = char(info.SeriesDate);
    else
        dStr = '';
    end
    
    if ~isempty(dStr) && length(dStr) == 8
        % YYYYMMDD -> YYYY-MM-DD
        extractedInfo.date = [dStr(1:4), '-', dStr(5:6), '-', dStr(7:8)];
    else
        extractedInfo.date = dStr;
    end
    
    data.patientInfo = extractedInfo;
    
    % 更新界面
    updatePatientInfoPanel(fig, extractedInfo);
    log_addWorkLog('已从DICOM自动提取患者信息');
    
    guidata(fig, data);
    
    % --- 提取结束 ---
    
    % 更新UI控件
    updateUIControlsAfterImport(fig, totalFrames);
    
    % 显示图像
    mainAxes = getappdata(fig, 'mainAxes');
    if ishandle(mainAxes)
        axes(mainAxes);
        imagesc(data.img2D);
        colormap(gray);
        axis image;
        clim([min(data.img2D(:)) max(data.img2D(:))]);
        title(sprintf('%s - 帧 1/%d', fname, totalFrames), 'Color', [0.2, 0.2, 0.2], 'FontSize', 14, 'Interpreter', 'none', 'FontName', 'Microsoft YaHei');
    end
    
    % 正式完成加载
    setappdata(fig, 'isPlaying', false);
    guidata(fig, data);
    updateFrameDisplay(fig); % 触发边界检查，数据初始化时 coreFrame 为 1
    log_updateStatus(sprintf('加载完成: %s (%d帧)', fname, totalFrames));
    log_addWorkLog(sprintf('成功解析并载入DSA序列: %s', fullName));
    
catch ME
    utils_showMessage('DICOM读取失败', 'error', ME.message);
    log_updateStatus('导入失败');
    log_addWorkLog(sprintf('导入失败: %s', ME.message));
end
end

function updateUIControlsAfterImport(fig, totalFrames)
% 更新导入后的UI控件状态
frameSlider = getappdata(fig, 'frameSlider');
currentFrameText = getappdata(fig, 'currentFrameText');
totalFramesText = getappdata(fig, 'totalFramesText');
playBtn = getappdata(fig, 'playBtn');
pauseBtn = getappdata(fig, 'pauseBtn');
firstFrameBtn = getappdata(fig, 'firstFrameBtn');
prevFrameBtn = getappdata(fig, 'prevFrameBtn');
nextFrameBtn = getappdata(fig, 'nextFrameBtn');
lastFrameBtn = getappdata(fig, 'lastFrameBtn');
startFrameEdit = getappdata(fig, 'startFrameEdit');
endFrameEdit = getappdata(fig, 'endFrameEdit');
frameRateEdit = getappdata(fig, 'frameRateEdit');

% 启用控件
if ishandle(frameSlider)
    set(frameSlider, 'Enable', 'on', 'Min', 1, 'Max', totalFrames, 'Value', 1, 'SliderStep', [1/max(1,totalFrames-1), 10/max(1,totalFrames-1)]);
end
if ishandle(playBtn), set(playBtn, 'Enable', 'on'); end
if ishandle(pauseBtn), set(pauseBtn, 'Enable', 'off'); end
if ishandle(firstFrameBtn), set(firstFrameBtn, 'Enable', 'on'); end
if ishandle(prevFrameBtn), set(prevFrameBtn, 'Enable', 'on'); end
if ishandle(nextFrameBtn), set(nextFrameBtn, 'Enable', 'on'); end
if ishandle(lastFrameBtn), set(lastFrameBtn, 'Enable', 'on'); end

if ishandle(currentFrameText), set(currentFrameText, 'String', '1'); end
if ishandle(totalFramesText), set(totalFramesText, 'String', num2str(totalFrames)); end

if ishandle(startFrameEdit), set(startFrameEdit, 'Enable', 'on', 'String', '1'); end
if ishandle(endFrameEdit), set(endFrameEdit, 'Enable', 'on', 'String', num2str(totalFrames)); end
if ishandle(frameRateEdit), set(frameRateEdit, 'Enable', 'on'); end
end
