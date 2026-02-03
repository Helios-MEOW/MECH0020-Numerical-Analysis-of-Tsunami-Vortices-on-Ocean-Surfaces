function omega = ic_lamb_oseen(X, Y, params)
% IC_LAMB_OSEEN Lamb-Oseen viscous vortex
%
% Represents a diffusing point vortex with Gaussian decay of vorticity.
% Common in geophysical flows and represents decay of concentrated vorticity.
%
% Inputs:
%   X, Y    - Coordinate matrices
%   params  - Structure with fields:
%             .circulation (Gamma) - Circulation strength
%             .virtual_time (t0)   - Virtual/reference time for viscous decay
%             .nu                  - Kinematic viscosity
%
% Output:
%   omega   - Vorticity field
%
% Mathematical form:
%   omega(r) = (Gamma / (4*pi*nu*t0)) * exp(-r^2 / (4*nu*t0))
%
% Author: Spectral Methods Implementation
% Date: February 2026

    % Extract parameters
    Gamma = params.circulation;
    t0 = params.virtual_time;
    nu = params.nu;
    
    % Distance from center
    R = sqrt(X.^2 + Y.^2);
    
    % Lamb-Oseen profile
    omega = (Gamma / (4*pi*nu*t0)) * exp(-R.^2 / (4*nu*t0));
end
