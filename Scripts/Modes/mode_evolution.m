function [Results, paths] = mode_evolution(Run_Config, Parameters, Settings)
    % mode_evolution - METHOD-AGNOSTIC Evolution Mode
    %
    % Purpose:
    %   Orchestrates a single time evolution simulation
    %   Works with ANY numerical method (FD, Spectral, FV)
    %   Method selection handled internally via switch/case
    %
    % This is the SINGLE SOURCE OF TRUTH for Evolution mode logic
    % NO method-specific evolution files (no FD_Evolution, etc.)
    %
    % Inputs:
    %   Run_Config - .method, .mode, .ic_type, .run_id
    %   Parameters - physics + numerics
    %   Settings - IO, monitoring, logging
    %
    % Outputs:
    %   Results - simulation results and metrics
    %   paths - directory structure
    %
    % Usage:
    %   [Results, paths] = mode_evolution(Run_Config, Parameters, Settings);

    % ===== VALIDATION =====
    [ok, issues] = validate_evolution(Run_Config, Parameters);
    if ~ok
        error('Evolution mode validation failed: %s', strjoin(issues, '; '));
    end

    % ===== SETUP =====
    % Generate run ID if not provided
    if ~isfield(Run_Config, 'run_id') || isempty(Run_Config.run_id)
        Run_Config.run_id = RunIDGenerator.generate(Run_Config, Parameters);
    end

    % Get directory paths
    output_root = resolve_output_root(Settings);
    paths = PathBuilder.get_run_paths(Run_Config.method, Run_Config.mode, Run_Config.run_id, output_root);
    PathBuilder.ensure_directories(paths);

    % Save configuration
    config_path = fullfile(paths.config, 'Config.mat');
    save(config_path, 'Run_Config', 'Parameters', 'Settings');

    % ===== METHOD DISPATCH =====
    % Resolve method callbacks (init, step, diagnostics)
    [init_fn, step_fn, diag_fn] = resolve_method(Run_Config.method);

    % ===== BUILD CONTEXT =====
    ctx = build_mode_context(Parameters, Settings);
    ctx.mode = 'evolution';

    % ===== MONITORING =====
    MonitorInterface.start(Run_Config, Settings);

    % ===== SIMULATION LOOP =====
    tic;

    % Initialize method-specific state
    cfg = prepare_cfg(Run_Config, Parameters);
    State = init_fn(cfg, ctx);

    % Time integration parameters
    Tfinal = Parameters.Tfinal;
    dt = Parameters.dt;
    Nt = round(Tfinal / dt);
    snap_times = Parameters.snap_times;
    Nsnap = length(snap_times);

    % Storage for snapshots
    snapshots = struct();
    snapshots.omega = zeros(cfg.Ny, cfg.Nx, Nsnap);
    snapshots.psi = zeros(cfg.Ny, cfg.Nx, Nsnap);
    snapshots.times = snap_times;

    % Store initial snapshot
    snapshots.omega(:, :, 1) = State.omega;
    snapshots.psi(:, :, 1) = State.psi;
    snap_index = 2;
    if Nsnap >= 2
        next_snap_t = snap_times(snap_index);
    else
        next_snap_t = inf;
    end

    % Progress reporting
    progress_stride = max(1, round(Nt / 20));

    % Time history for diagnostics
    time_vec = zeros(1, Nt + 1);
    time_vec(1) = 0.0;
    kinetic_energy = zeros(1, Nt + 1);
    enstrophy = zeros(1, Nt + 1);
    max_vorticity = zeros(1, Nt + 1);

    % Initial diagnostics
    Metrics = diag_fn(State, cfg, ctx);
    kinetic_energy(1) = Metrics.kinetic_energy;
    enstrophy(1) = Metrics.enstrophy;
    max_vorticity(1) = Metrics.max_vorticity;

    % Main time integration loop
    for n = 1:Nt
        % Advance state by one time step
        State = step_fn(State, cfg, ctx);

        % Store diagnostics
        time_vec(n + 1) = State.t;
        Metrics = diag_fn(State, cfg, ctx);
        kinetic_energy(n + 1) = Metrics.kinetic_energy;
        enstrophy(n + 1) = Metrics.enstrophy;
        max_vorticity(n + 1) = Metrics.max_vorticity;

        % Snapshot if needed
        if snap_index <= Nsnap && State.t >= next_snap_t - 1e-12
            snapshots.omega(:, :, snap_index) = State.omega;
            snapshots.psi(:, :, snap_index) = State.psi;
            snap_index = snap_index + 1;
            if snap_index <= Nsnap
                next_snap_t = snap_times(snap_index);
            end
        end

        % Progress reporting
        if mod(n, progress_stride) == 0 || n == 1 || n == Nt
            fprintf('[Evolution] %6.2f%% | t = %.3f / %.3f | Method = %s | max|ω| = %.3e\n', ...
                100 * n / Nt, State.t, Tfinal, Run_Config.method, Metrics.max_vorticity);
        end
    end

    wall_time = toc;

    % ===== RESULTS COLLECTION =====
    Results = struct();
    Results.run_id = Run_Config.run_id;
    Results.wall_time = wall_time;
    Results.final_time = Tfinal;
    Results.total_steps = Nt;
    Results.method = Run_Config.method;
    Results.max_omega = max_vorticity(end);
    Results.final_energy = kinetic_energy(end);
    Results.final_enstrophy = enstrophy(end);

    % Analysis structure (for compatibility with plotting)
    analysis = struct();
    analysis.omega_snaps = snapshots.omega;
    analysis.psi_snaps = snapshots.psi;
    analysis.time_vec = time_vec;
    analysis.kinetic_energy = kinetic_energy;
    analysis.enstrophy = enstrophy;
    analysis.peak_vorticity = max(max_vorticity);
    analysis.method = sprintf('%s (method-agnostic)', Run_Config.method);

    % ===== SAVE OUTPUTS =====
    if Settings.save_data
        data_path = fullfile(paths.data, 'results.mat');
        save(data_path, 'analysis', 'Results', 'State', '-v7.3');
    end

    if Settings.save_figures
        generate_evolution_figures(analysis, Parameters, Run_Config, paths, Settings);
    end

    if Settings.save_reports
        RunReportGenerator.generate(Run_Config.run_id, Run_Config, Parameters, Settings, Results, paths);
    end

    if Settings.append_to_master
        MasterRunsTable.append_run(Run_Config.run_id, Run_Config, Parameters, Results);
    end

    % ===== MONITORING COMPLETE =====
    Run_Summary = struct();
    Run_Summary.total_time = wall_time;
    Run_Summary.status = 'completed';
    MonitorInterface.stop(Run_Summary);
end

%% ===== LOCAL FUNCTIONS =====

function [ok, issues] = validate_evolution(Run_Config, Parameters)
    % Validate Evolution mode configuration
    ok = true;
    issues = {};

    % Check required fields
    if ~isfield(Run_Config, 'method')
        ok = false;
        issues{end+1} = 'Run_Config.method is required';
    end

    if ~isfield(Parameters, 'Tfinal') || Parameters.Tfinal <= 0
        ok = false;
        issues{end+1} = 'Parameters.Tfinal must be > 0';
    end

    if ~isfield(Parameters, 'dt') || Parameters.dt <= 0
        ok = false;
        issues{end+1} = 'Parameters.dt must be > 0';
    end

    if ~isfield(Parameters, 'Nx') || ~isfield(Parameters, 'Ny')
        ok = false;
        issues{end+1} = 'Parameters.Nx and Parameters.Ny are required';
    end
end

function [init_fn, step_fn, diag_fn] = resolve_method(method_name)
    % Resolve method callbacks from method name
    % This is the ONLY place where method branching occurs
    % CRITICAL: This must be inside the mode script, not in separate files

    switch lower(method_name)
        case 'fd'
            init_fn = @(cfg, ctx) FiniteDifferenceMethod('init', cfg, ctx);
            step_fn = @(State, cfg, ctx) FiniteDifferenceMethod('step', State, cfg, ctx);
            diag_fn = @(State, cfg, ctx) FiniteDifferenceMethod('diagnostics', State, cfg, ctx);
        case {'spectral', 'fft'}
            init_fn = @(cfg, ctx) SpectralMethod('init', cfg, ctx);
            step_fn = @(State, cfg, ctx) SpectralMethod('step', State, cfg, ctx);
            diag_fn = @(State, cfg, ctx) SpectralMethod('diagnostics', State, cfg, ctx);
        case {'fv', 'finitevolume'}
            init_fn = @(cfg, ctx) FiniteVolumeMethod('init', cfg, ctx);
            step_fn = @(State, cfg, ctx) FiniteVolumeMethod('step', State, cfg, ctx);
            diag_fn = @(State, cfg, ctx) FiniteVolumeMethod('diagnostics', State, cfg, ctx);
        otherwise
            error('Unknown method: %s. Valid: FD, Spectral, FV', method_name);
    end
end

function ctx = build_mode_context(~, Settings)
    % Build mode-specific context data
    ctx = struct();
    ctx.save_data = Settings.save_data;
    ctx.save_figures = Settings.save_figures;
    ctx.monitor_enabled = Settings.monitor_enabled;
end

function cfg = prepare_cfg(Run_Config, Parameters)
    % Prepare configuration struct for method entrypoints
    % This is a standardized interface between mode and method

    cfg = struct();
    % Grid
    cfg.Nx = Parameters.Nx;
    cfg.Ny = Parameters.Ny;
    cfg.Lx = Parameters.Lx;
    cfg.Ly = Parameters.Ly;

    % Time
    cfg.dt = Parameters.dt;
    cfg.Tfinal = Parameters.Tfinal;

    % Physics
    cfg.nu = Parameters.nu;

    % IC
    cfg.ic_type = Run_Config.ic_type;
    if isfield(Parameters, 'ic_coeff')
        cfg.ic_coeff = Parameters.ic_coeff;
    end
    if isfield(Parameters, 'omega')
        cfg.omega = Parameters.omega;
    end
end

function generate_evolution_figures(analysis, ~, Run_Config, paths, ~)
    % Generate evolution figures (contours, vectors, etc.)
    % Reuse existing visualization utilities

    % Create main evolution figure
    fig = figure('Position', [100, 100, 1200, 800]);

    Nsnap = size(analysis.omega_snaps, 3);
    ncols = min(4, Nsnap);
    nrows = ceil(Nsnap / ncols);

    for k = 1:Nsnap
        subplot(nrows, ncols, k);
        imagesc(analysis.omega_snaps(:, :, k));
        axis equal tight;
        colormap(turbo);
        colorbar;
        title(sprintf('t = %.3f', analysis.time_vec(k)));
    end

    sgtitle(sprintf('Evolution: %s | Method: %s', Run_Config.ic_type, Run_Config.method));

    % Save figure
    fig_name = RunIDGenerator.make_figure_filename(Run_Config.run_id, 'evolution', '');
    fig_path = fullfile(paths.figures_evolution, fig_name);
    saveas(fig, fig_path);
    close(fig);
end

function output_root = resolve_output_root(Settings)
    output_root = 'Results';
    if isfield(Settings, 'output_root') && ~isempty(Settings.output_root)
        output_root = char(string(Settings.output_root));
    end
end
