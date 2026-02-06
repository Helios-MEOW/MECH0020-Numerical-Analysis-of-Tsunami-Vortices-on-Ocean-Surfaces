function params = default_parameters(method)
% DEFAULT_PARAMETERS Unified default parameters for all simulation methods
%
% Purpose:
%   Single source of truth for all default simulation parameters
%   Organizes parameters into logical sections with inline documentation
%   Supports method-specific parameter sets via switch
%
% Location: Scripts/Config/ (user-editable directory)
%
% Usage:
%   params = default_parameters();           % Returns FD defaults
%   params = default_parameters('FD');       % Finite Difference
%   params = default_parameters('Spectral'); % Spectral method
%   params.Nx = 256;                         % Override as needed
%
% Input:
%   method - (optional) String: 'FD', 'Spectral', 'FV', 'Bathymetry'
%            Default: 'FD'
%
% Returns:
%   params - Struct with all default simulation parameters
%
% Author: MECH0020 Framework
% Date: February 2026

    % Default to Finite Difference if no method specified
    if nargin < 1 || isempty(method)
        method = 'FD';
    end
    
    % Normalize method string
    method = char(method);
    if strcmpi(method, 'Finite Difference')
        method = 'FD';
    end
    
    % ===== GRID PARAMETERS =====
    % Grid resolution and domain size
    switch upper(method)
        case 'FD'
            params.Nx = 128;                        % Grid points X (typical: 64, 128, 256, 512)
            params.Ny = 128;                        % Grid points Y
            params.Lx = 2 * pi;                     % Domain size X (meters)
            params.Ly = 2 * pi;                     % Domain size Y (meters)
            params.delta = 2;                       % Grid spacing scaling factor
            params.use_explicit_delta = false;      % Use explicit delta instead of computed
            
        case 'SPECTRAL'
            params.Nx = 128;                        % Grid points X (power of 2 recommended)
            params.Ny = 128;                        % Grid points Y
            params.Lx = 10;                         % Domain size X (meters)
            params.Ly = 10;                         % Domain size Y (meters)
            
        case {'FV', 'BATHYMETRY'}
            params.Nx = 128;
            params.Ny = 128;
            params.Lx = 10;
            params.Ly = 10;
            
        otherwise
            error('Unknown method: %s. Use FD, Spectral, FV, or Bathymetry', method);
    end
    
    % ===== PHYSICS PARAMETERS =====
    % Physical properties of the flow
    params.nu = 0.001;                              % Kinematic viscosity (m^2/s)
                                                    % Typical range: 1e-6 (water) to 1e-3
    
    % ===== TIME INTEGRATION =====
    % Temporal discretization
    params.dt = 0.001;                              % Timestep (seconds)
    params.Tfinal = 1.0;                            % Final simulation time (seconds)
    params.t_final = params.Tfinal;                 % Alias for compatibility
    params.time_scheme = 'rk2';                     % Time integration: 'euler', 'rk2', 'rk4'
    
    % ===== INITIAL CONDITION =====
    % Vorticity field initialization
    params.ic_type = 'Lamb-Oseen';                  % IC type: 'Lamb-Oseen', 'stretched_gaussian',
                                                    %         'double_vortex', 'random'
    params.ic_coeff = [];                           % IC-specific coefficients (varies by type)
                                                    % Lamb-Oseen: [Gamma, r0]
                                                    % stretched_gaussian: [A, sigma, x0, y0, sx, sy]
    
    % ===== OUTPUT & SNAPSHOTS =====
    % Control what data is saved and when
    params.num_snapshots = 11;                      % Number of snapshots to save
    params.snap_times = linspace(0, params.Tfinal, params.num_snapshots);
    
    % ===== PROGRESS & MONITORING =====
    % Live feedback during simulation
    params.progress_stride = 100;                   % Console output every N steps (0 = off)
    params.live_preview = false;                    % Enable live figure updates
    params.live_stride = 0;                         % Update figure every N steps (0 = off)
    
    % ===== ANIMATION SETTINGS =====
    % Animation generation (when enabled as setting)
    params.create_animations = false;               % Generate animations (default off)
    params.animation_format = 'gif';                % Format: 'gif', 'mp4', 'avi'
    params.animation_fps = 30;                      % Frame rate
    params.animation_quality = 90;                  % Quality (1-100 for video codecs)
    params.animation_num_frames = 100;              % Number of frames
    params.animation_codec = 'MPEG-4';              % Codec for video formats
    params.animation_dir = [];                      % Set automatically if empty
    
    % ===== BATHYMETRY (if applicable) =====
    % Variable bathymetry settings
    params.bathymetry_enabled = false;              % Enable bathymetry
    params.bathymetry_file = '';                    % Path to bathymetry data file
    params.bathymetry_resolution = 1;               % Resolution scaling
    params.bathymetry_use_dry_mask = true;          % Use dry cell masking
    
    % ===== METHOD & MODE =====
    % Execution control
    params.method = lower(method);                  % Method identifier (lowercase)
    params.analysis_method = get_method_display_name(method);  % Display name
    params.mode = 'Evolution';                      % Run mode: 'Evolution', 'Convergence', 'ParameterSweep'
    params.method_config = [];                      % Method-specific config (set externally)
    
    % ===== ENERGY MONITORING =====
    % Hardware/energy tracking (optional)
    params.energy_monitoring = struct(...
        'enabled', false, ...                       % Enable energy monitoring
        'sample_interval', 0.5, ...                 % Sample every N seconds
        'output_dir', '../../sensor_logs');         % Log output directory
    
    % ===== SUSTAINABILITY =====
    % Carbon footprint estimation (optional)
    params.sustainability = struct(...
        'enabled', false, ...                       % Enable sustainability tracking
        'build_model', false, ...                   % Build power model
        'auto_compare', false);                     % Auto-compare with baseline
    
    % ===== POST-PROCESSING =====
    % Set derived fields
    if isempty(params.animation_dir)
        params.animation_dir = fullfile('Figures', params.analysis_method, 'Animations');
    end
end

function display_name = get_method_display_name(method)
    % Convert method identifier to display name
    switch upper(method)
        case 'FD'
            display_name = 'Finite Difference';
        case 'SPECTRAL'
            display_name = 'Spectral';
        case 'FV'
            display_name = 'Finite Volume';
        case 'BATHYMETRY'
            display_name = 'Variable Bathymetry';
        otherwise
            display_name = method;
    end
end
