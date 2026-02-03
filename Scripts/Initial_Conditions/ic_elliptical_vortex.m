function omega = ic_elliptical_vortex(X, Y, params)
% IC_ELLIPTICAL_VORTEX Elliptical (asymmetric) Gaussian vortex
%
% Represents a vortex with elliptical (non-circular) shape.
% Common in geophysical and atmospheric vortices that are deformed
% by external shear or asymmetric forcing.
%
% Inputs:
%   X, Y    - Coordinate matrices
%   params  - Structure with fields:
%             .peak_vorticity (omega0)     - Peak vorticity magnitude
%             .width_x (sigma_x)           - Width in x-direction
%             .width_y (sigma_y)           - Width in y-direction
%             .rotation_angle (theta)      - Rotation angle (radians)
%
% Output:
%   omega   - Vorticity field
%
% Mathematical form:
%   omega(x,y) = omega0 * exp(-(xr^2/(2*sigma_x^2) + yr^2/(2*sigma_y^2)))
%   where (xr, yr) are rotated coordinates
%
% Physical relevance:
%   - Represents asymmetric vortices
%   - Exhibits asymmetric instabilities
%   - Common in mesoscale ocean eddies
%   - Aspect ratio = sigma_x / sigma_y determines elongation
%
% Author: Spectral Methods Implementation
% Date: February 2026

    % Extract parameters
    omega0 = params.peak_vorticity;
    sigma_x = params.width_x;
    sigma_y = params.width_y;
    rotation_angle = params.rotation_angle;
    
    % Rotate coordinates
    Xr = X*cos(rotation_angle) + Y*sin(rotation_angle);
    Yr = -X*sin(rotation_angle) + Y*cos(rotation_angle);
    
    % Elliptical Gaussian
    omega = omega0 * exp(-Xr.^2/(2*sigma_x^2) - Yr.^2/(2*sigma_y^2));
end
