function omega = ic_lamb_dipole(X, Y, params)
% IC_LAMB_DIPOLE Lamb dipole (exact translating vortex pair solution)
%
% The Lamb dipole is an exact analytical solution of the 2D Euler equations
% that represents a rotating vortex pair translating at constant velocity.
%
% Inputs:
%   X, Y    - Coordinate matrices
%   params  - Structure with fields:
%             .translation_speed (U) - Speed of dipole translation
%             .dipole_radius (a)    - Radius of dipole region
%
% Output:
%   omega   - Vorticity field
%
% Mathematical form (inside r <= a):
%   omega(r,theta) = -(2*U / (a*J0(ka))) * J1(k*r) * sin(theta)
%   where k*a = 3.832 (first zero of J1)
%
% Physical relevance:
%   - Exact solution to 2D Navier-Stokes (in inviscid limit)
%   - Represents counter-rotating vortex pair
%   - Translates without deformation
%   - Classical benchmark for vortex dynamics
%
% Author: Spectral Methods Implementation
% Date: February 2026

    U = params.translation_speed;
    a = params.dipole_radius;
    
    % k*a equals first zero of J1 Bessel function
    ka = 3.83170598; % More precise value
    k = ka / a;
    
    % Polar coordinates
    R = sqrt(X.^2 + Y.^2);
    THETA = atan2(Y, X);
    
    % Lamb dipole profile (zero outside r = a)
    omega = zeros(size(X));
    mask = R <= a;
    
    % Inside dipole region
    J0_ka = besselj(0, ka);
    omega(mask) = -(2*U / (a*J0_ka)) * besselj(1, k*R(mask)) .* sin(THETA(mask));
end
