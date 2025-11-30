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
        % 从文件管理器加载文件夹中的第一个DICOM文件
        pname = getappdata(fig, 'autoLoadFolder');
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
        
        % 灰度反转
        if isinteger(img2D)
            img2D = double(img2D);
        end
        img2D = 255 - img2D;
        
        % 处理整个序列的灰度反转
        processedSeries = [];
        if ~isempty(img4D)
            if ndims(img4D) == 4
                processedSeries = zeros(size(img4D,1), size(img4D,2), size(img4D,4));
                for i = 1:size(img4D, 4)
                    frameData = img4D(:,:,1,i);
                    if isinteger(frameData)
                        frameData = double(frameData);
                    end
                    processedSeries(:,:,i) = 255 - frameData;
                end
            else
                processedSeries = zeros(size(img4D,1), size(img4D,2), size(img4D,3));
                for i = 1:size(img4D, 3)
                    frameData = img4D(:,:,i);
                    if isinteger(frameData)
                        frameData = double(frameData);
                    end
                    processedSeries(:,:,i) = 255 - frameData;
                end
            end
        end
        
        % 更新数据
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
        data.analysisInfo.timestamp = datestr(now);
        guidata(fig, data);
        
        % 更新UI控件
        updateUIControlsAfterImport(fig, totalFrames);
        
        % 显示图像
        mainAxes = getappdata(fig, 'mainAxes');
        if ishandle(mainAxes)
            axes(mainAxes);
            imagesc(data.img2D); 
            colormap(gray); 
            axis image;
            caxis([min(data.img2D(:)) max(data.img2D(:))]);
            title(sprintf('%s - 帧 1/%d', fname, totalFrames), 'Color', 'white', 'FontSize', 14, 'Interpreter', 'none');
        end
        
        log_updateStatus(sprintf('成功导入: %s (%d帧)', fname, totalFrames));
        log_addWorkLog(sprintf('成功导入DSA数据: %s', fname));
        log_addWorkLog(sprintf('图像维度: %s', mat2str(dims)));
        log_addWorkLog(sprintf('总帧数: %d', totalFrames));
        
    catch ME
        utils_showMessage('DICOM读取失败', 'error', ME.message);
        log_updateStatus('导入失败');
        log_addWorkLog(sprintf('导入失败: %s', ME.message));
    end
end

function updateUIControlsAfterImport(fig, totalFrames)
    % 同原实现：更新导入后的UI控件状态
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
    applyRangeBtn = getappdata(fig, 'applyRangeBtn');
    frameRateEdit = getappdata(fig, 'frameRateEdit');
    
    if totalFrames > 1
        if ishandle(frameSlider)
            set(frameSlider, 'Min', 1, 'Max', totalFrames, 'Value', 1,...
                'SliderStep', [1/max(1,totalFrames-1), 10/max(1,totalFrames-1)],...
                'Enable', 'on');
        end
        if ishandle(playBtn)
            set(playBtn, 'Enable', 'on');
        end
        if ishandle(firstFrameBtn)
            set(firstFrameBtn, 'Enable', 'on');
        end
        if ishandle(prevFrameBtn)
            set(prevFrameBtn, 'Enable', 'on');
        end
        if ishandle(nextFrameBtn)
            set(nextFrameBtn, 'Enable', 'on');
        end
        if ishandle(lastFrameBtn)
            set(lastFrameBtn, 'Enable', 'on');
        end
    end
    if ishandle(currentFrameText)
        set(currentFrameText, 'String', '1');
    end
    if ishandle(totalFramesText)
        set(totalFramesText, 'String', num2str(totalFrames));
    end
    if ishandle(startFrameEdit)
        set(startFrameEdit, 'String', '1', 'Enable', 'on');
    end
    if ishandle(endFrameEdit)
        set(endFrameEdit, 'String', num2str(totalFrames), 'Enable', 'on');
    end
    if ishandle(applyRangeBtn)
        set(applyRangeBtn, 'Enable', 'on');
    end
    if ishandle(frameRateEdit)
        set(frameRateEdit, 'Enable', 'on');
    end
end
