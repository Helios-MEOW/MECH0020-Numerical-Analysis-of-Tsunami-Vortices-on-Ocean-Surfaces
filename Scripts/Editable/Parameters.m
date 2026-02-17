function params = Parameters()
% Parameters - Unified editable simulation parameters (all methods + modes).
%
% Edit this file for standard runs:
%   Scripts/Drivers/Tsunami_Vorticity_Emulator.m
%
% Canonical sections introduced by repo hardening:
%   output_root
%   media.*
%   reporting.*

    % ---------------------------------------------------------------------
    % Global run defaults
    % ---------------------------------------------------------------------
    params.default_method = 'FD';            % FD | Spectral | FV | Bathymetry
    params.default_mode = 'Evolution';       % Evolution | Convergence | ParameterSweep | Plotting
    params.available_methods = {'FD', 'Spectral', 'FV', 'Bathymetry'};
    params.available_modes = {'Evolution', 'Convergence', 'ParameterSweep', 'Plotting'};
    params.output_root = 'Results';

    % Keep method naming compatible with existing infrastructure.
    params.method = 'finite_difference';
    params.analysis_method = 'Finite Difference';

    % ---------------------------------------------------------------------
    % Core physics + numerics
    % ---------------------------------------------------------------------
    params.Lx = 10;
    params.Ly = 10;
    params.Nx = 128;
    params.Ny = 128;
    params.Nz = 12;                          % 3D layers for FV evolution
    params.delta = 2;
    params.use_explicit_delta = true;
    params.Lz = 1.0;                         % Vertical domain thickness for layered FV

    params.nu = 1e-6;
    params.dt = 0.01;
    params.Tfinal = 8;
    params.t_final = params.Tfinal;          % Legacy alias

    % ---------------------------------------------------------------------
    % Initial condition
    % ---------------------------------------------------------------------
    params.ic_type = 'stretched_gaussian';
    params.ic_coeff = [2, 0.2];

    % ---------------------------------------------------------------------
    % Sampling policy
    % ---------------------------------------------------------------------
    params.num_plot_snapshots = 9;
    params.num_snapshots = params.num_plot_snapshots;  % Legacy alias
    params.plot_snap_times = linspace(0, params.Tfinal, params.num_plot_snapshots);
    params.snap_times = params.plot_snap_times;         % Consumed by dispatcher modes

    params.num_animation_frames = 100;
    params.animation_times = linspace(0, params.Tfinal, params.num_animation_frames);

    % ---------------------------------------------------------------------
    % Runtime controls
    % ---------------------------------------------------------------------
    params.progress_stride = 0;              % 0 means auto
    params.live_preview = false;
    params.live_stride = 0;

    % UI / runtime-only defaults (editable canonical location)
    % These mirror the small set of UI runtime defaults previously maintained
    % inside the UIController so users can persist and edit them centrally.
    params.ic_pattern = 'single';           % default initial-condition pattern
    params.motion_enabled = false;          % whether boundary motion forcing is enabled
    params.motion_model = 'none';           % motion model name
    params.motion_amplitude = 0.0;          % amplitude for motion models
    params.sustainability_auto_log = true;  % enable auto sustainability logging by default
    params.collectors = struct('cpuz', false, 'hwinfo', false, 'icue', false, ...
        'strict', false, 'machine_tag', getenv('COMPUTERNAME'));
    params.experimentation = struct('coeff_selector', 'ic_coeff1', 'range_start', 0.5, 'range_end', 2.0, 'num_points', 4);
    params.run_mode_internal = 'Evolution'; % UI internal run-mode canonical default

    % ---------------------------------------------------------------------
    % Media policy
    % ---------------------------------------------------------------------
    params.media = struct();
    params.media.format = 'mp4';
    params.media.codec = 'MPEG-4';
    params.media.fps = 30;
    params.media.num_frames = params.num_animation_frames;
    params.media.quality = 90;
    params.media.fallback_format = 'gif';

    % Compatibility aliases used by existing analysis helpers.
    params.mode = 'solve';
    params.create_animations = true;
    params.animation_format = params.media.format;
    params.animation_quality = params.media.quality;
    params.animation_codec = params.media.codec;
    params.animation_fps = params.media.fps;
    params.animation_dir = '';   % Resolved at runtime to canonical Results/<...>/Media/Animation

    % ---------------------------------------------------------------------
    % Reporting policy
    % ---------------------------------------------------------------------
    params.reporting = struct();
    params.reporting.template = 'default';
    params.reporting.template_by_mode = struct( ...
        'Evolution', 'evolution', ...
        'Convergence', 'convergence', ...
        'ParameterSweep', 'parameter_sweep', ...
        'Plotting', 'plotting');
    params.report_template = params.reporting.template;  % Alias

    % ---------------------------------------------------------------------
    % Convergence mode options
    % ---------------------------------------------------------------------
    params.mesh_sizes = [32, 64, 128];
    params.convergence_variable = 'max_omega';   % max_omega | energy | enstrophy
    params.conv_tolerance = 1e-6;
    params.conv_max_iter = 8;
    % Spectral-specific convergence (frequency-domain refinement by explicit k-vectors)
    params.spectral_convergence = struct();
    params.spectral_convergence.levels = [ ...
        struct('label', 'k32',  'kx', make_kvec(32,  params.Lx), 'ky', make_kvec(32,  params.Ly)), ...
        struct('label', 'k64',  'kx', make_kvec(64,  params.Lx), 'ky', make_kvec(64,  params.Ly)), ...
        struct('label', 'k128', 'kx', make_kvec(128, params.Lx), 'ky', make_kvec(128, params.Ly))];

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

    params.method_config.fv3d = struct( ...
        'vertical_diffusivity_scale', 1.0, ...
        'z_boundary', 'no_flux', ...
        'projection', 'depth_average');

    params.method_config.bathymetry = struct( ...
        'enabled', false, ...
        'bathymetry_file', '', ...
        'bathymetry_resolution', 1, ...
        'use_dry_mask', true);

    % Compatibility aliases used in existing analysis helpers.
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
        'enabled', true, ...
        'build_model', false, ...
        'auto_compare', false, ...
        'machine_tag', 'auto', ...
        'collector_paths', struct('cpuz', '', 'hwinfo', '', 'icue', ''));
end

function k = make_kvec(N, L)
    if mod(N, 2) ~= 0
        error('Parameters:InvalidSpectralGrid', 'Spectral convergence levels require even N, got %d', N);
    end
    k = (2 * pi / L) * [0:(N/2 - 1), (-N/2):-1];
end
