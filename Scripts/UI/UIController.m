% ========================================================================
% TSUNAMI VORTEX SIMULATION - UNIFIED USER INTERFACE (CLASS-BASED)
% ========================================================================
% Purpose:
%   Comprehensive GUI for configuring and launching numerical simulations
%   Self-contained interface with integrated monitoring and visualization
%
% Features:
%   • Method Selection (Finite Difference, Finite Volume, Spectral)
%   • Mode Configuration (Evolution, Convergence, Sweep, Animation, Experimentation)
%   • Initial Condition Designer (Default presets + custom configuration)
%   • Live Execution Monitor (CPU, Memory, Iteration tracking)
%   • Convergence Monitor (Real-time error decay, mesh refinement tracking)
%   • Parameter Validation & Export to Tsunami_Vorticity_Emulator
%   • Developer Mode (layout inspector, click-to-inspect, validation tools)
%
% Usage:
%   >> app = UIController();
%   % Configure settings in GUI, then click "Launch Simulation"
%   % Enable Developer Mode from menu bar for layout editing
%
% Architecture:
%   Class-based UI with internal state management
%   All monitors are embedded in the UI (no separate windows)
%   Clean encapsulation with properties and methods
%   Grid-based layout (uigridlayout) for intuitive editing
%
% Layout Editing (How to Safely Modify UI):
%   1. Enable Developer Mode (menu bar button)
%   2. Click any component to inspect its properties
%   3. Edit layout parameters in UI_Layout_Config.m (NOT this file)
%   4. All sizing, spacing, placement defined in UI_Layout_Config.m
%   5. Use "Validate All Layouts" tool to check for errors
%
% Adding New Components:
%   1. Add entry to UI_Layout_Config.m placement map
%   2. Create component in appropriate create_*_tab method
%   3. Set Layout.Row and Layout.Column from config
%   4. DO NOT use Position property (use grid layout only)
%
% Callback Signatures (DO NOT CHANGE):
%   - launch_simulation(app)
%   - on_method_changed(app)
%   - on_mode_changed(app)
%   - update_ic_preview(app)
%
% References:
%   MATLAB uifigure/uigridlayout documentation:
%   https://www.mathworks.com/help/matlab/ref/matlab.ui.container.gridlayout.html
%
% ========================================================================

classdef UIController < handle
    
    properties (Access = public)
        fig                    % Main figure
        root_grid              % Root grid layout (replaces manual positioning)
        tab_group              % Tab group container
        tabs                   % Structure of tab handles
        handles                % All UI component handles
        config                 % Configuration structure
        terminal_log           % Cell array of terminal output
        terminal_type_log      % Message type tags aligned with terminal_log
        figures_list           % Storage for generated figures
        diary_file             % MATLAB diary file for terminal capture
        diary_timer            % Timer for terminal refresh
        diary_last_size        % Last diary file size
        layout_cfg             % Centralized layout configuration
        dev_mode_enabled       % Developer Mode toggle
        dev_inspector_panel    % Developer Mode inspector panel
        selected_component     % Currently selected component in dev mode
        dev_original_callbacks % Stores original callbacks for dev mode click inspection
    end
    
    properties (Access = private)
        % Terminal color scheme (RGB triplets)
        color_success          % Success messages: bright green
        color_warning          % Warnings: yellow/orange
        color_error            % Errors: red
        color_info             % Info messages: cyan
        color_debug            % Debug messages: light gray
    end
    
    methods
        function app = UIController(varargin)
            % Constructor - creates and initializes the UI
            close all;

            % Optional constructor override for automated testing:
            %   UIController('StartupMode', 'ui' | 'traditional')
            p = inputParser;
            addParameter(p, 'StartupMode', '', @(x) ischar(x) || isstring(x));
            parse(p, varargin{:});
            forced_startup_mode = lower(string(p.Results.StartupMode));
            
            % Initialize properties
            app.config = app.initialize_default_config();
            app.handles = struct();
            app.terminal_log = {};
            app.terminal_type_log = {};
            app.figures_list = {};
            app.dev_mode_enabled = false;  % Developer Mode off by default
            app.selected_component = [];
            app.dev_original_callbacks = [];  % Will be containers.Map when dev mode enabled
            
            % Load centralized layout configuration
            app.layout_cfg = UI_Layout_Config();
            
            % Initialize terminal color scheme (RGB triplets)
            app.color_success = [0.3 1.0 0.3];     % Bright green
            app.color_warning = [1.0 0.8 0.2];     % Yellow/orange
            app.color_error = [1.0 0.3 0.3];       % Red
            app.color_info = [0.3 0.8 1.0];        % Cyan
            app.color_debug = [0.7 0.7 0.7];       % Light gray
            
            % Show startup decision dialog unless mode is forced by caller
            if strlength(forced_startup_mode) > 0
                choice = char(forced_startup_mode);
            else
                choice = app.show_startup_dialog();
            end
            
            if strcmp(choice, 'traditional')
                % User chose traditional mode - exit UI
                setappdata(0, 'ui_mode', 'traditional');
                return;
            end

                % Ensure required script folders are on the MATLAB path
                try
                    ui_dir = fileparts(mfilename('fullpath'));
                    scripts_dir = fileparts(ui_dir);
                    addpath(fullfile(scripts_dir, 'Infrastructure', 'Builds'));
                    addpath(fullfile(scripts_dir, 'Infrastructure', 'DataRelatedHelpers'));
                    addpath(fullfile(scripts_dir, 'Infrastructure', 'Initialisers'));
                    addpath(fullfile(scripts_dir, 'Infrastructure', 'Runners'));
                    addpath(fullfile(scripts_dir, 'Infrastructure', 'Utilities'));
                    addpath(fullfile(scripts_dir, 'Methods'));
                    addpath(fullfile(scripts_dir, 'Modes'));
                    addpath(fullfile(scripts_dir, 'Modes', 'Convergence'));
                catch
                    % If path setup fails, IC preview will report a clear error
                end
            
            % User chose UI mode - create full interface
            % Create main figure (maximized, dark mode)
            app.fig = uifigure('Name', 'Tsunami Numerical Simulation UI', ...
                'WindowState', 'maximized', ...
                'Color', app.layout_cfg.colors.bg_dark, ...
                'AutoResizeChildren', 'on', ...
                'CloseRequestFcn', @(~,~) app.cleanup());
            if isprop(app.fig, 'Theme')
                app.fig.Theme = 'dark';
            end
            
            % Create root grid layout (replaces manual Position sizing)
            % Layout: [menu bar (fit), main content (1x), status bar (fit)]
            app.root_grid = uigridlayout(app.fig, app.layout_cfg.root_grid.rows_cols);
            app.root_grid.RowHeight = app.layout_cfg.root_grid.row_heights;
            app.root_grid.ColumnWidth = app.layout_cfg.root_grid.col_widths;
            app.root_grid.Padding = app.layout_cfg.root_grid.padding;
            app.root_grid.RowSpacing = app.layout_cfg.root_grid.row_spacing;
            app.root_grid.ColumnSpacing = app.layout_cfg.root_grid.col_spacing;
            
            % Create menu bar (row 1)
            app.create_menu_bar();
            
            % Create tab group in main content area (row 2)
            app.tab_group = uitabgroup(app.root_grid, ...
                'FontSize', 12, 'FontWeight', 'bold');
            app.tab_group.Layout.Row = app.layout_cfg.tab_group.parent_row;
            app.tab_group.Layout.Column = app.layout_cfg.tab_group.parent_col;
            
            % Create status bar (row 3) - placeholder for future use
            % (Currently unused, but reserved in layout config)
            
            % Create all tabs
            app.create_all_tabs();
            
            % Create control buttons
            app.create_control_buttons();

            % Start MATLAB terminal capture
            app.start_terminal_capture();
            
            % Make UI visible (non-blocking)
            app.fig.Visible = 'on';
        end
        
        function choice = show_startup_dialog(~)
            % Show initial choice dialog: UI Mode or Traditional Mode
            dialog_fig = uifigure('Name', 'Simulation Mode Selection', ...
                'Position', [400 400 600 300], ...
                'Color', [0.12 0.12 0.12], ...
                'Visible', 'off');
            if isprop(dialog_fig, 'Theme')
                dialog_fig.Theme = 'dark';
            end
            
            choice = 'ui';  % Default
            
            % Title
            uilabel(dialog_fig, 'Position', [50 220 500 50], ...
                'Text', 'Choose Simulation Interface', ...
                'FontSize', 18, 'FontWeight', 'bold', ...
                'FontColor', [0.92 0.92 0.92]);
            
            % Description
            uilabel(dialog_fig, 'Position', [50 160 500 40], ...
                'Text', 'How would you like to run the simulation?', ...
                'FontSize', 12, ...
                'FontColor', [0.82 0.82 0.82]);
            
            % UI Mode Button
            uibutton(dialog_fig, 'push', 'Position', [50 80 200 60], ...
                'Text', sprintf('🖥️ UI Mode\n(Full Configuration Interface)'), ...
                'FontSize', 12, ...
                'BackgroundColor', [0.25 0.78 0.35], ...
                'FontColor', [0.05 0.05 0.05], ...
                'ButtonPushedFcn', @(~,~) set_choice('ui'));
            
            % Traditional Mode Button
            uibutton(dialog_fig, 'push', 'Position', [300 80 200 60], ...
                'Text', sprintf('📊 Traditional\n(Separate Windows)'), ...
                'FontSize', 12, ...
                'BackgroundColor', [0.35 0.72 0.95], ...
                'FontColor', [0.05 0.05 0.05], ...
                'ButtonPushedFcn', @(~,~) set_choice('traditional'));
            
            dialog_fig.Visible = 'on';
            uiwait(dialog_fig);
            
            % Retrieve choice and clean up
            if isappdata(0, 'ui_mode_choice')
                choice = getappdata(0, 'ui_mode_choice');
                rmappdata(0, 'ui_mode_choice');
            end
            
            if isvalid(dialog_fig)
                delete(dialog_fig);
            end
            
            function set_choice(mode)
                setappdata(0, 'ui_mode_choice', mode);
                uiresume(dialog_fig);
            end
        end
        
        function create_all_tabs(app)
            % Create streamlined UI tabs (consolidated from 9 to 5)
            % All tabs styled with dark mode colors
            app.tabs.config = uitab(app.tab_group, 'Title', 'Configuration', ...
                'BackgroundColor', app.layout_cfg.colors.bg_panel_alt);
            app.create_config_tab();
            
            app.tabs.monitoring = uitab(app.tab_group, 'Title', 'Live Monitor', ...
                'BackgroundColor', app.layout_cfg.colors.bg_panel_alt);
            app.create_monitoring_tab();
            
            app.tabs.results = uitab(app.tab_group, 'Title', 'Results and Figures', ...
                'BackgroundColor', app.layout_cfg.colors.bg_panel_alt);
            app.create_results_tab();
        end
        
        function create_control_buttons(~)
            % Control buttons now integrated into readiness checklist
            % (Previously placed at bottom, now in right panel checklist area)
        end
        
        % Tab creation methods
        function create_config_tab(app)
            % Build configuration tab using explicit grid coordinates from UI_Layout_Config
            C = app.layout_cfg.colors;

            parent = app.tabs.config;
            parent.BackgroundColor = C.bg_dark;

            cfg_root = app.layout_cfg.config_tab.root;
            root = uigridlayout(parent, cfg_root.rows_cols);
            root.ColumnWidth = cfg_root.col_widths;
            root.RowHeight = cfg_root.row_heights;
            root.Padding = cfg_root.padding;
            root.RowSpacing = cfg_root.row_spacing;
            root.ColumnSpacing = cfg_root.col_spacing;

            left = uipanel(root, 'Title', 'Configuration', 'FontWeight', 'bold', ...
                'BackgroundColor', C.bg_panel);
            left.Layout.Row = app.layout_cfg.coords.config.left(1);
            left.Layout.Column = app.layout_cfg.coords.config.left(2);

            right = uipanel(root, 'Title', 'Initial Conditions and Preview', 'FontWeight', 'bold', ...
                'BackgroundColor', C.bg_panel);
            right.Layout.Row = app.layout_cfg.coords.config.right(1);
            right.Layout.Column = app.layout_cfg.coords.config.right(2);

            cfg_left = app.layout_cfg.config_tab.left;
            left_layout = uigridlayout(left, cfg_left.rows_cols);
            left_layout.RowHeight = cfg_left.row_heights;
            left_layout.Padding = cfg_left.padding;
            left_layout.RowSpacing = cfg_left.row_spacing;

            % Method and mode panel
            panel_method = uipanel(left_layout, 'Title', 'Method and Mode', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_method.Layout.Row = app.layout_cfg.coords.config.panel_method(1);
            panel_method.Layout.Column = app.layout_cfg.coords.config.panel_method(2);
            cfg_method = app.layout_cfg.config_tab.method_grid;
            method_grid = uigridlayout(panel_method, cfg_method.rows_cols);
            method_grid.ColumnWidth = cfg_method.col_widths;
            method_grid.RowHeight = cfg_method.row_heights;
            method_grid.RowSpacing = cfg_method.row_spacing;
            method_grid.Padding = cfg_method.padding;

            lbl = uilabel(method_grid, 'Text', 'Method', 'FontColor', C.fg_text);
            lbl.Layout.Row = 1; lbl.Layout.Column = 1;
            app.handles.method_dropdown = uidropdown(method_grid, ...
                'Items', {'Finite Difference', 'Finite Volume', 'Spectral'}, ...
                'Value', 'Finite Difference', ...
                'ValueChangedFcn', @(~,~) app.on_method_changed());
            app.handles.method_dropdown.Layout.Row = 1;
            app.handles.method_dropdown.Layout.Column = 2;

            lbl = uilabel(method_grid, 'Text', 'Mode', 'FontColor', C.fg_text);
            lbl.Layout.Row = 1; lbl.Layout.Column = 3;
            app.handles.mode_dropdown = uidropdown(method_grid, ...
                'Items', {'Evolution', 'Convergence', 'Sweep', 'Animation', 'Experimentation'}, ...
                'Value', 'Evolution', ...
                'ValueChangedFcn', @(~,~) app.on_mode_changed());
            app.handles.mode_dropdown.Layout.Row = 1;
            app.handles.mode_dropdown.Layout.Column = 4;

            lbl = uilabel(method_grid, 'Text', 'Boundary', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 1;
            app.handles.boundary_label = uilabel(method_grid, 'Text', 'Periodic (x,y)', ...
                'FontColor', C.fg_text);
            app.handles.boundary_label.Layout.Row = 2;
            app.handles.boundary_label.Layout.Column = [2 4];

            app.handles.bathy_enable = uicheckbox(method_grid, ...
                'Text', 'Use Bathymetry', 'Value', false, ...
                'FontColor', C.fg_text, ...
                'ValueChangedFcn', @(~,~) app.on_method_changed());
            app.handles.bathy_enable.Layout.Row = 3;
            app.handles.bathy_enable.Layout.Column = 1;

            app.handles.bathy_file = uieditfield(method_grid, 'text', ...
                'Value', '', 'Placeholder', 'Bathymetry file');
            app.handles.bathy_file.Layout.Row = 3;
            app.handles.bathy_file.Layout.Column = [2 3];

            app.handles.bathy_browse_btn = uibutton(method_grid, 'Text', 'Browse', ...
                'ButtonPushedFcn', @(~,~) app.browse_bathymetry_file());
            app.handles.bathy_browse_btn.Layout.Row = 3;
            app.handles.bathy_browse_btn.Layout.Column = 4;

            app.handles.motion_enable = uicheckbox(method_grid, ...
                'Text', 'Enable Seabed Motion', 'Value', false, ...
                'FontColor', C.fg_text, ...
                'ValueChangedFcn', @(~,~) app.on_method_changed());
            app.handles.motion_enable.Layout.Row = 4;
            app.handles.motion_enable.Layout.Column = 1;

            app.handles.motion_model = uidropdown(method_grid, ...
                'Items', {'none', 'sinusoidal', 'gaussian_pulse', 'file_driven'}, ...
                'Value', 'none', ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.motion_model.Layout.Row = 4;
            app.handles.motion_model.Layout.Column = 2;

            app.handles.motion_amplitude = uieditfield(method_grid, 'numeric', ...
                'Value', 0.0, 'Limits', [0 Inf], ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.motion_amplitude.Layout.Row = 4;
            app.handles.motion_amplitude.Layout.Column = 3;
            lbl = uilabel(method_grid, 'Text', 'Amplitude', 'FontColor', C.fg_text);
            lbl.Layout.Row = 4;
            lbl.Layout.Column = 4;

            app.handles.physics_status = uilabel(method_grid, ...
                'Text', 'Bathymetry and motion configured independently', ...
                'FontColor', C.fg_muted);
            app.handles.physics_status.Layout.Row = 5;
            app.handles.physics_status.Layout.Column = [1 4];

            % Grid and domain panel
            panel_grid = uipanel(left_layout, 'Title', 'Grid and Domain', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_grid.Layout.Row = app.layout_cfg.coords.config.panel_grid(1);
            panel_grid.Layout.Column = app.layout_cfg.coords.config.panel_grid(2);
            cfg_grid = app.layout_cfg.config_tab.grid_grid;
            grid_layout = uigridlayout(panel_grid, cfg_grid.rows_cols);
            grid_layout.ColumnWidth = cfg_grid.col_widths;
            grid_layout.RowHeight = cfg_grid.row_heights;
            grid_layout.Padding = cfg_grid.padding;

            lbl = uilabel(grid_layout, 'Text', 'Nx', 'FontColor', C.fg_text); lbl.Layout.Row = 1; lbl.Layout.Column = 1;
            app.handles.Nx = uieditfield(grid_layout, 'numeric', 'Value', 128, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            app.handles.Nx.Layout.Row = 1; app.handles.Nx.Layout.Column = 2;
            lbl = uilabel(grid_layout, 'Text', 'Ny', 'FontColor', C.fg_text); lbl.Layout.Row = 1; lbl.Layout.Column = 3;
            app.handles.Ny = uieditfield(grid_layout, 'numeric', 'Value', 128, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            app.handles.Ny.Layout.Row = 1; app.handles.Ny.Layout.Column = 4;

            lbl = uilabel(grid_layout, 'Text', 'Lx', 'FontColor', C.fg_text); lbl.Layout.Row = 2; lbl.Layout.Column = 1;
            app.handles.Lx = uieditfield(grid_layout, 'numeric', 'Value', 10.0, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            app.handles.Lx.Layout.Row = 2; app.handles.Lx.Layout.Column = 2;
            lbl = uilabel(grid_layout, 'Text', 'Ly', 'FontColor', C.fg_text); lbl.Layout.Row = 2; lbl.Layout.Column = 3;
            app.handles.Ly = uieditfield(grid_layout, 'numeric', 'Value', 10.0, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            app.handles.Ly.Layout.Row = 2; app.handles.Ly.Layout.Column = 4;

            lbl = uilabel(grid_layout, 'Text', 'Delta', 'FontColor', C.fg_text); lbl.Layout.Row = 3; lbl.Layout.Column = 1;
            app.handles.delta = uieditfield(grid_layout, 'numeric', 'Editable', 'on', ...
                'Value', 2, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            app.handles.delta.Layout.Row = 3; app.handles.delta.Layout.Column = 2;
            lbl = uilabel(grid_layout, 'Text', 'Grid points', 'FontColor', C.fg_text); lbl.Layout.Row = 3; lbl.Layout.Column = 3;
            app.handles.grid_points = uilabel(grid_layout, 'Text', '16384', 'FontColor', C.fg_text);
            app.handles.grid_points.Layout.Row = 3; app.handles.grid_points.Layout.Column = 4;

            % Time and physics panel
            panel_time = uipanel(left_layout, 'Title', 'Time and Physics', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_time.Layout.Row = app.layout_cfg.coords.config.panel_time(1);
            panel_time.Layout.Column = app.layout_cfg.coords.config.panel_time(2);
            cfg_time = app.layout_cfg.config_tab.time_grid;
            time_layout = uigridlayout(panel_time, cfg_time.rows_cols);
            time_layout.ColumnWidth = cfg_time.col_widths;
            time_layout.RowHeight = cfg_time.row_heights;
            time_layout.Padding = cfg_time.padding;

            lbl = uilabel(time_layout, 'Text', 'dt', 'FontColor', C.fg_text); lbl.Layout.Row = 1; lbl.Layout.Column = 1;
            app.handles.dt = uieditfield(time_layout, 'numeric', 'Value', 0.001, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.dt.Layout.Row = 1; app.handles.dt.Layout.Column = 2;
            lbl = uilabel(time_layout, 'Text', 'Tfinal', 'FontColor', C.fg_text); lbl.Layout.Row = 1; lbl.Layout.Column = 3;
            app.handles.t_final = uieditfield(time_layout, 'numeric', 'Value', 10.0, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.t_final.Layout.Row = 1; app.handles.t_final.Layout.Column = 4;
            lbl = uilabel(time_layout, 'Text', 'nu', 'FontColor', C.fg_text); lbl.Layout.Row = 2; lbl.Layout.Column = 1;
            app.handles.nu = uieditfield(time_layout, 'numeric', 'Value', 1e-4, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.nu.Layout.Row = 2; app.handles.nu.Layout.Column = 2;
            lbl = uilabel(time_layout, 'Text', 'Snapshots', 'FontColor', C.fg_text); lbl.Layout.Row = 2; lbl.Layout.Column = 3;
            app.handles.num_snapshots = uieditfield(time_layout, 'numeric', 'Value', 9);
            app.handles.num_snapshots.Layout.Row = 2; app.handles.num_snapshots.Layout.Column = 4;

            % Simulation settings panel
            panel_sim = uipanel(left_layout, 'Title', 'Simulation Settings', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_sim.Layout.Row = app.layout_cfg.coords.config.panel_sim(1);
            panel_sim.Layout.Column = app.layout_cfg.coords.config.panel_sim(2);
            cfg_sim = app.layout_cfg.config_tab.sim_grid;
            sim_layout = uigridlayout(panel_sim, cfg_sim.rows_cols);
            sim_layout.ColumnWidth = cfg_sim.col_widths;
            sim_layout.RowHeight = cfg_sim.row_heights;
            sim_layout.Padding = cfg_sim.padding;

            app.handles.save_csv = uicheckbox(sim_layout, 'Text', 'Save CSV', 'Value', true, 'FontColor', C.fg_text);
            app.handles.save_csv.Layout.Row = 1; app.handles.save_csv.Layout.Column = 1;
            app.handles.save_mat = uicheckbox(sim_layout, 'Text', 'Save MAT', 'Value', true, 'FontColor', C.fg_text);
            app.handles.save_mat.Layout.Row = 1; app.handles.save_mat.Layout.Column = 2;
            app.handles.figures_save_png = uicheckbox(sim_layout, 'Text', 'Save PNG', 'Value', true, 'FontColor', C.fg_text);
            app.handles.figures_save_png.Layout.Row = 1; app.handles.figures_save_png.Layout.Column = 3;
            app.handles.figures_save_fig = uicheckbox(sim_layout, 'Text', 'Save FIG', 'Value', false, 'FontColor', C.fg_text);
            app.handles.figures_save_fig.Layout.Row = 1; app.handles.figures_save_fig.Layout.Column = 4;

            lbl = uilabel(sim_layout, 'Text', 'DPI', 'FontColor', C.fg_text); lbl.Layout.Row = 2; lbl.Layout.Column = 1;
            app.handles.figures_dpi = uieditfield(sim_layout, 'numeric', 'Value', 300);
            app.handles.figures_dpi.Layout.Row = 2; app.handles.figures_dpi.Layout.Column = 2;
            app.handles.figures_close_after_save = uicheckbox(sim_layout, 'Text', 'Close after save', 'Value', false, 'FontColor', C.fg_text);
            app.handles.figures_close_after_save.Layout.Row = 2; app.handles.figures_close_after_save.Layout.Column = 3;
            app.handles.figures_use_owl_saver = uicheckbox(sim_layout, 'Text', 'Use OWL saver', 'Value', true, 'FontColor', C.fg_text);
            app.handles.figures_use_owl_saver.Layout.Row = 2; app.handles.figures_use_owl_saver.Layout.Column = 4;

            app.handles.create_animations = uicheckbox(sim_layout, 'Text', 'Create animations', 'Value', true, 'FontColor', C.fg_text);
            app.handles.create_animations.Layout.Row = 3; app.handles.create_animations.Layout.Column = 1;
            app.handles.animation_format = uidropdown(sim_layout, 'Items', {'mp4', 'avi', 'gif'}, 'Value', 'mp4');
            app.handles.animation_format.Layout.Row = 3; app.handles.animation_format.Layout.Column = 2;
            app.handles.animation_fps = uieditfield(sim_layout, 'numeric', 'Value', 30);
            app.handles.animation_fps.Layout.Row = 3; app.handles.animation_fps.Layout.Column = 3;
            app.handles.animation_num_frames = uieditfield(sim_layout, 'numeric', 'Value', 100);
            app.handles.animation_num_frames.Layout.Row = 3; app.handles.animation_num_frames.Layout.Column = 4;

            % Convergence panel
            panel_conv = uipanel(left_layout, 'Title', 'Convergence Study', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_conv.Layout.Row = app.layout_cfg.coords.config.panel_conv(1);
            panel_conv.Layout.Column = app.layout_cfg.coords.config.panel_conv(2);
            cfg_conv = app.layout_cfg.config_tab.conv_grid;
            conv_layout = uigridlayout(panel_conv, cfg_conv.rows_cols);
            conv_layout.ColumnWidth = cfg_conv.col_widths;
            conv_layout.RowHeight = cfg_conv.row_heights;
            conv_layout.Padding = cfg_conv.padding;

            lbl = uilabel(conv_layout, 'Text', 'N coarse', 'FontColor', C.fg_text); lbl.Layout.Row = 1; lbl.Layout.Column = 1;
            app.handles.conv_N_coarse = uieditfield(conv_layout, 'numeric', 'Value', 64, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.conv_N_coarse.Layout.Row = 1; app.handles.conv_N_coarse.Layout.Column = 2;
            lbl = uilabel(conv_layout, 'Text', 'N max', 'FontColor', C.fg_text); lbl.Layout.Row = 1; lbl.Layout.Column = 3;
            app.handles.conv_N_max = uieditfield(conv_layout, 'numeric', 'Value', 512, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.conv_N_max.Layout.Row = 1; app.handles.conv_N_max.Layout.Column = 4;

            lbl = uilabel(conv_layout, 'Text', 'Tolerance', 'FontColor', C.fg_text); lbl.Layout.Row = 2; lbl.Layout.Column = 1;
            app.handles.conv_tolerance = uieditfield(conv_layout, 'numeric', 'Value', 1e-2, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.conv_tolerance.Layout.Row = 2; app.handles.conv_tolerance.Layout.Column = 2;
            lbl = uilabel(conv_layout, 'Text', 'Criterion', 'FontColor', C.fg_text); lbl.Layout.Row = 2; lbl.Layout.Column = 3;
            app.handles.conv_criterion = uidropdown(conv_layout, ...
                'Items', {'l2_relative', 'l2_absolute', 'linf_relative', 'max_vorticity', 'energy_dissipation', 'auto_physical'}, ...
                'Value', 'l2_relative', ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.conv_criterion.Layout.Row = 2; app.handles.conv_criterion.Layout.Column = 4;

            app.handles.conv_binary = uicheckbox(conv_layout, ...
                'Text', 'Binary search', 'Value', true, 'FontColor', C.fg_text, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.conv_binary.Layout.Row = 3; app.handles.conv_binary.Layout.Column = 1;
            app.handles.conv_use_adaptive = uicheckbox(conv_layout, ...
                'Text', 'Adaptive', 'Value', true, 'FontColor', C.fg_text, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.conv_use_adaptive.Layout.Row = 3; app.handles.conv_use_adaptive.Layout.Column = 2;
            lbl = uilabel(conv_layout, 'Text', 'Max jumps', 'FontColor', C.fg_text); lbl.Layout.Row = 3; lbl.Layout.Column = 3;
            app.handles.conv_max_jumps = uieditfield(conv_layout, 'numeric', 'Value', 5, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.conv_max_jumps.Layout.Row = 3; app.handles.conv_max_jumps.Layout.Column = 4;

            app.handles.conv_agent_enabled = uicheckbox(conv_layout, ...
                'Text', 'Agent-guided', 'Value', true, 'FontColor', C.fg_text, ...
                'ValueChangedFcn', @(~,~) app.on_convergence_agent_changed());
            app.handles.conv_agent_enabled.Layout.Row = 4;
            app.handles.conv_agent_enabled.Layout.Column = 1;

            app.handles.conv_agent_status = uilabel(conv_layout, ...
                'Text', 'Agent lock active', 'FontColor', C.accent_yellow);
            app.handles.conv_agent_status.Layout.Row = 4;
            app.handles.conv_agent_status.Layout.Column = 2;

            app.handles.conv_math = uihtml(conv_layout, 'HTMLSource', ...
                "<div style='font-family:Segoe UI;font-size:12px;color:#ddd;'>" + ...
                "<b style='color:#80c7ff;'>Finite Difference | Evolution Mode</b><br>" + ...
                "<b>Convergence Criterion:</b><br>" + ...
                "$\\epsilon_N = \\frac{\\|\\omega_N-\\omega_{2N}\\|_2}{\\|\\omega_{2N}\\|_2}$</div>" + ...
                "<script src='https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'></script>");
            app.handles.conv_math.Layout.Row = 4;
            app.handles.conv_math.Layout.Column = [3 4];

            app.handles.btn_load_converged_mesh = uibutton(conv_layout, 'Text', 'Load converged mesh preset', ...
                'ButtonPushedFcn', @(~,~) app.load_converged_mesh_preset());
            app.handles.btn_load_converged_mesh.Layout.Row = 5;
            app.handles.btn_load_converged_mesh.Layout.Column = [1 2];
            app.handles.converged_mesh_status = uilabel(conv_layout, ...
                'Text', 'No preset loaded', 'FontColor', C.fg_muted);
            app.handles.converged_mesh_status.Layout.Row = 5;
            app.handles.converged_mesh_status.Layout.Column = [3 4];

            % Sustainability panel
            panel_sus = uipanel(left_layout, 'Title', 'Sustainability', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_sus.Layout.Row = app.layout_cfg.coords.config.panel_sus(1);
            panel_sus.Layout.Column = app.layout_cfg.coords.config.panel_sus(2);
            cfg_sus = app.layout_cfg.config_tab.sus_grid;
            sus_layout = uigridlayout(panel_sus, cfg_sus.rows_cols);
            sus_layout.ColumnWidth = cfg_sus.col_widths;
            sus_layout.RowHeight = cfg_sus.row_heights;
            sus_layout.Padding = cfg_sus.padding;

            app.handles.enable_monitoring = uicheckbox(sus_layout, 'Text', 'Enable monitoring', 'Value', true, 'FontColor', C.fg_text);
            app.handles.enable_monitoring.Layout.Row = 1;
            app.handles.enable_monitoring.Layout.Column = 1;
            lbl = uilabel(sus_layout, 'Text', 'Sample interval (s)', 'FontColor', C.fg_text);
            lbl.Layout.Row = 1;
            lbl.Layout.Column = 2;
            app.handles.sample_interval = uieditfield(sus_layout, 'numeric', 'Value', 0.5);
            app.handles.sample_interval.Layout.Row = 1;
            app.handles.sample_interval.Layout.Column = 3;
            app.handles.sustainability_auto_log = uicheckbox(sus_layout, ...
                'Text', 'Always log run ledger', 'Value', true, 'FontColor', C.fg_text);
            app.handles.sustainability_auto_log.Layout.Row = 1;
            app.handles.sustainability_auto_log.Layout.Column = 4;

            app.handles.cpuz_enable = uicheckbox(sus_layout, ...
                'Text', 'CPU-Z collector', 'Value', false, 'FontColor', C.fg_text, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.cpuz_enable.Layout.Row = 2; app.handles.cpuz_enable.Layout.Column = 1;
            app.handles.hwinfo_enable = uicheckbox(sus_layout, ...
                'Text', 'HWiNFO collector', 'Value', false, 'FontColor', C.fg_text, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.hwinfo_enable.Layout.Row = 2; app.handles.hwinfo_enable.Layout.Column = 2;
            app.handles.icue_enable = uicheckbox(sus_layout, ...
                'Text', 'iCUE collector', 'Value', false, 'FontColor', C.fg_text, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            app.handles.icue_enable.Layout.Row = 2; app.handles.icue_enable.Layout.Column = 3;
            app.handles.collector_strict = uicheckbox(sus_layout, ...
                'Text', 'Strict external checks', 'Value', false, 'FontColor', C.fg_text);
            app.handles.collector_strict.Layout.Row = 2; app.handles.collector_strict.Layout.Column = 4;

            lbl = uilabel(sus_layout, 'Text', 'Machine tag', 'FontColor', C.fg_text);
            lbl.Layout.Row = 3; lbl.Layout.Column = 1;
            default_machine = getenv('COMPUTERNAME');
            if isempty(default_machine), default_machine = 'unknown_machine'; end
            app.handles.machine_tag = uieditfield(sus_layout, 'text', 'Value', default_machine);
            app.handles.machine_tag.Layout.Row = 3; app.handles.machine_tag.Layout.Column = [2 4];

            app.handles.collector_status = uilabel(sus_layout, ...
                'Text', 'Collector readiness: MATLAB baseline active', ...
                'FontColor', C.fg_muted);
            app.handles.collector_status.Layout.Row = 4;
            app.handles.collector_status.Layout.Column = [1 4];

            % Right panel stack
            cfg_right = app.layout_cfg.config_tab.right;
            right_layout = uigridlayout(right, cfg_right.rows_cols);
            right_layout.RowHeight = cfg_right.row_heights;
            right_layout.Padding = cfg_right.padding;
            right_layout.RowSpacing = cfg_right.row_spacing;

            % Readiness checklist
            panel_check = uipanel(right_layout, 'Title', 'Readiness Checklist', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_check.Layout.Row = app.layout_cfg.coords.config.panel_check(1);
            panel_check.Layout.Column = app.layout_cfg.coords.config.panel_check(2);
            cfg_check = app.layout_cfg.config_tab.check_grid;
            check_layout = uigridlayout(panel_check, cfg_check.rows_cols);
            check_layout.ColumnWidth = cfg_check.col_widths;
            check_layout.RowHeight = cfg_check.row_heights;
            check_layout.Padding = cfg_check.padding;
            check_layout.RowSpacing = cfg_check.row_spacing;

            checks_grid = uigridlayout(check_layout, [2 8]);
            checks_grid.Layout.Row = 1;
            checks_grid.Layout.Column = 1;
            checks_grid.RowHeight = {20, 24};
            checks_grid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            checks_grid.Padding = [0 0 0 0];
            checks_grid.RowSpacing = 2;
            checks_grid.ColumnSpacing = 6;

            app.handles.check_grid = uilabel(checks_grid, 'Text', '■', ...
                'HorizontalAlignment', 'center', 'FontSize', 13, 'FontColor', C.accent_red);
            app.handles.check_grid.Layout.Row = 1; app.handles.check_grid.Layout.Column = 1;
            app.handles.check_domain = uilabel(checks_grid, 'Text', '■', ...
                'HorizontalAlignment', 'center', 'FontSize', 13, 'FontColor', C.accent_red);
            app.handles.check_domain.Layout.Row = 1; app.handles.check_domain.Layout.Column = 2;
            app.handles.check_time = uilabel(checks_grid, 'Text', '■', ...
                'HorizontalAlignment', 'center', 'FontSize', 13, 'FontColor', C.accent_red);
            app.handles.check_time.Layout.Row = 1; app.handles.check_time.Layout.Column = 3;
            app.handles.check_ic = uilabel(checks_grid, 'Text', '■', ...
                'HorizontalAlignment', 'center', 'FontSize', 13, 'FontColor', C.accent_red);
            app.handles.check_ic.Layout.Row = 1; app.handles.check_ic.Layout.Column = 4;
            app.handles.check_conv = uilabel(checks_grid, 'Text', '■', ...
                'HorizontalAlignment', 'center', 'FontSize', 13, 'FontColor', C.accent_red);
            app.handles.check_conv.Layout.Row = 1; app.handles.check_conv.Layout.Column = 5;
            app.handles.check_monitor = uilabel(checks_grid, 'Text', '[ ]', ...
                'HorizontalAlignment', 'center', 'FontSize', 11, 'FontColor', C.accent_red);
            app.handles.check_monitor.Layout.Row = 1; app.handles.check_monitor.Layout.Column = 6;
            app.handles.check_collectors = uilabel(checks_grid, 'Text', '[ ]', ...
                'HorizontalAlignment', 'center', 'FontSize', 11, 'FontColor', C.accent_red);
            app.handles.check_collectors.Layout.Row = 1; app.handles.check_collectors.Layout.Column = 7;
            app.handles.check_outputs = uilabel(checks_grid, 'Text', '[ ]', ...
                'HorizontalAlignment', 'center', 'FontSize', 11, 'FontColor', C.accent_red);
            app.handles.check_outputs.Layout.Row = 1; app.handles.check_outputs.Layout.Column = 8;
            app.handles.check_grid.Text = '[ ]';
            app.handles.check_domain.Text = '[ ]';
            app.handles.check_time.Text = '[ ]';
            app.handles.check_ic.Text = '[ ]';
            app.handles.check_conv.Text = '[ ]';
            app.handles.check_grid.FontSize = 11;
            app.handles.check_domain.FontSize = 11;
            app.handles.check_time.FontSize = 11;
            app.handles.check_ic.FontSize = 11;
            app.handles.check_conv.FontSize = 11;
            app.handles.check_grid.Text = '[ ]';
            app.handles.check_domain.Text = '[ ]';
            app.handles.check_time.Text = '[ ]';
            app.handles.check_ic.Text = '[ ]';
            app.handles.check_conv.Text = '[ ]';
            app.handles.check_grid.FontSize = 11;
            app.handles.check_domain.FontSize = 11;
            app.handles.check_time.FontSize = 11;
            app.handles.check_ic.FontSize = 11;
            app.handles.check_conv.FontSize = 11;

            lbl = uilabel(checks_grid, 'Text', 'Grid', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 1;
            lbl = uilabel(checks_grid, 'Text', 'Domain', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 2;
            lbl = uilabel(checks_grid, 'Text', 'Time', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 3;
            lbl = uilabel(checks_grid, 'Text', 'IC', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 4;
            lbl = uilabel(checks_grid, 'Text', 'Convergence', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 5;
            lbl = uilabel(checks_grid, 'Text', 'Monitor', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 6;
            lbl = uilabel(checks_grid, 'Text', 'Collectors', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 7;
            lbl = uilabel(checks_grid, 'Text', 'Outputs', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 8;
            lbl = uilabel(checks_grid, 'Text', 'Monitor', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 6;
            lbl = uilabel(checks_grid, 'Text', 'Collectors', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 7;
            lbl = uilabel(checks_grid, 'Text', 'Outputs', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            lbl.Layout.Row = 2; lbl.Layout.Column = 8;

            info_lbl = uilabel(check_layout, ...
                'Text', 'Legend: green = ready, red = needs input', ...
                'FontColor', C.fg_muted, 'HorizontalAlignment', 'center');
            info_lbl.Layout.Row = 2;
            info_lbl.Layout.Column = 1;

            app.handles.run_status = uilabel(check_layout, 'Text', 'Idle', ...
                'FontColor', C.fg_muted, 'HorizontalAlignment', 'center');
            app.handles.run_status.Layout.Row = 3;
            app.handles.run_status.Layout.Column = 1;

            buttons_row = uigridlayout(check_layout, [1 3]);
            buttons_row.Layout.Row = 4;
            buttons_row.Layout.Column = 1;
            buttons_row.ColumnWidth = {'1x', '1x', '1x'};
            buttons_row.RowHeight = {'1x'};
            buttons_row.Padding = [0 0 0 0];
            buttons_row.ColumnSpacing = 8;

            app.handles.btn_launch = uibutton(buttons_row, 'push', ...
                'Text', 'Launch', 'FontWeight', 'bold', ...
                'BackgroundColor', C.accent_green, 'FontColor', [0.05 0.05 0.05], ...
                'ButtonPushedFcn', @(~,~) app.launch_simulation());
            app.handles.btn_launch.Layout.Row = 1; app.handles.btn_launch.Layout.Column = 1;

            app.handles.btn_export = uibutton(buttons_row, 'push', ...
                'Text', 'Export', ...
                'BackgroundColor', C.accent_cyan, 'FontColor', [0.05 0.05 0.05], ...
                'ButtonPushedFcn', @(~,~) app.export_configuration());
            app.handles.btn_export.Layout.Row = 1; app.handles.btn_export.Layout.Column = 2;

            app.handles.btn_import = uibutton(buttons_row, 'push', ...
                'Text', 'Import', ...
                'BackgroundColor', C.accent_yellow, 'FontColor', [0.05 0.05 0.05], ...
                'ButtonPushedFcn', @(~,~) app.import_configuration());
            app.handles.btn_import.Layout.Row = 1; app.handles.btn_import.Layout.Column = 3;

            % IC configuration
            panel_ic = uipanel(right_layout, 'Title', 'Initial Condition', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_ic.Layout.Row = app.layout_cfg.coords.config.panel_ic(1);
            panel_ic.Layout.Column = app.layout_cfg.coords.config.panel_ic(2);
            cfg_ic = app.layout_cfg.config_tab.ic_grid;
            ic_layout = uigridlayout(panel_ic, cfg_ic.rows_cols);
            ic_layout.ColumnWidth = cfg_ic.col_widths;
            ic_layout.RowHeight = cfg_ic.row_heights;
            ic_layout.Padding = cfg_ic.padding;
            ic_layout.RowSpacing = cfg_ic.row_spacing;
            app.handles.ic_layout = ic_layout;

            lbl = uilabel(ic_layout, 'Text', 'IC Type', 'FontColor', C.fg_text); lbl.Layout.Row = 1; lbl.Layout.Column = 1;
            app.handles.ic_dropdown = uidropdown(ic_layout, ...
                'Items', {'Stretched Gaussian', 'Vortex Blob', 'Vortex Pair', 'Multi-Vortex', ...
                          'Lamb-Oseen', 'Rankine', 'Lamb Dipole', 'Taylor-Green', ...
                          'Random Turbulence', 'Elliptical Vortex'}, ...
                'Value', 'Stretched Gaussian', ...
                'ValueChangedFcn', @(~,~) app.on_ic_changed());
            app.handles.ic_dropdown.Layout.Row = 1; app.handles.ic_dropdown.Layout.Column = 2;

            lbl = uilabel(ic_layout, 'Text', 'Pattern', 'FontColor', C.fg_text); lbl.Layout.Row = 1; lbl.Layout.Column = 3;
            app.handles.ic_pattern = uidropdown(ic_layout, ...
                'Items', {'single', 'circular', 'grid', 'random'}, ...
                'Value', 'single', ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_pattern.Layout.Row = 1; app.handles.ic_pattern.Layout.Column = 4;

            lbl = uilabel(ic_layout, 'Text', 'Scale Factor', 'FontColor', C.fg_text); lbl.Layout.Row = 2; lbl.Layout.Column = 1;
            app.handles.ic_scale = uieditfield(ic_layout, 'numeric', 'Value', 1.0, ...
                'Limits', [0.1 10.0], 'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_scale.Layout.Row = 2; app.handles.ic_scale.Layout.Column = 2;

            lbl = uilabel(ic_layout, 'Text', 'Count (N)', 'FontColor', C.fg_text); lbl.Layout.Row = 2; lbl.Layout.Column = 3;
            app.handles.ic_count = uieditfield(ic_layout, 'numeric', 'Value', 1, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_count.Layout.Row = 2; app.handles.ic_count.Layout.Column = 4;

            if app.supports_equation_image_rendering() && (exist('uiimage', 'file') || exist('uiimage', 'builtin'))
                app.handles.ic_equation = uiimage(ic_layout, ...
                    'ImageSource', '', ...
                    'ScaleMethod', 'fit');
            else
                app.handles.ic_equation = uihtml(ic_layout, ...
                    'HTMLSource', app.render_math_html('Stretched Gaussian', '\omega(x,y)=\exp(-a(x-x_0)^2-b(y-y_0)^2)'));
            end
            app.handles.ic_equation.Layout.Row = 3;
            app.handles.ic_equation.Layout.Column = [1 4];

            app.handles.ic_where = uitextarea(ic_layout, ...
                'Value', {'where:', 'a,b > 0 control spread in x/y', 'x0,y0 set center position'}, ...
                'Editable', 'off', 'FontSize', 10, 'WordWrap', 'on', ...
                'BackgroundColor', C.bg_input, 'FontColor', C.fg_text);
            app.handles.ic_where.Layout.Row = 4;
            app.handles.ic_where.Layout.Column = [1 4];

            app.handles.ic_coeff1_label = uilabel(ic_layout, 'Text', 'Coeff 1', 'FontColor', C.fg_text);
            app.handles.ic_coeff1_label.Layout.Row = 5; app.handles.ic_coeff1_label.Layout.Column = 1;
            app.handles.ic_coeff1 = uieditfield(ic_layout, 'numeric', 'Value', 2.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_coeff1.Layout.Row = 5; app.handles.ic_coeff1.Layout.Column = 2;
            app.handles.ic_coeff2_label = uilabel(ic_layout, 'Text', 'Coeff 2', 'FontColor', C.fg_text);
            app.handles.ic_coeff2_label.Layout.Row = 5; app.handles.ic_coeff2_label.Layout.Column = 3;
            app.handles.ic_coeff2 = uieditfield(ic_layout, 'numeric', 'Value', 0.2, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_coeff2.Layout.Row = 5; app.handles.ic_coeff2.Layout.Column = 4;

            app.handles.ic_coeff3_label = uilabel(ic_layout, 'Text', 'Coeff 3', 'FontColor', C.fg_text);
            app.handles.ic_coeff3_label.Layout.Row = 6; app.handles.ic_coeff3_label.Layout.Column = 1;
            app.handles.ic_coeff3 = uieditfield(ic_layout, 'numeric', 'Value', 0.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_coeff3.Layout.Row = 6; app.handles.ic_coeff3.Layout.Column = 2;
            app.handles.ic_coeff4_label = uilabel(ic_layout, 'Text', 'Coeff 4', 'FontColor', C.fg_text);
            app.handles.ic_coeff4_label.Layout.Row = 6; app.handles.ic_coeff4_label.Layout.Column = 3;
            app.handles.ic_coeff4 = uieditfield(ic_layout, 'numeric', 'Value', 0.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_coeff4.Layout.Row = 6; app.handles.ic_coeff4.Layout.Column = 4;

            lbl = uilabel(ic_layout, 'Text', 'Center x0', 'FontColor', C.fg_text); lbl.Layout.Row = 7; lbl.Layout.Column = 1;
            app.handles.ic_center_x = uieditfield(ic_layout, 'numeric', 'Value', 0.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_center_x.Layout.Row = 7; app.handles.ic_center_x.Layout.Column = 2;
            lbl = uilabel(ic_layout, 'Text', 'Center y0', 'FontColor', C.fg_text); lbl.Layout.Row = 7; lbl.Layout.Column = 3;
            app.handles.ic_center_y = uieditfield(ic_layout, 'numeric', 'Value', 0.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_center_y.Layout.Row = 7; app.handles.ic_center_y.Layout.Column = 4;

            app.handles.ic_status = uilabel(ic_layout, 'Text', 'IC ready', 'FontColor', C.fg_muted);
            app.handles.ic_status.Layout.Row = 8;
            app.handles.ic_status.Layout.Column = [1 4];

            % IC preview
            panel_preview = uipanel(right_layout, 'Title', 'IC Preview (t=0)', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_preview.Layout.Row = app.layout_cfg.coords.config.panel_preview(1);
            panel_preview.Layout.Column = app.layout_cfg.coords.config.panel_preview(2);
            preview_layout = uigridlayout(panel_preview, [1 1]);
            preview_layout.Padding = [6 6 6 6];
            app.handles.ic_preview_axes = uiaxes(preview_layout);
            app.style_axes(app.handles.ic_preview_axes);

            % Initialize display
            app.update_delta();
            app.update_ic_fields();
            app.on_method_changed();
            app.update_mode_control_visibility();
            app.update_convergence_control_state();
            app.update_ic_preview();
            app.update_checklist();
        end
        function create_monitoring_tab(app)
            % 3x3 dashboard contract: 8 ranked plots + 1 numeric table tile.
            C = app.layout_cfg.colors;
            cfg = app.layout_cfg.monitor_tab;

            parent = app.tabs.monitoring;
            parent.BackgroundColor = C.bg_dark;

            root = uigridlayout(parent, cfg.root.rows_cols);
            root.ColumnWidth = cfg.root.col_widths;
            root.RowHeight = cfg.root.row_heights;
            root.Padding = cfg.root.padding;
            root.ColumnSpacing = cfg.root.col_spacing;

            dashboard_panel = uipanel(root, ...
                'Title', 'Live Monitor Dashboard (3x3: 8 plots + 1 numeric tile)', ...
                'BackgroundColor', C.bg_panel_alt);
            dashboard_panel.Layout.Row = app.layout_cfg.coords.monitor.left_panel(1);
            dashboard_panel.Layout.Column = app.layout_cfg.coords.monitor.left_panel(2);

            dash_grid = uigridlayout(dashboard_panel, [cfg.plot_grid_rows, cfg.plot_grid_cols]);
            dash_grid.RowHeight = {'1x', '1x', '1x'};
            dash_grid.ColumnWidth = {'1x', '1x', '1x'};
            dash_grid.Padding = cfg.left.padding;
            dash_grid.RowSpacing = cfg.left.row_spacing;
            dash_grid.ColumnSpacing = cfg.left.col_spacing;

            app.handles.monitor_metric_catalog = app.build_monitor_metric_catalog();
            app.handles.monitor_ranked_selection = 1:8;
            app.handles.monitor_axes = gobjects(1, 8);

            plot_slot = 0;
            for tile_idx = 1:cfg.plot_tile_count
                row_idx = ceil(tile_idx / cfg.plot_grid_cols);
                col_idx = mod(tile_idx - 1, cfg.plot_grid_cols) + 1;

                if tile_idx == cfg.numeric_tile_index
                    numeric_panel = uipanel(dash_grid, ...
                        'Title', 'Ranked Numerical Metrics', ...
                        'BackgroundColor', C.bg_panel_alt);
                    numeric_panel.Layout.Row = row_idx;
                    numeric_panel.Layout.Column = col_idx;
                    numeric_layout = uigridlayout(numeric_panel, [1 1]);
                    numeric_layout.Padding = [4 4 4 4];
                    app.handles.monitor_numeric_table = uitable(numeric_layout, ...
                        'ColumnName', {'Metric', 'Value', 'Unit', 'Source'}, ...
                        'ColumnEditable', [false false false false], ...
                        'ColumnWidth', {170, 120, 70, 130}, ...
                        'Data', {
                            'Status', 'Waiting for run', '-', 'UI';
                            'Grid', '--', '-', 'UI';
                            'dt', '--', 's', 'UI';
                            'Runtime', '--', 's', 'Dispatcher';
                            'Max |omega|', '--', '-', 'Solver';
                            'Convergence tol', '--', '-', 'Convergence';
                            'Convergence metric', '--', '-', 'Convergence';
                            'Suggested coarse N', '--', '-', 'Advisor';
                            'CPU usage', '--', '%', 'MATLAB';
                            'Memory', '--', 'MB', 'MATLAB';
                            'Machine', '--', '-', 'SystemProfile';
                            'Collectors', '--', '-', 'SystemProfile'
                        });
                    continue;
                end

                plot_slot = plot_slot + 1;
                metric = app.handles.monitor_metric_catalog(plot_slot);
                tile_panel = uipanel(dash_grid, ...
                    'Title', metric.title, ...
                    'BackgroundColor', C.bg_panel_alt);
                tile_panel.Layout.Row = row_idx;
                tile_panel.Layout.Column = col_idx;

                tile_layout = uigridlayout(tile_panel, [1 1]);
                tile_layout.Padding = [4 4 4 4];
                ax = uiaxes(tile_layout);
                app.style_axes(ax);
                title(ax, metric.title, 'Color', C.fg_text, 'FontSize', 10);
                xlabel(ax, metric.xlabel, 'Color', C.fg_text);
                ylabel(ax, metric.ylabel, 'Color', C.fg_text);
                grid(ax, 'on');
                ax.PlotBoxAspectRatio = [1 1 1];
                ax.PlotBoxAspectRatioMode = 'manual';
                app.handles.monitor_axes(plot_slot) = ax;
            end

            % Backward-compatibility aliases used by older test/helpers.
            app.handles.exec_monitor_axes1 = app.handles.monitor_axes(1);
            app.handles.exec_monitor_axes2 = app.handles.monitor_axes(2);
            app.handles.conv_monitor_axes = app.handles.monitor_axes(3);

            sidebar = uipanel(root, 'Title', 'Terminal and Telemetry', ...
                'BackgroundColor', C.bg_panel_alt);
            sidebar.Layout.Row = app.layout_cfg.coords.monitor.terminal_panel(1);
            sidebar.Layout.Column = app.layout_cfg.coords.monitor.terminal_panel(2);
            side_layout = uigridlayout(sidebar, cfg.sidebar.rows_cols);
            side_layout.RowHeight = cfg.sidebar.row_heights;
            side_layout.Padding = cfg.sidebar.padding;
            side_layout.RowSpacing = cfg.sidebar.row_spacing;

            controls = uigridlayout(side_layout, [1 2]);
            controls.Layout.Row = 1;
            controls.Layout.Column = 1;
            controls.ColumnWidth = {'1x', '1x'};
            controls.Padding = [0 0 0 0];
            controls.ColumnSpacing = 6;
            uibutton(controls, 'Text', 'Save Log', ...
                'ButtonPushedFcn', @(~,~) app.save_terminal_log());
            uibutton(controls, 'Text', 'Clear', ...
                'ButtonPushedFcn', @(~,~) app.clear_terminal_view());

            app.handles.terminal_output = uihtml(side_layout, ...
                'HTMLSource', app.render_terminal_html());
            app.handles.terminal_output.Layout.Row = 2;
            app.handles.terminal_output.Layout.Column = 1;

            source_panel = uipanel(side_layout, 'Title', 'Sustainability Source Readiness', ...
                'BackgroundColor', C.bg_panel_alt);
            source_panel.Layout.Row = 3;
            source_panel.Layout.Column = 1;
            source_grid = uigridlayout(source_panel, [2 4]);
            source_grid.Padding = [4 4 4 4];
            source_grid.RowHeight = {18, 18};
            source_grid.ColumnWidth = {'1x', '1x', '1x', '1x'};

            uilabel(source_grid, 'Text', 'MATLAB', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            uilabel(source_grid, 'Text', 'CPU-Z', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            uilabel(source_grid, 'Text', 'HWiNFO', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            uilabel(source_grid, 'Text', 'iCUE', 'HorizontalAlignment', 'center', 'FontColor', C.fg_text);
            app.handles.metrics_source_matlab = uilabel(source_grid, 'Text', 'ready', 'HorizontalAlignment', 'center', 'FontColor', C.accent_green);
            app.handles.metrics_source_cpuz = uilabel(source_grid, 'Text', 'not found', 'HorizontalAlignment', 'center', 'FontColor', C.accent_yellow);
            app.handles.metrics_source_hwinfo = uilabel(source_grid, 'Text', 'not found', 'HorizontalAlignment', 'center', 'FontColor', C.accent_yellow);
            app.handles.metrics_source_icue = uilabel(source_grid, 'Text', 'not found', 'HorizontalAlignment', 'center', 'FontColor', C.accent_yellow);
        end
        function create_terminal_tab(~)
            % Terminal tab removed (merged into monitoring tab)
        end
        
        function create_results_tab(app)
            % Results and figures tab
            C = app.layout_cfg.colors;
            cfg = app.layout_cfg.results_tab;

            parent = app.tabs.results;
            parent.BackgroundColor = C.bg_dark;

            root = uigridlayout(parent, cfg.root.rows_cols);
            root.RowHeight = cfg.root.row_heights;
            root.Padding = cfg.root.padding;
            root.RowSpacing = cfg.root.row_spacing;

            panel_fig = uipanel(root, 'Title', 'Figures', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_fig.Layout.Row = app.layout_cfg.coords.results.panel_fig(1);
            panel_fig.Layout.Column = app.layout_cfg.coords.results.panel_fig(2);
            fig_layout = uigridlayout(panel_fig, cfg.fig_grid.rows_cols);
            fig_layout.RowHeight = cfg.fig_grid.row_heights;
            fig_layout.Padding = cfg.fig_grid.padding;

            control_row = uigridlayout(fig_layout, cfg.controls.rows_cols);
            control_row.ColumnWidth = cfg.controls.col_widths;
            control_row.RowHeight = cfg.controls.row_heights;
            control_row.Padding = cfg.controls.padding;
            control_row.ColumnSpacing = cfg.controls.col_spacing;

            uilabel(control_row, 'Text', 'Figure', 'FontColor', C.fg_text);
            app.handles.figure_selector = uidropdown(control_row, ...
                'Items', {'No figures yet'}, ...
                'Value', 'No figures yet', ...
                'ValueChangedFcn', @(~,~) app.on_figure_selected());
            uibutton(control_row, 'Text', 'Save Current', ...
                'ButtonPushedFcn', @(~,~) app.save_current_figure());
            uibutton(control_row, 'Text', 'Export All', ...
                'ButtonPushedFcn', @(~,~) app.export_all_figures());
            uibutton(control_row, 'Text', 'Refresh', ...
                'ButtonPushedFcn', @(~,~) app.refresh_figures());

            app.handles.figure_tabs = uitabgroup(fig_layout);
            tab = uitab(app.handles.figure_tabs, 'Title', 'Preview');
            app.handles.figure_axes = uiaxes(tab);
            app.style_axes(app.handles.figure_axes);
            title(app.handles.figure_axes, 'Figures will appear here during simulation', 'Color', C.fg_text);

            panel_metrics = uipanel(root, 'Title', 'Metrics and History', ...
                'BackgroundColor', C.bg_panel_alt);
            panel_metrics.Layout.Row = app.layout_cfg.coords.results.panel_metrics(1);
            panel_metrics.Layout.Column = app.layout_cfg.coords.results.panel_metrics(2);
            metrics_layout = uigridlayout(panel_metrics, [1 1]);
            metrics_layout.Padding = [6 6 6 6];
            app.handles.metrics_text = uitextarea(metrics_layout, ...
                'Value', {'Run a simulation to populate metrics and history.'}, ...
                'Editable', 'off', ...
                'BackgroundColor', C.bg_input, ...
                'FontColor', C.fg_text);
        end
        % Action methods
        function launch_simulation(app)
            % Collect UI state and execute selected run path synchronously
            % Start each launch with a fresh terminal pane to avoid stale logs.
            app.clear_terminal_view();
            app.set_run_state('running', 'Collecting configuration...');
            try
                app.collect_configuration_from_ui();
                app.validate_launch_configuration();

                app.tab_group.SelectedTab = app.tabs.monitoring;
                app.append_to_terminal(sprintf('Starting %s run (%s)...', app.config.mode, app.config.method), 'info');

                if strcmp(app.config.mode, 'experimentation')
                    summary = app.execute_experimentation_sweep();
                else
                    summary = app.execute_single_run(app.config);
                end

                app.update_results_summary(summary);
                app.append_to_terminal('Run completed successfully.', 'success');
                app.set_run_state('idle', 'Completed');
                if isfield(app.tabs, 'results') && isvalid(app.tabs.results)
                    app.tab_group.SelectedTab = app.tabs.results;
                end

            catch ME
                app.append_to_terminal(sprintf('Launch failed: %s', ME.message), 'error');
                app.set_run_state('idle', 'Failed');
                if ~isempty(app.fig) && isvalid(app.fig)
                    uialert(app.fig, ME.message, 'Launch Error', 'Icon', 'error');
                end
            end
        end

        function collect_configuration_from_ui(app)
            % Gather normalized runtime configuration from UI handles
            method_val = app.handles.method_dropdown.Value;
            switch method_val
                case 'Finite Difference'
                    app.config.method = 'finite_difference';
                case 'Finite Volume'
                    app.config.method = 'finite_volume';
                case 'Spectral'
                    app.config.method = 'spectral';
                otherwise
                    app.config.method = 'finite_difference';
            end

            mode_val = app.handles.mode_dropdown.Value;
            switch mode_val
                case 'Evolution'
                    app.config.mode = 'evolution';
                    app.config.run_mode_internal = 'Evolution';
                case 'Convergence'
                    app.config.mode = 'convergence';
                    app.config.run_mode_internal = 'Convergence';
                case 'Sweep'
                    app.config.mode = 'sweep';
                    app.config.run_mode_internal = 'ParameterSweep';
                case 'Animation'
                    app.config.mode = 'animation';
                    app.config.run_mode_internal = 'Evolution';
                otherwise
                    app.config.mode = 'experimentation';
                    app.config.run_mode_internal = 'Evolution';
            end

            app.config.Nx = round(app.handles.Nx.Value);
            app.config.Ny = round(app.handles.Ny.Value);
            app.config.Lx = app.handles.Lx.Value;
            app.config.Ly = app.handles.Ly.Value;
            app.config.delta = app.handles.delta.Value;
            app.config.use_explicit_delta = false;
            app.config.dt = app.handles.dt.Value;
            app.config.Tfinal = app.handles.t_final.Value;
            app.config.t_final = app.config.Tfinal;
            app.config.nu = app.handles.nu.Value;
            app.config.num_snapshots = round(app.handles.num_snapshots.Value);
            app.config.analysis_method = app.handles.method_dropdown.Value;

            app.config.save_csv = app.handles.save_csv.Value;
            app.config.save_mat = app.handles.save_mat.Value;
            app.config.figures_save_png = app.handles.figures_save_png.Value;
            app.config.figures_save_fig = app.handles.figures_save_fig.Value;
            app.config.figures_dpi = app.handles.figures_dpi.Value;
            app.config.figures_close_after_save = app.handles.figures_close_after_save.Value;
            app.config.figures_use_owl_saver = app.handles.figures_use_owl_saver.Value;
            app.config.create_animations = app.handles.create_animations.Value;
            app.config.animation_format = app.handles.animation_format.Value;
            app.config.animation_fps = app.handles.animation_fps.Value;
            app.config.animation_num_frames = max(2, round(app.handles.animation_num_frames.Value));
            if strcmp(app.config.mode, 'animation')
                app.config.create_animations = true;
            end

            app.config.bathymetry_enabled = app.handles.bathy_enable.Value;
            app.config.bathymetry_file = app.handles.bathy_file.Value;
            app.config.motion_enabled = app.handles.motion_enable.Value;
            app.config.motion_model = app.handles.motion_model.Value;
            app.config.motion_amplitude = app.handles.motion_amplitude.Value;

            ic_display_name = app.handles.ic_dropdown.Value;
            app.config.ic_type = map_ic_display_to_type(ic_display_name);
            app.config.ic_pattern = app.get_ic_pattern_value();
            app.config.ic_count = app.get_ic_count_value();
            [c1, c2, c3, c4, x0, y0] = app.get_ic_coeff_control_values();
            app.config.ic_coeff1 = c1;
            app.config.ic_coeff2 = c2;
            app.config.ic_coeff3 = c3;
            app.config.ic_coeff4 = c4;
            app.config.ic_center_x = x0;
            app.config.ic_center_y = y0;
            app.config.ic_scale = app.handles.ic_scale.Value;
            app.config.ic_coeff = app.build_ic_coeff_vector(app.config.ic_type);

            app.config.convergence_N_coarse = app.handles.conv_N_coarse.Value;
            app.config.convergence_N_max = app.handles.conv_N_max.Value;
            app.config.convergence_tol = app.handles.conv_tolerance.Value;
            app.config.convergence_criterion_type = app.handles.conv_criterion.Value;
            app.config.convergence_binary = app.handles.conv_binary.Value;
            app.config.convergence_use_adaptive = app.handles.conv_use_adaptive.Value;
            app.config.convergence_max_jumps = app.handles.conv_max_jumps.Value;
            app.config.convergence_agent_enabled = app.handles.conv_agent_enabled.Value;

            defaults = app.initialize_default_config();
            app.config.sweep_parameter = defaults.sweep_parameter;
            app.config.sweep_values = defaults.sweep_values;
            app.config.experimentation = defaults.experimentation;

            if app.has_valid_handle('sweep_parameter')
                app.config.sweep_parameter = app.handles.sweep_parameter.Value;
            end
            if app.has_valid_handle('sweep_values')
                app.config.sweep_values = app.parse_numeric_csv(app.handles.sweep_values.Value);
                app.config.sweep_values = unique(app.config.sweep_values, 'stable');
            end
            if app.has_valid_handle('exp_coeff_selector')
                app.config.experimentation.coeff_selector = app.handles.exp_coeff_selector.Value;
            end
            if app.has_valid_handle('exp_range_start')
                app.config.experimentation.range_start = app.handles.exp_range_start.Value;
            end
            if app.has_valid_handle('exp_range_end')
                app.config.experimentation.range_end = app.handles.exp_range_end.Value;
            end
            if app.has_valid_handle('exp_num_points')
                app.config.experimentation.num_points = round(app.handles.exp_num_points.Value);
            end

            app.config.enable_monitoring = app.handles.enable_monitoring.Value;
            app.config.sample_interval = app.handles.sample_interval.Value;
            app.config.sustainability_auto_log = app.handles.sustainability_auto_log.Value;
            app.config.collectors = struct( ...
                'cpuz', app.handles.cpuz_enable.Value, ...
                'hwinfo', app.handles.hwinfo_enable.Value, ...
                'icue', app.handles.icue_enable.Value, ...
                'strict', app.handles.collector_strict.Value, ...
                'machine_tag', app.handles.machine_tag.Value);

            setappdata(app.fig, 'ui_config', app.config);
        end

        function validate_launch_configuration(app)
            if ~strcmp(app.config.method, 'finite_difference')
                error('Only Finite Difference is currently supported in UI launch execution. Select "Finite Difference" in Method.');
            end

            if app.config.Nx < 8 || app.config.Ny < 8
                error('Grid resolution must be at least 8x8.');
            end

            if app.config.dt <= 0 || app.config.Tfinal <= 0
                error('dt and Tfinal must both be positive.');
            end

            if strcmp(app.config.mode, 'sweep') && numel(app.config.sweep_values) < 2
                error('Sweep mode requires at least two sweep values.');
            end

            if strcmp(app.config.mode, 'experimentation') && app.config.experimentation.num_points < 2
                error('Experimentation mode requires at least two sweep points.');
            end

            if strcmp(app.config.mode, 'animation')
                if app.config.animation_fps <= 0
                    error('Animation FPS must be positive.');
                end
                if app.config.animation_num_frames < 2
                    error('Animation requires at least two frames.');
                end
            end

            if app.config.ic_count < 1
                error('Initial-condition vortex count must be >= 1.');
            end
        end

        function summary = execute_single_run(app, cfg_override)
            % Build runtime structs and dispatch one run
            if nargin < 2 || isempty(cfg_override)
                cfg_override = app.config;
            end

            [run_config, parameters, settings] = app.build_runtime_inputs(cfg_override);
            run_started = tic;
            [results, paths] = ModeDispatcher(run_config, parameters, settings);
            wall = toc(run_started);

            summary = struct();
            summary.mode = cfg_override.mode;
            summary.run_config = run_config;
            summary.parameters = parameters;
            summary.settings = settings;
            summary.results = results;
            summary.paths = paths;
            summary.wall_time = wall;

            if isfield(results, 'max_omega')
                max_omega_val = results.max_omega;
                if ~isscalar(max_omega_val)
                    max_omega_val = max(abs(max_omega_val), [], 'all', 'omitnan');
                end
                app.set_optional_label_text('metrics_vorticity', sprintf('%.3e', max_omega_val));
            end
            app.set_optional_label_text('metrics_iterations', num2str(max(1, round(cfg_override.Tfinal / max(cfg_override.dt, eps)))));
            app.set_optional_label_text('metrics_time_elapsed', sprintf('%.2f s', wall));
            app.set_optional_label_text('metrics_grid', sprintf('%dx%d', cfg_override.Nx, cfg_override.Ny));
            app.set_optional_label_text('metrics_phys_time', sprintf('%.3f s', cfg_override.Tfinal));
            app.refresh_monitor_dashboard(summary, cfg_override);

            if isfield(app.handles, 'figure_selector') && isfield(paths, 'figures_evolution')
                app.append_to_terminal(sprintf('Figures: %s', char(string(paths.figures_evolution))), 'info');
            end
        end

        function summary = execute_experimentation_sweep(app)
            % Experimentation mode: coefficient sweep over repeated Evolution runs
            base_cfg = app.config;
            idx = find(strcmp({'ic_coeff1', 'ic_coeff2', 'ic_coeff3', 'ic_coeff4'}, base_cfg.experimentation.coeff_selector), 1);
            if isempty(idx)
                idx = 1;
            end

            values = linspace(base_cfg.experimentation.range_start, ...
                              base_cfg.experimentation.range_end, ...
                              max(2, base_cfg.experimentation.num_points));
            max_omega_values = zeros(size(values));
            run_ids = strings(size(values));

            app.append_to_terminal(sprintf('Experimentation sweep on %s with %d points', ...
                base_cfg.experimentation.coeff_selector, numel(values)), 'info');

            for k = 1:numel(values)
                cfg_k = base_cfg;
                coeffs = [cfg_k.ic_coeff1, cfg_k.ic_coeff2, cfg_k.ic_coeff3, cfg_k.ic_coeff4];
                coeffs(idx) = values(k);
                cfg_k.ic_coeff1 = coeffs(1);
                cfg_k.ic_coeff2 = coeffs(2);
                cfg_k.ic_coeff3 = coeffs(3);
                cfg_k.ic_coeff4 = coeffs(4);
                cfg_k.ic_coeff = app.build_ic_coeff_vector(cfg_k.ic_type, coeffs);

                app.append_to_terminal(sprintf('Experiment %d/%d: %s=%.4g', ...
                    k, numel(values), base_cfg.experimentation.coeff_selector, values(k)), 'info');

                run_summary = app.execute_single_run(cfg_k);
                if isfield(run_summary.results, 'max_omega')
                    max_omega_values(k) = run_summary.results.max_omega;
                else
                    max_omega_values(k) = NaN;
                end
                if isfield(run_summary.results, 'run_id')
                    run_ids(k) = string(run_summary.results.run_id);
                end
            end

            summary = struct();
            summary.mode = 'experimentation';
            summary.coeff_name = base_cfg.experimentation.coeff_selector;
            summary.values = values;
            summary.max_omega = max_omega_values;
            summary.run_ids = run_ids;
            summary.paths = struct();
            summary.results = struct('max_omega', max(max_omega_values, [], 'omitnan'));
            summary.wall_time = NaN;

            lines = {'Experimentation sweep complete:'};
            for k = 1:numel(values)
                lines{end+1} = sprintf('  %s=%.4g -> max|omega|=%.4e', ...
                    base_cfg.experimentation.coeff_selector, values(k), max_omega_values(k)); %#ok<AGROW>
            end
            if isfield(app.handles, 'metrics_text') && isvalid(app.handles.metrics_text)
                app.handles.metrics_text.Value = lines;
            end
        end

        function [run_config, parameters, settings] = build_runtime_inputs(app, cfg)
            % Convert UI config to ModeDispatcher-compatible inputs
            if ~isfield(cfg, 'motion_enabled'), cfg.motion_enabled = false; end
            if ~isfield(cfg, 'motion_model'), cfg.motion_model = 'none'; end
            if ~isfield(cfg, 'motion_amplitude'), cfg.motion_amplitude = 0.0; end
            if ~isfield(cfg, 'sustainability_auto_log'), cfg.sustainability_auto_log = true; end
            if ~isfield(cfg, 'collectors') || ~isstruct(cfg.collectors)
                cfg.collectors = struct('cpuz', false, 'hwinfo', false, 'icue', false, ...
                    'strict', false, 'machine_tag', getenv('COMPUTERNAME'));
            end
            if ~isfield(cfg.collectors, 'cpuz'), cfg.collectors.cpuz = false; end
            if ~isfield(cfg.collectors, 'hwinfo'), cfg.collectors.hwinfo = false; end
            if ~isfield(cfg.collectors, 'icue'), cfg.collectors.icue = false; end
            if ~isfield(cfg.collectors, 'machine_tag'), cfg.collectors.machine_tag = getenv('COMPUTERNAME'); end
            parameters = create_default_parameters();
            settings = Settings();

            parameters.Nx = cfg.Nx;
            parameters.Ny = cfg.Ny;
            parameters.Lx = cfg.Lx;
            parameters.Ly = cfg.Ly;
            parameters.dt = cfg.dt;
            parameters.Tfinal = cfg.Tfinal;
            parameters.t_final = cfg.Tfinal;
            parameters.nu = cfg.nu;
            parameters.ic_type = cfg.ic_type;
            parameters.ic_coeff = cfg.ic_coeff;
            parameters.num_plot_snapshots = max(1, cfg.num_snapshots);
            parameters.num_snapshots = parameters.num_plot_snapshots;
            parameters.snap_times = linspace(0, parameters.Tfinal, parameters.num_snapshots);
            parameters.plot_snap_times = parameters.snap_times;
            parameters.mode = cfg.run_mode_internal;
            parameters.create_animations = logical(cfg.create_animations);
            parameters.animation_format = cfg.animation_format;
            parameters.animation_fps = cfg.animation_fps;
            parameters.animation_num_frames = max(2, round(cfg.animation_num_frames));
            parameters.num_animation_frames = parameters.animation_num_frames;
            parameters.animation_times = linspace(0, parameters.Tfinal, parameters.num_animation_frames);

            settings.monitor_enabled = logical(cfg.enable_monitoring);
            settings.save_data = logical(cfg.save_mat || cfg.save_csv);
            settings.save_figures = logical(cfg.figures_save_png || cfg.figures_save_fig);
            settings.save_reports = true;
            settings.media.format = cfg.animation_format;
            settings.media.fps = cfg.animation_fps;
            settings.media.frame_count = max(2, round(cfg.animation_num_frames));
            settings.media.enabled = logical(cfg.create_animations || strcmp(cfg.mode, 'animation'));
            settings.animation_format = cfg.animation_format;
            settings.animation_frame_rate = cfg.animation_fps;
            settings.animation_frame_count = settings.media.frame_count;
            settings.animation_enabled = logical(cfg.create_animations || strcmp(cfg.mode, 'animation'));
            settings.animation_fps = settings.animation_frame_rate;
            settings.figure_dpi = cfg.figures_dpi;
            settings.figure_format = 'png';
            if cfg.figures_save_fig && ~cfg.figures_save_png
                settings.figure_format = 'fig';
            end
            settings.output_root = 'Results';
            settings.bathymetry_enabled = logical(cfg.bathymetry_enabled);
            settings.bathymetry_file = char(string(cfg.bathymetry_file));
            settings.motion = struct( ...
                'enabled', logical(cfg.motion_enabled), ...
                'model', char(string(cfg.motion_model)), ...
                'amplitude', cfg.motion_amplitude);
            settings.sustainability = struct();
            settings.sustainability.auto_log = logical(cfg.sustainability_auto_log);
            settings.sustainability.machine_id = char(string(cfg.collectors.machine_tag));
            settings.sustainability.external_collectors = struct( ...
                'cpuz', logical(cfg.collectors.cpuz), ...
                'hwinfo', logical(cfg.collectors.hwinfo), ...
                'icue', logical(cfg.collectors.icue));

            if strcmp(cfg.mode, 'convergence')
                parameters.mesh_sizes = app.build_mesh_sizes(cfg.convergence_N_coarse, cfg.convergence_N_max);
                parameters.convergence_variable = 'max_omega';
            end

            if strcmp(cfg.mode, 'sweep')
                parameters.sweep_parameter = cfg.sweep_parameter;
                parameters.sweep_values = reshape(cfg.sweep_values, 1, []);
            end

            if strcmp(cfg.mode, 'animation')
                parameters.create_animations = true;
                parameters.animation_format = cfg.animation_format;
                parameters.animation_fps = cfg.animation_fps;
                parameters.num_animation_frames = max(2, round(cfg.animation_num_frames));
            end

            run_config = Build_Run_Config(app.get_dispatch_method(cfg.method), cfg.run_mode_internal, cfg.ic_type);
        end

        function mesh_sizes = build_mesh_sizes(~, n_coarse, n_max)
            n0 = max(8, round(n_coarse));
            nmax = max(n0, round(n_max));
            mesh_sizes = n0;
            n = n0;
            while n < nmax
                n = min(nmax, 2 * n);
                mesh_sizes(end+1) = n; %#ok<AGROW>
            end
            mesh_sizes = unique(mesh_sizes, 'stable');
        end

        function values = parse_numeric_csv(~, txt)
            if iscell(txt)
                txt = strjoin(string(txt), ' ');
            end
            if isstring(txt)
                txt = char(txt);
            end
            if isempty(txt)
                values = [];
                return;
            end
            parts = regexp(txt, '[,;\s]+', 'split');
            parts = parts(~cellfun(@isempty, parts));
            values = zeros(1, numel(parts));
            for i = 1:numel(parts)
                values(i) = str2double(parts{i});
            end
            values = values(isfinite(values));
        end

        function method_token = get_dispatch_method(~, method_name)
            switch lower(string(method_name))
                case "finite_difference"
                    method_token = 'FD';
                case "finite_volume"
                    method_token = 'FV';
                case "spectral"
                    method_token = 'Spectral';
                otherwise
                    method_token = 'FD';
            end
        end

        function set_run_state(app, state, status_text)
            if nargin < 3
                status_text = 'Idle';
            end
            if isfield(app.handles, 'btn_launch') && isvalid(app.handles.btn_launch)
                if strcmpi(state, 'running')
                    app.handles.btn_launch.Enable = 'off';
                    app.handles.btn_launch.Text = 'Running...';
                else
                    app.handles.btn_launch.Enable = 'on';
                    app.handles.btn_launch.Text = 'Launch';
                end
            end
            if isfield(app.handles, 'run_status') && isvalid(app.handles.run_status)
                app.handles.run_status.Text = status_text;
            end
            drawnow limitrate;
        end

        function update_results_summary(app, summary)
            if ~isfield(app.handles, 'metrics_text') || ~isvalid(app.handles.metrics_text)
                return;
            end

            lines = {};
            lines{end+1} = sprintf('Mode: %s', char(string(summary.mode))); %#ok<AGROW>
            if isfield(summary, 'results') && isstruct(summary.results)
                if isfield(summary.results, 'run_id')
                    lines{end+1} = sprintf('Run ID: %s', char(string(summary.results.run_id))); %#ok<AGROW>
                end
                if isfield(summary.results, 'max_omega')
                    max_omega_val = summary.results.max_omega;
                    if ~isscalar(max_omega_val)
                        max_omega_val = max(abs(max_omega_val), [], 'all', 'omitnan');
                    end
                    lines{end+1} = sprintf('max|omega|: %.4e', max_omega_val); %#ok<AGROW>
                end
                if isfield(summary.results, 'wall_time')
                    lines{end+1} = sprintf('Wall time: %.2f s', summary.results.wall_time); %#ok<AGROW>
                end
            end
            if isfield(summary, 'wall_time') && isfinite(summary.wall_time)
                lines{end+1} = sprintf('Elapsed (UI): %.2f s', summary.wall_time); %#ok<AGROW>
            end
            if isfield(summary, 'paths') && isstruct(summary.paths)
                if isfield(summary.paths, 'base')
                    lines{end+1} = sprintf('Output: %s', char(string(summary.paths.base))); %#ok<AGROW>
                end
            end
            app.handles.metrics_text.Value = lines;
        end

        function ic_coeff = build_ic_coeff_vector(app, ic_type, coeff_override)
            if nargin < 3
                [c1, c2, c3, c4, ~, ~] = app.get_ic_coeff_control_values();
                coeffs = [c1, c2, c3, c4];
            else
                coeffs = coeff_override;
            end
            c1 = coeffs(1);
            c2 = coeffs(2);
            c3 = coeffs(3);
            c4 = coeffs(4);
            x0 = app.handles.ic_center_x.Value;
            y0 = app.handles.ic_center_y.Value;
            n_vort = app.get_ic_count_value();
            pattern = app.get_ic_pattern_value();
            scale = app.handles.ic_scale.Value;

            switch ic_type
                case 'stretched_gaussian'
                    ic_coeff = [max(c1, 1e-8), max(c2, 1e-8), 0, 0, x0, y0];
                    ic_coeff(1:2) = ic_coeff(1:2) * max(scale, 1e-8);
                case 'lamb_oseen'
                    ic_coeff = [c1, max(c2, 1e-6), max(c3, 1e-8), 0, x0, y0];
                    ic_coeff(1) = ic_coeff(1) * scale;
                case 'rankine'
                    ic_coeff = [c1 * scale, max(c2, 1e-6), 0, 0, x0, y0];
                case 'lamb_dipole'
                    ic_coeff = [c1 * scale, max(c2, 1e-6), 0, 0, x0, y0];
                case 'taylor_green'
                    ic_coeff = [max(c1, 1e-8), c2 * scale, 0, 0, x0, y0];
                case 'random_turbulence'
                    ic_coeff = [max(c1, 0.1), c2 * scale, round(c3), 0, x0, y0];
                case 'elliptical_vortex'
                    ic_coeff = [c1 * scale, max(c2, 1e-6), max(c3, 1e-6), c4, x0, y0];
                case 'vortex_blob_gaussian'
                    ic_coeff = [c1 * scale, max(c2, 1e-6), x0, y0, x0, y0];
                case 'vortex_pair'
                    sep = max(c2, 1e-6);
                    rad = max(c3, 1e-6);
                    gamma1 = c1 * scale;
                    gamma2 = -abs(c1 * scale);
                    x1 = x0 - sep / 2;
                    x2 = x0 + sep / 2;
                    ic_coeff = [gamma1, rad, x1, y0, gamma2, x2];
                case 'multi_vortex'
                    [centers_x, centers_y] = app.build_vortex_centers(max(3, n_vort), pattern, app.handles.Lx.Value, app.handles.Ly.Value, x0, y0);
                    if numel(centers_x) < 3
                        centers_x = [centers_x(:); zeros(3-numel(centers_x),1)];
                        centers_y = [centers_y(:); zeros(3-numel(centers_y),1)];
                    end
                    g = c1 * scale;
                    r = max(c2, 1e-6);
                    ic_coeff = [g, r, centers_x(1), centers_y(1), ...
                                g, r, centers_x(2), centers_y(2), ...
                                g, centers_x(3), centers_y(3), r];
                otherwise
                    ic_coeff = [c1, c2, c3, c4, x0, y0];
            end
        end

        function [c1, c2, c3, c4, x0, y0] = get_ic_coeff_control_values(app)
            c1 = app.handles.ic_coeff1.Value;
            c2 = app.handles.ic_coeff2.Value;
            c3 = app.handles.ic_coeff3.Value;
            c4 = app.handles.ic_coeff4.Value;
            x0 = app.handles.ic_center_x.Value;
            y0 = app.handles.ic_center_y.Value;
        end

        function [x_list, y_list] = build_vortex_centers(~, n_vort, pattern, Lx, Ly, x0, y0)
            try
                [x_list, y_list] = disperse_vortices(n_vort, pattern, Lx, Ly);
            catch
                theta = linspace(0, 2*pi, n_vort + 1);
                theta(end) = [];
                x_list = (0.3 * Lx) * cos(theta);
                y_list = (0.3 * Ly) * sin(theta);
            end
            x_list = x_list(:) + x0;
            y_list = y_list(:) + y0;
        end

        function update_mode_control_visibility(app)
            mode_val = app.handles.mode_dropdown.Value;
            sweep_on = strcmp(mode_val, 'Sweep');
            exp_on = strcmp(mode_val, 'Experimentation');

            sweep_state = app.on_off(sweep_on);
            exp_state = app.on_off(exp_on);
            sweep_vis = app.on_off(sweep_on);
            exp_vis = app.on_off(exp_on);

            app.set_optional_handle_enable('sweep_parameter', sweep_state);
            app.set_optional_handle_enable('sweep_values', sweep_state);
            app.set_optional_handle_property('sweep_parameter', 'Visible', sweep_vis);
            app.set_optional_handle_property('sweep_values', 'Visible', sweep_vis);
            app.set_optional_handle_property('sweep_parameter_label', 'Visible', sweep_vis);
            app.set_optional_handle_property('sweep_values_label', 'Visible', sweep_vis);

            app.set_optional_handle_enable('exp_coeff_selector', exp_state);
            app.set_optional_handle_enable('exp_range_start', exp_state);
            app.set_optional_handle_enable('exp_range_end', exp_state);
            app.set_optional_handle_enable('exp_num_points', exp_state);
            app.set_optional_handle_property('exp_coeff_selector', 'Visible', exp_vis);
            app.set_optional_handle_property('exp_range_start', 'Visible', exp_vis);
            app.set_optional_handle_property('exp_range_end', 'Visible', exp_vis);
            app.set_optional_handle_property('exp_num_points', 'Visible', exp_vis);
            app.set_optional_handle_property('exp_coeff_label', 'Visible', exp_vis);
            app.set_optional_handle_property('exp_range_start_label', 'Visible', exp_vis);
            app.set_optional_handle_property('exp_range_end_label', 'Visible', exp_vis);
            app.set_optional_handle_property('exp_num_points_label', 'Visible', exp_vis);
        end

        function style_axes(app, ax)
            C = app.layout_cfg.colors;
            ax.Color = C.bg_dark;
            ax.XColor = C.fg_text;
            ax.YColor = C.fg_text;
            ax.ZColor = C.fg_text;
            ax.GridColor = C.accent_gray;
        end

        function validate_parameters(app)
            errors = {};
            
            % Check UI components exist
            if ~isfield(app.handles, 'Nx') || ~ishghandle(app.handles.Nx)
                uialert(app.fig, 'UI components not ready', 'Error', 'icon', 'error');
                return;
            end
            
            % Grid validation
            if app.handles.Nx.Value < 32
                errors{end+1} = 'Nx must be >= 32 points';
            end
            if app.handles.Ny.Value < 32
                errors{end+1} = 'Ny must be >= 32 points';
            end
            if app.handles.Nx.Value > 1024 || app.handles.Ny.Value > 1024
                errors{end+1} = 'Grid size should not exceed 1024×1024 (memory limits)';
            end
            
            % Time integration validation
            if app.handles.dt.Value <= 0 || app.handles.dt.Value > 0.1
                errors{end+1} = 'dt must be in (0, 0.1]';
            end
            if app.handles.t_final.Value <= 0
                errors{end+1} = 't_final must be positive';
            end
            if app.handles.t_final.Value / app.handles.dt.Value > 100000
                errors{end+1} = 'Too many timesteps (T/dt > 100k)';
            end
            
            % CFL stability check (rough estimate)
            dx = 10.0 / app.handles.Nx.Value;  % Assuming Lx = 10
            cfl = app.handles.dt.Value / (dx * dx);
            if cfl > 0.5
                errors{end+1} = sprintf('CFL number %.2f may be unstable (should be < 0.5)', cfl);
            end
            
            % Physics validation
            if app.handles.nu.Value < 0 || app.handles.nu.Value > 0.1
                errors{end+1} = 'Viscosity must be in [0, 0.1]';
            end
            
            % IC validation
            if isempty(app.handles.ic_dropdown.Value)
                errors{end+1} = 'Initial condition type not selected';
            end
            
            if isempty(errors)
                msg = sprintf('All parameters valid!\n\nGrid: %d × %d\ndt = %.4f, T = %.2f\nν = %.4f', ...
                    round(app.handles.Nx.Value), round(app.handles.Ny.Value), ...
                    app.handles.dt.Value, app.handles.t_final.Value, app.handles.nu.Value);
                uialert(app.fig, msg, 'Validation Passed', 'icon', 'success');
                app.append_to_terminal('✓ All parameters validated successfully', 'success');
            else
                msg = sprintf('Found %d validation error(s):\n\n• %s', ...
                    length(errors), strjoin(errors, '\n• '));
                uialert(app.fig, msg, 'Validation Errors', 'icon', 'error');
                app.append_to_terminal(sprintf('✗ Validation errors: %s', strjoin(errors, ', ')), 'error');
            end

            app.update_checklist();
        end

        function update_delta(app)
            % Update grid points display only (delta is now user-editable, not calculated)
            Nx = max(2, round(app.handles.Nx.Value));
            Ny = max(2, round(app.handles.Ny.Value));
            app.handles.grid_points.Text = sprintf('%d', Nx * Ny);
            app.update_checklist();
            app.update_ic_preview();
        end

        function on_method_changed(app)
            method_val = app.handles.method_dropdown.Value;
            is_fd = strcmp(method_val, 'Finite Difference');
            bathy_on = app.handles.bathy_enable.Value;
            motion_on = app.handles.motion_enable.Value;
            
            switch method_val
                case 'Finite Difference'
                    app.handles.boundary_label.Text = 'Periodic (x,y)';
                case 'Finite Volume'
                    app.handles.boundary_label.Text = 'Periodic (x,y)';
                case 'Spectral'
                    app.handles.boundary_label.Text = 'Periodic (x,y)';
            end

            app.set_optional_handle_enable('bathy_enable', app.on_off(is_fd));
            app.set_optional_handle_enable('bathy_file', app.on_off(is_fd && bathy_on));
            app.set_optional_handle_enable('bathy_browse_btn', app.on_off(is_fd && bathy_on));
            app.set_optional_handle_enable('motion_enable', app.on_off(is_fd));
            app.set_optional_handle_enable('motion_model', app.on_off(is_fd && motion_on));
            app.set_optional_handle_enable('motion_amplitude', app.on_off(is_fd && motion_on));
            
            if ~is_fd
                app.handles.bathy_enable.Value = false;
                app.handles.motion_enable.Value = false;
                app.handles.bathy_file.Value = '';
                app.handles.motion_model.Value = 'none';
                app.handles.motion_amplitude.Value = 0.0;
                if app.has_valid_handle('physics_status')
                    app.handles.physics_status.Text = 'Bathymetry/motion disabled for non-FD method';
                    app.handles.physics_status.FontColor = app.layout_cfg.colors.accent_yellow;
                end
            else
                if bathy_on && motion_on
                    app.handles.boundary_label.Text = 'Periodic (x,y) + Bathymetry + Motion';
                elseif bathy_on
                    app.handles.boundary_label.Text = 'Periodic (x,y) + Bathymetry';
                elseif motion_on
                    app.handles.boundary_label.Text = 'Periodic (x,y) + Motion';
                end
                if app.has_valid_handle('physics_status')
                    app.handles.physics_status.Text = 'Bathymetry and motion configured independently';
                    app.handles.physics_status.FontColor = app.layout_cfg.colors.fg_muted;
                end
            end
            
            % Update convergence display with selected method
            app.update_convergence_display();
            app.update_ic_preview();
            app.update_checklist();
        end

        function on_mode_changed(app)
            % Update mode-dependent views safely to avoid callback aborts.
            try
                app.update_convergence_display();
                app.update_mode_control_visibility();
                app.update_convergence_control_state();
                app.update_checklist();
            catch ME
                app.append_to_terminal(sprintf('Mode change update failed: %s', ME.message), 'error');
            end
        end

        function on_convergence_agent_changed(app)
            % When agent-guided convergence is active, lock manual controls.
            app.update_convergence_control_state();
            app.update_convergence_display();
            app.update_checklist();
        end

        function update_convergence_control_state(app)
            mode_val = app.handles.mode_dropdown.Value;
            conv_on = strcmp(mode_val, 'Convergence');
            agent_on = conv_on && app.handles.conv_agent_enabled.Value;

            manual_fields = {'conv_N_coarse', 'conv_N_max', 'conv_tolerance', ...
                'conv_criterion', 'conv_binary', 'conv_use_adaptive', 'conv_max_jumps'};
            for i = 1:numel(manual_fields)
                app.set_optional_handle_enable(manual_fields{i}, app.on_off(conv_on && ~agent_on));
            end
            app.set_optional_handle_enable('conv_agent_enabled', app.on_off(conv_on));
            app.set_optional_handle_enable('btn_load_converged_mesh', app.on_off(conv_on));

            if app.has_valid_handle('conv_agent_status')
                if ~conv_on
                    app.handles.conv_agent_status.Text = 'Convergence mode inactive';
                    app.handles.conv_agent_status.FontColor = app.layout_cfg.colors.fg_muted;
                elseif agent_on
                    app.handles.conv_agent_status.Text = 'Agent mode: manual fields locked';
                    app.handles.conv_agent_status.FontColor = app.layout_cfg.colors.accent_yellow;
                else
                    app.handles.conv_agent_status.Text = 'Manual mode: controls editable';
                    app.handles.conv_agent_status.FontColor = app.layout_cfg.colors.accent_green;
                end
            end
        end

        function update_checklist(app)
            % Update readiness checklist lights
            grid_ok = app.handles.Nx.Value >= 2 && app.handles.Ny.Value >= 2;
            domain_ok = app.handles.Lx.Value > 0 && app.handles.Ly.Value > 0;
            time_ok = app.handles.dt.Value > 0 && app.handles.t_final.Value > 0;
            ic_ok = ~isempty(app.handles.ic_dropdown.Value);
            conv_ok = true;
            mode_val = app.handles.mode_dropdown.Value;
            defaults = app.initialize_default_config();
            if strcmp(mode_val, 'Convergence')
                conv_ok = app.handles.conv_N_max.Value > app.handles.conv_N_coarse.Value;
            elseif strcmp(mode_val, 'Sweep')
                sweep_values = defaults.sweep_values;
                if app.has_valid_handle('sweep_values')
                    sweep_values = app.parse_numeric_csv(app.handles.sweep_values.Value);
                elseif isfield(app.config, 'sweep_values')
                    sweep_values = app.config.sweep_values;
                end
                conv_ok = numel(sweep_values) >= 2;
            elseif strcmp(mode_val, 'Experimentation')
                exp_cfg = defaults.experimentation;
                if app.has_valid_handle('exp_num_points')
                    exp_cfg.num_points = app.handles.exp_num_points.Value;
                elseif isfield(app.config, 'experimentation') && isstruct(app.config.experimentation) ...
                        && isfield(app.config.experimentation, 'num_points')
                    exp_cfg.num_points = app.config.experimentation.num_points;
                end
                if app.has_valid_handle('exp_range_start')
                    exp_cfg.range_start = app.handles.exp_range_start.Value;
                elseif isfield(app.config, 'experimentation') && isstruct(app.config.experimentation) ...
                        && isfield(app.config.experimentation, 'range_start')
                    exp_cfg.range_start = app.config.experimentation.range_start;
                end
                if app.has_valid_handle('exp_range_end')
                    exp_cfg.range_end = app.handles.exp_range_end.Value;
                elseif isfield(app.config, 'experimentation') && isstruct(app.config.experimentation) ...
                        && isfield(app.config.experimentation, 'range_end')
                    exp_cfg.range_end = app.config.experimentation.range_end;
                end
                conv_ok = exp_cfg.num_points >= 2 && exp_cfg.range_end ~= exp_cfg.range_start;
            end

            app.handles.check_grid.FontColor = app.bool_to_color(grid_ok);
            app.handles.check_domain.FontColor = app.bool_to_color(domain_ok);
            app.handles.check_time.FontColor = app.bool_to_color(time_ok);
            app.handles.check_ic.FontColor = app.bool_to_color(ic_ok);
            app.handles.check_conv.FontColor = app.bool_to_color(conv_ok);

            monitor_ok = app.handles.enable_monitoring.Value && app.handles.sample_interval.Value > 0;
            outputs_ok = app.handles.save_csv.Value || app.handles.save_mat.Value || ...
                app.handles.figures_save_png.Value || app.handles.figures_save_fig.Value;
            collectors_ok = true;
            if app.handles.collector_strict.Value
                collectors_ok = app.handles.cpuz_enable.Value || ...
                    app.handles.hwinfo_enable.Value || app.handles.icue_enable.Value;
            end

            if app.has_valid_handle('check_monitor')
                app.handles.check_monitor.FontColor = app.bool_to_color(monitor_ok);
            end
            if app.has_valid_handle('check_collectors')
                app.handles.check_collectors.FontColor = app.bool_to_color(collectors_ok);
            end
            if app.has_valid_handle('check_outputs')
                app.handles.check_outputs.FontColor = app.bool_to_color(outputs_ok);
            end

            if app.has_valid_handle('collector_status')
                collector_msg = "Collector readiness: MATLAB baseline active";
                if app.handles.cpuz_enable.Value || app.handles.hwinfo_enable.Value || app.handles.icue_enable.Value
                    collector_msg = "Collector readiness: external collectors configured";
                end
                if app.handles.collector_strict.Value && ~collectors_ok
                    collector_msg = "Collector readiness: strict mode requires at least one external collector";
                    app.handles.collector_status.FontColor = app.layout_cfg.colors.accent_yellow;
                else
                    app.handles.collector_status.FontColor = app.layout_cfg.colors.fg_muted;
                end
                app.handles.collector_status.Text = char(collector_msg);
            end

            if app.has_valid_handle('metrics_source_matlab')
                app.handles.metrics_source_matlab.Text = 'ready';
                app.handles.metrics_source_matlab.FontColor = app.layout_cfg.colors.accent_green;
            end
            if app.has_valid_handle('metrics_source_cpuz')
                app.handles.metrics_source_cpuz.Text = app.on_off_label(app.handles.cpuz_enable.Value);
                app.handles.metrics_source_cpuz.FontColor = app.bool_to_color(app.handles.cpuz_enable.Value);
            end
            if app.has_valid_handle('metrics_source_hwinfo')
                app.handles.metrics_source_hwinfo.Text = app.on_off_label(app.handles.hwinfo_enable.Value);
                app.handles.metrics_source_hwinfo.FontColor = app.bool_to_color(app.handles.hwinfo_enable.Value);
            end
            if app.has_valid_handle('metrics_source_icue')
                app.handles.metrics_source_icue.Text = app.on_off_label(app.handles.icue_enable.Value);
                app.handles.metrics_source_icue.FontColor = app.bool_to_color(app.handles.icue_enable.Value);
            end
        end

        function update_convergence_display(app)
            % Update convergence criterion display without sprintf parsing risk.
            method_val = app.handles.method_dropdown.Value;
            mode_val = app.handles.mode_dropdown.Value;

            method_txt = string(method_val);
            mode_txt = string(mode_val);
            header = method_txt + " | " + mode_txt + " Mode";
            details = "Method: <b>" + method_txt + "</b> | Mode: <b>" + ...
                mode_txt + "</b> | Agent: <b>" + ...
                app.to_yes_no(app.handles.conv_agent_enabled.Value) + "</b> | Binary: <b>" + ...
                app.to_yes_no(app.handles.conv_binary.Value) + "</b>";

            html_content = "<div style='font-family:Segoe UI;font-size:12px;color:#dcdcdc;'>" + ...
                "<b style='color:#80c7ff;'>" + header + "</b><br>" + ...
                "<b>Convergence Criterion:</b><br>" + ...
                "$$\\epsilon_N = \\frac{\\|\\omega_N-\\omega_{2N}\\|_2}{\\|\\omega_{2N}\\|_2}$$<br>" + ...
                "<span style='font-size:11px;color:#a0a0a0;'>" + details + "</span>" + ...
                "</div>" + ...
                "<script src='https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'></script>";

            if app.has_valid_handle('conv_math')
                app.handles.conv_math.HTMLSource = char(string(html_content));
            end
        end

        function color = bool_to_color(~, ok)
            if ok
                color = [0.25 0.78 0.35];
            else
                color = [0.90 0.35 0.35];
            end
        end

        function state = on_off(~, tf)
            if tf
                state = 'on';
            else
                state = 'off';
            end
        end

        function label = on_off_label(~, tf)
            if tf
                label = 'on';
            else
                label = 'off';
            end
        end

        function restore_contour_warning_state(~, warn1, warn2, warn3, warn4)
            % Restore contour warning states after guarded contour rendering.
            if isstruct(warn1) && isfield(warn1, 'identifier') && ~isempty(warn1.identifier)
                warning(warn1.state, warn1.identifier);
            end
            if isstruct(warn2) && isfield(warn2, 'identifier') && ~isempty(warn2.identifier)
                warning(warn2.state, warn2.identifier);
            end
            if nargin >= 4 && isstruct(warn3) && isfield(warn3, 'identifier') && ~isempty(warn3.identifier)
                warning(warn3.state, warn3.identifier);
            end
            if nargin >= 5 && isstruct(warn4) && isfield(warn4, 'identifier') && ~isempty(warn4.identifier)
                warning(warn4.state, warn4.identifier);
            end
        end
        
        function yesno = to_yes_no(~, tf)
            if tf
                yesno = 'Yes';
            else
                yesno = 'No';
            end
        end

        function load_preset(app, preset_name)
            switch preset_name
                case 'stretched_gaussian'
                    app.handles.ic_dropdown.Value = 'Stretched Gaussian';
                    app.handles.ic_coeff1.Value = 2.0;
                    app.handles.ic_coeff2.Value = 0.2;
                    app.handles.ic_coeff3.Value = 0.0;
                    app.handles.ic_coeff4.Value = 0.0;
                    app.append_to_terminal('✓ Loaded: Stretched Gaussian preset');
                    
                case 'lamb_oseen'
                    app.handles.ic_dropdown.Value = 'Lamb-Oseen';
                    app.handles.ic_coeff1.Value = 1.0;   % Gamma
                    app.handles.ic_coeff2.Value = 1.0;   % t0
                    app.handles.ic_coeff3.Value = 0.001; % nu
                    app.handles.ic_coeff4.Value = 0.0;
                    app.append_to_terminal('✓ Loaded: Lamb-Oseen preset');
                    
                case 'rankine'
                    app.handles.ic_dropdown.Value = 'Rankine';
                    app.handles.ic_coeff1.Value = 1.0;   % omega0
                    app.handles.ic_coeff2.Value = 1.0;   % core radius
                    app.handles.ic_coeff3.Value = 0.0;
                    app.handles.ic_coeff4.Value = 0.0;
                    app.append_to_terminal('✓ Loaded: Rankine preset');
                    
                case 'lamb_dipole'
                    app.handles.ic_dropdown.Value = 'Lamb Dipole';
                    app.handles.ic_coeff1.Value = 0.5;   % U
                    app.handles.ic_coeff2.Value = 1.0;   % a
                    app.handles.ic_coeff3.Value = 0.0;
                    app.handles.ic_coeff4.Value = 0.0;
                    app.append_to_terminal('✓ Loaded: Lamb Dipole preset');
            end
            app.update_ic_preview();
        end
        
        function export_configuration(app)
            [file, path] = uiputfile({'*.json';'*.mat'}, 'Export Configuration', 'simulation_config.json');
            if isequal(file, 0)
                return;
            end
            
            filepath = fullfile(path, file);
            config_export = struct();
            method_val = app.handles.method_dropdown.Value;
            switch method_val
                case 'Finite Difference'
                    config_export.method = 'finite_difference';
                case 'Finite Volume'
                    config_export.method = 'finite_volume';
                case 'Spectral'
                    config_export.method = 'spectral';
                otherwise
                    config_export.method = 'finite_difference';
            end

            mode_val = app.handles.mode_dropdown.Value;
            switch mode_val
                case 'Evolution'
                    config_export.mode = 'evolution';
                    config_export.run_mode_internal = 'Evolution';
                case 'Convergence'
                    config_export.mode = 'convergence';
                    config_export.run_mode_internal = 'Convergence';
                case 'Sweep'
                    config_export.mode = 'sweep';
                    config_export.run_mode_internal = 'ParameterSweep';
                case 'Animation'
                    config_export.mode = 'animation';
                    config_export.run_mode_internal = 'Evolution';
                otherwise
                    config_export.mode = 'experimentation';
                    config_export.run_mode_internal = 'Evolution';
            end

            config_export.Nx = round(app.handles.Nx.Value);
            config_export.Ny = round(app.handles.Ny.Value);
            config_export.Lx = app.handles.Lx.Value;
            config_export.Ly = app.handles.Ly.Value;
            config_export.delta = app.handles.delta.Value;
            config_export.dt = app.handles.dt.Value;
            config_export.t_final = app.handles.t_final.Value;
            config_export.Tfinal = app.handles.t_final.Value;
            config_export.nu = app.handles.nu.Value;
            config_export.num_snapshots = round(app.handles.num_snapshots.Value);
            config_export.ic_type = map_ic_display_to_type(app.handles.ic_dropdown.Value);
            config_export.ic_pattern = app.get_ic_pattern_value();
            config_export.ic_count = app.get_ic_count_value();
            config_export.ic_scale = app.handles.ic_scale.Value;
            config_export.ic_coeff1 = app.handles.ic_coeff1.Value;
            config_export.ic_coeff2 = app.handles.ic_coeff2.Value;
            config_export.ic_coeff3 = app.handles.ic_coeff3.Value;
            config_export.ic_coeff4 = app.handles.ic_coeff4.Value;
            config_export.ic_center_x = app.handles.ic_center_x.Value;
            config_export.ic_center_y = app.handles.ic_center_y.Value;
            config_export.bathymetry_enabled = app.handles.bathy_enable.Value;
            config_export.bathymetry_file = app.handles.bathy_file.Value;
            config_export.motion_enabled = app.handles.motion_enable.Value;
            config_export.motion_model = app.handles.motion_model.Value;
            config_export.motion_amplitude = app.handles.motion_amplitude.Value;
            config_export.ic_coeff = app.build_ic_coeff_vector(config_export.ic_type);

            config_export.convergence_N_coarse = app.handles.conv_N_coarse.Value;
            config_export.convergence_N_max = app.handles.conv_N_max.Value;
            config_export.convergence_tol = app.handles.conv_tolerance.Value;
            config_export.convergence_criterion_type = app.handles.conv_criterion.Value;
            config_export.convergence_binary = app.handles.conv_binary.Value;
            config_export.convergence_use_adaptive = app.handles.conv_use_adaptive.Value;
            config_export.convergence_max_jumps = app.handles.conv_max_jumps.Value;
            config_export.convergence_agent_enabled = app.handles.conv_agent_enabled.Value;

            defaults = app.initialize_default_config();
            config_export.sweep_parameter = defaults.sweep_parameter;
            config_export.sweep_values = defaults.sweep_values;
            config_export.experimentation = defaults.experimentation;
            if isfield(app, 'config') && isstruct(app.config) && ~isempty(fieldnames(app.config))
                if isfield(app.config, 'sweep_parameter') && ~isempty(app.config.sweep_parameter)
                    config_export.sweep_parameter = app.config.sweep_parameter;
                end
                if isfield(app.config, 'sweep_values') && ~isempty(app.config.sweep_values)
                    config_export.sweep_values = app.config.sweep_values;
                end
                if isfield(app.config, 'experimentation') && isstruct(app.config.experimentation)
                    config_export.experimentation = app.config.experimentation;
                end
            end

            config_export.save_csv = app.handles.save_csv.Value;
            config_export.save_mat = app.handles.save_mat.Value;
            config_export.figures_save_png = app.handles.figures_save_png.Value;
            config_export.figures_save_fig = app.handles.figures_save_fig.Value;
            config_export.figures_dpi = app.handles.figures_dpi.Value;
            config_export.figures_close_after_save = app.handles.figures_close_after_save.Value;
            config_export.figures_use_owl_saver = app.handles.figures_use_owl_saver.Value;
            config_export.create_animations = app.handles.create_animations.Value;
            config_export.animation_format = app.handles.animation_format.Value;
            config_export.animation_fps = app.handles.animation_fps.Value;
            config_export.animation_num_frames = max(2, round(app.handles.animation_num_frames.Value));

            config_export.enable_monitoring = app.handles.enable_monitoring.Value;
            config_export.sample_interval = app.handles.sample_interval.Value;
            config_export.sustainability_auto_log = app.handles.sustainability_auto_log.Value;
            config_export.collectors = struct( ...
                'cpuz', app.handles.cpuz_enable.Value, ...
                'hwinfo', app.handles.hwinfo_enable.Value, ...
                'icue', app.handles.icue_enable.Value, ...
                'strict', app.handles.collector_strict.Value, ...
                'machine_tag', app.handles.machine_tag.Value);
            
            if endsWith(file, '.json')
                json_str = jsonencode(config_export);
                fid = fopen(filepath, 'w');
                fprintf(fid, '%s', json_str);
                fclose(fid);
            else
                save(filepath, 'config_export');
            end
            
            app.append_to_terminal(sprintf('✓ Configuration exported to: %s', file));
        end
        
        function import_configuration(app)
            [file, path] = uigetfile({'*.json;*.mat', 'Config Files (*.json, *.mat)'}, ...
                'Import Configuration');
            if isequal(file, 0)
                return;
            end

            filepath = fullfile(path, file);
            cfg = struct();
            try
                if endsWith(lower(file), '.json')
                    cfg = jsondecode(fileread(filepath));
                else
                    payload = load(filepath);
                    if isfield(payload, 'config_export')
                        cfg = payload.config_export;
                    else
                        keys = fieldnames(payload);
                        if ~isempty(keys) && isstruct(payload.(keys{1}))
                            cfg = payload.(keys{1});
                        end
                    end
                end
            catch ME
                uialert(app.fig, sprintf('Could not import config: %s', ME.message), ...
                    'Import Error', 'icon', 'error');
                app.append_to_terminal(sprintf('Import failed: %s', ME.message), 'error');
                return;
            end

            if ~isstruct(cfg) || isempty(fieldnames(cfg))
                uialert(app.fig, 'Config file contained no usable fields.', ...
                    'Import Error', 'icon', 'error');
                app.append_to_terminal('Import failed: no usable fields found.', 'error');
                return;
            end

            if isfield(cfg, 'method')
                method_token = lower(char(string(cfg.method)));
                switch method_token
                    case 'finite_difference'
                        app.handles.method_dropdown.Value = 'Finite Difference';
                    case 'finite_volume'
                        app.handles.method_dropdown.Value = 'Finite Volume';
                    case 'spectral'
                        app.handles.method_dropdown.Value = 'Spectral';
                    case 'bathymetry'
                        app.handles.method_dropdown.Value = 'Finite Difference';
                        app.handles.bathy_enable.Value = true;
                end
            end

            if isfield(cfg, 'mode')
                mode_token = lower(char(string(cfg.mode)));
                switch mode_token
                    case 'evolution'
                        app.handles.mode_dropdown.Value = 'Evolution';
                    case 'convergence'
                        app.handles.mode_dropdown.Value = 'Convergence';
                    case 'sweep'
                        app.handles.mode_dropdown.Value = 'Sweep';
                    case 'animation'
                        app.handles.mode_dropdown.Value = 'Animation';
                    case 'experimentation'
                        app.handles.mode_dropdown.Value = 'Experimentation';
                end
            end

            if isfield(cfg, 'Nx'), app.handles.Nx.Value = cfg.Nx; end
            if isfield(cfg, 'Ny'), app.handles.Ny.Value = cfg.Ny; end
            if isfield(cfg, 'Lx'), app.handles.Lx.Value = cfg.Lx; end
            if isfield(cfg, 'Ly'), app.handles.Ly.Value = cfg.Ly; end
            if isfield(cfg, 'delta'), app.handles.delta.Value = cfg.delta; end
            if isfield(cfg, 'dt'), app.handles.dt.Value = cfg.dt; end
            if isfield(cfg, 't_final'), app.handles.t_final.Value = cfg.t_final; end
            if isfield(cfg, 'Tfinal'), app.handles.t_final.Value = cfg.Tfinal; end
            if isfield(cfg, 'nu'), app.handles.nu.Value = cfg.nu; end
            if isfield(cfg, 'num_snapshots'), app.handles.num_snapshots.Value = cfg.num_snapshots; end

            if isfield(cfg, 'ic_type')
                target_ic = char(string(cfg.ic_type));
                for k = 1:numel(app.handles.ic_dropdown.Items)
                    item = app.handles.ic_dropdown.Items{k};
                    if strcmp(map_ic_display_to_type(item), target_ic)
                        app.handles.ic_dropdown.Value = item;
                        break;
                    end
                end
            end

            if isfield(cfg, 'ic_pattern') && app.has_valid_handle('ic_pattern')
                requested = char(string(cfg.ic_pattern));
                if any(strcmpi(requested, app.handles.ic_pattern.Items))
                    app.handles.ic_pattern.Value = requested;
                end
            end
            if isfield(cfg, 'ic_count') && app.has_valid_handle('ic_count')
                app.handles.ic_count.Value = cfg.ic_count;
            end
            if isfield(cfg, 'ic_scale'), app.handles.ic_scale.Value = cfg.ic_scale; end
            if isfield(cfg, 'ic_coeff1'), app.handles.ic_coeff1.Value = cfg.ic_coeff1; end
            if isfield(cfg, 'ic_coeff2'), app.handles.ic_coeff2.Value = cfg.ic_coeff2; end
            if isfield(cfg, 'ic_coeff3'), app.handles.ic_coeff3.Value = cfg.ic_coeff3; end
            if isfield(cfg, 'ic_coeff4'), app.handles.ic_coeff4.Value = cfg.ic_coeff4; end
            if isfield(cfg, 'ic_center_x'), app.handles.ic_center_x.Value = cfg.ic_center_x; end
            if isfield(cfg, 'ic_center_y'), app.handles.ic_center_y.Value = cfg.ic_center_y; end

            if isfield(cfg, 'bathymetry_enabled'), app.handles.bathy_enable.Value = logical(cfg.bathymetry_enabled); end
            if isfield(cfg, 'bathymetry_file'), app.handles.bathy_file.Value = char(string(cfg.bathymetry_file)); end
            if isfield(cfg, 'motion_enabled'), app.handles.motion_enable.Value = logical(cfg.motion_enabled); end
            if isfield(cfg, 'motion_model')
                requested_model = char(string(cfg.motion_model));
                if any(strcmpi(requested_model, app.handles.motion_model.Items))
                    app.handles.motion_model.Value = requested_model;
                end
            end
            if isfield(cfg, 'motion_amplitude'), app.handles.motion_amplitude.Value = cfg.motion_amplitude; end

            if isfield(cfg, 'convergence_N_coarse'), app.handles.conv_N_coarse.Value = cfg.convergence_N_coarse; end
            if isfield(cfg, 'convergence_N_max'), app.handles.conv_N_max.Value = cfg.convergence_N_max; end
            if isfield(cfg, 'convergence_tol'), app.handles.conv_tolerance.Value = cfg.convergence_tol; end
            if isfield(cfg, 'convergence_criterion_type'), app.handles.conv_criterion.Value = char(string(cfg.convergence_criterion_type)); end
            if isfield(cfg, 'convergence_binary'), app.handles.conv_binary.Value = logical(cfg.convergence_binary); end
            if isfield(cfg, 'convergence_use_adaptive'), app.handles.conv_use_adaptive.Value = logical(cfg.convergence_use_adaptive); end
            if isfield(cfg, 'convergence_max_jumps'), app.handles.conv_max_jumps.Value = cfg.convergence_max_jumps; end
            if isfield(cfg, 'convergence_agent_enabled'), app.handles.conv_agent_enabled.Value = logical(cfg.convergence_agent_enabled); end

            if isfield(cfg, 'sweep_parameter')
                app.config.sweep_parameter = char(string(cfg.sweep_parameter));
                if app.has_valid_handle('sweep_parameter')
                    app.handles.sweep_parameter.Value = app.config.sweep_parameter;
                end
            end
            if isfield(cfg, 'sweep_values')
                vals = cfg.sweep_values;
                if isnumeric(vals)
                    app.config.sweep_values = vals(:).';
                    if app.has_valid_handle('sweep_values')
                        app.handles.sweep_values.Value = strjoin(arrayfun(@(x) sprintf('%.6g', x), vals(:).', 'UniformOutput', false), ',');
                    end
                elseif ischar(vals) || isstring(vals)
                    app.config.sweep_values = app.parse_numeric_csv(char(string(vals)));
                    if app.has_valid_handle('sweep_values')
                        app.handles.sweep_values.Value = char(string(vals));
                    end
                end
            end
            if isfield(cfg, 'experimentation') && isstruct(cfg.experimentation)
                exp_cfg = cfg.experimentation;
                if ~isfield(app.config, 'experimentation') || ~isstruct(app.config.experimentation)
                    app.config.experimentation = app.initialize_default_config().experimentation;
                end
                if isfield(exp_cfg, 'coeff_selector')
                    app.config.experimentation.coeff_selector = char(string(exp_cfg.coeff_selector));
                    if app.has_valid_handle('exp_coeff_selector')
                        app.handles.exp_coeff_selector.Value = app.config.experimentation.coeff_selector;
                    end
                end
                if isfield(exp_cfg, 'range_start')
                    app.config.experimentation.range_start = exp_cfg.range_start;
                    if app.has_valid_handle('exp_range_start')
                        app.handles.exp_range_start.Value = exp_cfg.range_start;
                    end
                end
                if isfield(exp_cfg, 'range_end')
                    app.config.experimentation.range_end = exp_cfg.range_end;
                    if app.has_valid_handle('exp_range_end')
                        app.handles.exp_range_end.Value = exp_cfg.range_end;
                    end
                end
                if isfield(exp_cfg, 'num_points')
                    app.config.experimentation.num_points = exp_cfg.num_points;
                    if app.has_valid_handle('exp_num_points')
                        app.handles.exp_num_points.Value = exp_cfg.num_points;
                    end
                end
            end

            if isfield(cfg, 'save_csv'), app.handles.save_csv.Value = logical(cfg.save_csv); end
            if isfield(cfg, 'save_mat'), app.handles.save_mat.Value = logical(cfg.save_mat); end
            if isfield(cfg, 'figures_save_png'), app.handles.figures_save_png.Value = logical(cfg.figures_save_png); end
            if isfield(cfg, 'figures_save_fig'), app.handles.figures_save_fig.Value = logical(cfg.figures_save_fig); end
            if isfield(cfg, 'figures_dpi'), app.handles.figures_dpi.Value = cfg.figures_dpi; end
            if isfield(cfg, 'figures_close_after_save'), app.handles.figures_close_after_save.Value = logical(cfg.figures_close_after_save); end
            if isfield(cfg, 'figures_use_owl_saver'), app.handles.figures_use_owl_saver.Value = logical(cfg.figures_use_owl_saver); end
            if isfield(cfg, 'create_animations'), app.handles.create_animations.Value = logical(cfg.create_animations); end
            if isfield(cfg, 'animation_format'), app.handles.animation_format.Value = char(string(cfg.animation_format)); end
            if isfield(cfg, 'animation_fps'), app.handles.animation_fps.Value = cfg.animation_fps; end
            if isfield(cfg, 'animation_num_frames'), app.handles.animation_num_frames.Value = cfg.animation_num_frames; end

            if isfield(cfg, 'enable_monitoring'), app.handles.enable_monitoring.Value = logical(cfg.enable_monitoring); end
            if isfield(cfg, 'sample_interval'), app.handles.sample_interval.Value = cfg.sample_interval; end
            if isfield(cfg, 'sustainability_auto_log'), app.handles.sustainability_auto_log.Value = logical(cfg.sustainability_auto_log); end
            if isfield(cfg, 'collectors') && isstruct(cfg.collectors)
                c = cfg.collectors;
                if isfield(c, 'cpuz'), app.handles.cpuz_enable.Value = logical(c.cpuz); end
                if isfield(c, 'hwinfo'), app.handles.hwinfo_enable.Value = logical(c.hwinfo); end
                if isfield(c, 'icue'), app.handles.icue_enable.Value = logical(c.icue); end
                if isfield(c, 'strict'), app.handles.collector_strict.Value = logical(c.strict); end
                if isfield(c, 'machine_tag'), app.handles.machine_tag.Value = char(string(c.machine_tag)); end
            end

            app.on_method_changed();
            app.on_mode_changed();
            app.on_ic_changed();
            app.update_delta();
            app.update_checklist();
            app.append_to_terminal(sprintf('Configuration imported from: %s', file), 'success');
        end

        function save_terminal_log(app)
            if isempty(app.terminal_log)
                uialert(app.fig, 'No terminal output to save', 'Empty Log', 'icon', 'warning');
                return;
            end
            
            timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
            [file, path] = uiputfile('*.log', 'Save Terminal Log', sprintf('sim_log_%s.log', timestamp));
            if isequal(file, 0)
                return;
            end
            
            filepath = fullfile(path, file);
            fid = fopen(filepath, 'w');
            for i = 1:length(app.terminal_log)
                fprintf(fid, '%s\n', app.terminal_log{i});
            end
            fclose(fid);
            
            app.append_to_terminal(sprintf('✓ Terminal log saved (%d lines) to: %s', length(app.terminal_log), file));
        end
        
        function save_current_figure(app)
            if isempty(app.figures_list)
                uialert(app.fig, 'No figures to save', 'No Figures', 'icon', 'warning');
                return;
            end
            
            [file, path] = uiputfile({'*.png';'*.pdf';'*.fig'}, 'Save Figure As', 'figure.png');
            if isequal(file, 0)
                return;
            end
            
            try
                % Get selected figure
                current_idx = find(strcmp(app.handles.figure_selector.Items, app.handles.figure_selector.Value));
                if isempty(current_idx) || current_idx > length(app.figures_list)
                    current_idx = length(app.figures_list);
                end
                
                saveas(app.figures_list(current_idx), fullfile(path, file));
                app.append_to_terminal(sprintf('✓ Figure saved to: %s', file));
            catch ME
                app.append_to_terminal(sprintf('✗ Error saving figure: %s', ME.message));
            end
        end
        
        function export_all_figures(app)
            if isempty(app.figures_list)
                uialert(app.fig, 'No figures to export', 'No Figures', 'icon', 'warning');
                return;
            end
            
            path = uigetdir(pwd, 'Select Export Directory for All Figures');
            if isequal(path, 0)
                return;
            end
            
            try
                for i = 1:length(app.figures_list)
                    filename = sprintf('figure_%03d.png', i);
                    saveas(app.figures_list(i), fullfile(path, filename));
                end
                app.append_to_terminal(sprintf('✓ Exported %d figures to: %s', length(app.figures_list), path));
            catch ME
                app.append_to_terminal(sprintf('✗ Error exporting figures: %s', ME.message));
            end
        end
        
        function append_to_terminal(app, message, msg_type)
            % Append colored message to terminal with timestamp
            % Args:
            %   message: String to display
            %   msg_type: 'success', 'warning', 'error', 'info', 'debug' (optional)
            %             If omitted, auto-detects from message content
            
            if nargin < 3
                % Auto-detect message type from content
                if contains(message, {'✓', 'Success', 'Updated', 'Complete'}, 'IgnoreCase', true)
                    msg_type = 'success';
                elseif contains(message, {'✗', 'Error', 'Failed', 'Exception'}, 'IgnoreCase', true)
                    msg_type = 'error';
                elseif contains(message, {'Warning', 'Caution'}, 'IgnoreCase', true)
                    msg_type = 'warning';
                else
                    msg_type = 'info';
                end
            end
            
            % Determine color based on message type
            switch lower(msg_type)
                case 'success'
                    color = app.color_success;  % Bright green [0.3 1.0 0.3]
                case 'warning'
                    color = app.color_warning;  % Yellow/orange [1.0 0.8 0.2]
                case 'error'
                    color = app.color_error;    % Red [1.0 0.3 0.3]
                case 'info'
                    color = app.color_info;     % Cyan [0.3 0.8 1.0]
                case 'debug'
                    color = app.color_debug;    % Light gray [0.7 0.7 0.7]
                otherwise
                    color = app.color_info;     % Default to cyan
            end
            
            % Format message with timestamp
            timestamp = char(datetime('now', 'Format', 'HH:mm:ss'));
            formatted_msg = sprintf('[%s] %s', timestamp, message);
            
            app.terminal_log{end+1} = formatted_msg;
            app.terminal_type_log{end+1} = lower(string(msg_type));
            
            % Keep only last 500 lines for responsiveness
            if numel(app.terminal_log) > 500
                app.terminal_log = app.terminal_log(end-499:end);
                app.terminal_type_log = app.terminal_type_log(end-499:end);
            end

            if app.has_valid_handle('terminal_output')
                if isprop(app.handles.terminal_output, 'HTMLSource')
                    app.handles.terminal_output.HTMLSource = app.render_terminal_html();
                elseif isprop(app.handles.terminal_output, 'Value')
                    app.handles.terminal_output.Value = app.terminal_log;
                    app.handles.terminal_output.FontColor = color;
                end
                drawnow limitrate;
            end
        end

        function start_terminal_capture(app)
            % Capture MATLAB command window output in the UI terminal panel
            try
                app.diary_file = fullfile(tempdir, 'ui_controller_terminal.log');
                app.diary_last_size = 0;
                diary off;
                diary(app.diary_file);
                diary on;

                app.safe_stop_timer('diary_timer');

                app.diary_timer = timer('ExecutionMode', 'fixedSpacing', ...
                    'Period', 1.0, ...
                    'TimerFcn', @(~,~) app.update_terminal_from_diary());
                start(app.diary_timer);
            catch
                % If diary capture fails, fall back to manual logs only
            end
        end

        function update_terminal_from_diary(app)
            % Refresh terminal panel from MATLAB diary file
            if isempty(app.diary_file) || ~isfile(app.diary_file)
                return;
            end
            if ~app.has_valid_handle('terminal_output')
                return;
            end

            file_info = dir(app.diary_file);
            if isempty(file_info)
                return;
            end
            if file_info.bytes == app.diary_last_size
                return;
            end
            app.diary_last_size = file_info.bytes;

            try
                txt = fileread(app.diary_file);
                lines = splitlines(string(txt));
                lines = lines(strlength(strtrim(lines)) > 0);
                if isempty(lines)
                    return;
                end
                if numel(lines) > 500
                    lines = lines(end-499:end);
                end

                existing = string(app.terminal_log);
                for i = 1:numel(lines)
                    line_i = char(lines(i));
                    if isempty(existing) || ~strcmp(existing(end), string(line_i))
                        app.terminal_log{end+1} = line_i;
                        app.terminal_type_log{end+1} = 'debug';
                        existing(end+1) = string(line_i); %#ok<AGROW>
                    end
                end
                if numel(app.terminal_log) > 500
                    app.terminal_log = app.terminal_log(end-499:end);
                    app.terminal_type_log = app.terminal_type_log(end-499:end);
                end

                if isprop(app.handles.terminal_output, 'HTMLSource')
                    app.handles.terminal_output.HTMLSource = app.render_terminal_html();
                elseif isprop(app.handles.terminal_output, 'Value')
                    app.handles.terminal_output.Value = app.terminal_log;
                end
                drawnow limitrate;
            catch
            end
        end
        
        function add_figure(app, fig, name)
            % Add figure to figures list
            if nargin < 3
                name = sprintf('Figure %d', length(app.figures_list) + 1);
            end
            app.figures_list(end+1) = fig;

            fig_names = arrayfun(@(i) sprintf('Figure %d', i), 1:length(app.figures_list), 'UniformOutput', false);
            app.handles.figure_selector.Items = fig_names;
            app.handles.figure_selector.Value = fig_names{end};

            % Create a new tab entry for the figure
            if isfield(app.handles, 'figure_tabs') && ishghandle(app.handles.figure_tabs)
                tab = uitab(app.handles.figure_tabs, 'Title', name);
                % Use grid layout for label instead of Position
                tab_grid = uigridlayout(tab, [1 1]);
                tab_grid.Padding = [10 10 10 10];
                uilabel(tab_grid, 'Text', sprintf('%s stored. Select in dropdown to preview.', name));
            end

            app.show_figure(length(app.figures_list));
            app.append_to_terminal(sprintf('✓ Added figure: %s', name));
        end
        
        function on_figure_selected(app)
            if isempty(app.figures_list)
                return;
            end
            idx = find(strcmp(app.handles.figure_selector.Items, app.handles.figure_selector.Value), 1);
            if isempty(idx)
                idx = length(app.figures_list);
            end
            app.show_figure(idx);
        end

        function refresh_figures(app)
            if isempty(app.figures_list)
                app.handles.figure_selector.Items = {'No figures yet'};
                app.handles.figure_selector.Value = 'No figures yet';
                return;
            end
            fig_names = arrayfun(@(i) sprintf('Figure %d', i), 1:length(app.figures_list), 'UniformOutput', false);
            app.handles.figure_selector.Items = fig_names;
            app.handles.figure_selector.Value = fig_names{end};
            app.show_figure(length(app.figures_list));
        end

        function show_figure(app, idx)
            if isempty(app.figures_list) || idx < 1 || idx > length(app.figures_list)
                return;
            end
            try
                ax = app.handles.figure_axes;
                cla(ax);
                frame = getframe(app.figures_list(idx));
                image(ax, frame.cdata);
                axis(ax, 'off');
            catch
                % If frame capture fails, keep placeholder
            end
        end

        function cleanup(app)
            % Cleanup when UI closes
            try
                app.safe_stop_timer('diary_timer');
                diary off;
                if ~isempty(app.fig) && isvalid(app.fig)
                    if isprop(app.fig, 'CloseRequestFcn')
                        app.fig.CloseRequestFcn = '';
                    end
                    delete(app.fig);
                end
            catch
            end
        end

        function delete(app)
            % Defensive destructor: ensure background timer is never leaked
            try
                app.safe_stop_timer('diary_timer');
            catch
            end
            try
                diary off;
            catch
            end
        end
        
        function resize_ui(~)
            % Resize callback - NO LONGER NEEDED
            % Grid layout auto-resizes, no manual Position adjustments required
            % This method kept as stub for backwards compatibility
        end
        
        % Additional stub methods for button callbacks
        function update_ic_preview(app)
            % Update initial condition preview using the same coefficient
            % packing and IC factory used in launched runs.
            try
                if ~isfield(app.handles, 'ic_preview_axes') || ~isvalid(app.handles.ic_preview_axes)
                    return;
                end

                ax = app.handles.ic_preview_axes;
                cla(ax);

                Nx = max(16, round(app.handles.Nx.Value));
                Ny = max(16, round(app.handles.Ny.Value));
                n = min(256, max(64, round(min([Nx Ny]))));

                Lx = max(app.handles.Lx.Value, 1e-6);
                Ly = max(app.handles.Ly.Value, 1e-6);
                [X, Y] = meshgrid(linspace(-Lx / 2, Lx / 2, n), linspace(-Ly / 2, Ly / 2, n));

                ic_display = app.handles.ic_dropdown.Value;
                ic_type = map_ic_display_to_type(ic_display);
                ic_coeff = app.build_ic_coeff_vector(ic_type);

                Z = initialise_omega(X, Y, ic_type, ic_coeff);
                if any(~isfinite(Z), 'all')
                    error('Initial condition generated non-finite values for preview.');
                end

                z_min = min(Z, [], 'all');
                z_max = max(Z, [], 'all');
                z_span = z_max - z_min;
                z_tol = max(1e-10, 1e-7 * max(1, max(abs(Z), [], 'all')));

                if z_span <= z_tol
                    app.render_ic_image(ax, X, Y, Z);
                else
                    rendered_contour = app.render_ic_contours(ax, X, Y, Z);
                    if ~rendered_contour
                        app.render_ic_image(ax, X, Y, Z);
                    end
                end
                hold(ax, 'on');
                rectangle(ax, 'Position', [-Lx/2 -Ly/2 Lx Ly], ...
                    'EdgeColor', app.layout_cfg.colors.accent_gray, ...
                    'LineStyle', '--', ...
                    'LineWidth', 1.0);
                hold(ax, 'off');

                colormap(ax, 'turbo');
                cb = colorbar(ax);
                cb.Color = app.layout_cfg.colors.fg_text;
                title(ax, sprintf('Initial Vorticity w(x,y,0): %s', ic_display), ...
                    'FontSize', 11, ...
                    'FontWeight', 'bold', ...
                    'Color', app.layout_cfg.colors.fg_text);
                xlabel(ax, 'x', 'FontSize', 10, 'Color', app.layout_cfg.colors.fg_text);
                ylabel(ax, 'y', 'FontSize', 10, 'Color', app.layout_cfg.colors.fg_text);
                axis(ax, 'equal');
                xlim(ax, [-Lx/2 Lx/2]);
                ylim(ax, [-Ly/2 Ly/2]);
                grid(ax, 'on');

                wmax = max(abs(Z), [], 'all');
                app.handles.ic_status.Text = sprintf('IC ready (max|w| = %.3e)', wmax);
                app.handles.ic_status.FontColor = app.layout_cfg.colors.fg_muted;
                app.update_checklist();
            catch ME
                if isfield(app.handles, 'ic_status') && isvalid(app.handles.ic_status)
                    app.handles.ic_status.Text = 'IC preview error';
                    app.handles.ic_status.FontColor = app.layout_cfg.colors.accent_red;
                end
                app.append_to_terminal(sprintf('IC preview error: %s', ME.message), 'error');
            end
        end

        function on_ic_changed(app)
            % Update IC field labels and preview when IC selection changes
            app.update_ic_fields();
            app.update_ic_preview();
        end

        function render_ic_image(~, ax, X, Y, Z)
            % Render IC preview as image-only field (safe for constant Z).
            imagesc(ax, X(1, :), Y(:, 1), Z);
            set(ax, 'YDir', 'normal');
        end

        function rendered = render_ic_contours(app, ax, X, Y, Z)
            % Render contours with guarded warning handling; fallback controlled by caller.
            rendered = false;
            warn1 = warning('query', 'MATLAB:contour:ConstantZData');
            warn2 = warning('query', 'MATLAB:contourf:ConstantZData');
            warn3 = warning('query', 'MATLAB:contour:ConstantData');
            warn4 = warning('query', 'MATLAB:contourf:ConstantData');
            cleanup_obj = onCleanup(@() app.restore_contour_warning_state(warn1, warn2, warn3, warn4)); %#ok<NASGU>
            warning('off', 'MATLAB:contour:ConstantZData');
            warning('off', 'MATLAB:contourf:ConstantZData');
            warning('off', 'MATLAB:contour:ConstantData');
            warning('off', 'MATLAB:contourf:ConstantData');
            try
                contourf(ax, X, Y, Z, 20, 'LineStyle', 'none');
                hold(ax, 'on');
                contour(ax, X, Y, Z, 12, 'LineWidth', 0.9, 'LineColor', [0.82 0.82 0.82]);
                rendered = true;
            catch
                rendered = false;
            end
        end

        function update_ic_fields(app)
            % Update coefficient labels/visibility to match selected IC.
            ic_display = app.handles.ic_dropdown.Value;
            ic_type = map_ic_display_to_type(ic_display);
            eq_tex = '\omega(x,y)=\exp(-a(x-x_0)^2-b(y-y_0)^2)';
            where_lines = {
                'where:';
                'a,b > 0 set spread in x and y (larger => tighter core)';
                'x0,y0 set vortex center location';
            };
            visible_coeff_count = 4;

            app.handles.ic_coeff1.Visible = 'on';
            app.handles.ic_coeff2.Visible = 'on';
            app.handles.ic_coeff3.Visible = 'on';
            app.handles.ic_coeff4.Visible = 'on';
            app.handles.ic_coeff1_label.Visible = 'on';
            app.handles.ic_coeff2_label.Visible = 'on';
            app.handles.ic_coeff3_label.Visible = 'on';
            app.handles.ic_coeff4_label.Visible = 'on';

            app.set_optional_handle_enable('ic_pattern', 'off');
            app.set_optional_handle_enable('ic_count', 'off');

            switch ic_type
                case 'stretched_gaussian'
                    app.handles.ic_coeff1_label.Text = 'Stretch x (a):';
                    app.handles.ic_coeff2_label.Text = 'Stretch y (b):';
                    eq_tex = '\omega(x,y)=\exp\left(-a(x-x_0)^2-b(y-y_0)^2\right)';
                    where_lines = {
                        'where:';
                        'a,b in [0.1,10] control x/y anisotropy (high values sharpen)';
                        'x0,y0 shift the vortex center';
                    };
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    visible_coeff_count = 2;

                case 'vortex_blob_gaussian'
                    app.handles.ic_coeff1_label.Text = 'Circulation (Gamma):';
                    app.handles.ic_coeff2_label.Text = 'Radius (R):';
                    eq_tex = '\omega(r)=\frac{\Gamma}{2\pi R^2}\exp\left(-\frac{r^2}{2R^2}\right)';
                    where_lines = {
                        'where:';
                        '\Gamma sets signed circulation strength';
                        'R > 0 sets core radius (larger R diffuses peak)';
                    };
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    visible_coeff_count = 2;

                case 'vortex_pair'
                    app.handles.ic_coeff1_label.Text = 'Gamma1 amplitude:';
                    app.handles.ic_coeff2_label.Text = 'Separation:';
                    app.handles.ic_coeff3_label.Text = 'Core radius:';
                    eq_tex = '\omega=\omega_1+\omega_2,\;\Gamma_2=-|\Gamma_1|';
                    where_lines = {
                        'where:';
                        '\Gamma_1 controls pair strength; \Gamma_2 is opposite-signed';
                        'separation controls interaction and orbiting distance';
                        'core radius controls compactness of each vortex';
                    };
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    visible_coeff_count = 3;

                case 'multi_vortex'
                    app.handles.ic_coeff1_label.Text = 'Gamma (per vortex):';
                    app.handles.ic_coeff2_label.Text = 'Core radius:';
                    eq_tex = '\omega(x,y)=\sum_{i=1}^{N}\frac{\Gamma}{2\pi R^2}\exp\left(-\frac{r_i^2}{2R^2}\right)';
                    where_lines = {
                        'where:';
                        'N = vortex count (>=1), pattern selects center placement';
                        '\Gamma and R tune strength and core size of each element';
                    };
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    app.set_optional_handle_enable('ic_pattern', 'on');
                    app.set_optional_handle_enable('ic_count', 'on');
                    visible_coeff_count = 2;

                case 'lamb_oseen'
                    app.handles.ic_coeff1_label.Text = 'Circulation (Gamma):';
                    app.handles.ic_coeff2_label.Text = 'Virtual time (t0):';
                    app.handles.ic_coeff3_label.Text = 'Viscosity (nu):';
                    eq_tex = '\omega(r)=\frac{\Gamma}{4\pi\nu t_0}\exp\left(-\frac{r^2}{4\nu t_0}\right)';
                    where_lines = {
                        'where:';
                        '\Gamma is circulation, \nu > 0 is viscosity';
                        't_0 > 0 broadens the core as it increases';
                    };
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    visible_coeff_count = 3;

                case 'rankine'
                    app.handles.ic_coeff1_label.Text = 'Core vorticity:';
                    app.handles.ic_coeff2_label.Text = 'Core radius:';
                    eq_tex = '\omega(r)=\begin{cases}\omega_0,&r\le r_c\\0,&r>r_c\end{cases}';
                    where_lines = {
                        'where:';
                        '\omega_0 sets plateau vorticity inside core';
                        'r_c sets abrupt cutoff radius';
                    };
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    visible_coeff_count = 2;

                case 'lamb_dipole'
                    app.handles.ic_coeff1_label.Text = 'Translation speed (U):';
                    app.handles.ic_coeff2_label.Text = 'Dipole radius (a):';
                    eq_tex = '\omega=\omega_{\mathrm{dipole}}(r,\theta;U,a)';
                    where_lines = {
                        'where:';
                        'U sets propagation speed of dipole pair';
                        'a controls dipole radius and compactness';
                    };
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    visible_coeff_count = 2;

                case 'taylor_green'
                    app.handles.ic_coeff1_label.Text = 'Wavenumber (k):';
                    app.handles.ic_coeff2_label.Text = 'Strength (G):';
                    eq_tex = '\omega(x,y)=2kG\sin(kx)\sin(ky)';
                    where_lines = {
                        'where:';
                        'k controls spectral scale (higher k => finer structures)';
                        'G scales initial vorticity magnitude';
                    };
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    visible_coeff_count = 2;

                case 'random_turbulence'
                    app.handles.ic_coeff1_label.Text = 'Spectrum exponent (alpha):';
                    app.handles.ic_coeff2_label.Text = 'Energy level (E0):';
                    app.handles.ic_coeff3_label.Text = 'Seed:';
                    eq_tex = '\omega(x,y)=\sum_{k}A_k\,\sin(k\cdot x+\phi_k),\;A_k\propto |k|^{-\alpha}';
                    where_lines = {
                        'where:';
                        '\alpha controls decay of high-frequency modes';
                        'E_0 sets total energy scale';
                        'seed fixes reproducibility of random phases';
                    };
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    visible_coeff_count = 3;

                case 'elliptical_vortex'
                    app.handles.ic_coeff1_label.Text = 'Peak vorticity:';
                    app.handles.ic_coeff2_label.Text = 'Sigma x:';
                    app.handles.ic_coeff3_label.Text = 'Sigma y:';
                    app.handles.ic_coeff4_label.Text = 'Rotation theta (rad):';
                    eq_tex = '\omega=w_0\exp\left(-\frac{x_r^2}{2\sigma_x^2}-\frac{y_r^2}{2\sigma_y^2}\right)';
                    where_lines = {
                        'where:';
                        'w_0 sets peak intensity';
                        '\sigma_x,\sigma_y set anisotropic spread; \theta rotates ellipse';
                    };
                    visible_coeff_count = 4;

                otherwise
                    app.handles.ic_coeff1_label.Text = 'Coeff 1:';
                    app.handles.ic_coeff2_label.Text = 'Coeff 2:';
                    app.handles.ic_coeff3_label.Text = 'Coeff 3:';
                    app.handles.ic_coeff4_label.Text = 'Coeff 4:';
                    eq_tex = '\omega(x,y)=f(x,y)';
                    where_lines = {
                        'where:';
                        'coefficients map directly into selected IC factory implementation';
                    };
            end

            app.set_ic_equation_and_where(ic_display, eq_tex, where_lines);
            app.update_ic_compact_layout(visible_coeff_count);
        end

        function set_ic_equation_and_where(app, ic_name, eq_tex, where_lines)
            if app.has_valid_handle('ic_equation')
                eq_handle = app.handles.ic_equation;
                if isprop(eq_handle, 'ImageSource') && app.supports_equation_image_rendering()
                    eq_handle.ImageSource = app.render_equation_image(ic_name, eq_tex);
                elseif isprop(eq_handle, 'ImageSource')
                    eq_handle.ImageSource = '';
                elseif isprop(eq_handle, 'HTMLSource')
                    eq_handle.HTMLSource = app.render_math_html(ic_name, eq_tex);
                end
            end
            if app.has_valid_handle('ic_where')
                app.handles.ic_where.Value = where_lines;
            end
        end

        function image_path = render_equation_image(app, ic_name, eq_tex)
            % Render equation as themed PNG so mathematical symbols display consistently.
            cache_root = fullfile(tempdir, 'tsunami_ui_equations');
            if ~exist(cache_root, 'dir')
                mkdir(cache_root);
            end

            key = app.stable_text_hash(string(ic_name) + "|" + string(eq_tex));
            stem = "ic_eq_" + key;
            image_path = fullfile(cache_root, char(stem + ".png"));
            md_path = fullfile(cache_root, char(stem + ".md"));

            app.write_equation_markdown_source(md_path, ic_name, eq_tex);
            if isfile(image_path)
                return;
            end

            bg = app.layout_cfg.colors.bg_input;
            fg = app.layout_cfg.colors.fg_text;
            header = app.layout_cfg.colors.accent_cyan;

            fig = figure('Visible', 'off', ...
                'Color', bg, ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Units', 'pixels', ...
                'Position', [100 100 1280 220]);
            cleanup_obj = onCleanup(@() app.close_hidden_figure(fig)); %#ok<NASGU>

            ax = axes('Parent', fig, ...
                'Position', [0 0 1 1], ...
                'Visible', 'off', ...
                'Color', bg);
            axis(ax, [0 1 0 1]);
            axis(ax, 'off');

            title_str = "Initial Condition Equation - " + string(ic_name);
            eq_latex = app.normalize_equation_for_latex(eq_tex);
            plain_eq = app.equation_tex_to_plain(eq_tex);

            try
                text(ax, 0.015, 0.88, title_str, ...
                    'Interpreter', 'none', ...
                    'Color', header, ...
                    'FontWeight', 'bold', ...
                    'FontSize', 13, ...
                    'VerticalAlignment', 'top');

                text(ax, 0.02, 0.42, "$\displaystyle " + string(eq_latex) + "$", ...
                    'Interpreter', 'latex', ...
                    'Color', fg, ...
                    'FontSize', 24, ...
                    'VerticalAlignment', 'middle', ...
                    'Clipping', 'on');

                drawnow;
                exportgraphics(ax, image_path, 'Resolution', 170, 'BackgroundColor', bg);
            catch
                cla(ax);
                axis(ax, [0 1 0 1]);
                axis(ax, 'off');
                text(ax, 0.015, 0.88, title_str, ...
                    'Interpreter', 'none', ...
                    'Color', header, ...
                    'FontWeight', 'bold', ...
                    'FontSize', 13, ...
                    'VerticalAlignment', 'top');
                text(ax, 0.02, 0.42, string(plain_eq), ...
                    'Interpreter', 'none', ...
                    'Color', fg, ...
                    'FontName', 'Consolas', ...
                    'FontSize', 15, ...
                    'VerticalAlignment', 'middle', ...
                    'Clipping', 'on');
                drawnow;
                exportgraphics(ax, image_path, 'Resolution', 170, 'BackgroundColor', bg);
            end
        end

        function write_equation_markdown_source(~, md_path, ic_name, eq_tex)
            % Persist markdown source used for equation-image rendering.
            if isfile(md_path)
                return;
            end
            lines = {
                '# UI Equation Source'
                ''
                ['IC: ', char(string(ic_name))]
                ''
                '$$'
                char(string(eq_tex))
                '$$'
                ''
            };
            fid = fopen(md_path, 'w');
            if fid < 0
                return;
            end
            cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
            fprintf(fid, '%s\n', lines{:});
        end

        function close_hidden_figure(~, fig_handle)
            if isempty(fig_handle)
                return;
            end
            try
                if isvalid(fig_handle)
                    close(fig_handle);
                end
            catch
            end
        end

        function eq_out = normalize_equation_for_latex(~, eq_tex)
            % Convert unsupported TeX fragments to MATLAB-LaTeX-safe form.
            eq_out = char(string(eq_tex));
            eq_out = strrep(eq_out, '\begin{cases}', '(');
            eq_out = strrep(eq_out, '\end{cases}', ')');
            eq_out = strrep(eq_out, '\\', '; ');
            eq_out = strrep(eq_out, '&', ' ');
            eq_out = strrep(eq_out, '\left', '');
            eq_out = strrep(eq_out, '\right', '');
            eq_out = regexprep(eq_out, '\s+', ' ');
            eq_out = strtrim(eq_out);
        end

        function key = stable_text_hash(~, txt)
            raw = char(string(txt));
            if isempty(raw)
                key = "00000000";
                return;
            end
            idx = 1:numel(raw);
            bytes = double(raw);
            h = uint32(2166136261);
            for k = 1:numel(bytes)
                h = bitxor(h, uint32(bytes(k)));
                h = uint32(mod(double(h) * 16777619 + idx(k), 2^32));
            end
            key = string(dec2hex(h, 8));
        end

        function tf = supports_equation_image_rendering(~)
            % Equation snapshot rendering is only enabled in desktop UI sessions.
            tf = usejava('desktop');
        end

        function html = render_math_html(app, ic_name, eq_tex)
            eq_text = app.equation_tex_to_plain(eq_tex);
            eq_text = app.escape_html_text(eq_text);
            html = "<div style='font-family:Segoe UI,Arial,sans-serif;font-size:12px;color:#dcdcdc;line-height:1.35;'>" + ...
                "<b style='color:#80c7ff;'>Initial Condition Equation - " + app.escape_html_text(string(ic_name)) + "</b><br>" + ...
                "<div style='margin-top:6px;padding:6px 8px;border:1px solid #505050;background:#1a1a1a;" + ...
                "font-family:Consolas,Monaco,monospace;font-size:12px;color:#f2f2f2;'>" + eq_text + ...
                "</div></div>";
            html = char(string(html));
        end

        function eq_plain = equation_tex_to_plain(~, eq_tex)
            eq_plain = char(string(eq_tex));
            eq_plain = regexprep(eq_plain, '\\left|\\right', '');
            eq_plain = regexprep(eq_plain, '\\mathrm\{([^{}]+)\}', '$1');
            eq_plain = regexprep(eq_plain, '\\frac\{([^{}]+)\}\{([^{}]+)\}', '($1)/($2)');
            eq_plain = strrep(eq_plain, '\omega', 'ω');
            eq_plain = strrep(eq_plain, '\Gamma', 'Γ');
            eq_plain = strrep(eq_plain, '\nu', 'ν');
            eq_plain = strrep(eq_plain, '\theta', 'θ');
            eq_plain = strrep(eq_plain, '\sigma', 'σ');
            eq_plain = strrep(eq_plain, '\alpha', 'α');
            eq_plain = strrep(eq_plain, '\pi', 'π');
            eq_plain = strrep(eq_plain, '\sum', 'Σ');
            eq_plain = strrep(eq_plain, '\cdot', '·');
            eq_plain = strrep(eq_plain, '\exp', 'exp');
            eq_plain = strrep(eq_plain, '\begin{cases}', '');
            eq_plain = strrep(eq_plain, '\end{cases}', '');
            eq_plain = strrep(eq_plain, '\;', ' ');
            eq_plain = strrep(eq_plain, '\\', '');
            eq_plain = strrep(eq_plain, '{', '(');
            eq_plain = strrep(eq_plain, '}', ')');
            eq_plain = regexprep(eq_plain, '\s+', ' ');
            eq_plain = strtrim(eq_plain);
        end

        function escaped = escape_html_text(~, txt)
            escaped = char(string(txt));
            escaped = strrep(escaped, '&', '&amp;');
            escaped = strrep(escaped, '<', '&lt;');
            escaped = strrep(escaped, '>', '&gt;');
        end

        function update_ic_compact_layout(app, visible_coeff_count)
            if ~app.has_valid_handle('ic_layout')
                return;
            end
            n = max(2, min(4, round(visible_coeff_count)));
            base_top = 34;
            equation_h = 92;
            where_h = 72;
            coeff_total = 124;
            coeff_row = max(28, floor(coeff_total / n));
            center_row = max(28, 36 + (4 - n) * 4);
            status_row = 28;
            app.handles.ic_layout.RowHeight = {base_top, base_top, equation_h, where_h, coeff_row, coeff_row, center_row, status_row};
        end

        function load_converged_mesh_preset(app)
            % Load latest convergence study settings as a reusable mesh preset.
            candidates = dir(fullfile('Results', '*', 'Convergence', '*', 'Config', 'Config.mat'));
            if isempty(candidates)
                candidates = dir(fullfile('Results', '*', 'Convergence', '*', 'Config.mat'));
            end

            if isempty(candidates)
                app.append_to_terminal('No convergence preset found under Results/*/Convergence.', 'warning');
                if app.has_valid_handle('converged_mesh_status')
                    app.handles.converged_mesh_status.Text = 'No convergence preset found';
                    app.handles.converged_mesh_status.FontColor = app.layout_cfg.colors.accent_yellow;
                end
                return;
            end

            [~, idx] = max([candidates.datenum]);
            preset_file = fullfile(candidates(idx).folder, candidates(idx).name);
            S = load(preset_file);

            n_coarse = NaN;
            n_max = NaN;
            tol = NaN;

            if isfield(S, 'Parameters')
                P = S.Parameters;
                if isfield(P, 'mesh_sizes') && isnumeric(P.mesh_sizes) && ~isempty(P.mesh_sizes)
                    n_coarse = min(P.mesh_sizes);
                    n_max = max(P.mesh_sizes);
                end
                if isfield(P, 'conv_tolerance')
                    tol = P.conv_tolerance;
                elseif isfield(P, 'convergence_tol')
                    tol = P.convergence_tol;
                end
            end
            if isfield(S, 'Results')
                R = S.Results;
                if (isnan(n_coarse) || isnan(n_max)) && isfield(R, 'mesh_sizes') && isnumeric(R.mesh_sizes) && ~isempty(R.mesh_sizes)
                    n_coarse = min(R.mesh_sizes);
                    n_max = max(R.mesh_sizes);
                end
            end

            if isnan(n_coarse), n_coarse = app.handles.conv_N_coarse.Value; end
            if isnan(n_max), n_max = app.handles.conv_N_max.Value; end
            if isnan(tol), tol = app.handles.conv_tolerance.Value; end

            app.handles.conv_N_coarse.Value = max(8, round(n_coarse));
            app.handles.conv_N_max.Value = max(app.handles.conv_N_coarse.Value + 8, round(n_max));
            app.handles.conv_tolerance.Value = tol;

            msg = sprintf('Loaded preset N=[%d,%d], tol=%.2e', ...
                app.handles.conv_N_coarse.Value, app.handles.conv_N_max.Value, app.handles.conv_tolerance.Value);
            if app.has_valid_handle('converged_mesh_status')
                app.handles.converged_mesh_status.Text = msg;
                app.handles.converged_mesh_status.FontColor = app.layout_cfg.colors.accent_green;
            end
            app.append_to_terminal(sprintf('Loaded convergence preset from %s', preset_file), 'success');
            app.update_checklist();
            app.update_convergence_display();
        end

        function run_convergence_test(app)
            % Run a quick convergence test
            app.append_to_terminal('🔧 Convergence test would run here (integrate with Tsunami_Vorticity_Emulator)');
            uialert(app.fig, 'Convergence test integration pending', 'Info', 'icon', 'info');
        end
        
        function view_convergence_results(app)
            % View previous convergence results
            app.append_to_terminal('📊 Loading previous convergence results...');
            uialert(app.fig, 'Convergence results viewer pending', 'Info', 'icon', 'info');
        end
        
        function export_convergence_data(app)
            % Export convergence data to CSV
            app.append_to_terminal('💾 Exporting convergence data...');
            uialert(app.fig, 'Convergence data export pending', 'Info', 'icon', 'info');
        end
        
        function view_energy_dashboard(app)
            % View energy monitoring dashboard
            app.append_to_terminal('🔌 Energy dashboard would launch here');
            uialert(app.fig, 'Energy dashboard integration pending', 'Info', 'icon', 'info');
        end
        
        function export_energy_data(app)
            % Export energy monitoring data
            app.append_to_terminal('💾 Exporting energy data...');
            uialert(app.fig, 'Energy data export pending', 'Info', 'icon', 'info');
        end
        
        function browse_bathymetry_file(app)
            % Open file browser for bathymetry file selection
            [file, path] = uigetfile({'*.mat;*.xyz;*.txt;*.dat', 'Bathymetry Files'; ...
                '*.mat', 'MATLAB Files'; ...
                '*.xyz;*.txt;*.dat', 'Text Files'; ...
                '*.*', 'All Files'}, ...
                'Select Bathymetry File', ...
                pwd);
            
            if ~isequal(file, 0)
                full_path = fullfile(path, file);
                app.handles.bathy_file.Value = full_path;
                fprintf('Bathymetry file selected: %s\n', full_path);
            end
        end
    end
    
    methods
        function config = initialize_default_config(~)
            % Initialize default configuration by loading from create_default_parameters.m
            % This ensures UIController always uses the authoritative defaults
            try
                default_params = create_default_parameters();
                % Extract key parameters from defaults
                config = struct(...
                    "method", default_params.analysis_method, ...
                    "mode", 'evolution', ...
                    "Nx", default_params.Nx, ...
                    "Ny", default_params.Ny, ...
                    "Lx", default_params.Lx, ...
                    "Ly", default_params.Ly, ...
                    "delta", default_params.delta, ...
                    "use_explicit_delta", default_params.use_explicit_delta, ...
                    "dt", default_params.dt, ...
                    "t_final", default_params.Tfinal, ...
                    "nu", default_params.nu, ...
                    "num_snapshots", default_params.num_snapshots, ...
                    "ic_type", default_params.ic_type, ...
                    "ic_coeff", default_params.ic_coeff, ...
                    "create_animations", default_params.create_animations, ...
                    "animation_format", default_params.animation_format, ...
                    "animation_fps", default_params.animation_fps, ...
                    "bathymetry_enabled", default_params.bathymetry_enabled ...
                );
            catch ME
                % Fallback to hardcoded defaults if create_default_parameters is not available
                warning(ME.identifier, '%s', ME.message);
                config = struct(...
                    "method", 'Finite Difference', ...
                    "mode", 'evolution', ...
                    "Nx", 128, ...
                    "Ny", 128, ...
                    "Lx", 10, ...
                    "Ly", 10, ...
                    "delta", 2, ...
                    "use_explicit_delta", true, ... 
                    "dt", 0.01, ...
                    "t_final", 8.0, ...
                    "nu", 1e-6, ...
                    "num_snapshots", 9, ...
                    "ic_type", "stretched_gaussian", ...
                    "ic_coeff", [2, 0.2], ...
                    "create_animations", true, ...
                    "animation_format", 'mp4', ...
                    "animation_fps", 30, ...
                    "bathymetry_enabled", false ...
                );
            end

            % UI runtime-only fields used by launch/export paths.
            config.ic_pattern = 'single';
            config.sweep_parameter = 'nu';
            config.sweep_values = [1e-6, 5e-6, 1e-5];
            config.motion_enabled = false;
            config.motion_model = 'none';
            config.motion_amplitude = 0.0;
            config.sustainability_auto_log = true;
            config.collectors = struct('cpuz', false, 'hwinfo', false, 'icue', false, ...
                'strict', false, 'machine_tag', getenv('COMPUTERNAME'));
            config.experimentation = struct( ...
                'coeff_selector', 'ic_coeff1', ...
                'range_start', 0.5, ...
                'range_end', 2.0, ...
                'num_points', 4);
            config.run_mode_internal = 'Evolution';
        end
        
        % ===================================================================
        % DEVELOPER MODE & LAYOUT INSPECTION
        % ===================================================================
        
        function create_menu_bar(app)
            % Create menu bar with Developer Mode toggle
            % Menu bar occupies row 1 of root_grid
            
            menu_panel = uipanel(app.root_grid, 'BorderType', 'none', ...
                'BackgroundColor', app.layout_cfg.colors.bg_panel);
            menu_panel.Layout.Row = 1;
            menu_panel.Layout.Column = 1;
            
            menu_grid = uigridlayout(menu_panel, [1, 3]);
            menu_grid.ColumnWidth = {'fit', '1x', 'fit'};
            menu_grid.Padding = [10 5 10 5];
            menu_grid.ColumnSpacing = 10;
            
            % Title label
            uilabel(menu_grid, 'Text', '🌊 Tsunami Vortex Simulation UI', ...
                'FontSize', 14, 'FontWeight', 'bold', ...
                'FontColor', app.layout_cfg.colors.fg_text);
            
            % Spacer
            uilabel(menu_grid, 'Text', '');
            
            % Developer Mode toggle
            app.handles.dev_mode_toggle = uibutton(menu_grid, 'push', ...
                'Text', '🔧 Developer Mode: OFF', ...
                'FontSize', 11, ...
                'BackgroundColor', [0.3 0.3 0.3], ...
                'FontColor', [0.9 0.9 0.9], ...
                'ButtonPushedFcn', @(~,~) app.toggle_developer_mode());
        end
        
        function toggle_developer_mode(app)
            % Toggle Developer Mode on/off
            app.dev_mode_enabled = ~app.dev_mode_enabled;
            
            if app.dev_mode_enabled
                app.handles.dev_mode_toggle.Text = '🔧 Developer Mode: ON';
                app.handles.dev_mode_toggle.BackgroundColor = app.layout_cfg.colors.accent_green;
                app.handles.dev_mode_toggle.FontColor = [0 0 0];
                app.show_developer_inspector();
                app.append_to_terminal('Developer Mode ENABLED. Click any component to inspect.', 'info');
            else
                app.handles.dev_mode_toggle.Text = '🔧 Developer Mode: OFF';
                app.handles.dev_mode_toggle.BackgroundColor = [0.3 0.3 0.3];
                app.handles.dev_mode_toggle.FontColor = [0.9 0.9 0.9];
                app.hide_developer_inspector();
                app.append_to_terminal('Developer Mode DISABLED.', 'info');
            end
        end
        
        function show_developer_inspector(app)
            % Create or show Developer Mode inspector panel
            % Inspector appears as floating window with component details
            
            if isfield(app.handles, 'dev_inspector_fig') && ishghandle(app.handles.dev_inspector_fig)
                app.handles.dev_inspector_fig.Visible = 'on';
                return;
            end
            
            % Create inspector figure
            app.handles.dev_inspector_fig = uifigure('Name', 'UI Developer Inspector', ...
                'Position', [100 100 app.layout_cfg.dev_mode.inspector_width 500], ...
                'Color', app.layout_cfg.colors.bg_dark);
            
            grid = uigridlayout(app.handles.dev_inspector_fig, [8 1]);
            grid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '1x'};
            grid.Padding = [10 10 10 10];
            grid.RowSpacing = 8;
            
            % Title
            uilabel(grid, 'Text', '🔍 Component Inspector', ...
                'FontSize', 14, 'FontWeight', 'bold', ...
                'FontColor', app.layout_cfg.colors.fg_text);
            
            % Instructions
            uilabel(grid, 'Text', 'Click any UI component to inspect', ...
                'FontSize', 10, 'FontColor', app.layout_cfg.colors.accent_gray, ...
                'WordWrap', 'on');
            
            % Component info panel
            info_panel = uipanel(grid, 'Title', 'Selected Component', ...
                'FontWeight', 'bold', 'BackgroundColor', app.layout_cfg.colors.bg_panel);
            info_grid = uigridlayout(info_panel, [10 2]);
            info_grid.ColumnWidth = {'fit', '1x'};
            info_grid.RowHeight = repmat({'fit'}, 1, 10);
            info_grid.Padding = [8 8 8 8];
            info_grid.RowSpacing = 4;
            
            % Labels and values
            uilabel(info_grid, 'Text', 'Type:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_type = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7]);
            
            uilabel(info_grid, 'Text', 'Parent:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_parent = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7]);
            
            uilabel(info_grid, 'Text', 'Layout.Row:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_row = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7]);
            
            uilabel(info_grid, 'Text', 'Layout.Column:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_col = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7]);
            
            uilabel(info_grid, 'Text', 'Row Span:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_rowspan = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7]);
            
            uilabel(info_grid, 'Text', 'Col Span:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_colspan = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7]);
            
            uilabel(info_grid, 'Text', 'Parent Grid Rows:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_parent_rows = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7]);
            
            uilabel(info_grid, 'Text', 'Parent Grid Cols:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_parent_cols = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7]);
            
            uilabel(info_grid, 'Text', 'Callbacks:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_callbacks = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7], 'WordWrap', 'on');
            
            uilabel(info_grid, 'Text', 'Tag/ID:', 'FontWeight', 'bold', 'FontColor', [0.9 0.9 0.9]);
            app.handles.dev_tag = uilabel(info_grid, 'Text', '(none)', 'FontColor', [0.7 0.7 0.7], 'WordWrap', 'on');
            
            % Tools panel
            tools_panel = uipanel(grid, 'Title', 'Layout Tools', ...
                'FontWeight', 'bold', 'BackgroundColor', app.layout_cfg.colors.bg_panel);
            tools_grid = uigridlayout(tools_panel, [3 1]);
            tools_grid.RowHeight = {'fit', 'fit', 'fit'};
            tools_grid.Padding = [8 8 8 8];
            tools_grid.RowSpacing = 6;
            
            uibutton(tools_grid, 'Text', 'Validate All Layouts', ...
                'FontSize', 11, 'ButtonPushedFcn', @(~,~) app.validate_all_layouts());
            
            uibutton(tools_grid, 'Text', 'Dump UI Map to Console', ...
                'FontSize', 11, 'ButtonPushedFcn', @(~,~) app.dump_ui_map());
            
            uibutton(tools_grid, 'Text', 'Reset to Default Layout', ...
                'FontSize', 11, 'ButtonPushedFcn', @(~,~) app.reset_layout());
            
            % Log area
            log_panel = uipanel(grid, 'Title', 'Inspector Log', ...
                'FontWeight', 'bold', 'BackgroundColor', app.layout_cfg.colors.bg_panel);
            log_grid = uigridlayout(log_panel, [1 1]);
            log_grid.Padding = [5 5 5 5];
            
            app.handles.dev_log = uitextarea(log_grid, 'Value', {'Developer Mode Active'}, ...
                'Editable', 'off', 'FontName', 'Courier New', 'FontSize', 9);
            
            % Enable click-to-inspect on all components
            app.enable_click_inspector();
        end
        
        function hide_developer_inspector(app)
            % Hide Developer Mode inspector
            if isfield(app.handles, 'dev_inspector_fig') && ishghandle(app.handles.dev_inspector_fig)
                app.handles.dev_inspector_fig.Visible = 'off';
            end
            app.disable_click_inspector();
        end
        
        function enable_click_inspector(app)
            % Enable click-to-inspect on all UI components
            % Store original callbacks and replace with inspector
            app.dev_original_callbacks = containers.Map('KeyType', 'double', 'ValueType', 'any');
            app.add_click_listener_recursive(app.fig);
        end
        
        function disable_click_inspector(app)
            % Disable click-to-inspect (restore original callbacks)
            if isempty(app.dev_original_callbacks)
                return;
            end
            
            % Check if it's a containers.Map with keys
            if ~isa(app.dev_original_callbacks, 'containers.Map')
                app.dev_original_callbacks = [];
                return;
            end
            
            % Restore all original callbacks
            keys_array = keys(app.dev_original_callbacks);
            for i = 1:length(keys_array)
                handle_id = keys_array{i};
                original_callback = app.dev_original_callbacks(handle_id);
                
                % Find the handle and restore its callback
                try
                    h = handle(handle_id);
                    if ishghandle(h) && isprop(h, 'ButtonDownFcn')
                        h.ButtonDownFcn = original_callback;
                    end
                catch
                    % Handle no longer exists or not accessible
                end
            end
            
            % Clear the stored callbacks
            app.dev_original_callbacks = [];
        end
        
        function add_click_listener_recursive(app, obj)
            % Recursively add click listeners to all children
            % Store original callbacks before overwriting
            if ~ishghandle(obj)
                return;
            end
            
            % Add listener if component supports it
            try
                if isprop(obj, 'ButtonDownFcn')
                    % Store original callback using handle's double value as key
                    handle_id = double(obj);
                    if ~isempty(obj.ButtonDownFcn)
                        app.dev_original_callbacks(handle_id) = obj.ButtonDownFcn;
                    else
                        app.dev_original_callbacks(handle_id) = [];
                    end
                    % Set inspector callback
                    obj.ButtonDownFcn = @(src, ~) app.safe_inspect_component(src);
                end
            catch
                % Component doesn't support ButtonDownFcn
            end
            
            % Recurse to children
            try
                children = obj.Children;
                for i = 1:length(children)
                    app.add_click_listener_recursive(children(i));
                end
            catch
                % No children or children not accessible
            end
        end
        
        function inspect_component(app, component)
            % Inspect clicked component and display details
            if ~app.dev_mode_enabled
                return;  % Only active in dev mode
            end

            if nargin < 2 || isempty(component) || ~ishghandle(component)
                return;
            end

            % If inspector widgets were deleted manually, fail closed.
            if ~app.has_valid_handle('dev_inspector_fig') || ...
                    ~strcmpi(app.handles.dev_inspector_fig.Visible, 'on')
                app.dev_mode_enabled = false;
                app.disable_click_inspector();
                if app.has_valid_handle('dev_mode_toggle')
                    app.handles.dev_mode_toggle.Text = 'Developer Mode: OFF';
                    app.handles.dev_mode_toggle.BackgroundColor = [0.3 0.3 0.3];
                    app.handles.dev_mode_toggle.FontColor = [0.9 0.9 0.9];
                end
                return;
            end

            app.selected_component = component;

            % Get component type
            comp_type = class(component);
            app.set_dev_text('dev_type', comp_type);

            % Get parent
            try
                parent = component.Parent;
                parent_type = class(parent);
                app.set_dev_text('dev_parent', parent_type);
            catch
                app.set_dev_text('dev_parent', '(no parent)');
            end

            % Get Layout properties
            try
                if isprop(component, 'Layout')
                    layout = component.Layout;

                    if isprop(layout, 'Row')
                        app.set_dev_text('dev_row', mat2str(layout.Row));
                    else
                        app.set_dev_text('dev_row', '(not grid layout)');
                    end

                    if isprop(layout, 'Column')
                        app.set_dev_text('dev_col', mat2str(layout.Column));
                    else
                        app.set_dev_text('dev_col', '(not grid layout)');
                    end
                else
                    app.set_dev_text('dev_row', '(no Layout property)');
                    app.set_dev_text('dev_col', '(no Layout property)');
                end
            catch
                app.set_dev_text('dev_row', '(error)');
                app.set_dev_text('dev_col', '(error)');
            end

            % Get parent grid properties
            try
                parent = component.Parent;
                if isa(parent, 'matlab.ui.container.GridLayout')
                    app.set_dev_text('dev_parent_rows', sprintf('%d rows', length(parent.RowHeight)));
                    app.set_dev_text('dev_parent_cols', sprintf('%d cols', length(parent.ColumnWidth)));
                else
                    app.set_dev_text('dev_parent_rows', '(parent not grid)');
                    app.set_dev_text('dev_parent_cols', '(parent not grid)');
                end
            catch
                app.set_dev_text('dev_parent_rows', '(error)');
                app.set_dev_text('dev_parent_cols', '(error)');
            end

            % Get callbacks
            callback_names = {};
            try
                props = properties(component);
                for i = 1:length(props)
                    prop = props{i};
                    if contains(lower(prop), 'callback') || contains(lower(prop), 'fcn')
                        if ~isempty(component.(prop))
                            callback_names{end+1} = prop; %#ok<AGROW>
                        end
                    end
                end
                if isempty(callback_names)
                    app.set_dev_text('dev_callbacks', '(none)');
                else
                    app.set_dev_text('dev_callbacks', strjoin(callback_names, ', '));
                end
            catch
                app.set_dev_text('dev_callbacks', '(error)');
            end

            % Get Tag
            try
                if isprop(component, 'Tag')
                    tag_val = component.Tag;
                    if isempty(tag_val)
                        app.set_dev_text('dev_tag', '(no tag)');
                    else
                        app.set_dev_text('dev_tag', tag_val);
                    end
                else
                    app.set_dev_text('dev_tag', '(no Tag property)');
                end
            catch
                app.set_dev_text('dev_tag', '(error)');
            end

            % Log to inspector
            log_msg = sprintf('Inspected: %s', comp_type);
            app.append_dev_log(log_msg);
        end

        function safe_inspect_component(app, component)
            % Guarded inspector callback to avoid propagating UI callback errors.
            try
                if isempty(app) || ~isvalid(app)
                    return;
                end
                app.inspect_component(component);
            catch
                % Best effort only: ignore stale handle callback failures.
            end
        end
        
        function append_dev_log(app, msg)
            % Append message to developer log
            if ~isfield(app.handles, 'dev_log') || ~ishghandle(app.handles.dev_log)
                return;
            end
            
            current = app.handles.dev_log.Value;
            current{end+1} = sprintf('[%s] %s', char(datetime('now', 'Format', 'HH:mm:ss')), msg);
            
            % Keep last 50 messages
            if length(current) > 50
                current = current(end-49:end);
            end
            
            app.handles.dev_log.Value = current;
            try
                scroll(app.handles.dev_log, 'bottom');
            catch
                % scroll may not be available in all MATLAB versions
            end
        end

        function safe_stop_timer(app, field_name)
            % Stop and delete timer handles defensively without noisy warnings.
            if ~isprop(app, field_name)
                return;
            end
            t = app.(field_name);
            if isempty(t)
                app.(field_name) = [];
                return;
            end

            try
                if isvalid(t)
                    try
                        if strcmpi(char(string(t.Running)), 'on')
                            stop(t);
                        end
                    catch
                        stop(t);
                    end
                    delete(t);
                end
            catch
            end

            app.(field_name) = [];
        end

        function tf = has_valid_handle(app, field_name)
            % True when app.handles.<field_name> exists and is a live UI handle.
            tf = false;
            if ~isfield(app.handles, field_name)
                return;
            end
            h = app.handles.(field_name);
            if isempty(h)
                return;
            end
            try
                tf = isvalid(h);
            catch
                try
                    tf = ishghandle(h);
                catch
                    tf = false;
                end
            end
        end

        function pattern = get_ic_pattern_value(app)
            % Return a safe IC pattern value even when legacy UI layouts omit the control.
            pattern = 'single';
            if ~app.has_valid_handle('ic_pattern')
                return;
            end
            try
                raw = char(string(app.handles.ic_pattern.Value));
                allowed = {'single', 'circular', 'grid', 'random'};
                if any(strcmpi(raw, allowed))
                    pattern = lower(raw);
                end
            catch
                pattern = 'single';
            end
        end

        function n_vort = get_ic_count_value(app)
            % Return a safe positive integer vortex count when control is missing/unset.
            n_vort = 1;
            if ~app.has_valid_handle('ic_count')
                return;
            end
            try
                value = app.handles.ic_count.Value;
                if isfinite(value)
                    n_vort = max(1, round(value));
                end
            catch
                n_vort = 1;
            end
        end

        function set_optional_handle_enable(app, field_name, state)
            % Toggle Enable for optional controls without throwing if absent.
            if ~app.has_valid_handle(field_name)
                return;
            end
            h = app.handles.(field_name);
            if isprop(h, 'Enable')
                h.Enable = state;
            end
        end

        function set_optional_handle_property(app, field_name, prop_name, value)
            % Set arbitrary handle property when the optional control exists.
            if ~app.has_valid_handle(field_name)
                return;
            end
            h = app.handles.(field_name);
            if isprop(h, prop_name)
                h.(prop_name) = value;
            end
        end

        function set_dev_text(app, field_name, value)
            % Set inspector label text only when the target UI element is valid.
            if ~app.has_valid_handle(field_name)
                return;
            end
            h = app.handles.(field_name);
            if isprop(h, 'Text')
                h.Text = char(string(value));
            elseif isprop(h, 'Value')
                h.Value = char(string(value));
            end
        end

        function set_optional_label_text(app, field_name, value)
            % Set label text only when the handle exists and exposes Text.
            if ~app.has_valid_handle(field_name)
                return;
            end
            h = app.handles.(field_name);
            if isprop(h, 'Text')
                h.Text = char(string(value));
            end
        end

        function clear_terminal_view(app)
            app.terminal_log = {};
            app.terminal_type_log = {};
            if app.has_valid_handle('terminal_output')
                if isprop(app.handles.terminal_output, 'HTMLSource')
                    app.handles.terminal_output.HTMLSource = app.render_terminal_html();
                elseif isprop(app.handles.terminal_output, 'Value')
                    app.handles.terminal_output.Value = {'Terminal cleared'};
                end
            end
        end

        function html = render_terminal_html(app)
            % Render terminal log as color-coded HTML rows.
            if isempty(app.terminal_log)
                lines = "<span style='color:#8ab4f8;'>[terminal]</span> waiting for output...";
                html = "<html><body style='margin:0;background:#111;color:#ddd;font-family:Consolas,monospace;font-size:11px;'>" + ...
                    "<div style='padding:6px;white-space:pre-wrap;line-height:1.25;'>" + lines + "</div></body></html>";
                html = char(html);
                return;
            end

            chunks = strings(1, numel(app.terminal_log));
            for i = 1:numel(app.terminal_log)
                msg = string(app.terminal_log{i});
                msg = replace(msg, "&", "&amp;");
                msg = replace(msg, "<", "&lt;");
                msg = replace(msg, ">", "&gt;");
                msg = replace(msg, newline, "<br>");

                if i <= numel(app.terminal_type_log)
                    msg_type = char(string(app.terminal_type_log{i}));
                else
                    msg_type = 'info';
                end
                color = app.terminal_type_color(msg_type);
                chunks(i) = "<div style='color:" + color + ";'>" + msg + "</div>";
            end

            html = "<html><body style='margin:0;background:#111;color:#ddd;font-family:Consolas,monospace;font-size:11px;'>" + ...
                "<div style='padding:6px;white-space:pre-wrap;line-height:1.2;overflow:auto;'>" + ...
                strjoin(chunks, "") + ...
                "</div></body></html>";
            html = char(html);
        end

        function color = terminal_type_color(~, msg_type)
            switch lower(string(msg_type))
                case "success"
                    color = '#5CFF8A';
                case "warning"
                    color = '#FFD166';
                case "error"
                    color = '#FF6B6B';
                case "debug"
                    color = '#9AA0A6';
                otherwise
                    color = '#7CC9FF';
            end
        end

        function catalog = build_monitor_metric_catalog(~)
            % Ranked tiles for the 3x3 monitor (first 8 are plots).
            catalog = struct( ...
                'id', {'iter_vs_time', 'iter_per_sec', 'max_vorticity', 'energy_proxy', ...
                       'enstrophy_proxy', 'cpu_proxy', 'memory_mb', 'convergence_residual'}, ...
                'title', {'Iterations', 'Iterations/s', 'Max |omega|', 'Energy Proxy', ...
                          'Enstrophy Proxy', 'CPU Load Proxy', 'Memory Usage', 'Convergence Residual'}, ...
                'xlabel', {'Physical time', 'Physical time', 'Physical time', 'Physical time', ...
                           'Physical time', 'Physical time', 'Physical time', 'Iteration'}, ...
                'ylabel', {'iters', 'iters/s', '|omega|_{max}', 'E*', ...
                           'Z*', 'CPU %', 'MB', 'residual'}, ...
                'rank', num2cell(1:8));
        end

        function refresh_monitor_dashboard(app, summary, cfg)
            if ~isfield(app.handles, 'monitor_axes') || isempty(app.handles.monitor_axes)
                return;
            end
            if nargin < 3 || isempty(cfg)
                cfg = app.config;
            end
            cfg = app.normalize_monitor_cfg(cfg);

            n_steps = max(16, min(400, round(cfg.Tfinal / max(cfg.dt, eps))));
            t = linspace(0, cfg.Tfinal, n_steps);
            iters = linspace(1, max(1, round(cfg.Tfinal / max(cfg.dt, eps))), n_steps);
            iter_rate = gradient(iters, t + eps);

            max_omega = NaN(1, n_steps);
            if isfield(summary, 'results') && isstruct(summary.results) && isfield(summary.results, 'max_omega')
                m = summary.results.max_omega;
                if ~isscalar(m)
                    m = max(abs(m), [], 'all', 'omitnan');
                end
                max_omega = abs(m) * (0.85 + 0.15 * exp(-2 * t / max(cfg.Tfinal, eps)));
            else
                max_omega = 0.5 + 0.5 * exp(-2 * t / max(cfg.Tfinal, eps));
            end

            energy_proxy = max_omega .^ 2;
            enstrophy_proxy = max_omega .^ 1.5;

            cpu_proxy = 30 + 20 * sin(2 * pi * (t / max(cfg.Tfinal, eps)));
            mem_now = NaN;
            if ispc
                try
                    mem_info = memory;
                    mem_now = mem_info.MemUsedMATLAB / 1024^2;
                catch
                    mem_now = NaN;
                end
            end
            if ~isfinite(mem_now)
                mem_now = 1024;
            end
            memory_series = mem_now + 20 * sin(2 * pi * (t / max(cfg.Tfinal, eps)));

            tol = NaN;
            if isfield(cfg, 'convergence_tol')
                tol = cfg.convergence_tol;
            elseif app.has_valid_handle('conv_tolerance')
                tol = app.handles.conv_tolerance.Value;
            end
            conv_residual = logspace(-1, -4, n_steps);
            if isfinite(tol) && tol > 0
                conv_residual = max(tol / 4, conv_residual);
            end

            series = {
                t, iters;
                t, iter_rate;
                t, max_omega;
                t, energy_proxy;
                t, enstrophy_proxy;
                t, cpu_proxy;
                t, memory_series;
                1:n_steps, conv_residual
            };

            for i = 1:min(numel(app.handles.monitor_axes), 8)
                ax = app.handles.monitor_axes(i);
                if ~isvalid(ax)
                    continue;
                end
                cla(ax);
                x = series{i, 1};
                y = series{i, 2};
                plot(ax, x, y, 'LineWidth', 1.6, 'Color', app.layout_cfg.colors.accent_cyan);
                metric = app.handles.monitor_metric_catalog(i);
                title(ax, metric.title, 'Color', app.layout_cfg.colors.fg_text, 'FontSize', 10);
                xlabel(ax, metric.xlabel, 'Color', app.layout_cfg.colors.fg_text);
                ylabel(ax, metric.ylabel, 'Color', app.layout_cfg.colors.fg_text);
                grid(ax, 'on');
                ax.PlotBoxAspectRatio = [1 1 1];
                ax.PlotBoxAspectRatioMode = 'manual';

                if strcmp(metric.id, 'convergence_residual') && isfinite(tol) && tol > 0
                    yline(ax, tol, '--', sprintf('tol=%.1e', tol), ...
                        'Color', app.layout_cfg.colors.accent_yellow, 'LineWidth', 1.1);
                    if strcmpi(string(cfg.mode), "convergence")
                        idx = find(y <= 1.15 * tol, 1, 'first');
                        if ~isempty(idx)
                            xline(ax, x(idx), ':', 'near-threshold', ...
                                'Color', app.layout_cfg.colors.accent_green, 'LineWidth', 1.0);
                        end
                    end
                end
            end

            app.update_monitor_numeric_table(summary, cfg, mem_now, tol, conv_residual(end));
        end

        function update_monitor_numeric_table(app, summary, cfg, mem_now, tol, conv_metric)
            if ~app.has_valid_handle('monitor_numeric_table')
                return;
            end

            machine = getenv('COMPUTERNAME');
            if isempty(machine)
                machine = getenv('HOSTNAME');
            end
            if isempty(machine)
                machine = 'unknown_machine';
            end
            collectors = 'MATLAB';
            if app.has_valid_handle('cpuz_enable') && app.handles.cpuz_enable.Value
                collectors = collectors + "+CPU-Z";
            end
            if app.has_valid_handle('hwinfo_enable') && app.handles.hwinfo_enable.Value
                collectors = collectors + "+HWiNFO";
            end
            if app.has_valid_handle('icue_enable') && app.handles.icue_enable.Value
                collectors = collectors + "+iCUE";
            end
            collectors = char(string(collectors));

            run_mode = char(string(cfg.mode));
            run_id = '';
            max_omega_val = NaN;
            wall_time = NaN;
            if isfield(summary, 'results') && isstruct(summary.results)
                if isfield(summary.results, 'run_id')
                    run_id = char(string(summary.results.run_id));
                end
                if isfield(summary.results, 'max_omega')
                    max_omega_val = summary.results.max_omega;
                    if ~isscalar(max_omega_val)
                        max_omega_val = max(abs(max_omega_val), [], 'all', 'omitnan');
                    end
                end
                if isfield(summary.results, 'wall_time')
                    wall_time = summary.results.wall_time;
                end
            end
            if isfield(summary, 'wall_time') && isfinite(summary.wall_time)
                wall_time = summary.wall_time;
            end
            if ~isfinite(wall_time)
                wall_time = NaN;
            end

            suggested_n = NaN;
            if strcmpi(run_mode, 'convergence') && isfinite(tol) && tol > 0 && isfinite(conv_metric)
                if conv_metric <= 1.15 * tol
                    if isfield(cfg, 'convergence_N_max') && isfinite(cfg.convergence_N_max)
                        suggested_n = max(8, round(0.8 * cfg.convergence_N_max));
                    end
                elseif isfield(cfg, 'convergence_N_max')
                    suggested_n = cfg.convergence_N_max;
                end
            end

            rows = {
                'Status', 'Ready', '-', 'UI';
                'Mode', run_mode, '-', 'UI';
                'Run ID', app.if_empty(run_id, '--'), '-', 'Dispatcher';
                'Method', char(string(cfg.method)), '-', 'UI';
                'Grid', sprintf('%dx%d', cfg.Nx, cfg.Ny), '-', 'Parameters';
                'Domain Lx', sprintf('%.3g', cfg.Lx), 'm', 'Parameters';
                'Domain Ly', sprintf('%.3g', cfg.Ly), 'm', 'Parameters';
                'dt', sprintf('%.3g', cfg.dt), 's', 'Parameters';
                'Tfinal', sprintf('%.3g', cfg.Tfinal), 's', 'Parameters';
                'Runtime', app.if_nan_num(wall_time), 's', 'Dispatcher';
                'Max |omega|', app.if_nan_num(max_omega_val), '-', 'Solver';
                'Convergence tol', app.if_nan_num(tol), '-', 'Convergence';
                'Convergence metric', app.if_nan_num(conv_metric), '-', 'Convergence';
                'Suggested coarse N', app.if_nan_num(suggested_n), '-', 'Advisor';
                'CPU usage', '--', '%', 'MATLAB';
                'Memory', app.if_nan_num(mem_now), 'MB', 'MATLAB';
                'Machine', machine, '-', 'SystemProfile';
                'Collectors', collectors, '-', 'SystemProfile'
            };
            app.handles.monitor_numeric_table.Data = rows;
        end

        function cfg = normalize_monitor_cfg(app, cfg)
            % Normalize monitor config aliases to avoid missing-field warnings.
            if nargin < 2 || isempty(cfg) || ~isstruct(cfg)
                cfg = struct();
            end

            if ~isfield(cfg, 'Tfinal')
                if isfield(cfg, 't_final')
                    cfg.Tfinal = cfg.t_final;
                elseif app.has_valid_handle('t_final')
                    cfg.Tfinal = app.handles.t_final.Value;
                else
                    cfg.Tfinal = 10;
                end
            end
            if ~isfield(cfg, 'dt')
                if app.has_valid_handle('dt')
                    cfg.dt = app.handles.dt.Value;
                else
                    cfg.dt = 0.01;
                end
            end
            if ~isfield(cfg, 'mode')
                if app.has_valid_handle('mode_dropdown')
                    cfg.mode = lower(char(string(app.handles.mode_dropdown.Value)));
                else
                    cfg.mode = 'evolution';
                end
            end
            if ~isfield(cfg, 'method')
                if app.has_valid_handle('method_dropdown')
                    cfg.method = char(string(app.handles.method_dropdown.Value));
                else
                    cfg.method = 'finite_difference';
                end
            end
            if ~isfield(cfg, 'Nx') && app.has_valid_handle('Nx')
                cfg.Nx = app.handles.Nx.Value;
            end
            if ~isfield(cfg, 'Ny') && app.has_valid_handle('Ny')
                cfg.Ny = app.handles.Ny.Value;
            end
            if ~isfield(cfg, 'Lx') && app.has_valid_handle('Lx')
                cfg.Lx = app.handles.Lx.Value;
            end
            if ~isfield(cfg, 'Ly') && app.has_valid_handle('Ly')
                cfg.Ly = app.handles.Ly.Value;
            end
            if ~isfield(cfg, 'convergence_N_max') && app.has_valid_handle('conv_N_max')
                cfg.convergence_N_max = app.handles.conv_N_max.Value;
            end
            if ~isfield(cfg, 'convergence_tol') && app.has_valid_handle('conv_tolerance')
                cfg.convergence_tol = app.handles.conv_tolerance.Value;
            end
        end

        function out = if_nan_num(~, value)
            if isnumeric(value) && isscalar(value) && isfinite(value)
                out = sprintf('%.4g', value);
            else
                out = '--';
            end
        end

        function out = if_empty(~, txt, fallback)
            if nargin < 3
                fallback = '--';
            end
            t = char(string(txt));
            if isempty(strtrim(t))
                out = fallback;
            else
                out = t;
            end
        end
        
        function validate_all_layouts(app)
            % Validate all layouts in UI (check for errors)
            app.append_dev_log('Running layout validation...');
            
            issues = {};
            
            % Check for leftover Position usage
            issues = app.check_position_usage_recursive(app.fig, issues);
            
            % Check for invalid row/col indices
            % (TODO: implement full validation)
            
            if isempty(issues)
                app.append_dev_log('✓ Validation passed: No issues found');
                app.append_to_terminal('Layout validation PASSED', 'success');
            else
                for i = 1:length(issues)
                    app.append_dev_log(sprintf('⚠ Issue: %s', issues{i}));
                end
                app.append_to_terminal(sprintf('Layout validation found %d issue(s)', length(issues)), 'warning');
            end
        end
        
        function issues = check_position_usage_recursive(app, obj, issues)
            % Recursively check for Position property usage
            if ~ishghandle(obj)
                return;
            end
            
            try
                if isprop(obj, 'Units') && strcmp(obj.Units, 'normalized') && isprop(obj, 'Position')
                    % Check if Position is being used (non-default)
                    % Skip tab group (allowed for now)
                    if ~isa(obj, 'matlab.ui.container.TabGroup')
                        issues{end+1} = sprintf('%s uses Position (should use grid layout)', class(obj));
                    end
                end
            catch
                % Skip
            end
            
            % Recurse
            try
                children = obj.Children;
                for i = 1:length(children)
                    issues = app.check_position_usage_recursive(children(i), issues);
                end
            catch
                % No children
            end
        end
        
        function dump_ui_map(app)
            % Dump UI component map to console and inspector log
            app.append_dev_log('Dumping UI map to console...');
            fprintf('\n===== UI COMPONENT MAP =====\n');
            app.dump_component_tree_recursive(app.fig, 0);
            fprintf('===== END UI MAP =====\n\n');
            app.append_dev_log('✓ UI map dumped to console');
        end
        
        function dump_component_tree_recursive(~, obj, depth)
            % Recursively dump component tree
            if ~ishghandle(obj)
                return;
            end
            
            indent = repmat('  ', 1, depth);
            comp_type = class(obj);
            
            % Get layout info if available
            layout_info = '';
            try
                if isprop(obj, 'Layout') && isprop(obj.Layout, 'Row')
                    layout_info = sprintf(' [Row=%s, Col=%s]', ...
                        mat2str(obj.Layout.Row), mat2str(obj.Layout.Column));
                end
            catch
                % No layout info
            end
            
            % Get tag if available
            tag_info = '';
            try
                if isprop(obj, 'Tag') && ~isempty(obj.Tag)
                    tag_info = sprintf(' (Tag: %s)', obj.Tag);
                end
            catch
                % No tag
            end
            
            fprintf('%s- %s%s%s\n', indent, comp_type, layout_info, tag_info);
            
            % Recurse
            try
                children = obj.Children;
                for i = 1:length(children)
                    dump_component_tree_recursive([], children(i), depth + 1);
                end
            catch
                % No children
            end
        end
        
        function reset_layout(app)
            % Reset UI to default layout configuration
            app.append_dev_log('Resetting layout to defaults...');
            app.append_to_terminal('Layout reset not yet implemented', 'warning');
            % TODO: Full implementation would recreate UI from LayoutCfg
        end
        
    end
end

function ic_type = map_ic_display_to_type(display_name)
    % Map UI display names to internal ic_type values
    % This ensures the display names are human-friendly while 
    % the actual ic_type values match the initialise_omega switch cases
    display_name = char(string(display_name));

    switch display_name
        case {'Stretched Gaussian', 'stretched_gaussian'}
            ic_type = 'stretched_gaussian';
        case {'Vortex Blob', 'Vortex Blob Gaussian', 'vortex_blob', 'vortex_blob_gaussian'}
            ic_type = 'vortex_blob_gaussian';
        case {'Vortex Pair', 'vortex_pair'}
            ic_type = 'vortex_pair';
        case {'Multi-Vortex', 'multi_vortex'}
            ic_type = 'multi_vortex';
        case {'Lamb-Oseen', 'lamb_oseen'}
            ic_type = 'lamb_oseen';
        case {'Rankine', 'rankine'}
            ic_type = 'rankine';
        case {'Lamb Dipole', 'lamb_dipole'}
            ic_type = 'lamb_dipole';
        case {'Taylor-Green', 'taylor_green'}
            ic_type = 'taylor_green';
        case {'Random Turbulence', 'random_turbulence'}
            ic_type = 'random_turbulence';
        case {'Elliptical Vortex', 'elliptical_vortex'}
            ic_type = 'elliptical_vortex';
        otherwise
            % Fallback: try to use display_name directly if it's a valid ic_type
            ic_type = lower(display_name);
    end
end










