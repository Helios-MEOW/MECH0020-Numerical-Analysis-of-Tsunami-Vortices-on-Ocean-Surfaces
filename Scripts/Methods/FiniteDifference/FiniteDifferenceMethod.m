function varargout = FiniteDifferenceMethod(action, varargin)
% FiniteDifferenceMethod - Single-file finite-difference method module
%
% Supported actions:
%   callbacks                  -> struct with init/step/diagnostics handles
%   init(cfg, ctx)             -> State
%   step(State, cfg, ctx)      -> State
%   diagnostics(State, cfg, ctx)-> Metrics
%   run(Parameters)            -> [fig_handle, analysis]

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
                string(action));
    end
end

function State = fd_init_internal(cfg)
    setup = fd_setup_internal(cfg);

    if isfield(cfg, "omega") && ~isempty(cfg.omega)
        omega0 = cfg.omega;
    else
        if isfield(cfg, "ic_coeff")
            ic_coeff = cfg.ic_coeff;
        else
            ic_coeff = [];
        end
        omega0 = initialise_omega(setup.X, setup.Y, cfg.ic_type, ic_coeff);
    end

    omega = reshape(omega0, setup.Ny, setup.Nx);
    psi_vec = setup.delta^2 * (setup.A \ omega(:));
    psi = reshape(psi_vec, setup.Ny, setup.Nx);

    State = struct();
    State.omega = omega;
    State.psi = psi;
    State.t = 0.0;
    State.step = 0;
    State.setup = setup;
end

function State = fd_step_internal(State, cfg)
    dt = cfg.dt;
    nu = cfg.nu;
    s = State.setup;

    omega_vec = State.omega(:);

    k1 = rhs_fd_arakawa(omega_vec, s.A, s.dx, s.dy, nu, ...
        s.shift_xp, s.shift_xm, s.shift_yp, s.shift_ym, s.Nx, s.Ny, s.delta);
    k2 = rhs_fd_arakawa(omega_vec + 0.5 * dt * k1, s.A, s.dx, s.dy, nu, ...
        s.shift_xp, s.shift_xm, s.shift_yp, s.shift_ym, s.Nx, s.Ny, s.delta);
    k3 = rhs_fd_arakawa(omega_vec + 0.5 * dt * k2, s.A, s.dx, s.dy, nu, ...
        s.shift_xp, s.shift_xm, s.shift_yp, s.shift_ym, s.Nx, s.Ny, s.delta);
    k4 = rhs_fd_arakawa(omega_vec + dt * k3, s.A, s.dx, s.dy, nu, ...
        s.shift_xp, s.shift_xm, s.shift_yp, s.shift_ym, s.Nx, s.Ny, s.delta);

    omega_vec = omega_vec + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4);
    State.omega = reshape(omega_vec, s.Ny, s.Nx);

    psi_vec = s.delta^2 * (s.A \ omega_vec);
    State.psi = reshape(psi_vec, s.Ny, s.Nx);

    State.t = State.t + dt;
    State.step = State.step + 1;
end

function Metrics = fd_diagnostics_internal(State)
    omega = State.omega;
    psi = State.psi;
    s = State.setup;

    max_vorticity = max(abs(omega(:)));
    enstrophy = sum(omega(:).^2) * s.dx * s.dy;

    dpsi_dx = (s.shift_xp(psi) - s.shift_xm(psi)) / (2 * s.dx);
    dpsi_dy = (s.shift_yp(psi) - s.shift_ym(psi)) / (2 * s.dy);
    grad_psi_sq = dpsi_dx.^2 + dpsi_dy.^2;
    kinetic_energy = 0.5 * sum(grad_psi_sq(:)) * s.dx * s.dy;

    Metrics = struct();
    Metrics.max_vorticity = max_vorticity;
    Metrics.enstrophy = enstrophy;
    Metrics.kinetic_energy = kinetic_energy;
    Metrics.t = State.t;
    Metrics.step = State.step;
end

function [fig_handle, analysis] = fd_run_internal(Parameters)
    required_fields = {'nu', 'Lx', 'Ly', 'Nx', 'Ny', 'dt', 'Tfinal', 'ic_type'};
    for k = 1:numel(required_fields)
        if ~isfield(Parameters, required_fields{k})
            error("FD:MissingField", "Missing required field: %s", required_fields{k});
        end
    end

    if ~isfield(Parameters, "snap_times") || isempty(Parameters.snap_times)
        if isfield(Parameters, "num_snapshots") && Parameters.num_snapshots > 1
            n_snapshots = Parameters.num_snapshots;
        else
            n_snapshots = 9;
        end
        Parameters.snap_times = linspace(0, Parameters.Tfinal, n_snapshots);
    end

    cfg = fd_cfg_from_parameters(Parameters);
    State = fd_init_internal(cfg);
    snap_times = Parameters.snap_times(:).';
    n_snapshots = numel(snap_times);

    omega_snaps = zeros(cfg.Ny, cfg.Nx, n_snapshots);
    psi_snaps = zeros(cfg.Ny, cfg.Nx, n_snapshots);

    snap_index = 1;
    while snap_index <= n_snapshots && State.t >= snap_times(snap_index) - 1e-12
        omega_snaps(:, :, snap_index) = State.omega;
        psi_snaps(:, :, snap_index) = State.psi;
        snap_index = snap_index + 1;
    end

    n_steps = max(0, ceil(cfg.Tfinal / cfg.dt));
    for step_index = 1:n_steps
        State = fd_step_internal(State, cfg);

        while snap_index <= n_snapshots && State.t >= snap_times(snap_index) - 1e-12
            omega_snaps(:, :, snap_index) = State.omega;
            psi_snaps(:, :, snap_index) = State.psi;
            snap_index = snap_index + 1;
        end

        if step_index == n_steps
            % No-op: keeps step_index intentionally used for static analyzers.
        end
    end

    if snap_index <= n_snapshots
        omega_snaps(:, :, snap_index:end) = repmat(State.omega, 1, 1, n_snapshots - snap_index + 1);
        psi_snaps(:, :, snap_index:end) = repmat(State.psi, 1, 1, n_snapshots - snap_index + 1);
    end

    analysis = struct();
    analysis.method = "finite_difference";
    analysis.omega_snaps = omega_snaps;
    analysis.psi_snaps = psi_snaps;
    analysis.snapshot_times = snap_times(:);
    analysis.time_vec = snap_times(:);
    analysis.snapshots_stored = n_snapshots;
    analysis.Nx = cfg.Nx;
    analysis.Ny = cfg.Ny;
    analysis.dx = cfg.Lx / cfg.Nx;
    analysis.dy = cfg.Ly / cfg.Ny;
    analysis.grid_points = cfg.Nx * cfg.Ny;

    if exist("extract_unified_metrics", "file") == 2
        unified_metrics = extract_unified_metrics(omega_snaps, psi_snaps, snap_times, analysis.dx, analysis.dy, Parameters);
        analysis = merge_structs(analysis, unified_metrics);
    else
        Metrics = fd_diagnostics_internal(State);
        analysis.peak_abs_omega = Metrics.max_vorticity;
        analysis.peak_vorticity = Metrics.max_vorticity;
        analysis.kinetic_energy = Metrics.kinetic_energy;
        analysis.enstrophy = Metrics.enstrophy;
    end

    if ~isfield(analysis, "peak_abs_omega") || isempty(analysis.peak_abs_omega)
        analysis.peak_abs_omega = max(abs(omega_snaps(:)));
    end
    analysis.peak_vorticity = analysis.peak_abs_omega;

    show_figs = usejava("desktop") && ~strcmpi(get(0, "DefaultFigureVisible"), "off");
    if show_figs
        fig_handle = figure("Name", "Finite Difference Analysis", "NumberTitle", "off");
        subplot(1, 2, 1);
        imagesc(omega_snaps(:, :, 1));
        axis equal tight;
        title(sprintf("t = %.3f", snap_times(1)));
        colorbar;

        subplot(1, 2, 2);
        imagesc(omega_snaps(:, :, end));
        axis equal tight;
        title(sprintf("t = %.3f", snap_times(end)));
        colorbar;
    else
        fig_handle = figure("Visible", "off");
    end
end

function cfg = fd_cfg_from_parameters(Parameters)
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
end

function setup = fd_setup_internal(cfg)
    Nx = cfg.Nx;
    Ny = cfg.Ny;
    Lx = cfg.Lx;
    Ly = cfg.Ly;

    dx = Lx / Nx;
    dy = Ly / Ny;
    delta = dx;

    x = linspace(0, Lx - dx, Nx);
    y = linspace(0, Ly - dy, Ny);
    [X, Y] = meshgrid(x, y);

    ex = ones(Nx, 1);
    ey = ones(Ny, 1);

    Tx = spdiags([ex, -2 * ex, ex], [-1, 0, 1], Nx, Nx);
    Tx(1, end) = 1;
    Tx(end, 1) = 1;

    Ty = spdiags([ey, -2 * ey, ey], [-1, 0, 1], Ny, Ny);
    Ty(1, end) = 1;
    Ty(end, 1) = 1;

    Ix = speye(Nx);
    Iy = speye(Ny);
    A = (1 / dx^2) * kron(Tx, Iy) + (1 / dy^2) * kron(Ix, Ty);

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

    setup.shift_xp = @(F) circshift(F, [0, +1]);
    setup.shift_xm = @(F) circshift(F, [0, -1]);
    setup.shift_yp = @(F) circshift(F, [+1, 0]);
    setup.shift_ym = @(F) circshift(F, [-1, 0]);
end

function dwdt = rhs_fd_arakawa(omega_in, A, dx, dy, nu, shift_xp, shift_xm, shift_yp, shift_ym, Nx, Ny, delta)
    omega2d = reshape(omega_in, Ny, Nx);

    psi_vec = delta^2 * (A \ omega_in);
    psi2d = reshape(psi_vec, Ny, Nx);

    u = -(shift_yp(psi2d) - shift_ym(psi2d)) / (2 * dy);
    v = (shift_xp(psi2d) - shift_xm(psi2d)) / (2 * dx);

    dwdx = (shift_xp(omega2d) - shift_xm(omega2d)) / (2 * dx);
    dwdy = (shift_yp(omega2d) - shift_ym(omega2d)) / (2 * dy);
    adv = u .* dwdx + v .* dwdy;

    d2wdx2 = (shift_xp(omega2d) - 2 * omega2d + shift_xm(omega2d)) / dx^2;
    d2wdy2 = (shift_yp(omega2d) - 2 * omega2d + shift_ym(omega2d)) / dy^2;
    diff = nu * (d2wdx2 + d2wdy2);

    dwdt = (-adv + diff);
    dwdt = dwdt(:);
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
