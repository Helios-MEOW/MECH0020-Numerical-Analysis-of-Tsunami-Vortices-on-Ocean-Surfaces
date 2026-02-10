function varargout = FiniteVolumeMethod(action, varargin)
% FiniteVolumeMethod - Single-file finite-volume method module
%
% Supported actions:
%   callbacks
%   init(cfg, ctx)
%   step(State, cfg, ctx)
%   diagnostics(State, cfg, ctx)
%   run(Parameters)

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
            finite_volume_not_implemented("Finite Volume init is not available in dispatcher mode yet.");

        case "step"
            finite_volume_not_implemented("Finite Volume step is not available in dispatcher mode yet.");

        case "diagnostics"
            finite_volume_not_implemented("Finite Volume diagnostics are not available in dispatcher mode yet.");

        case "run"
            Parameters = varargin{1};
            [fig_handle, analysis] = finite_volume_run_internal(Parameters);
            varargout{1} = fig_handle;
            varargout{2} = analysis;

        otherwise
            error("FV:InvalidAction", ...
                "Unsupported action '%s'. Valid actions: callbacks, init, step, diagnostics, run.", ...
                char(string(action)));
    end
end

function [fig_handle, analysis] = finite_volume_run_internal(Parameters)
    required_fields = {'nu', 'Lx', 'Ly', 'Nx', 'Ny', 'dt', 'Tfinal', 'ic_type'};
    for k = 1:numel(required_fields)
        if ~isfield(Parameters, required_fields{k})
            error("FV:MissingField", "Missing required field: %s", required_fields{k});
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
    if ~isfield(Parameters, "ic_coeff")
        Parameters.ic_coeff = [];
    end

    Nx = Parameters.Nx;
    Ny = Parameters.Ny;
    Lx = Parameters.Lx;
    Ly = Parameters.Ly;
    dx = Lx / Nx;
    dy = Ly / Ny;
    dt = Parameters.dt;
    t_final = Parameters.Tfinal;

    x = linspace(0, Lx - dx, Nx);
    y = linspace(0, Ly - dy, Ny);
    [X, Y] = meshgrid(x, y);

    if exist("initialise_omega", "file") == 2
        omega = initialise_omega(X, Y, Parameters.ic_type, Parameters.ic_coeff);
    elseif exist("ic_factory", "file") == 2
        omega = ic_factory(X, Y, Parameters.ic_type, Parameters.ic_coeff);
    else
        omega = exp(-2 * (X.^2 + Y.^2));
    end

    snap_times = Parameters.snap_times(:).';
    n_snapshots = numel(snap_times);
    omega_snaps = zeros(Ny, Nx, n_snapshots);
    psi_snaps = zeros(Ny, Nx, n_snapshots);

    t = 0;
    snap_index = 1;
    while snap_index <= n_snapshots && t >= snap_times(snap_index) - 1e-12
        omega_snaps(:, :, snap_index) = omega;
        psi_snaps(:, :, snap_index) = solve_poisson_fv(omega);
        snap_index = snap_index + 1;
    end

    n_steps_guard = max(1, ceil(t_final / max(dt, eps)) * 5);
    n = 0;
    while t < t_final && n < n_steps_guard
        max_vel = max(abs(omega(:))) * 1.5;
        dt_cfl = 0.5 * min(dx, dy) / max(max_vel, 1e-6);
        dt_use = min(dt, 0.8 * dt_cfl);

        omega_1 = fv_update(omega, dt_use, dx, dy, Parameters.nu);
        omega_2 = fv_update(omega_1, dt_use, dx, dy, Parameters.nu);
        omega = omega_2;

        t = t + dt_use;
        n = n + 1;

        while snap_index <= n_snapshots && t >= snap_times(snap_index) - 1e-12
            omega_snaps(:, :, snap_index) = omega;
            psi_snaps(:, :, snap_index) = solve_poisson_fv(omega);
            snap_index = snap_index + 1;
        end
    end

    if snap_index <= n_snapshots
        psi_final = solve_poisson_fv(omega);
        omega_snaps(:, :, snap_index:end) = repmat(omega, 1, 1, n_snapshots - snap_index + 1);
        psi_snaps(:, :, snap_index:end) = repmat(psi_final, 1, 1, n_snapshots - snap_index + 1);
    end

    analysis = struct();
    analysis.method = "finite_volume";
    analysis.omega_snaps = omega_snaps;
    analysis.psi_snaps = psi_snaps;
    analysis.snapshot_times = snap_times(:);
    analysis.time_vec = snap_times(:);
    analysis.snapshots_stored = n_snapshots;
    analysis.grid_points = Nx * Ny;
    analysis.Nx = Nx;
    analysis.Ny = Ny;
    analysis.dx = dx;
    analysis.dy = dy;

    if exist("extract_unified_metrics", "file") == 2
        unified_metrics = extract_unified_metrics(omega_snaps, psi_snaps, snap_times, dx, dy, Parameters);
        analysis = merge_structs(analysis, unified_metrics);
    else
        analysis.kinetic_energy = zeros(1, n_snapshots);
        analysis.enstrophy = zeros(1, n_snapshots);
        for i = 1:n_snapshots
            omega_i = omega_snaps(:, :, i);
            psi_i = psi_snaps(:, :, i);
            [dpsi_dx, dpsi_dy] = gradient(psi_i);
            dpsi_dx = dpsi_dx / dx;
            dpsi_dy = dpsi_dy / dy;
            analysis.kinetic_energy(i) = 0.5 * sum(sum(dpsi_dx.^2 + dpsi_dy.^2)) * dx * dy;
            analysis.enstrophy(i) = 0.5 * sum(sum(omega_i.^2)) * dx * dy;
        end
    end

    analysis.peak_abs_omega = max(abs(omega_snaps(:)));
    analysis.peak_vorticity = analysis.peak_abs_omega;

    show_figs = usejava("desktop") && ~strcmpi(get(0, "DefaultFigureVisible"), "off");
    if show_figs
        fig_handle = figure("Name", "Finite Volume Analysis", "NumberTitle", "off");
        subplot(1, 2, 1);
        contourf(X, Y, omega_snaps(:, :, end), 20);
        colorbar;
        title("Vorticity (final)");
        xlabel("x");
        ylabel("y");

        subplot(1, 2, 2);
        semilogy(analysis.time_vec, analysis.enstrophy + 1e-10);
        hold on;
        semilogy(analysis.time_vec, analysis.kinetic_energy + 1e-10);
        legend("Enstrophy", "Kinetic Energy");
        xlabel("Time");
        ylabel("Value");
        grid on;
    else
        fig_handle = figure("Visible", "off");
    end
end

function omega_new = fv_update(omega, dt, dx, dy, nu)
    [Ny, Nx] = size(omega);

    omega_l = zeros(Ny, Nx);
    omega_r = zeros(Ny, Nx);
    for i = 1:Nx
        im = mod(i - 2, Nx) + 1;
        ip = mod(i, Nx) + 1;
        slope_left = omega(:, i) - omega(:, im);
        slope_right = omega(:, ip) - omega(:, i);
        slope = minmod(slope_left, slope_right);
        omega_l(:, i) = omega(:, i) - 0.5 * slope;
        omega_r(:, i) = omega(:, i) + 0.5 * slope;
    end

    psi = solve_poisson_fv(omega);
    [u, v] = get_velocity_fv(psi, dx, dy);

    flux_x = roe_flux(omega_l, omega_r, u);
    flux_y = roe_flux(omega_l, omega_r, v);

    omega_adv = omega - (dt / dx) * (flux_x(:, [2:Nx, 1]) - flux_x) ...
                      - (dt / dy) * (flux_y([2:Ny, 1], :) - flux_y);

    omega_diff = nu * dt * laplacian_periodic_fv(omega, dx, dy);
    omega_new = omega_adv + omega_diff;
end

function psi = solve_poisson_fv(omega)
    [Ny, Nx] = size(omega);
    omega_hat = fft2(omega);
    kx = 2 * pi / Nx * [0:(Nx/2 - 1), (-Nx/2):-1];
    ky = 2 * pi / Ny * [0:(Ny/2 - 1), (-Ny/2):-1];
    [Kx, Ky] = meshgrid(kx, ky);
    K2 = Kx.^2 + Ky.^2;
    K2(1, 1) = 1;
    psi_hat = -omega_hat ./ K2;
    psi_hat(1, 1) = 0;
    psi = real(ifft2(psi_hat));
end

function [u, v] = get_velocity_fv(psi, dx, dy)
    [v, u] = gradient(psi);
    u = u / dx;
    v = v / dy;
end

function lapl = laplacian_periodic_fv(F, dx, dy)
    lapl = (circshift(F, 1, 2) + circshift(F, -1, 2) - 2 * F) / (dx^2) ...
         + (circshift(F, 1, 1) + circshift(F, -1, 1) - 2 * F) / (dy^2);
end

function flux = roe_flux(F_l, F_r, vel)
    flux = (vel >= 0) .* F_l + (vel < 0) .* F_r;
    flux = vel .* flux;
end

function s = minmod(a, b)
    s = sign(a) .* max(0, min(abs(a), abs(b) .* sign(a) .* sign(b)));
    s(sign(a) ~= sign(b)) = 0;
end

function finite_volume_not_implemented(message)
    if exist("ErrorHandler", "class") == 8
        ErrorHandler.throw("SOL-FV-0001", ...
            "file", mfilename, ...
            "message", message, ...
            "context", struct("requested_method", "FiniteVolume"));
    else
        error('SOL_FV_0001:NotImplemented', '%s', char(message));
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
