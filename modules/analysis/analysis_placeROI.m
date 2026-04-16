function analysis_placeROI(varargin)
% 放置狭窄双端 ROI (Proximal/Distal)
fig = gcf;
data = guidata(fig);
if isempty(data.img2D)
    utils_showMessage('请先导入图像', 'error');
    log_addWorkLog('错误: 尝试放置ROI但未导入图像');
    return;
end
log_updateStatus('请在狭窄段的【近端】和【远端】各选择一个ROI');
log_addWorkLog('开始双端ROI放置流程');
imageSize = size(data.img2D);
roiMask = false(imageSize(1), imageSize(2), 2);
roiPositions = zeros(2, 4);
roiNames = {'狭窄近端 (Proximal)', '狭窄远端 (Distal)'};
roiColors = [1, 0.4, 0.4; 0.4, 0.8, 1]; % 红色(近)，蓝色(远)

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
currentImg = squeeze(currentImg);
hImg = findobj(mainAxes, 'Type', 'image');
if isempty(hImg)
    imagesc(currentImg, 'Parent', mainAxes);
else
    set(hImg, 'CData', currentImg);
end
colormap(mainAxes, gray); axis(mainAxes, 'image'); 

cMin = min(currentImg(:), [], 'omitnan');
cMax = max(currentImg(:), [], 'omitnan');
if isempty(cMin) || isnan(cMin) || cMin >= cMax
    caxis(mainAxes, 'auto');
else
    caxis(mainAxes, [cMin cMax]);
end 
title('请放置狭窄双端 ROI', 'Color', [0.2, 0.2, 0.2], 'FontName', 'Microsoft YaHei'); hold on;
text(10, 30, '操作说明:', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 12, 'BackgroundColor', 'black');
text(10, 60, '1. 分别点击狭窄的【近端(血流来向)】和【远端(去向)】', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
text(10, 90, '2. 尽量点在主血管附近，系统会自动【靶向吸附】血流中心线', 'Color', 'white', 'FontSize', 10, 'BackgroundColor', 'black');
text(10, 120, '3. 右键点击可撤销', 'Color', 'yellow', 'FontSize', 10, 'BackgroundColor', 'black');

% 【核心升级】：计算 Frangi 血管性地图用于智能吸附
% 【修复】先屏蔽边缘伪影区（准直器高亮条带），防止吸附到非血管区域
try
    log_updateStatus('正在计算 Frangi 血管增强掩膜 (用于智能吸附)...');
    vesselness = utils_frangiFilter2D(currentImg);
    % 边缘排除：左右各 6%，上下各 3%（准直器/运动伪影好发区域）
    marginX = round(imageSize(2) * 0.06);
    marginY = round(imageSize(1) * 0.03);
    vesselness(:, 1:marginX) = 0;
    vesselness(:, end-marginX+1:end) = 0;
    vesselness(1:marginY, :) = 0;
    vesselness(end-marginY+1:end, :) = 0;
catch
    vesselness = double(currentImg);
end

roiCount = 1;
roiHandles = {};
currentText = [];

while roiCount <= 3
    if ishandle(currentText), delete(currentText); end
    
    if roiCount == 3
        currentText = text(imageSize(2)/2, 30, '✅ 双端靶点已就绪！请【单击左键】确认完成，或【右键】撤销上一点', ...
            'Color', [0.3, 1, 0.3], 'FontWeight', 'bold', 'FontSize', 14, 'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
        validClick = false;
        while ~validClick
            set(fig, 'Pointer', 'arrow');
            try
                waitforbuttonpress;
                clickType = get(fig, 'SelectionType');
                if strcmp(clickType, 'alt')
                    if length(roiHandles) >= 2
                        prevHandles = roiHandles{2};
                        for k=1:length(prevHandles), if ishandle(prevHandles(k)), delete(prevHandles(k)); end; end
                        roiHandles(2) = [];
                    end
                    roiMask(:, :, 2) = false;
                    roiPositions(2, :) = [0, 0, 0, 0];
                    roiCount = 2;
                    validClick = true;
                elseif strcmp(clickType, 'normal') || strcmp(clickType, 'open') || strcmp(clickType, 'extend')
                    roiCount = 4; % 满足结束条件退出
                    validClick = true;
                end
            catch
                validClick = false;
            end
        end
        continue;
    end
    
    currentText = text(imageSize(2)/2, 30, sprintf('请选择【%s】中心点 (右键撤销)', roiNames{roiCount}), ...
        'Color', roiColors(roiCount,:), 'FontWeight', 'bold', 'FontSize', 14, 'HorizontalAlignment', 'center', 'BackgroundColor', 'black');
    
    validClick = false;
    while ~validClick
        try
            set(fig, 'Pointer', 'circle');
            waitforbuttonpress;
            clickType = get(fig, 'SelectionType');
            pt = get(mainAxes, 'CurrentPoint');
            x = pt(1,1); y = pt(1,2);
            
            if strcmp(clickType, 'alt')
                if roiCount > 1
                    if length(roiHandles) >= roiCount-1
                        prevHandles = roiHandles{roiCount-1};
                        for k=1:length(prevHandles), if ishandle(prevHandles(k)), delete(prevHandles(k)); end; end
                        roiHandles(roiCount-1) = [];
                    end
                    roiMask(:, :, roiCount - 1) = false;
                    roiPositions(roiCount - 1, :) = [0, 0, 0, 0];
                    roiCount = roiCount - 1;
                    validClick = true; break;
                else
                    continue;
                end
            end
            
            if strcmp(clickType, 'normal')
                x_orig = round(x); y_orig = round(y);
                
                % 防越界处理（缩减搜索半径至5px，避免大范围全局吸附）
                searchRadius = 5;
                x_orig = max(searchRadius+1, min(x_orig, imageSize(2)-searchRadius));
                y_orig = max(searchRadius+1, min(y_orig, imageSize(1)-searchRadius));
                
                % 在局部窗口内寻找 Frangi 管状响应最强的像素（中心线吸附）
                localMask = vesselness(y_orig-searchRadius:y_orig+searchRadius, x_orig-searchRadius:x_orig+searchRadius);
                [~, maxIdx] = max(localMask(:));
                [dy, dx] = ind2sub(size(localMask), maxIdx);
                x_snap = x_orig - searchRadius + dx - 1;
                y_snap = y_orig - searchRadius + dy - 1;
                
                % 【新增】重叠检测：若两个 ROI 落在同一位置，警告并强制用原始点击坐标
                if roiCount == 2 && roiPositions(1,1) > 0
                    dist = sqrt((x_snap - roiPositions(1,1))^2 + (y_snap - roiPositions(1,2))^2);
                    if dist < 15  % 两ROI中心距离小于15px认为重叠
                        warning('DSA:ROIOverlap', '吸附点与第一个ROI距离过近 (%.1fpx)，已回退到原始点击点', dist);
                        log_addWorkLog(sprintf('警告: ROI吸附重叠检测，强制使用原始坐标 (%d,%d)', x_orig, y_orig));
                        x_snap = x_orig; y_snap = y_orig;  % 回退到原始点
                    end
                end
                
                % 固定 ROI 大小 7×7
                w = 7; h = 7;
                x_start = x_snap - floor(w/2); y_start = y_snap - floor(h/2);
                if x_start < 1, x_start = 1; end
                if y_start < 1, y_start = 1; end
                if x_start+w-1 > imageSize(2), x_start = imageSize(2)-w+1; end
                if y_start+h-1 > imageSize(1), y_start = imageSize(1)-h+1; end
                
                roiPositions(roiCount, :) = [x_start, y_start, w, h];
                roiMask(y_start:y_start+h-1, x_start:x_start+w-1, roiCount) = true;
                
                h1 = rectangle('Position', [x_start, y_start, w, h], 'EdgeColor', roiColors(roiCount,:), 'LineWidth', 2);
                h2 = text(x_start+w+2, y_start-h, roiNames{roiCount}, 'Color', roiColors(roiCount,:), 'FontWeight', 'bold', 'BackgroundColor', 'k');
                h3 = plot(x_snap, y_snap, '+', 'Color', roiColors(roiCount,:), 'MarkerSize', 10, 'LineWidth', 2);
                h4 = plot([x_orig, x_snap], [y_orig, y_snap], '--', 'Color', [1 1 0], 'LineWidth', 1.5);
                roiHandles{roiCount} = [h1, h2, h3, h4];
                log_addWorkLog(sprintf('ROI %d 放置完成: 原始点(%d,%d) → 吸附点(%d,%d)', roiCount, x_orig, y_orig, x_snap, y_snap));
                
                roiCount = roiCount + 1;
                validClick = true;
            end
        catch
            validClick = false;
        end
    end
    set(fig, 'Pointer', 'arrow'); pause(0.1);
end
if ishandle(currentText), delete(currentText); end
hold off;
data.roiMask = roiMask; data.roiPositions = roiPositions; 
data.roiNames = roiNames; data.roiColors = roiColors;
guidata(fig, data);

preOpROIStatus = getappdata(fig, 'preOpROIStatus'); 
if ishandle(preOpROIStatus), set(preOpROIStatus, 'String', '已标定(双端)', 'ForegroundColor', [0.8, 1, 0.8]); end
log_updateStatus('双端ROI放置完成'); 
if ishandle(mainAxes), title('狭窄双端ROI放置完成', 'Color', 'white'); end
log_addWorkLog('双端ROI放置完成'); 
end
