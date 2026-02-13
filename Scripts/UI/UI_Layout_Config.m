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
    % Top-level grid: toolbar (40px) | tab content (flexible) | hidden footer
    cfg.root_grid.rows_cols    = [3, 1];
    cfg.root_grid.row_heights  = {40, '1x', 0};       % Fixed toolbar, flexible content, hidden row
    cfg.root_grid.col_widths   = {'1x'};              % Single full-width column
    cfg.root_grid.padding      = [5 5 5 5];           % [top, bottom, left, right] in pixels
    cfg.root_grid.row_spacing  = 5;                   % Vertical spacing between rows
    cfg.root_grid.col_spacing  = 5;                   % Horizontal spacing (single column, minimal)

    % ===== TAB GROUP GRID =====
    % Tab group positioned in row 2 (flexible-height content area) of root grid
    cfg.tab_group.parent_row   = 2;                   % Row containing tabs
    cfg.tab_group.parent_col   = 1;                   % Column containing tabs
    cfg.tab_group.order        = {'config', 'monitoring', 'results'};  % Tab creation order

    % ===== STANDARD COMPONENT SIZES =====
    % Defines preferred heights for all UI element types (in pixels)
    cfg.sizes.button_height        = 34;              % Standard button height
    cfg.sizes.dropdown_height      = 30;              % Dropdown/combobox height
    cfg.sizes.edit_height          = 30;              % Single-line edit field
    cfg.sizes.label_height         = 22;              % Text label height
    cfg.sizes.checkbox_height      = 24;              % Checkbox control height
    cfg.sizes.textarea_height      = 78;              % Multi-line text area height
    cfg.sizes.panel_title_padding  = 10;              % Padding around panel titles
    cfg.sizes.form_row_height      = 30;              % Standard form row height
    cfg.sizes.form_row_tall        = 40;              % Tall form row (e.g., multi-line content)

    % ===== STANDARD HEIGHT ALIASES =====
    % Mirror sizes struct for easier reference in layout configs (cfg.heights.*)
    cfg.heights.button          = cfg.sizes.button_height;
    cfg.heights.dropdown        = cfg.sizes.dropdown_height;
    cfg.heights.edit            = cfg.sizes.edit_height;
    cfg.heights.label           = cfg.sizes.label_height;
    cfg.heights.checkbox        = cfg.sizes.checkbox_height;
    cfg.heights.textarea        = cfg.sizes.textarea_height;
    cfg.heights.form_row        = cfg.sizes.form_row_height;
    cfg.heights.form_row_tall   = cfg.sizes.form_row_tall;

    % ===== CONFIG TAB =====
    % Configuration tab: 2-column layout (left=1.1x wider, right=1x narrower)
    cfg.config_tab.root.rows_cols      = [1, 2];      % Single row, 2 columns
    cfg.config_tab.root.col_widths     = {'1.1x', '1x'};  % Left wider, right narrower
    cfg.config_tab.root.row_heights    = {'1x'};      % Single flexible row
    cfg.config_tab.root.padding        = [10 10 10 10]; % Inner padding all sides
    cfg.config_tab.root.row_spacing    = 10;          % Row spacing (not used: 1 row)
    cfg.config_tab.root.col_spacing    = 12;          % Column spacing between left/right

    % Left column: 7 stacked panels (method, grid, time, sim, convergence, sustainability, spacer)
    cfg.config_tab.left.rows_cols      = [7, 1];      % 7 rows, 1 column
    cfg.config_tab.left.row_heights    = {150, 145, 105, 145, 190, 105, '1x'};  % Fixed heights + flexible footer
    cfg.config_tab.left.padding        = [10 10 10 10]; % Panel internal padding
    cfg.config_tab.left.row_spacing    = 8;           % Vertical spacing between panels

    % Right column: 3 stacked panels (readiness, initial condition, IC preview) with proportional heights
    cfg.config_tab.right.rows_cols     = [3, 1];      % 3 rows, 1 column
    cfg.config_tab.right.row_heights   = {'0.9x', '1.15x', '1.45x'};  % Proportional flexible sizing
    cfg.config_tab.right.padding       = [10 10 10 10]; % Panel internal padding
    cfg.config_tab.right.row_spacing   = 8;           % Vertical spacing between panels

    % Method panel: 5x4 grid for algorithm/mode selectors (5 control rows, 4 columns)
    cfg.config_tab.method_grid.rows_cols    = [5, 4]; % 5 rows, 4 columns
    cfg.config_tab.method_grid.col_widths   = {'1x', '1x', '1x', '1x'};  % Equal-width columns
    cfg.config_tab.method_grid.row_heights  = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.method_grid.padding      = [6 6 6 6]; % Inner padding
    cfg.config_tab.method_grid.row_spacing  = 6;       % Vertical spacing

    % Grid panel: 3x4 grid for domain/mesh parameters (Nx, Ny, Lx, Ly, etc.)
    cfg.config_tab.grid_grid.rows_cols     = [3, 4]; % 3 rows, 4 columns
    cfg.config_tab.grid_grid.col_widths    = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.grid_grid.row_heights   = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.grid_grid.padding       = [6 6 6 6];

    % Time panel: 2x4 grid for temporal parameters (dt, Tfinal, nu, etc.)
    cfg.config_tab.time_grid.rows_cols     = [2, 4]; % 2 rows, 4 columns
    cfg.config_tab.time_grid.col_widths    = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.time_grid.row_heights   = {cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.time_grid.padding       = [6 6 6 6];

    % Simulation panel: 3x4 grid for output/save/animation parameters
    cfg.config_tab.sim_grid.rows_cols      = [3, 4]; % 3 rows, 4 columns
    cfg.config_tab.sim_grid.col_widths     = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.sim_grid.row_heights    = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.sim_grid.padding        = [6 6 6 6];

    % Convergence panel: 5x4 grid for convergence study parameters (sweeps, ranges, etc.)
    cfg.config_tab.conv_grid.rows_cols     = [5, 4]; % 5 rows, 4 columns
    cfg.config_tab.conv_grid.col_widths    = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.conv_grid.row_heights   = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.conv_grid.padding       = [6 6 6 6];

    % Sustainability panel: 4x4 grid for monitoring/collector settings
    cfg.config_tab.sus_grid.rows_cols      = [4, 4]; % 4 rows, 4 columns
    cfg.config_tab.sus_grid.col_widths     = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.sus_grid.row_heights    = {cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};
    cfg.config_tab.sus_grid.padding        = [6 6 6 6];

    % Readiness panel: 3x1 column for pre-flight checks, status, and launch button
    cfg.config_tab.check_grid.rows_cols   = [3, 1]; % 3 rows, 1 column
    cfg.config_tab.check_grid.col_widths  = {'1x'};   % Full width
    cfg.config_tab.check_grid.row_heights = {64, 36, cfg.heights.button};  % Status, message, button
    cfg.config_tab.check_grid.padding     = [6 6 6 6];
    cfg.config_tab.check_grid.row_spacing = 4;       % Tight spacing

    % IC panel: 8x4 grid for initial condition parameters (type, amplitude, wavelength, etc.)
    cfg.config_tab.ic_grid.rows_cols     = [8, 4]; % 8 rows, 4 columns
    cfg.config_tab.ic_grid.col_widths    = {'1x', '1x', '1x', '1x'};
    cfg.config_tab.ic_grid.row_heights   = {cfg.heights.form_row, cfg.heights.form_row, 92, 72, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row, cfg.heights.form_row};  % Fixed + spacious rows
    cfg.config_tab.ic_grid.padding       = [6 6 6 6];
    cfg.config_tab.ic_grid.row_spacing   = 6;

    % ===== MONITOR TAB =====
    % Live monitoring: 2-column layout (main plots 3x wider, sidebar 1x narrower)
    cfg.monitor_tab.root.rows_cols     = [1, 2];      % Single row, 2 columns
    cfg.monitor_tab.root.col_widths    = {'3x', '1x'};  % Left: plots (wider), Right: sidebar
    cfg.monitor_tab.root.row_heights   = {'1x'};      % Single flexible row
    cfg.monitor_tab.root.padding       = [10 10 10 10]; % Inner padding
    cfg.monitor_tab.root.col_spacing   = 12;          % Column spacing

    % 3x3 plot grid configuration (8 plots + 1 numeric metrics panel)
    cfg.monitor_tab.plot_grid_rows      = 3;          % 3 rows in plot grid
    cfg.monitor_tab.plot_grid_cols      = 3;          % 3 columns in plot grid
    cfg.monitor_tab.plot_tile_count     = 9;          % Total tiles (3x3)
    cfg.monitor_tab.numeric_tile_index  = 9;          % Last tile (position 9) is numeric display
    cfg.monitor_tab.plot_area_ratio     = 0.75;       % Plots occupy 75% of available space

    % Plot grid: 3x3 equal tiles with flexible sizing
    cfg.monitor_tab.left.rows_cols   = [cfg.monitor_tab.plot_grid_rows, cfg.monitor_tab.plot_grid_cols];  % 3x3
    cfg.monitor_tab.left.row_heights = {'1x', '1x', '1x'};  % Equal-height rows
    cfg.monitor_tab.left.col_widths  = {'1x', '1x', '1x'};  % Equal-width columns
    cfg.monitor_tab.left.padding     = [8 8 8 8];   % Inner padding per tile
    cfg.monitor_tab.left.row_spacing = 10;          % Vertical spacing between tiles
    cfg.monitor_tab.left.col_spacing = 10;          % Horizontal spacing between tiles

    % Sidebar: 4x1 column for terminal, status, metrics, and run info
    cfg.monitor_tab.sidebar.rows_cols      = [4, 1]; % 4 rows, 1 column
    cfg.monitor_tab.sidebar.row_heights    = {36, 24, '1x', 'fit'};  % Fixed + flexible + auto-fit
    cfg.monitor_tab.sidebar.padding        = [8 8 8 8]; % Inner padding
    cfg.monitor_tab.sidebar.row_spacing    = 8;       % Vertical spacing
    cfg.monitor_tab.live_update = struct( ...
        'refresh_stride', 2, ...           % Refresh plots every N accepted payloads
        'min_refresh_seconds', 0.12, ...   % Time-based refresh floor
        'force_refresh_every', 25, ...     % Guaranteed refresh cadence
        'max_history_points', 500);        % Keep tail samples for responsive plotting

    % ===== RESULTS TAB =====
    % Results display: 2-row layout (figures flexible + metrics fixed 140px)
    cfg.results_tab.root.rows_cols     = [2, 1];      % 2 rows, 1 column
    cfg.results_tab.root.row_heights   = {'1x', 140}; % Figures flexible, metrics fixed
    cfg.results_tab.root.padding       = [10 10 10 10]; % Inner padding
    cfg.results_tab.root.row_spacing   = 10;          % Vertical spacing

    % Figure display grid: controls + figure canvas
    cfg.results_tab.fig_grid.rows_cols    = [2, 1]; % 2 rows, 1 column
    cfg.results_tab.fig_grid.row_heights  = {cfg.heights.form_row_tall, '1x'};  % Control bar + canvas
    cfg.results_tab.fig_grid.padding      = [6 6 6 6];

    % Control bar: 1x5 grid for navigation and action buttons
    cfg.results_tab.controls.rows_cols  = [1, 5]; % 1 row, 5 columns
    cfg.results_tab.controls.col_widths = {90, '1x', 110, 100, 90};  % Mixed fixed/flexible
    cfg.results_tab.controls.row_heights = {cfg.heights.button};
    cfg.results_tab.controls.padding    = [0 0 0 0]; % No padding (tight)
    cfg.results_tab.controls.col_spacing = 8;      % Column spacing

    % ===== EXPLICIT GRID COORDINATES =====
    % Maps component names to grid positions [row, col, rowspan, colspan]
    % Used for programmatic placement and to avoid magic numbers in controller code
    cfg.coords = struct();

    % Configuration tab coordinates
    cfg.coords.config.left              = [1, 1, 1, 1];  % Left column (entire column)
    cfg.coords.config.right             = [1, 2, 1, 1];  % Right column (entire column)
    cfg.coords.config.panel_method      = [1, 1, 1, 1];  % Method panel (left row 1)
    cfg.coords.config.panel_grid        = [2, 1, 1, 1];  % Grid panel (left row 2)
    cfg.coords.config.panel_time        = [3, 1, 1, 1];  % Time panel (left row 3)
    cfg.coords.config.panel_sim         = [4, 1, 1, 1];  % Sim panel (left row 4)
    cfg.coords.config.panel_conv        = [5, 1, 1, 1];  % Convergence panel (left row 5)
    cfg.coords.config.panel_sus         = [6, 1, 1, 1];  % Sustainability panel (left row 6)
    cfg.coords.config.panel_check       = [1, 1, 1, 1];  % Readiness panel (right row 1)
    cfg.coords.config.panel_ic          = [2, 1, 1, 1];  % IC panel (right row 2)
    cfg.coords.config.panel_preview     = [3, 1, 1, 1];  % IC Preview panel (right row 3)

    % Monitor tab coordinates
    cfg.coords.monitor.left_panel        = [1, 1, 1, 1];  % Plot grid (row 1, col 1)
    cfg.coords.monitor.terminal_panel   = [1, 2, 1, 1];  % Sidebar (row 1, col 2)
    cfg.coords.monitor.panel_iter_time  = [1, 1, 1, 1];  % Iteration time plot (grid pos)
    cfg.coords.monitor.panel_iter_per_sec = [1, 2, 1, 1]; % Iterations/sec plot (grid pos)
    cfg.coords.monitor.panel_conv       = [2, 1, 1, 1];  % Convergence plot (grid pos)
    cfg.coords.monitor.panel_metrics    = [2, 2, 1, 1];  % Metrics panel (grid pos)

    % Results tab coordinates
    cfg.coords.results.panel_fig      = [1, 1, 1, 1];  % Figure display (row 1)
    cfg.coords.results.panel_metrics  = [2, 1, 1, 1];  % Metrics summary (row 2)

    % ===== UI TEXT MANIFEST =====
    % Centralized human-facing strings used by major layout panels/tabs.
    % Enables easy internationalization and consistent UI labeling
    cfg.text.app_title = 'Tsunami Vortex Simulation UI';  % Main window title
    cfg.text.tabs = struct( ...
        'config', 'Configuration', ...
        'monitoring', 'Live Monitor', ...
        'results', 'Results and Figures');
    cfg.text.config_panels = struct( ...
        'method', 'Method and Mode', ...
        'grid', 'Grid and Domain', ...
        'time', 'Time and Physics', ...
        'simulation', 'Simulation Settings', ...
        'convergence', 'Convergence Study', ...
        'sustainability', 'Sustainability', ...
        'readiness', 'Readiness Checklist', ...
        'ic', 'Initial Condition', ...
        'preview', 'IC Preview (t=0)');
    cfg.text.monitor_panels = struct( ...
        'dashboard', 'Live Monitor Dashboard (3x3: 8 plots + 1 numeric tile)', ...
        'numeric_tile', 'Simulation Metrics (Categorized)', ...
        'sidebar', 'Terminal and Telemetry', ...
        'collector', 'Collector Probe and Runtime Signals');
    cfg.text.results_panels = struct( ...
        'figures', 'Figures', ...
        'metrics', 'Metrics Summary');
    cfg.text.placeholder = struct( ...
        'value', '<placeholder>', ...
        'description_prefix', 'Placeholder for');

    % ===== DEFAULTS PROVENANCE =====
    % Clarifies where launch defaults are loaded from.
    % Helpful for debugging and understanding configuration flow
    cfg.defaults_source = struct( ...
        'summary', 'Startup defaults are loaded via create_default_parameters.m and mirrored in Scripts/Editable/Parameters.m + Scripts/Editable/Settings.m', ...
        'loader', 'Scripts/Infrastructure/Initialisers/create_default_parameters.m', ...
        'editable_parameters', 'Scripts/Editable/Parameters.m', ...
        'editable_settings', 'Scripts/Editable/Settings.m', ...
        'default_keys', {{'method', 'mode', 'Nx', 'Ny', 'Lx', 'Ly', 'dt', 'Tfinal', 'nu', ...
            'num_snapshots', 'ic_type', 'create_animations', 'animation_format', ...
            'animation_fps', 'bathymetry_enabled'}});

    % ===== LAYOUT MANIFEST =====
    % This manifest is consumed by UI_Layout_Sandbox for rapid UI trialing.
    % Provides a flat map of major UI components for debugging and visualization
    cfg.layout_manifest = build_layout_manifest(cfg);
    cfg.tab_layout = build_tab_layout_groups(cfg);

    % ===== DEVELOPER MODE SETTINGS =====
    % Enable inspector overlay and component highlighting for layout debugging
    cfg.dev_mode.enabled         = false;  % Default off - set true to enable inspector
    cfg.dev_mode.inspector_width = 300;    % pixels - width of inspector panel
    cfg.dev_mode.highlight_color = [1 0.8 0];  % yellow - RGB color for highlighting
    cfg.dev_mode.highlight_width = 2;      % pixels - outline thickness
    
    % ===== COLOR SCHEME (Dark Mode) =====
    % RGB color values (0-1 scale) for consistent dark-mode styling
    % Background colors (dark -> light)
    cfg.colors.bg_dark        = [0.11 0.11 0.11];  % Darkest background
    cfg.colors.bg_panel       = [0.16 0.16 0.16];  % Standard panel background
    cfg.colors.bg_panel_alt   = [0.20 0.20 0.20];  % Alternate panel (contrast)
    cfg.colors.bg_input       = [0.13 0.13 0.13];  % Input field background
    % Text colors
    cfg.colors.fg_text        = [0.90 0.90 0.90];  % Primary text (bright white)
    cfg.colors.fg_muted       = [0.72 0.72 0.72];  % Secondary text (dimmed)
    % Accent colors (status/semantic)
    cfg.colors.accent_green   = [0.25 0.78 0.35];  % Success/valid status
    cfg.colors.accent_yellow  = [0.95 0.72 0.20];  % Warning/caution status
    cfg.colors.accent_red     = [0.90 0.35 0.35];  % Error/invalid status
    cfg.colors.accent_cyan    = [0.35 0.72 0.95];  % Info/highlight status
    cfg.colors.accent_gray    = [0.60 0.60 0.60];  % Disabled/inactive state
    
end

function tab_layout = build_tab_layout_groups(cfg)
    % build_tab_layout_groups - Group layout controls per tab for easier editing.
    %
    % Field order inside each tab group:
    %   tab_name -> grid -> sections -> sub_tabs -> plots
    %
    % This is an editor-facing organization layer and keeps legacy fields intact
    % (`cfg.config_tab`, `cfg.monitor_tab`, `cfg.results_tab`) for compatibility.

    tab_layout = struct();

    tab_layout.config = struct( ...
        'tab_name', cfg.text.tabs.config, ...
        'grid', cfg.config_tab.root, ...
        'sections', struct( ...
            'left_column', cfg.config_tab.left, ...
            'right_column', cfg.config_tab.right, ...
            'method', cfg.config_tab.method_grid, ...
            'grid', cfg.config_tab.grid_grid, ...
            'time', cfg.config_tab.time_grid, ...
            'simulation', cfg.config_tab.sim_grid, ...
            'convergence', cfg.config_tab.conv_grid, ...
            'sustainability', cfg.config_tab.sus_grid, ...
            'readiness', cfg.config_tab.check_grid, ...
            'initial_condition', cfg.config_tab.ic_grid), ...
        'sub_tabs', struct(), ...
        'plots', struct(), ...
        'coords', cfg.coords.config);

    tab_layout.monitoring = struct( ...
        'tab_name', cfg.text.tabs.monitoring, ...
        'grid', cfg.monitor_tab.root, ...
        'sections', struct( ...
            'dashboard_grid', cfg.monitor_tab.left, ...
            'sidebar', cfg.monitor_tab.sidebar), ...
        'sub_tabs', struct(), ...
        'plots', struct( ...
            'plot_grid_rows', cfg.monitor_tab.plot_grid_rows, ...
            'plot_grid_cols', cfg.monitor_tab.plot_grid_cols, ...
            'plot_tile_count', cfg.monitor_tab.plot_tile_count, ...
            'numeric_tile_index', cfg.monitor_tab.numeric_tile_index, ...
            'live_update', cfg.monitor_tab.live_update), ...
        'coords', cfg.coords.monitor);

    tab_layout.results = struct( ...
        'tab_name', cfg.text.tabs.results, ...
        'grid', cfg.results_tab.root, ...
        'sections', struct( ...
            'figure_area', cfg.results_tab.fig_grid, ...
            'control_row', cfg.results_tab.controls), ...
        'sub_tabs', struct('default_preview', 'Preview'), ...
        'plots', struct(), ...
        'coords', cfg.coords.results);
end

function manifest = build_layout_manifest(cfg)
    % build_layout_manifest - Flat major-component map for sandbox rendering.
    % Creates a comprehensive index of all UI regions for debugging/visualization
    manifest = struct( ...
        'id', {}, ...
        'region', {}, ...
        'coords', {}, ...
        'title', {}, ...
        'description', {});

    % Configuration tab entries
    manifest(end + 1) = make_entry('config_left', 'Configuration', cfg.coords.config.left, ...
        'Configuration Left Column', 'Method/grid/time/simulation/convergence/sustainability stacks');
    manifest(end + 1) = make_entry('config_right', 'Configuration', cfg.coords.config.right, ...
        'Configuration Right Column', 'Readiness, initial condition, and preview stacks');
    manifest(end + 1) = make_entry('config_method', 'Configuration', cfg.coords.config.panel_method, ...
        cfg.text.config_panels.method, 'Method and run-mode selector panel');
    manifest(end + 1) = make_entry('config_grid', 'Configuration', cfg.coords.config.panel_grid, ...
        cfg.text.config_panels.grid, 'Grid size and spatial-domain panel');
    manifest(end + 1) = make_entry('config_time', 'Configuration', cfg.coords.config.panel_time, ...
        cfg.text.config_panels.time, 'Time-step and viscosity panel');
    manifest(end + 1) = make_entry('config_sim', 'Configuration', cfg.coords.config.panel_sim, ...
        cfg.text.config_panels.simulation, 'Output/save/animation panel');
    manifest(end + 1) = make_entry('config_conv', 'Configuration', cfg.coords.config.panel_conv, ...
        cfg.text.config_panels.convergence, 'Convergence controls panel');
    manifest(end + 1) = make_entry('config_sus', 'Configuration', cfg.coords.config.panel_sus, ...
        cfg.text.config_panels.sustainability, 'Sustainability collectors and monitoring panel');
    manifest(end + 1) = make_entry('config_check', 'Configuration', cfg.coords.config.panel_check, ...
        cfg.text.config_panels.readiness, 'Readiness checks and launch controls');
    % Right column entries (readiness, IC setup, IC preview)
    manifest(end + 1) = make_entry('config_ic', 'Configuration', cfg.coords.config.panel_ic, ...
        cfg.text.config_panels.ic, 'Initial condition parameter panel');
    manifest(end + 1) = make_entry('config_preview', 'Configuration', cfg.coords.config.panel_preview, ...
        cfg.text.config_panels.preview, 'Initial condition visualization panel');

    % Live Monitor tab entries
    manifest(end + 1) = make_entry('monitor_left', 'Live Monitor', cfg.coords.monitor.left_panel, ...
        cfg.text.monitor_panels.dashboard, '8 plot tiles plus 1 numeric metrics tile');
    manifest(end + 1) = make_entry('monitor_sidebar', 'Live Monitor', cfg.coords.monitor.terminal_panel, ...
        cfg.text.monitor_panels.sidebar, 'Terminal log, run status, collector probes');

    % Results tab entries
    manifest(end + 1) = make_entry('results_figures', 'Results and Figures', cfg.coords.results.panel_fig, ...
        cfg.text.results_panels.figures, 'Generated figure browser and display');
    manifest(end + 1) = make_entry('results_metrics', 'Results and Figures', cfg.coords.results.panel_metrics, ...
        cfg.text.results_panels.metrics, 'Metrics summary readout');
end

function entry = make_entry(id, region, coords, title_txt, description_txt)
    % Helper function to create manifest entry struct
    entry = struct( ...
        'id', id, ...
        'region', region, ...
        'coords', coords, ...
        'title', title_txt, ...
        'description', description_txt);
end
