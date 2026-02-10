function [fig_handle, analysis] = run_simulation_with_method(Parameters)
% run_simulation_with_method - Dispatch simulation to the selected method module
%
% Input:
%   Parameters.method - FD | Spectral | FV | Bathymetry aliases
%
% Output:
%   fig_handle - Result figure handle (visible or offscreen)
%   analysis   - Unified analysis structure

    method_normalized = normalize_method_name(Parameters);

    switch method_normalized
        case "finite_difference"
            fprintf('[Dispatcher] Routing to Finite Difference method\n');
            [fig_handle, analysis] = FiniteDifferenceMethod('run', Parameters);

        case "spectral"
            fprintf('[Dispatcher] Routing to Spectral method\n');
            [fig_handle, analysis] = SpectralMethod('run', Parameters);

        case "finite_volume"
            fprintf('[Dispatcher] Routing to Finite Volume method\n');
            [fig_handle, analysis] = FiniteVolumeMethod('run', Parameters);

        case "bathymetry"
            fprintf('[Dispatcher] Routing to Variable Bathymetry method\n');
            if exist('Variable_Bathymetry_Analysis.m', 'file') == 2
                [fig_handle, analysis] = Variable_Bathymetry_Analysis(Parameters);
            else
                warning('Variable_Bathymetry_Analysis.m not found. Falling back to Finite Difference.');
                [fig_handle, analysis] = FiniteDifferenceMethod('run', Parameters);
            end

        otherwise
            warning('Unknown method: %s. Falling back to Finite Difference.', method_normalized);
            [fig_handle, analysis] = FiniteDifferenceMethod('run', Parameters);
    end

    analysis = normalize_analysis_struct(analysis, Parameters, method_normalized);
    print_metrics_summary(analysis);
end

function method_name = normalize_method_name(Parameters)
    if isfield(Parameters, 'method') && ~isempty(Parameters.method)
        method_raw = lower(char(string(Parameters.method)));
    else
        method_raw = 'finite_difference';
    end

    switch method_raw
        case {'fd', 'finite_difference', 'finite difference'}
            method_name = "finite_difference";
        case {'spectral', 'fft', 'pseudospectral'}
            method_name = "spectral";
        case {'fv', 'finite_volume', 'finite volume'}
            method_name = "finite_volume";
        case {'bathymetry', 'variable_bathymetry', 'variable bathymetry'}
            method_name = "bathymetry";
        otherwise
            method_name = string(method_raw);
    end
end

function analysis = normalize_analysis_struct(analysis, Parameters, method_name)
    if ~isfield(analysis, 'method') || isempty(analysis.method)
        analysis.method = char(method_name);
    end

    if ~isfield(analysis, 'omega_snaps')
        analysis.omega_snaps = [];
    end
    if ~isfield(analysis, 'psi_snaps')
        analysis.psi_snaps = [];
    end

    if ~isfield(analysis, 'snapshot_times') || isempty(analysis.snapshot_times)
        if isfield(analysis, 'time_vec') && ~isempty(analysis.time_vec)
            analysis.snapshot_times = analysis.time_vec(:);
        elseif isfield(Parameters, 'snap_times') && ~isempty(Parameters.snap_times)
            analysis.snapshot_times = Parameters.snap_times(:);
        else
            analysis.snapshot_times = [];
        end
    else
        analysis.snapshot_times = analysis.snapshot_times(:);
    end

    if ~isfield(analysis, 'time_vec') || isempty(analysis.time_vec)
        analysis.time_vec = analysis.snapshot_times;
    else
        analysis.time_vec = analysis.time_vec(:);
    end

    if ~isfield(analysis, 'snapshots_stored') || isempty(analysis.snapshots_stored)
        if ~isempty(analysis.snapshot_times)
            analysis.snapshots_stored = numel(analysis.snapshot_times);
        elseif ~isempty(analysis.omega_snaps)
            analysis.snapshots_stored = size(analysis.omega_snaps, 3);
        else
            analysis.snapshots_stored = 0;
        end
    end

    if ~isfield(analysis, 'Nx')
        if isfield(Parameters, 'Nx')
            analysis.Nx = Parameters.Nx;
        elseif ~isempty(analysis.omega_snaps)
            analysis.Nx = size(analysis.omega_snaps, 2);
        else
            analysis.Nx = 0;
        end
    end

    if ~isfield(analysis, 'Ny')
        if isfield(Parameters, 'Ny')
            analysis.Ny = Parameters.Ny;
        elseif ~isempty(analysis.omega_snaps)
            analysis.Ny = size(analysis.omega_snaps, 1);
        else
            analysis.Ny = 0;
        end
    end

    if ~isfield(analysis, 'grid_points') || isempty(analysis.grid_points)
        analysis.grid_points = analysis.Nx * analysis.Ny;
    end

    if ~isfield(analysis, 'peak_abs_omega') || isempty(analysis.peak_abs_omega)
        if ~isempty(analysis.omega_snaps)
            analysis.peak_abs_omega = max(abs(analysis.omega_snaps(:)));
        else
            analysis.peak_abs_omega = NaN;
        end
    end

    if ~isfield(analysis, 'peak_vorticity') || isempty(analysis.peak_vorticity)
        analysis.peak_vorticity = analysis.peak_abs_omega;
    end
end

function print_metrics_summary(analysis)
    fprintf('\n');
    fprintf('=============== SIMULATION SUMMARY ===============\n');
    fprintf('Method: %s\n', char(string(analysis.method)));
    fprintf('Grid: %d x %d (%d points)\n', analysis.Nx, analysis.Ny, analysis.grid_points);

    if isfield(analysis, 'snapshot_times') && ~isempty(analysis.snapshot_times)
        fprintf('Snapshots: %d (t = %.3f to %.3f s)\n', ...
            analysis.snapshots_stored, min(analysis.snapshot_times), max(analysis.snapshot_times));
    else
        fprintf('Snapshots: %d\n', analysis.snapshots_stored);
    end

    if isfield(analysis, 'peak_abs_omega') && isfinite(analysis.peak_abs_omega)
        fprintf('Peak |omega|: %.6e\n', analysis.peak_abs_omega);
    end

    if isfield(analysis, 'kinetic_energy') && ~isempty(analysis.kinetic_energy)
        fprintf('Kinetic energy: %.6e -> %.6e\n', analysis.kinetic_energy(1), analysis.kinetic_energy(end));
    end

    if isfield(analysis, 'enstrophy') && ~isempty(analysis.enstrophy)
        fprintf('Enstrophy: %.6e -> %.6e\n', analysis.enstrophy(1), analysis.enstrophy(end));
    end

    if isfield(analysis, 'peak_speed') && isfinite(analysis.peak_speed)
        fprintf('Peak speed: %.6e m/s\n', analysis.peak_speed);
    end

    if isfield(analysis, 'sustainability_index') && ~isempty(analysis.sustainability_index)
        fprintf('Sustainability index (final): %.4f\n', analysis.sustainability_index(end));
    end

    fprintf('==================================================\n\n');
end
