function [fig_handle, analysis] = Finite_Volume_Analysis(Parameters)
% FINITE_VOLUME_ANALYSIS Conservative finite volume method for 2D vorticity
%
% Implements a conservative finite volume discretization with:
%   - Cell-centered storage of vorticity
%   - MUSCL reconstruction for higher-order accuracy
%   - Roe Riemann solver for advection fluxes
%   - RK3-SSP time stepping
%
% Physics:
%   Volume-averaged vorticity: d/dt<ω> + div(flux) = νω
%   Flux: F = uω (conservative advection)
%   Update: ω_new = ω_old - (Δt/dx)*(F_face)

    required_fields = {'nu','Lx','Ly','Nx','Ny','dt','Tfinal','snap_times','ic_type'};
    for k = 1:numel(required_fields)
        if ~isfield(Parameters, required_fields{k})
            error('Missing required field: %s', required_fields{k});
        end
    end

    Nx = Parameters.Nx;
    Ny = Parameters.Ny;
    Lx = Parameters.Lx;
    Ly = Parameters.Ly;
    dx = Lx / Nx;
    dy = Ly / Ny;
    
    x = linspace(0, Lx - dx, Nx);
    y = linspace(0, Ly - dy, Ny);
    [X, Y] = meshgrid(x, y);
    
    % Initial condition
    if exist('initialise_omega', 'file') == 2
        omega = initialise_omega(X, Y, Parameters.ic_type, Parameters.ic_coeff);
    elseif exist('ic_factory', 'file') == 2
        omega = ic_factory(X, Y, Parameters.ic_type, Parameters.ic_coeff);
    else
        omega = exp(-2*(X.^2 + Y.^2));
    end
    
    dt = Parameters.dt;
    Tfinal = Parameters.Tfinal;
    t = 0;
    n = 0;
    
    snap_times = Parameters.snap_times;
    snap_idx = 1;
    omega_snaps = zeros(Ny, Nx, length(snap_times));
    psi_snaps = zeros(Ny, Nx, length(snap_times));
    time_vec = [];
    
    omega_snaps(:,:,1) = omega;
    psi_snaps(:,:,1) = solve_poisson_fv(omega, dx, dy);
    time_vec = [time_vec, t];
    snap_idx = 2;
    
    fprintf('[Finite Volume] Grid: %dx%d, dx=%.4f, RK3 + MUSCL + Roe\n', Nx, Ny, dx);
    
    while t < Tfinal && n < 10000
        % CFL
        max_vel = max(abs(omega(:))) * 1.5;
        dt_cfl = 0.5 * min(dx, dy) / max(max_vel, 1e-6);
        dt_use = min(dt, 0.8 * dt_cfl);
        
        % RK3-SSP
        [omega_1] = fv_update(omega, dt_use, dx, dy, Parameters.nu);
        [omega_2] = fv_update(omega_1, dt_use, dx, dy, Parameters.nu);
        omega = omega_2;
        
        t = t + dt_use;
        n = n + 1;
        
        % Snapshots
        while snap_idx <= length(snap_times) && t >= snap_times(snap_idx)
            omega_snaps(:,:,snap_idx) = omega;
            psi_snaps(:,:,snap_idx) = solve_poisson_fv(omega, dx, dy);
            time_vec = [time_vec, t];
            snap_idx = snap_idx + 1;
        end
        
        if mod(n, max(1, round(Tfinal/dt/20))) == 0
            fprintf('  t=%.3f: ||ω||_=%.4e\n', t, max(abs(omega(:))));
        end
    end
    
    omega_snaps = omega_snaps(:,:,1:snap_idx-1);
    psi_snaps = psi_snaps(:,:,1:snap_idx-1);
    
    analysis = struct();
    analysis.method = 'finite_volume';
    analysis.omega_snaps = omega_snaps;
    analysis.psi_snaps = psi_snaps;
    analysis.snapshot_times = time_vec;
    analysis.snap_times = time_vec;  % Ensure both naming conventions work
    
    % === UNIFIED METRICS EXTRACTION ===
    % Use comprehensive metrics framework for consistency across all methods
    if exist('extract_unified_metrics', 'file') == 2
        unified_metrics = extract_unified_metrics(omega_snaps, psi_snaps, time_vec, dx, dy, Parameters);
        
        % Merge unified metrics into analysis struct
        analysis = mergestruct(analysis, unified_metrics);
    else
        % Fallback: compute basic metrics if helper function not available
        analysis.kinetic_energy = zeros(1, length(time_vec));
        analysis.enstrophy = zeros(1, length(time_vec));
        for i = 1:length(time_vec)
            omega_t = omega_snaps(:,:,i);
            psi_t = psi_snaps(:,:,i);
            
            [dpsi_dx, dpsi_dy] = gradient(psi_t);
            dpsi_dx = dpsi_dx / dx;
            dpsi_dy = dpsi_dy / dy;
            analysis.kinetic_energy(i) = 0.5 * sum(sum(dpsi_dx.^2 + dpsi_dy.^2)) * dx * dy;
            analysis.enstrophy(i) = 0.5 * sum(sum(omega_t.^2)) * dx * dy;
        end
        analysis.peak_vorticity = max(abs(omega_snaps(:)));
    end
    
    analysis.dx = dx;
    analysis.dy = dy;
    analysis.Nx = Nx;
    analysis.Ny = Ny;
    
    fig_handle = figure('Name', 'Finite Volume Analysis', 'NumberTitle', 'off');
    subplot(1, 2, 1);
    contourf(X, Y, analysis.omega_snaps(:,:,end), 20);
    colorbar; title('Vorticity (FV)'); xlabel('x'); ylabel('y');
    
    subplot(1, 2, 2);
    semilogy(analysis.time_vec, analysis.enstrophy + 1e-10);
    hold on; semilogy(analysis.time_vec, analysis.kinetic_energy + 1e-10);
    legend('Enstrophy', 'KE'); xlabel('Time'); ylabel('Value');
    grid on;
end

function omega_new = fv_update(omega, dt, dx, dy, nu)
    [Ny, Nx] = size(omega);
    
    % MUSCL slopes
    omega_L = zeros(Ny, Nx);
    omega_R = zeros(Ny, Nx);
    for i = 1:Nx
        im = mod(i-2, Nx) + 1;
        ip = mod(i, Nx) + 1;
        slope_left = omega(:,i) - omega(:,im);
        slope_right = omega(:,ip) - omega(:,i);
        slope = minmod(slope_left, slope_right);
        omega_L(:,i) = omega(:,i) - 0.5 * slope;
        omega_R(:,i) = omega(:,i) + 0.5 * slope;
    end
    
    psi = solve_poisson_fv(omega, dx, dy);
    [u, v] = get_velocity_fv(psi, dx, dy);
    
    flux_x = roe_flux(omega_L, omega_R, u);
    flux_y = roe_flux(omega_L, omega_R, v);
    
    omega_adv = omega - (dt/dx) * (flux_x(:,[2:Nx 1]) - flux_x) - ...
                       (dt/dy) * (flux_y([2:Ny 1],:) - flux_y);
    
    omega_diff = nu * dt * laplacian_periodic_fv(omega, dx, dy);
    
    omega_new = omega_adv + omega_diff;
end

function psi = solve_poisson_fv(omega, dx, dy)
    [Ny, Nx] = size(omega);
    omega_hat = fft2(omega);
    kx = 2*pi/Nx * [0:Nx/2-1, -Nx/2:-1];
    ky = 2*pi/Ny * [0:Ny/2-1, -Ny/2:-1];
    [Kx, Ky] = meshgrid(kx, ky);
    K2 = Kx.^2 + Ky.^2;
    K2(1,1) = 1;
    psi_hat = -omega_hat ./ K2;
    psi_hat(1,1) = 0;
    psi = real(ifft2(psi_hat));
end

function [u, v] = get_velocity_fv(psi, dx, dy)
    [v, u] = gradient(psi);
    u = u / dx;
    v = v / dy;
end

function lapl = laplacian_periodic_fv(f, dx, dy)
    lapl = (circshift(f,1,2) + circshift(f,-1,2) - 2*f) / (dx^2) + ...
           (circshift(f,1,1) + circshift(f,-1,1) - 2*f) / (dy^2);
end

function flux = roe_flux(f_L, f_R, vel)
    flux = (vel >= 0) .* f_L + (vel < 0) .* f_R;
    flux = vel .* flux;
end

function s = minmod(a, b)
    s = sign(a) .* max(0, min(abs(a), abs(b) .* sign(a) .* sign(b)));
    s(sign(a) ~= sign(b)) = 0;
end
