function omega = ic_taylor_green(X, Y, params)
% IC_TAYLOR_GREEN Taylor-Green vortex (2D turbulence decay benchmark)
%
% Classic analytical solution for periodic 2D Navier-Stokes equations.
% Exhibits exponential decay of vorticity due to viscous dissipation.
%
% Inputs:
%   X, Y    - Coordinate matrices (domain: [0, 2pi]  [0, 2pi])
%   params  - Structure with fields:
%             .wavenumber (k)  - Fundamental wavenumber
%             .strength (Gamma) - Amplitude of vorticity
%
% Output:
%   omega   - Vorticity field
%
% Mathematical form:
%   omega(x,y,t) = 2*k*Gamma * sin(k*x) * sin(k*y) * exp(-2*nu*k^2*t)
%   Note: Time dependence can be applied in time-stepping
%
% Physical relevance:
%   - Exact solution to 2D Navier-Stokes
%   - Exhibits viscous energy decay
%   - Good benchmark for numerical errors
%   - Energy: E ~ k^(-5/3) initially (2D Kraichnan spectrum)
%
% Author: Spectral Methods Implementation
% Date: February 2026

    k = params.wavenumber;
    Gamma = params.strength;
    
    % Taylor-Green vorticity (initial time t=0)
    omega = 2*k*Gamma * sin(k*X) .* sin(k*Y);
end
