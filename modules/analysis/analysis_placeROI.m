function analysis_placeROI(varargin)
% 放置ROI - migrated to modules/analysis
fig = gcf;
data = guidata(fig);
if isempty(data.img2D)
    utils_showMessage('请先导入图像', 'error');
    log_addWorkLog('错误: 尝试放置ROI但未导入图像');
    return;
end
log_updateStatus('请为4个脑叶各选择3个ROI中心点（共12个点）');
log_addWorkLog('开始ROI放置流程');
imageSize = size(data.img2D);
roiMask = false(imageSize(1), imageSize(2), 4, 3);
roiPositions = zeros(12, 4);
mainAxes = getappdata(fig, 'mainAxes');
if ~ishandle(mainAxes), return; end
axes(mainAxes);
if ~isempty(data.processedSeries)
    currentImg = data.processedSeries(:,:,data.currentFrame);
elseif ~isempty(data.img4D)
    if ndims(data.img4D) == 4
        frameData = data.img4D(:,:,1,data.currentFrame);
    else
        frameData = data.img4D(:,:,data.currentFrame);
    end
    if isinteger(frameData), frameData = double(frameData); end
    currentImg = 255 - frameData;
else
    currentImg = data.img2D;
end
imagesc(currentImg); colormap(gray); axis image; caxis([min(currentImg(:)) max(currentImg(:))]); title('请依次为4个脑叶选择ROI中心点', 'Color', [0.2, 0.2, 0.2], 'FontName', 'Microsoft YaHei'); hold on;
text(10, 30, '操作说明:', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 12, 'BackgroundColor', 'black');
text(10, 60, '1. 依次为额叶、顶叶、颞叶、枕叶各选3个点', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
text(10, 90, '2. 尽量避开血管，选择脑实质区域', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
text(10, 120, '3. 点击后程序会自动创建5x5 ROI', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
text(10, 150, '4. 右键点击可撤销上一个ROI', 'Color', 'yellow', 'FontSize', 10, 'BackgroundColor', 'black');

roiCount = 1;
roiHandles = {}; % 存储ROI图形句柄用于撤销
currentText = [];

% 使用while循环以便支持撤销
while roiCount <= 12
    % 计算当前是哪个脑叶的哪个ROI
    lobe = ceil(roiCount / 3);
    r = mod(roiCount - 1, 3) + 1;
    
    % 删除旧的提示文本
    if ishandle(currentText)
        delete(currentText);
    end
    
    % 显示当前提示
    currentText = text(imageSize(2)/2, 30, sprintf('请为 %s 选择第 %d/3 个ROI中心点 (已完成%d/12，右键撤销)', data.lobeNames{lobe}, r, roiCount-1), 'Color', data.colors(lobe,:), 'FontWeight', 'bold', 'FontSize', 14, 'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
    
    validClick = false;
    while ~validClick
        try
            set(fig, 'Pointer', 'circle');
            
            % 使用waitforbuttonpress和SelectionType获取更准确的按键信息
            waitforbuttonpress;
            clickType = get(fig, 'SelectionType');
            pt = get(mainAxes, 'CurrentPoint');
            x = pt(1,1);
            y = pt(1,2);
            
            % 'alt' = 右键, 'normal' = 左键
            if strcmp(clickType, 'alt')
                % 右键撤销
                if roiCount > 1
                    % 删除上一个ROI的图形
                    if ~isempty(roiHandles) && length(roiHandles) >= roiCount-1
                        prevHandles = roiHandles{roiCount-1};
                        for k = 1:length(prevHandles)
                            if ishandle(prevHandles(k))
                                delete(prevHandles(k));
                            end
                        end
                        roiHandles(roiCount-1) = [];
                    end
                    
                    % 清除上一个ROI的mask和position（使用roiCount-1计算）
                    prev_lobe = ceil((roiCount - 1) / 3);
                    prev_r = mod((roiCount - 1) - 1, 3) + 1;
                    roiMask(:, :, prev_lobe, prev_r) = false;
                    roiPositions(roiCount - 1, :) = [0, 0, 0, 0];
                    
                    % 回退计数器
                    roiCount = roiCount - 1;
                    
                    % 跳出内层循环，重新计算并显示提示（支持连续撤销）
                    validClick = true;
                    break;  % 跳出到外层循环重新显示提示
                else
                    % 已经是第一个点，无法继续撤销
                    continue;  % 继续等待有效输入
                end
            end
            
            % 左键放置ROI
            if strcmp(clickType, 'normal')
                x = round(x); y = round(y);
                x = max(3, min(x, imageSize(2)-3)); y = max(3, min(y, imageSize(1)-3));
                
                % 根据图像分辨率自动调整ROI大小
                % 512x512 -> 5x5
                % 1024x1024 -> 10x10
                if imageSize(2) > 800
                    roiSize = 10;
                else
                    roiSize = 5;
                end
                
                w = roiSize; h = roiSize;
                x_start = x - floor(w/2); y_start = y - floor(h/2);
                if x_start < 1, x_start = 1; end
                if y_start < 1, y_start = 1; end
                if x_start + w > imageSize(2), x_start = imageSize(2) - w; end
                if y_start + h > imageSize(1), y_start = imageSize(1) - h; end
                roiPositions(roiCount, :) = [x_start, y_start, w, h];
                roiMask(y_start:y_start+h-1, x_start:x_start+w-1, lobe, r) = true;
                
                % 绘制并保存句柄
                h1 = rectangle('Position', [x_start, y_start, w, h], 'EdgeColor', data.colors(lobe,:), 'LineWidth', 2);
                h2 = text(x_start+2, y_start-8, sprintf('%s-%d', data.lobeNames{lobe}, r), 'Color', data.colors(lobe,:), 'FontWeight', 'bold', 'BackgroundColor', 'white');
                h3 = plot(x, y, 'r+', 'MarkerSize', 15, 'LineWidth', 2);
                roiHandles{roiCount} = [h1, h2, h3];
                
                roiCount = roiCount + 1;
                validClick = true;
            end
        catch                % 异常处理：使用默认位置
            if imageSize(2) > 800
                roiSize = 10;
                spacing_scale = 2; % 调整间距
            else
                roiSize = 5;
                spacing_scale = 1;
            end
            w = roiSize; h = roiSize;
            
            x_start = 50*spacing_scale + (lobe-1)*80*spacing_scale + (r-1)*20*spacing_scale;
            y_start = 50*spacing_scale + (lobe-1)*80*spacing_scale + (r-1)*20*spacing_scale;
            if x_start < 1, x_start = 1; end
            if y_start < 1, y_start = 1; end
            if x_start + w > imageSize(2), x_start = imageSize(2) - w; end
            if y_start + h > imageSize(1), y_start = imageSize(1) - h; end
            roiPositions(roiCount, :) = [x_start, y_start, w, h];
            roiMask(y_start:y_start+h-1, x_start:x_start+w-1, lobe, r) = true;
            
            h1 = rectangle('Position', [x_start, y_start, w, h], 'EdgeColor', data.colors(lobe,:), 'LineWidth', 2, 'LineStyle', '--');
            h2 = text(x_start+2, y_start-8, sprintf('%s-%d(D)', data.lobeNames{lobe}, r), 'Color', data.colors(lobe,:), 'FontWeight', 'bold');
            roiHandles{roiCount} = [h1, h2];
            
            roiCount = roiCount + 1;
            validClick = true;
        end
    end
    set(fig, 'Pointer', 'arrow');
    pause(0.1);
end

% 清除提示文本
if ishandle(currentText)
    delete(currentText);
end
hold off;
data.roiMask = roiMask; data.roiPositions = roiPositions; guidata(fig, data);
preOpROIStatus = getappdata(fig, 'preOpROIStatus'); if ishandle(preOpROIStatus), set(preOpROIStatus, 'String', '已标定', 'ForegroundColor', [0.8, 1, 0.8]); end
log_updateStatus('ROI放置完成'); if ishandle(mainAxes), title('ROI放置完成', 'Color', 'white'); end
log_addWorkLog('ROI放置完成'); log_addWorkLog(sprintf('共放置 %d 个ROI (4个脑叶各3个)', 12));
end
