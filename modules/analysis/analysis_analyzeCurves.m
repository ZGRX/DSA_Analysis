function analysis_analyzeCurves(varargin)
    % analyzeCurves 已迁移到 modules/analysis
    fig = gcf;
    data = guidata(fig);
    if isempty(data.timeSeriesData)
        errordlg('请先提取时间序列数据', '错误');
        log_addWorkLog('错误: 尝试分析曲线但无时间序列数据');
        return;
    end
    log_updateStatus('正在分析TDC曲线...');
    log_addWorkLog('开始TDC曲线分析');
    try
        frameRateEdit = getappdata(fig, 'frameRateEdit');
        if ishandle(frameRateEdit)
            frameRate = str2double(get(frameRateEdit, 'String'));
        else
            frameRate = 4;
        end
        if isnan(frameRate) || frameRate <= 0
            frameRate = 4;
            if ishandle(frameRateEdit)
                set(frameRateEdit, 'String', '4');
            end
        end
        lobeAvgData = zeros(4, size(data.timeSeriesData, 2));
        for lobe = 1:4
            lobe_indices = (lobe-1)*3+1:lobe*3;
            lobeAvgData(lobe, :) = mean(data.timeSeriesData(lobe_indices, :), 1);
        end
        t = (0:size(data.timeSeriesData, 2)-1) / frameRate;
        t_highres = linspace(t(1), t(end), length(t) * 10);
        smoothedLobeData = zeros(4, length(t_highres));
        hWait = waitbar(0, '正在进行Hermite多项式插值平滑...');
        for lobe = 1:4
            smoothedLobeData(lobe, :) = pchip(t, lobeAvgData(lobe, :), t_highres);
            waitbar(lobe/4, hWait, sprintf('正在处理%s...', data.lobeNames{lobe}));
        end
        close(hWait);
        perfusionParams = struct();
        for lobe = 1:4
            curve = smoothedLobeData(lobe, :);
            time = t_highres;
            [maxVal, maxIdx] = max(curve);
            TMAX = time(maxIdx);
            baseline = mean(curve(1:min(5, length(curve))));
            threshold = baseline + 0.1 * (maxVal - baseline);
            tuIdx = find(curve > threshold, 1, 'first');
            if isempty(tuIdx), tuIdx = 1; end
            TU = time(tuIdx);
            TD = TMAX - TU;
            cumulative_auc = cumtrapz(time, curve - baseline);
            half_auc = cumulative_auc(end) / 2;
            mttIdx = find(cumulative_auc >= half_auc, 1, 'first');
            if isempty(mttIdx), MTT = TMAX; else MTT = time(mttIdx); end
            halfMaxVal = baseline + (maxVal - baseline) / 2;
            halfMaxIdx = find(curve(1:maxIdx) >= halfMaxVal, 1, 'first');
            if isempty(halfMaxIdx), halfTMAX = TU; else halfTMAX = time(halfMaxIdx); end
            AUC = trapz(time, curve - baseline);
            AUCbefore = trapz(time(1:maxIdx), curve(1:maxIdx) - baseline);
            AUCratio = AUCbefore / AUC;
            dCurve = diff(curve) ./ diff(time);
            timeRangeForSlope = (time >= TU) & (time <= TMAX);
            timeRangeForSlope(end) = [];
            if any(timeRangeForSlope)
                MS = max(dCurve(timeRangeForSlope));
            else
                MS = max(dCurve);
            end
            curveValueAtTU = curve(tuIdx);
            AFS = (maxVal - curveValueAtTU) / TD;
            CBF = AUC / MTT;
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
        data.perfusionParams = perfusionParams;
        data.smoothedLobeData = smoothedLobeData;
        data.t_highres = t_highres;
        data.frameRate = frameRate;
        guidata(fig, data);
        updateParamTable();
        showPerfusionParams(perfusionParams, data.lobeNames);
        log_updateStatus('TDC曲线分析完成');
        log_addWorkLog('TDC曲线分析完成');
        log_addWorkLog('使用Hermite多项式插值进行曲线平滑');
        log_addWorkLog('计算了TMAX, MTT, AUC等11个灌注参数');
        msgbox('TDC曲线分析完成！', '完成');
    catch ME
        errordlg(sprintf('曲线分析失败: %s', ME.message), '错误');
        log_updateStatus('曲线分析失败');
        log_addWorkLog(sprintf('错误: 曲线分析失败 - %s', ME.message));
    end
end

function showPerfusionParams(params, lobeNames)
    % 同原实现，显示灌注参数表格
    paramFig = figure('Name', '脑叶灌注参数表', 'NumberTitle', 'off', 'Position', [200, 200, 1000, 400], 'MenuBar', 'none', 'Color', [0.95, 0.95, 0.95]);
    paramNames = {'TMAX (s)', 'MTT (s)', 'TU (s)', 'TD (s)', '1/2TMAX (s)', 'AUC', 'AUCbefore', 'AUCbefore/AUC', 'MS (SI/s)', 'AFS (SI/s)', 'CBF (SI)'};
    tableData = cell(12, 6);
    tableData{1, 1} = '参数';
    tableData{1, 2} = '单位';
    for i = 1:4, tableData{1, i+2} = lobeNames{i}; end
    for i = 1:11
        tableData{i+1, 1} = paramNames{i};
        switch i
            case {1,2,3,4,5}, tableData{i+1, 2} = 's';
            case {6,7}, tableData{i+1, 2} = 'SI*s';
            case 8, tableData{i+1, 2} = '';
            case {9,10}, tableData{i+1, 2} = 'SI/s';
            case 11, tableData{i+1, 2} = 'SI';
        end
        for j = 1:4
            switch i
                case 1, tableData{i+1, j+2} = sprintf('%.3f', params(j).TMAX);
                case 2, tableData{i+1, j+2} = sprintf('%.3f', params(j).MTT);
                case 3, tableData{i+1, j+2} = sprintf('%.3f', params(j).TU);
                case 4, tableData{i+1, j+2} = sprintf('%.3f', params(j).TD);
                case 5, tableData{i+1, j+2} = sprintf('%.3f', params(j).halfTMAX);
                case 6, tableData{i+1, j+2} = sprintf('%.1f', params(j).AUC);
                case 7, tableData{i+1, j+2} = sprintf('%.1f', params(j).AUCbefore);
                case 8, tableData{i+1, j+2} = sprintf('%.3f', params(j).AUCratio);
                case 9, tableData{i+1, j+2} = sprintf('%.3f', params(j).MS);
                case 10, tableData{i+1, j+2} = sprintf('%.3f', params(j).AFS);
                case 11, tableData{i+1, j+2} = sprintf('%.3f', params(j).CBF);
            end
        end
    end
    uitable('Parent', paramFig, 'Data', tableData, 'Position', [20, 20, 960, 350], 'ColumnWidth', {100, 50, 80, 80, 80, 80}, 'RowName', [], 'ColumnName', {'参数', '单位', '额叶', '顶叶', '颞叶', '枕叶'});
end
