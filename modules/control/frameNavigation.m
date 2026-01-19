function frameNavigation(action, ~, ~)
% frameNavigation 统一帧导航函数（first/prev/next/last/number）
% 用法示例:
%   frameNavigation('prev')      % 上一帧
%   frameNavigation('next')      % 下一帧
%   frameNavigation('first')     % 第一帧
%   frameNavigation('last')      % 最后一帧
%   frameNavigation(10)          % 跳到第 10 帧

    if nargin < 1 || isempty(action)
        return;
    end

    fig = gcf;
    data = guidata(fig);
    if isempty(data) || (~isfield(data, 'img4D') && ~isfield(data, 'processedSeries'))
        return;
    end

    % 获取可选的 UI 句柄
    frameSlider = getappdata(fig, 'frameSlider');
    currentFrameText = getappdata(fig, 'currentFrameText');

    % 处理 action
    msg = '';
    if ischar(action) || isstring(action)
        act = lower(char(action));
        switch act
            case 'first'
                data.currentFrame = 1;
                msg = '跳转到第一帧';
            case 'prev'
                data.currentFrame = max(1, data.currentFrame - 1);
                msg = sprintf('跳转到前一帧: %d', data.currentFrame);
            case 'next'
                if isfield(data, 'totalFrames')
                    data.currentFrame = min(data.totalFrames, data.currentFrame + 1);
                else
                    data.currentFrame = data.currentFrame + 1;
                end
                msg = sprintf('跳转到后一帧: %d', data.currentFrame);
            case 'last'
                if isfield(data, 'totalFrames')
                    data.currentFrame = data.totalFrames;
                end
                if isfield(data, 'totalFrames')
                    msg = sprintf('跳转到最后一帧: %d', data.totalFrames);
                else
                    msg = '跳转到最后一帧';
                end
            otherwise
                return;
        end
    elseif isnumeric(action)
        target = round(action);
        if target < 1
            target = 1;
        end
        if isfield(data, 'totalFrames')
            target = min(target, data.totalFrames);
        end
        data.currentFrame = target;
        msg = sprintf('跳转到指定帧: %d', data.currentFrame);
    else
        return;
    end

    % 写回数据并更新 UI
    guidata(fig, data);
    if ishandle(frameSlider)
        try set(frameSlider, 'Value', data.currentFrame); end
    end
    if ishandle(currentFrameText)
        try set(currentFrameText, 'String', num2str(data.currentFrame)); end
    end

    % 刷新显示并更新状态
    try updateFrameDisplay(); end
    if ~isempty(msg)
        try log_updateStatus(msg); end
    end
end
