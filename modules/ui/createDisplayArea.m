function createDisplayArea(parent)
    % 创建中间图像显示区域（现代医疗风格）
    % 输入: parent - 父容器句柄
    
    % 主显示轴（为播放控件留出底部空间，浅色背景）
    mainAxes = axes('Parent', parent, ...
                   'Position', [0.05, 0.15, 0.9, 0.82], ...
                   'Color', [0.92, 0.94, 0.96], ...
                   'XColor', [0.5, 0.6, 0.7], ...
                   'YColor', [0.5, 0.6, 0.7]);
    axis(mainAxes, 'image');
    colormap(mainAxes, 'gray');
    title(mainAxes, 'DICOM影像显示区域', 'Color', [0.3, 0.5, 0.7], 'FontSize', 15, 'FontWeight', 'bold');
    
    setappdata(gcf, 'mainAxes', mainAxes);
    
    % 创建播放控件（位于底部）
    createPlaybackControls(parent);
end
