function placeROI(~,~)
    % 放置ROI - 为4个脑叶各放置3个ROI
    fig = gcf;
    data = guidata(fig);
    
    if isempty(data.img2D)
        errordlg('请先导入图像');
        addWorkLog('错误: 尝试放置ROI但未导入图像');
        return;
    end
    
    updateStatus('请为4个脑叶各选择3个ROI中心点（共12个点）');
    addWorkLog('开始ROI放置流程');
    imageSize = size(data.img2D);
    roiMask = false(imageSize(1), imageSize(2), 4, 3);
    roiPositions = zeros(12, 4);
    
    mainAxes = getappdata(fig, 'mainAxes');
    if ~ishandle(mainAxes), return; end
    
    axes(mainAxes);
    
    % 获取当前帧图像
    if ~isempty(data.processedSeries)
        currentImg = data.processedSeries(:,:,data.currentFrame);
    elseif ~isempty(data.img4D)
        if ndims(data.img4D) == 4
            frameData = data.img4D(:,:,1,data.currentFrame);
        else
            frameData = data.img4D(:,:,data.currentFrame);
        end
        if isinteger(frameData)
            frameData = double(frameData);
        end
        currentImg = 255 - frameData;
    else
        currentImg = data.img2D;
    end
    
    imagesc(currentImg); 
    colormap(gray); 
    axis image;
    caxis([min(currentImg(:)) max(currentImg(:))]);
    title('请依次为4个脑叶选择ROI中心点', 'Color', 'white');
    hold on;
    
    text(10, 30, '操作说明:', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 12, 'BackgroundColor', 'black');
    text(10, 60, '1. 依次为额叶、顶叶、颞叶、枕叶各选3个点', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
    text(10, 90, '2. 尽量避开血管，选择脑实质区域', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
    text(10, 120, '3. 点击后程序会自动创建5x5 ROI', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
    
    roiCount = 1;
    for lobe = 1:4
        for r = 1:3
            currentText = text(imageSize(2)/2, 30, ...
                sprintf('请为 %s 选择第 %d/3 个ROI中心点', data.lobeNames{lobe}, r), ...
                'Color', data.colors(lobe,:), 'FontWeight', 'bold', 'FontSize', 14, ...
                'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
            
            try
                % 设置十字交叉光标
                set(fig, 'Pointer', 'crosshair');
                
                [x, y] = ginput(1);
                x = round(x); y = round(y);
                
                x = max(3, min(x, imageSize(2)-3));
                y = max(3, min(y, imageSize(1)-3));
                
                x_start = x - 2; y_start = y - 2;
                w = 5; h = 5;
                
                if x_start < 1, x_start = 1; end
                if y_start < 1, y_start = 1; end
                if x_start + w > imageSize(2), x_start = imageSize(2) - w; end
                if y_start + h > imageSize(1), y_start = imageSize(1) - h; end
                
                roiPositions(roiCount, :) = [x_start, y_start, w, h];
                roiMask(y_start:y_start+h-1, x_start:x_start+w-1, lobe, r) = true;
                
                rectangle('Position', [x_start, y_start, w, h], ...
                         'EdgeColor', data.colors(lobe,:), 'LineWidth', 2);
                text(x_start+2, y_start-8, sprintf('%s-%d', data.lobeNames{lobe}, r), ...
                     'Color', data.colors(lobe,:), 'FontWeight', 'bold', 'BackgroundColor', 'white');
                
                plot(x, y, 'r+', 'MarkerSize', 15, 'LineWidth', 2);
                
                roiCount = roiCount + 1;
                
            catch
                % 如果用户取消或出错，使用默认位置
                x_start = 50 + (lobe-1)*80 + (r-1)*20;
                y_start = 50 + (lobe-1)*80 + (r-1)*20;
                w = 5; h = 5;
                
                if x_start < 1, x_start = 1; end
                if y_start < 1, y_start = 1; end
                if x_start + w > imageSize(2), x_start = imageSize(2) - w; end
                if y_start + h > imageSize(1), y_start = imageSize(1) - h; end
                
                roiPositions(roiCount, :) = [x_start, y_start, w, h];
                roiMask(y_start:y_start+h-1, x_start:x_start+w-1, lobe, r) = true;
                
                rectangle('Position', [x_start, y_start, w, h], ...
                         'EdgeColor', data.colors(lobe,:), 'LineWidth', 2, 'LineStyle', '--');
                text(x_start+2, y_start-8, sprintf('%s-%d(D)', data.lobeNames{lobe}, r), ...
                     'Color', data.colors(lobe,:), 'FontWeight', 'bold');
                
                roiCount = roiCount + 1;
            end
            
            % 恢复默认光标
            set(fig, 'Pointer', 'arrow');
            
            if exist('currentText', 'var') && isvalid(currentText)
                delete(currentText);
            end
            pause(0.2);
        end
    end
    
    hold off;
    
    data.roiMask = roiMask;
    data.roiPositions = roiPositions;
    guidata(fig, data);
    
    % 更新ROI状态显示
    preOpROIStatus = getappdata(fig, 'preOpROIStatus');
    if ishandle(preOpROIStatus)
        set(preOpROIStatus, 'String', '已标定', 'ForegroundColor', [0.8, 1, 0.8]);
    end
    
    updateStatus('ROI放置完成');
    if ishandle(mainAxes)
        title('ROI放置完成', 'Color', 'white');
    end
    
    addWorkLog('ROI放置完成');
    addWorkLog(sprintf('共放置 %d 个ROI (4个脑叶各3个)', 12));
end
