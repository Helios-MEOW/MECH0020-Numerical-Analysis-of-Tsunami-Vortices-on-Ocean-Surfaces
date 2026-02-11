function s = Settings()
% Settings - Unified operational settings for run output and tooling.
%
% Canonical sections:
%   output_root
%   reporting.*
%   media.*
%   sustainability.*
%
% Compatibility aliases are preserved for existing scripts.

    % ---------------------------------------------------------------------
    % Output root
    % ---------------------------------------------------------------------
    s.output_root = 'Results';

    % ---------------------------------------------------------------------
    % Persistence toggles
    % ---------------------------------------------------------------------
    s.save_figures = true;
    s.save_data = true;
    s.append_to_master = true;

    % ---------------------------------------------------------------------
    % Monitoring and UI
    % ---------------------------------------------------------------------
    s.monitor_enabled = true;
    s.monitor_theme = 'dark';
    s.terminal_capture = true;
    s.log_level = 'INFO';       % DEBUG | INFO | WARN | ERROR

    % ---------------------------------------------------------------------
    % Figure formatting
    % ---------------------------------------------------------------------
    s.figure_format = 'png';    % png | pdf | eps | fig
    s.figure_dpi = 300;

    % ---------------------------------------------------------------------
    % Reporting policy
    % ---------------------------------------------------------------------
    s.reporting = struct();
    s.reporting.enabled = true;
    s.reporting.engine = 'quarto';   % quarto with internal fallback
    s.reporting.template = 'default';
    s.reporting.formats = {'html', 'pdf'};
    s.reporting.max_rows = 500;
    s.reporting.max_figures = 24;

    % Compatibility alias used across current code.
    s.save_reports = s.reporting.enabled;

    % ---------------------------------------------------------------------
    % Media/animation policy
    % ---------------------------------------------------------------------
    s.media = struct();
    s.media.enabled = true;
    s.media.format = 'mp4';          % mp4 | avi | gif
    s.media.codec = 'MPEG-4';        % VideoWriter profile for MP4 path
    s.media.fps = 30;
    s.media.frame_count = 100;
    s.media.quality = 90;
    s.media.fallback_format = 'gif'; % Used when video writer fails

    % Compatibility aliases used by existing scripts.
    s.animation_enabled = s.media.enabled;
    s.tile_snapshot_count = 9;             % For 3x3 tiled summary plots
    s.animation_frame_rate = s.media.fps;  % Frames per second
    s.animation_frame_count = s.media.frame_count;
    s.animation_format = s.media.format;
    s.animation_quality = s.media.quality;
    s.animation_codec = s.media.codec;
    s.animation_fps = s.animation_frame_rate;

    % ---------------------------------------------------------------------
    % Sustainability policy (always-on ledger, optional enrichers)
    % ---------------------------------------------------------------------
    s.sustainability = struct();
    s.sustainability.enabled = true;
    s.sustainability.machine_id = 'auto';      % auto uses hostname/computername
    s.sustainability.machine_label = '';       % optional display label
    s.sustainability.external_collectors = struct( ...
        'cpuz', false, ...
        'hwinfo', false, ...
        'icue', false);
    s.sustainability.collector_paths = struct( ...
        'cpuz', '', ...
        'hwinfo', '', ...
        'icue', '');

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
