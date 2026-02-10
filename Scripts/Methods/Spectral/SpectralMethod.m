function varargout = SpectralMethod(action, varargin)
% SpectralMethod - Single-file spectral method module
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
            callbacks.init = @(cfg, ctx) SpectralMethod("init", cfg, ctx);
            callbacks.step = @(State, cfg, ctx) SpectralMethod("step", State, cfg, ctx);
            callbacks.diagnostics = @(State, cfg, ctx) SpectralMethod("diagnostics", State, cfg, ctx);
            callbacks.run = @(Parameters) SpectralMethod("run", Parameters);
            varargout{1} = callbacks;

        case "init"
            spectral_not_implemented("Spectral init is not available in dispatcher mode yet.");

        case "step"
            spectral_not_implemented("Spectral step is not available in dispatcher mode yet.");

        case "diagnostics"
            spectral_not_implemented("Spectral diagnostics are not available in dispatcher mode yet.");

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

function [fig_handle, analysis] = spectral_run_internal(Parameters)
    required_fields = {'nu', 'Lx', 'Ly', 'Nx', 'Ny', 'dt', 'Tfinal', 'ic_type'};
    for k = 1:numel(required_fields)
        if ~isfield(Parameters, required_fields{k})
            error("Spectral:MissingField", "Missing required field: %s", required_fields{k});
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

    dx = Parameters.Lx / Parameters.Nx;
    dy = Parameters.Ly / Parameters.Ny;
    x = linspace(0, Parameters.Lx - dx, Parameters.Nx);
    y = linspace(0, Parameters.Ly - dy, Parameters.Ny);
    [X, Y] = meshgrid(x, y);

    if exist("initialise_omega", "file") == 2
        omega0 = initialise_omega(X, Y, Parameters.ic_type, Parameters.ic_coeff);
    elseif exist("ic_factory", "file") == 2
        omega0 = ic_factory(X, Y, Parameters.ic_type, Parameters.ic_coeff);
    else
        omega0 = exp(-2 * (X - Parameters.Lx / 2).^2 - 0.2 * (Y - Parameters.Ly / 2).^2);
    end

    [time_vec, omega_full, psi_full, meta] = spectral_impl(omega0, Parameters);

    snap_times = Parameters.snap_times(:).';
    n_snapshots = numel(snap_times);
    snap_indices = zeros(1, n_snapshots);
    for i = 1:n_snapshots
        [~, snap_indices(i)] = min(abs(time_vec - snap_times(i)));
    end

    omega_snaps = omega_full(:, :, snap_indices);
    psi_snaps = psi_full(:, :, snap_indices);
    selected_times = time_vec(snap_indices);

    analysis = struct();
    analysis.method = "spectral";
    analysis.omega_snaps = omega_snaps;
    analysis.psi_snaps = psi_snaps;
    analysis.time_vec = selected_times(:);
    analysis.snapshot_times = selected_times(:);
    analysis.snapshots_stored = n_snapshots;
    analysis.grid_points = Parameters.Nx * Parameters.Ny;
    analysis.Nx = Parameters.Nx;
    analysis.Ny = Parameters.Ny;
    analysis.dx = dx;
    analysis.dy = dy;
    analysis.meta = meta;

    if exist("extract_unified_metrics", "file") == 2
        unified_metrics = extract_unified_metrics(omega_snaps, psi_snaps, selected_times, dx, dy, Parameters);
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
        fig_handle = figure("Name", "Spectral Analysis Results", "NumberTitle", "off");
        subplot(1, 2, 1);
        contourf(x, y, omega_snaps(:, :, end), 20);
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

function [time_vec, omega, psi, meta] = spectral_impl(omega0, Parameters)
    [Ny, Nx] = size(omega0);
    Lx = Parameters.Lx;
    Ly = Parameters.Ly;
    dt = Parameters.dt;
    t_final = Parameters.Tfinal;
    nu = Parameters.nu;

    kx = (2 * pi / Lx) * [0:(Nx/2 - 1), (-Nx/2):-1];
    ky = (2 * pi / Ly) * [0:(Ny/2 - 1), (-Ny/2):-1];
    [Kx, Ky] = meshgrid(kx, ky);
    K2 = Kx.^2 + Ky.^2;
    K2(1, 1) = 1;

    kx_max = max(abs(kx));
    ky_max = max(abs(ky));
    dealias = (abs(Kx) <= (2 / 3) * kx_max) & (abs(Ky) <= (2 / 3) * ky_max);

    n_steps = ceil(t_final / dt) + 1;
    time_vec = linspace(0, t_final, n_steps);

    omega = zeros(Ny, Nx, n_steps);
    psi = zeros(Ny, Nx, n_steps);
    omega(:, :, 1) = omega0;

    omega_hat = fft2(omega0);
    psi_hat = -omega_hat ./ K2;
    psi_hat(1, 1) = 0;
    psi(:, :, 1) = real(ifft2(psi_hat));

    for n = 1:(n_steps - 1)
        k1 = spectral_rhs(omega_hat, Kx, Ky, K2, nu, dealias);

        omega_hat_2 = (omega_hat + 0.5 * dt * k1) .* dealias;
        k2 = spectral_rhs(omega_hat_2, Kx, Ky, K2, nu, dealias);

        omega_hat_3 = (omega_hat + 0.5 * dt * k2) .* dealias;
        k3 = spectral_rhs(omega_hat_3, Kx, Ky, K2, nu, dealias);

        omega_hat_4 = (omega_hat + dt * k3) .* dealias;
        k4 = spectral_rhs(omega_hat_4, Kx, Ky, K2, nu, dealias);

        omega_hat = (omega_hat + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4)) .* dealias;

        omega(:, :, n + 1) = real(ifft2(omega_hat));
        psi_hat = -omega_hat ./ K2;
        psi_hat(1, 1) = 0;
        psi(:, :, n + 1) = real(ifft2(psi_hat));
    end

    meta = struct();
    meta.method = "Spectral (FFT)";
    meta.Nx = Nx;
    meta.Ny = Ny;
    meta.dt = dt;
    meta.nu = nu;
    meta.t_final = t_final;
end

function rhs = spectral_rhs(omega_hat, Kx, Ky, K2, nu, dealias)
    K2_safe = K2;
    K2_safe(1, 1) = 1;

    psi_hat = -omega_hat ./ K2_safe;
    psi_hat(1, 1) = 0;

    u_hat = 1i * Ky .* psi_hat;
    v_hat = -1i * Kx .* psi_hat;
    u = real(ifft2(u_hat));
    v = real(ifft2(v_hat));

    dw_dx = real(ifft2(1i * Kx .* omega_hat));
    dw_dy = real(ifft2(1i * Ky .* omega_hat));

    advection = u .* dw_dx + v .* dw_dy;
    adv_hat = fft2(advection) .* dealias;
    diff_hat = nu * K2_safe .* omega_hat;

    rhs = -adv_hat + diff_hat;
end

function spectral_not_implemented(message)
    if exist("ErrorHandler", "class") == 8
        ErrorHandler.throw("SOL-SP-0001", ...
            "file", mfilename, ...
            "message", message, ...
            "context", struct("requested_method", "Spectral"));
    else
        error('SOL_SP_0001:NotImplemented', '%s', char(message));
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
