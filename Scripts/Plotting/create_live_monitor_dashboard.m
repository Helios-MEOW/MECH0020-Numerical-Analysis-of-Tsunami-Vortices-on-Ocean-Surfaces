%% LIVE MONITORING DASHBOARD - UIFIGURE-BASED
% Creates a futuristic dark-mode dashboard for real-time simulation monitoring

function fig = create_live_monitor_dashboard()
    % Futuristic dark-mode dashboard (uifigure-based)
    global monitor_data; %#ok<GVMIS>

    warning('off', 'MATLAB:ui:Figure:a11yTextScalingNotSupported');

    bg = [0 0 0];
    panel_bg = [0.08 0.08 0.08];
    panel_edge = [0.25 0.25 0.25];
    accent = [0.20 0.85 1.00];
    text_main = [0.88 0.92 1.00];
    text_dim = [0.65 0.72 0.85];

    fig = uifigure('Name', 'Live Execution Monitor', ...
        'Color', bg, ...
        'Position', [80, 60, 1220, 720]);

    position_monitor_next_to_main(fig);

    main_grid = uigridlayout(fig, [2 3]);
    main_grid.RowHeight = {'1x', '1x'};
    main_grid.ColumnWidth = {'1x', '1x', '1x'};
    main_grid.Padding = [12 12 12 12];
    main_grid.RowSpacing = 10;
    main_grid.ColumnSpacing = 10;
    main_grid.BackgroundColor = bg;

    % Helper to create card panel
    function p = card(title_text)
        p = uipanel(main_grid, 'BackgroundColor', panel_bg, 'BorderColor', panel_edge, ...
            'BorderWidth', 1, 'FontWeight', 'bold');
        gl = uigridlayout(p, [2 1]);
        gl.RowHeight = {24, '1x'};
        gl.Padding = [10 10 10 8];
        gl.RowSpacing = 6;
        t = uilabel(gl, 'Text', title_text, 'FontSize', 12, 'FontWeight', 'bold', ...
            'FontColor', accent, 'BackgroundColor', panel_bg, 'HorizontalAlignment', 'left');
        t.Layout.Row = 1;
        p.UserData = struct('Body', gl);
    end

    % Panel 1: Progress
    p1 = card('COMPUTATION PROGRESS');
    p1.Layout.Row = 1; p1.Layout.Column = 1;
    body1 = p1.UserData.Body;
    ax_progress = uiaxes(body1);
    ax_progress.Layout.Row = 2;
    ax_progress.XLim = [0 1]; ax_progress.YLim = [0 1];
    ax_progress.Visible = 'off';
    ax_progress.Color = panel_bg;
    hold(ax_progress, 'on');
    progress_bar = patch(ax_progress, [0 0 0 0], [0 0 1 1], accent, 'FaceAlpha', 0.85, 'EdgeColor', 'none');
    rectangle(ax_progress, 'Position', [0 0 1 1], 'EdgeColor', panel_edge, 'LineWidth', 1.2);
    progress_text = text(ax_progress, 0.5, 0.5, 'Initializing...', 'Color', text_main, ...
        'FontSize', 13, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

    % Panel 2: Time
    p2 = card('ELAPSED TIME');
    p2.Layout.Row = 1; p2.Layout.Column = 2;
    body2 = p2.UserData.Body;
    ax_time = uiaxes(body2);
    ax_time.Layout.Row = 2;
    ax_time.Color = panel_bg;
    ax_time.XColor = text_dim; ax_time.YColor = text_dim;
    ax_time.GridColor = [0.2 0.3 0.45]; ax_time.GridAlpha = 0.25;
    ax_time.XLabel.String = 'Iteration'; ax_time.YLabel.String = 'Time (s)';
    ax_time.XLabel.Color = text_dim; ax_time.YLabel.Color = text_dim;
    time_line = plot(ax_time, NaN, NaN, 'LineWidth', 2, 'Color', accent);
    grid(ax_time, 'on');

    % Panel 3: Performance
    p3 = card('PERFORMANCE');
    p3.Layout.Row = 1; p3.Layout.Column = 3;
    body3 = p3.UserData.Body;
    g3 = uigridlayout(body3, [4 1]);
    g3.RowHeight = {'1x','1x','1x','1x'};
    g3.Padding = [2 2 2 2];
    avg_time = uilabel(g3, 'Text', 'Avg Time/Iter: --', 'FontColor', accent, 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    est_remaining = uilabel(g3, 'Text', 'Est. Remaining: --', 'FontColor', [0.0 1.0 0.5], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    memory = uilabel(g3, 'Text', 'Memory Usage: --', 'FontColor', [1.0 0.7 0.2], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    overhead = uilabel(g3, 'Text', 'Monitor Overhead: --', 'FontColor', [1.0 0.5 0.5], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');

    % Panel 4: Computational load
    p4 = card('COMPUTATIONAL LOAD');
    p4.Layout.Row = 2; p4.Layout.Column = 1;
    body4 = p4.UserData.Body;
    g4 = uigridlayout(body4, [4 1]);
    g4.RowHeight = {'1x','1x','1x','1x'};
    g4.Padding = [2 2 2 2];
    total_ops = uilabel(g4, 'Text', 'Total Operations: --', 'FontColor', [1.0 0.8 0.2], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    grid_size = uilabel(g4, 'Text', 'Grid Size: --', 'FontColor', [0.5 1.0 1.0], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    time_steps = uilabel(g4, 'Text', 'Time Steps: --', 'FontColor', [1.0 0.6 0.8], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    phase = uilabel(g4, 'Text', 'Current Phase: --', 'FontColor', text_main, 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');

    % Panel 5: Speed
    p5 = card('ITERATION SPEED');
    p5.Layout.Row = 2; p5.Layout.Column = 2;
    body5 = p5.UserData.Body;
    ax_speed = uiaxes(body5);
    ax_speed.Layout.Row = 2;
    ax_speed.Color = panel_bg;
    ax_speed.XColor = text_dim; ax_speed.YColor = text_dim;
    ax_speed.GridColor = [0.2 0.3 0.45]; ax_speed.GridAlpha = 0.25;
    ax_speed.XLabel.String = 'Iteration'; ax_speed.YLabel.String = 'Iter/sec';
    ax_speed.XLabel.Color = text_dim; ax_speed.YLabel.Color = text_dim;
    speed_line = plot(ax_speed, NaN, NaN, 'LineWidth', 2, 'Color', [0.95 0.45 1.0]);
    grid(ax_speed, 'on');

    % Panel 6: Key metrics
    p6 = card('KEY METRICS');
    p6.Layout.Row = 2; p6.Layout.Column = 3;
    body6 = p6.UserData.Body;
    g6 = uigridlayout(body6, [5 1]);
    g6.RowHeight = {'1x','1x','1x','1x','1x'};
    g6.Padding = [2 2 2 2];
    max_vort = uilabel(g6, 'Text', 'Max Vorticity: --', 'FontColor', [1.0 0.3 0.3], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    total_energy = uilabel(g6, 'Text', 'Total Energy: --', 'FontColor', [0.3 1.0 0.3], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    convergence = uilabel(g6, 'Text', 'Convergence: --', 'FontColor', [0.3 0.8 1.0], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    conv_status = uilabel(g6, 'Text', 'Convergence Status: --', 'FontColor', [1.0 1.0 0.3], 'BackgroundColor', panel_bg, 'FontSize', 11, 'HorizontalAlignment', 'center');
    status = uilabel(g6, 'Text', 'Status: Initializing', 'FontColor', accent, 'BackgroundColor', panel_bg, 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    monitor_data.ui = struct(...
        'fig', fig, ...
        'progress_ax', ax_progress, ...
        'progress_bar', progress_bar, ...
        'progress_text', progress_text, ...
        'time_ax', ax_time, ...
        'time_line', time_line, ...
        'time_phase_lines', gobjects(0), ...
        'speed_ax', ax_speed, ...
        'speed_line', speed_line, ...
        'speed_phase_lines', gobjects(0), ...
        'avg_time', avg_time, ...
        'est_remaining', est_remaining, ...
        'memory', memory, ...
        'overhead', overhead, ...
        'total_ops', total_ops, ...
        'grid_size', grid_size, ...
        'time_steps', time_steps, ...
        'phase', phase, ...
        'max_vort', max_vort, ...
        'total_energy', total_energy, ...
        'convergence', convergence, ...
        'conv_status', conv_status, ...
        'status', status, ...
        'colors', struct('accent', accent, 'text_main', text_main, 'text_dim', text_dim) ...
    );

    cache_live_monitor_fonts(fig);
    fig.SizeChangedFcn = @(src, evt) resize_live_monitor_ui(src);

    drawnow;
end

function position_monitor_next_to_main(monitor_fig)
    try
        screen = get(0, 'ScreenSize');
        padding = 20;
        width = floor((screen(3) - 3 * padding) / 2);
        height = floor(screen(4) - 2 * padding);
        left_pos = [screen(1) + padding, screen(2) + padding, width, height];
        right_pos = [screen(1) + 2 * padding + width, screen(2) + padding, width, height];

        figs = findall(0, 'Type', 'figure');
        uifigs = findall(0, 'Type', 'uifigure');
        main_fig = [];

        for k = 1:numel(figs)
            if isvalid(figs(k)) && figs(k) ~= monitor_fig
                main_fig = figs(k);
                break;
            end
        end

        if isempty(main_fig)
            for k = 1:numel(uifigs)
                if isvalid(uifigs(k)) && uifigs(k) ~= monitor_fig
                    main_fig = uifigs(k);
                    break;
                end
            end
        end

        if ~isempty(main_fig) && isvalid(main_fig)
            try
                main_fig.Position = left_pos;
            catch
                set(main_fig, 'Position', left_pos);
            end
            monitor_fig.Position = right_pos;
        else
            monitor_fig.Position = right_pos;
        end
    catch
        % If positioning fails, keep default placement
    end
end

function cache_live_monitor_fonts(fig)
    labels = findall(fig, 'Type', 'uilabel');
    axes_list = findall(fig, 'Type', 'uiaxes');
    text_list = findall(fig, 'Type', 'text');

    cache = struct();
    cache.base_width = fig.Position(3);
    cache.labels = labels;
    cache.label_sizes = arrayfun(@(h) h.FontSize, labels);
    cache.axes = axes_list;
    cache.axes_sizes = arrayfun(@(h) h.FontSize, axes_list);
    cache.title_sizes = arrayfun(@(h) h.Title.FontSize, axes_list);
    cache.xlabel_sizes = arrayfun(@(h) h.XLabel.FontSize, axes_list);
    cache.ylabel_sizes = arrayfun(@(h) h.YLabel.FontSize, axes_list);
    cache.text = text_list;
    cache.text_sizes = arrayfun(@(h) h.FontSize, text_list);

    fig.UserData = cache;
end

function resize_live_monitor_ui(fig)
    try
        cache = fig.UserData;
        if isempty(cache) || ~isfield(cache, 'base_width')
            cache_live_monitor_fonts(fig);
            cache = fig.UserData;
        end

        scale = fig.Position(3) / max(cache.base_width, 1);
        scale = min(max(scale, 0.75), 1.4);

        for i = 1:numel(cache.labels)
            if isvalid(cache.labels(i))
                cache.labels(i).FontSize = max(8, cache.label_sizes(i) * scale);
            end
        end

        for i = 1:numel(cache.axes)
            if isvalid(cache.axes(i))
                cache.axes(i).FontSize = max(8, cache.axes_sizes(i) * scale);
                cache.axes(i).Title.FontSize = max(9, cache.title_sizes(i) * scale);
                cache.axes(i).XLabel.FontSize = max(8, cache.xlabel_sizes(i) * scale);
                cache.axes(i).YLabel.FontSize = max(8, cache.ylabel_sizes(i) * scale);
            end
        end

        for i = 1:numel(cache.text)
            if isvalid(cache.text(i))
                cache.text(i).FontSize = max(9, cache.text_sizes(i) * scale);
            end
        end
    catch
        % Ignore resize errors
    end
end
