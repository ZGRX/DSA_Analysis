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
            errordlg('请输入有效的帧范围');
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
        errordlg(sprintf('应用帧范围失败: %s', ME.message));
    end
end
