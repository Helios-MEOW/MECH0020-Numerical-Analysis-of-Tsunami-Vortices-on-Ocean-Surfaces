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
%   • Parameter Validation & Export to Analysis.m
%
% Usage:
%   >> app = UIController();
%   % Configure settings in GUI, then click "Launch Simulation"
%
% Architecture:
%   Class-based UI with internal state management
%   All monitors are embedded in the UI (no separate windows)
%   Clean encapsulation with properties and methods
%
% ========================================================================

classdef UIController < handle
    
    properties
        fig                    % Main figure
        tab_group              % Tab group container
        tabs                   % Structure of tab handles
        handles                % All UI component handles
        config                 % Configuration structure
        terminal_log           % Cell array of terminal output
        figures_list           % Storage for generated figures
        diary_file             % MATLAB diary file for terminal capture
        diary_timer            % Timer for terminal refresh
        diary_last_size        % Last diary file size
    end
    
    methods
        function app = UIController()
            % Constructor - creates and initializes the UI
            close all;
            
            % Initialize properties
            app.config = app.initialize_default_config();
            app.handles = struct();
            app.terminal_log = {};
            app.figures_list = {};
            
            % Show startup decision dialog
            choice = app.show_startup_dialog();
            
            if strcmp(choice, 'traditional')
                % User chose traditional mode - exit UI
                setappdata(0, 'ui_mode', 'traditional');
                return;
            end

                % Ensure required script folders are on the MATLAB path
                try
                    ui_dir = fileparts(mfilename('fullpath'));
                    scripts_dir = fileparts(ui_dir);
                    addpath(fullfile(scripts_dir, 'Infrastructure'));
                    addpath(fullfile(scripts_dir, 'Methods'));
                catch
                    % If path setup fails, IC preview will report a clear error
                end
            
            % User chose UI mode - create full interface
            % Create main figure with resize callback (maximized)
            % Dark mode theme for professional appearance
            app.fig = uifigure('Name', 'Tsunami Vortex Simulation - Professional Interface', ...
                'WindowState', 'maximized', ...
                'Color', [0.15 0.15 0.15], ...  % Dark background
                'AutoResizeChildren', 'on', ...
                'CloseRequestFcn', @(~,~) app.cleanup());
            
            % Create tab group with relative sizing (fit within maximized window)
            app.tab_group = uitabgroup(app.fig, 'Units', 'normalized', ...
                'Position', [0.01 0.08 0.98 0.88], ...
                'FontSize', 12, 'FontWeight', 'bold');
            
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
                'Color', [0.94 0.94 0.94], ...
                'Visible', 'off');
            
            choice = 'ui';  % Default
            
            % Title
            uilabel(dialog_fig, 'Position', [50 220 500 50], ...
                'Text', 'Choose Simulation Interface', ...
                'FontSize', 18, 'FontWeight', 'bold');
            
            % Description
            uilabel(dialog_fig, 'Position', [50 160 500 40], ...
                'Text', 'How would you like to run the simulation?', ...
                'FontSize', 12);
            
            % UI Mode Button
            uibutton(dialog_fig, 'push', 'Position', [50 80 200 60], ...
                'Text', sprintf('🖥️ UI Mode\n(Full Configuration Interface)'), ...
                'FontSize', 12, ...
                'BackgroundColor', [0.2 0.7 0.3], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) set_choice('ui'));
            
            % Traditional Mode Button
            uibutton(dialog_fig, 'push', 'Position', [300 80 200 60], ...
                'Text', sprintf('📊 Traditional\n(Separate Windows)'), ...
                'FontSize', 12, ...
                'BackgroundColor', [0.3 0.5 0.8], ...
                'FontColor', 'white', ...
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
            app.tabs.config = uitab(app.tab_group, 'Title', '⚙️ Configuration');
            app.create_config_tab();
            
            app.tabs.monitoring = uitab(app.tab_group, 'Title', '📊 Live Monitor');
            app.create_monitoring_tab();
            
            app.tabs.results = uitab(app.tab_group, 'Title', '📈 Results & Figures');
            app.create_results_tab();
        end
        
        function create_control_buttons(~)
            % Control buttons now integrated into readiness checklist
            % (Previously placed at bottom, now in right panel checklist area)
        end
        
        % Tab creation methods
        function create_config_tab(app)
            % Rebuilt configuration tab (grouped, compact, method-aware)
            parent = app.tabs.config;
            parent.Units = 'normalized';
            parent.BackgroundColor = [0.97 0.97 0.99];

            root = uigridlayout(parent, [1 2]);
            root.ColumnWidth = {'1.05x', '1x'};
            root.RowHeight = {'1x'};
            root.Padding = [10 10 10 10];
            root.RowSpacing = 10;
            root.ColumnSpacing = 12;

            left = uipanel(root, 'Title', 'Configuration', 'FontWeight', 'bold');
            right = uipanel(root, 'Title', 'Initial Conditions & Preview', 'FontWeight', 'bold');

            left_layout = uigridlayout(left, [7 1]);
            left_layout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '1x'};
            left_layout.Padding = [10 10 10 10];
            left_layout.RowSpacing = 8;

            % --- Method & Mode ---
            panel_method = uipanel(left_layout, 'Title', 'Method & Mode');
            method_grid = uigridlayout(panel_method, [3 4]);
            method_grid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            method_grid.RowHeight = {'fit', 'fit', 'fit'};
            method_grid.RowSpacing = 6;
            method_grid.Padding = [6 6 6 6];

            uilabel(method_grid, 'Text', 'Method');
            app.handles.method_dropdown = uidropdown(method_grid, ...
                'Items', {'Finite Difference', 'Finite Volume', 'Spectral', 'Variable Bathymetry + Motion'}, ...
                'Value', 'Finite Difference', ...
                'ValueChangedFcn', @(~,~) app.on_method_changed());

            uilabel(method_grid, 'Text', 'Mode');
            app.handles.mode_dropdown = uidropdown(method_grid, ...
                'Items', {'Evolution', 'Convergence', 'Sweep', 'Animation', 'Experimentation'}, ...
                'Value', 'Evolution', ...
                'ValueChangedFcn', @(~,~) app.on_mode_changed());

            uilabel(method_grid, 'Text', 'Boundary');
            app.handles.boundary_label = uilabel(method_grid, 'Text', 'Periodic (x,y)');

            app.handles.bathy_enable = uicheckbox(method_grid, ...
                'Text', 'Use Bathymetry', 'Value', false, ...
                'Visible', 'off', ...
                'ValueChangedFcn', @(~,~) app.on_method_changed());
            app.handles.bathy_file = uieditfield(method_grid, 'text', ...
                'Value', '', 'Placeholder', 'Bathymetry file', ...
                'Visible', 'off');

            app.handles.bathy_browse_btn = uibutton(method_grid, 'Text', 'Browse', ...
                'Visible', 'off', ...
                'ButtonPushedFcn', @(~,~) app.browse_bathymetry_file());

            % --- Grid & Domain ---
            panel_grid = uipanel(left_layout, 'Title', 'Grid & Domain');
            grid_layout = uigridlayout(panel_grid, [3 4]);
            grid_layout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            grid_layout.RowHeight = {'fit', 'fit', 'fit'};
            grid_layout.Padding = [6 6 6 6];

            uilabel(grid_layout, 'Text', 'Nx');
            app.handles.Nx = uieditfield(grid_layout, 'numeric', 'Value', 128, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            uilabel(grid_layout, 'Text', 'Ny');
            app.handles.Ny = uieditfield(grid_layout, 'numeric', 'Value', 128, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            uilabel(grid_layout, 'Text', 'Lx');
            app.handles.Lx = uieditfield(grid_layout, 'numeric', 'Value', 10.0, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            uilabel(grid_layout, 'Text', 'Ly');
            app.handles.Ly = uieditfield(grid_layout, 'numeric', 'Value', 10.0, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            uilabel(grid_layout, 'Text', 'Δ (dx=dy)');
            app.handles.delta = uieditfield(grid_layout, 'numeric', 'Editable', 'on', ...
                'Value', 2, ...
                'ValueChangedFcn', @(~,~) app.update_delta());
            uilabel(grid_layout, 'Text', 'Grid points');
            app.handles.grid_points = uilabel(grid_layout, 'Text', '16384');

            % --- Time & Physics ---
            panel_time = uipanel(left_layout, 'Title', 'Time & Physics');
            time_layout = uigridlayout(panel_time, [2 4]);
            time_layout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            time_layout.RowHeight = {'fit', 'fit'};
            time_layout.Padding = [6 6 6 6];

            uilabel(time_layout, 'Text', 'dt');
            app.handles.dt = uieditfield(time_layout, 'numeric', 'Value', 0.001, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            uilabel(time_layout, 'Text', 'Tfinal');
            app.handles.t_final = uieditfield(time_layout, 'numeric', 'Value', 10.0, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            uilabel(time_layout, 'Text', 'ν');
            app.handles.nu = uieditfield(time_layout, 'numeric', 'Value', 1e-4, ...
                'ValueChangedFcn', @(~,~) app.update_checklist());
            uilabel(time_layout, 'Text', 'Snapshots');
            app.handles.num_snapshots = uieditfield(time_layout, 'numeric', 'Value', 9);

            % --- Simulation Settings ---
            panel_sim = uipanel(left_layout, 'Title', 'Simulation Settings');
            sim_layout = uigridlayout(panel_sim, [3 4]);
            sim_layout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            sim_layout.RowHeight = {'fit', 'fit', 'fit'};
            sim_layout.Padding = [6 6 6 6];

            app.handles.save_csv = uicheckbox(sim_layout, 'Text', 'Save CSV', 'Value', true);
            app.handles.save_mat = uicheckbox(sim_layout, 'Text', 'Save MAT', 'Value', true);
            app.handles.figures_save_png = uicheckbox(sim_layout, 'Text', 'Save PNG', 'Value', true);
            app.handles.figures_save_fig = uicheckbox(sim_layout, 'Text', 'Save FIG', 'Value', false);
            uilabel(sim_layout, 'Text', 'DPI');
            app.handles.figures_dpi = uieditfield(sim_layout, 'numeric', 'Value', 300);
            app.handles.figures_close_after_save = uicheckbox(sim_layout, 'Text', 'Close after save', 'Value', false);
            app.handles.figures_use_owl_saver = uicheckbox(sim_layout, 'Text', 'Use OWL saver', 'Value', true);
            app.handles.create_animations = uicheckbox(sim_layout, 'Text', 'Create animations', 'Value', true);
            app.handles.animation_format = uidropdown(sim_layout, 'Items', {'gif', 'mp4', 'avi'}, 'Value', 'gif');
            app.handles.animation_fps = uieditfield(sim_layout, 'numeric', 'Value', 30);
            app.handles.animation_num_frames = uieditfield(sim_layout, 'numeric', 'Value', 100);

            % --- Convergence Study ---
            panel_conv = uipanel(left_layout, 'Title', 'Convergence Study');
            conv_layout = uigridlayout(panel_conv, [4 4]);
            conv_layout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            conv_layout.RowHeight = {'fit', 'fit', 'fit', 'fit'};
            conv_layout.Padding = [6 6 6 6];

            uilabel(conv_layout, 'Text', 'N coarse');
            app.handles.conv_N_coarse = uieditfield(conv_layout, 'numeric', 'Value', 64);
            uilabel(conv_layout, 'Text', 'N max');
            app.handles.conv_N_max = uieditfield(conv_layout, 'numeric', 'Value', 512);
            uilabel(conv_layout, 'Text', 'Tolerance');
            app.handles.conv_tolerance = uieditfield(conv_layout, 'numeric', 'Value', 1e-2);
            uilabel(conv_layout, 'Text', 'Criterion');
            app.handles.conv_criterion = uidropdown(conv_layout, ...
                'Items', {'l2_relative', 'l2_absolute', 'linf_relative', 'max_vorticity', 'energy_dissipation', 'auto_physical'}, ...
                'Value', 'l2_relative');
            app.handles.conv_binary = uicheckbox(conv_layout, 'Text', 'Binary search', 'Value', true);
            app.handles.conv_use_adaptive = uicheckbox(conv_layout, 'Text', 'Adaptive', 'Value', true);
            uilabel(conv_layout, 'Text', 'Max jumps');
            app.handles.conv_max_jumps = uieditfield(conv_layout, 'numeric', 'Value', 5);
            app.handles.conv_agent_enabled = uicheckbox(conv_layout, 'Text', 'Agent-guided', 'Value', true);

            app.handles.conv_math = uihtml(panel_conv, 'HTMLSource', ...
                "<div style='font-family:Segoe UI;font-size:12px;color:#333;'>" + ...
                "<b style='color:#0066cc;'>Finite Difference | Evolution Mode</b><br>" + ...
                "<b>Convergence Criterion:</b><br>" + ...
                "$$\epsilon_N = \frac{\|\omega_N-\omega_{2N}\|_2}{\|\omega_{2N}\|_2}$$<br>" + ...
                "<span style='font-size:11px;color:#666;'>" + ...
                "Method: <b>Finite Difference</b> | Mode: <b>Evolution</b> | Agent: <b>Yes</b> | Binary: <b>Yes</b>" + ...
                "</span></div>" + ...
                "<script src='https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'></script>");

            % --- Sustainability ---
            panel_sus = uipanel(left_layout, 'Title', 'Sustainability');
            sus_layout = uigridlayout(panel_sus, [2 2]);
            sus_layout.ColumnWidth = {'1x', '1x'};
            sus_layout.RowHeight = {'fit', 'fit'};
            sus_layout.Padding = [6 6 6 6];

            app.handles.enable_monitoring = uicheckbox(sus_layout, 'Text', 'Enable monitoring', 'Value', true);
            uilabel(sus_layout, 'Text', 'Sample interval (s)');
            app.handles.sample_interval = uieditfield(sus_layout, 'numeric', 'Value', 0.5);
            uilabel(sus_layout, 'Text', '');

            % --- Validation ---
            % Moved to readiness checklist area

            % Right panel layout
            right_layout = uigridlayout(right, [3 1]);
            right_layout.RowHeight = {'fit', 'fit', '1x'};
            right_layout.Padding = [10 10 10 10];
            right_layout.RowSpacing = 10;

            % Checklist
            panel_check = uipanel(right_layout, 'Title', 'Readiness Checklist');
            check_layout = uigridlayout(panel_check, [9 2]);
            check_layout.ColumnWidth = {20, '1x'};
            check_layout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            check_layout.Padding = [6 6 6 6];
            check_layout.RowSpacing = 6;

            app.handles.check_grid = uilabel(check_layout, 'Text', '●', 'FontSize', 12, 'FontColor', [0.8 0.2 0.2]);
            uilabel(check_layout, 'Text', 'Grid (Nx, Ny)');
            app.handles.check_domain = uilabel(check_layout, 'Text', '●', 'FontSize', 12, 'FontColor', [0.8 0.2 0.2]);
            uilabel(check_layout, 'Text', 'Domain (Lx, Ly)');
            app.handles.check_time = uilabel(check_layout, 'Text', '●', 'FontSize', 12, 'FontColor', [0.8 0.2 0.2]);
            uilabel(check_layout, 'Text', 'Time (dt, Tfinal)');
            app.handles.check_ic = uilabel(check_layout, 'Text', '●', 'FontSize', 12, 'FontColor', [0.8 0.2 0.2]);
            uilabel(check_layout, 'Text', 'Initial condition');
            app.handles.check_conv = uilabel(check_layout, 'Text', '●', 'FontSize', 12, 'FontColor', [0.8 0.2 0.2]);
            uilabel(check_layout, 'Text', 'Convergence settings');
            
            % Add spacer
            uilabel(check_layout, 'Text', '');
            uilabel(check_layout, 'Text', '');
            
            % Action buttons
            app.handles.btn_launch = uibutton(check_layout, 'push', ...
                'Text', '🚀 Launch', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.2 0.8 0.3], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.launch_simulation());
            
            app.handles.btn_export = uibutton(check_layout, 'push', ...
                'Text', '💾 Export Config', ...
                'BackgroundColor', [0.2 0.5 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.export_configuration());
            
            app.handles.btn_save_log = uibutton(check_layout, 'push', ...
                'Text', '📋 Save Log', ...
                'BackgroundColor', [0.9 0.6 0.2], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.save_terminal_log());
            
            uilabel(check_layout, 'Text', '');

            % IC configuration
            panel_ic = uipanel(right_layout, 'Title', 'Initial Condition');
            ic_layout = uigridlayout(panel_ic, [6 4]);
            ic_layout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            ic_layout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            ic_layout.Padding = [6 6 6 6];

            uilabel(ic_layout, 'Text', 'IC Type');
            app.handles.ic_dropdown = uidropdown(ic_layout, ...
                'Items', {'Stretched Gaussian', 'Lamb-Oseen', 'Rankine', 'Lamb Dipole', ...
                          'Taylor-Green', 'Random Turbulence', 'Elliptical Vortex'}, ...
                'Value', 'Stretched Gaussian', ...
                'ValueChangedFcn', @(~,~) app.on_ic_changed());
            uilabel(ic_layout, 'Text', 'Scale Factor');
            app.handles.ic_scale = uieditfield(ic_layout, 'numeric', 'Value', 1.0, ...
                'Limits', [0.1 10.0], ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            uilabel(ic_layout, 'Text', 'Count (N)');
            app.handles.ic_count = uieditfield(ic_layout, 'numeric', 'Value', 1, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());

            app.handles.ic_equation = uitextarea(ic_layout, ...
                'Value', {'ω(x,y) = exp(−ax² − by²)'}, ...
                'Editable', 'off', ...
                'FontSize', 12, 'WordWrap', 'on');

            app.handles.ic_coeff1_label = uilabel(ic_layout, 'Text', 'Coeff 1');
            app.handles.ic_coeff1 = uieditfield(ic_layout, 'numeric', 'Value', 2.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_coeff2_label = uilabel(ic_layout, 'Text', 'Coeff 2');
            app.handles.ic_coeff2 = uieditfield(ic_layout, 'numeric', 'Value', 0.2, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_coeff3_label = uilabel(ic_layout, 'Text', 'Coeff 3');
            app.handles.ic_coeff3 = uieditfield(ic_layout, 'numeric', 'Value', 0.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            app.handles.ic_coeff4_label = uilabel(ic_layout, 'Text', 'Coeff 4');
            app.handles.ic_coeff4 = uieditfield(ic_layout, 'numeric', 'Value', 0.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            uilabel(ic_layout, 'Text', 'Center x₀');
            app.handles.ic_center_x = uieditfield(ic_layout, 'numeric', 'Value', 0.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());
            uilabel(ic_layout, 'Text', 'Center y₀');
            app.handles.ic_center_y = uieditfield(ic_layout, 'numeric', 'Value', 0.0, ...
                'ValueChangedFcn', @(~,~) app.update_ic_preview());

            % IC preview
            panel_preview = uipanel(right_layout, 'Title', 'IC Preview (t=0)');
            preview_layout = uigridlayout(panel_preview, [1 1]);
            preview_layout.Padding = [6 6 6 6];
            app.handles.ic_preview_axes = uiaxes(preview_layout);
            app.handles.ic_preview_axes.Color = [0.15 0.15 0.15];
            app.handles.ic_preview_axes.XColor = [0.9 0.9 0.9];
            app.handles.ic_preview_axes.YColor = [0.9 0.9 0.9];
            app.handles.ic_preview_axes.ZColor = [0.9 0.9 0.9];
            app.handles.ic_preview_axes.GridColor = [0.3 0.3 0.3];

            % Initialize display
            app.update_delta();
            app.update_ic_fields();
            app.update_ic_preview();
            app.update_checklist();
        end
        
        
        function create_monitoring_tab(app)
            % Live execution (side-by-side) + convergence + MATLAB terminal (split layout)
            parent = app.tabs.monitoring;
            parent.Units = 'normalized';
            parent.BackgroundColor = [0.15 0.15 0.15];  % Dark mode

            root = uigridlayout(parent, [3 3]);
            root.ColumnWidth = {'1x', '1x', '1x'};
            root.RowHeight = {'1x', '1x', '1x'};
            root.Padding = [10 10 10 10];
            root.RowSpacing = 10;
            root.ColumnSpacing = 12;

            % Panel 1: Live Execution Monitor (Iterations vs Time) - TOP LEFT
            panel_exec1 = uipanel(root, 'Title', '⚡ Iterations vs Time', ...
                'BackgroundColor', [0.20 0.20 0.20]);
            panel_exec1.Layout.Row = 1;
            panel_exec1.Layout.Column = 1;
            exec_layout1 = uigridlayout(panel_exec1, [1 1]);
            exec_layout1.Padding = [6 6 6 6];
            
            app.handles.exec_monitor_axes1 = uiaxes(exec_layout1);
            app.handles.exec_monitor_axes1.Color = [0.15 0.15 0.15];
            app.handles.exec_monitor_axes1.XColor = [0.9 0.9 0.9];
            app.handles.exec_monitor_axes1.YColor = [0.9 0.9 0.9];
            app.handles.exec_monitor_axes1.ZColor = [0.9 0.9 0.9];
            app.handles.exec_monitor_axes1.GridColor = [0.3 0.3 0.3];
            title(app.handles.exec_monitor_axes1, 'Iterations vs Time (no data yet)', 'Color', [0.9 0.9 0.9]);
            xlabel(app.handles.exec_monitor_axes1, 'Time (s)', 'Color', [0.9 0.9 0.9]);
            ylabel(app.handles.exec_monitor_axes1, 'Iterations', 'Color', [0.9 0.9 0.9]);
            grid(app.handles.exec_monitor_axes1, 'on');

            % Panel 2: Live Execution Monitor (Iterations/Second vs Time) - TOP MIDDLE
            panel_exec2 = uipanel(root, 'Title', '⚡ Iterations/Second vs Time', ...
                'BackgroundColor', [0.20 0.20 0.20]);
            panel_exec2.Layout.Row = 1;
            panel_exec2.Layout.Column = 2;
            exec_layout2 = uigridlayout(panel_exec2, [1 1]);
            exec_layout2.Padding = [6 6 6 6];
            
            app.handles.exec_monitor_axes2 = uiaxes(exec_layout2);
            app.handles.exec_monitor_axes2.Color = [0.15 0.15 0.15];
            app.handles.exec_monitor_axes2.XColor = [0.9 0.9 0.9];
            app.handles.exec_monitor_axes2.YColor = [0.9 0.9 0.9];
            app.handles.exec_monitor_axes2.ZColor = [0.9 0.9 0.9];
            app.handles.exec_monitor_axes2.GridColor = [0.3 0.3 0.3];
            title(app.handles.exec_monitor_axes2, 'Iterations/Second vs Time (no data yet)', 'Color', [0.9 0.9 0.9]);
            xlabel(app.handles.exec_monitor_axes2, 'Time (s)', 'Color', [0.9 0.9 0.9]);
            ylabel(app.handles.exec_monitor_axes2, 'Iterations/s', 'Color', [0.9 0.9 0.9]);
            grid(app.handles.exec_monitor_axes2, 'on');

            % Panel 3: Terminal (TOP RIGHT)
            panel_terminal = uipanel(root, 'Title', '🖥️ MATLAB Terminal', ...
                'BackgroundColor', [0.20 0.20 0.20]);
            panel_terminal.Layout.Row = 1;
            panel_terminal.Layout.Column = 3;
            terminal_layout = uigridlayout(panel_terminal, [1 1]);
            terminal_layout.Padding = [6 6 6 6];

            app.handles.terminal_output = uitextarea(terminal_layout, ...
                'Value', {'MATLAB terminal capture enabled', 'Output will appear here.'}, ...
                'Editable', 'off', ...
                'FontName', 'Courier New', ...
                'FontSize', 10, ...
                'BackgroundColor', [0.08 0.08 0.08], ...
                'FontColor', [0.2 1.0 0.2]);

            % Panel 4: Convergence Monitor (BOTTOM LEFT-MIDDLE)
            panel_conv = uipanel(root, 'Title', '📉 Convergence Monitor: Refinement vs Iteration', ...
                'BackgroundColor', [0.20 0.20 0.20]);
            panel_conv.Layout.Row = [2 3];
            panel_conv.Layout.Column = 1;
            conv_layout = uigridlayout(panel_conv, [1 1]);
            conv_layout.Padding = [6 6 6 6];

            app.handles.conv_monitor_axes = uiaxes(conv_layout);
            app.handles.conv_monitor_axes.Color = [0.15 0.15 0.15];
            app.handles.conv_monitor_axes.XColor = [0.9 0.9 0.9];
            app.handles.conv_monitor_axes.YColor = [0.9 0.9 0.9];
            app.handles.conv_monitor_axes.ZColor = [0.9 0.9 0.9];
            app.handles.conv_monitor_axes.GridColor = [0.3 0.3 0.3];
            title(app.handles.conv_monitor_axes, 'Refinement (no data yet)', 'Color', [0.9 0.9 0.9]);
            xlabel(app.handles.conv_monitor_axes, 'Iteration', 'Color', [0.9 0.9 0.9]);
            ylabel(app.handles.conv_monitor_axes, 'Refinement Level (integers)', 'Color', [0.9 0.9 0.9]);
            grid(app.handles.conv_monitor_axes, 'on');
            % Keep Y-axis at integers only
            app.handles.conv_monitor_axes.YTickMode = 'manual';

            % Panel 5: Simulation Metrics (BOTTOM RIGHT)
            panel_metrics = uipanel(root, 'Title', '📊 Simulation Metrics', ...
                'BackgroundColor', [0.20 0.20 0.20]);
            panel_metrics.Layout.Row = [2 3];
            panel_metrics.Layout.Column = [2 3];
            metrics_layout = uigridlayout(panel_metrics, [4 2]);
            metrics_layout.ColumnWidth = {'1x', '1x'};
            metrics_layout.RowHeight = {'fit', 'fit', 'fit', 'fit'};
            metrics_layout.Padding = [6 6 6 6];

            uilabel(metrics_layout, 'Text', 'Time Elapsed:', 'FontColor', [0.9 0.9 0.9]);
            app.handles.metrics_time_elapsed = uilabel(metrics_layout, 'Text', '0.0 s', 'FontColor', [0.3 1.0 0.3]);
            
            uilabel(metrics_layout, 'Text', 'Grid Size:', 'FontColor', [0.9 0.9 0.9]);
            app.handles.metrics_grid = uilabel(metrics_layout, 'Text', '128×128', 'FontColor', [0.3 1.0 0.3]);
            
            uilabel(metrics_layout, 'Text', 'CPU Usage:', 'FontColor', [0.9 0.9 0.9]);
            app.handles.metrics_cpu = uilabel(metrics_layout, 'Text', '-- %', 'FontColor', [0.3 1.0 0.3]);
            
            uilabel(metrics_layout, 'Text', 'Memory:', 'FontColor', [0.9 0.9 0.9]);
            app.handles.metrics_memory = uilabel(metrics_layout, 'Text', '-- MB', 'FontColor', [0.3 1.0 0.3]);
        end
        
        function create_terminal_tab(~)
            % Terminal tab removed (merged into monitoring tab)
        end
        
        function create_results_tab(app)
            % Results & Figures with dropdown + tabbed gallery
            parent = app.tabs.results;
            parent.Units = 'normalized';
            parent.BackgroundColor = [0.97 0.97 0.99];

            root = uigridlayout(parent, [2 1]);
            root.RowHeight = {'1x', 'fit'};
            root.Padding = [10 10 10 10];
            root.RowSpacing = 10;

            panel_fig = uipanel(root, 'Title', 'Figures');
            fig_layout = uigridlayout(panel_fig, [2 1]);
            fig_layout.RowHeight = {'fit', '1x'};
            fig_layout.Padding = [6 6 6 6];

            control_row = uigridlayout(fig_layout, [1 5]);
            control_row.ColumnWidth = {'fit', '1x', 'fit', 'fit', 'fit'};
            control_row.Padding = [0 0 0 0];

            uilabel(control_row, 'Text', 'Figure');
            app.handles.figure_selector = uidropdown(control_row, ...
                'Items', {'No figures yet'}, ...
                'Value', 'No figures yet', ...
                'ValueChangedFcn', @(~,~) app.on_figure_selected());
            uibutton(control_row, 'Text', '💾 Save Current', ...
                'ButtonPushedFcn', @(~,~) app.save_current_figure());
            uibutton(control_row, 'Text', '📦 Export All', ...
                'ButtonPushedFcn', @(~,~) app.export_all_figures());
            uibutton(control_row, 'Text', '🔄 Refresh', ...
                'ButtonPushedFcn', @(~,~) app.refresh_figures());

            app.handles.figure_tabs = uitabgroup(fig_layout, 'Units', 'normalized');
            tab = uitab(app.handles.figure_tabs, 'Title', 'Preview');
            app.handles.figure_axes = uiaxes(tab);
            title(app.handles.figure_axes, 'Figures will appear here during simulation');

            panel_metrics = uipanel(root, 'Title', 'Metrics & History');
            metrics_layout = uigridlayout(panel_metrics, [1 1]);
            metrics_layout.Padding = [6 6 6 6];
            app.handles.metrics_text = uitextarea(metrics_layout, ...
                'Value', {'Run a simulation to populate metrics and history.'}, ...
                'Editable', 'off');
        end
        
        % Action methods
        function launch_simulation(app)
            % Collect all configuration from UI
            try
                % Method and Mode
                method_val = app.handles.method_dropdown.Value;
                switch method_val
                    case 'Finite Difference'
                        app.config.method = 'finite_difference';
                    case 'Finite Volume'
                        app.config.method = 'finite_volume';
                    case 'Spectral'
                        app.config.method = 'spectral';
                    otherwise
                        app.config.method = 'bathymetry';
                end

                mode_val = app.handles.mode_dropdown.Value;
                switch mode_val
                    case 'Evolution'
                        app.config.mode = 'evolution';
                    case 'Convergence'
                        app.config.mode = 'convergence';
                    case 'Sweep'
                        app.config.mode = 'sweep';
                    case 'Animation'
                        app.config.mode = 'animation';
                    otherwise
                        app.config.mode = 'experimentation';
                end
                
                % Parameters
                app.config.Nx = round(app.handles.Nx.Value);
                app.config.Ny = round(app.handles.Ny.Value);
                app.config.Lx = app.handles.Lx.Value;
                app.config.Ly = app.handles.Ly.Value;
                app.config.delta = app.handles.delta.Value;
                app.config.use_explicit_delta = false;
                app.config.dt = app.handles.dt.Value;
                app.config.Tfinal = app.handles.t_final.Value;
                app.config.nu = app.handles.nu.Value;
                app.config.num_snapshots = round(app.handles.num_snapshots.Value);
                app.config.analysis_method = app.handles.method_dropdown.Value;

                % Simulation settings
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
                app.config.animation_num_frames = app.handles.animation_num_frames.Value;

                % Bathymetry
                app.config.bathymetry_enabled = app.handles.bathy_enable.Value;
                app.config.bathymetry_file = app.handles.bathy_file.Value;

                % IC - map display name to internal ic_type
                ic_display_name = app.handles.ic_dropdown.Value;
                app.config.ic_type = map_ic_display_to_type(ic_display_name);
                app.config.ic_pattern = app.handles.ic_pattern.Value;
                app.config.ic_count = round(app.handles.ic_count.Value);
                app.config.ic_coeff1 = app.handles.ic_coeff1.Value;
                app.config.ic_coeff2 = app.handles.ic_coeff2.Value;
                app.config.ic_coeff3 = app.handles.ic_coeff3.Value;
                app.config.ic_coeff4 = app.handles.ic_coeff4.Value;
                app.config.ic_center_x = app.handles.ic_center_x.Value;
                app.config.ic_center_y = app.handles.ic_center_y.Value;
                app.config.ic_coeff = [app.config.ic_coeff1, app.config.ic_coeff2, ...
                                        app.config.ic_coeff3, app.config.ic_coeff4, ...
                                        app.config.ic_center_x, app.config.ic_center_y];

                % Convergence
                app.config.convergence_N_coarse = app.handles.conv_N_coarse.Value;
                app.config.convergence_N_max = app.handles.conv_N_max.Value;
                app.config.convergence_tol = app.handles.conv_tolerance.Value;
                app.config.convergence_criterion_type = app.handles.conv_criterion.Value;
                app.config.convergence_binary = app.handles.conv_binary.Value;
                app.config.convergence_use_adaptive = app.handles.conv_use_adaptive.Value;
                app.config.convergence_max_jumps = app.handles.conv_max_jumps.Value;
                app.config.convergence_agent_enabled = app.handles.conv_agent_enabled.Value;

                % Sustainability
                app.config.enable_monitoring = app.handles.enable_monitoring.Value;
                app.config.sample_interval = app.handles.sample_interval.Value;
                
                % Store config for Analysis.m
                setappdata(app.fig, 'ui_config', app.config);
                
                % Log
                app.append_to_terminal(sprintf('✓ Configuration collected for %s method in %s mode', ...
                    app.config.method, app.config.mode));
                app.append_to_terminal(sprintf('  Grid: %d × %d, dt=%.4f, T=%.2f', ...
                    app.config.Nx, app.config.Ny, app.config.dt, app.config.Tfinal));
                
                % Switch to monitoring/logs tab
                app.tab_group.SelectedTab = app.tabs.monitoring;
                
            catch ME
                app.append_to_terminal(sprintf('✗ Error collecting configuration: %s', ME.message));
                uialert(app.fig, ME.message, 'Configuration Error', 'icon', 'error');
            end
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
                app.append_to_terminal('✓ All parameters validated successfully');
            else
                msg = sprintf('Found %d validation error(s):\n\n• %s', ...
                    length(errors), strjoin(errors, '\n• '));
                uialert(app.fig, msg, 'Validation Errors', 'icon', 'error');
                app.append_to_terminal(sprintf('✗ Validation errors: %s', strjoin(errors, ', ')));
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
            is_bathy = strcmp(method_val, 'Variable Bathymetry + Motion');
            
            switch method_val
                case 'Finite Difference'
                    app.handles.boundary_label.Text = 'Periodic (x,y)';
                case 'Finite Volume'
                    app.handles.boundary_label.Text = 'Periodic (x,y)';
                case 'Spectral'
                    app.handles.boundary_label.Text = 'Periodic (x,y)';
                case 'Variable Bathymetry + Motion'
                    app.handles.boundary_label.Text = 'Periodic (x,y) + Bathymetry';
            end

            app.handles.bathy_enable.Visible = app.on_off(is_bathy);
            app.handles.bathy_file.Visible = app.on_off(is_bathy);
            app.handles.bathy_browse_btn.Visible = app.on_off(is_bathy);
            
            if ~is_bathy
                app.handles.bathy_enable.Value = false;
                app.handles.bathy_file.Value = '';
            end
            
            % Update convergence display with selected method
            app.update_convergence_display();
            app.update_ic_preview();
        end

        function on_mode_changed(app)
            mode_val = app.handles.mode_dropdown.Value;
            conv_on = strcmp(mode_val, 'Convergence');
            
            app.handles.conv_N_coarse.Enable = app.on_off(conv_on);
            app.handles.conv_N_max.Enable = app.on_off(conv_on);
            app.handles.conv_tolerance.Enable = app.on_off(conv_on);
            app.handles.conv_criterion.Enable = app.on_off(conv_on);
            app.handles.conv_binary.Enable = app.on_off(conv_on);
            app.handles.conv_use_adaptive.Enable = app.on_off(conv_on);
            app.handles.conv_max_jumps.Enable = app.on_off(conv_on);
            app.handles.conv_agent_enabled.Enable = app.on_off(conv_on);
            
            % Update convergence display when mode changes
            app.update_convergence_display();
            app.update_checklist();
        end

        function update_checklist(app)
            % Update readiness checklist lights
            grid_ok = app.handles.Nx.Value >= 2 && app.handles.Ny.Value >= 2;
            domain_ok = app.handles.Lx.Value > 0 && app.handles.Ly.Value > 0;
            time_ok = app.handles.dt.Value > 0 && app.handles.t_final.Value > 0;
            ic_ok = ~isempty(app.handles.ic_dropdown.Value);
            conv_ok = true;
            if strcmp(app.handles.mode_dropdown.Value, 'Convergence')
                conv_ok = app.handles.conv_N_max.Value > app.handles.conv_N_coarse.Value;
            end

            app.handles.check_grid.FontColor = app.bool_to_color(grid_ok);
            app.handles.check_domain.FontColor = app.bool_to_color(domain_ok);
            app.handles.check_time.FontColor = app.bool_to_color(time_ok);
            app.handles.check_ic.FontColor = app.bool_to_color(ic_ok);
            app.handles.check_conv.FontColor = app.bool_to_color(conv_ok);
        end

        function update_convergence_display(app)
            % Update convergence criterion display to include selected method
            method_val = app.handles.method_dropdown.Value;
            mode_val = app.handles.mode_dropdown.Value;
            
            % Build HTML with method information
            html_content = sprintf([ ...
                "<div style='font-family:Segoe UI;font-size:12px;color:#333;'>" ...
                "<b style='color:#0066cc;'>%s | %s Mode</b><br>" ...
                "<b>Convergence Criterion:</b><br>" ...
                "$$\\epsilon_N = \\frac{\\|\\omega_N-\\omega_{2N}\\|_2}{\\|\\omega_{2N}\\|_2}$$<br>" ...
                "<span style='font-size:11px;color:#666;'>" ...
                "Method: <b>%s</b> | Mode: <b>%s</b> | Agent: <b>%s</b> | Binary: <b>%s</b>" ...
                "</span></div>" ...
                "<script src='https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'></script>"], ...
                method_val, mode_val, method_val, mode_val, ...
                app.to_yes_no(app.handles.conv_agent_enabled.Value), ...
                app.to_yes_no(app.handles.conv_binary.Value));
            
            % Update the convergence criterion display
            if isfield(app.handles, 'conv_math') && ishghandle(app.handles.conv_math)
                app.handles.conv_math.HTMLSource = html_content;
            end
        end

        function color = bool_to_color(~, ok)
            if ok
                color = [0.1 0.7 0.2];
            else
                color = [0.8 0.2 0.2];
            end
        end

        function state = on_off(~, tf)
            if tf
                state = 'on';
            else
                state = 'off';
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
                    config_export.method = 'bathymetry';
            end

            mode_val = app.handles.mode_dropdown.Value;
            switch mode_val
                case 'Evolution'
                    config_export.mode = 'evolution';
                case 'Convergence'
                    config_export.mode = 'convergence';
                case 'Sweep'
                    config_export.mode = 'sweep';
                case 'Animation'
                    config_export.mode = 'animation';
                otherwise
                    config_export.mode = 'experimentation';
            end

            config_export.Nx = round(app.handles.Nx.Value);
            config_export.Ny = round(app.handles.Ny.Value);
            config_export.dt = app.handles.dt.Value;
            config_export.t_final = app.handles.t_final.Value;
            config_export.nu = app.handles.nu.Value;
            config_export.ic_type = map_ic_display_to_type(app.handles.ic_dropdown.Value);
            config_export.ic_coeff1 = app.handles.ic_coeff1.Value;
            config_export.ic_coeff2 = app.handles.ic_coeff2.Value;
            config_export.ic_coeff3 = app.handles.ic_coeff3.Value;
            config_export.ic_coeff4 = app.handles.ic_coeff4.Value;
            config_export.ic_center_x = app.handles.ic_center_x.Value;
            config_export.ic_center_y = app.handles.ic_center_y.Value;
            config_export.bathymetry_enabled = app.handles.bathy_enable.Value;
            config_export.bathymetry_file = app.handles.bathy_file.Value;
            config_export.ic_coeff = [config_export.ic_coeff1, config_export.ic_coeff2, ...
                                       config_export.ic_coeff3, config_export.ic_coeff4, ...
                                       config_export.ic_center_x, config_export.ic_center_y];
            
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
        
        function save_terminal_log(app)
            if isempty(app.terminal_log)
                uialert(app.fig, 'No terminal output to save', 'Empty Log', 'icon', 'warning');
                return;
            end
            
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
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
        
        function append_to_terminal(app, message)
            % Append message to terminal with timestamp
            % Defensive: checks if terminal_output exists before updating
            timestamp = datestr(now, 'HH:MM:SS');
            formatted_msg = sprintf('[%s] %s', timestamp, message);
            
            app.terminal_log{end+1} = formatted_msg;
            
            % Only update UI if terminal_output has been created
            if isfield(app.handles, 'terminal_output') && ishghandle(app.handles.terminal_output)
                current_text = app.handles.terminal_output.Value;
                if isstring(current_text)
                    current_text = cellstr(current_text);
                end
                if ~iscell(current_text)
                    current_text = {};
                end
                
                current_text{end+1} = formatted_msg;
                
                % Keep only last 1000 lines
                if length(current_text) > 1000
                    current_text = current_text(end-999:end);
                end
                
                app.handles.terminal_output.Value = current_text;
                drawnow;
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

                if ~isempty(app.diary_timer) && isvalid(app.diary_timer)
                    stop(app.diary_timer);
                    delete(app.diary_timer);
                end

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
            if ~isfield(app.handles, 'terminal_output') || ~ishghandle(app.handles.terminal_output)
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
                % Keep last 400 lines to stay responsive
                if numel(lines) > 400
                    lines = lines(end-399:end);
                end
                app.handles.terminal_output.Value = cellstr(lines);
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
                uilabel(tab, 'Text', sprintf('%s stored. Select in dropdown to preview.', name), ...
                    'Position', [10 10 400 20]);
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
                if ~isempty(app.diary_timer) && isvalid(app.diary_timer)
                    stop(app.diary_timer);
                    delete(app.diary_timer);
                end
                diary off;
                if ishandle(app.fig)
                    delete(app.fig);
                end
            catch
            end
        end
        
        function resize_ui(app)
            % Callback for window resize - maintains proper proportions
            try
                if isempty(app.fig) || ~ishghandle(app.fig)
                    return;
                end
                
                % Tab group uses normalized units and auto-scales
                if ishghandle(app.tab_group)
                    app.tab_group.Units = 'normalized';
                    app.tab_group.Position = [0.007 0.08 0.986 0.91];
                end
                
                % Buttons are now in checklist (normalized layout) - no manual repositioning needed
            catch
                % Silently handle resize errors
            end
        end
        
        % Additional stub methods for button callbacks
        function update_ic_preview(app)
            % Update initial condition preview visualization (2D contour at t=0)
            try
                if ~isfield(app.handles, 'ic_preview_axes') || ~ishghandle(app.handles.ic_preview_axes)
                    return;
                end

                axes(app.handles.ic_preview_axes);
                cla(app.handles.ic_preview_axes);

                Nx = max(16, round(app.handles.Nx.Value));
                Ny = max(16, round(app.handles.Ny.Value));
                n = min(256, max(64, round(min([Nx Ny]))));

                Lx = max(app.handles.Lx.Value, 1e-6);
                Ly = max(app.handles.Ly.Value, 1e-6);
                [X, Y] = meshgrid(linspace(-Lx/2, Lx/2, n), linspace(-Ly/2, Ly/2, n));

                c1 = app.handles.ic_coeff1.Value;
                c2 = app.handles.ic_coeff2.Value;
                c3 = app.handles.ic_coeff3.Value;
                c4 = app.handles.ic_coeff4.Value;
                x0 = app.handles.ic_center_x.Value;
                y0 = app.handles.ic_center_y.Value;
                n_vort = max(1, round(app.handles.ic_count.Value));

                ic_display = app.handles.ic_dropdown.Value;
                ic_type = map_ic_display_to_type(ic_display);

                % Vortex centers
                centers = [x0, y0];
                if n_vort > 1
                    % Grid dispersion pattern
                    theta = linspace(0, 2*pi, n_vort+1); theta(end) = [];
                    centers = [0.3*Lx*cos(theta(:)), 0.3*Ly*sin(theta(:))];
                end

                Z = zeros(size(X));
                switch ic_type
                    case 'stretched_gaussian'
                        Z = exp(-c1*(X-x0).^2 - c2*(Y-y0).^2);
                    case 'lamb_oseen'
                        Gamma = c1; t0 = max(c2, 1e-6); nu = max(c3, 1e-8);
                        for i = 1:size(centers,1)
                            R2 = (X-centers(i,1)).^2 + (Y-centers(i,2)).^2;
                            Z = Z + (Gamma/(4*pi*nu*t0)) * exp(-R2/(4*nu*t0));
                        end
                    case 'rankine'
                        omega0 = c1; rc = max(c2, 1e-6);
                        for i = 1:size(centers,1)
                            R = sqrt((X-centers(i,1)).^2 + (Y-centers(i,2)).^2);
                            Z = Z + omega0 * (R <= rc);
                        end
                    case 'lamb_dipole'
                        U = c1; a = max(c2, 1e-6);
                        k = 3.8317 / a;  % first root of J1
                        r = sqrt((X-x0).^2 + (Y-y0).^2);
                        theta = atan2(Y-y0, X-x0);
                        J1ka = besselj(1, k*a);
                        if abs(J1ka) < 1e-8
                            J1ka = 1e-8;
                        end
                        Z = 2*k*U*besselj(1, k*r).*sin(theta)./J1ka;
                        Z(r > a) = 0;
                    case 'taylor_green'
                        k = c1; G = c2;
                        Z = 2*k*G.*sin(k*X).*sin(k*Y);
                    case 'random_turbulence'
                        alpha = c1; E0 = c2; seed = round(c3);
                        rng(seed);
                        Z = zeros(size(X));
                        for k = 1:6
                            phi = 2*pi*rand; psi = 2*pi*rand;
                            Z = Z + (1/k^(alpha/2))*sin(k*X+phi).*cos(k*Y+psi);
                        end
                        Z = E0 * Z;
                    case 'elliptical_vortex'
                        w0 = c1; sx = max(c2, 1e-6); sy = max(c3, 1e-6); th = c4;
                        Xr = (X-x0)*cos(th) + (Y-y0)*sin(th);
                        Yr = -(X-x0)*sin(th) + (Y-y0)*cos(th);
                        Z = w0*exp(-(Xr.^2/(2*sx^2) + Yr.^2/(2*sy^2)));
                    case 'vortex_blob_gaussian'
                        Gamma = c1; R = max(c2, 1e-6);
                        Z = Gamma/(2*pi*R^2) * exp(-((X-x0).^2 + (Y-y0).^2)/(2*R^2));
                    case 'vortex_pair'
                        Gamma = c1; sep = max(c2, 1e-6); R = max(c3, 1e-6);
                        Z = Gamma*exp(-((X-(x0-sep/2)).^2 + (Y-y0).^2)/(2*R^2)) - ...
                            Gamma*exp(-((X-(x0+sep/2)).^2 + (Y-y0).^2)/(2*R^2));
                    case 'multi_vortex'
                        Gamma = c1; R = max(c2, 1e-6);
                        for i = 1:size(centers,1)
                            Z = Z + Gamma/(2*pi*R^2) * exp(-((X-centers(i,1)).^2 + (Y-centers(i,2)).^2)/(2*R^2));
                        end
                    otherwise
                        Z = exp(-((X-x0).^2 + (Y-y0).^2));
                end

                contour(app.handles.ic_preview_axes, X, Y, Z, 12, 'LineWidth', 1.0);
                hold(app.handles.ic_preview_axes, 'on');
                contourf(app.handles.ic_preview_axes, X, Y, Z, 20);
                rectangle(app.handles.ic_preview_axes, 'Position', [-Lx/2 -Ly/2 Lx Ly], ...
                    'EdgeColor', [0.2 0.2 0.2], 'LineStyle', '--');
                hold(app.handles.ic_preview_axes, 'off');

                title(app.handles.ic_preview_axes, sprintf('Initial Vorticity ω(x,y,0): %s', ic_display), ...
                    'FontSize', 11, 'FontWeight', 'bold');
                xlabel(app.handles.ic_preview_axes, 'x', 'FontSize', 10);
                ylabel(app.handles.ic_preview_axes, 'y', 'FontSize', 10);
                colormap(app.handles.ic_preview_axes, 'turbo');
                colorbar(app.handles.ic_preview_axes);
                axis(app.handles.ic_preview_axes, 'equal');
                grid(app.handles.ic_preview_axes, 'on');

                app.update_checklist();
                app.append_to_terminal(sprintf('✓ IC preview updated (t=0, ω_max=%.3f)', max(Z, [], 'all')));
            catch ME
                app.append_to_terminal(sprintf('✗ Error updating IC preview: %s', ME.message));
            end
        end

        function on_ic_changed(app)
            % Update IC field labels and preview when IC selection changes
            app.update_ic_fields();
            app.update_ic_preview();
        end

        function update_ic_fields(app)
            % Update coefficient labels, visibility, and equation text for selected IC
            ic_display = app.handles.ic_dropdown.Value;
            ic_type = map_ic_display_to_type(ic_display);
            
            % Default visibility
            app.handles.ic_coeff1.Visible = 'on';
            app.handles.ic_coeff2.Visible = 'on';
            app.handles.ic_coeff3.Visible = 'on';
            app.handles.ic_coeff4.Visible = 'on';
            app.handles.ic_coeff1_label.Visible = 'on';
            app.handles.ic_coeff2_label.Visible = 'on';
            app.handles.ic_coeff3_label.Visible = 'on';
            app.handles.ic_coeff4_label.Visible = 'on';
            
            switch ic_type
                case 'stretched_gaussian'
                    app.handles.ic_coeff1_label.Text = 'x stretch (a):';
                    app.handles.ic_coeff2_label.Text = 'y stretch (b):';
                    app.handles.ic_equation.Value = {'ω(x,y) = exp(−ax² − by²)'};
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                case 'lamb_oseen'
                    app.handles.ic_coeff1_label.Text = 'Γ (circulation):';
                    app.handles.ic_coeff2_label.Text = 't₀ (time):';
                    app.handles.ic_coeff3_label.Text = 'ν (viscosity):';
                    app.handles.ic_equation.Value = {'ω(r,t₀) = Γ/(4πνt₀) exp(−r²/4νt₀)'};
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                case 'rankine'
                    app.handles.ic_coeff1_label.Text = 'ω₀ (core):';
                    app.handles.ic_coeff2_label.Text = 'r_c (radius):';
                    app.handles.ic_equation.Value = {'ω = ω₀ for r ≤ r_c, 0 otherwise'};
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                case 'lamb_dipole'
                    app.handles.ic_coeff1_label.Text = 'U (speed):';
                    app.handles.ic_coeff2_label.Text = 'a (radius):';
                    app.handles.ic_equation.Value = {'ω = 2kU·J₁(kr)·sin(θ)/J₁(ka)'};
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                case 'taylor_green'
                    app.handles.ic_coeff1_label.Text = 'k (wavenumber):';
                    app.handles.ic_coeff2_label.Text = 'Γ (strength):';
                    app.handles.ic_equation.Value = {'ω = 2kΓ·sin(kx)·sin(ky)'};
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                case 'random_turbulence'
                    app.handles.ic_coeff1_label.Text = 'α (spectrum):';
                    app.handles.ic_coeff2_label.Text = 'E₀ (energy):';
                    app.handles.ic_coeff3_label.Text = 'seed:';
                    app.handles.ic_equation.Value = {'|ω̂ₖ| ∝ k^(−α/2) with random phases'};
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                case 'elliptical_vortex'
                    app.handles.ic_coeff1_label.Text = 'ω₀ (peak):';
                    app.handles.ic_coeff2_label.Text = 'σx:';
                    app.handles.ic_coeff3_label.Text = 'σy:';
                    app.handles.ic_coeff4_label.Text = 'θ (rad):';
                    app.handles.ic_equation.Value = {'ω = ω₀·exp(−x_r²/(2σx²) − y_r²/(2σy²))'};
                case 'vortex_blob_gaussian'
                    app.handles.ic_coeff1_label.Text = 'Γ (circulation):';
                    app.handles.ic_coeff2_label.Text = 'R (radius):';
                    app.handles.ic_coeff3_label.Text = 'x₀:';
                    app.handles.ic_coeff4_label.Text = 'y₀:';
                    app.handles.ic_equation.Value = {'ω = Γ/(2πR²)·exp(−r²/(2R²))'};
                case 'vortex_pair'
                    app.handles.ic_coeff1_label.Text = 'Γ (circulation):';
                    app.handles.ic_coeff2_label.Text = 'separation:';
                    app.handles.ic_coeff3_label.Text = 'R (radius):';
                    app.handles.ic_equation.Value = {'Counter-rotating vortex pair'};
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                case 'multi_vortex'
                    app.handles.ic_coeff1_label.Text = 'Γ (circulation):';
                    app.handles.ic_coeff2_label.Text = 'R (radius):';
                    app.handles.ic_coeff3.Visible = 'off';
                    app.handles.ic_coeff4.Visible = 'off';
                    app.handles.ic_coeff3_label.Visible = 'off';
                    app.handles.ic_coeff4_label.Visible = 'off';
                    app.handles.ic_equation.Value = {'ω = Σᵢ₌₁ᴺ ωᵢ(r−rᵢ)  [Multi-vortex]'};
            end
        end
        
        function run_convergence_test(app)
            % Run a quick convergence test
            app.append_to_terminal('🔧 Convergence test would run here (integrate with Analysis.m)');
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
    
    methods (Static)
        function config = initialize_default_config()
            % Initialize default configuration by loading from create_default_parameters.m
            % This ensures UIController always uses the authoritative defaults
            try
                default_params = create_default_parameters();
                % Extract key parameters from defaults
                config = struct();
                config.method = default_params.analysis_method;
                config.mode = 'evolution';
                config.Nx = default_params.Nx;
                config.Ny = default_params.Ny;
                config.Lx = default_params.Lx;
                config.Ly = default_params.Ly;
                config.delta = default_params.delta;
                config.use_explicit_delta = default_params.use_explicit_delta;
                config.dt = default_params.dt;
                config.t_final = default_params.Tfinal;
                config.nu = default_params.nu;
                config.num_snapshots = default_params.num_snapshots;
                config.ic_type = default_params.ic_type;
                config.ic_coeff = default_params.ic_coeff;
                config.create_animations = default_params.create_animations;
                config.animation_format = default_params.animation_format;
                config.animation_fps = default_params.animation_fps;
                config.bathymetry_enabled = default_params.bathymetry_enabled;
            catch ME
                % Fallback to hardcoded defaults if create_default_parameters is not available
                warning(ME.identifier, '%s', ME.message);
                config = struct();
                config.method = 'Finite Difference';
                config.mode = 'evolution';
                config.Nx = 128;
                config.Ny = 128;
                config.Lx = 10;
                config.Ly = 10;
                config.delta = 2;
                config.use_explicit_delta = true;
                config.dt = 0.01;
                config.t_final = 8.0;
                config.nu = 1e-6;
                config.num_snapshots = 9;
                config.ic_type = "stretched_gaussian";
                config.ic_coeff = [2, 0.2];
                config.create_animations = true;
                config.animation_format = 'gif';
                config.animation_fps = 30;
                config.bathymetry_enabled = false;
            end
        end
    end
end

function ic_type = map_ic_display_to_type(display_name)
    % Map UI display names to internal ic_type values
    % This ensures the display names are human-friendly while 
    % the actual ic_type values match the initialise_omega switch cases
    
    switch display_name
        case 'Stretched Gaussian'
            ic_type = 'stretched_gaussian';
        case 'Vortex Blob'
            ic_type = 'vortex_blob_gaussian';
        case 'Vortex Pair'
            ic_type = 'vortex_pair';
        case 'Multi-Vortex'
            ic_type = 'multi_vortex';
        case 'Lamb-Oseen'
            ic_type = 'lamb_oseen';
        case 'Rankine'
            ic_type = 'rankine';
        case 'Lamb Dipole'
            ic_type = 'lamb_dipole';
        case 'Taylor-Green'
            ic_type = 'taylor_green';
        case 'Random Turbulence'
            ic_type = 'random_turbulence';
        case 'Elliptical Vortex'
            ic_type = 'elliptical_vortex';
        otherwise
            % Fallback: try to use display_name directly if it's a valid ic_type
            ic_type = lower(display_name);
    end
end
