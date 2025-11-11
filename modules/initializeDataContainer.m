<<<<<<< HEAD
function initializeDataContainer(fig)
    % 初始化数据容器
    % 输入: fig - 主窗口句柄
    
    data = guidata(fig);
    
    % 基本数据结构
    data.img2D = [];
    data.img4D = [];
    data.info = [];
    data.roiMask = [];
    data.roiPositions = [];
    data.timeSeriesData = [];
    data.currentFrame = 1;
    data.totalFrames = 1;
    data.frameRate = 4;
    data.startFrame = 1;
    data.endFrame = 1;
    data.processedSeries = [];
    data.smoothedLobeData = [];
    data.TMAX_times = [];
    data.AUC_values = [];
    data.t_highres = [];
    data.perfusionParams = [];
    data.fileName = '';
    data.filePath = '';
    data.roiBaselines = [];
    
    % 脑叶名称
    data.lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    
    % ROI颜色
    data.colors = [
        0.3, 0.6, 0.9;  % 额叶 - 蓝色
        0.9, 0.6, 0.3;  % 顶叶 - 橙色
        0.3, 0.9, 0.6;  % 颞叶 - 绿色
        0.9, 0.3, 0.6   % 枕叶 - 粉色
    ];
    
    % 分析信息
    data.analysisInfo = struct();
    data.analysisInfo.timestamp = datestr(now);
    data.analysisInfo.softwareVersion = 'v3.0';
    
    % 存储数据
    guidata(fig, data);
    
    % 初始化工作日志
    addWorkLog('数据容器初始化完成');
end
=======
function initializeDataContainer(fig)
    % 初始化数据容器
    % 输入: fig - 主窗口句柄
    
    data = guidata(fig);
    
    % 基本数据结构
    data.img2D = [];
    data.img4D = [];
    data.info = [];
    data.roiMask = [];
    data.roiPositions = [];
    data.timeSeriesData = [];
    data.currentFrame = 1;
    data.totalFrames = 1;
    data.frameRate = 4;
    data.startFrame = 1;
    data.endFrame = 1;
    data.processedSeries = [];
    data.smoothedLobeData = [];
    data.TMAX_times = [];
    data.AUC_values = [];
    data.t_highres = [];
    data.perfusionParams = [];
    data.fileName = '';
    data.filePath = '';
    data.roiBaselines = [];
    
    % 脑叶名称
    data.lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    
    % ROI颜色
    data.colors = [
        0.3, 0.6, 0.9;  % 额叶 - 蓝色
        0.9, 0.6, 0.3;  % 顶叶 - 橙色
        0.3, 0.9, 0.6;  % 颞叶 - 绿色
        0.9, 0.3, 0.6   % 枕叶 - 粉色
    ];
    
    % 分析信息
    data.analysisInfo = struct();
    data.analysisInfo.timestamp = datestr(now);
    data.analysisInfo.softwareVersion = 'v3.0';
    
    % 存储数据
    guidata(fig, data);
    
    % 初始化工作日志
    addWorkLog('数据容器初始化完成');
end
>>>>>>> 4d5e5c9 (Initial commit)
