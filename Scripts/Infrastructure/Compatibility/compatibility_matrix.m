function [status, reason] = compatibility_matrix(method, mode)
    % compatibility_matrix - Method/Mode Compatibility Checker
    %
    % Purpose:
    %   Single source of truth for method/mode compatibility
    %   Used by mode scripts to validate configurations early
    %
    % Inputs:
    %   method - Method name ('FD', 'Spectral', 'FV')
    %   mode - Mode name ('Evolution', 'Convergence', 'ParameterSweep', 'Plotting')
    %
    % Outputs:
    %   status - 'supported' | 'experimental' | 'blocked'
    %   reason - Explanation string (for blocked/experimental)
    %
    % Usage:
    %   [status, reason] = compatibility_matrix('FD', 'Evolution');
    %   if strcmp(status, 'blocked')
    %       error('Incompatible: %s', reason);
    %   end

    % Normalize inputs
    method = lower(method);
    mode = lower(mode);

    % ===== FINITE DIFFERENCE COMPATIBILITY =====
    if strcmp(method, 'fd')
        switch mode
            case 'evolution'
                status = 'supported';
                reason = '';
            case 'convergence'
                status = 'supported';
                reason = '';
            case 'parametersweep'
                status = 'supported';
                reason = '';
            case 'plotting'
                status = 'supported';
                reason = '';
            case 'variablebathymetry'
                status = 'experimental';
                reason = 'Variable bathymetry is experimental for FD method';
            otherwise
                status = 'blocked';
                reason = sprintf('Unknown mode: %s', mode);
        end
        return;
    end

    % ===== SPECTRAL METHOD COMPATIBILITY =====
    if strcmp(method, 'spectral') || strcmp(method, 'fft')
        switch mode
            case 'evolution'
                status = 'experimental';
                reason = 'Spectral evolution is enabled under the single-file callback module.';
            case 'convergence'
                status = 'experimental';
                reason = 'Spectral convergence uses frequency-domain refinement (explicit k-vectors).';
            case 'parametersweep'
                status = 'blocked';
                reason = 'Spectral parameter sweep not enabled in this checkpoint.';
            case 'plotting'
                status = 'supported';
                reason = '';  % Plotting is method-agnostic
            case 'variablebathymetry'
                status = 'blocked';
                reason = 'Spectral method not compatible with variable bathymetry';
            otherwise
                status = 'blocked';
                reason = sprintf('Unknown mode: %s', mode);
        end
        return;
    end

    % ===== FINITE VOLUME COMPATIBILITY =====
    if strcmp(method, 'fv') || strcmp(method, 'finitevolume')
        switch mode
            case 'evolution'
                status = 'experimental';
                reason = 'Finite Volume evolution runs as layered 3D FV on structured Cartesian mesh.';
            case 'convergence'
                status = 'blocked';
                reason = 'Finite Volume convergence is deferred to the next checkpoint.';
            case 'parametersweep'
                status = 'blocked';
                reason = 'Finite Volume parameter sweep is deferred to the next checkpoint.';
            case 'plotting'
                status = 'supported';
                reason = '';  % Plotting is method-agnostic
            case 'variablebathymetry'
                status = 'experimental';
                reason = 'FV + bathymetry is experimental (requires flux reconstruction)';
            otherwise
                status = 'blocked';
                reason = sprintf('Unknown mode: %s', mode);
        end
        return;
    end

    % ===== UNKNOWN METHOD =====
    status = 'blocked';
    reason = sprintf('Unknown method: %s. Valid methods: FD, Spectral, FV', method);
end
