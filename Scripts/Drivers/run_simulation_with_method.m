function [fig_handle, analysis] = run_simulation_with_method(Parameters)
% RUN_SIMULATION_WITH_METHOD Method dispatcher with comprehensive metrics
%
% This function routes simulation calls to the appropriate numerical method
% based on Parameters.method field, providing a seamless interface with unified
% data extraction for vorticity, energy, velocity, and sustainability metrics.
%
% COMPREHENSIVE DATA EXTRACTION
% ================================
% All methods now extract the following key metrics:
%
% VORTICITY METRICS:
%   - peak_abs_omega         : Maximum absolute vorticity (s^-1)
%   - peak_omega_history     : Peak vorticity time history
%   - mean_omega_history     : Mean absolute vorticity time history
%   - rms_omega_history      : RMS vorticity time history
%
% ENERGY METRICS:
%   - kinetic_energy         : Time history of kinetic energy (J/kg)
%   - enstrophy              : Time history of enstrophy (s^-2)
%   - energy_decay           : Normalized energy decay (1-E(t)/E(0))
%   - final_kinetic_energy   : Final kinetic energy value
%   - final_enstrophy        : Final enstrophy value
%
% VELOCITY METRICS:
%   - u_snaps                : u-component velocity snapshots
%   - v_snaps                : v-component velocity snapshots
%   - peak_u                 : Maximum u-velocity (m/s)
%   - peak_v                 : Maximum v-velocity (m/s)
%   - peak_speed             : Maximum speed sqrt(u+v) (m/s)
%   - peak_u_history         : u-velocity time history
%   - peak_v_history         : v-velocity time history
%   - peak_speed_history     : Speed time history
%   - mean_speed_history     : Mean speed time history
%   - final_peak_u           : Final u-velocity
%   - final_peak_v           : Final v-velocity
%
% FLOW SUSTAINABILITY METRICS:
%   - circulation            : Integrated vorticity (mass flux)
%   - circulation_decay      : Normalized circulation decay
%   - sustainability_index   : Structure preservation measure (0-1)
%   - dissipation_rate       : Rate of energy dissipation
%   - energy_dissipation     : Time derivative of kinetic energy
%   - enstrophy_decay_rate   : Normalized enstrophy decay rate
%
% GRID DIAGNOSTICS:
%   - Nx, Ny                 : Grid dimensions
%   - dx, dy                 : Grid spacing
%   - grid_points            : Total number of grid points
%   - domain_area            : Total domain area
%
% SNAPSHOT DATA:
%   - omega_snaps            : Vorticity field snapshots
%   - psi_snaps              : Streamfunction snapshots
%   - snapshot_times         : Times of snapshots
%   - snapshots_stored       : Number of snapshots
%
% Usage:
%   [fig_handle, analysis] = run_simulation_with_method(Parameters)
%
% Input:
%   Parameters - struct with 'method' field and all required numerical parameters
%
% Output:
%   fig_handle - handle to generated figure
%   analysis   - struct with comprehensive metrics listed above

    % Normalize method name
    if isstring(Parameters.method) || ischar(Parameters.method)
        method_normalized = lower(char(Parameters.method));
    else
        method_normalized = 'finite_difference';  % Default
    end
    
    % Route to appropriate solver
    switch method_normalized
        case {'fd', 'finite_difference', 'finite difference'}
            fprintf('[Dispatcher] Routing to Finite Difference method\n');
            [fig_handle, analysis] = Finite_Difference_Analysis(Parameters);
            
        case {'spectral', 'fft', 'pseudospectral'}
            fprintf('[Dispatcher] Routing to Spectral (FFT) method\n');
            [fig_handle, analysis] = Spectral_Analysis(Parameters);
            
        case {'fv', 'finite_volume', 'finite volume'}
            fprintf('[Dispatcher] Routing to Finite Volume method\n');
            if exist('Finite_Volume_Analysis.m', 'file') == 2
                [fig_handle, analysis] = Finite_Volume_Analysis(Parameters);
            else
                warning('Finite_Volume_Analysis.m not found. Falling back to Finite Difference.');
                [fig_handle, analysis] = Finite_Difference_Analysis(Parameters);
            end
            
        case {'bathymetry', 'variable_bathymetry', 'variable bathymetry'}
            fprintf('[Dispatcher] Routing to Variable Bathymetry method\n');
            if exist('Variable_Bathymetry_Analysis.m', 'file') == 2
                [fig_handle, analysis] = Variable_Bathymetry_Analysis(Parameters);
            else
                warning('Variable_Bathymetry_Analysis.m not found. Falling back to Finite Difference.');
                [fig_handle, analysis] = Finite_Difference_Analysis(Parameters);
            end
            
        otherwise
            warning('Unknown method: %s. Using Finite Difference as default.', method_normalized);
            [fig_handle, analysis] = Finite_Difference_Analysis(Parameters);
    end
    
    % Ensure analysis struct has method field for tracking
    if ~isfield(analysis, 'method')
        analysis.method = method_normalized;
    end

    if ~isfield(analysis, 'omega_snaps')
        analysis.omega_snaps = [];
    end
    if ~isfield(analysis, 'psi_snaps')
        analysis.psi_snaps = [];
    end
    if ~isfield(analysis, 'time_vec')
        if isfield(analysis, 'snapshot_times')
            analysis.time_vec = analysis.snapshot_times;
        elseif isfield(analysis, 'snap_times')
            analysis.time_vec = analysis.snap_times;
        else
            analysis.time_vec = [];
        end
    end
    if ~isfield(analysis, 'snapshot_times')
        analysis.snapshot_times = analysis.time_vec;
    end
    if ~isfield(analysis, 'snapshots_stored')
        if ~isempty(analysis.snapshot_times)
            analysis.snapshots_stored = numel(analysis.snapshot_times);
        else
            analysis.snapshots_stored = 0;
        end
    end
    if ~isfield(analysis, 'grid_points') && isfield(analysis, 'Nx') && isfield(analysis, 'Ny')
        analysis.grid_points = analysis.Nx * analysis.Ny;
    end
    if ~isfield(analysis, 'peak_abs_omega') && ~isempty(analysis.omega_snaps)
        analysis.peak_abs_omega = max(abs(analysis.omega_snaps(:)));
    end
    if ~isfield(analysis, 'peak_vorticity') && isfield(analysis, 'peak_abs_omega')
        analysis.peak_vorticity = analysis.peak_abs_omega;
    end
    
    % Print summary of extracted metrics
    fprintf('\n');
    fprintf('\n');
    fprintf('               SIMULATION METRICS EXTRACTION SUMMARY        \n');
    fprintf('\n');
    fprintf('Method: %s\n', analysis.method);
    fprintf('Grid: %d  %d = %d points\n', analysis.Nx, analysis.Ny, analysis.grid_points);
    fprintf('Snapshots: %d at times [%.3f - %.3f] s\n', analysis.snapshots_stored, ...
        min(analysis.snapshot_times), max(analysis.snapshot_times));
    fprintf('\nVorticity Metrics:\n');
    fprintf('   Peak |ω|: %.6e s\n', analysis.peak_abs_omega);
    fprintf('   Mean |ω|: %.6e s\n', mean(analysis.mean_omega_history));
    fprintf('   RMS ω: %.6e s\n', mean(analysis.rms_omega_history));
    fprintf('\nEnergy Metrics:\n');
    fprintf('   Initial KE: %.6e J/kg\n', analysis.kinetic_energy(1));
    fprintf('   Final KE: %.6e J/kg\n', analysis.kinetic_energy(end));
    fprintf('   Energy decay: %.2f %%\n', 100*analysis.energy_decay(end));
    fprintf('   Initial enstrophy: %.6e s\n', analysis.enstrophy(1));
    fprintf('   Final enstrophy: %.6e s\n', analysis.enstrophy(end));
    fprintf('\nVelocity Metrics:\n');
    fprintf('   Peak |u|: %.6e m/s\n', analysis.peak_u);
    fprintf('   Peak |v|: %.6e m/s\n', analysis.peak_v);
    fprintf('   Peak speed: %.6e m/s\n', analysis.peak_speed);
    fprintf('   Mean speed: %.6e m/s\n', mean(analysis.mean_speed_history));
    fprintf('\nSustainability Metrics:\n');
    fprintf('   Circulation: %.6e\n', analysis.circulation(end));
    fprintf('   Circulation decay: %.2f %%\n', 100*analysis.circulation_decay(end));
    fprintf('   Sustainability index: %.4f (1.0=perfect)\n', analysis.sustainability_index(end));
    if isfield(analysis, 'dissipation_rate')
        fprintf('   Dissipation rate: %.6e\n', mean(analysis.dissipation_rate));
    end
    fprintf('\n');
    fprintf('\n');
end
