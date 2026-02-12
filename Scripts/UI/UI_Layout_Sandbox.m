function sandbox = UI_Layout_Sandbox(varargin)
% UI_LAYOUT_SANDBOX - Dummy UI that mirrors production layout with placeholders.
%
% Purpose:
%   Give a safe playground for layout edits without touching runtime logic.
%   All coordinates and titles come from UI_Layout_Config().
%
% Usage:
%   sandbox = UI_Layout_Sandbox();
%   sandbox = UI_Layout_Sandbox('Visible', 'on');
%
% Returns:
%   sandbox.fig      - Sandbox uifigure handle
%   sandbox.cfg      - Layout config used to build sandbox
%   sandbox.handles  - Struct of representative placeholder handles

    p = inputParser;
    addParameter(p, 'Visible', 'off', @(x) ischar(x) || isstring(x));
    parse(p, varargin{:});

    cfg = UI_Layout_Config();
    C = cfg.colors;

    fig = uifigure('Name', sprintf('%s - Layout Sandbox', cfg.text.app_title), ...
        'Color', C.bg_dark, ...
        'Visible', 'off', ...
        'AutoResizeChildren', 'on');
    if isprop(fig, 'Theme')
        fig.Theme = 'dark';
    end

    root = uigridlayout(fig, cfg.root_grid.rows_cols);
    root.RowHeight = cfg.root_grid.row_heights;
    root.ColumnWidth = cfg.root_grid.col_widths;
    root.Padding = cfg.root_grid.padding;
    root.RowSpacing = cfg.root_grid.row_spacing;
    root.ColumnSpacing = cfg.root_grid.col_spacing;

    banner = uipanel(root, 'BorderType', 'none', 'BackgroundColor', C.bg_panel);
    banner.Layout.Row = 1;
    banner.Layout.Column = 1;
    banner_grid = uigridlayout(banner, [1, 2]);
    banner_grid.ColumnWidth = {'1x', 'fit'};
    banner_grid.Padding = [8 6 8 6];
    uilabel(banner_grid, ...
        'Text', sprintf('%s (Sandbox)', cfg.text.app_title), ...
        'FontColor', C.fg_text, ...
        'FontWeight', 'bold', ...
        'FontSize', 13);
    uilabel(banner_grid, ...
        'Text', 'Placeholder-only layout trial surface', ...
        'FontColor', C.fg_muted, ...
        'HorizontalAlignment', 'right');

    tab_group = uitabgroup(root);
    tab_group.Layout.Row = 2;
    tab_group.Layout.Column = 1;

    handles = struct();
    handles.config = build_config_tab(tab_group, cfg, C);
    handles.monitor = build_monitor_tab(tab_group, cfg, C);
    handles.results = build_results_tab(tab_group, cfg, C);

    fig.Visible = char(string(p.Results.Visible));

    sandbox = struct();
    sandbox.fig = fig;
    sandbox.cfg = cfg;
    sandbox.handles = handles;
end

function out = build_config_tab(tab_group, cfg, C)
    out = struct();
    tab = uitab(tab_group, 'Title', cfg.text.tabs.config, 'BackgroundColor', C.bg_panel_alt);
    root = uigridlayout(tab, cfg.config_tab.root.rows_cols);
    root.RowHeight = cfg.config_tab.root.row_heights;
    root.ColumnWidth = cfg.config_tab.root.col_widths;
    root.Padding = cfg.config_tab.root.padding;
    root.RowSpacing = cfg.config_tab.root.row_spacing;
    root.ColumnSpacing = cfg.config_tab.root.col_spacing;

    left = uipanel(root, 'Title', 'Configuration Left Column', 'BackgroundColor', C.bg_panel, 'Scrollable', 'on');
    left.Layout.Row = cfg.coords.config.left(1);
    left.Layout.Column = cfg.coords.config.left(2);
    left_grid = uigridlayout(left, cfg.config_tab.left.rows_cols);
    left_grid.RowHeight = cfg.config_tab.left.row_heights;
    left_grid.Padding = cfg.config_tab.left.padding;
    left_grid.RowSpacing = cfg.config_tab.left.row_spacing;

    add_placeholder_panel(left_grid, cfg.coords.config.panel_method, cfg.text.config_panels.method, ...
        'Method/mode selectors + source defaults placeholder', C);
    add_placeholder_panel(left_grid, cfg.coords.config.panel_grid, cfg.text.config_panels.grid, ...
        'Nx, Ny, Lx, Ly, delta placeholders', C);
    add_placeholder_panel(left_grid, cfg.coords.config.panel_time, cfg.text.config_panels.time, ...
        'dt, Tfinal, nu placeholders', C);
    add_placeholder_panel(left_grid, cfg.coords.config.panel_sim, cfg.text.config_panels.simulation, ...
        'Save/export/animation placeholders', C);
    add_placeholder_panel(left_grid, cfg.coords.config.panel_conv, cfg.text.config_panels.convergence, ...
        'Convergence controls placeholders', C);
    add_placeholder_panel(left_grid, cfg.coords.config.panel_sus, cfg.text.config_panels.sustainability, ...
        'Monitoring and collector placeholders', C);

    right = uipanel(root, 'Title', 'Configuration Right Column', 'BackgroundColor', C.bg_panel, 'Scrollable', 'on');
    right.Layout.Row = cfg.coords.config.right(1);
    right.Layout.Column = cfg.coords.config.right(2);
    right_grid = uigridlayout(right, cfg.config_tab.right.rows_cols);
    right_grid.RowHeight = cfg.config_tab.right.row_heights;
    right_grid.Padding = cfg.config_tab.right.padding;
    right_grid.RowSpacing = cfg.config_tab.right.row_spacing;

    add_placeholder_panel(right_grid, cfg.coords.config.panel_check, cfg.text.config_panels.readiness, ...
        'Checklist + launch/import/export placeholders', C);
    add_placeholder_panel(right_grid, cfg.coords.config.panel_ic, cfg.text.config_panels.ic, ...
        'IC equation and coefficients placeholders', C);
    add_placeholder_panel(right_grid, cfg.coords.config.panel_preview, cfg.text.config_panels.preview, ...
        'IC preview axes placeholder', C);

    out.tab = tab;
    out.left_panel = left;
    out.right_panel = right;
end

function out = build_monitor_tab(tab_group, cfg, C)
    out = struct();
    tab = uitab(tab_group, 'Title', cfg.text.tabs.monitoring, 'BackgroundColor', C.bg_panel_alt);
    root = uigridlayout(tab, cfg.monitor_tab.root.rows_cols);
    root.RowHeight = cfg.monitor_tab.root.row_heights;
    root.ColumnWidth = cfg.monitor_tab.root.col_widths;
    root.Padding = cfg.monitor_tab.root.padding;
    root.ColumnSpacing = cfg.monitor_tab.root.col_spacing;

    dashboard = uipanel(root, 'Title', cfg.text.monitor_panels.dashboard, 'BackgroundColor', C.bg_panel);
    dashboard.Layout.Row = cfg.coords.monitor.left_panel(1);
    dashboard.Layout.Column = cfg.coords.monitor.left_panel(2);
    dash_grid = uigridlayout(dashboard, [cfg.monitor_tab.plot_grid_rows, cfg.monitor_tab.plot_grid_cols]);
    dash_grid.Padding = cfg.monitor_tab.left.padding;
    dash_grid.RowSpacing = cfg.monitor_tab.left.row_spacing;
    dash_grid.ColumnSpacing = cfg.monitor_tab.left.col_spacing;

    for i = 1:cfg.monitor_tab.plot_tile_count
        tile_row = ceil(i / cfg.monitor_tab.plot_grid_cols);
        tile_col = mod(i - 1, cfg.monitor_tab.plot_grid_cols) + 1;
        if i == cfg.monitor_tab.numeric_tile_index
            tile = uipanel(dash_grid, 'Title', cfg.text.monitor_panels.numeric_tile, 'BackgroundColor', C.bg_panel_alt);
            tile.Layout.Row = tile_row;
            tile.Layout.Column = tile_col;
            tgrid = uigridlayout(tile, [1 1]);
            tgrid.Padding = [4 4 4 4];
            uitable(tgrid, 'ColumnName', {'Metric', 'Value', 'Unit', 'Source'}, ...
                'Data', {'Status', cfg.text.placeholder.value, '-', 'Sandbox'});
        else
            tile = uipanel(dash_grid, 'Title', sprintf('Plot Tile %d', i), 'BackgroundColor', C.bg_panel_alt);
            tile.Layout.Row = tile_row;
            tile.Layout.Column = tile_col;
            tgrid = uigridlayout(tile, [1 1]);
            tgrid.Padding = [4 4 4 4];
            ax = uiaxes(tgrid);
            ax.Color = C.bg_dark;
            ax.XColor = C.fg_text;
            ax.YColor = C.fg_text;
            title(ax, sprintf('Placeholder %d', i), 'Color', C.fg_text, 'FontSize', 10);
            grid(ax, 'on');
        end
    end

    sidebar = uipanel(root, 'Title', cfg.text.monitor_panels.sidebar, 'BackgroundColor', C.bg_panel);
    sidebar.Layout.Row = cfg.coords.monitor.terminal_panel(1);
    sidebar.Layout.Column = cfg.coords.monitor.terminal_panel(2);
    side_grid = uigridlayout(sidebar, cfg.monitor_tab.sidebar.rows_cols);
    side_grid.RowHeight = cfg.monitor_tab.sidebar.row_heights;
    side_grid.Padding = cfg.monitor_tab.sidebar.padding;
    side_grid.RowSpacing = cfg.monitor_tab.sidebar.row_spacing;

    uilabel(side_grid, ...
        'Text', sprintf('%s run status', cfg.text.placeholder.description_prefix), ...
        'FontColor', C.fg_muted, ...
        'HorizontalAlignment', 'center');
    uilabel(side_grid, ...
        'Text', cfg.text.placeholder.value, ...
        'FontColor', C.fg_text, ...
        'HorizontalAlignment', 'center');
    uitextarea(side_grid, ...
        'Value', {sprintf('%s terminal output', cfg.text.placeholder.description_prefix)}, ...
        'Editable', 'off');
    collector = uipanel(side_grid, 'Title', cfg.text.monitor_panels.collector, 'BackgroundColor', C.bg_panel_alt);
    collector_grid = uigridlayout(collector, [2 1]);
    collector_grid.Padding = [4 4 4 4];
    uilabel(collector_grid, 'Text', 'Collector lights placeholder', 'FontColor', C.fg_muted, 'HorizontalAlignment', 'center');
    uilabel(collector_grid, 'Text', 'MATLAB / CPU-Z / HWiNFO / iCUE', 'FontColor', C.fg_text, 'HorizontalAlignment', 'center');

    out.tab = tab;
    out.dashboard_panel = dashboard;
    out.sidebar_panel = sidebar;
end

function out = build_results_tab(tab_group, cfg, C)
    out = struct();
    tab = uitab(tab_group, 'Title', cfg.text.tabs.results, 'BackgroundColor', C.bg_panel_alt);
    root = uigridlayout(tab, cfg.results_tab.root.rows_cols);
    root.RowHeight = cfg.results_tab.root.row_heights;
    root.Padding = cfg.results_tab.root.padding;
    root.RowSpacing = cfg.results_tab.root.row_spacing;

    figures_panel = uipanel(root, 'Title', cfg.text.results_panels.figures, 'BackgroundColor', C.bg_panel);
    figures_panel.Layout.Row = cfg.coords.results.panel_fig(1);
    figures_panel.Layout.Column = cfg.coords.results.panel_fig(2);
    add_panel_placeholder(figures_panel, ...
        'Figure tab group + controls placeholder', ...
        cfg.text.placeholder.value, C);

    metrics_panel = uipanel(root, 'Title', cfg.text.results_panels.metrics, 'BackgroundColor', C.bg_panel);
    metrics_panel.Layout.Row = cfg.coords.results.panel_metrics(1);
    metrics_panel.Layout.Column = cfg.coords.results.panel_metrics(2);
    add_panel_placeholder(metrics_panel, ...
        'Metrics summary placeholder', ...
        cfg.text.placeholder.value, C);

    out.tab = tab;
    out.figures_panel = figures_panel;
    out.metrics_panel = metrics_panel;
end

function add_placeholder_panel(parent_grid, coords, panel_title, subtitle, C)
    panel = uipanel(parent_grid, 'Title', panel_title, 'BackgroundColor', C.bg_panel_alt);
    panel.Layout.Row = coords(1);
    panel.Layout.Column = coords(2);
    add_panel_placeholder(panel, subtitle, '<placeholder>', C);
end

function add_panel_placeholder(panel, subtitle, value_txt, C)
    grid = uigridlayout(panel, [2 1]);
    grid.RowHeight = {24, '1x'};
    grid.Padding = [6 6 6 6];
    uilabel(grid, 'Text', subtitle, 'FontColor', C.fg_muted, 'FontSize', 10);
    uilabel(grid, ...
        'Text', value_txt, ...
        'FontColor', C.accent_cyan, ...
        'HorizontalAlignment', 'center', ...
        'FontWeight', 'bold');
end
