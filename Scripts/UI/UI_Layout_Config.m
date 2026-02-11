function cfg = UI_Layout_Config()
% UI_LAYOUT_CONFIG - Centralized layout configuration for UIController
%
% Purpose:
%   Single source of truth for all UI layout parameters
%   Editing layout = edit this file only
%
% Returns:
%   cfg - struct with layout configuration
%
% Usage:
%   cfg = UI_Layout_Config();
%   main_grid = uigridlayout(parent, cfg.main_grid.rows_cols);
%   main_grid.ColumnWidth = cfg.main_grid.col_widths;
%
% Constraints:
%   - All sizes must be valid MATLAB layout specs
%   - Row/column indices must match component placement map
%
% References:
%   MATLAB uigridlayout documentation:
%   https://www.mathworks.com/help/matlab/ref/matlab.ui.container.gridlayout-properties.html

    % ===== ROOT FIGURE GRID =====
    cfg.root_grid.rows_cols = [3, 1];
    cfg.root_grid.row_heights = {40, '1x', 0};
    cfg.root_grid.col_widths = {'1x'};
    cfg.root_grid.padding = [5 5 5 5];
    cfg.root_grid.row_spacing = 5;
    cfg.root_grid.col_spacing = 5;

    % ===== TAB GROUP GRID =====
    cfg.tab_group.parent_row = 2;
    cfg.tab_group.parent_col = 1;

    % ===== STANDARD COMPONENT SIZES =====
    cfg.sizes.button_height = 34;
    cfg.sizes.dropdown_height = 30;
    cfg.sizes.edit_height = 30;
    cfg.sizes.label_height = 22;
    cfg.sizes.checkbox_height = 24;
    cfg.sizes.textarea_height = 78;
    cfg.sizes.panel_title_padding = 10;
    cfg.sizes.form_row_height = 30;
    cfg.sizes.form_row_tall = 40;

    % ===== STANDARD HEIGHT ALIASES =====
    cfg.heights.button = cfg.sizes.button_height;
    cfg.heights.dropdown = cfg.sizes.dropdown_height;
    cfg.heights.edit = cfg.sizes.edit_height;
    cfg.heights.label = cfg.sizes.label_height;
    cfg.heights.checkbox = cfg.sizes.checkbox_height;
    cfg.heights.textarea = cfg.sizes.textarea_height;
    cfg.heights.form_row = cfg.sizes.form_row_height;
    cfg.heights.form_row_tall = cfg.sizes.form_row_tall;

    % ===== CONFIG TAB =====
    cfg.config_tab.root.rows_cols = [1, 2];
    cfg.config_tab.root.col_widths = {'1.1x', '1x'};
    cfg.config_tab.root.row_heights = {'1x'};
    cfg.config_tab.root.padding = [10 10 10 10];
    cfg.config_tab.root.row_spacing = 10;
    cfg.config_tab.root.col_spacing = 12;

    cfg.config_tab.left.rows_cols = [7, 1];
    cfg.config_tab.left.row_heights = {150, 145, 105, 145, 190, 105, '1x'};
    cfg.config_tab.left.padding = [10 10 10 10];
    cfg.config_tab.left.row_spacing = 8;

    cfg.config_tab.right.rows_cols = [4, 1];
    cfg.config_tab.right.row_heights = {'0.9x', '1.1x', '0.7x', '1.3x'};
    cfg.config_tab.right.padding = [10 10 10 10];
    cfg.config_tab.right.row_spacing = 8;

    cfg.config_tab.method_grid.rows_cols = [3, 4];
    cfg.config_tab.method_grid.col_widths = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.method_grid.row_heights = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.method_grid.padding = [6 6 6 6];
    cfg.config_tab.method_grid.row_spacing = 6;

    cfg.config_tab.grid_grid.rows_cols = [3, 4];
    cfg.config_tab.grid_grid.col_widths = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.grid_grid.row_heights = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.grid_grid.padding = [6 6 6 6];

    cfg.config_tab.time_grid.rows_cols = [2, 4];
    cfg.config_tab.time_grid.col_widths = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.time_grid.row_heights = {cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.time_grid.padding = [6 6 6 6];

    cfg.config_tab.sim_grid.rows_cols = [3, 4];
    cfg.config_tab.sim_grid.col_widths = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.sim_grid.row_heights = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.sim_grid.padding = [6 6 6 6];

    cfg.config_tab.conv_grid.rows_cols = [4, 4];
    cfg.config_tab.conv_grid.col_widths = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.conv_grid.row_heights = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.conv_grid.padding = [6 6 6 6];

    cfg.config_tab.sus_grid.rows_cols = [2, 2];
    cfg.config_tab.sus_grid.col_widths = {'1x', '1x'};
    cfg.config_tab.sus_grid.row_heights = {cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.sus_grid.padding = [6 6 6 6];

    cfg.config_tab.check_grid.rows_cols = [4, 1];
    cfg.config_tab.check_grid.col_widths = {'1x'};
    cfg.config_tab.check_grid.row_heights = {76, 40, cfg.heights.form_row, cfg.heights.button};
    cfg.config_tab.check_grid.padding = [6 6 6 6];
    cfg.config_tab.check_grid.row_spacing = 6;

    cfg.config_tab.ic_grid.rows_cols = [7, 4];
    cfg.config_tab.ic_grid.col_widths = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.ic_grid.row_heights = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.textarea, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.ic_grid.padding = [6 6 6 6];
    cfg.config_tab.ic_grid.row_spacing = 6;

    cfg.config_tab.mode_grid.rows_cols = [3, 4];
    cfg.config_tab.mode_grid.col_widths = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.mode_grid.row_heights = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.mode_grid.padding = [6 6 6 6];
    cfg.config_tab.mode_grid.row_spacing = 6;

    % ===== MONITOR TAB =====
    cfg.monitor_tab.root.rows_cols = [1, 2];
    cfg.monitor_tab.root.col_widths = {'3x', '1x'};
    cfg.monitor_tab.root.row_heights = {'1x'};
    cfg.monitor_tab.root.padding = [10 10 10 10];
    cfg.monitor_tab.root.col_spacing = 12;

    cfg.monitor_tab.left.rows_cols = [2, 2];
    cfg.monitor_tab.left.row_heights = {'1x', '1x'};
    cfg.monitor_tab.left.col_widths = {'1x', '1x'};
    cfg.monitor_tab.left.padding = [8 8 8 8];
    cfg.monitor_tab.left.row_spacing = 10;
    cfg.monitor_tab.left.col_spacing = 10;

    cfg.monitor_tab.metrics.rows_cols = [12, 2];
    cfg.monitor_tab.metrics.col_widths = {'1x', '1x'};
    cfg.monitor_tab.metrics.row_heights = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.monitor_tab.metrics.padding = [6 6 6 6];
    cfg.monitor_tab.metrics.row_spacing = 4;

    % ===== RESULTS TAB =====
    cfg.results_tab.root.rows_cols = [2, 1];
    cfg.results_tab.root.row_heights = {'1x', 140};
    cfg.results_tab.root.padding = [10 10 10 10];
    cfg.results_tab.root.row_spacing = 10;

    cfg.results_tab.fig_grid.rows_cols = [2, 1];
    cfg.results_tab.fig_grid.row_heights = {cfg.heights.form_row_tall, '1x'};
    cfg.results_tab.fig_grid.padding = [6 6 6 6];

    cfg.results_tab.controls.rows_cols = [1, 5];
    cfg.results_tab.controls.col_widths = {90, '1x', 110, 100, 90};
    cfg.results_tab.controls.row_heights = {cfg.heights.button};
    cfg.results_tab.controls.padding = [0 0 0 0];
    cfg.results_tab.controls.col_spacing = 8;

    % ===== EXPLICIT GRID COORDINATES =====
    cfg.coords = struct();

    cfg.coords.config.left = [1, 1, 1, 1];
    cfg.coords.config.right = [1, 2, 1, 1];
    cfg.coords.config.panel_method = [1, 1, 1, 1];
    cfg.coords.config.panel_grid = [2, 1, 1, 1];
    cfg.coords.config.panel_time = [3, 1, 1, 1];
    cfg.coords.config.panel_sim = [4, 1, 1, 1];
    cfg.coords.config.panel_conv = [5, 1, 1, 1];
    cfg.coords.config.panel_sus = [6, 1, 1, 1];
    cfg.coords.config.panel_check = [1, 1, 1, 1];
    cfg.coords.config.panel_ic = [2, 1, 1, 1];
    cfg.coords.config.panel_mode = [3, 1, 1, 1];
    cfg.coords.config.panel_preview = [4, 1, 1, 1];

    cfg.coords.monitor.left_panel = [1, 1, 1, 1];
    cfg.coords.monitor.terminal_panel = [1, 2, 1, 1];
    cfg.coords.monitor.panel_iter_time = [1, 1, 1, 1];
    cfg.coords.monitor.panel_iter_per_sec = [1, 2, 1, 1];
    cfg.coords.monitor.panel_conv = [2, 1, 1, 1];
    cfg.coords.monitor.panel_metrics = [2, 2, 1, 1];

    cfg.coords.results.panel_fig = [1, 1, 1, 1];
    cfg.coords.results.panel_metrics = [2, 1, 1, 1];

    % ===== DEVELOPER MODE SETTINGS =====
    cfg.dev_mode.enabled = false;  % Default off
    cfg.dev_mode.inspector_width = 300;  % pixels
    cfg.dev_mode.highlight_color = [1 0.8 0];  % yellow
    cfg.dev_mode.highlight_width = 2;
    
    % ===== COLOR SCHEME (Dark Mode) =====
    cfg.colors.bg_dark = [0.11 0.11 0.11];
    cfg.colors.bg_panel = [0.16 0.16 0.16];
    cfg.colors.bg_panel_alt = [0.20 0.20 0.20];
    cfg.colors.bg_input = [0.13 0.13 0.13];
    cfg.colors.fg_text = [0.90 0.90 0.90];
    cfg.colors.fg_muted = [0.72 0.72 0.72];
    cfg.colors.accent_green = [0.25 0.78 0.35];
    cfg.colors.accent_yellow = [0.95 0.72 0.20];
    cfg.colors.accent_red = [0.90 0.35 0.35];
    cfg.colors.accent_cyan = [0.35 0.72 0.95];
    cfg.colors.accent_gray = [0.60 0.60 0.60];
    
end
