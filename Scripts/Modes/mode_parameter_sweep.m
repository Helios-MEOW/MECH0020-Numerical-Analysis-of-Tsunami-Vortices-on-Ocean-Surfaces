function [Results, paths] = mode_parameter_sweep(Run_Config, Parameters, Settings)
    % mode_parameter_sweep - METHOD-AGNOSTIC Parameter Sweep Mode
    %
    % Purpose:
    %   Orchestrates parameter sensitivity study
    %   Works with ANY numerical method (FD, Spectral, FV)
    %   Sweeps a single parameter across specified values
    %
    % This is the SINGLE SOURCE OF TRUTH for Parameter Sweep logic
    %
    % Inputs:
    %   Run_Config - .method, .mode, .ic_type, .study_id
    %   Parameters - physics + numerics + sweep settings
    %   Settings - IO, monitoring, logging
    %
    % Sweep Parameters (in Parameters struct):
    %   .sweep_parameter - parameter name ('nu', 'dt', etc.)
    %   .sweep_values - array of values to sweep
    %
    % Outputs:
    %   Results - sweep results (QoI vs parameter)
    %   paths - directory structure

    % ===== VALIDATION =====
    [ok, issues] = validate_parameter_sweep(Run_Config, Parameters);
    if ~ok
        error('Parameter Sweep validation failed: %s', strjoin(issues, '; '));
    end

    % ===== SETUP =====
    if ~isfield(Run_Config, 'study_id') || isempty(Run_Config.study_id)
        Run_Config.study_id = RunIDGenerator.generate(Run_Config, Parameters);
    end

    paths = PathBuilder.get_run_paths(Run_Config.method, Run_Config.mode, Run_Config.study_id);
    PathBuilder.ensure_directories(paths);

    config_path = fullfile(paths.base, 'Config.mat');
    save(config_path, 'Run_Config', 'Parameters', 'Settings');

    % ===== SWEEP SETTINGS =====
    sweep_param = Parameters.sweep_parameter;
    sweep_values = Parameters.sweep_values;
    n_values = length(sweep_values);

    % ===== METHOD DISPATCH =====
    [init_fn, step_fn, diag_fn] = resolve_method(Run_Config.method);

    % ===== MONITORING =====
    MonitorInterface.start(Run_Config, Settings);

    % ===== PARAMETER SWEEP =====
    tic;

    % Storage
    QoI_max_omega = zeros(n_values, 1);
    QoI_energy = zeros(n_values, 1);
    QoI_enstrophy = zeros(n_values, 1);
    wall_times = zeros(n_values, 1);

    base_params = Parameters;

    for i = 1:n_values
        param_val = sweep_values(i);
        fprintf('\n=== Sweep %d/%d: %s = %.3e ===\n', i, n_values, sweep_param, param_val);

        % Update parameter
        params_i = base_params;
        params_i = setfield(params_i, sweep_param, param_val);

        % Run simulation
        tic_sim = tic;
        [QoI_struct, ~] = run_sweep_simulation(params_i, Run_Config, Settings, init_fn, step_fn, diag_fn);
        wall_times(i) = toc(tic_sim);

        QoI_max_omega(i) = QoI_struct.max_omega;
        QoI_energy(i) = QoI_struct.energy;
        QoI_enstrophy(i) = QoI_struct.enstrophy;

        fprintf('[Sweep] %s = %.3e: max_omega = %.3e, time = %.2f s\n', ...
            sweep_param, param_val, QoI_max_omega(i), wall_times(i));
    end

    total_time = toc;

    % ===== RESULTS COLLECTION =====
    Results = struct();
    Results.study_id = Run_Config.study_id;
    Results.method = Run_Config.method;
    Results.sweep_parameter = sweep_param;
    Results.sweep_values = sweep_values;
    Results.max_omega = QoI_max_omega;
    Results.energy = QoI_energy;
    Results.enstrophy = QoI_enstrophy;
    Results.wall_times = wall_times;
    Results.total_time = total_time;

    % ===== SAVE RESULTS =====
    if Settings.save_data
        results_path = fullfile(paths.data, 'sweep_results.mat');
        save(results_path, 'Results', '-v7.3');
    end

    if Settings.save_figures
        generate_sweep_figures(Results, Run_Config, paths);
    end

    % ===== MONITORING COMPLETE =====
    Run_Summary = struct();
    Run_Summary.total_time = total_time;
    Run_Summary.status = 'completed';
    MonitorInterface.stop(Run_Summary);
end

%% ===== LOCAL FUNCTIONS =====

function [ok, issues] = validate_parameter_sweep(Run_Config, Parameters)
    ok = true;
    issues = {};

    if ~isfield(Run_Config, 'method')
        ok = false;
        issues{end+1} = 'Run_Config.method is required'; %#ok<AGROW>
    end

    if ~isfield(Parameters, 'sweep_parameter')
        ok = false;
        issues{end+1} = 'Parameters.sweep_parameter is required'; %#ok<AGROW>
    end

    if ~isfield(Parameters, 'sweep_values')
        ok = false;
        issues{end+1} = 'Parameters.sweep_values is required'; %#ok<AGROW>
    elseif length(Parameters.sweep_values) < 2
        ok = false;
        issues{end+1} = 'At least 2 sweep values required'; %#ok<AGROW>
    end
end

function [init_fn, step_fn, diag_fn] = resolve_method(method_name)
    switch lower(method_name)
        case 'fd'
            init_fn = @fd_init;
            step_fn = @fd_step;
            diag_fn = @fd_diagnostics;
        case {'spectral', 'fft'}
            init_fn = @spectral_init;
            step_fn = @spectral_step;
            diag_fn = @spectral_diagnostics;
        case {'fv', 'finitevolume'}
            init_fn = @fv_init;
            step_fn = @fv_step;
            diag_fn = @fv_diagnostics;
        otherwise
            error('Unknown method: %s', method_name);
    end
end

function [QoI_struct, analysis] = run_sweep_simulation(params, Run_Config, ~, init_fn, step_fn, diag_fn)
    % Run single simulation for sweep

    cfg = struct();
    cfg.Nx = params.Nx;
    cfg.Ny = params.Ny;
    cfg.Lx = params.Lx;
    cfg.Ly = params.Ly;
    cfg.dt = params.dt;
    cfg.Tfinal = params.Tfinal;
    cfg.nu = params.nu;
    cfg.ic_type = Run_Config.ic_type;
    if isfield(params, 'ic_coeff'), cfg.ic_coeff = params.ic_coeff; end
    if isfield(params, 'omega'), cfg.omega = params.omega; end

    ctx = struct();
    ctx.mode = 'parameter_sweep';

    State = init_fn(cfg, ctx);

    Tfinal = params.Tfinal;
    dt = params.dt;
    Nt = round(Tfinal / dt);

    max_vorticity_hist = zeros(1, Nt + 1);
    energy_hist = zeros(1, Nt + 1);
    enstrophy_hist = zeros(1, Nt + 1);

    Metrics = diag_fn(State, cfg, ctx);
    max_vorticity_hist(1) = Metrics.max_vorticity;
    energy_hist(1) = Metrics.kinetic_energy;
    enstrophy_hist(1) = Metrics.enstrophy;

    for n = 1:Nt
        State = step_fn(State, cfg, ctx);
        Metrics = diag_fn(State, cfg, ctx);
        max_vorticity_hist(n + 1) = Metrics.max_vorticity;
        energy_hist(n + 1) = Metrics.kinetic_energy;
        enstrophy_hist(n + 1) = Metrics.enstrophy;
    end

    analysis = struct();
    analysis.max_vorticity = max_vorticity_hist;
    analysis.energy = energy_hist;
    analysis.enstrophy = enstrophy_hist;

    QoI_struct = struct();
    QoI_struct.max_omega = max(max_vorticity_hist);
    QoI_struct.energy = energy_hist(end);
    QoI_struct.enstrophy = enstrophy_hist(end);
end

function generate_sweep_figures(Results, Run_Config, paths)
    fig = figure('Position', [100, 100, 1200, 400]);

    subplot(1, 3, 1);
    plot(Results.sweep_values, Results.max_omega, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    grid on;
    xlabel(Results.sweep_parameter);
    ylabel('max |\omega|');
    title('Max Vorticity');

    subplot(1, 3, 2);
    plot(Results.sweep_values, Results.energy, 's-', 'LineWidth', 2, 'MarkerSize', 8);
    grid on;
    xlabel(Results.sweep_parameter);
    ylabel('Kinetic Energy');
    title('Energy');

    subplot(1, 3, 3);
    plot(Results.sweep_values, Results.enstrophy, '^-', 'LineWidth', 2, 'MarkerSize', 8);
    grid on;
    xlabel(Results.sweep_parameter);
    ylabel('Enstrophy');
    title('Enstrophy');

    sgtitle(sprintf('Parameter Sweep: %s | Method: %s', Results.sweep_parameter, Run_Config.method));

    fig_path = fullfile(paths.figures_sweep, 'sweep_plot.png');
    saveas(fig, fig_path);
    close(fig);
end
