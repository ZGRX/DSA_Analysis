function resetAll(~,~)
    fig = gcf;
    data = guidata(fig);
    
    choice = questdlg('确定要重置所有数据吗？', '重置确认', '是', '否', '否');
    if strcmp(choice, '否')
        return;
    end
    
    stopPlayback();
    
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
    data.analysisInfo.timestamp = '';
    guidata(fig, data);
    
    resetUIControls(fig);
    log_updateStatus('已重置所有数据 - 请导入DSA数据');
end

function resetUIControls(fig)
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

    preOpROIStatus = getappdata(fig, 'preOpROIStatus');
    postOpROIStatus = getappdata(fig, 'postOpROIStatus');
    riskResultText = getappdata(fig, 'riskResultText');
    mainAxes = getappdata(fig, 'mainAxes');
    paramTable = getappdata(fig, 'paramTable');
    
    if ishandle(frameSlider), set(frameSlider, 'Value', 1, 'Enable', 'off'); end
    if ishandle(currentFrameText), set(currentFrameText, 'String', '1'); end
    if ishandle(totalFramesText), set(totalFramesText, 'String', '1'); end
    if ishandle(playBtn), set(playBtn, 'Enable', 'off', 'BackgroundColor', [0.2, 0.7, 0.2]); end
    if ishandle(pauseBtn), set(pauseBtn, 'Enable', 'off', 'BackgroundColor', [0.5, 0.5, 0.5]); end
    if ishandle(firstFrameBtn), set(firstFrameBtn, 'Enable', 'off'); end
    if ishandle(prevFrameBtn), set(prevFrameBtn, 'Enable', 'off'); end
    if ishandle(nextFrameBtn), set(nextFrameBtn, 'Enable', 'off'); end
    if ishandle(lastFrameBtn), set(lastFrameBtn, 'Enable', 'off'); end
    if ishandle(startFrameEdit), set(startFrameEdit, 'String', '1', 'Enable', 'off'); end
    if ishandle(endFrameEdit), set(endFrameEdit, 'String', '1', 'Enable', 'off'); end
    if ishandle(frameRateEdit), set(frameRateEdit, 'String', '4', 'Enable', 'off'); end

    if ishandle(preOpROIStatus), set(preOpROIStatus, 'String', '术前:未标定', 'ForegroundColor', [1, 0.8, 0.8]); end
    if ishandle(postOpROIStatus), set(postOpROIStatus, 'String', '术后:未标定', 'ForegroundColor', [1, 0.8, 0.8]); end
    if ishandle(riskResultText), set(riskResultText, 'String', '未评估', 'ForegroundColor', [1, 1, 0]); end
    
    if ishandle(paramTable)
        paramNames = {'TTP 达峰(s)', 'MTT 平均(s)', 'TU 到达(s)', 'FWHM 展宽(s)', 'AUC 流量', 'Peak 峰值', 'WFD 波形失真', 'TTS 时移(s)'};
        tableData = cell(length(paramNames), 3);
        tableData(:,1) = paramNames';
        for i = 1:length(paramNames)
            tableData{i,2} = '--';
            tableData{i,3} = '--';
        end
        set(paramTable, 'Data', tableData);
        set(paramTable, 'ColumnName', {'参数指标', '近端(Proximal)', '远端(Distal)'});
        set(paramTable, 'RowName', []);
        set(paramTable, 'ColumnWidth', {120, 85, 90});
        set(paramTable, 'ColumnEditable', false);
    end
    
    if ishandle(mainAxes)
        axes(mainAxes); cla; title('DICOM影像显示区域', 'Color', [0.3, 0.5, 0.7], 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Microsoft YaHei');
    end
end
