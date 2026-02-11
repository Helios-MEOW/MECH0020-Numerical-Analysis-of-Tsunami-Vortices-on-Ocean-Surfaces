function [Results, paths] = mode_convergence(Run_Config, Parameters, Settings)
    % mode_convergence - METHOD-AGNOSTIC Convergence Mode
    %
    % Purpose:
    %   Orchestrates convergence studies across supported methods.
    %   - FD/FV: mesh-size refinement (h-based)
    %   - Spectral: frequency-domain refinement via explicit k-vectors (dk-based)

    % ===== VALIDATION =====
    [ok, issues] = validate_convergence(Run_Config, Parameters);
    if ~ok
        error('Convergence mode validation failed: %s', strjoin(issues, '; '));
    end

    % ===== SETUP =====
    if ~isfield(Run_Config, 'study_id') || isempty(Run_Config.study_id)
        Run_Config.study_id = RunIDGenerator.generate(Run_Config, Parameters);
    end

    output_root = resolve_output_root(Settings);
    paths = PathBuilder.get_run_paths(Run_Config.method, Run_Config.mode, Run_Config.study_id, output_root);
    PathBuilder.ensure_directories(paths);

    config_path = fullfile(paths.config, 'Config.mat');
    save(config_path, 'Run_Config', 'Parameters', 'Settings');

    % ===== CONVERGENCE SETTINGS =====
    is_spectral = is_spectral_method(Run_Config.method);
    use_spectral_levels = is_spectral && has_spectral_levels(Parameters);

    if ~isfield(Parameters, 'convergence_variable')
        Parameters.convergence_variable = 'max_omega';
    end

    if use_spectral_levels
        levels = Parameters.spectral_convergence.levels;
        n_levels = numel(levels);
        mesh_sizes = [];
    else
        if ~isfield(Parameters, 'mesh_sizes')
            Parameters.mesh_sizes = [32, 64, 128];
        end
        mesh_sizes = Parameters.mesh_sizes;
        n_levels = length(mesh_sizes);
        levels = [];
    end

    % ===== METHOD DISPATCH =====
    [init_fn, step_fn, diag_fn] = resolve_method(Run_Config.method);

    % ===== MONITORING =====
    MonitorInterface.start(Run_Config, Settings);

    % ===== CONVERGENCE STUDY =====
    tic;

    % Storage
    QoI_values = zeros(n_levels, 1);
    refine_scale = zeros(n_levels, 1); % h for FD/FV, dk for spectral
    wall_times = zeros(n_levels, 1);
    level_labels = strings(n_levels, 1);
    Nx_values = zeros(n_levels, 1);
    Ny_values = zeros(n_levels, 1);

    base_params = Parameters;

    for i = 1:n_levels
        if use_spectral_levels
            [params_i, level_label, dk_val] = prepare_spectral_level_params(base_params, levels(i), i);
            refine_scale(i) = dk_val;
            level_labels(i) = string(level_label);
            Nx_values(i) = params_i.Nx;
            Ny_values(i) = params_i.Ny;
            fprintf('\n=== Spectral Convergence Level %d/%d: %s (Nx=%d, Ny=%d, dk=%.3e) ===\n', ...
                i, n_levels, level_label, params_i.Nx, params_i.Ny, dk_val);
        else
            N = mesh_sizes(i);
            params_i = base_params;
            params_i.Nx = N;
            params_i.Ny = N;
            refine_scale(i) = base_params.Lx / N;
            level_labels(i) = string(sprintf('N%d', N));
            Nx_values(i) = N;
            Ny_values(i) = N;
            fprintf('\n=== Convergence Mesh %d/%d: N=%d ===\n', i, n_levels, N);
        end

        tic_mesh = tic;
        [QoI, analysis_i] = run_convergence_simulation(params_i, Run_Config, Settings, init_fn, step_fn, diag_fn);
        wall_times(i) = toc(tic_mesh);
        QoI_values(i) = QoI;

        if use_spectral_levels
            fprintf('[Convergence] Level %d: dk = %.3e, QoI = %.6e, time = %.2f s\n', ...
                i, refine_scale(i), QoI_values(i), wall_times(i));
            mesh_name = sprintf('spectral_level_%02d', i);
        else
            fprintf('[Convergence] Mesh %d: h = %.3e, QoI = %.6e, time = %.2f s\n', ...
                i, refine_scale(i), QoI_values(i), wall_times(i));
            mesh_name = sprintf('mesh_N%d', Nx_values(i));
        end

        if Settings.save_data
            mesh_path = fullfile(paths.data, sprintf('%s.mat', mesh_name));
            save(mesh_path, 'analysis_i', 'QoI', '-v7.3');
        end
    end

    total_time = toc;

    % ===== CONVERGENCE ANALYSIS =====
    valid = isfinite(refine_scale) & (refine_scale > 0) & isfinite(QoI_values);
    if nnz(valid) >= 2
        log_scale = log(refine_scale(valid));
        log_qoi = log(abs(QoI_values(valid)) + eps);
        p = polyfit(log_scale, log_qoi, 1);
        convergence_order = p(1);
    else
        convergence_order = NaN;
    end

    % ===== RESULTS COLLECTION =====
    Results = struct();
    Results.study_id = Run_Config.study_id;
    Results.method = Run_Config.method;
    Results.level_labels = cellstr(level_labels);
    Results.Nx_values = Nx_values;
    Results.Ny_values = Ny_values;
    Results.QoI_values = QoI_values;
    Results.wall_times = wall_times;
    Results.convergence_order = convergence_order;
    Results.total_time = total_time;
    Results.convergence_variable = Parameters.convergence_variable;

    if use_spectral_levels
        Results.refinement_axis = 'dk';
        Results.dk_values = refine_scale;
        Results.h_values = refine_scale; % compatibility for downstream plotting paths
        Results.mesh_sizes = Nx_values;
    else
        Results.refinement_axis = 'h';
        Results.h_values = refine_scale;
        Results.mesh_sizes = mesh_sizes;
    end

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

    is_spectral = is_spectral_method(Run_Config.method);
    if is_spectral && has_spectral_levels(Parameters)
        [ok_levels, level_issues] = validate_spectral_levels(Parameters.spectral_convergence.levels);
        if ~ok_levels
            ok = false;
            issues = [issues, level_issues]; %#ok<AGROW>
        end
    else
        if isfield(Parameters, 'mesh_sizes')
            if length(Parameters.mesh_sizes) < 2
                ok = false;
                issues{end+1} = 'At least 2 mesh sizes required for convergence study';
            end
        end
    end
end

function [ok, issues] = validate_spectral_levels(levels)
    ok = true;
    issues = {};

    if isempty(levels)
        ok = false;
        issues{end+1} = 'spectral_convergence.levels must not be empty';
        return;
    end

    prev_scale = inf;
    for i = 1:numel(levels)
        level = levels(i);
        if ~isfield(level, 'kx') || ~isfield(level, 'ky')
            ok = false;
            issues{end+1} = sprintf('spectral level %d must define both kx and ky', i);
            continue;
        end

        kx = level.kx(:).';
        ky = level.ky(:).';

        if mod(numel(kx), 2) ~= 0 || mod(numel(ky), 2) ~= 0
            ok = false;
            issues{end+1} = sprintf('spectral level %d requires even-length k vectors', i);
        end

        dkx = spectral_min_positive_spacing(kx);
        dky = spectral_min_positive_spacing(ky);
        if ~isfinite(dkx) || dkx <= 0 || ~isfinite(dky) || dky <= 0
            ok = false;
            issues{end+1} = sprintf('spectral level %d has invalid k spacing', i);
        end

        scale = spectral_refinement_scale(kx, ky);

        % Monotonic refinement: effective spectral length scale should decrease.
        if i > 1 && scale >= prev_scale - 1e-14
            ok = false;
            issues{end+1} = sprintf('spectral level %d does not refine frequency resolution monotonically', i);
        end
        prev_scale = scale;
    end
end

function [init_fn, step_fn, diag_fn] = resolve_method(method_name)
    switch lower(method_name)
        case 'fd'
            init_fn = @(cfg, ctx) FiniteDifferenceMethod('init', cfg, ctx);
            step_fn = @(State, cfg, ctx) FiniteDifferenceMethod('step', State, cfg, ctx);
            diag_fn = @(State, cfg, ctx) FiniteDifferenceMethod('diagnostics', State, cfg, ctx);
        case {'spectral', 'fft'}
            init_fn = @(cfg, ctx) SpectralMethod('init', cfg, ctx);
            step_fn = @(State, cfg, ctx) SpectralMethod('step', State, cfg, ctx);
            diag_fn = @(State, cfg, ctx) SpectralMethod('diagnostics', State, cfg, ctx);
        case {'fv', 'finitevolume', 'finite volume'}
            init_fn = @(cfg, ctx) FiniteVolumeMethod('init', cfg, ctx);
            step_fn = @(State, cfg, ctx) FiniteVolumeMethod('step', State, cfg, ctx);
            diag_fn = @(State, cfg, ctx) FiniteVolumeMethod('diagnostics', State, cfg, ctx);
        otherwise
            error('Unknown method: %s', method_name);
    end
end

function [params_i, level_label, dk_val] = prepare_spectral_level_params(base_params, level, level_index)
    params_i = base_params;

    kx = level.kx(:).';
    ky = level.ky(:).';

    params_i.kx = kx;
    params_i.ky = ky;
    params_i.Nx = numel(kx);
    params_i.Ny = numel(ky);

    dk_val = spectral_refinement_scale(kx, ky);

    if isfield(level, 'label') && ~isempty(level.label)
        level_label = char(string(level.label));
    else
        level_label = sprintf('k_level_%02d', level_index);
    end
end

function [QoI, analysis] = run_convergence_simulation(params, Run_Config, ~, init_fn, step_fn, diag_fn)
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
    if isfield(params, 'kx'), cfg.kx = params.kx; end
    if isfield(params, 'ky'), cfg.ky = params.ky; end
    if isfield(params, 'Nz'), cfg.Nz = params.Nz; end
    if isfield(params, 'Lz'), cfg.Lz = params.Lz; end
    if isfield(params, 'method_config') && isfield(params.method_config, 'fv3d')
        cfg.fv3d = params.method_config.fv3d;
    end

    ctx = struct();
    ctx.mode = 'convergence';

    State = init_fn(cfg, ctx);

    Tfinal = params.Tfinal;
    dt = params.dt;
    Nt = max(0, round(Tfinal / dt));

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

    if isfield(params, 'convergence_variable')
        QoI = extract_qoi(analysis, params.convergence_variable);
    else
        QoI = max_vorticity_hist(end);
    end
end

function QoI = extract_qoi(analysis, var_name)
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
    fig = figure('Position', [100, 100, 1000, 400]);

    if isfield(Results, 'refinement_axis') && strcmpi(Results.refinement_axis, 'dk')
        x_label = 'Spectral spacing dk';
    else
        x_label = 'Grid spacing h';
    end

    subplot(1, 2, 1);
    loglog(Results.h_values, abs(Results.QoI_values) + eps, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    grid on;
    xlabel(x_label);
    ylabel(Results.convergence_variable);
    title(sprintf('Convergence: order = %.2f', Results.convergence_order));

    subplot(1, 2, 2);
    plot(Results.Nx_values, Results.wall_times, 's-', 'LineWidth', 2, 'MarkerSize', 8);
    grid on;
    xlabel('Resolution Nx');
    ylabel('Wall time (s)');
    title('Computational cost');

    sgtitle(sprintf('Convergence Study: %s | Method: %s', Run_Config.ic_type, Run_Config.method));

    fig_path = fullfile(paths.figures_convergence, 'convergence_plot.png');
    saveas(fig, fig_path);
    close(fig);
end

function generate_convergence_report(Results, Run_Config, paths)
    report_path = fullfile(paths.reports, 'convergence_report.txt');
    fid = fopen(report_path, 'w');

    fprintf(fid, '=== CONVERGENCE STUDY REPORT ===\n\n');
    fprintf(fid, 'Method: %s\n', Run_Config.method);
    fprintf(fid, 'IC Type: %s\n', Run_Config.ic_type);
    fprintf(fid, 'Convergence Variable: %s\n', Results.convergence_variable);
    fprintf(fid, 'Refinement Axis: %s\n\n', Results.refinement_axis);

    fprintf(fid, 'Convergence Order: %.4f\n\n', Results.convergence_order);

    fprintf(fid, '--- Detailed Results ---\n');
    for i = 1:numel(Results.QoI_values)
        fprintf(fid, '%s: Nx=%d, Ny=%d, scale=%.3e, QoI=%.6e, time=%.2f s\n', ...
            Results.level_labels{i}, Results.Nx_values(i), Results.Ny_values(i), ...
            Results.h_values(i), Results.QoI_values(i), Results.wall_times(i));
    end

    fprintf(fid, '\nTotal Time: %.2f s\n', Results.total_time);
    fclose(fid);
end

function tf = is_spectral_method(method_name)
    token = lower(char(string(method_name)));
    tf = strcmp(token, 'spectral') || strcmp(token, 'fft');
end

function tf = has_spectral_levels(Parameters)
    tf = isfield(Parameters, 'spectral_convergence') && ...
         isstruct(Parameters.spectral_convergence) && ...
         isfield(Parameters.spectral_convergence, 'levels') && ...
         ~isempty(Parameters.spectral_convergence.levels);
end

function dk = spectral_min_positive_spacing(k)
    vals = unique(sort(k(:)));
    dv = diff(vals);
    dv = dv(dv > 0);
    if isempty(dv)
        dk = NaN;
    else
        dk = min(dv);
    end
end

function scale = spectral_refinement_scale(kx, ky)
    % Use inverse resolved cutoff as a stable refinement length scale.
    kmax_x = max(abs(kx(:)));
    kmax_y = max(abs(ky(:)));
    kmax = max([kmax_x, kmax_y, eps]);
    scale = 1 / kmax;
end

function output_root = resolve_output_root(Settings)
    output_root = 'Results';
    if isfield(Settings, 'output_root') && ~isempty(Settings.output_root)
        output_root = char(string(Settings.output_root));
    end
end

