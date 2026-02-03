function omega = ic_rankine(X, Y, params)
% IC_RANKINE Rankine vortex (solid-body core)
%
% Piecewise-constant vorticity profile representing a vortex with solid-body
% rotation in the core and irrotational flow outside.
%
% Inputs:
%   X, Y    - Coordinate matrices
%   params  - Structure with fields:
%             .core_vorticity (omega0) - Vorticity in core
%             .core_radius (a)        - Radius of vortex core
%
% Output:
%   omega   - Vorticity field (step function)
%
% Mathematical form:
%   omega(r) = omega0  if r <= a
%   omega(r) = 0       if r > a
%
% Physical relevance:
%   - Represents a concentrated vortex with sharp boundary
%   - Good for testing shock-capturing schemes
%   - Circulation: Gamma = pi * a^2 * omega0
%
% Author: Spectral Methods Implementation
% Date: February 2026

    omega0 = params.core_vorticity;
    a = params.core_radius;
    
    R = sqrt(X.^2 + Y.^2);
    omega = omega0 * (R <= a);
end
