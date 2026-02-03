function omega = ic_random_turbulence(X, Y, params)
% IC_RANDOM_TURBULENCE Random vorticity field from turbulent spectrum
%
% Generates a random vorticity field with power-law energy spectrum.
% Useful for initializing 2D turbulence decay studies and testing
% performance under realistic stochastic initial conditions.
%
% Inputs:
%   X, Y    - Coordinate matrices
%   params  - Structure with fields:
%             .spectrum_exp (alpha)  - Spectrum exponent (5/3 for Kraichnan)
%             .energy_level (E0)     - Characteristic energy level
%             .seed (optional)       - Random seed for reproducibility
%
% Output:
%   omega   - Vorticity field
%
% Mathematical form:
%   Spectral: |omega_hat_k| ~ k^(-alpha/2) * |random phase|
%   Physical: omega = IFFT(omega_hat)
%
% Spectrum exponents:
%   alpha = 5/3  : Kolmogorov turbulence (3D cascade)
%   alpha = 3    : 2D Kraichnan turbulence (enstrophy cascade)
%   alpha = 1    : White noise (high frequency)
%
% Author: Spectral Methods Implementation
% Date: February 2026

    [Nx, Ny] = size(X);
    
    % Extract parameters
    alpha = params.spectrum_exp;
    E0 = params.energy_level;
    
    % Optional: set random seed for reproducibility
    if isfield(params, 'seed')
        rng(params.seed);
    end
    
    % Wavenumber grid (proper ordering for FFT)
    kx = [0:Nx/2-1, 0, -Nx/2+1:-1]';
    ky = [0:Ny/2-1, 0, -Ny/2+1:-1]';
    [KX, KY] = meshgrid(ky, kx);
    K = sqrt(KX.^2 + KY.^2) + 1e-10; % Avoid division by zero
    
    % Random phases (uniform on [0, 2*pi])
    phi = 2*pi*rand(Nx, Ny);
    
    % Energy spectrum E(k) ~ k^(-alpha)
    % Amplitude spectrum: |omega_hat| ~ sqrt(E(k)) ~ k^(-alpha/2)
    E_k = E0 * K.^(-alpha/2);
    E_k(1,1) = 0;  % Zero mean
    
    % Complex vorticity in spectral space
    omega_hat = E_k .* exp(1i*phi);
    
    % Transform to physical space via IFFT
    omega = real(ifft2(omega_hat));
    
    % Normalize to desired energy level
    current_energy = mean(omega(:).^2);
    if current_energy > 0
        omega = omega * sqrt(E0 / current_energy);
    end
end
