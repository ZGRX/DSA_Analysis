"""
visualizations.py — Plotly 动态交互图表组件
对应原 MATLAB: visual_plotDTWWaterfall.m, visual_plotRadar.m 及标准TDC出图
"""
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import numpy as np

def plot_tdc_curves(t: np.ndarray, curve_prox: np.ndarray, curve_dist: np.ndarray,
                    params_prox, params_dist):
    """双端TDC曲线与关键指标点交互图"""
    fig = go.Figure()

    # 近端曲线 (红)
    fig.add_trace(go.Scatter(x=t, y=curve_prox, mode='lines', name='近端 (Proximal)',
                             line=dict(color='#ff4b4b', width=3)))
    # 远端曲线 (蓝)
    fig.add_trace(go.Scatter(x=t, y=curve_dist, mode='lines', name='远端 (Distal)',
                             line=dict(color='#0096ff', width=3)))

    # 标记达峰点 (TTP, Peak)
    fig.add_trace(go.Scatter(x=[params_prox.TTP], y=[params_prox.Peak], mode='markers+text',
                             text=['Prox TTP'], textposition='top center',
                             marker=dict(color='#ff4b4b', size=10, symbol='star'), name='Prox Peak'))
    fig.add_trace(go.Scatter(x=[params_dist.TTP], y=[params_dist.Peak], mode='markers+text',
                             text=['Dist TTP'], textposition='top center',
                             marker=dict(color='#0096ff', size=10, symbol='star'), name='Dist Peak'))

    # TTS时移带
    if params_dist.TTP > params_prox.TTP:
        fig.add_vrect(x0=params_prox.TTP, x1=params_dist.TTP, fillcolor='yellow', opacity=0.2,
                      layer='below', line_width=0, annotation_text=f"TTS = {params_dist.TTP - params_prox.TTP:.2f}s")

    fig.update_layout(title="双端时间密度曲线 (Time-Density Curve)",
                      xaxis_title="时间 (s)", yaxis_title="对比剂相对浓度",
                      template='plotly_dark', hovermode='x unified',
                      margin=dict(l=20, r=20, t=40, b=20))
    return fig

def plot_radar_comparison(params_prox, params_dist):
    """参数多维雷达图"""
    categories = ['TTP', 'MTT', 'TU', 'FWHM', 'AUC', 'Peak']
    
    # 获取数值
    # 为了在同一雷达图上显示，需要归一化，但这里直接显示原始数值对比（只对比这几项由于不同量级会畸形，所以在展示上建议做最大值归一）
    vals_prox = [getattr(params_prox, k) for k in categories]
    vals_dist = [getattr(params_dist, k) for k in categories]
    
    max_vals = [max(p, d, 0.01) for p, d in zip(vals_prox, vals_dist)]
    # 归一化
    norm_prox = [p/m * 100 for p, m in zip(vals_prox, max_vals)]
    norm_dist = [d/m * 100 for d, m in zip(vals_dist, max_vals)]

    fig = go.Figure()
    fig.add_trace(go.Scatterpolar(
        r=norm_prox, theta=categories, fill='toself', name='近端 (Prox)',
        line_color='#ff4b4b', fillcolor='rgba(255, 75, 75, 0.3)'
    ))
    fig.add_trace(go.Scatterpolar(
        r=norm_dist, theta=categories, fill='toself', name='远端 (Dist)',
        line_color='#0096ff', fillcolor='rgba(0, 150, 255, 0.3)'
    ))

    fig.update_layout(
        polar=dict(radialaxis=dict(visible=False, range=[0, 110])),
        showlegend=True, template='plotly_dark',
        title="双端灌注参数多维对比雷达图",
        margin=dict(l=40, r=40, t=60, b=40)
    )
    return fig
