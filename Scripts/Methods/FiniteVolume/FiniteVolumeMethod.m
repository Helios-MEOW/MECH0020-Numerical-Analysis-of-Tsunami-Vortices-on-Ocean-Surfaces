function varargout = FiniteVolumeMethod(action, varargin)
% FiniteVolumeMethod - Self-contained finite-volume method module (3D layered).
%
% Supported actions:
%   callbacks                     -> struct with init/step/diagnostics/run handles
%   init(cfg, ctx)                -> State
%   step(State, cfg, ctx)         -> State
%   diagnostics(State, cfg, ctx)  -> Metrics
%   run(Parameters)               -> [fig_handle, analysis]
%
% Notes:
%   - Single-file module following the FD action-contract architecture.
%   - Uses a structured Cartesian Nx x Ny x Nz mesh with periodic x/y and
%     fixed (no-flux by default) z boundaries.
%   - Keeps projected 2D state (depth-averaged omega/psi) for compatibility
%     with existing mode orchestration and report pipelines.

    narginchk(1, inf);
    action_name = lower(string(action));

    switch action_name
        case "callbacks"
            callbacks = struct();
            callbacks.init = @(cfg, ctx) FiniteVolumeMethod("init", cfg, ctx);
            callbacks.step = @(State, cfg, ctx) FiniteVolumeMethod("step", State, cfg, ctx);
            callbacks.diagnostics = @(State, cfg, ctx) FiniteVolumeMethod("diagnostics", State, cfg, ctx);
            callbacks.run = @(Parameters) FiniteVolumeMethod("run", Parameters);
            varargout{1} = callbacks;

        case "init"
            cfg = varargin{1};
            varargout{1} = fv_init_internal(cfg);

        case "step"
            State = varargin{1};
            cfg = varargin{2};
            varargout{1} = fv_step_internal(State, cfg);

        case "diagnostics"
            State = varargin{1};
            varargout{1} = fv_diagnostics_internal(State);

        case "run"
            Parameters = varargin{1};
            [fig_handle, analysis] = fv_run_internal(Parameters);
            varargout{1} = fig_handle;
            varargout{2} = analysis;

        otherwise
            error("FV:InvalidAction", ...
                "Unsupported action '%s'. Valid actions: callbacks, init, step, diagnostics, run.", ...
                char(string(action)));
    end
end

function State = fv_init_internal(cfg)
    cfg = fv_normalize_cfg(cfg);
    setup = fv_build_setup(cfg);

    omega2d = fv_initial_vorticity_2d(cfg, setup.X, setup.Y);
    omega3d = fv_lift_to_3d(omega2d, setup);
    psi3d = fv_solve_poisson_layers(omega3d, setup);

    State = struct();
    State.omega3d = omega3d;
    State.psi3d = psi3d;
    State.omega = mean(omega3d, 3);
    State.psi = mean(psi3d, 3);
    State.t = 0.0;
    State.step = 0;
    State.setup = setup;
end

function State = fv_step_internal(State, cfg)
    cfg = fv_normalize_cfg(cfg);
    setup = State.setup;

    rhs = fv_rhs_3d(State.omega3d, State.psi3d, setup, cfg.nu, setup.nu_z);
    omega3d_next = State.omega3d + cfg.dt * rhs;

    psi3d_next = fv_solve_poisson_layers(omega3d_next, setup);

    State.omega3d = omega3d_next;
    State.psi3d = psi3d_next;
    State.omega = mean(omega3d_next, 3);
    State.psi = mean(psi3d_next, 3);
    State.t = State.t + cfg.dt;
    State.step = State.step + 1;
end

function Metrics = fv_diagnostics_internal(State)
    setup = State.setup;
    [u3d, v3d] = fv_velocity_from_psi3d(State.psi3d, setup.dx, setup.dy);

    speed = sqrt(u3d.^2 + v3d.^2);

    Metrics = struct();
    Metrics.max_vorticity = max(abs(State.omega3d(:)));
    Metrics.enstrophy = 0.5 * sum(State.omega3d(:).^2) * setup.dx * setup.dy * setup.dz;
    Metrics.kinetic_energy = 0.5 * sum((u3d(:).^2 + v3d(:).^2)) * setup.dx * setup.dy * setup.dz;
    Metrics.peak_speed = max(speed(:));
    Metrics.t = State.t;
    Metrics.step = State.step;
end

function [fig_handle, analysis] = fv_run_internal(Parameters)
    run_cfg = fv_cfg_from_parameters(Parameters);

    if ~isfield(run_cfg, "snap_times") || isempty(run_cfg.snap_times)
        if isfield(Parameters, "num_snapshots") && Parameters.num_snapshots > 1
            n_snapshots = Parameters.num_snapshots;
        else
            n_snapshots = 9;
        end
        run_cfg.snap_times = linspace(0, run_cfg.Tfinal, n_snapshots);
    end

    State = fv_init_internal(run_cfg);

    snap_times = run_cfg.snap_times(:).';
    n_snapshots = numel(snap_times);

    omega_snaps = zeros(run_cfg.Ny, run_cfg.Nx, n_snapshots);
    psi_snaps = zeros(run_cfg.Ny, run_cfg.Nx, n_snapshots);
    kinetic_energy = zeros(n_snapshots, 1);
    enstrophy = zeros(n_snapshots, 1);
    peak_speed = zeros(n_snapshots, 1);
    max_omega = zeros(n_snapshots, 1);
    sampled_times = zeros(n_snapshots, 1);

    snap_idx = 1;
    while snap_idx <= n_snapshots && State.t >= snap_times(snap_idx) - 1e-12
        [omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, snap_idx] = ...
            fv_store_snapshot(State, omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, snap_idx);
    end

    Nt = max(0, ceil(run_cfg.Tfinal / run_cfg.dt));
    for n = 1:Nt
        State = fv_step_internal(State, run_cfg);

        while snap_idx <= n_snapshots && State.t >= snap_times(snap_idx) - 1e-12
            [omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, snap_idx] = ...
                fv_store_snapshot(State, omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, snap_idx);
        end
    end

    if snap_idx <= n_snapshots
        for idx = snap_idx:n_snapshots
            [omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, ~] = ...
                fv_store_snapshot(State, omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, idx);
        end
    end

    analysis = struct();
    analysis.method = "finite_volume_3d_layered";
    analysis.omega_snaps = omega_snaps;
    analysis.psi_snaps = psi_snaps;
    analysis.snapshot_times = sampled_times;
    analysis.time_vec = sampled_times;
    analysis.snapshots_stored = n_snapshots;
    analysis.Nx = run_cfg.Nx;
    analysis.Ny = run_cfg.Ny;
    analysis.Nz = run_cfg.Nz;
    analysis.Lx = run_cfg.Lx;
    analysis.Ly = run_cfg.Ly;
    analysis.Lz = run_cfg.Lz;
    analysis.dx = State.setup.dx;
    analysis.dy = State.setup.dy;
    analysis.dz = State.setup.dz;
    analysis.grid_points = run_cfg.Nx * run_cfg.Ny * run_cfg.Nz;
    analysis.kinetic_energy = kinetic_energy;
    analysis.enstrophy = enstrophy;
    analysis.peak_speed_history = peak_speed;
    analysis.max_omega_history = max_omega;
    analysis.peak_abs_omega = max(max_omega);
    analysis.peak_vorticity = analysis.peak_abs_omega;
    analysis.vertical_bc = State.setup.z_bc;
    analysis.projection = "depth_average";
    analysis.omega3d_final = State.omega3d;
    analysis.psi3d_final = State.psi3d;

    analysis = fv_maybe_merge_unified_metrics(analysis, Parameters);

    fig_handle = fv_summary_figure(analysis);
end

function cfg = fv_cfg_from_parameters(Parameters)
    cfg = struct();
    cfg.nu = required_field(Parameters, "nu");
    cfg.Lx = required_field(Parameters, "Lx");
    cfg.Ly = required_field(Parameters, "Ly");
    cfg.Nx = required_field(Parameters, "Nx");
    cfg.Ny = required_field(Parameters, "Ny");
    cfg.dt = required_field(Parameters, "dt");
    cfg.Tfinal = required_field(Parameters, "Tfinal");
    cfg.ic_type = required_field(Parameters, "ic_type");

    if isfield(Parameters, "ic_coeff")
        cfg.ic_coeff = Parameters.ic_coeff;
    else
        cfg.ic_coeff = [];
    end
    if isfield(Parameters, "omega")
        cfg.omega = Parameters.omega;
    end
    if isfield(Parameters, "Nz")
        cfg.Nz = Parameters.Nz;
    end
    if isfield(Parameters, "Lz")
        cfg.Lz = Parameters.Lz;
    end
    if isfield(Parameters, "snap_times")
        cfg.snap_times = Parameters.snap_times;
    end

    if isfield(Parameters, "method_config") && isfield(Parameters.method_config, "fv3d")
        cfg.fv3d = Parameters.method_config.fv3d;
    end
end

function cfg = fv_normalize_cfg(cfg)
    needed = {"nu", "Lx", "Ly", "Nx", "Ny", "dt", "Tfinal"};
    for i = 1:numel(needed)
        if ~isfield(cfg, needed{i})
            error("FV:MissingField", "Missing required field: %s", needed{i});
        end
    end

    if ~isfield(cfg, "ic_type")
        cfg.ic_type = "stretched_gaussian";
    end
    if ~isfield(cfg, "ic_coeff")
        cfg.ic_coeff = [];
    end

    if ~isfield(cfg, "Nz") || isempty(cfg.Nz)
        cfg.Nz = 12;
    end
    if ~isfield(cfg, "Lz") || isempty(cfg.Lz)
        cfg.Lz = 1.0;
    end

    if cfg.Nx <= 0 || cfg.Ny <= 0 || cfg.Nz <= 0 || cfg.dt <= 0 || cfg.Tfinal <= 0
        error("FV:InvalidConfig", "Nx, Ny, Nz, dt, and Tfinal must be positive.");
    end

    if ~isfield(cfg, "fv3d") || ~isstruct(cfg.fv3d)
        cfg.fv3d = struct();
    end

    if ~isfield(cfg.fv3d, "vertical_diffusivity_scale") || isempty(cfg.fv3d.vertical_diffusivity_scale)
        cfg.fv3d.vertical_diffusivity_scale = 1.0;
    end
    if ~isfield(cfg.fv3d, "z_boundary") || isempty(cfg.fv3d.z_boundary)
        cfg.fv3d.z_boundary = "no_flux";
    end
end

function setup = fv_build_setup(cfg)
    dx = cfg.Lx / cfg.Nx;
    dy = cfg.Ly / cfg.Ny;
    dz = cfg.Lz / cfg.Nz;

    x = linspace(0, cfg.Lx - dx, cfg.Nx);
    y = linspace(0, cfg.Ly - dy, cfg.Ny);
    z = linspace(0, cfg.Lz - dz, cfg.Nz);

    [X, Y] = meshgrid(x, y);

    setup = struct();
    setup.Nx = cfg.Nx;
    setup.Ny = cfg.Ny;
    setup.Nz = cfg.Nz;
    setup.dx = dx;
    setup.dy = dy;
    setup.dz = dz;
    setup.Lx = cfg.Lx;
    setup.Ly = cfg.Ly;
    setup.Lz = cfg.Lz;
    setup.x = x;
    setup.y = y;
    setup.z = z;
    setup.X = X;
    setup.Y = Y;
    setup.nu_z = cfg.nu * cfg.fv3d.vertical_diffusivity_scale;
    setup.z_bc = char(string(cfg.fv3d.z_boundary));
end

function omega2d = fv_initial_vorticity_2d(cfg, X, Y)
    if isfield(cfg, "omega") && ~isempty(cfg.omega)
        omega2d = cfg.omega;
        return;
    end

    if exist("initialise_omega", "file") == 2
        omega2d = initialise_omega(X, Y, cfg.ic_type, cfg.ic_coeff);
    elseif exist("ic_factory", "file") == 2
        omega2d = ic_factory(X, Y, cfg.ic_type, cfg.ic_coeff);
    else
        omega2d = exp(-2 * (X.^2 + Y.^2));
    end
end

function omega3d = fv_lift_to_3d(omega2d, setup)
    omega3d = zeros(setup.Ny, setup.Nx, setup.Nz);

    z_mid = 0.5 * setup.Lz;
    sigma = max(setup.Lz / 6, eps);

    profile = exp(-((setup.z - z_mid).^2) / (2 * sigma^2));
    profile = profile / max(mean(profile), eps);

    for k = 1:setup.Nz
        omega3d(:, :, k) = omega2d * profile(k);
    end
end

function psi3d = fv_solve_poisson_layers(omega3d, setup)
    psi3d = zeros(size(omega3d));
    for k = 1:setup.Nz
        psi3d(:, :, k) = fv_poisson_2d_periodic(omega3d(:, :, k), setup);
    end
end

function psi = fv_poisson_2d_periodic(omega, setup)
    [Ny, Nx] = size(omega);
    omega_hat = fft2(omega);

    kx = 2 * pi / setup.Lx * [0:(Nx/2 - 1), (-Nx/2):-1];
    ky = 2 * pi / setup.Ly * [0:(Ny/2 - 1), (-Ny/2):-1];
    [Kx, Ky] = meshgrid(kx, ky);

    K2 = Kx.^2 + Ky.^2;
    K2(1, 1) = 1;

    psi_hat = -omega_hat ./ K2;
    psi_hat(1, 1) = 0;

    psi = real(ifft2(psi_hat));
end

function rhs = fv_rhs_3d(omega3d, psi3d, setup, nu_xy, nu_z)
    [u3d, v3d] = fv_velocity_from_psi3d(psi3d, setup.dx, setup.dy);

    dwdx = fv_ddx_upwind(omega3d, u3d, setup.dx);
    dwdy = fv_ddy_upwind(omega3d, v3d, setup.dy);
    advection = u3d .* dwdx + v3d .* dwdy;

    lap_xy = fv_laplacian_xy_periodic(omega3d, setup.dx, setup.dy);
    lap_z = fv_laplacian_z(omega3d, setup.dz, setup.z_bc);

    rhs = -advection + nu_xy * lap_xy + nu_z * lap_z;
end

function [u3d, v3d] = fv_velocity_from_psi3d(psi3d, dx, dy)
    [Ny, Nx, Nz] = size(psi3d);
    u3d = zeros(Ny, Nx, Nz);
    v3d = zeros(Ny, Nx, Nz);

    for k = 1:Nz
        psi = psi3d(:, :, k);
        u3d(:, :, k) = -(circshift(psi, [+1, 0]) - circshift(psi, [-1, 0])) / (2 * dy);
        v3d(:, :, k) = (circshift(psi, [0, +1]) - circshift(psi, [0, -1])) / (2 * dx);
    end
end

function dwdx = fv_ddx_upwind(F, U, dx)
    F_im = circshift(F, [0, -1, 0]);
    F_ip = circshift(F, [0, +1, 0]);

    backward = (F - F_im) / dx;
    forward = (F_ip - F) / dx;

    dwdx = (U >= 0) .* backward + (U < 0) .* forward;
end

function dwdy = fv_ddy_upwind(F, V, dy)
    F_jm = circshift(F, [-1, 0, 0]);
    F_jp = circshift(F, [+1, 0, 0]);

    backward = (F - F_jm) / dy;
    forward = (F_jp - F) / dy;

    dwdy = (V >= 0) .* backward + (V < 0) .* forward;
end

function lap = fv_laplacian_xy_periodic(F, dx, dy)
    lap = (circshift(F, [0, +1, 0]) + circshift(F, [0, -1, 0]) - 2 * F) / (dx^2) ...
        + (circshift(F, [+1, 0, 0]) + circshift(F, [-1, 0, 0]) - 2 * F) / (dy^2);
end

function lapz = fv_laplacian_z(F, dz, z_bc)
    [Ny, Nx, Nz] = size(F);
    lapz = zeros(Ny, Nx, Nz);

    for k = 1:Nz
        if k == 1
            if strcmpi(z_bc, "periodic")
                km = Nz;
            else
                km = 2; % no-flux ghost reflection
            end
            kp = 2;
        elseif k == Nz
            km = Nz - 1;
            if strcmpi(z_bc, "periodic")
                kp = 1;
            else
                kp = Nz - 1; % no-flux ghost reflection
            end
        else
            km = k - 1;
            kp = k + 1;
        end

        lapz(:, :, k) = (F(:, :, kp) - 2 * F(:, :, k) + F(:, :, km)) / (dz^2);
    end
end

function [omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, next_idx] = ...
        fv_store_snapshot(State, omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, idx)
    M = fv_diagnostics_internal(State);

    omega_snaps(:, :, idx) = State.omega;
    psi_snaps(:, :, idx) = State.psi;
    kinetic_energy(idx) = M.kinetic_energy;
    enstrophy(idx) = M.enstrophy;
    peak_speed(idx) = M.peak_speed;
    max_omega(idx) = M.max_vorticity;
    sampled_times(idx) = State.t;
    next_idx = idx + 1;
end

function analysis = fv_maybe_merge_unified_metrics(analysis, Parameters)
    if exist("extract_unified_metrics", "file") ~= 2
        return;
    end

    metrics = extract_unified_metrics( ...
        analysis.omega_snaps, ...
        analysis.psi_snaps, ...
        analysis.snapshot_times, ...
        analysis.dx, ...
        analysis.dy, ...
        Parameters);

    analysis = merge_structs(analysis, metrics);
    if ~isfield(analysis, "peak_abs_omega") || isempty(analysis.peak_abs_omega)
        analysis.peak_abs_omega = max(abs(analysis.omega_snaps(:)));
    end
    analysis.peak_vorticity = analysis.peak_abs_omega;
end

function fig_handle = fv_summary_figure(analysis)
    show_figs = usejava("desktop") && ~strcmpi(get(0, "DefaultFigureVisible"), "off");
    fig_visibility = "off";
    if show_figs
        fig_visibility = "on";
    end

    fig_handle = figure("Name", "Finite Volume 3D Layered Analysis", "NumberTitle", "off", "Visible", fig_visibility);

    subplot(1, 2, 1);
    contourf(analysis.omega_snaps(:, :, end), 20);
    colorbar;
    title("Depth-averaged vorticity (final)");
    xlabel("x-index");
    ylabel("y-index");

    subplot(1, 2, 2);
    semilogy(analysis.time_vec, analysis.enstrophy + 1e-10, "LineWidth", 1.6);
    hold on;
    semilogy(analysis.time_vec, analysis.kinetic_energy + 1e-10, "LineWidth", 1.6);
    legend("Enstrophy", "Kinetic Energy", "Location", "best");
    xlabel("Time");
    ylabel("Value");
    grid on;
end

function val = required_field(S, name)
    if ~isfield(S, name)
        error("FV:MissingField", "Missing required field: %s", name);
    end
    val = S.(name);
end

function merged = merge_structs(a, b)
    merged = a;
    if isempty(b)
        return;
    end
    fields = fieldnames(b);
    for i = 1:numel(fields)
        merged.(fields{i}) = b.(fields{i});
    end
end
