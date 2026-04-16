function utils_validateFrameInput(~,~)
    fig = gcf;
    data = guidata(fig);
    if isempty(data) || ~isfield(data, 'totalFrames') || isempty(data.totalFrames)
        return;
    end

    startFrameEdit = getappdata(fig, 'startFrameEdit');
    endFrameEdit = getappdata(fig, 'endFrameEdit');

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

    if isnan(startFrame) || startFrame < 1
        set(startFrameEdit, 'String', '1');
    elseif startFrame > data.totalFrames
        set(startFrameEdit, 'String', num2str(data.totalFrames));
    end

    if isnan(endFrame) || endFrame < 1
        set(endFrameEdit, 'String', '1');
    elseif endFrame > data.totalFrames
        set(endFrameEdit, 'String', num2str(data.totalFrames));
    end
end
