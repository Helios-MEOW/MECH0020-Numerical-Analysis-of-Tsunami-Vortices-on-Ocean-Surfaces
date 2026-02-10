function s = Settings()
% Settings - Unified editable operational settings
%
% This file controls IO, monitoring, logging, and animation policy.
% Snapshot policy:
%   - tile_snapshot_count is for the 3x3 summary panels.
%   - animation_frame_rate/frame_count are for animation sampling.
%   - They are intentionally independent.

    % ---------------------------------------------------------------------
    % Output and persistence
    % ---------------------------------------------------------------------
    s.save_figures = true;
    s.save_data = true;
    s.save_reports = true;
    s.append_to_master = true;

    % ---------------------------------------------------------------------
    % Monitoring and UI
    % ---------------------------------------------------------------------
    s.monitor_enabled = true;
    s.monitor_theme = 'dark';
    s.terminal_capture = true;

    % ---------------------------------------------------------------------
    % Logging
    % ---------------------------------------------------------------------
    s.log_level = 'INFO';       % DEBUG | INFO | WARN | ERROR

    % ---------------------------------------------------------------------
    % Figure formatting
    % ---------------------------------------------------------------------
    s.figure_format = 'png';    % png | pdf | eps | fig
    s.figure_dpi = 300;

    % ---------------------------------------------------------------------
    % Animation policy (separate from tiled plotting snapshots)
    % ---------------------------------------------------------------------
    s.animation_enabled = true;
    s.tile_snapshot_count = 9;      % For 3x3 tiled summary plots
    s.animation_frame_rate = 30;    % Frames per second for generated animation
    s.animation_frame_count = 100;  % Total sampled frames for animation timeline
    s.animation_format = 'gif';
    s.animation_quality = 90;
    s.animation_codec = 'MPEG-4';

    % Compatibility alias used by existing scripts
    s.animation_fps = s.animation_frame_rate;

    % ---------------------------------------------------------------------
    % Validation/normalization guards
    % ---------------------------------------------------------------------
    if s.tile_snapshot_count < 1
        s.tile_snapshot_count = 9;
    end
    if s.animation_frame_rate <= 0
        s.animation_frame_rate = 30;
    end
    if s.animation_frame_count < 2
        s.animation_frame_count = 100;
    end
end
