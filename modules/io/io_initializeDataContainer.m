function io_initializeDataContainer(fig)
    % 初始化数据容器（migrated to modules/io）
    % 统一使用 guidata 作为主数据存储，appdata 仅用于UI状态
    data = guidata(fig);
    
    % 基础图像数据
    data.img2D = [];
    data.img4D = [];
    data.info = [];
    
    % ROI相关
    data.roiMask = [];
    data.roiPositions = [];
    data.roiBaselines = [];
    data.roiNames = {'狭窄近端 (Proximal)', '狭窄远端 (Distal)'}; % 预先初始化，避免未放置ROI时其他模块访问未定义字段
    data.roiColors = [1, 0.4, 0.4; 0.4, 0.8, 1]; % 红色(近端)、蓝色(远端)
    
    % 时间序列数据
    data.timeSeriesData = [];
    data.currentFrame = 1;
    data.totalFrames = 1;
    data.frameRate = 4;
    data.startFrame = 1;
    data.endFrame = 1;
    data.processedSeries = [];
    data.smoothedLobeData = [];
    
    % 灌注参数（ROI级别）
    data.TMAX_times = [];
    data.AUC_values = [];
    data.t_highres = [];
    data.perfusionParams = [];
    
    % 像素级参数图（新增：统一存储在 guidata 中）
    data.ParamMaps = struct();
    data.ParamMaps.TTP = [];
    data.ParamMaps.AUC = [];
    data.ParamMaps.CBF = [];
    data.ParamMaps.CBV = [];
    data.ParamMaps.MTT = [];
    data.ParamMaps.vesselMask = [];
    
    % 分类和风险评估结果
    data.classMap = [];
    data.perfusionRiskMap = [];
    
    % 文件信息
    data.fileName = '';
    data.filePath = '';
    
    % 端点显示配置（双端架构）
    data.endpointNames = {'狭窄近端 (Proximal)', '狭窄远端 (Distal)'};
    data.colors = [
        1.0, 0.4, 0.4;  % 近端: 红
        0.4, 0.8, 1.0   % 远端: 蓝
    ];
    
    % 分析元信息
    data.analysisInfo = struct();
    data.analysisInfo.timestamp = datestr(now);
    data.analysisInfo.softwareVersion = 'v5.0';
    
    guidata(fig, data);
    log_addWorkLog('数据容器初始化完成（包含像素级参数图结构）');
end
