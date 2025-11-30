%%应用用户输入的起始/结束帧范围，更新数据结构并刷新显示与状态
function applyFrameRange(~,~)
    fig = gcf;
    data = guidata(fig);
    if isempty(data) || ~isfield(data,'totalFrames') || isempty(data.totalFrames)
        return;
    end
    try
        startFrameEdit = getappdata(fig, 'startFrameEdit');
        endFrameEdit = getappdata(fig, 'endFrameEdit');
        frameSlider = getappdata(fig, 'frameSlider');
        currentFrameText = getappdata(fig, 'currentFrameText');
        
        if ishandle(startFrameEdit)
            startFrame = str2double(get(startFrameEdit, 'String'));
        else
            return;
        end
        if ishandle(endFrameEdit)
            endFrame = str2double(get(endFrameEdit, 'String'));
        else
            return;
        end
        
        if isnan(startFrame) || isnan(endFrame) || startFrame < 1 || endFrame > data.totalFrames || startFrame > endFrame
            utils_showMessage('请输入有效的帧范围', 'error');
            return;
        end
        
        data.startFrame = startFrame;
        data.endFrame = endFrame;
        data.currentFrame = startFrame;
        guidata(fig, data);
        
        if ishandle(frameSlider), set(frameSlider, 'Value', startFrame); end
        if ishandle(currentFrameText), set(currentFrameText, 'String', num2str(startFrame)); end
        
        updateFrameDisplay();
        log_updateStatus(sprintf('已应用帧范围: %d-%d', startFrame, endFrame));
    catch ME
        utils_showMessage('应用帧范围失败', 'error', ME.message);
    end
end
