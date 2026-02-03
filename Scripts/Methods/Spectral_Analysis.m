% ========================================================================
% Spectral_Analysis.m - FFT-based Pseudospectral Method
% ========================================================================
% Implements J. Nathan Kutz's pseudospectral approach for 2D vorticity

function [T, omega, psi, meta] = Spectral_Analysis(X, Y, omega0, Parameters, ~)
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
