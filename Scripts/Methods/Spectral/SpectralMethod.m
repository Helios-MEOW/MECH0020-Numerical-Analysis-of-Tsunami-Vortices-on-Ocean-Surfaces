function varargout = SpectralMethod(action, varargin)
% SpectralMethod - Self-contained spectral (FFT) method module.
%
% Supported actions:
%   callbacks                     -> struct with init/step/diagnostics/run handles
%   init(cfg, ctx)                -> State
%   step(State, cfg, ctx)         -> State
%   diagnostics(State, cfg, ctx)  -> Metrics
%   run(Parameters)               -> [fig_handle, analysis]
%
% Notes:
%   - Single-file method module following the FD action-contract pattern.
%   - Uses Fourier-space RK4 stepping with 2/3-rule dealiasing.
%   - Supports explicit k-space controls through cfg.kx/cfg.ky when provided.

    narginchk(1, inf);
    action_name = lower(string(action));

    switch action_name
        case "callbacks"
            callbacks = struct();
            callbacks.init = @(cfg, ctx) SpectralMethod("init", cfg, ctx);
            callbacks.step = @(State, cfg, ctx) SpectralMethod("step", State, cfg, ctx);
            callbacks.diagnostics = @(State, cfg, ctx) SpectralMethod("diagnostics", State, cfg, ctx);
            callbacks.run = @(Parameters) SpectralMethod("run", Parameters);
            varargout{1} = callbacks;

        case "init"
            cfg = varargin{1};
            varargout{1} = spectral_init_internal(cfg);

        case "step"
            State = varargin{1};
            cfg = varargin{2};
            varargout{1} = spectral_step_internal(State, cfg);

        case "diagnostics"
            State = varargin{1};
            varargout{1} = spectral_diagnostics_internal(State);

        case "run"
            Parameters = varargin{1};
            [fig_handle, analysis] = spectral_run_internal(Parameters);
            varargout{1} = fig_handle;
            varargout{2} = analysis;

        otherwise
            error("Spectral:InvalidAction", ...
                "Unsupported action '%s'. Valid actions: callbacks, init, step, diagnostics, run.", ...
                char(string(action)));
    end
end

function State = spectral_init_internal(cfg)
    cfg = spectral_normalize_cfg(cfg);
    setup = spectral_build_setup(cfg);

    omega0 = spectral_initial_vorticity(cfg, setup.X, setup.Y);
    omega0 = reshape(omega0, setup.Ny, setup.Nx);

    omega_hat = fft2(omega0);
    psi_hat = spectral_streamfunction_hat(omega_hat, setup.K2_safe);

    State = struct();
    State.omega = omega0;
    State.psi = real(ifft2(psi_hat));
    State.omega_hat = omega_hat;
    State.psi_hat = psi_hat;
    State.t = 0.0;
    State.step = 0;
    State.setup = setup;
end

function State = spectral_step_internal(State, cfg)
    cfg = spectral_normalize_cfg(cfg);
    setup = State.setup;

    dt = cfg.dt;
    nu = cfg.nu;

    k1 = spectral_rhs_hat(State.omega_hat, setup, nu);
    w2 = (State.omega_hat + 0.5 * dt * k1) .* setup.dealias;

    k2 = spectral_rhs_hat(w2, setup, nu);
    w3 = (State.omega_hat + 0.5 * dt * k2) .* setup.dealias;

    k3 = spectral_rhs_hat(w3, setup, nu);
    w4 = (State.omega_hat + dt * k3) .* setup.dealias;

    k4 = spectral_rhs_hat(w4, setup, nu);

    omega_hat = (State.omega_hat + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4)) .* setup.dealias;
    psi_hat = spectral_streamfunction_hat(omega_hat, setup.K2_safe);

    State.omega_hat = omega_hat;
    State.psi_hat = psi_hat;
    State.omega = real(ifft2(omega_hat));
    State.psi = real(ifft2(psi_hat));
    State.t = State.t + dt;
    State.step = State.step + 1;
end

function Metrics = spectral_diagnostics_internal(State)
    setup = State.setup;
    omega = State.omega;

    [u, v] = spectral_velocity_from_psi_hat(State.psi_hat, setup);

    Metrics = struct();
    Metrics.max_vorticity = max(abs(omega(:)));
    Metrics.enstrophy = 0.5 * sum(omega(:).^2) * setup.dx * setup.dy;
    Metrics.kinetic_energy = 0.5 * sum((u(:).^2 + v(:).^2)) * setup.dx * setup.dy;
    Metrics.peak_speed = max(sqrt(u(:).^2 + v(:).^2));
    Metrics.t = State.t;
    Metrics.step = State.step;
end

function [fig_handle, analysis] = spectral_run_internal(Parameters)
    run_cfg = spectral_cfg_from_parameters(Parameters);

    if ~isfield(run_cfg, "snap_times") || isempty(run_cfg.snap_times)
        if isfield(Parameters, "num_snapshots") && Parameters.num_snapshots > 1
            n_snapshots = Parameters.num_snapshots;
        else
            n_snapshots = 9;
        end
        run_cfg.snap_times = linspace(0, run_cfg.Tfinal, n_snapshots);
    end

    State = spectral_init_internal(run_cfg);

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
            spectral_store_snapshot(State, omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, snap_idx);
    end

    Nt = max(0, ceil(run_cfg.Tfinal / run_cfg.dt));
    for n = 1:Nt
        State = spectral_step_internal(State, run_cfg);

        while snap_idx <= n_snapshots && State.t >= snap_times(snap_idx) - 1e-12
            [omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, snap_idx] = ...
                spectral_store_snapshot(State, omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, snap_idx);
        end
    end

    if snap_idx <= n_snapshots
        for idx = snap_idx:n_snapshots
            [omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, ~] = ...
                spectral_store_snapshot(State, omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, idx);
        end
    end

    analysis = struct();
    analysis.method = "spectral_fft_rk4";
    analysis.omega_snaps = omega_snaps;
    analysis.psi_snaps = psi_snaps;
    analysis.snapshot_times = sampled_times;
    analysis.time_vec = sampled_times;
    analysis.snapshots_stored = n_snapshots;
    analysis.grid_points = run_cfg.Nx * run_cfg.Ny;
    analysis.Nx = run_cfg.Nx;
    analysis.Ny = run_cfg.Ny;
    analysis.dx = run_cfg.Lx / run_cfg.Nx;
    analysis.dy = run_cfg.Ly / run_cfg.Ny;
    analysis.kinetic_energy = kinetic_energy;
    analysis.enstrophy = enstrophy;
    analysis.peak_speed_history = peak_speed;
    analysis.max_omega_history = max_omega;
    analysis.peak_abs_omega = max(max_omega);
    analysis.peak_vorticity = analysis.peak_abs_omega;
    analysis.kx = State.setup.kx;
    analysis.ky = State.setup.ky;
    analysis.frequency_metadata = struct( ...
        "kx", State.setup.kx, ...
        "ky", State.setup.ky, ...
        "dealiasing_rule", "2/3", ...
        "dkx", State.setup.dkx, ...
        "dky", State.setup.dky);

    analysis = spectral_maybe_merge_unified_metrics(analysis, Parameters);

    fig_handle = spectral_summary_figure(analysis);
end

function cfg = spectral_cfg_from_parameters(Parameters)
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
    if isfield(Parameters, "kx")
        cfg.kx = Parameters.kx;
    end
    if isfield(Parameters, "ky")
        cfg.ky = Parameters.ky;
    end
    if isfield(Parameters, "snap_times")
        cfg.snap_times = Parameters.snap_times;
    end
end

function cfg = spectral_normalize_cfg(cfg)
    needed = {"nu", "Lx", "Ly", "Nx", "Ny", "dt", "Tfinal"};
    for i = 1:numel(needed)
        if ~isfield(cfg, needed{i})
            error("Spectral:MissingField", "Missing required field: %s", needed{i});
        end
    end

    if ~isfield(cfg, "ic_type")
        cfg.ic_type = "stretched_gaussian";
    end
    if ~isfield(cfg, "ic_coeff")
        cfg.ic_coeff = [];
    end

    if isfield(cfg, "kx") && ~isempty(cfg.kx)
        cfg.kx = cfg.kx(:).';
        cfg.Nx = numel(cfg.kx);
    else
        cfg.kx = spectral_make_wavenumbers(cfg.Nx, cfg.Lx);
    end

    if isfield(cfg, "ky") && ~isempty(cfg.ky)
        cfg.ky = cfg.ky(:).';
        cfg.Ny = numel(cfg.ky);
    else
        cfg.ky = spectral_make_wavenumbers(cfg.Ny, cfg.Ly);
    end

    if mod(cfg.Nx, 2) ~= 0 || mod(cfg.Ny, 2) ~= 0
        error("Spectral:InvalidGrid", "Nx and Ny must be even for FFT-based spectral stepping.");
    end

    if cfg.Nx <= 0 || cfg.Ny <= 0 || cfg.dt <= 0 || cfg.Tfinal <= 0 || cfg.Lx <= 0 || cfg.Ly <= 0
        error("Spectral:InvalidConfig", "Nx, Ny, dt, Tfinal, Lx, Ly must all be positive.");
    end
end

function setup = spectral_build_setup(cfg)
    dx = cfg.Lx / cfg.Nx;
    dy = cfg.Ly / cfg.Ny;

    x = linspace(0, cfg.Lx - dx, cfg.Nx);
    y = linspace(0, cfg.Ly - dy, cfg.Ny);
    [X, Y] = meshgrid(x, y);

    [Kx, Ky] = meshgrid(cfg.kx, cfg.ky);
    K2 = Kx.^2 + Ky.^2;
    K2_safe = K2;
    K2_safe(1, 1) = 1;

    kx_max = max(abs(cfg.kx));
    ky_max = max(abs(cfg.ky));
    dealias = (abs(Kx) <= (2 / 3) * kx_max) & (abs(Ky) <= (2 / 3) * ky_max);

    setup = struct();
    setup.Nx = cfg.Nx;
    setup.Ny = cfg.Ny;
    setup.dx = dx;
    setup.dy = dy;
    setup.X = X;
    setup.Y = Y;
    setup.kx = cfg.kx;
    setup.ky = cfg.ky;
    setup.Kx = Kx;
    setup.Ky = Ky;
    setup.K2_safe = K2_safe;
    setup.dealias = dealias;
    setup.dkx = spectral_min_positive_spacing(cfg.kx);
    setup.dky = spectral_min_positive_spacing(cfg.ky);
end

function omega0 = spectral_initial_vorticity(cfg, X, Y)
    if isfield(cfg, "omega") && ~isempty(cfg.omega)
        omega0 = cfg.omega;
        return;
    end

    if exist("initialise_omega", "file") == 2
        omega0 = initialise_omega(X, Y, cfg.ic_type, cfg.ic_coeff);
    elseif exist("ic_factory", "file") == 2
        omega0 = ic_factory(X, Y, cfg.ic_type, cfg.ic_coeff);
    else
        omega0 = exp(-2 * (X - cfg.Lx / 2).^2 - 0.2 * (Y - cfg.Ly / 2).^2);
    end
end

function rhs_hat = spectral_rhs_hat(omega_hat, setup, nu)
    psi_hat = spectral_streamfunction_hat(omega_hat, setup.K2_safe);

    u_hat = 1i * setup.Ky .* psi_hat;
    v_hat = -1i * setup.Kx .* psi_hat;

    u = real(ifft2(u_hat));
    v = real(ifft2(v_hat));

    dwdx = real(ifft2(1i * setup.Kx .* omega_hat));
    dwdy = real(ifft2(1i * setup.Ky .* omega_hat));

    advection = u .* dwdx + v .* dwdy;
    adv_hat = fft2(advection) .* setup.dealias;
    diff_hat = nu * setup.K2_safe .* omega_hat;

    rhs_hat = -adv_hat + diff_hat;
end

function psi_hat = spectral_streamfunction_hat(omega_hat, K2_safe)
    psi_hat = -omega_hat ./ K2_safe;
    psi_hat(1, 1) = 0;
end

function [u, v] = spectral_velocity_from_psi_hat(psi_hat, setup)
    u = real(ifft2(1i * setup.Ky .* psi_hat));
    v = real(ifft2(-1i * setup.Kx .* psi_hat));
end

function [omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, next_idx] = ...
        spectral_store_snapshot(State, omega_snaps, psi_snaps, kinetic_energy, enstrophy, peak_speed, max_omega, sampled_times, idx)
    M = spectral_diagnostics_internal(State);

    omega_snaps(:, :, idx) = State.omega;
    psi_snaps(:, :, idx) = State.psi;
    kinetic_energy(idx) = M.kinetic_energy;
    enstrophy(idx) = M.enstrophy;
    peak_speed(idx) = M.peak_speed;
    max_omega(idx) = M.max_vorticity;
    sampled_times(idx) = State.t;
    next_idx = idx + 1;
end

function analysis = spectral_maybe_merge_unified_metrics(analysis, Parameters)
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

function fig_handle = spectral_summary_figure(analysis)
    show_figs = usejava("desktop") && ~strcmpi(get(0, "DefaultFigureVisible"), "off");
    fig_visibility = "off";
    if show_figs
        fig_visibility = "on";
    end

    fig_handle = figure("Name", "Spectral Analysis Results", "NumberTitle", "off", "Visible", fig_visibility);

    subplot(1, 2, 1);
    contourf(analysis.omega_snaps(:, :, end), 20);
    colorbar;
    title("Vorticity (final)");
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
        error("Spectral:MissingField", "Missing required field: %s", name);
    end
    val = S.(name);
end

function k = spectral_make_wavenumbers(N, L)
    k = (2 * pi / L) * [0:(N/2 - 1), (-N/2):-1];
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
