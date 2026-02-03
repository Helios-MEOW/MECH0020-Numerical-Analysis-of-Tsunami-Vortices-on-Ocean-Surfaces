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
            
            % User chose UI mode - create full interface
            % Create main figure with resize callback (maximized)
            app.fig = uifigure('Name', 'Tsunami Vortex Simulation Control Panel', ...
                'Position', [0 0 1920 1080], ...
                'WindowState', 'maximized', ...
                'Color', [0.92 0.92 0.94], ...
                'AutoResizeChildren', 'off', ...
                'CloseRequestFcn', @(~,~) app.cleanup(), ...
                'SizeChangedFcn', @(~,~) app.resize_ui());
            
            % Create tab group with relative sizing (fit within maximized window)
            app.tab_group = uitabgroup(app.fig, 'Units', 'normalized', ...
                'Position', [0.01 0.08 0.98 0.88], ...
                'FontSize', 12, 'FontWeight', 'bold');
            
            % Create all tabs
            app.create_all_tabs();
            
            % Create control buttons
            app.create_control_buttons();
            
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
            
            app.tabs.sustainability = uitab(app.tab_group, 'Title', '🌱 Sustainability');
            app.create_sustainability_tab();
            
            app.tabs.monitoring = uitab(app.tab_group, 'Title', '📊 Live Monitoring');
            app.create_monitoring_tab();
            
            app.tabs.terminal = uitab(app.tab_group, 'Title', '🖥️ Terminal & Logs');
            app.create_terminal_tab();
            
            app.tabs.results = uitab(app.tab_group, 'Title', '📈 Results & Figures');
            app.create_results_tab();
        end
        
        function create_control_buttons(app)
            % Create launch, export, and save log buttons with enhanced styling
            app.handles.btn_launch = uibutton(app.fig, 'push', ...
                'Position', [1100 20 250 50], ...
                'Text', '🚀 Launch Simulation', ...
                'FontSize', 14, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.2 0.8 0.3], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.launch_simulation());
            
            app.handles.btn_export = uibutton(app.fig, 'push', ...
                'Position', [820 20 250 50], ...
                'Text', '💾 Export Configuration', ...
                'FontSize', 13, ...
                'BackgroundColor', [0.2 0.5 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.export_configuration());
            
            app.handles.btn_save_log = uibutton(app.fig, 'push', ...
                'Position', [540 20 250 50], ...
                'Text', '💾 Save Terminal Log', ...
                'FontSize', 13, ...
                'BackgroundColor', [0.9 0.6 0.2], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.save_terminal_log());
        end
        
        % Tab creation methods
        function create_config_tab(app)
            % Unified configuration tab with all simulation settings (fully scalable + enhanced styling)
            parent = app.tabs.config;
            parent.Units = 'normalized';
            parent.BackgroundColor = [0.97 0.97 0.99];
            
            % === ROW 1: Method (left), Mode (center), IC (right) ===
            panel_method = uipanel(parent, 'Title', 'Analysis Method', ...
                'Units', 'normalized', ...
                'Position', [0.01 0.65 0.32 0.33], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.88 0.95 0.88], 'ForegroundColor', [0.1 0.5 0.1]);
            panel_method.Units = 'pixels';  % Convert to pixels for child positioning
            pos_method = panel_method.Position;
            
            app.handles.method_group = uibuttongroup(panel_method, ...
                'Position', [5 5 pos_method(3)-10 pos_method(4)-25], ...
                'BackgroundColor', [0.88 0.95 0.88]);
            
            h = pos_method(4) - 30;
            uiradiobutton(app.handles.method_group, ...
                'Position', [5 h-30 pos_method(3)-15 25], ...
                'Text', 'Finite Difference (2nd Order)', 'FontSize', 11, 'Value', 1);
            uiradiobutton(app.handles.method_group, ...
                'Position', [5 h-60 pos_method(3)-15 25], ...
                'Text', 'Finite Volume (Conservative)', 'FontSize', 11);
            uiradiobutton(app.handles.method_group, ...
                'Position', [5 h-90 pos_method(3)-15 25], ...
                'Text', 'Spectral (Fourier)', 'FontSize', 11);
            
            % Mode Selection
            panel_mode = uipanel(parent, 'Title', 'Simulation Mode', ...
                'Units', 'normalized', ...
                'Position', [0.34 0.65 0.32 0.33], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.88 0.92 0.99], 'ForegroundColor', [0.1 0.3 0.7]);
            panel_mode.Units = 'pixels';
            pos_mode = panel_mode.Position;
            
            app.handles.mode_dropdown = uidropdown(panel_mode, ...
                'Position', [5 pos_mode(4)-45 pos_mode(3)-10 30], ...
                'Items', {'Evolution', 'Convergence Study', 'Parameter Sweep', 'Animation', 'Experimentation'}, ...
                'Value', 'Evolution', ...
                'FontSize', 11);
            
            app.handles.mode_description = uitextarea(panel_mode, ...
                'Position', [5 5 pos_mode(3)-10 pos_mode(4)-55], ...
                'Value', {'Evolution: Standard time-evolution simulation'}, ...
                'Editable', 'off', ...
                'FontSize', 10, 'BackgroundColor', [0.95 0.97 1]);
            
            % Initial Conditions
            panel_ic = uipanel(parent, 'Title', 'Initial Conditions', ...
                'Units', 'normalized', ...
                'Position', [0.67 0.65 0.32 0.33], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.99 0.94 0.88], 'ForegroundColor', [0.8 0.4 0.1]);
            panel_ic.Units = 'pixels';
            pos_ic = panel_ic.Position;
            
            app.handles.ic_dropdown = uidropdown(panel_ic, ...
                'Position', [5 pos_ic(4)-45 pos_ic(3)-10 30], ...
                'Items', {'Stretched Gaussian (Kutz)', 'Vortex Blob', 'Vortex Pair', 'Multi-Vortex', ...
                          'Lamb-Oseen', 'Rankine', 'Lamb Dipole', 'Taylor-Green', ...
                          'Random Turbulence', 'Elliptical Vortex', 'Custom'}, ...
                'Value', 'Stretched Gaussian (Kutz)', ...
                'FontSize', 11);
            
            uilabel(panel_ic, 'Position', [5 pos_ic(4)-75 40 20], 'Text', 'Coeff 1:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.ic_coeff1 = uieditfield(panel_ic, 'numeric', ...
                'Position', [50 pos_ic(4)-75 pos_ic(3)-60 20], 'Value', 2.0, 'FontSize', 10);
            
            uilabel(panel_ic, 'Position', [5 pos_ic(4)-100 40 20], 'Text', 'Coeff 2:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.ic_coeff2 = uieditfield(panel_ic, 'numeric', ...
                'Position', [50 pos_ic(4)-100 pos_ic(3)-60 20], 'Value', 0.2, 'FontSize', 10);
            
            app.handles.ic_preview_axes = uiaxes(panel_ic, ...
                'Position', [5 25 pos_ic(3)-10 pos_ic(4)-130]);
            title(app.handles.ic_preview_axes, 'IC Preview');
            
            uibutton(panel_ic, 'push', ...
                'Position', [5 5 pos_ic(3)-10 18], ...
                'Text', '🔄 Preview', 'FontSize', 10, ...
                'BackgroundColor', [0.99 0.75 0.5], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.update_ic_preview());
            
            % === ROW 2: Domain & Grid (left), Time Integration (right) ===
            panel_domain = uipanel(parent, 'Title', 'Domain & Grid', ...
                'Units', 'normalized', ...
                'Position', [0.01 0.33 0.48 0.30], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.92 0.97 0.92], 'ForegroundColor', [0.1 0.5 0.1]);
            panel_domain.Units = 'pixels';
            pos_domain = panel_domain.Position;
            
            col1 = 5; col2 = pos_domain(3)/2; w = (pos_domain(3)-15)/2;
            
            uilabel(panel_domain, 'Position', [col1 pos_domain(4)-45 w-5 20], 'Text', 'Lx:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.Lx = uieditfield(panel_domain, 'numeric', ...
                'Position', [col1 pos_domain(4)-70 w-5 20], 'Value', 10.0, 'FontSize', 10);
            
            uilabel(panel_domain, 'Position', [col2 pos_domain(4)-45 w-5 20], 'Text', 'Ly:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.Ly = uieditfield(panel_domain, 'numeric', ...
                'Position', [col2 pos_domain(4)-70 w-5 20], 'Value', 10.0, 'FontSize', 10);
            
            uilabel(panel_domain, 'Position', [col1 pos_domain(4)-100 w-5 20], 'Text', 'Nx:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.Nx = uieditfield(panel_domain, 'numeric', ...
                'Position', [col1 pos_domain(4)-125 w-5 20], 'Value', 128, 'FontSize', 10);
            
            uilabel(panel_domain, 'Position', [col2 pos_domain(4)-100 w-5 20], 'Text', 'Ny:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.Ny = uieditfield(panel_domain, 'numeric', ...
                'Position', [col2 pos_domain(4)-125 w-5 20], 'Value', 128, 'FontSize', 10);
            
            uibutton(panel_domain, 'push', ...
                'Position', [5 5 pos_domain(3)-10 25], ...
                'Text', '✓ Validate Parameters', 'FontSize', 11, ...
                'BackgroundColor', [0.2 0.7 0.3], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.validate_parameters());
            
            % Time Integration
            panel_time = uipanel(parent, 'Title', 'Time Integration', ...
                'Units', 'normalized', ...
                'Position', [0.51 0.33 0.48 0.30], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.92 0.94 0.99], 'ForegroundColor', [0.1 0.3 0.7]);
            panel_time.Units = 'pixels';
            pos_time = panel_time.Position;
            
            col1 = 5; col2 = pos_time(3)/2; w = (pos_time(3)-15)/2;
            
            uilabel(panel_time, 'Position', [col1 pos_time(4)-45 w-5 20], 'Text', 'dt:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.dt = uieditfield(panel_time, 'numeric', ...
                'Position', [col1 pos_time(4)-70 w-5 20], 'Value', 0.001, 'FontSize', 10);
            
            uilabel(panel_time, 'Position', [col2 pos_time(4)-45 w-5 20], 'Text', 'T (final):', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.t_final = uieditfield(panel_time, 'numeric', ...
                'Position', [col2 pos_time(4)-70 w-5 20], 'Value', 10.0, 'FontSize', 10);
            
            uilabel(panel_time, 'Position', [5 pos_time(4)-100 50 20], 'Text', 'Viscosity (ν):', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.nu = uieditfield(panel_time, 'numeric', ...
                'Position', [60 pos_time(4)-100 pos_time(3)-70 20], 'Value', 0.0001, 'FontSize', 10);
            
            % === ROW 3: Convergence (left), Presets (right) ===
            panel_conv = uipanel(parent, 'Title', 'Convergence Study', ...
                'Units', 'normalized', ...
                'Position', [0.01 0.01 0.48 0.30], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.95 0.90 0.99], 'ForegroundColor', [0.5 0.1 0.7]);
            panel_conv.Units = 'pixels';
            pos_conv = panel_conv.Position;
            
            col1 = 5; col2 = pos_conv(3)/2; w = (pos_conv(3)-15)/2;
            
            uilabel(panel_conv, 'Position', [col1 pos_conv(4)-45 w-5 20], 'Text', 'Tolerance:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.conv_tolerance = uieditfield(panel_conv, 'numeric', ...
                'Position', [col1 pos_conv(4)-70 w-5 20], 'Value', 1e-4, 'FontSize', 10);
            
            uilabel(panel_conv, 'Position', [col2 pos_conv(4)-45 w-5 20], 'Text', 'Max Iter:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.conv_max_iter = uieditfield(panel_conv, 'numeric', ...
                'Position', [col2 pos_conv(4)-70 w-5 20], 'Value', 20, 'FontSize', 10);
            
            uilabel(panel_conv, 'Position', [col1 pos_conv(4)-100 w-5 20], 'Text', 'Refinement:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.conv_refinement = uieditfield(panel_conv, 'numeric', ...
                'Position', [col1 pos_conv(4)-125 w-5 20], 'Value', 1.5, 'FontSize', 10);
            
            uibutton(panel_conv, 'push', ...
                'Position', [5 5 pos_conv(3)-10 25], ...
                'Text', '🎯 Run Convergence Test', 'FontSize', 11, ...
                'BackgroundColor', [0.7 0.3 0.8], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.run_convergence_test());
            
            % Quick Presets
            panel_presets = uipanel(parent, 'Title', 'Quick Presets', ...
                'Units', 'normalized', ...
                'Position', [0.51 0.01 0.48 0.30], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.99 0.97 0.92], 'ForegroundColor', [0.8 0.4 0.1]);
            panel_presets.Units = 'pixels';
            pos_presets = panel_presets.Position;
            
            btn_w = (pos_presets(3)-15)/2;
            btn_h = (pos_presets(4)-50)/2;
            
            uibutton(panel_presets, 'push', ...
                'Position', [5 pos_presets(4)-btn_h-30 btn_w btn_h], ...
                'Text', '🎯 Kutz', 'FontSize', 11, ...
                'BackgroundColor', [0.4 0.7 0.9], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.load_preset('kutz'));
            
            uibutton(panel_presets, 'push', ...
                'Position', [5+btn_w+5 pos_presets(4)-btn_h-30 btn_w btn_h], ...
                'Text', '📐 Convergence', 'FontSize', 11, ...
                'BackgroundColor', [0.7 0.3 0.8], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.load_preset('convergence'));
            
            uibutton(panel_presets, 'push', ...
                'Position', [5 5+btn_h btn_w btn_h], ...
                'Text', '🌊 Animation', 'FontSize', 11, ...
                'BackgroundColor', [0.2 0.7 0.9], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.load_preset('animation'));
            
            uibutton(panel_presets, 'push', ...
                'Position', [5+btn_w+5 5+btn_h btn_w btn_h], ...
                'Text', '⚡ Fast Test', 'FontSize', 11, ...
                'BackgroundColor', [1 0.6 0.2], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.load_preset('fast_test'));
            
            % Autorun button - loads preset and launches immediately
            % Positioned at bottom spanning full width with proper margins
            autorun_width = parent.Position(3) - 10;
            if autorun_width > 0
                uibutton(parent, 'push', ...
                    'Position', [5 2 autorun_width 28], ...
                    'Text', '▶ Autorun Kutz (Preconfigured)', 'FontSize', 11, 'FontWeight', 'bold', ...
                    'BackgroundColor', [0.9 0.2 0.2], 'FontColor', 'white', ...
                    'ButtonPushedFcn', @(~,~) app.autorun_kutz());
            end
        end
        
        function create_sustainability_tab(app)
            % Sustainability tab with energy monitoring and analysis (normalized units)
            parent = app.tabs.sustainability;
            parent.Units = 'normalized';
            parent.BackgroundColor = [0.97 0.97 0.99];
            
            % === ROW 1: Energy Monitoring (left), Sustainability Analysis (right) ===
            panel_energy = uipanel(parent, 'Title', 'Energy Monitoring', ...
                'Units', 'normalized', ...
                'Position', [0.01 0.51 0.48 0.47], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.88 0.95 0.88], 'ForegroundColor', [0.1 0.5 0.1]);
            panel_energy.Units = 'pixels';
            pos_energy = panel_energy.Position;
            
            app.handles.enable_monitoring = uicheckbox(panel_energy, ...
                'Position', [10 pos_energy(4)-45 300 25], ...
                'Text', 'Enable Energy Monitoring', ...
                'Value', true, 'FontSize', 11);
            
            uilabel(panel_energy, 'Position', [10 pos_energy(4)-75 140 20], 'Text', 'Sample Interval (s):', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.sample_interval = uieditfield(panel_energy, 'numeric', ...
                'Position', [160 pos_energy(4)-75 80 20], 'Value', 0.5, 'FontSize', 10);
            
            uilabel(panel_energy, 'Position', [10 pos_energy(4)-105 140 20], 'Text', 'Output Directory:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.energy_dir = uieditfield(panel_energy, ...
                'Position', [10 pos_energy(4)-130 pos_energy(3)-20 20], ...
                'Value', '../../Results/Sustainability', 'FontSize', 9);
            
            uibutton(panel_energy, 'push', 'Position', [10 pos_energy(4)-160 pos_energy(3)-20 25], ...
                'Text', '📁 Browse Directory', 'FontSize', 10, ...
                'BackgroundColor', [0.99 0.75 0.5], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.browse_energy_dir());
            
            % Hardware Selection
            uilabel(panel_energy, 'Position', [10 pos_energy(4)-195 140 20], 'Text', 'Monitor Hardware:', 'FontSize', 10, 'FontWeight', 'bold');
            app.handles.monitor_cpu = uicheckbox(panel_energy, ...
                'Position', [10 pos_energy(4)-220 100 20], ...
                'Text', 'CPU Usage', ...
                'Value', true, 'FontSize', 10);
            
            app.handles.monitor_gpu = uicheckbox(panel_energy, ...
                'Position', [120 pos_energy(4)-220 100 20], ...
                'Text', 'GPU Usage', ...
                'Value', false, 'FontSize', 10);
            
            app.handles.monitor_memory = uicheckbox(panel_energy, ...
                'Position', [230 pos_energy(4)-220 120 20], ...
                'Text', 'Memory Usage', ...
                'Value', true, 'FontSize', 10);
            
            % Sustainability Analysis
            panel_sus = uipanel(parent, 'Title', 'Analysis Options', ...
                'Units', 'normalized', ...
                'Position', [0.51 0.51 0.48 0.47], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.95 0.90 0.99], 'ForegroundColor', [0.5 0.1 0.7]);
            panel_sus.Units = 'pixels';
            pos_sus = panel_sus.Position;
            
            app.handles.build_model = uicheckbox(panel_sus, ...
                'Position', [10 pos_sus(4)-45 300 20], ...
                'Text', 'Build Power-Law Energy Model', ...
                'Value', true, 'FontSize', 10);
            
            app.handles.compare_runs = uicheckbox(panel_sus, ...
                'Position', [10 pos_sus(4)-70 300 20], ...
                'Text', 'Compare Across Configurations', ...
                'Value', false, 'FontSize', 10);
            
            app.handles.generate_report = uicheckbox(panel_sus, ...
                'Position', [10 pos_sus(4)-95 300 20], ...
                'Text', 'Generate Sustainability Report', ...
                'Value', true, 'FontSize', 10);
            
            app.handles.export_metrics = uicheckbox(panel_sus, ...
                'Position', [10 pos_sus(4)-120 300 20], ...
                'Text', 'Export Hardware Metrics to CSV', ...
                'Value', true, 'FontSize', 10);
            
            % Action Buttons
            btn_w = (pos_sus(3)-15)/2;
            uibutton(panel_sus, 'push', 'Position', [10 pos_sus(4)-160 btn_w 30], ...
                'Text', '📊 View Dashboard', 'FontSize', 11, ...
                'BackgroundColor', [0.4 0.7 0.9], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.view_energy_dashboard());
            
            uibutton(panel_sus, 'push', 'Position', [10+btn_w+5 pos_sus(4)-160 btn_w 30], ...
                'Text', '💾 Export Data', 'FontSize', 11, ...
                'BackgroundColor', [0.7 0.3 0.8], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.export_energy_data());
            
            % Info Panel
            panel_info = uipanel(parent, 'Title', 'Energy Monitoring Framework', ...
                'Units', 'normalized', ...
                'Position', [0.01 0.01 0.98 0.48], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.99 0.97 0.92], 'ForegroundColor', [0.8 0.4 0.1]);
            panel_info.Units = 'pixels';
            pos_info = panel_info.Position;
            
            app.handles.sus_info = uitextarea(panel_info, ...
                'Position', [10 10 pos_info(3)-20 pos_info(4)-40], ...
                'Value', {'Energy Monitoring Framework:', '', ...
                         '• Tracks CPU, GPU, and memory usage during simulation', ...
                         '• Builds energy scaling models: E = A * C^α', ...
                         '• Separates setup costs from execution costs', ...
                         '• Exports hardware metrics to CSV for analysis', ...
                         '• Helps assess computational efficiency and scalability', '', ...
                         'Enable monitoring to collect real-time performance data during simulation runs.'}, ...
                'Editable', 'off', ...
                'FontSize', 10, ...
                'BackgroundColor', [1 1 1]);
        end
        
        function create_monitoring_tab(app)
            % Live execution and convergence monitoring (normalized units + refinements)
            parent = app.tabs.monitoring;
            parent.Units = 'normalized';
            parent.BackgroundColor = [0.97 0.97 0.99];
            
            % Split view: execution on top, convergence on bottom
            panel_exec = uipanel(parent, 'Title', '⚡ Execution Monitor - CPU, Memory, Progress', ...
                'Units', 'normalized', ...
                'Position', [0.01 0.51 0.98 0.47], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.88 0.92 0.99], 'ForegroundColor', [0.1 0.3 0.7]);
            panel_exec.Units = 'pixels';
            pos_exec = panel_exec.Position;
            
            app.handles.exec_monitor_axes = uiaxes(panel_exec, 'Position', [10 10 pos_exec(3)-20 pos_exec(4)-40]);
            app.handles.exec_monitor_axes.XTick = [];
            app.handles.exec_monitor_axes.YTick = [];
            app.handles.exec_monitor_axes.Title.String = 'Real-time Execution Metrics';
            
            panel_conv = uipanel(parent, 'Title', '📉 Convergence Monitor - Error Decay & Refinement', ...
                'Units', 'normalized', ...
                'Position', [0.01 0.01 0.98 0.48], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.92 0.97 0.92], 'ForegroundColor', [0.1 0.5 0.1]);
            panel_conv.Units = 'pixels';
            pos_conv = panel_conv.Position;
            
            app.handles.conv_monitor_axes = uiaxes(panel_conv, 'Position', [10 10 pos_conv(3)-20 pos_conv(4)-40]);
            app.handles.conv_monitor_axes.XTick = [];
            app.handles.conv_monitor_axes.YTick = [];
            app.handles.conv_monitor_axes.Title.String = 'Convergence & Refinement Progress';
        end
        
        function create_terminal_tab(app)
            % Console output with normalized units and refinements
            parent = app.tabs.terminal;
            parent.Units = 'normalized';
            parent.BackgroundColor = [0.97 0.97 0.99];
            
            panel_terminal = uipanel(parent, 'Title', '🖥️ Console Output', ...
                'Units', 'normalized', ...
                'Position', [0.01 0.01 0.98 0.97], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.15 0.15 0.15], 'ForegroundColor', [0.9 0.9 0.9]);
            panel_terminal.Units = 'pixels';
            pos_terminal = panel_terminal.Position;
            
            app.handles.terminal_output = uitextarea(panel_terminal, ...
                'Position', [10 10 pos_terminal(3)-20 pos_terminal(4)-40], ...
                'Value', {'🚀 Terminal Ready', '', ...
                          'All output from Analysis.m will appear here', ...
                          'Use "Save Terminal Log" button to export session'}, ...
                'Editable', 'off', ...
                'FontName', 'Courier New', ...
                'FontSize', 11, ...
                'BackgroundColor', [0.1 0.1 0.1], ...
                'FontColor', [0.0 1.0 0.0]);
        end
        
        function create_results_tab(app)
            % Results viewer with normalized units and refinements
            parent = app.tabs.results;
            parent.Units = 'normalized';
            parent.BackgroundColor = [0.97 0.97 0.99];
            
            panel_figures = uipanel(parent, 'Title', '📈 Simulation Results Viewer', ...
                'Units', 'normalized', ...
                'Position', [0.01 0.01 0.98 0.97], 'FontSize', 13, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.99 0.94 0.88], 'ForegroundColor', [0.8 0.4 0.1]);
            panel_figures.Units = 'pixels';
            pos_figures = panel_figures.Position;
            
            app.handles.figure_axes = uiaxes(panel_figures, ...
                'Position', [10 50 pos_figures(3)-20 pos_figures(4)-70]);
            title(app.handles.figure_axes, 'Figures will appear here during simulation');
            
            uilabel(panel_figures, 'Position', [10 20 80 20], 'Text', 'Figure:', 'FontSize', 11, 'FontWeight', 'bold');
            app.handles.figure_selector = uidropdown(panel_figures, ...
                'Position', [100 20 200 20], ...
                'Items', {'No figures yet'}, ...
                'FontSize', 11);
            
            uibutton(panel_figures, 'push', 'Position', [320 20 140 20], ...
                'Text', '💾 Save Current', 'FontSize', 10, ...
                'BackgroundColor', [0.99 0.75 0.5], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.save_current_figure());
            
            uibutton(panel_figures, 'push', 'Position', [475 20 140 20], ...
                'Text', '📦 Export All', 'FontSize', 10, ...
                'BackgroundColor', [0.4 0.7 0.9], 'FontColor', 'white', ...
                'ButtonPushedFcn', @(~,~) app.export_all_figures());
        end
        
        % Action methods
        function launch_simulation(app)
            % Collect all configuration from UI
            try
                % Method and Mode
                method_button = get(app.handles.method_group, 'SelectedObject');
                if contains(method_button.Text, 'Finite Difference')
                    app.config.method = 'finite_difference';
                elseif contains(method_button.Text, 'Finite Volume')
                    app.config.method = 'finite_volume';
                else
                    app.config.method = 'spectral';
                end
                
                mode_val = app.handles.mode_dropdown.Value;
                if contains(mode_val, 'Evolution')
                    app.config.mode = 'evolution';
                elseif contains(mode_val, 'Convergence')
                    app.config.mode = 'convergence';
                elseif contains(mode_val, 'Sweep')
                    app.config.mode = 'sweep';
                elseif contains(mode_val, 'Animation')
                    app.config.mode = 'animation';
                else
                    app.config.mode = 'experimentation';
                end
                
                % Parameters
                app.config.Nx = round(app.handles.Nx.Value);
                app.config.Ny = round(app.handles.Ny.Value);
                app.config.Lx = app.handles.Lx.Value;
                app.config.Ly = app.handles.Ly.Value;
                app.config.dt = app.handles.dt.Value;
                app.config.t_final = app.handles.t_final.Value;
                app.config.nu = app.handles.nu.Value;
                
                % IC - map display name to internal ic_type
                ic_display_name = app.handles.ic_dropdown.Value;
                app.config.ic_type = map_ic_display_to_type(ic_display_name);
                app.config.ic_coeff1 = app.handles.ic_coeff1.Value;
                app.config.ic_coeff2 = app.handles.ic_coeff2.Value;
                
                % Convergence
                app.config.conv_tolerance = app.handles.conv_tolerance.Value;
                app.config.conv_max_iter = round(app.handles.conv_max_iter.Value);
                app.config.conv_refinement = app.handles.conv_refinement.Value;
                
                % Sustainability
                app.config.enable_monitoring = app.handles.enable_monitoring.Value;
                app.config.sample_interval = app.handles.sample_interval.Value;
                
                % Store config for Analysis.m
                setappdata(app.fig, 'ui_config', app.config);
                
                % Log
                app.append_to_terminal(sprintf('✓ Configuration collected for %s method in %s mode', ...
                    app.config.method, app.config.mode));
                app.append_to_terminal(sprintf('  Grid: %d × %d, dt=%.4f, T=%.2f', ...
                    app.config.Nx, app.config.Ny, app.config.dt, app.config.t_final));
                
                % Switch to terminal tab
                app.tab_group.SelectedTab = app.tabs.terminal;
                
            catch ME
                app.append_to_terminal(sprintf('✗ Error collecting configuration: %s', ME.message));
                uialert(app.fig, ME.message, 'Configuration Error', 'icon', 'error');
            end
        end
        
        function validate_parameters(app)
            errors = {};
            
            % Check UI components exist
            if ~isfield(app.handles, 'Nx') || ~ishghandle(app.handles.Nx)
                errors{end+1} = 'UI not fully initialized';
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
        end
        
        function autorun_kutz(app)
            % Load Kutz preset and immediately launch simulation
            app.load_preset('kutz');
            pause(0.5);
            app.append_to_terminal('▶ Autorunning Kutz preset...');
            app.launch_simulation();
        end
        
        function load_preset(app, preset_name)
            switch preset_name
                case 'kutz'
                    app.handles.ic_dropdown.Value = 'Stretched Gaussian (Kutz)';
                    app.handles.ic_coeff1.Value = 2.0;
                    app.handles.ic_coeff2.Value = 0.2;
                    app.handles.Nx.Value = 256;
                    app.handles.Ny.Value = 256;
                    app.handles.dt.Value = 0.001;
                    app.handles.t_final.Value = 20.0;
                    app.append_to_terminal('✓ Loaded: Kutz Figure Replication preset');
                    
                case 'convergence'
                    app.handles.ic_dropdown.Value = 'Vortex Blob';
                    app.handles.Nx.Value = 128;
                    app.handles.Ny.Value = 128;
                    app.handles.dt.Value = 0.002;
                    app.handles.t_final.Value = 10.0;
                    app.handles.conv_tolerance.Value = 1e-5;
                    app.append_to_terminal('✓ Loaded: Convergence Study preset');
                    
                case 'animation'
                    app.handles.ic_dropdown.Value = 'Vortex Pair';
                    app.handles.ic_coeff1.Value = 1.5;
                    app.handles.ic_coeff2.Value = 0.3;
                    app.handles.Nx.Value = 256;
                    app.handles.Ny.Value = 256;
                    app.handles.dt.Value = 0.0005;
                    app.handles.t_final.Value = 15.0;
                    app.handles.mode_dropdown.Value = 'Animation';
                    app.append_to_terminal('✓ Loaded: Vortex Pair Animation preset');
                    
                case 'fast_test'
                    app.handles.ic_dropdown.Value = 'Vortex Blob';
                    app.handles.ic_coeff1.Value = 1.0;
                    app.handles.ic_coeff2.Value = 0.5;
                    app.handles.Nx.Value = 64;
                    app.handles.Ny.Value = 64;
                    app.handles.dt.Value = 0.01;
                    app.handles.t_final.Value = 5.0;
                    app.append_to_terminal('✓ Loaded: Fast Test Run preset (low resolution)');
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
            config_export.method = app.config.method;
            config_export.mode = app.config.mode;
            config_export.Nx = round(app.handles.Nx.Value);
            config_export.Ny = round(app.handles.Ny.Value);
            config_export.dt = app.handles.dt.Value;
            config_export.t_final = app.handles.t_final.Value;
            config_export.nu = app.handles.nu.Value;
            
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
            timestamp = datestr(now, 'HH:MM:SS');
            formatted_msg = sprintf('[%s] %s', timestamp, message);
            
            app.terminal_log{end+1} = formatted_msg;
            
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
        
        function add_figure(app, fig, name)
            % Add figure to figures list
            if nargin < 3
                name = sprintf('Figure_%d', length(app.figures_list) + 1);
            end
            
            app.figures_list(end+1) = fig;
            
            % Update dropdown
            fig_names = [{'Figure 1'} arrayfun(@(i) sprintf('Figure %d', i+1), ...
                1:length(app.figures_list)-1, 'UniformOutput', false)];
            app.handles.figure_selector.Items = fig_names;
            app.handles.figure_selector.Value = fig_names{end};
            
            app.append_to_terminal(sprintf('✓ Added figure: %s', name));
        end
        
        function cleanup(app)
            % Cleanup when UI closes
            try
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
                
                % Tab group auto-scales with normalized units
                if ishghandle(app.tab_group)
                    app.tab_group.Position = [0.007 0.08 0.986 0.91];
                end
                
                % Buttons reposition based on window size
                fig_pos = app.fig.Position;
                fig_width = fig_pos(3);
                
                btn_width = 250;
                btn_height = 50;
                btn_y = 15;
                
                if ishghandle(app.handles.btn_launch)
                    app.handles.btn_launch.Position = [fig_width - btn_width - 10, btn_y, btn_width, btn_height];
                end
                if ishghandle(app.handles.btn_export)
                    app.handles.btn_export.Position = [fig_width - 2*btn_width - 30, btn_y, btn_width, btn_height];
                end
                if ishghandle(app.handles.btn_save_log)
                    app.handles.btn_save_log.Position = [fig_width - 3*btn_width - 50, btn_y, btn_width, btn_height];
                end
                
                drawnow limitrate;
            catch
                % Silently ignore errors during figure closing
            end
        end
        
        % Additional stub methods for button callbacks
        function update_ic_preview(app)
            % Update initial condition preview visualization (2D contour at t=0)
            try
                % Safely get ic_preview_axes if it exists
                if ~isfield(app.handles, 'ic_preview_axes') || ~ishghandle(app.handles.ic_preview_axes)
                    return;
                end
                
                % Display IC as 2D contour plot (evolution plot style)
                axes(app.handles.ic_preview_axes);
                cla(app.handles.ic_preview_axes);
                
                % Create IC preview based on selected type
                [X, Y] = meshgrid(linspace(-5, 5, 100), linspace(-5, 5, 100));
                c1 = app.handles.ic_coeff1.Value;
                c2 = app.handles.ic_coeff2.Value;
                
                % Compute IC vorticity field (robust formula)
                R = sqrt(X.^2 + Y.^2);
                Z = c1 * exp(-(R.^2) / (2*max(c2, 0.01)^2));
                
                % Display as 2D contour (like evolution plot at t=0)
                contour(app.handles.ic_preview_axes, X, Y, Z, 12, 'LineWidth', 1.2);
                hold(app.handles.ic_preview_axes, 'on');
                contourf(app.handles.ic_preview_axes, X, Y, Z, 20);
                hold(app.handles.ic_preview_axes, 'off');
                
                title(app.handles.ic_preview_axes, sprintf('Initial Vorticity ω(x,y,0): %s', app.handles.ic_dropdown.Value), ...
                    'FontSize', 10, 'FontWeight', 'bold');
                xlabel(app.handles.ic_preview_axes, 'x', 'FontSize', 9);
                ylabel(app.handles.ic_preview_axes, 'y', 'FontSize', 9);
                colormap(app.handles.ic_preview_axes, 'jet');
                colorbar(app.handles.ic_preview_axes);
                axis(app.handles.ic_preview_axes, 'equal');
                grid(app.handles.ic_preview_axes, 'on');
                
                app.append_to_terminal(sprintf('✓ IC preview updated (t=0, ω_max=%.3f)', max(Z, [], 'all')));
            catch ME
                app.append_to_terminal(sprintf('✗ Error updating IC preview: %s', ME.message));
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
        
        function browse_energy_dir(app)
            % Browse for energy output directory
            path = uigetdir(app.handles.energy_dir.Value, 'Select Energy Output Directory');
            if path ~= 0
                app.handles.energy_dir.Value = path;
                app.append_to_terminal(sprintf('✓ Energy directory set to: %s', path));
            end
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
    end
    
    methods (Static)
        function config = initialize_default_config()
            % Initialize default configuration
            config = struct();
            config.method = 'Finite Difference';
            config.mode = 'evolution';
            config.Nx = 128;
            config.Ny = 128;
            config.dt = 0.001;
            config.t_final = 10.0;
            config.nu = 1e-4;
        end
    end
end

function ic_type = map_ic_display_to_type(display_name)
    % Map UI display names to internal ic_type values
    % This ensures the display names are human-friendly while 
    % the actual ic_type values match the initialise_omega switch cases
    
    switch display_name
        case 'Stretched Gaussian (Kutz)'
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
        case 'Custom'
            ic_type = 'custom';
        otherwise
            % Fallback: try to use display_name directly if it's a valid ic_type
            ic_type = lower(display_name);
    end
end
