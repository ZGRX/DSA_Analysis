function createDisplayArea(parent)
    % 创建中间图像显示区域（包含图像和播放控件）
    % 输入: parent - 父容器句柄
    
    % 主显示轴（为播放控件留出底部空间）
    mainAxes = axes('Parent', parent, ...
                   'Position', [0.05, 0.15, 0.9, 0.82], ...
                   'Color', [0.05, 0.1, 0.15], ...
                   'XColor', [0.8, 0.9, 1], ...
                   'YColor', [0.8, 0.9, 1]);
    axis(mainAxes, 'image');
    colormap(mainAxes, 'gray');
    title(mainAxes, 'DICOM影像显示区域', 'Color', [1, 1, 1], 'FontSize', 14);
    
    setappdata(gcf, 'mainAxes', mainAxes);
    
    % 创建播放控件（位于底部）
    createPlaybackControls(parent);
end
