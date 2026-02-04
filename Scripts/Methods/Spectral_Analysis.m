% ========================================================================
% Spectral_Analysis.m - FFT-based Pseudospectral Method
% ========================================================================
% Implements J. Nathan Kutz's pseudospectral approach for 2D vorticity
%
% DISPATCH WRAPPER (Entry Point):
%   [fig_handle, analysis] = Spectral_Analysis(Parameters)
%   
% ORIGINAL IMPLEMENTATION (Internal):
%   [T, omega, psi, meta] = Spectral_Analysis_Impl(X, Y, omega0, Parameters)

function [fig_handle, analysis] = Spectral_Analysis(Parameters)
    % Dispatch wrapper to match Finite_Difference_Analysis interface
    % This allows seamless method switching via method dispatcher
    
    % Validate required parameters
    required_fields = {'nu','Lx','Ly','Nx','Ny','dt','Tfinal','snap_times','ic_type'};
    for k = 1:numel(required_fields)
        if ~isfield(Parameters, required_fields{k})
            error('Missing required field: %s', required_fields{k});
        end
    end
    
    % Initialize grid
    dx = Parameters.Lx / Parameters.Nx;
    dy = Parameters.Ly / Parameters.Ny;
    x = linspace(0, Parameters.Lx - dx, Parameters.Nx);
    y = linspace(0, Parameters.Ly - dy, Parameters.Ny);
    [X, Y] = meshgrid(x, y);
    
    % Compute initial condition
    % Try to call initialise_omega from Analysis.m if available, otherwise use ic_factory
    if exist('initialise_omega', 'file') == 2
        omega0 = initialise_omega(X, Y, Parameters.ic_type, Parameters.ic_coeff);
    elseif exist('ic_factory', 'file') == 2
        omega0 = ic_factory(X, Y, Parameters.ic_type, Parameters.ic_coeff);
    else
        % Fallback: simple Gaussian if IC functions not available
        warning('Neither initialise_omega nor ic_factory found - using fallback Gaussian IC');
        if numel(Parameters.ic_coeff) >= 2
            omega0 = exp(-Parameters.ic_coeff(1)*(X - Parameters.Lx/2).^2 - Parameters.ic_coeff(2)*(Y - Parameters.Ly/2).^2);
        else
            omega0 = exp(-2*(X - Parameters.Lx/2).^2 - 0.2*(Y - Parameters.Ly/2).^2);
        end
    end
    
    % Call internal implementation
    [T, omega_full, psi_full, meta] = Spectral_Analysis_Impl(X, Y, omega0, Parameters);
    
    % Extract snapshots at requested times
    [~, snap_indices] = intersect(T, Parameters.snap_times, 'rows');
    if isempty(snap_indices)
        % If exact times not found, use nearest neighbors
        snap_indices = [];
        for i = 1:length(Parameters.snap_times)
            [~, idx] = min(abs(T - Parameters.snap_times(i)));
            snap_indices = [snap_indices; idx];
        end
    end
    
    % Build analysis struct compatible with FD method output
    analysis = struct();
    analysis.method = 'spectral';
    analysis.omega_snaps = omega_full(:, :, snap_indices);
    analysis.psi_snaps = psi_full(:, :, snap_indices);
    analysis.time_vec = T;
    
    % === UNIFIED METRICS EXTRACTION ===
    % Use comprehensive metrics framework for consistency across all methods
    if exist('extract_unified_metrics', 'file') == 2
        snap_times_extracted = T(snap_indices);
        unified_metrics = extract_unified_metrics(analysis.omega_snaps, analysis.psi_snaps, snap_times_extracted, dx, dy, Parameters);
        
        % Merge unified metrics into analysis struct
        analysis = mergestruct(analysis, unified_metrics);
    else
        % Fallback: minimal metrics extraction if helper function not available
        analysis.kinetic_energy = zeros(1, length(T));
        analysis.enstrophy = zeros(1, length(T));
        for t = 1:length(T)
            omega_t = omega_full(:, :, t);
            psi_t = psi_full(:, :, t);
            
            [dpsidx, dpsidy] = gradient(psi_t);
            dpsidx = dpsidx / dx;
            dpsidy = dpsidy / dy;
            analysis.kinetic_energy(t) = 0.5 * sum(sum(dpsidx.^2 + dpsidy.^2)) * dx * dy;
            analysis.enstrophy(t) = 0.5 * sum(sum(omega_t.^2)) * dx * dy;
        end
        analysis.peak_vorticity = max(abs(omega_full(:)));
    end
    
    % Metadata
    analysis.meta = meta;
    analysis.dx = dx;
    analysis.dy = dy;
    analysis.Nx = Parameters.Nx;
    analysis.Ny = Parameters.Ny;
    
    % Create figure (compatible with FD output)
    fig_handle = figure('Name', 'Spectral Analysis Results', 'NumberTitle', 'off');
    subplot(1, 2, 1);
    contourf(X, Y, analysis.omega_snaps(:, :, end), 20);
    colorbar; title('Vorticity (final)'); xlabel('x'); ylabel('y');
    
    subplot(1, 2, 2);
    semilogy(analysis.time_vec, analysis.enstrophy + 1e-10);
    hold on; semilogy(analysis.time_vec, analysis.kinetic_energy + 1e-10);
    legend('Enstrophy', 'Kinetic Energy'); xlabel('Time'); ylabel('Value');
    grid on;
end

function [T, omega, psi, meta] = Spectral_Analysis_Impl(X, Y, omega0, Parameters)
    % Spectral pseudospectral method for 2D vorticity dynamics
    
    % Grid parameters
    [Nx, Ny] = size(X);
    Lx = Parameters.Lx;
    Ly = Parameters.Ly;
    
    % Time parameters
    dt = Parameters.dt;
    t_final = Parameters.t_final;
    nu = Parameters.nu;
    
    % Wavenumber arrays for FFT
    kx = (2*pi/Lx) * [0:Nx/2-1, -Nx/2:-1]';
    ky = (2*pi/Ly) * [0:Ny/2-1, -Ny/2:-1]';
    [Kx, Ky] = meshgrid(ky, kx);
    K2 = Kx.^2 + Ky.^2;
    K2(1,1) = 1;
    
    % De-aliasing filter (2/3 rule)
    kx_max = max(abs(kx));
    ky_max = max(abs(ky));
    dealias = (abs(Kx) <= (2/3)*kx_max) & (abs(Ky) <= (2/3)*ky_max);
    
    % Time stepping
    nt = ceil(t_final / dt) + 1;
    T = linspace(0, t_final, nt);
    
    % Storage
    omega = zeros(Nx, Ny, nt);
    psi = zeros(Nx, Ny, nt);
    omega(:,:,1) = omega0;
    
    % Initial spectral coefficients
    omega_hat = fft2(omega0);
    
    fprintf('[Spectral] FFT Pseudospectral RK4, Grid: %dx%d, dt=%.4f, nu=%.6e\n', ...
        Nx, Ny, dt, nu);
    
    % RK4 time integration
    for n = 1:nt-1
        % RK4 stages
        k1 = get_spectral_rhs(omega_hat, Kx, Ky, K2, nu, dealias);
        
        omega_hat_2 = (omega_hat + 0.5*dt*k1) .* dealias;
        k2 = get_spectral_rhs(omega_hat_2, Kx, Ky, K2, nu, dealias);
        
        omega_hat_3 = (omega_hat + 0.5*dt*k2) .* dealias;
        k3 = get_spectral_rhs(omega_hat_3, Kx, Ky, K2, nu, dealias);
        
        omega_hat_4 = (omega_hat + dt*k3) .* dealias;
        k4 = get_spectral_rhs(omega_hat_4, Kx, Ky, K2, nu, dealias);
        
        % RK4 update
        omega_hat = (omega_hat + (dt/6)*(k1 + 2*k2 + 2*k3 + k4)) .* dealias;
        
        % Store solution
        omega(:,:,n+1) = real(ifft2(omega_hat));
        
        % Stream function
        psi_hat = -omega_hat ./ K2;
        psi_hat(1,1) = 0;
        psi(:,:,n+1) = real(ifft2(psi_hat));
        
        % Progress
        if mod(n, max(1, round(nt/20))) == 0
            omega_current = omega(:,:,n+1);
            omega_max = max(abs(omega_current(:)));
            fprintf('  t=%.4f: ||omega||_inf=%.4e\n', T(n+1), omega_max);
        end
    end
    
    % Metadata
    meta.method = 'Spectral (FFT Pseudospectral)';
    meta.Nx = Nx;
    meta.Ny = Ny;
    meta.dt = dt;
    meta.nu = nu;
    meta.t_final = t_final;
    meta.de_aliasing = '2/3 rule';
end

function rhs = get_spectral_rhs(omega_hat, Kx, Ky, K2, nu, dealias)
    % RHS of vorticity equation in spectral space
    
    K2_safe = K2;
    K2_safe(1,1) = 1;
    
    % Stream function
    psi_hat = -omega_hat ./ K2_safe;
    psi_hat(1,1) = 0;
    
    % Velocity
    u_hat = 1i * Ky .* psi_hat;
    v_hat = -1i * Kx .* psi_hat;
    u = real(ifft2(u_hat));
    v = real(ifft2(v_hat));
    
    % Vorticity derivatives
    dw_dx = real(ifft2(1i * Kx .* omega_hat));
    dw_dy = real(ifft2(1i * Ky .* omega_hat));
    
    % Advection in physical space
    advection = u .* dw_dx + v .* dw_dy;
    adv_hat = fft2(advection) .* dealias;
    
    % Diffusion
    diff_hat = nu * K2_safe .* omega_hat;
    
    % RHS
    rhs = -adv_hat + diff_hat;
end
