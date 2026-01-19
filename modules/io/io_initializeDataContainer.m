function io_initializeDataContainer(fig)
    % 初始化数据容器（migrated to modules/io）
    data = guidata(fig);
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
    data.lobeNames = {'额叶', '顶叶', '颞叶', '枕叶'};
    data.colors = [
        0.3, 0.6, 0.9;  
        0.9, 0.6, 0.3;  
        0.3, 0.9, 0.6;  
        0.9, 0.3, 0.6   
    ];
    data.analysisInfo = struct();
    data.analysisInfo.timestamp = datestr(now);
    data.analysisInfo.softwareVersion = 'v3.0';
    guidata(fig, data);
    log_addWorkLog('数据容器初始化完成');
end
