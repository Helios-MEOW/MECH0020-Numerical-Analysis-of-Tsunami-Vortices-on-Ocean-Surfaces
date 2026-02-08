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
    % Main figure grid: [rows, cols]
    % Layout: top menu bar, main content, bottom status bar
    cfg.root_grid.rows_cols = [3, 1];
    cfg.root_grid.row_heights = {'fit', '1x', 'fit'};  % menu, content, status
    cfg.root_grid.col_widths = {'1x'};
    cfg.root_grid.padding = [5 5 5 5];
    cfg.root_grid.row_spacing = 5;
    cfg.root_grid.col_spacing = 5;
    
    % ===== TAB GROUP GRID (replaces Position) =====
    % Tab group occupies row 2 (main content area)
    cfg.tab_group.parent_row = 2;
    cfg.tab_group.parent_col = 1;
    
    % ===== CONFIG TAB: LEFT-RIGHT SPLIT =====
    cfg.config_tab.root.rows_cols = [1, 2];
    cfg.config_tab.root.col_widths = {'1.05x', '1x'};  % left slightly wider
    cfg.config_tab.root.row_heights = {'1x'};
    cfg.config_tab.root.padding = [10 10 10 10];
    cfg.config_tab.root.row_spacing = 10;
    cfg.config_tab.root.col_spacing = 12;
    
    % Left panel: 7-row vertical stack
    cfg.config_tab.left.rows_cols = [7, 1];
    cfg.config_tab.left.row_heights = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '1x'};
    cfg.config_tab.left.padding = [10 10 10 10];
    cfg.config_tab.left.row_spacing = 8;
    
    % Right panel: 3-row vertical stack (checklist, IC, preview)
    cfg.config_tab.right.rows_cols = [3, 1];
    cfg.config_tab.right.row_heights = {'fit', 'fit', '1x'};
    cfg.config_tab.right.padding = [10 10 10 10];
    cfg.config_tab.right.row_spacing = 8;
    
    % ===== MONITORING TAB: LEFT-RIGHT SPLIT =====
    cfg.monitor_tab.root.rows_cols = [1, 2];
    cfg.monitor_tab.root.col_widths = {'1x', '1.5x'};  % right wider for plots
    cfg.monitor_tab.root.row_heights = {'1x'};
    cfg.monitor_tab.root.padding = [10 10 10 10];
    cfg.monitor_tab.root.row_spacing = 10;
    cfg.monitor_tab.root.col_spacing = 12;
    
    % Left panel: 2x2 gauges
    cfg.monitor_tab.left.rows_cols = [2, 2];
    cfg.monitor_tab.left.row_heights = {'1x', '1x'};
    cfg.monitor_tab.left.col_widths = {'1x', '1x'};
    cfg.monitor_tab.left.padding = [10 10 10 10];
    cfg.monitor_tab.left.row_spacing = 8;
    cfg.monitor_tab.left.col_spacing = 8;
    
    % Right panel: top controls + bottom metrics/terminal
    cfg.monitor_tab.right.rows_cols = [2, 1];
    cfg.monitor_tab.right.row_heights = {'fit', '1x'};
    cfg.monitor_tab.right.padding = [10 10 10 10];
    cfg.monitor_tab.right.row_spacing = 8;
    
    % ===== RESULTS TAB: TOP-BOTTOM SPLIT =====
    cfg.results_tab.root.rows_cols = [2, 1];
    cfg.results_tab.root.row_heights = {'fit', '1x'};
    cfg.results_tab.root.padding = [10 10 10 10];
    cfg.results_tab.root.row_spacing = 10;
    
    % Top panel: figure controls
    cfg.results_tab.top.rows_cols = [2, 1];
    cfg.results_tab.top.row_heights = {'fit', 'fit'};
    cfg.results_tab.top.padding = [8 8 8 8];
    cfg.results_tab.top.row_spacing = 6;
    
    % Control row: 5 buttons
    cfg.results_tab.controls.rows_cols = [1, 5];
    cfg.results_tab.controls.col_widths = {'2x', '1x', '1x', '1x', '1x'};
    cfg.results_tab.controls.row_heights = {'fit'};
    cfg.results_tab.controls.padding = [5 5 5 5];
    cfg.results_tab.controls.col_spacing = 8;
    

    % ===== STANDARD COMPONENT SIZES =====
    cfg.sizes.button_height = 40;
    cfg.sizes.dropdown_height = 30;
    cfg.sizes.edit_height = 28;
    cfg.sizes.label_height = 22;
    cfg.sizes.checkbox_height = 22;
    cfg.sizes.panel_title_padding = 10;
    
    % ===== DEVELOPER MODE SETTINGS =====
    cfg.dev_mode.enabled = false;  % Default off
    cfg.dev_mode.inspector_width = 300;  % pixels
    cfg.dev_mode.highlight_color = [1 0.8 0];  % yellow
    cfg.dev_mode.highlight_width = 2;
    
    % ===== COLOR SCHEME (Dark Mode) =====
    cfg.colors.bg_dark = [0.15 0.15 0.15];
    cfg.colors.bg_panel = [0.20 0.20 0.20];
    cfg.colors.fg_text = [0.9 0.9 0.9];
    cfg.colors.accent_green = [0.3 1.0 0.3];
    cfg.colors.accent_yellow = [1.0 0.8 0.2];
    cfg.colors.accent_red = [1.0 0.3 0.3];
    cfg.colors.accent_cyan = [0.3 0.8 1.0];
    cfg.colors.accent_gray = [0.7 0.7 0.7];
    
end
