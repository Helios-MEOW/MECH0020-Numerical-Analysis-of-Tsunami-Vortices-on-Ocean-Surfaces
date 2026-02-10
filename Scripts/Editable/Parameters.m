function params = Parameters()
    % PARAMETERS - Comprehensive user-editable simulation parameters
    %
    % Purpose:
    %   Central configuration file for ALL physics, numerics, and initial conditions
    %   Supports multiple numerical methods (FD, Spectral, FV)
    %   Provides framework for easy integration of future methods
    %
    % Location: Scripts/Editable/ (user-editable directory)
    %
    % Usage:
    %   params = Parameters();
    %   params.Nx = 256;              % Override defaults as needed
    %   params.ic_type = 'Rankine';   % Change initial condition
    %   params.method = 'FD';         % Select numerical method
    %
    % See also: Settings, ic_factory, Tsunami_Vorticity_Emulator
    
    %% ====================================================================
    %  PHYSICS PARAMETERS
    %% ====================================================================
    
    % Kinematic viscosity (m²/s)
    % Typical values: 1e-6 (water), 1e-5 (oil), 0.001 (high viscosity test)
    params.nu = 0.001;
    
    % Domain size (dimensionless or meters)
    params.Lx = 2 * pi;             % Domain length in X
    params.Ly = 2 * pi;             % Domain length in Y
    
    % Bathymetry (ocean floor depth variation) - FUTURE FEATURE
    params.bathymetry_enabled = false;
    params.bathymetry_file = '';           % Path to bathymetry data
    params.bathymetry_type = 'uniform';    % 'uniform', 'slope', 'channel', 'file'
    params.bathymetry_params = [];         % Method-specific parameters
    
    %% ====================================================================
    %  GRID PARAMETERS (Method-specific)
    %% ====================================================================
    
    % --- Common Grid Parameters ---
    params.Nx = 128;                % Grid points in X direction
    params.Ny = 128;                % Grid points in Y direction
    params.delta = 2;               % Grid spacing scaling factor (legacy)
    
    % --- Finite Difference (FD) Specific ---
    params.fd_boundary_type = 'periodic';  % 'periodic', 'dirichlet', 'neumann'
    params.fd_stencil = 'central';         % 'central', 'upwind', 'compact'
    params.fd_order = 2;                   % Accuracy order: 2, 4, 6
    
    % --- Spectral Method Specific (FRAMEWORK READY) ---
    params.spectral_dealias = true;        % Anti-aliasing (2/3 rule)
    params.spectral_filter = 'none';       % 'none', 'exponential', 'gaussian'
    params.spectral_filter_order = 8;      % Filter order (if used)
    params.spectral_padding = 1.5;         % Padding factor for dealiasing
    
    % --- Finite Volume (FV) Specific (FRAMEWORK READY) ---
    params.fv_flux_scheme = 'central';     % 'central', 'upwind', 'MUSCL', 'WENO'
    params.fv_limiter = 'minmod';          % 'minmod', 'superbee', 'vanLeer'
    params.fv_reconstruction_order = 2;    % 1 (1st order), 2 (2nd order), 3 (WENO)
    
    %% ====================================================================
    %  TIME INTEGRATION PARAMETERS
    %% ====================================================================
    
    % Timestep (seconds)
    % Ensure CFL < 1 for stability: dt < dx / max_velocity
    params.dt = 0.001;
    
    % Final simulation time (seconds)
    params.Tfinal = 1.0;
    
    % Time integration scheme
    % Options: 'RK4' (default), 'RK3', 'AB3' (Adams-Bashforth), 'Euler'
    params.time_scheme = 'RK4';
    
    % Adaptive time stepping (FUTURE FEATURE)
    params.adaptive_dt = false;
    params.dt_min = 1e-6;           % Minimum timestep
    params.dt_max = 0.01;           % Maximum timestep
    params.cfl_target = 0.5;        % Target CFL number
    
    %% ====================================================================
    %  INITIAL CONDITIONS (9 Types Available)
    %% ====================================================================
    % Select ONE of the following IC types
    % Each IC type requires specific coefficients (ic_coeff)
    
    params.ic_type = 'Lamb-Oseen';  % Selected IC type
    
    % --- Initial Condition Catalog ---
    %
    % 1. 'Lamb-Oseen' - Classic viscous vortex (axisymmetric)
    %    ic_coeff: [Gamma, a]
    %      Gamma = circulation strength (default: 1.0)
    %      a = core radius (default: 0.5)
    %    Formula: omega = (Gamma/(2*pi*a^2)) * exp(-r^2/(2*a^2))
    %
    % 2. 'Rankine' - Piecewise constant vortex (solid body + potential)
    %    ic_coeff: [Gamma, a]
    %      Gamma = circulation (default: 1.0)
    %      a = core radius (default: 0.5)
    %    Formula: omega = 2*Gamma/(pi*a^2) for r <= a, 0 otherwise
    %
    % 3. 'Lamb-Dipole' - Counter-rotating vortex pair
    %    ic_coeff: [Gamma, a, separation]
    %      Gamma = circulation (default: 1.0)
    %      a = core radius (default: 0.5)
    %      separation = distance between vortices (default: 2*a)
    %
    % 4. 'Taylor-Green' - Periodic cellular flow pattern
    %    ic_coeff: [k_x, k_y]
    %      k_x = wavenumber in x (default: 1)
    %      k_y = wavenumber in y (default: 1)
    %    Formula: omega = sin(k_x*2*pi*x) * sin(k_y*2*pi*y)
    %
    % 5. 'Stretched-Gaussian' - Anisotropic Gaussian vortex
    %    ic_coeff: [x_coeff, y_coeff, angle, x0, y0]
    %      x_coeff = x-direction width (default: 2.0)
    %      y_coeff = y-direction width (default: 0.2)
    %      angle = rotation angle in degrees (default: 0)
    %      x0, y0 = center position (default: 0, 0)
    %
    % 6. 'Elliptical-Vortex' - Elliptical vortex core
    %    ic_coeff: [a, b, angle]
    %      a = semi-major axis (default: 1.5)
    %      b = semi-minor axis (default: 1.0)
    %      angle = rotation angle in degrees (default: 0)
    %
    % 7. 'Random-Turbulence' - Multi-scale turbulent field
    %    ic_coeff: [k_max, seed]
    %      k_max = maximum wavenumber (default: 4)
    %      seed = random seed for reproducibility (default: 42)
    %
    % 8. 'Gaussian' - Simple isotropic Gaussian vortex
    %    ic_coeff: [amplitude, width]
    %      amplitude = peak vorticity (default: 1.0)
    %      width = characteristic width (default: 1.0)
    %
    % 9. 'Custom' - User-defined IC (edit ic_factory.m)
    %    ic_coeff: User-specified parameters
    
    % IC coefficients for selected type (leave empty for defaults)
    params.ic_coeff = [];           % Uses defaults for selected IC type
    
    % Multiple vortex initialization (FUTURE FEATURE)
    params.multi_vortex = false;
    params.num_vortices = 1;
    params.vortex_positions = [];   % [x1 y1; x2 y2; ...]
    params.vortex_strengths = [];   % [Gamma1; Gamma2; ...]
    
    %% ====================================================================
    %  OUTPUT CONTROL - PLOTS vs ANIMATIONS
    %% ====================================================================
    % Separate control for plot snapshots and animation frames
    
    % --- Plot Snapshots (saved figures at specific times) ---
    params.num_plot_snapshots = 11;
    params.snap_times = linspace(0, params.Tfinal, params.num_plot_snapshots);
    
    % You can also specify exact snapshot times:
    % params.snap_times = [0, 0.1, 0.25, 0.5, 1.0];
    
    % --- Animation Frames (for movies/GIFs - higher temporal resolution) ---
    params.animation_enabled = false;      % Enable animation generation
    params.animation_num_frames = 100;     % Number of frames (higher = smoother)
    params.animation_fps = 30;             % Frames per second
    params.animation_format = 'gif';       % 'gif', 'mp4', 'avi'
    params.animation_quality = 90;         % Quality (1-100 for video)
    
    % Animation frames are automatically distributed over [0, Tfinal]
    % This allows: 11 plot snapshots + 100 animation frames independently
    
    %% ====================================================================
    %  PROGRESS & LIVE PREVIEW
    %% ====================================================================
    
    % Console output frequency
    params.progress_stride = 100;   % Print progress every N steps (0 = off)
    
    % Live visualization during simulation
    params.live_preview = false;    % Show updating figure during run
    params.live_stride = 50;        % Update live figure every N steps (0 = off)
    params.live_plot_type = 'contour';  % 'contour', 'surface', 'quiver'
    
    %% ====================================================================
    %  NUMERICAL METHOD SELECTION
    %% ====================================================================
    
    % Primary numerical method
    % Options: 'FD' (Finite Difference), 'Spectral', 'FV' (Finite Volume)
    params.method = 'FD';
    
    % Method-specific analysis configuration (auto-populated by framework)
    params.analysis_method = 'Finite Difference';
    params.method_config = [];      % Populated by Build_Run_Config
    
    %% ====================================================================
    %  CONVERGENCE STUDY PARAMETERS (for mode_convergence)
    %% ====================================================================
    
    params.convergence_mesh_sizes = [32, 64, 128, 256];  % Grid resolutions to test
    params.convergence_reference_size = 512;              % High-res reference solution
    params.convergence_norms = {'L2', 'Linf'};            % Error norms to compute
    
    %% ====================================================================
    %  PARAMETER SWEEP PARAMETERS (for mode_parameter_sweep)
    %% ====================================================================
    
    params.sweep_parameter = 'nu';           % Parameter to sweep
    params.sweep_values = [0.0005, 0.001, 0.002, 0.005];  % Values to test
    params.sweep_type = 'linear';            % 'linear', 'logarithmic'
    
    %% ====================================================================
    %  ADVANCED DIAGNOSTICS (FUTURE FEATURES)
    %% ====================================================================
    
    % Enstrophy and energy tracking
    params.track_enstrophy = true;
    params.track_energy = true;
    params.diagnostic_interval = 10;  % Compute diagnostics every N steps
    
    % Vortex detection and tracking
    params.vortex_detection = false;
    params.vortex_threshold = 0.1;    % Minimum vorticity for detection
    
    % Spectral analysis
    params.spectral_analysis = false;
    params.spectral_save_spectrum = false;
    
    %% ====================================================================
    %  LEGACY COMPATIBILITY
    %% ====================================================================
    
    % Ensure backward compatibility with older scripts
    params.t_final = params.Tfinal;
    params.num_snapshots = params.num_plot_snapshots;
end
