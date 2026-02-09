function omega = ic_factory(X, Y, ic_type, ic_coeff)
% IC_FACTORY Standalone initial condition factory function
%
% Provides access to all initial condition functions without requiring
% Analysis.m to be on the path. Used by method dispatchers that need IC init.
%
% Usage:
%   omega = ic_factory(X, Y, 'lamb_oseen', [1.0, 0.5]);
%   omega = ic_factory(X, Y, 'stretched_gaussian', [2.0, 0.2, 0, 0, 0.5, -0.3]);
%
% Input:
%   X, Y  - 2D coordinate arrays (from meshgrid)
%   ic_type - string: IC type name (see below)
%   ic_coeff - numeric array: IC coefficients (length varies by type)
%
% Output:
%   omega - 2D vorticity field

    % Convert ic_type to lowercase
    if isstring(ic_type) || ischar(ic_type)
        ic_type = lower(char(ic_type));
    end

    % Ensure ic_coeff is valid
    if ~isnumeric(ic_coeff) || isempty(ic_coeff)
        ic_coeff = [];
    end

    switch ic_type
        case 'lamb_oseen'
            omega = ic_factory_lamb_oseen(X, Y, ic_coeff);

        case 'rankine'
            omega = ic_factory_rankine(X, Y, ic_coeff);

        case 'lamb_dipole'
            omega = ic_factory_lamb_dipole(X, Y, ic_coeff);

        case 'taylor_green'
            omega = ic_factory_taylor_green(X, Y, ic_coeff);

        case 'random_turbulence'
            omega = ic_factory_random_turbulence(X, Y, ic_coeff);

        case 'elliptical_vortex'
            omega = ic_factory_elliptical_vortex(X, Y, ic_coeff);

        case 'stretched_gaussian'
            % Stretched Gaussian vortex (legacy)
            if isempty(ic_coeff) || numel(ic_coeff) < 2
                x_coeff = -1.0;
                y_coeff = -1.0;
            else
                x_coeff = -ic_coeff(1);
                y_coeff = -ic_coeff(2);
            end
            x0 = 0; y0 = 0;
            if numel(ic_coeff) >= 6
                x0 = ic_coeff(5);
                y0 = ic_coeff(6);
            end
            omega = exp(x_coeff*(X-x0).^2 + y_coeff*(Y-y0).^2);

        otherwise
            warning('Unknown IC type: %s. Using stretched Gaussian fallback.', ic_type);
            omega = exp(-1*(X.^2 + Y.^2));
    end
end

% Fallback IC implementations (minimal)
function omega = ic_factory_lamb_oseen(X, Y, ic_coeff)
    % Lamb-Oseen vortex: omega = (Gamma/(2*pi*a^2)) * exp(-r^2/(2*a^2))
    if numel(ic_coeff) < 2
        Gamma = 1.0;
        a = 0.5;
    else
        Gamma = ic_coeff(1);
        a = ic_coeff(2);
    end
    r2 = X.^2 + Y.^2;
    omega = (Gamma/(2*pi*a^2)) * exp(-r2/(2*a^2));
end

function omega = ic_factory_rankine(X, Y, ic_coeff)
    % Rankine vortex
    if numel(ic_coeff) < 2
        Gamma = 1.0;
        a = 0.5;
    else
        Gamma = ic_coeff(1);
        a = ic_coeff(2);
    end
    r2 = X.^2 + Y.^2;
    r = sqrt(r2);
    omega = zeros(size(X));
    core = r <= a;
    omega(core) = 2*Gamma/(pi*a^2);
    omega(~core) = 0;
end

function omega = ic_factory_lamb_dipole(X, Y, ic_coeff)
    % Lamb dipole (simple Gaussian pair surrogate)
    if numel(ic_coeff) < 2
        Gamma = 1.0;
        a = 0.5;
    else
        Gamma = ic_coeff(1);
        a = ic_coeff(2);
    end
    r1_2 = (X+a/2).^2 + Y.^2;
    r2_2 = (X-a/2).^2 + Y.^2;
    a2 = a^2;
    omega = (Gamma/(pi*a2)) * (exp(-r1_2/a2) - exp(-r2_2/a2));
end

function omega = ic_factory_taylor_green(X, Y, ~)
    % Taylor-Green vortex
    omega = sin(2*pi*X) .* sin(2*pi*Y);
end

function omega = ic_factory_random_turbulence(X, Y, ~)
    % Random turbulent field
    rng(42);  % Fixed seed for reproducibility
    kmax = 4;
    omega = zeros(size(X));
    for k = 1:kmax
        omega = omega + sin(k*2*pi*X) .* cos(k*2*pi*Y) / k;
    end
end

function omega = ic_factory_elliptical_vortex(X, Y, ic_coeff)
    % Elliptical vortex
    if numel(ic_coeff) < 2
        a = 1.5;
        b = 1.0;
    else
        a = ic_coeff(1);
        b = ic_coeff(2);
    end
    ellipse = (X/a).^2 + (Y/b).^2;
    omega = exp(-ellipse);
end
