function Settings = Default_Settings()
    % Default_Settings - User-editable operational settings
    %
    % Purpose:
    %   Single source of default IO, UI, logging, and plotting settings
    %   Separate from Parameters (physics/numerics)
    %
    % Location: Scripts/Config/ (user-editable directory)
    %
    % Structure: Returns Settings struct (operational knobs)
    %
    % Usage:
    %   Settings = Default_Settings();
    %   Settings.save_figures = false;  % Override as needed
    
    % ===== IO SETTINGS =====
    Settings.save_figures = true;       % Save figures to disk
    Settings.save_data = true;          % Save MAT/HDF5 data
    Settings.save_reports = true;       % Generate run reports
    
    % ===== MONITOR/UI SETTINGS =====
    Settings.monitor_enabled = true;    % Enable live monitor
    Settings.monitor_theme = 'dark';    % 'dark' or 'light'
    Settings.terminal_capture = true;   % Capture terminal output in UI
    
    % ===== LOGGING SETTINGS =====
    Settings.log_level = 'INFO';        % 'DEBUG', 'INFO', 'WARN', 'ERROR'
    Settings.append_to_master = true;   % Append to master runs table
    
    % ===== PLOTTING POLICY =====
    Settings.figure_format = 'png';     % 'png', 'pdf', 'eps', 'fig'
    Settings.figure_dpi = 300;          % Resolution for raster formats
    Settings.animation_enabled = false; % Generate animations (setting, not mode)
    Settings.animation_fps = 10;        % Animation frame rate
end
