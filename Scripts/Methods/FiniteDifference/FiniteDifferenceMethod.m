function varargout = FiniteDifferenceMethod(action, varargin)
% FiniteDifferenceMethod - Finite-difference method module (Arakawa + RK4).
%
% Supported actions:
%   callbacks                     -> struct with init/step/diagnostics/run handles
%   init(cfg, ctx)                -> State
%   step(State, cfg, ctx)         -> State
%   diagnostics(State, cfg, ctx)  -> Metrics
%   run(Parameters)               -> [fig_handle, analysis]
%
% Notes:
%   - The action-based API is the contract used by mode dispatchers.
%   - The numerical core uses the full Arakawa Jacobian for conservative
%     advection and RK4 for time integration.
%   - This implementation intentionally keeps the module self-contained so
%     direct calls from tests and scripts behave like dispatcher runs.

    narginchk(1, inf);
    action_name = lower(string(action));

    switch action_name
        case "callbacks"
            callbacks = struct();
            callbacks.init = @(cfg, ctx) FiniteDifferenceMethod("init", cfg, ctx);
            callbacks.step = @(State, cfg, ctx) FiniteDifferenceMethod("step", State, cfg, ctx);
            callbacks.diagnostics = @(State, cfg, ctx) FiniteDifferenceMethod("diagnostics", State, cfg, ctx);
            callbacks.run = @(Parameters) FiniteDifferenceMethod("run", Parameters);
            varargout{1} = callbacks;

        case "init"
            cfg = varargin{1};
            varargout{1} = fd_init_internal(cfg);

        case "step"
            State = varargin{1};
            cfg = varargin{2};
            varargout{1} = fd_step_internal(State, cfg);

        case "diagnostics"
            State = varargin{1};
            varargout{1} = fd_diagnostics_internal(State);

        case "run"
            Parameters = varargin{1};
            [fig_handle, analysis] = fd_run_internal(Parameters);
            varargout{1} = fig_handle;
            varargout{2} = analysis;

        otherwise
            error("FD:InvalidAction", ...
                "Unsupported action '%s'. Valid actions: callbacks, init, step, diagnostics, run.", ...
                char(string(action)));
    end
end

function State = fd_init_internal(cfg)
% fd_init_internal - Build initial FD state for dispatcher-driven runs.

    validate_fd_cfg(cfg, "init");
    setup = fd_setup_internal(cfg);

    omega_initial = fd_build_initial_vorticity(cfg, setup.X, setup.Y);
    omega_initial = reshape(omega_initial, setup.Ny, setup.Nx);
    if setup.use_gpu
        omega_initial = gpuArray(omega_initial);
    end
    psi_initial = reshape(setup.solve_poisson(omega_initial(:)), setup.Ny, setup.Nx);

    State = struct();
    State.omega = omega_initial;
    State.psi = psi_initial;
    State.t = 0.0;
    State.step = 0;
    State.setup = setup;
end

function State = fd_step_internal(State, cfg)
% fd_step_internal - Advance one explicit RK4 step.

    validate_fd_cfg(cfg, "step");
    dt = cfg.dt;
    nu = cfg.nu;
    setup = State.setup;

    omega_vector = State.omega(:);

    % Select RHS function based on Arakawa toggle
    if setup.use_arakawa
        rhs_fn = @(w) rhs_fd_arakawa(w, setup, nu);
    else
        rhs_fn = @(w) rhs_fd_simple(w, setup, nu);
    end

    % RK4 stages
    stage1 = rhs_fn(omega_vector);
    stage2 = rhs_fn(omega_vector + 0.5 * dt * stage1);
    stage3 = rhs_fn(omega_vector + 0.5 * dt * stage2);
    stage4 = rhs_fn(omega_vector + dt * stage3);

    omega_vector = omega_vector + (dt / 6) * (stage1 + 2 * stage2 + 2 * stage3 + stage4);
    State.omega = reshape(omega_vector, setup.Ny, setup.Nx);
    State.psi = reshape(setup.solve_poisson(omega_vector), setup.Ny, setup.Nx);
    State.t = State.t + dt;
    State.step = State.step + 1;
end

function Metrics = fd_diagnostics_internal(State)
% fd_diagnostics_internal - Compute common diagnostics from current state.

    omega = State.omega;
    psi = State.psi;
    setup = State.setup;

    [velocity_u, velocity_v] = velocity_from_streamfunction(psi, setup);
    kinetic_energy = 0.5 * sum((velocity_u(:).^2 + velocity_v(:).^2)) * setup.dx * setup.dy;
    enstrophy = 0.5 * sum(omega(:).^2) * setup.dx * setup.dy;

    Metrics = struct();
    Metrics.max_vorticity = gather_if_gpu(max(abs(omega(:))));
    Metrics.enstrophy = gather_if_gpu(enstrophy);
    Metrics.kinetic_energy = gather_if_gpu(kinetic_energy);
    Metrics.peak_speed = gather_if_gpu(max(sqrt(velocity_u(:).^2 + velocity_v(:).^2)));
    Metrics.t = State.t;
    Metrics.step = State.step;
end

function [fig_handle, analysis] = fd_run_internal(Parameters)
% fd_run_internal - Self-contained batch run path used by tests/scripts.

    run_options = normalize_fd_run_options(Parameters);
    validate_fd_cfg(run_options, "run");

    cfg = fd_cfg_from_parameters(run_options);
    snapshot_times = run_options.snap_times(:).';
    n_snapshots = numel(snapshot_times);
    n_steps = max(0, ceil(cfg.Tfinal / cfg.dt));

    setup_start_cpu = cputime;
    setup_start_wall = tic;
    State = fd_init_internal(cfg);
    setup_cpu_time_s = cputime - setup_start_cpu;
    setup_wall_time_s = toc(setup_start_wall);

    omega_snapshots = zeros(cfg.Ny, cfg.Nx, n_snapshots);
    psi_snapshots = zeros(cfg.Ny, cfg.Nx, n_snapshots);

    snapshot_index = 1;
    while snapshot_index <= n_snapshots && State.t >= snapshot_times(snapshot_index) - 1e-12
        omega_snapshots(:, :, snapshot_index) = State.omega;
        psi_snapshots(:, :, snapshot_index) = State.psi;
        snapshot_index = snapshot_index + 1;
    end

    progress_stride = resolve_progress_stride(run_options, n_steps);
    live_stride = resolve_live_stride(run_options, n_steps);
    live_preview = open_live_preview_if_requested(run_options, cfg, State.omega);

    if n_steps > 0
        scheme_label = 'Arakawa';
        if ~cfg.use_arakawa, scheme_label = 'Central'; end
        gpu_label = '';
        if cfg.use_gpu, gpu_label = ' [GPU]'; end
        fprintf('[FD] Running %d steps (dt=%.3e, Tfinal=%.3f, scheme=%s%s)\n', ...
            n_steps, cfg.dt, cfg.Tfinal, scheme_label, gpu_label);
    end

    solve_start_cpu = cputime;
    solve_start_wall = tic;

    for step_index = 1:n_steps
        State = fd_step_internal(State, cfg);

        while snapshot_index <= n_snapshots && State.t >= snapshot_times(snapshot_index) - 1e-12
            omega_snapshots(:, :, snapshot_index) = State.omega;
            psi_snapshots(:, :, snapshot_index) = State.psi;
            snapshot_index = snapshot_index + 1;
        end

        if mod(step_index, progress_stride) == 0 || step_index == 1 || step_index == n_steps
            Metrics_live = fd_diagnostics_internal(State);
            cfl_estimate = compute_cfl_estimate(Metrics_live.peak_speed, cfg.dt, State.setup);
            fprintf(['[FD] %6.2f%% | step %d/%d | t = %.3f / %.3f | ', ...
                     'max|omega| = %.3e | CFL(est)=%.3f\n'], ...
                100 * step_index / max(1, n_steps), step_index, n_steps, State.t, cfg.Tfinal, ...
                Metrics_live.max_vorticity, cfl_estimate);
        end

        if mod(step_index, live_stride) == 0 || step_index == n_steps
            update_live_preview(live_preview, State.omega, State.t);
        end
    end

    solve_cpu_time_s = cputime - solve_start_cpu;
    solve_wall_time_s = toc(solve_start_wall);
    close_live_preview(live_preview);

    if snapshot_index <= n_snapshots
        % Ensure all requested snapshot slots are populated for downstream tools.
        omega_snapshots(:, :, snapshot_index:end) = repmat(State.omega, 1, 1, n_snapshots - snapshot_index + 1);
        psi_snapshots(:, :, snapshot_index:end) = repmat(State.psi, 1, 1, n_snapshots - snapshot_index + 1);
    end

    % Gather GPU arrays back to CPU for downstream plotting/saving
    omega_snapshots = gather_if_gpu(omega_snapshots);
    psi_snapshots = gather_if_gpu(psi_snapshots);

    analysis = struct();
    if cfg.use_arakawa
        analysis.method = "finite_difference_arakawa_rk4";
    else
        analysis.method = "finite_difference_central_rk4";
    end
    analysis.use_arakawa = cfg.use_arakawa;
    analysis.use_gpu = cfg.use_gpu;
    analysis.nu = cfg.nu;
    analysis.Lx = cfg.Lx;
    analysis.Ly = cfg.Ly;
    analysis.Nx = cfg.Nx;
    analysis.Ny = cfg.Ny;
    analysis.dx = State.setup.dx;
    analysis.dy = State.setup.dy;
    analysis.delta = State.setup.delta;
    analysis.dt = cfg.dt;
    analysis.Tfinal = cfg.Tfinal;
    analysis.Nt = n_steps;
    analysis.grid_points = cfg.Nx * cfg.Ny;
    analysis.unknowns = analysis.grid_points;
    analysis.rhs_calls = 4 * n_steps;
    analysis.poisson_solves = 1 + 5 * n_steps;
    analysis.poisson_matrix_n = analysis.grid_points;
    analysis.poisson_matrix_nnz = nnz(State.setup.A);
    analysis.setup_wall_time_s = setup_wall_time_s;
    analysis.setup_cpu_time_s = setup_cpu_time_s;
    analysis.solve_wall_time_s = solve_wall_time_s;
    analysis.solve_cpu_time_s = solve_cpu_time_s;
    analysis.wall_time_s = setup_wall_time_s + solve_wall_time_s;
    analysis.cpu_time_s = setup_cpu_time_s + solve_cpu_time_s;
    analysis.snapshot_times = snapshot_times(:);
    analysis.time_vec = snapshot_times(:);
    analysis.snapshots_stored = n_snapshots;
    analysis.omega_snaps = omega_snapshots;
    analysis.psi_snaps = psi_snapshots;

    analysis = append_snapshot_metrics(analysis, State.setup);
    analysis = maybe_merge_unified_metrics(analysis, run_options);

    if ~isfield(analysis, "peak_abs_omega") || isempty(analysis.peak_abs_omega)
        analysis.peak_abs_omega = max(abs(omega_snapshots(:)));
    end
    analysis.peak_vorticity = analysis.peak_abs_omega;

    fig_handle = create_fd_summary_figure(analysis, run_options);
    maybe_write_vorticity_animation(analysis, cfg, run_options);
end

function run_options = normalize_fd_run_options(Parameters)
% normalize_fd_run_options - Populate optional run flags and defaults.

    run_options = Parameters;

    if ~isfield(run_options, "snap_times") || isempty(run_options.snap_times)
        if isfield(run_options, "num_snapshots") && run_options.num_snapshots > 1
            n_snapshots = run_options.num_snapshots;
        else
            n_snapshots = 9;
        end
        run_options.snap_times = linspace(0, run_options.Tfinal, n_snapshots);
    end

    if ~isfield(run_options, "mode") || isempty(run_options.mode)
        run_options.mode = "solve";
    end
    if ~isfield(run_options, "progress_stride") || isempty(run_options.progress_stride)
        run_options.progress_stride = 0;
    end
    if ~isfield(run_options, "live_preview") || isempty(run_options.live_preview)
        run_options.live_preview = false;
    end
    if ~isfield(run_options, "live_stride") || isempty(run_options.live_stride)
        run_options.live_stride = 0;
    end
    if ~isfield(run_options, "create_animations") || isempty(run_options.create_animations)
        run_options.create_animations = false;
    end
    if ~isfield(run_options, "animation_fps") || isempty(run_options.animation_fps)
        if isfield(run_options, "animation_frame_rate") && ~isempty(run_options.animation_frame_rate)
            run_options.animation_fps = run_options.animation_frame_rate;
        else
            run_options.animation_fps = 20;
        end
    end
    if ~isfield(run_options, "animation_format") || isempty(run_options.animation_format)
        run_options.animation_format = "gif";
    end
    if ~isfield(run_options, "animation_dir") || isempty(run_options.animation_dir)
        run_options.animation_dir = fullfile("Figures", "Finite Difference", "Animations");
    end
    if ~isfield(run_options, "animation_quality") || isempty(run_options.animation_quality)
        run_options.animation_quality = 90;
    end

    run_options.live_preview = logical(run_options.live_preview);
    run_options.create_animations = logical(run_options.create_animations);
end

function validate_fd_cfg(cfg, caller_name)
% validate_fd_cfg - Guard required fields for init/step/run paths.

    required_fields = {'nu', 'Lx', 'Ly', 'Nx', 'Ny', 'dt', 'Tfinal'};
    for idx = 1:numel(required_fields)
        field_name = required_fields{idx};
        if ~isfield(cfg, field_name)
            error('FD:MissingField', 'Missing required field for %s: %s', caller_name, field_name);
        end
    end

    if cfg.Nx <= 0 || cfg.Ny <= 0 || cfg.dt <= 0 || cfg.Tfinal <= 0 || cfg.Lx <= 0 || cfg.Ly <= 0
        error('FD:InvalidConfig', ...
            'Nx, Ny, dt, Tfinal, Lx, and Ly must all be positive in %s path.', caller_name);
    end
end

function cfg = fd_cfg_from_parameters(Parameters)
% fd_cfg_from_parameters - Build canonical cfg used by init/step functions.

    cfg = struct();
    cfg.Nx = Parameters.Nx;
    cfg.Ny = Parameters.Ny;
    cfg.Lx = Parameters.Lx;
    cfg.Ly = Parameters.Ly;
    cfg.dt = Parameters.dt;
    cfg.Tfinal = Parameters.Tfinal;
    cfg.nu = Parameters.nu;
    cfg.ic_type = Parameters.ic_type;

    if isfield(Parameters, "ic_coeff")
        cfg.ic_coeff = Parameters.ic_coeff;
    end
    if isfield(Parameters, "omega")
        cfg.omega = Parameters.omega;
    end
    if isfield(Parameters, "delta")
        cfg.delta = Parameters.delta;
    else
        cfg.delta = [];
    end

    % Arakawa toggle (default: on for conservative advection)
    if isfield(Parameters, "use_arakawa")
        cfg.use_arakawa = logical(Parameters.use_arakawa);
    else
        cfg.use_arakawa = true;
    end

    % GPU acceleration toggle (default: off)
    if isfield(Parameters, "use_gpu")
        cfg.use_gpu = logical(Parameters.use_gpu);
    else
        cfg.use_gpu = false;
    end
end

function setup = fd_setup_internal(cfg)
% fd_setup_internal - Precompute finite-difference operators and solvers.

    Nx = cfg.Nx;
    Ny = cfg.Ny;
    Lx = cfg.Lx;
    Ly = cfg.Ly;

    dx = Lx / Nx;
    dy = Ly / Ny;
    if isfield(cfg, "delta") && ~isempty(cfg.delta) && isfinite(cfg.delta) && cfg.delta > 0
        delta = cfg.delta;
    else
        delta = dx;
    end

    x = linspace(0, Lx - dx, Nx);
    y = linspace(0, Ly - dy, Ny);
    [X, Y] = meshgrid(x, y);

    ex = ones(Nx, 1);
    ey = ones(Ny, 1);
    Tx = spdiags([ex, -2 * ex, ex], [-1, 0, 1], Nx, Nx);
    Ty = spdiags([ey, -2 * ey, ey], [-1, 0, 1], Ny, Ny);
    Tx(1, end) = 1;
    Tx(end, 1) = 1;
    Ty(1, end) = 1;
    Ty(end, 1) = 1;

    Ix = speye(Nx);
    Iy = speye(Ny);
    A = (1 / dx^2) * kron(Tx, Iy) + (1 / dy^2) * kron(Ix, Ty);

    % Factorize once to avoid repeated sparse factorization in the time loop.
    try
        poisson_solver = decomposition(A, "lu");
        solve_poisson = @(omega_vector) delta^2 * (poisson_solver \ omega_vector);
    catch
        solve_poisson = @(omega_vector) delta^2 * (A \ omega_vector);
    end

    % Resolve toggle flags
    if isfield(cfg, 'use_arakawa')
        use_arakawa = logical(cfg.use_arakawa);
    else
        use_arakawa = true;
    end
    if isfield(cfg, 'use_gpu')
        use_gpu = logical(cfg.use_gpu);
    else
        use_gpu = false;
    end

    % GPU acceleration: convert key arrays to gpuArray
    if use_gpu
        if ~(exist('gpuDevice', 'file') == 2 || exist('gpuDevice', 'builtin') > 0)
            warning('FD:NoGPU', 'GPU requested but Parallel Computing Toolbox not available. Falling back to CPU.');
            use_gpu = false;
        else
            try
                gpu_info = gpuDevice;
                if ~gpu_info.DeviceAvailable
                    warning('FD:GPUUnavailable', 'GPU device not available. Falling back to CPU.');
                    use_gpu = false;
                end
            catch
                warning('FD:GPUError', 'Could not initialise GPU device. Falling back to CPU.');
                use_gpu = false;
            end
        end
    end

    if use_gpu
        X = gpuArray(X);
        Y = gpuArray(Y);
        A = gpuArray(A);

        try
            poisson_solver = decomposition(A, "lu");
            solve_poisson = @(omega_vector) delta^2 * (poisson_solver \ omega_vector);
        catch
            solve_poisson = @(omega_vector) delta^2 * (A \ omega_vector);
        end
    end

    setup = struct();
    setup.Nx = Nx;
    setup.Ny = Ny;
    setup.Lx = Lx;
    setup.Ly = Ly;
    setup.dx = dx;
    setup.dy = dy;
    setup.delta = delta;
    setup.X = X;
    setup.Y = Y;
    setup.A = A;
    setup.solve_poisson = solve_poisson;
    setup.shift_xp = @(F) circshift(F, [0, +1]);
    setup.shift_xm = @(F) circshift(F, [0, -1]);
    setup.shift_yp = @(F) circshift(F, [+1, 0]);
    setup.shift_ym = @(F) circshift(F, [-1, 0]);
    setup.use_arakawa = use_arakawa;
    setup.use_gpu = use_gpu;
end

function omega_initial = fd_build_initial_vorticity(cfg, X, Y)
% fd_build_initial_vorticity - Resolve initial condition source for omega.

    if isfield(cfg, "omega") && ~isempty(cfg.omega)
        omega_initial = cfg.omega;
        return;
    end

    if isfield(cfg, "ic_coeff")
        ic_coeff = cfg.ic_coeff;
    else
        ic_coeff = [];
    end

    if exist("initialise_omega", "file") == 2
        omega_initial = initialise_omega(X, Y, cfg.ic_type, ic_coeff);
    elseif exist("ic_factory", "file") == 2
        omega_initial = ic_factory(X, Y, cfg.ic_type, ic_coeff);
    else
        omega_initial = exp(-2 * (X.^2 + Y.^2));
    end
end

function rhs_vector = rhs_fd_arakawa(omega_vector, setup, nu)
% rhs_fd_arakawa - Conservative Arakawa Jacobian + diffusion RHS.

    Nx = setup.Nx;
    Ny = setup.Ny;
    dx = setup.dx;
    dy = setup.dy;

    omega_matrix = reshape(omega_vector, Ny, Nx);
    psi_matrix = reshape(setup.solve_poisson(omega_vector), Ny, Nx);

    shift_xp = setup.shift_xp;
    shift_xm = setup.shift_xm;
    shift_yp = setup.shift_yp;
    shift_ym = setup.shift_ym;

    psi_ip = shift_xp(psi_matrix);
    psi_im = shift_xm(psi_matrix);
    psi_jp = shift_yp(psi_matrix);
    psi_jm = shift_ym(psi_matrix);

    psi_ipjp = shift_yp(psi_ip);
    psi_ipjm = shift_ym(psi_ip);
    psi_imjp = shift_yp(psi_im);
    psi_imjm = shift_ym(psi_im);

    omega_ip = shift_xp(omega_matrix);
    omega_im = shift_xm(omega_matrix);
    omega_jp = shift_yp(omega_matrix);
    omega_jm = shift_ym(omega_matrix);

    omega_ipjp = shift_yp(omega_ip);
    omega_ipjm = shift_ym(omega_ip);
    omega_imjp = shift_yp(omega_im);
    omega_imjm = shift_ym(omega_im);

    jacobian_1 = ((psi_ip - psi_im) .* (omega_jp - omega_jm) ...
                - (psi_jp - psi_jm) .* (omega_ip - omega_im)) / (4 * dx * dy);

    jacobian_2 = (psi_ip .* (omega_ipjp - omega_ipjm) ...
                - psi_im .* (omega_imjp - omega_imjm) ...
                - psi_jp .* (omega_ipjp - omega_imjp) ...
                + psi_jm .* (omega_ipjm - omega_imjm)) / (4 * dx * dy);

    jacobian_3 = (psi_ipjp .* (omega_jp - omega_ip) ...
                - psi_imjm .* (omega_im - omega_jm) ...
                - psi_imjp .* (omega_jp - omega_im) ...
                + psi_ipjm .* (omega_ip - omega_jm)) / (4 * dx * dy);

    arakawa_jacobian = (jacobian_1 + jacobian_2 + jacobian_3) / 3;

    laplacian_omega = (omega_ip - 2 * omega_matrix + omega_im) / dx^2 ...
                    + (omega_jp - 2 * omega_matrix + omega_jm) / dy^2;

    rhs_matrix = -arakawa_jacobian + nu * laplacian_omega;
    rhs_vector = rhs_matrix(:);
end

function rhs_vector = rhs_fd_simple(omega_vector, setup, nu)
% rhs_fd_simple - Simple central-difference advection + diffusion RHS.
%
%   Non-conservative alternative to rhs_fd_arakawa. Uses standard
%   central-difference approximations for the advection term:
%     J(psi, omega) = dpsi/dy * domega/dx - dpsi/dx * domega/dy
%   This is cheaper per step but does NOT conserve energy/enstrophy.

    Nx = setup.Nx;
    Ny = setup.Ny;
    dx = setup.dx;
    dy = setup.dy;

    omega_matrix = reshape(omega_vector, Ny, Nx);
    psi_matrix = reshape(setup.solve_poisson(omega_vector), Ny, Nx);

    shift_xp = setup.shift_xp;
    shift_xm = setup.shift_xm;
    shift_yp = setup.shift_yp;
    shift_ym = setup.shift_ym;

    omega_ip = shift_xp(omega_matrix);
    omega_im = shift_xm(omega_matrix);
    omega_jp = shift_yp(omega_matrix);
    omega_jm = shift_ym(omega_matrix);

    psi_ip = shift_xp(psi_matrix);
    psi_im = shift_xm(psi_matrix);
    psi_jp = shift_yp(psi_matrix);
    psi_jm = shift_ym(psi_matrix);

    % Central-difference velocity components from streamfunction
    u = -(psi_jp - psi_jm) / (2 * dy);  % u = -dpsi/dy
    v =  (psi_ip - psi_im) / (2 * dx);  % v =  dpsi/dx

    % Central-difference advection: u * domega/dx + v * domega/dy
    advection = u .* (omega_ip - omega_im) / (2 * dx) ...
              + v .* (omega_jp - omega_jm) / (2 * dy);

    % Diffusion: nu * laplacian(omega)
    laplacian_omega = (omega_ip - 2 * omega_matrix + omega_im) / dx^2 ...
                    + (omega_jp - 2 * omega_matrix + omega_jm) / dy^2;

    rhs_matrix = -advection + nu * laplacian_omega;
    rhs_vector = rhs_matrix(:);
end

function val = gather_if_gpu(val)
% gather_if_gpu - Transfer gpuArray to CPU; pass-through for regular arrays.

    if isa(val, 'gpuArray')
        val = gather(val);
    end
end

function analysis = append_snapshot_metrics(analysis, setup)
% append_snapshot_metrics - Derive per-snapshot quantities used by plots/reports.

    n_snapshots = size(analysis.omega_snaps, 3);
    kinetic_energy = zeros(n_snapshots, 1);
    enstrophy = zeros(n_snapshots, 1);
    max_omega_history = zeros(n_snapshots, 1);
    peak_speed_history = zeros(n_snapshots, 1);
    u_snapshots = zeros(size(analysis.omega_snaps));
    v_snapshots = zeros(size(analysis.omega_snaps));

    for idx = 1:n_snapshots
        omega_snapshot = analysis.omega_snaps(:, :, idx);
        psi_snapshot = analysis.psi_snaps(:, :, idx);
        [velocity_u, velocity_v] = velocity_from_streamfunction(psi_snapshot, setup);

        u_snapshots(:, :, idx) = velocity_u;
        v_snapshots(:, :, idx) = velocity_v;

        kinetic_energy(idx) = 0.5 * sum((velocity_u(:).^2 + velocity_v(:).^2)) * setup.dx * setup.dy;
        enstrophy(idx) = 0.5 * sum(omega_snapshot(:).^2) * setup.dx * setup.dy;
        max_omega_history(idx) = max(abs(omega_snapshot(:)));
        peak_speed_history(idx) = max(sqrt(velocity_u(:).^2 + velocity_v(:).^2));
    end

    analysis.kinetic_energy = kinetic_energy;
    analysis.enstrophy = enstrophy;
    analysis.max_omega_history = max_omega_history;
    analysis.peak_speed_history = peak_speed_history;
    analysis.u_snaps = u_snapshots;
    analysis.v_snaps = v_snapshots;
    analysis.peak_abs_omega = max(max_omega_history);
    analysis.peak_speed = max(peak_speed_history);
end

function analysis = maybe_merge_unified_metrics(analysis, Parameters)
% maybe_merge_unified_metrics - Optional harmonization with shared metrics extractor.

    if exist("extract_unified_metrics", "file") ~= 2
        return;
    end

    unified_metrics = extract_unified_metrics( ...
        analysis.omega_snaps, ...
        analysis.psi_snaps, ...
        analysis.snapshot_times, ...
        analysis.dx, ...
        analysis.dy, ...
        Parameters);

    analysis = merge_structs(analysis, unified_metrics);
end

function fig_handle = create_fd_summary_figure(analysis, Parameters)
% create_fd_summary_figure - Build a compact diagnostic figure set.

    show_figures = usejava("desktop") && ~strcmpi(get(0, "DefaultFigureVisible"), "off");
    figure_visibility = "off";
    if show_figures
        figure_visibility = "on";
    end

    fig_handle = figure("Name", "Finite Difference Analysis", ...
        "NumberTitle", "off", ...
        "Visible", figure_visibility, ...
        "Position", [100, 100, 1100, 700]);

    snapshot_times = analysis.snapshot_times(:);
    n_snapshots = max(1, size(analysis.omega_snaps, 3));
    snapshot_indices = unique(round(linspace(1, n_snapshots, min(4, n_snapshots))));

    tiledlayout(2, 2, "TileSpacing", "compact");

    nexttile;
    imagesc(analysis.omega_snaps(:, :, 1));
    axis equal tight;
    set(gca, "YDir", "normal");
    colorbar;
    title(sprintf("Initial vorticity (t=%.3f)", snapshot_times(1)));
    xlabel("x-index");
    ylabel("y-index");

    nexttile;
    imagesc(analysis.omega_snaps(:, :, end));
    axis equal tight;
    set(gca, "YDir", "normal");
    colorbar;
    title(sprintf("Final vorticity (t=%.3f)", snapshot_times(end)));
    xlabel("x-index");
    ylabel("y-index");

    nexttile;
    plot(snapshot_times, analysis.kinetic_energy, "LineWidth", 1.8);
    hold on;
    plot(snapshot_times, analysis.enstrophy, "LineWidth", 1.8);
    hold off;
    grid on;
    xlabel("time (s)");
    ylabel("integral quantity");
    legend("Kinetic energy", "Enstrophy", "Location", "best");
    title("Integral diagnostics");

    nexttile;
    plot(snapshot_times, analysis.max_omega_history, "LineWidth", 1.8);
    hold on;
    plot(snapshot_times, analysis.peak_speed_history, "LineWidth", 1.5);
    hold off;
    grid on;
    xlabel("time (s)");
    ylabel("peak value");
    legend("max|omega|", "peak speed", "Location", "best");
    title("Peak metrics");

    if isfield(Parameters, "ic_type")
        ic_name = char(string(Parameters.ic_type));
    else
        ic_name = "unknown";
    end
    if isfield(analysis, 'use_arakawa') && analysis.use_arakawa
        method_label = "FD Arakawa-RK4";
    else
        method_label = "FD Central-RK4";
    end
    if isfield(analysis, 'use_gpu') && analysis.use_gpu
        method_label = method_label + " [GPU]";
    end
    sgtitle(sprintf("%s | IC=%s | Grid=%dx%d", method_label, ic_name, analysis.Nx, analysis.Ny));

    % Add tiny overlay markers for representative snapshots to aid quick visual checks.
    for idx = 1:numel(snapshot_indices)
        marker_index = snapshot_indices(idx);
        annotation_text = sprintf("t=%.3f", snapshot_times(marker_index));
        x_pos = 0.02 + 0.10 * (idx - 1);
        annotation("textbox", [x_pos, 0.01, 0.09, 0.03], ...
            "String", annotation_text, ...
            "EdgeColor", "none", ...
            "HorizontalAlignment", "left", ...
            "FontSize", 8);
    end
end

function maybe_write_vorticity_animation(analysis, cfg, Parameters)
% maybe_write_vorticity_animation - Optional GIF/Video export from snapshots.

    if ~isfield(Parameters, "create_animations") || ~logical(Parameters.create_animations)
        return;
    end
    if size(analysis.omega_snaps, 3) < 2
        return;
    end
    if ~isfield(Parameters, "animation_fps") || Parameters.animation_fps <= 0
        return;
    end
    if strcmpi(get(0, "DefaultFigureVisible"), "off")
        % Respect headless test/CI sessions to avoid unnecessary export work.
        return;
    end

    animation_dir = char(string(Parameters.animation_dir));
    if isempty(animation_dir)
        return;
    end
    if ~exist(animation_dir, "dir")
        mkdir(animation_dir);
    end

    mode_token = sanitize_filename_token(char(string(Parameters.mode)));
    if isempty(mode_token)
        mode_token = "solve";
    end
    mode_dir = fullfile(animation_dir, mode_token);
    if ~exist(mode_dir, "dir")
        mkdir(mode_dir);
    end

    timestamp = char(datetime("now", "Format", "yyyyMMdd_HHmmss"));
    nu_token = sanitize_filename_token(sprintf("%.3e", cfg.nu));
    dt_token = sanitize_filename_token(sprintf("%.3e", cfg.dt));
    base_name = sprintf("vorticity_evolution_Nx%d_Ny%d_nu%s_dt%s_%s_%s", ...
        cfg.Nx, cfg.Ny, nu_token, dt_token, mode_token, timestamp);
    base_path = char(fullfile(mode_dir, base_name));

    animation_format = lower(char(string(Parameters.animation_format)));
    if ~ismember(animation_format, {'gif', 'mp4', 'avi'})
        animation_format = 'gif';
    end

    x = linspace(0, cfg.Lx - cfg.Lx / cfg.Nx, cfg.Nx);
    y = linspace(0, cfg.Ly - cfg.Ly / cfg.Ny, cfg.Ny);

    animation_figure = figure("Visible", "off", "Name", "FD Animation", "NumberTitle", "off");
    cleanup_animation = onCleanup(@() safe_close(animation_figure));
    frame_count = size(analysis.omega_snaps, 3);

    switch animation_format
        case 'gif'
            output_file = [base_path, '.gif'];
            delay_time = 1 / Parameters.animation_fps;
            for idx = 1:frame_count
                render_animation_frame(animation_figure, x, y, analysis.omega_snaps(:, :, idx), analysis.snapshot_times(idx));
                frame = getframe(animation_figure);
                image_frame = frame2im(frame);
                [indexed_frame, color_map] = rgb2ind(image_frame, 256);
                if idx == 1
                    imwrite(indexed_frame, color_map, output_file, 'gif', 'LoopCount', inf, 'DelayTime', delay_time);
                else
                    imwrite(indexed_frame, color_map, output_file, 'gif', 'WriteMode', 'append', 'DelayTime', delay_time);
                end
            end
            fprintf("[FD] Animation saved: %s\n", output_file);

        otherwise
            output_file = [base_path, '.', animation_format];
            if strcmp(animation_format, 'mp4')
                profile = 'MPEG-4';
            else
                profile = 'Motion JPEG AVI';
            end

            try
                writer = VideoWriter(output_file, profile);
                writer.FrameRate = Parameters.animation_fps;
                if strcmp(profile, 'MPEG-4') && isfield(Parameters, "animation_quality")
                    writer.Quality = Parameters.animation_quality;
                end
                open(writer);
                for idx = 1:frame_count
                    render_animation_frame(animation_figure, x, y, analysis.omega_snaps(:, :, idx), analysis.snapshot_times(idx));
                    writeVideo(writer, getframe(animation_figure));
                end
                close(writer);
                fprintf("[FD] Animation saved: %s\n", output_file);
            catch ME
                warning("FD:AnimationFallback", ...
                    "Video export failed (%s). Falling back to GIF output.", ME.message);
                Parameters.animation_format = 'gif';
                maybe_write_vorticity_animation(analysis, cfg, Parameters);
            end
    end

    clear cleanup_animation;
end

function render_animation_frame(fig_handle, x, y, omega_snapshot, time_value)
% render_animation_frame - Render one frame consistently for all formats.

    figure(fig_handle);
    clf(fig_handle);
    imagesc(x, y, omega_snapshot);
    axis equal tight;
    set(gca, "YDir", "normal");
    colormap(turbo);
    colorbar;
    xlabel("x");
    ylabel("y");
    title(sprintf("Vorticity evolution: t = %.3f s", time_value));
    drawnow;
end

function token = sanitize_filename_token(raw_token)
% sanitize_filename_token - Keep filenames filesystem-safe.

    token = regexprep(char(raw_token), "[^a-zA-Z0-9_-]", "");
end

function cfl_estimate = compute_cfl_estimate(peak_speed, dt, setup)
% compute_cfl_estimate - Cheap CFL estimate for console progress output.

    cfl_estimate = peak_speed * dt / min(setup.dx, setup.dy);
end

function [velocity_u, velocity_v] = velocity_from_streamfunction(psi, setup)
% velocity_from_streamfunction - Recover velocity from streamfunction.

    velocity_u = -(setup.shift_yp(psi) - setup.shift_ym(psi)) / (2 * setup.dy);
    velocity_v = (setup.shift_xp(psi) - setup.shift_xm(psi)) / (2 * setup.dx);
end

function progress_stride = resolve_progress_stride(Parameters, n_steps)
% resolve_progress_stride - Auto/explicit stride for textual progress logs.

    progress_stride = 0;
    if isfield(Parameters, "progress_stride") && isnumeric(Parameters.progress_stride) ...
            && isscalar(Parameters.progress_stride) && isfinite(Parameters.progress_stride)
        progress_stride = round(Parameters.progress_stride);
    end

    if progress_stride <= 0
        progress_stride = max(1, round(n_steps / 20));
    else
        progress_stride = max(1, progress_stride);
    end
end

function live_stride = resolve_live_stride(Parameters, n_steps)
% resolve_live_stride - Auto/explicit stride for live figure updates.

    live_stride = 0;
    if isfield(Parameters, "live_stride") && isnumeric(Parameters.live_stride) ...
            && isscalar(Parameters.live_stride) && isfinite(Parameters.live_stride)
        live_stride = round(Parameters.live_stride);
    end

    if live_stride <= 0
        live_stride = max(1, round(n_steps / 40));
    else
        live_stride = max(1, live_stride);
    end
end

function live_preview = open_live_preview_if_requested(Parameters, cfg, omega_initial)
% open_live_preview_if_requested - Create optional live-preview figure.

    live_preview = struct();
    live_preview.enabled = false;
    live_preview.figure = [];
    live_preview.image = [];
    live_preview.axes = [];

    if ~isfield(Parameters, "live_preview") || ~logical(Parameters.live_preview)
        return;
    end
    if ~usejava("desktop")
        return;
    end

    dx = cfg.Lx / cfg.Nx;
    dy = cfg.Ly / cfg.Ny;
    x = linspace(0, cfg.Lx - dx, cfg.Nx);
    y = linspace(0, cfg.Ly - dy, cfg.Ny);

    live_preview.figure = figure("Name", "FD Live Preview", "NumberTitle", "off");
    live_preview.axes = axes("Parent", live_preview.figure);
    live_preview.image = imagesc(live_preview.axes, x, y, omega_initial);
    axis(live_preview.axes, "equal", "tight");
    set(live_preview.axes, "YDir", "normal");
    colormap(live_preview.axes, turbo);
    colorbar(live_preview.axes);
    title(live_preview.axes, "Live vorticity preview: t = 0.000");
    drawnow;

    live_preview.enabled = true;
end

function update_live_preview(live_preview, omega_matrix, time_value)
% update_live_preview - Refresh optional live-preview frame.

    if ~isfield(live_preview, "enabled") || ~live_preview.enabled
        return;
    end
    if isempty(live_preview.figure) || ~isvalid(live_preview.figure)
        return;
    end

    set(live_preview.image, "CData", omega_matrix);
    title(live_preview.axes, sprintf("Live vorticity preview: t = %.3f", time_value));
    drawnow limitrate;
end

function close_live_preview(live_preview)
% close_live_preview - Close optional live-preview window cleanly.

    if ~isfield(live_preview, "enabled") || ~live_preview.enabled
        return;
    end
    safe_close(live_preview.figure);
end

function safe_close(fig_handle)
% safe_close - Close figure if valid (used by cleanup code paths).

    if ~isempty(fig_handle) && isvalid(fig_handle)
        close(fig_handle);
    end
end

function merged = merge_structs(a, b)
% merge_structs - Merge structs with right-hand side precedence.

    merged = a;
    if isempty(b)
        return;
    end

    fields = fieldnames(b);
    for idx = 1:numel(fields)
        merged.(fields{idx}) = b.(fields{idx});
    end
end
