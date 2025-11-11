function analyzeCurves(~, ~)
    % analyzeCurves - 分析TDC曲线并计算灌注参数
    %
    % 功能：
    %   1. 对原始TDC数据进行Hermite多项式插值平滑
    %   2. 计算11个灌注参数：TMAX, MTT, TU, TD, 1/2TMAX, AUC, AUCbefore, AUCbefore/AUC, MS, AFS, CBF
    %   3. 显示参数表格
    %
    % 输入：
    %   无（从guidata获取数据）
    %
    % 输出：
    %   无（结果保存到guidata）
    
    fig = gcf;
    data = guidata(fig);
    
    % 验证数据
    if isempty(data.timeSeriesData)
        errordlg('请先提取时间序列数据', '错误');
        addWorkLog('错误: 尝试分析曲线但无时间序列数据');
        return;
    end
    
    updateStatus('正在分析TDC曲线...');
    addWorkLog('开始TDC曲线分析');
    
    try
        % 获取帧率
        frameRateEdit = getappdata(fig, 'frameRateEdit');
        
        if ishandle(frameRateEdit)
            frameRate = str2double(get(frameRateEdit, 'String'));
        else
            frameRate = 4; % 默认帧率
        end
        
        % 验证帧率
        if isnan(frameRate) || frameRate <= 0
            frameRate = 4;
            if ishandle(frameRateEdit)
                set(frameRateEdit, 'String', '4');
            end
        end
        
        % 计算每个脑叶的平均TDC（3个ROI取平均）
        lobeAvgData = zeros(4, size(data.timeSeriesData, 2));
        for lobe = 1:4
            lobe_indices = (lobe-1)*3+1:lobe*3;
            lobeAvgData(lobe, :) = mean(data.timeSeriesData(lobe_indices, :), 1);
        end
        
        % 生成原始时间轴和高分辨率时间轴
        t = (0:size(data.timeSeriesData, 2)-1) / frameRate;
        t_highres = linspace(t(1), t(end), length(t) * 10);
        
        % Hermite多项式插值平滑
        smoothedLobeData = zeros(4, length(t_highres));
        
        hWait = waitbar(0, '正在进行Hermite多项式插值平滑...');
        for lobe = 1:4
            smoothedLobeData(lobe, :) = pchip(t, lobeAvgData(lobe, :), t_highres);
            waitbar(lobe/4, hWait, sprintf('正在处理%s...', data.lobeNames{lobe}));
        end
        close(hWait);
        
        % 初始化灌注参数结构
        perfusionParams = struct();
        
        % 计算每个脑叶的灌注参数
        for lobe = 1:4
            curve = smoothedLobeData(lobe, :);
            time = t_highres;
            
            % 1. TMAX - 峰值时间
            [maxVal, maxIdx] = max(curve);
            TMAX = time(maxIdx);
            
            % 2. TU - 上升开始时间（曲线到达10%峰值的时间）
            baseline = mean(curve(1:min(5, length(curve))));
            threshold = baseline + 0.1 * (maxVal - baseline);
            tuIdx = find(curve > threshold, 1, 'first');
            if isempty(tuIdx)
                tuIdx = 1;
            end
            TU = time(tuIdx);
            
            % 3. TD - 到峰时间
            TD = TMAX - TU;
            
            % 4. MTT - 平均通过时间（曲线下面积的中点时间）
            cumulative_auc = cumtrapz(time, curve - baseline);
            half_auc = cumulative_auc(end) / 2;
            mttIdx = find(cumulative_auc >= half_auc, 1, 'first');
            if isempty(mttIdx)
                MTT = TMAX;
            else
                MTT = time(mttIdx);
            end
            
            % 5. 1/2TMAX - 达到半峰值的时间
            halfMaxVal = baseline + (maxVal - baseline) / 2;
            halfMaxIdx = find(curve(1:maxIdx) >= halfMaxVal, 1, 'first');
            if isempty(halfMaxIdx)
                halfTMAX = TU;
            else
                halfTMAX = time(halfMaxIdx);
            end
            
            % 6. AUC - 曲线下总面积
            AUC = trapz(time, curve - baseline);
            
            % 7. AUCbefore - 峰值前面积
            AUCbefore = trapz(time(1:maxIdx), curve(1:maxIdx) - baseline);
            
            % 8. AUCratio - 峰值前面积占总面积比例
            AUCratio = AUCbefore / AUC;
            
            % 9. MS - 最大斜率
            dCurve = diff(curve) ./ diff(time);
            timeRangeForSlope = (time >= TU) & (time <= TMAX);
            timeRangeForSlope(end) = []; % 匹配diff后的长度
            if any(timeRangeForSlope)
                MS = max(dCurve(timeRangeForSlope));
            else
                MS = max(dCurve);
            end
            
            % 10. AFS - 平均流速
            curveValueAtTU = curve(tuIdx);
            AFS = (maxVal - curveValueAtTU) / TD;
            
            % 11. CBF - 脑血流量
            CBF = AUC / MTT;
            
            % 保存参数
            perfusionParams(lobe).TMAX = TMAX;
            perfusionParams(lobe).MTT = MTT;
            perfusionParams(lobe).TU = TU;
            perfusionParams(lobe).TD = TD;
            perfusionParams(lobe).halfTMAX = halfTMAX;
            perfusionParams(lobe).AUC = AUC;
            perfusionParams(lobe).AUCbefore = AUCbefore;
            perfusionParams(lobe).AUCratio = AUCratio;
            perfusionParams(lobe).MS = MS;
            perfusionParams(lobe).AFS = AFS;
            perfusionParams(lobe).CBF = CBF;
        end
        
        % 保存结果到guidata
        data.perfusionParams = perfusionParams;
        data.smoothedLobeData = smoothedLobeData;
        data.t_highres = t_highres;
        data.frameRate = frameRate;
        guidata(fig, data);
        
        % 更新参数表格
        updateParamTable();
        
        % 显示参数表格
        showPerfusionParams(perfusionParams, data.lobeNames);
        
        % 更新状态
        updateStatus('TDC曲线分析完成');
        addWorkLog('TDC曲线分析完成');
        addWorkLog('使用Hermite多项式插值进行曲线平滑');
        addWorkLog('计算了TMAX, MTT, AUC等11个灌注参数');
        
        msgbox('TDC曲线分析完成！', '完成');
        
    catch ME
        errordlg(sprintf('曲线分析失败: %s', ME.message), '错误');
        updateStatus('曲线分析失败');
        addWorkLog(sprintf('错误: 曲线分析失败 - %s', ME.message));
    end
end

function showPerfusionParams(params, lobeNames)
    % showPerfusionParams - 显示灌注参数表格
    %
    % 输入：
    %   params - 灌注参数结构数组（1×4）
    %   lobeNames - 脑叶名称元胞数组
    
    paramFig = figure('Name', '脑叶灌注参数表', ...
                     'NumberTitle', 'off', ...
                     'Position', [200, 200, 1000, 400],...
                     'MenuBar', 'none', ...
                     'Color', [0.95, 0.95, 0.95]);
    
    % 参数名称和单位
    paramNames = {
        'TMAX (s)', 'MTT (s)', 'TU (s)', 'TD (s)', '1/2TMAX (s)', ...
        'AUC', 'AUCbefore', 'AUCbefore/AUC', 'MS (SI/s)', 'AFS (SI/s)', 'CBF (SI)'
    };
    
    % 创建表格数据
    tableData = cell(12, 6);
    tableData{1, 1} = '参数';
    tableData{1, 2} = '单位';
    for i = 1:4
        tableData{1, i+2} = lobeNames{i};
    end
    
    % 填充参数数据
    for i = 1:11
        tableData{i+1, 1} = paramNames{i};
        
        % 单位列
        switch i
            case {1,2,3,4,5}
                tableData{i+1, 2} = 's';
            case {6,7}
                tableData{i+1, 2} = 'SI*s';
            case 8
                tableData{i+1, 2} = '';
            case {9,10}
                tableData{i+1, 2} = 'SI/s';
            case 11
                tableData{i+1, 2} = 'SI';
        end
        
        % 各脑叶数据
        for j = 1:4
            switch i
                case 1
                    tableData{i+1, j+2} = sprintf('%.3f', params(j).TMAX);
                case 2
                    tableData{i+1, j+2} = sprintf('%.3f', params(j).MTT);
                case 3
                    tableData{i+1, j+2} = sprintf('%.3f', params(j).TU);
                case 4
                    tableData{i+1, j+2} = sprintf('%.3f', params(j).TD);
                case 5
                    tableData{i+1, j+2} = sprintf('%.3f', params(j).halfTMAX);
                case 6
                    tableData{i+1, j+2} = sprintf('%.1f', params(j).AUC);
                case 7
                    tableData{i+1, j+2} = sprintf('%.1f', params(j).AUCbefore);
                case 8
                    tableData{i+1, j+2} = sprintf('%.3f', params(j).AUCratio);
                case 9
                    tableData{i+1, j+2} = sprintf('%.3f', params(j).MS);
                case 10
                    tableData{i+1, j+2} = sprintf('%.3f', params(j).AFS);
                case 11
                    tableData{i+1, j+2} = sprintf('%.3f', params(j).CBF);
            end
        end
    end
    
    % 创建表格
    uitable('Parent', paramFig, ...
            'Data', tableData, ...
            'Position', [20, 20, 960, 350], ...
            'ColumnWidth', {100, 50, 80, 80, 80, 80}, ...
            'RowName', [], ...
            'ColumnName', {'参数', '单位', '额叶', '顶叶', '颞叶', '枕叶'});
end
