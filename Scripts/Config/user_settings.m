function settings = user_settings(mode_type)
% USER_SETTINGS Unified user-editable settings for all modes
%
% Purpose:
%   Single source of all operational settings (IO, UI, logging, plotting)
%   Separate from physics/numerics (see default_parameters.m)
%   Supports mode-specific settings via switch
%
% Location: Scripts/Config/ (user-editable directory)
%
% Usage:
%   settings = user_settings();              % Returns standard mode settings
%   settings = user_settings('UI');          % UI mode settings
%   settings = user_settings('Standard');    % Standard/CLI mode settings
%   settings.save_figures = false;           % Override as needed
%
% Input:
%   mode_type - (optional) String: 'UI', 'Standard', 'Convergence'
%               Default: 'Standard'
%
% Returns:
%   settings - Struct with operational settings
%
% Author: MECH0020 Framework
% Date: February 2026

    % Default to Standard mode if not specified
    if nargin < 1 || isempty(mode_type)
        mode_type = 'Standard';
    end
    
    % Normalize mode type
    mode_type = char(mode_type);
    
    % ===== IO SETTINGS =====
    % File output control
    settings.save_figures = true;                   % Save figures to disk (true/false)
    settings.save_data = true;                      % Save MAT/HDF5 data (true/false)
    settings.save_reports = true;                   % Generate run reports (true/false)
    settings.results_root = 'Results';              % Root directory for results
    
    % ===== LOGGING SETTINGS =====
    % Logging and diagnostics
    settings.log_level = 'INFO';                    % Log level: 'DEBUG', 'INFO', 'WARN', 'ERROR'
    settings.append_to_master = true;               % Append to master runs table (true/false)
    settings.verbose = true;                        % Verbose console output (true/false)
    
    % ===== PLOTTING POLICY =====
    % Figure output format and quality
    settings.figure_format = 'png';                 % Format: 'png', 'pdf', 'eps', 'fig', 'svg'
    settings.figure_dpi = 300;                      % Resolution for raster formats (72-600)
    settings.figure_renderer = 'painters';          % Renderer: 'painters', 'opengl', 'software'
    
    % ===== MODE-SPECIFIC SETTINGS =====
    switch upper(mode_type)
        case 'UI'
            % UI mode: maximize interactivity
            settings.monitor_enabled = true;        % Enable live monitor dashboard
            settings.monitor_theme = 'dark';        % Theme: 'dark' or 'light'
            settings.terminal_capture = true;       % Capture terminal output in UI
            settings.animation_enabled = true;      % Enable animations in UI
            settings.animation_fps = 10;            % Animation frame rate (5-60)
            settings.auto_refresh = true;           % Auto-refresh results browser
            settings.preview_updates = true;        % Live preview during execution
            
        case 'STANDARD'
            % Standard/CLI mode: minimal overhead
            settings.monitor_enabled = true;        % Enable console monitor
            settings.monitor_theme = 'dark';        % Theme: 'dark' or 'light'
            settings.terminal_capture = false;      % No UI to capture to
            settings.animation_enabled = false;     % No animations in CLI
            settings.animation_fps = 10;            % (Not used in Standard mode)
            settings.auto_refresh = false;          % No UI to refresh
            settings.preview_updates = false;       % No live previews in CLI
            
        case 'CONVERGENCE'
            % Convergence study mode: focus on data collection
            settings.monitor_enabled = true;        % Show progress
            settings.monitor_theme = 'dark';
            settings.terminal_capture = false;
            settings.animation_enabled = false;     % No animations for convergence
            settings.animation_fps = 10;
            settings.auto_refresh = false;
            settings.preview_updates = false;
            settings.save_intermediate = true;      % Save intermediate results
            settings.parallel_enabled = false;      % Parallel execution (if supported)
            
        otherwise
            % Default to Standard mode settings
            warning('Unknown mode type "%s". Using Standard mode settings.', mode_type);
            settings.monitor_enabled = true;
            settings.monitor_theme = 'dark';
            settings.terminal_capture = false;
            settings.animation_enabled = false;
            settings.animation_fps = 10;
            settings.auto_refresh = false;
            settings.preview_updates = false;
    end
    
    % ===== MONITOR CONFIGURATION =====
    % Monitor display settings (when enabled)
    settings.monitor_refresh_rate = 1.0;            % Update monitor every N seconds
    settings.monitor_metrics = {                    % Metrics to display
        'Energy', ...
        'Enstrophy', ...
        'Palinstrophy', ...
        'Max Vorticity'
    };
    
    % ===== PERFORMANCE TUNING =====
    % Computational optimization hints
    settings.use_parallel = false;                  % Use parallel toolbox if available
    settings.num_workers = 4;                       % Number of parallel workers
    settings.memory_limit_gb = 8;                   % Memory limit (GB) for large arrays
    
    % ===== DEBUG & DEVELOPMENT =====
    % Debugging aids (normally off)
    settings.debug_mode = false;                    % Enable debug outputs
    settings.profile_enabled = false;               % Enable MATLAB profiler
    settings.timing_detailed = false;               % Detailed timing breakdown
    
    % ===== VALIDATION & CHECKS =====
    % Runtime validation settings
    settings.validate_inputs = true;                % Validate inputs before run
    settings.check_stability = true;                % Check CFL/stability conditions
    settings.warn_on_override = true;               % Warn if params overridden
end
