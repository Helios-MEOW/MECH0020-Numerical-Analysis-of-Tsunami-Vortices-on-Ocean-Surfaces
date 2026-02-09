function s = Settings()
    % Settings - User-editable operational settings
    %
    % Purpose:
    %   Single source of default IO, UI, logging, and plotting settings
    %   Separate from Parameters (physics/numerics)
    %
    % Location: Scripts/Editable/ (user-editable directory)
    %
    % Structure: Returns Settings struct (operational knobs)
    %
    % Usage:
    %   Settings = Settings();
    %   Settings.save_figures = false;  % Override as needed
    
    % ===== IO SETTINGS =====
    s.save_figures = true;       % Save figures to disk
    s.save_data = true;          % Save MAT/HDF5 data
    s.save_reports = true;       % Generate run reports
    
    % ===== MONITOR/UI SETTINGS =====
    s.monitor_enabled = true;    % Enable live monitor
    s.monitor_theme = 'dark';    % 'dark' or 'light'
    s.terminal_capture = true;   % Capture terminal output in UI
    
    % ===== LOGGING SETTINGS =====
    s.log_level = 'INFO';        % 'DEBUG', 'INFO', 'WARN', 'ERROR'
    s.append_to_master = true;   % Append to master runs table
    
    % ===== PLOTTING POLICY =====
    s.figure_format = 'png';     % 'png', 'pdf', 'eps', 'fig'
    s.figure_dpi = 300;          % Resolution for raster formats
    s.animation_enabled = false; % Generate animations (setting, not mode)
    s.animation_fps = 10;        % Animation frame rate
end
