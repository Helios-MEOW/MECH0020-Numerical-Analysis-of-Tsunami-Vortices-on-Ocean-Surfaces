function [Results, paths] = mode_convergence(Run_Config, Parameters, Settings)
    % mode_convergence - METHOD-AGNOSTIC Convergence Mode
    %
    % Purpose:
    %   Orchestrates grid convergence study
    %   Works with ANY numerical method (FD, Spectral, FV)
    %   Runs multiple simulations with increasing grid resolution
    %   Computes convergence order and asymptotic behavior
    %
% This is the SINGLE SOURCE OF TRUTH for Convergence mode logic
    % NO method-specific convergence files
    %
    % Inputs:
    %   Run_Config - .method, .mode, .ic_type, .study_id
    %   Parameters - physics + numerics + convergence settings
    %   Settings - IO, monitoring, logging
    %
    % Convergence Parameters (in Parameters struct):
    %   .mesh_sizes - array of grid sizes [32, 64, 128, ...]
    %   .convergence_variable - QoI ('max_omega', 'energy', 'enstrophy')
    %
    % Outputs:
    %   Results - convergence metrics (order, QoI vs mesh)
    %   paths - directory structure

    % ===== VALIDATION =====
    [ok, issues] = validate_convergence(Run_Config, Parameters);
    if ~ok
        error('Convergence mode validation failed: %s', strjoin(issues, '; '));
    end

    % ===== SETUP =====
    if ~isfield(Run_Config, 'study_id') || isempty(Run_Config.study_id)
        Run_Config.study_id = RunIDGenerator.generate(Run_Config, Parameters);
    end

    paths = PathBuilder.get_run_paths(Run_Config.method, Run_Config.mode, Run_Config.study_id);
    PathBuilder.ensure_directories(paths);

    config_path = fullfile(paths.base, 'Config.mat');
    save(config_path, 'Run_Config', 'Parameters', 'Settings');

    % ===== CONVERGENCE SETTINGS =====
    if ~isfield(Parameters, 'mesh_sizes')
        Parameters.mesh_sizes = [32, 64, 128];
    end
    if ~isfield(Parameters, 'convergence_variable')
        Parameters.convergence_variable = 'max_omega';
    end

    mesh_sizes = Parameters.mesh_sizes;
    n_meshes = length(mesh_sizes);

    % ===== METHOD DISPATCH =====
    [init_fn, step_fn, diag_fn] = resolve_method(Run_Config.method);

    % ===== MONITORING =====
    MonitorInterface.start(Run_Config, Settings);

    % ===== CONVERGENCE STUDY =====
    tic;

    % Storage for convergence data
    QoI_values = zeros(n_meshes, 1);
    h_values = zeros(n_meshes, 1);
    wall_times = zeros(n_meshes, 1);

    base_params = Parameters;

    for i = 1:n_meshes
        N = mesh_sizes(i);
        fprintf('\n=== Convergence Mesh %d/%d: N=%d ===\n', i, n_meshes, N);

        % Update grid parameters
        params_i = base_params;
        params_i.Nx = N;
        params_i.Ny = N;

        % Run simulation for this mesh
        tic_mesh = tic;
        [QoI, analysis_i] = run_convergence_simulation(params_i, Run_Config, Settings, init_fn, step_fn, diag_fn);
        wall_times(i) = toc(tic_mesh);

        % Extract QoI
        QoI_values(i) = QoI;
        h_values(i) = base_params.Lx / N;

        fprintf('[Convergence] Mesh %d: h = %.3e, QoI = %.6e, time = %.2f s\n', ...
            i, h_values(i), QoI_values(i), wall_times(i));

        % Save mesh-specific results
        if Settings.save_data
            mesh_name = sprintf('mesh_N%d', N);
            mesh_path = fullfile(paths.data, sprintf('%s.mat', mesh_name));
            save(mesh_path, 'analysis_i', 'QoI', '-v7.3');
        end
    end

    total_time = toc;

    % ===== CONVERGENCE ANALYSIS =====
    % Compute convergence order (assume power law: error ~ h^p)
    if n_meshes >= 2
        % Fit log(QoI) vs log(h) to get slope p
        log_h = log(h_values);
        log_QoI = log(abs(QoI_values));
        p = polyfit(log_h, log_QoI, 1);
        convergence_order = p(1);
    else
        convergence_order = NaN;
    end

    % ===== RESULTS COLLECTION =====
    Results = struct();
    Results.study_id = Run_Config.study_id;
    Results.method = Run_Config.method;
    Results.mesh_sizes = mesh_sizes;
    Results.h_values = h_values;
    Results.QoI_values = QoI_values;
    Results.wall_times = wall_times;
    Results.convergence_order = convergence_order;
    Results.total_time = total_time;
    Results.convergence_variable = Parameters.convergence_variable;

    % ===== SAVE RESULTS =====
    if Settings.save_data
        results_path = fullfile(paths.data, 'convergence_results.mat');
        save(results_path, 'Results', '-v7.3');
    end

    if Settings.save_figures
        generate_convergence_figures(Results, Run_Config, paths);
    end

    if Settings.save_reports
        generate_convergence_report(Results, Run_Config, paths);
    end

    % ===== MONITORING COMPLETE =====
    Run_Summary = struct();
    Run_Summary.total_time = total_time;
    Run_Summary.status = 'completed';
    MonitorInterface.stop(Run_Summary);
end

%% ===== LOCAL FUNCTIONS =====

function [ok, issues] = validate_convergence(Run_Config, Parameters)
    % Validate Convergence mode configuration
    ok = true;
    issues = {};

    if ~isfield(Run_Config, 'method')
        ok = false;
        issues{end+1} = 'Run_Config.method is required';
    end

    if ~isfield(Parameters, 'Tfinal') || Parameters.Tfinal <= 0
        ok = false;
        issues{end+1} = 'Parameters.Tfinal must be > 0';
    end

    if isfield(Parameters, 'mesh_sizes')
        if length(Parameters.mesh_sizes) < 2
            ok = false;
            issues{end+1} = 'At least 2 mesh sizes required for convergence study';
        end
    end
end

function [init_fn, step_fn, diag_fn] = resolve_method(method_name)
    % Resolve method callbacks (same as in mode_evolution.m)
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

function [QoI, analysis] = run_convergence_simulation(params, Run_Config, Settings, init_fn, step_fn, diag_fn)
    % Run single simulation for convergence study

    % Prepare cfg
    cfg = struct();
    cfg.Nx = params.Nx;
    cfg.Ny = params.Ny;
    cfg.Lx = params.Lx;
    cfg.Ly = params.Ly;
    cfg.dt = params.dt;
    cfg.Tfinal = params.Tfinal;
    cfg.nu = params.nu;
    cfg.ic_type = Run_Config.ic_type;
    if isfield(params, 'ic_coeff')
        cfg.ic_coeff = params.ic_coeff;
    end
    if isfield(params, 'omega')
        cfg.omega = params.omega;
    end

    % Context
    ctx = struct();
    ctx.mode = 'convergence';

    % Initialize
    State = init_fn(cfg, ctx);

    % Time integration
    Tfinal = params.Tfinal;
    dt = params.dt;
    Nt = round(Tfinal / dt);

    % Time history for diagnostics
    max_vorticity_hist = zeros(1, Nt + 1);
    energy_hist = zeros(1, Nt + 1);
    enstrophy_hist = zeros(1, Nt + 1);

    % Initial diagnostics
    Metrics = diag_fn(State, cfg, ctx);
    max_vorticity_hist(1) = Metrics.max_vorticity;
    energy_hist(1) = Metrics.kinetic_energy;
    enstrophy_hist(1) = Metrics.enstrophy;

    % Time loop
    for n = 1:Nt
        State = step_fn(State, cfg, ctx);
        Metrics = diag_fn(State, cfg, ctx);
        max_vorticity_hist(n + 1) = Metrics.max_vorticity;
        energy_hist(n + 1) = Metrics.kinetic_energy;
        enstrophy_hist(n + 1) = Metrics.enstrophy;
    end

    % Extract QoI
    analysis = struct();
    analysis.max_vorticity = max_vorticity_hist;
    analysis.energy = energy_hist;
    analysis.enstrophy = enstrophy_hist;

    % Return QoI based on convergence variable
    if isfield(params, 'convergence_variable')
        QoI = extract_qoi(analysis, params.convergence_variable);
    else
        QoI = max_vorticity_hist(end);
    end
end

function QoI = extract_qoi(analysis, var_name)
    % Extract quantity of interest from analysis
    switch lower(var_name)
        case 'max_omega'
            QoI = max(analysis.max_vorticity);
        case 'energy'
            QoI = analysis.energy(end);
        case 'enstrophy'
            QoI = analysis.enstrophy(end);
        otherwise
            QoI = max(analysis.max_vorticity);
    end
end

function generate_convergence_figures(Results, Run_Config, paths)
    % Generate convergence plots

    fig = figure('Position', [100, 100, 1000, 400]);

    % Plot 1: QoI vs h (log-log)
    subplot(1, 2, 1);
    loglog(Results.h_values, Results.QoI_values, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    grid on;
    xlabel('Grid spacing h');
    ylabel(Results.convergence_variable);
    title(sprintf('Convergence: order = %.2f', Results.convergence_order));

    % Plot 2: Wall time vs N
    subplot(1, 2, 2);
    plot(Results.mesh_sizes, Results.wall_times, 's-', 'LineWidth', 2, 'MarkerSize', 8);
    grid on;
    xlabel('Grid size N');
    ylabel('Wall time (s)');
    title('Computational cost');

    sgtitle(sprintf('Convergence Study: %s | Method: %s', Run_Config.ic_type, Run_Config.method));

    % Save
    fig_path = fullfile(paths.figures_convergence, 'convergence_plot.png');
    saveas(fig, fig_path);
    close(fig);
end

function generate_convergence_report(Results, Run_Config, paths)
    % Generate convergence report (text file)

    report_path = fullfile(paths.reports, 'convergence_report.txt');
    fid = fopen(report_path, 'w');

    fprintf(fid, '=== CONVERGENCE STUDY REPORT ===\n\n');
    fprintf(fid, 'Method: %s\n', Run_Config.method);
    fprintf(fid, 'IC Type: %s\n', Run_Config.ic_type);
    fprintf(fid, 'Convergence Variable: %s\n\n', Results.convergence_variable);

    fprintf(fid, 'Mesh Sizes: %s\n', mat2str(Results.mesh_sizes));
    fprintf(fid, 'Convergence Order: %.4f\n\n', Results.convergence_order);

    fprintf(fid, '--- Detailed Results ---\n');
    for i = 1:length(Results.mesh_sizes)
        fprintf(fid, 'N = %d: h = %.3e, QoI = %.6e, time = %.2f s\n', ...
            Results.mesh_sizes(i), Results.h_values(i), Results.QoI_values(i), Results.wall_times(i));
    end

    fprintf(fid, '\nTotal Time: %.2f s\n', Results.total_time);

    fclose(fid);
end
