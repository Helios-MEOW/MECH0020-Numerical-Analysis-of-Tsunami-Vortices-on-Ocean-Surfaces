function params = Parameters()
% Parameters - Unified editable simulation parameters (all methods + all modes)
%
% Edit this file for standard runs.
% Driver reference:
%   Scripts/Drivers/Tsunami_Vorticity_Emulator.m
%
% Notes on timing:
%   - num_plot_snapshots controls the tiled 3x3 evolution panels.
%   - num_animation_frames controls animation sampling.
%   - These are intentionally separate knobs.

    % ---------------------------------------------------------------------
    % Global run defaults
    % ---------------------------------------------------------------------
    params.default_method = 'FD';            % FD | Spectral | FV | Bathymetry
    params.default_mode = 'Evolution';       % Evolution | Convergence | ParameterSweep | Plotting
    params.available_methods = {'FD', 'Spectral', 'FV', 'Bathymetry'};
    params.available_modes = {'Evolution', 'Convergence', 'ParameterSweep', 'Plotting'};

    % Keep method naming compatible with existing infrastructure.
    params.method = 'finite_difference';
    params.analysis_method = 'Finite Difference';

    % ---------------------------------------------------------------------
    % Core physics + numerics (default values aligned with create_default_parameters)
    % ---------------------------------------------------------------------
    params.Lx = 10;
    params.Ly = 10;
    params.Nx = 128;
    params.Ny = 128;
    params.delta = 2;
    params.use_explicit_delta = true;

    params.nu = 1e-6;
    params.dt = 0.01;
    params.Tfinal = 8;
    params.t_final = params.Tfinal;          % Alias used by some legacy helpers.

    % ---------------------------------------------------------------------
    % Initial condition
    % ---------------------------------------------------------------------
    params.ic_type = 'stretched_gaussian';
    params.ic_coeff = [2, 0.2];

    % ---------------------------------------------------------------------
    % Sampling policy
    % Relationship:
    %   - plot snapshots are for tiled diagnostics/figures
    %   - animation frames are for video/gif generation
    % ---------------------------------------------------------------------
    params.num_plot_snapshots = 9;           % For 3x3 tiled plots
    params.num_snapshots = params.num_plot_snapshots;  % Compatibility alias
    params.plot_snap_times = linspace(0, params.Tfinal, params.num_plot_snapshots);
    params.snap_times = params.plot_snap_times;         % ModeDispatcher currently consumes snap_times

    params.num_animation_frames = 100;       % Independent from plot snapshots
    params.animation_times = linspace(0, params.Tfinal, params.num_animation_frames);

    % ---------------------------------------------------------------------
    % Runtime controls
    % ---------------------------------------------------------------------
    params.progress_stride = 0;              % 0 means auto
    params.live_preview = false;
    params.live_stride = 0;

    % ---------------------------------------------------------------------
    % Evolution mode options
    % ---------------------------------------------------------------------
    params.mode = 'solve';
    params.create_animations = true;
    params.animation_format = 'gif';
    params.animation_quality = 90;
    params.animation_codec = 'MPEG-4';
    params.animation_dir = fullfile('Figures', params.analysis_method, 'Animations');

    % ---------------------------------------------------------------------
    % Convergence mode options
    % ---------------------------------------------------------------------
    params.mesh_sizes = [32, 64, 128];
    params.convergence_variable = 'max_omega';   % max_omega | energy | enstrophy
    params.conv_tolerance = 1e-6;
    params.conv_max_iter = 8;

    % ---------------------------------------------------------------------
    % Parameter sweep mode options
    % ---------------------------------------------------------------------
    params.sweep_parameter = 'nu';
    params.sweep_values = [1e-6, 5e-6, 1e-5];

    % ---------------------------------------------------------------------
    % Plotting mode options
    % ---------------------------------------------------------------------
    params.plot_types = {'contours', 'evolution'};
    params.source_run_id = '';

    % ---------------------------------------------------------------------
    % Method-specific sub-configurations
    % ---------------------------------------------------------------------
    params.method_config = struct();

    params.method_config.fd = struct( ...
        'advection_scheme', 'Arakawa', ...
        'time_integrator', 'RK4', ...
        'poisson_solver', 'SparsePeriodic');

    params.method_config.spectral = struct( ...
        'dealiasing_rule', '2/3', ...
        'time_integrator', 'RK4', ...
        'transform_backend', 'fft2');

    params.method_config.fv = struct( ...
        'reconstruction', 'MUSCL', ...
        'flux', 'Roe', ...
        'time_integrator', 'RK3');

    params.method_config.bathymetry = struct( ...
        'enabled', false, ...
        'bathymetry_file', '', ...
        'bathymetry_resolution', 1, ...
        'use_dry_mask', true);

    % Compatibility aliases used in existing analysis helpers
    params.bathymetry_enabled = params.method_config.bathymetry.enabled;
    params.bathymetry_file = params.method_config.bathymetry.bathymetry_file;
    params.bathymetry_resolution = params.method_config.bathymetry.bathymetry_resolution;
    params.bathymetry_use_dry_mask = params.method_config.bathymetry.use_dry_mask;

    % ---------------------------------------------------------------------
    % Sustainability hooks
    % ---------------------------------------------------------------------
    params.energy_monitoring = struct( ...
        'enabled', true, ...
        'sample_interval', 0.5, ...
        'output_dir', '../../sensor_logs');

    params.sustainability = struct( ...
        'enabled', false, ...
        'build_model', false, ...
        'auto_compare', false);
end
