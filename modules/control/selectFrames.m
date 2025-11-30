function selectFrames(~,~)
    fig = gcf;  % 主界面图形句柄
    data = guidata(fig);
    
    if isempty(data) || (isempty(data.img4D) && isempty(data.processedSeries))
        utils_showMessage('没有多帧数据可用', 'error');
        return;
    end
    
    log_updateStatus('正在打开帧选择界面...');
    
    % 创建帧选择窗口
    figSelect = figure('Name','帧数选择',...
                      'NumberTitle','off',...
                      'Position',[400,300,600,500],...
                      'MenuBar','none',...
                      'ToolBar','none',...
                      'Color',[0.95 0.95 0.95]);
    
    setappdata(figSelect, 'mainFigure', fig);
    setappdata(figSelect, 'mainData', data);
    
    % 显示第一帧
    subplot(2,2,1);
    imgToShow = getFrameImage(data, 1);
    imagesc(imgToShow); colormap(gray); axis image; axis off;
    caxis([min(imgToShow(:)) max(imgToShow(:))]);
    title('第一帧');
    
    % 显示最后一帧
    subplot(2,2,2);
    imgToShow = getFrameImage(data, data.totalFrames);
    imagesc(imgToShow); colormap(gray); axis image; axis off;
    caxis([min(imgToShow(:)) max(imgToShow(:))]);
    title('最后一帧');
    
    % 面板与控件
    uipanel('Parent',figSelect,'Title','帧范围选择',...
           'Position',[0.1 0.4 0.8 0.25],...
           'BackgroundColor',[0.9 0.9 0.9]);
    
    uicontrol(figSelect,'Style','text','String','起始帧:',...
             'Position',[50,150,60,20],'HorizontalAlignment','left');
    startEdit = uicontrol(figSelect,'Style','edit','String','1',...
                         'Position',[120,150,60,25],'BackgroundColor',[1,1,1]);
    
    uicontrol(figSelect,'Style','text','String','结束帧:',...
             'Position',[200,150,60,20],'HorizontalAlignment','left');
    endEdit = uicontrol(figSelect,'Style','edit','String',num2str(data.totalFrames),...
                       'Position',[270,150,60,25],'BackgroundColor',[1,1,1]);
    
    uicontrol(figSelect,'Style','text','String',sprintf('总帧数: %d', data.totalFrames),...
             'Position',[350,150,100,20],'HorizontalAlignment','left');
    
    uicontrol(figSelect,'Style','pushbutton','String','预览当前帧',...
             'Position',[150,100,100,30],...
             'Callback',@previewCurrentFrame);
    
    uicontrol(figSelect,'Style','pushbutton','String','确定',...
             'Position',[270,100,80,30],...
             'Callback',@confirmFrameSelection);
    
    uicontrol(figSelect,'Style','pushbutton','String','取消',...
             'Position',[360,100,80,30],...
             'Callback',@(~,~) delete(figSelect));
    
    function previewCurrentFrame(~,~)
        try
            mainData = getappdata(figSelect, 'mainData');
            startFrame = str2double(get(startEdit, 'String'));
            endFrame = str2double(get(endEdit, 'String'));
            if isnan(startFrame) || isnan(endFrame) || startFrame < 1 || endFrame > mainData.totalFrames || startFrame > endFrame
                utils_showMessage('请输入有效的帧范围', 'error');
                return;
            end
            midFrame = round((startFrame + endFrame) / 2);
            previewImg = getFrameImage(mainData, midFrame);
            previewFig = figure('Name','帧预览');
            imagesc(previewImg); colormap(gray); axis image;
            caxis([min(previewImg(:)) max(previewImg(:))]);
            title(sprintf('预览帧 %d (范围: %d-%d)', midFrame, startFrame, endFrame));
            colorbar;
        catch ME
            utils_showMessage('帧预览失败', 'error', ME.message);
        end
    end
    
    function confirmFrameSelection(~,~)
        try
            mainFig = getappdata(figSelect, 'mainFigure');
            mainData = getappdata(figSelect, 'mainData');
            startFrame = str2double(get(startEdit, 'String'));
            endFrame = str2double(get(endEdit, 'String'));
            if isnan(startFrame) || isnan(endFrame) || startFrame < 1 || endFrame > mainData.totalFrames || startFrame > endFrame
                utils_showMessage('请输入有效的帧范围', 'error');
                return;
            end
            mainData.startFrame = startFrame;
            mainData.endFrame = endFrame;
            mainData.currentFrame = startFrame;
            guidata(mainFig, mainData);
            
            startFrameEdit = getappdata(mainFig, 'startFrameEdit');
            endFrameEdit = getappdata(mainFig, 'endFrameEdit');
            frameSlider = getappdata(mainFig, 'frameSlider');
            currentFrameText = getappdata(mainFig, 'currentFrameText');
            if ishandle(startFrameEdit), set(startFrameEdit, 'String', num2str(startFrame)); end
            if ishandle(endFrameEdit), set(endFrameEdit, 'String', num2str(endFrame)); end
            if ishandle(frameSlider), set(frameSlider, 'Value', startFrame); end
            if ishandle(currentFrameText), set(currentFrameText, 'String', num2str(startFrame)); end
            
            updateFrameDisplayForMain(mainFig);
            updateStatusForMain(mainFig, sprintf('已选择帧范围: %d-%d', startFrame, endFrame));
            delete(figSelect);
        catch ME
            utils_showMessage('帧选择失败', 'error', ME.message);
        end
    end
end

function img = getFrameImage(data, frameIdx)
    if ~isempty(data.processedSeries)
        img = data.processedSeries(:,:,frameIdx);
    else
        if ndims(data.img4D) == 4
            frameData = data.img4D(:,:,1,frameIdx);
        else
            frameData = data.img4D(:,:,frameIdx);
        end
        if isinteger(frameData), frameData = double(frameData); end
        img = 255 - frameData;
    end
end

function updateFrameDisplayForMain(mainFig)
    data = guidata(mainFig);
    if isempty(data) || (isempty(data.img4D) && isempty(data.processedSeries)), return; end
    currentFrame = data.currentFrame;
    if ~isempty(data.processedSeries)
        currentImg = data.processedSeries(:,:,currentFrame);
    elseif ~isempty(data.img4D)
        if ndims(data.img4D) == 4
            frameData = data.img4D(:,:,1,currentFrame);
        else
            frameData = data.img4D(:,:,currentFrame);
        end
        if isinteger(frameData), frameData = double(frameData); end
        currentImg = 255 - frameData;
    else
        return;
    end
    mainAxes = getappdata(mainFig, 'mainAxes');
    if ishandle(mainAxes)
        axes(mainAxes);
        imagesc(currentImg); colormap(gray); axis image;
        caxis([min(currentImg(:)) max(currentImg(:))]);
        if isfield(data,'roiPositions') && ~isempty(data.roiPositions)
            hold on;
            for i = 1:size(data.roiPositions,1)
                pos = data.roiPositions(i,:);
                lobe = ceil(i/3);
                color = data.colors(lobe,:);
                rectangle('Position', pos, 'EdgeColor', color, 'LineWidth', 2);
                text(pos(1)+2, pos(2)-8, sprintf('%s-%d', data.lobeNames{lobe}, mod(i-1,3)+1), ...
                     'Color', color, 'FontWeight', 'bold', 'BackgroundColor', 'white','FontSize',8);
            end
            hold off;
        end
        title(sprintf('%s - 帧 %d/%d', data.fileName, currentFrame, data.totalFrames), 'Color', 'white', 'Interpreter', 'none');
    end
    currentFrameText = getappdata(mainFig, 'currentFrameText');
    if ishandle(currentFrameText), set(currentFrameText, 'String', num2str(currentFrame)); end
    drawnow;
end

function updateStatusForMain(mainFig, message)
    resultsText = getappdata(mainFig, 'resultsText');
    if isempty(resultsText) || ~ishandle(resultsText)
        fprintf('[%s] %s\n', datestr(now,'HH:MM:SS'), message);
        return;
    end
    currentText = get(resultsText, 'String');
    if ischar(currentText), currentText = {currentText}; end
    timestamp = datestr(now, 'HH:MM:SS');
    newMessage = sprintf('[%s] %s', timestamp, message);
    newText = [currentText; {newMessage}];
    if length(newText) > 15, newText = newText(end-14:end); end
    set(resultsText, 'String', newText);
    set(resultsText, 'Value', length(newText));
    drawnow;
end
