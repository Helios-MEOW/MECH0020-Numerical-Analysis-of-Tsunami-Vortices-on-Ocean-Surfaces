function Tsunami_Vorticity_Emulator(varargin)
% Tsunami_Vorticity_Emulator - Unified driver and single simulation entrypoint
%
% High-level flow:
%   1) Add repository paths
%   2) Select mode: UI, Standard, or Interactive startup dialog
%   3) Load editable defaults from Scripts/Editable
%   4) In Standard mode, show parameter summary and confirm before running
%   5) Build Run_Config and dispatch via ModeDispatcher
%
% Editable defaults:
%   - Scripts/Editable/Parameters.m
%   - Scripts/Editable/Settings.m
% Fallback defaults:
%   - Scripts/Infrastructure/Initialisers/create_default_parameters.m
%
% Usage examples:
%   Tsunami_Vorticity_Emulator()
%   Tsunami_Vorticity_Emulator('Mode', 'UI')
%   Tsunami_Vorticity_Emulator('Mode', 'Standard', 'Method', 'FD', 'SimMode', 'Evolution')

    opts = parse_options(varargin{:});
    repo_root = setup_paths();
    ensure_results_storage_ready(repo_root, 'Verbose', true);

    switch lower(opts.Mode)
        case 'ui'
            run_ui_mode();
        case 'standard'
            run_standard_mode(opts);
        case 'interactive'
            run_interactive_mode(opts);
        otherwise
            error('TVE:InvalidMode', ...
                'Unknown mode ''%s''. Valid: UI, Standard, Interactive.', opts.Mode);
    end
end

function opts = parse_options(varargin)
    p = inputParser;
    addParameter(p, 'Mode', 'Interactive', @ischar);
    addParameter(p, 'Method', 'FD', @ischar);
    addParameter(p, 'SimMode', 'Evolution', @ischar);
    addParameter(p, 'IC', '', @ischar);
    addParameter(p, 'Nx', 0, @isnumeric);
    addParameter(p, 'Ny', 0, @isnumeric);
    addParameter(p, 'dt', 0, @isnumeric);
    addParameter(p, 'Tfinal', 0, @isnumeric);
    addParameter(p, 'nu', 0, @isnumeric);
    addParameter(p, 'SaveFigs', -1, @isnumeric);
    addParameter(p, 'SaveData', -1, @isnumeric);
    addParameter(p, 'Monitor', -1, @isnumeric);
    addParameter(p, 'NoPrompt', false, @islogical);
    parse(p, varargin{:});
    opts = p.Results;
end

function repo_root = setup_paths()
    script_dir = fileparts(mfilename('fullpath'));
    repo_root = fileparts(fileparts(script_dir));
    addpath(genpath(fullfile(repo_root, 'Scripts')));
    addpath(fullfile(repo_root, 'utilities'));
end

function run_interactive_mode(opts)
    ColorPrintf.header('TSUNAMI VORTICITY EMULATOR');
    app = UIController(); %#ok<NASGU>

    if isappdata(0, 'ui_mode') && strcmp(getappdata(0, 'ui_mode'), 'traditional')
        rmappdata(0, 'ui_mode');
        ColorPrintf.info('Startup dialog selected Standard mode.');
        run_standard_mode(opts);
    else
        ColorPrintf.info('UI mode selected. Continue inside the UI.');
    end
end

function run_ui_mode()
    ColorPrintf.header('TSUNAMI VORTICITY EMULATOR - UI MODE');
    app = UIController(); %#ok<NASGU>
    ColorPrintf.success('UI launched.');
end

function run_standard_mode(opts)
    ColorPrintf.header('TSUNAMI VORTICITY EMULATOR - STANDARD MODE');

    params = Parameters();
    settings = Settings();
    [params, settings] = ensure_time_sampling(params, settings);

    show_standard_mode_summary(params, settings);

    has_overrides = opts.Nx > 0 || opts.Ny > 0 || opts.dt > 0 || opts.Tfinal > 0 || ...
        opts.nu > 0 || opts.SaveFigs >= 0 || opts.SaveData >= 0 || opts.Monitor >= 0 || ...
        ~isempty(opts.IC) || ~strcmpi(opts.Method, 'FD') || ~strcmpi(opts.SimMode, 'Evolution');

    prompt_enabled = usejava('desktop') && ~opts.NoPrompt && ~has_overrides;
    if prompt_enabled
        [params, settings, user_abort] = confirm_or_adjust_parameters(params, settings);
        if user_abort
            ColorPrintf.warn('Run cancelled.');
            return;
        end
    end

    [params, settings] = apply_runtime_overrides(params, settings, opts);
    [params, settings] = ensure_time_sampling(params, settings);

    if isempty(opts.IC)
        ic_type = params.ic_type;
    else
        ic_type = opts.IC;
    end

    run_config = Build_Run_Config(opts.Method, opts.SimMode, ic_type);
    print_run_configuration(run_config, params, settings);

    try
        [results, paths] = ModeDispatcher(run_config, params, settings);
        print_run_results(results, paths);
    catch ME
        ErrorHandler.log('ERROR', 'RUN-EXEC-0003', ...
            'message', sprintf('Simulation failed: %s', ME.message), ...
            'file', mfilename, ...
            'context', struct('error_id', ME.identifier));
        rethrow(ME);
    end
end

function [params, settings, user_abort] = confirm_or_adjust_parameters(params, settings)
    user_abort = false;

    fprintf('Review editable defaults from:\n');
    fprintf('  - Scripts/Editable/Parameters.m\n');
    fprintf('  - Scripts/Editable/Settings.m\n\n');

    response = input('Are these parameters correct? [Y/n]: ', 's');
    if isempty(response) || strcmpi(response, 'y')
        return;
    end

    fprintf('\nChoose an option:\n');
    fprintf('  1) Edit Scripts/Editable/Parameters.m and rerun\n');
    fprintf('  2) Continue with create_default_parameters defaults\n');
    fprintf('  3) Abort\n');

    choice = input('Selection [1]: ', 's');
    if isempty(choice)
        choice = '1';
    end

    switch choice
        case '1'
            fprintf('\nEdit this file and rerun:\n');
            fprintf('  Scripts/Editable/Parameters.m\n\n');
            user_abort = true;

        case '2'
            fallback = create_default_parameters();
            params = overlay_struct(params, fallback);
            if isfield(fallback, 'create_animations')
                settings.animation_enabled = logical(fallback.create_animations);
            end
            if isfield(fallback, 'animation_fps')
                settings.animation_frame_rate = fallback.animation_fps;
            end
            fprintf('\nLoaded defaults from create_default_parameters.m\n\n');

        otherwise
            user_abort = true;
    end
end

function [params, settings] = apply_runtime_overrides(params, settings, opts)
    if opts.Nx > 0, params.Nx = opts.Nx; end
    if opts.Ny > 0, params.Ny = opts.Ny; end
    if opts.dt > 0, params.dt = opts.dt; end
    if opts.Tfinal > 0, params.Tfinal = opts.Tfinal; end
    if opts.nu > 0, params.nu = opts.nu; end
    if ~isempty(opts.IC), params.ic_type = opts.IC; end

    if opts.SaveFigs >= 0, settings.save_figures = logical(opts.SaveFigs); end
    if opts.SaveData >= 0, settings.save_data = logical(opts.SaveData); end
    if opts.Monitor >= 0, settings.monitor_enabled = logical(opts.Monitor); end
end

function [params, settings] = ensure_time_sampling(params, settings)
    % Normalize media aliases <-> canonical structs before sampling math.
    if isfield(settings, 'media') && isstruct(settings.media)
        if isfield(settings.media, 'fps') && settings.media.fps > 0
            settings.animation_frame_rate = settings.media.fps;
        end
        if isfield(settings.media, 'frame_count') && settings.media.frame_count >= 2
            settings.animation_frame_count = settings.media.frame_count;
        end
        if isfield(settings.media, 'format') && ~isempty(settings.media.format)
            settings.animation_format = char(string(settings.media.format));
        end
    end

    if isfield(params, 'media') && isstruct(params.media)
        if isfield(params.media, 'num_frames') && params.media.num_frames >= 2
            params.num_animation_frames = params.media.num_frames;
        end
        if isfield(params.media, 'fps') && params.media.fps > 0
            settings.animation_frame_rate = params.media.fps;
        end
        if isfield(params.media, 'format') && ~isempty(params.media.format)
            params.animation_format = char(string(params.media.format));
        end
    end

    if ~isfield(params, 'num_plot_snapshots') || params.num_plot_snapshots < 1
        if isfield(params, 'num_snapshots') && params.num_snapshots > 0
            params.num_plot_snapshots = params.num_snapshots;
        else
            params.num_plot_snapshots = 9;
        end
    end

    if ~isfield(settings, 'animation_frame_rate') || settings.animation_frame_rate <= 0
        settings.animation_frame_rate = 24;
    end

    if ~isfield(params, 'num_animation_frames') || params.num_animation_frames < 1
        params.num_animation_frames = max(2, round(params.Tfinal * settings.animation_frame_rate) + 1);
    end

    params.plot_snap_times = linspace(0, params.Tfinal, params.num_plot_snapshots);
    params.animation_times = linspace(0, params.Tfinal, params.num_animation_frames);
    params.snap_times = params.plot_snap_times;
    params.num_snapshots = params.num_plot_snapshots;

    % Keep canonical structs synced for downstream scripts.
    if ~isfield(settings, 'media') || ~isstruct(settings.media)
        settings.media = struct();
    end
    settings.media.fps = settings.animation_frame_rate;
    settings.media.frame_count = settings.animation_frame_count;
    settings.media.format = settings.animation_format;
    settings.media.quality = settings.animation_quality;
    settings.media.codec = settings.animation_codec;
    if ~isfield(settings.media, 'fallback_format')
        settings.media.fallback_format = 'gif';
    end

    if ~isfield(params, 'media') || ~isstruct(params.media)
        params.media = struct();
    end
    params.media.fps = settings.animation_frame_rate;
    params.media.num_frames = params.num_animation_frames;
    params.media.format = params.animation_format;
    params.media.quality = params.animation_quality;
    params.media.codec = params.animation_codec;
    if ~isfield(params.media, 'fallback_format')
        params.media.fallback_format = 'gif';
    end
end

function show_standard_mode_summary(params, settings)
    fprintf('------------------------------------------------------------\n');
    fprintf('Editable Parameter Snapshot\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Method defaults:           %s\n', char(string(params.default_method)));
    fprintf('Mode default:              %s\n', char(string(params.default_mode)));
    fprintf('Grid (Nx x Ny):            %d x %d\n', params.Nx, params.Ny);
    fprintf('Domain (Lx x Ly):          %.3f x %.3f\n', params.Lx, params.Ly);
    fprintf('Time (dt, Tfinal):         %.6f, %.3f\n', params.dt, params.Tfinal);
    fprintf('Viscosity nu:              %.6e\n', params.nu);
    fprintf('IC type:                   %s\n', char(string(params.ic_type)));
    fprintf('9-tile snapshots:          %d (separate from animation)\n', params.num_plot_snapshots);
    fprintf('Animation frame rate:      %.2f fps\n', settings.animation_frame_rate);
    fprintf('Animation frame count:     %d\n', params.num_animation_frames);
    fprintf('Save figures/data/reports: %d / %d / %d\n', ...
        settings.save_figures, settings.save_data, settings.save_reports);
    fprintf('------------------------------------------------------------\n\n');
end

function print_run_configuration(run_config, params, settings)
    ColorPrintf.section('RUN CONFIGURATION');
    fprintf('Method:          %s\n', run_config.method);
    fprintf('Mode:            %s\n', run_config.mode);
    fprintf('IC:              %s\n', run_config.ic_type);
    fprintf('Grid:            %d x %d\n', params.Nx, params.Ny);
    fprintf('dt / Tfinal:     %.6f / %.3f\n', params.dt, params.Tfinal);
    fprintf('Plot snapshots:  %d\n', params.num_plot_snapshots);
    fprintf('Animation fps:   %.2f\n', settings.animation_frame_rate);
    fprintf('\n');
end

function print_run_results(results, paths)
    ColorPrintf.header('SIMULATION COMPLETE');
    if isfield(results, 'run_id')
        fprintf('Run ID:       %s\n', results.run_id);
    end
    if isfield(results, 'wall_time')
        fprintf('Wall Time:    %.2f s\n', results.wall_time);
    end
    if isfield(results, 'max_omega')
        fprintf('Max |omega|:  %.6e\n', results.max_omega);
    end
    if isfield(paths, 'base')
        fprintf('Output Dir:   %s\n', paths.base);
    end
    fprintf('\n');
end

function out = overlay_struct(base, patch)
    out = base;
    fields = fieldnames(patch);
    for i = 1:numel(fields)
        out.(fields{i}) = patch.(fields{i});
    end
end
