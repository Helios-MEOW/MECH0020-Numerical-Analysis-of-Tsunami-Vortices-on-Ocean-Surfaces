function omega = initialise_omega(X, Y, ic_type, ic_coeff)
    % initialise_omega - Shared initial-condition factory for all methods.
    %
    % Why this exists:
    %   Keeps FD/Spectral/FV and test runs aligned on the same IC formulas.
    %   Avoids duplicated IC logic across method implementations.
    %
    % Inputs:
    %   X, Y      - meshgrid coordinates (Ny-by-Nx)
    %   ic_type   - canonical IC name or alias (case/spacing tolerant)
    %   ic_coeff  - optional coefficient vector interpreted per ic_type
    %
    % Output:
    %   omega     - initial vorticity field, same size as X/Y

    if isstring(ic_type) || ischar(ic_type)
        % Normalize user-facing aliases into one switch-friendly token.
        ic_type = lower(char(ic_type));
        ic_type = strrep(ic_type, '-', '_');
        ic_type = strrep(ic_type, ' ', '_');
    end

    if ~isnumeric(ic_coeff) || isempty(ic_coeff)
        ic_coeff = [];
    end

    params = ic_coeff_to_params(ic_type, ic_coeff);

    switch ic_type
        case 'lamb_oseen'
            Gamma = params.circulation;
            nu = params.nu;
            t0 = max(params.virtual_time, 1.0e-6);
            x0 = params.center_x;
            y0 = params.center_y;
            R2 = (X - x0).^2 + (Y - y0).^2;
            omega = (Gamma / (4 * pi * nu * t0)) * exp(-R2 / (4 * nu * t0));

        case 'rankine'
            omega0 = params.core_vorticity;
            rc = params.core_radius;
            x0 = params.center_x;
            y0 = params.center_y;
            R = sqrt((X - x0).^2 + (Y - y0).^2);
            omega = zeros(size(X));
            omega(R <= rc) = omega0;

        case 'lamb_dipole'
            U = params.translation_speed;
            a = max(params.dipole_radius, 1.0e-6);
            x0 = params.center_x;
            y0 = params.center_y;
            r1_2 = (X - x0 + a/2).^2 + (Y - y0).^2;
            r2_2 = (X - x0 - a/2).^2 + (Y - y0).^2;
            a2 = a^2;
            omega = (U/(pi*a2)) * (exp(-r1_2/a2) - exp(-r2_2/a2));

        case 'taylor_green'
            k = params.wavenumber;
            G = params.strength;
            x0 = params.center_x;
            y0 = params.center_y;
            omega = 2 * k * G * sin(k * (X - x0)) .* sin(k * (Y - y0));

        case 'random_turbulence'
            alpha = params.spectrum_exp;
            E0 = params.energy_level;
            seed = params.seed;
            % Deterministic random IC: reproducible when seed is fixed.
            rng(seed);
            kmax = 4;
            omega = zeros(size(X));
            for k = 1:kmax
                omega = omega + (E0 / k^(alpha/2)) * sin(k * X) .* cos(k * Y);
            end

        case 'elliptical_vortex'
            w0 = params.peak_vorticity;
            sx = max(params.width_x, 1.0e-6);
            sy = max(params.width_y, 1.0e-6);
            theta = params.rotation_angle;
            x0 = params.center_x;
            y0 = params.center_y;
            Xc = X - x0;
            Yc = Y - y0;
            xr = cos(theta) * Xc + sin(theta) * Yc;
            yr = -sin(theta) * Xc + cos(theta) * Yc;
            omega = w0 * exp(-(xr.^2 / (2*sx^2) + yr.^2 / (2*sy^2)));

        case {'stretched_gaussian', 'gaussian'}  % 'gaussian' is alias for stretched_gaussian
            if isempty(ic_coeff) || numel(ic_coeff) < 2
                x_coeff = -1.0;
                y_coeff = -1.0;
            else
                % Legacy convention stores positive widths; we convert to the
                % negative quadratic exponent form expected by exp(a*x^2+b*y^2).
                x_coeff = -ic_coeff(1);
                y_coeff = -ic_coeff(2);
            end
            x0 = 0; y0 = 0;
            if numel(ic_coeff) >= 6
                x0 = ic_coeff(5);
                y0 = ic_coeff(6);
            end
            omega = exp(x_coeff*(X-x0).^2 + y_coeff*(Y-y0).^2);

        case 'vortex_blob_gaussian'
            if numel(ic_coeff) >= 4
                Circulation = ic_coeff(1);
                Radius = ic_coeff(2);
                x_0 = ic_coeff(3);
                y_0 = ic_coeff(4);
            else
                error('vortex_blob_gaussian requires ic_coeff = [Circulation, Radius, x_0, y_0], got %d elements', numel(ic_coeff));
            end
            if numel(ic_coeff) >= 6 && (x_0 == 0 && y_0 == 0)
                x_0 = ic_coeff(5);
                y_0 = ic_coeff(6);
            end
            omega = Circulation/(2 * pi * Radius^2) * exp(-((X-x_0).^2 + (Y-y_0).^2)/(2*Radius^2));

        case 'vortex_pair'
            if numel(ic_coeff) >= 6
                Gamma1 = ic_coeff(1);
                R1 = ic_coeff(2);
                x1 = ic_coeff(3);
                y1 = ic_coeff(4);
                Gamma2 = ic_coeff(5);
                x2 = ic_coeff(6);
                y2 = 10 - y1;
            else
                error('vortex_pair requires 6 coefficients: [Gamma1, R1, x1, y1, Gamma2, x2]');
            end
            vort1 = Gamma1/(2*pi*R1^2) * exp(-((X-x1).^2 + (Y-y1).^2)/(2*R1^2));
            vort2 = Gamma2/(2*pi*R1^2) * exp(-((X-x2).^2 + (Y-y2).^2)/(2*R1^2));
            omega = vort1 + vort2;

        case 'multi_vortex'
            omega = zeros(size(X));
            if numel(ic_coeff) >= 10
                % Coeff layout: [G1 R1 x1 y1 G2 R2 x2 y2 G3 x3 y3 (R3 optional)]
                G1 = ic_coeff(1); R1 = ic_coeff(2); x1 = ic_coeff(3); y1 = ic_coeff(4);
                omega = omega + G1/(2*pi*R1^2) * exp(-((X-x1).^2 + (Y-y1).^2)/(2*R1^2));

                G2 = ic_coeff(5); R2 = ic_coeff(6); x2 = ic_coeff(7); y2 = ic_coeff(8);
                omega = omega + G2/(2*pi*R2^2) * exp(-((X-x2).^2 + (Y-y2).^2)/(2*R2^2));

                G3 = ic_coeff(9); x3 = ic_coeff(10); y3 = ic_coeff(11);
                R3 = 1.5;
                if numel(ic_coeff) >= 12
                    R3 = ic_coeff(12);
                end
                omega = omega + G3/(2*pi*R3^2) * exp(-((X-x3).^2 + (Y-y3).^2)/(2*R3^2));
            else
                error('multi_vortex requires at least 10 coefficients');
            end

        case 'counter_rotating_pair'
            if numel(ic_coeff) >= 8
                G1 = ic_coeff(1); R1 = ic_coeff(2); x1 = ic_coeff(3); y1 = ic_coeff(4);
                G2 = ic_coeff(5); R2 = ic_coeff(6); x2 = ic_coeff(7); y2 = ic_coeff(8);
            else
                error('counter_rotating_pair requires 8 coefficients: [G1,R1,x1,y1, G2,R2,x2,y2]');
            end
            vort1 = G1/(2*pi*R1^2) * exp(-((X-x1).^2 + (Y-y1).^2)/(2*R1^2));
            vort2 = G2/(2*pi*R2^2) * exp(-((X-x2).^2 + (Y-y2).^2)/(2*R1^2));
            omega = vort1 + vort2;

        case 'placeholder2'
            omega = zeros(size(X));

        case 'kutz'
            omega = sin(X) .* cos(Y);

        otherwise
            error('Unknown ic_type: %s', ic_type);
    end
end

function params = ic_coeff_to_params(ic_type, ic_coeff)
    % ic_coeff_to_params - Decode coefficient vector into named parameters.
    % Unspecified coefficients fall back to physically safe defaults.
    params = struct();

    switch ic_type
        case 'lamb_oseen'
            params.circulation = get_coeff(ic_coeff, 1, 1.0);
            params.virtual_time = get_coeff(ic_coeff, 2, 1.0);
            params.nu = get_coeff(ic_coeff, 3, 0.001);

        case 'rankine'
            params.core_vorticity = get_coeff(ic_coeff, 1, 1.0);
            params.core_radius = get_coeff(ic_coeff, 2, 1.0);

        case 'lamb_dipole'
            params.translation_speed = get_coeff(ic_coeff, 1, 0.5);
            params.dipole_radius = get_coeff(ic_coeff, 2, 1.0);

        case 'taylor_green'
            params.wavenumber = get_coeff(ic_coeff, 1, 1.0);
            params.strength = get_coeff(ic_coeff, 2, 1.0);

        case 'random_turbulence'
            params.spectrum_exp = get_coeff(ic_coeff, 1, 5/3);
            params.energy_level = get_coeff(ic_coeff, 2, 1.0);
            params.seed = get_coeff(ic_coeff, 3, 0);

        case 'elliptical_vortex'
            params.peak_vorticity = get_coeff(ic_coeff, 1, 1.0);
            params.width_x = get_coeff(ic_coeff, 2, 1.0);
            params.width_y = get_coeff(ic_coeff, 3, 0.5);
            params.rotation_angle = get_coeff(ic_coeff, 4, 0.0);
    end

    if ~isempty(fieldnames(params))
        params.center_x = get_coeff(ic_coeff, 5, 0.0);
        params.center_y = get_coeff(ic_coeff, 6, 0.0);
    end
end

function val = get_coeff(ic_coeff, index, default)
    % get_coeff - Safe coefficient accessor with default fallback.
    if numel(ic_coeff) >= index
        val = ic_coeff(index);
    else
        val = default;
    end
end
