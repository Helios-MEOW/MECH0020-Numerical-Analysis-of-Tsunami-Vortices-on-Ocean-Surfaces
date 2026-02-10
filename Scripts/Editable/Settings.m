function s = Settings()
    % SETTINGS - Comprehensive user-editable operational settings
    %
    % Purpose:
    %   Central configuration file for ALL operational settings
    %   Controls IO, UI, logging, plotting, animations, and method-specific options
    %   Separate from Parameters.m (which handles physics/numerics)
    %
    % Location: Scripts/Editable/ (user-editable directory)
    %
    % Usage:
    %   settings = Settings();
    %   settings.save_figures = false;     % Override defaults as needed
    %   settings.figure_format = 'pdf';    % Change output format
    %
    % See also: Parameters, Tsunami_Vorticity_Emulator
    
    %% ====================================================================
    %  INPUT/OUTPUT SETTINGS
    %% ====================================================================
    
    % --- File Output Control ---
    s.save_figures = true;          % Save plot snapshots to disk
    s.save_data = true;             % Save simulation data (MAT files)
    s.save_animations = false;      % Save animations (GIF/MP4)
    s.save_reports = true;          % Generate text/HTML run reports
    s.save_diagnostics = true;      % Save diagnostic data (energy, enstrophy)
    
    % --- Output Directories ---
    s.output_base = 'Data/Results'; % Base output directory
    s.use_run_id_subdirs = true;    % Create unique subdirectory per run
    s.organize_by_method = true;    % Organize outputs by numerical method
    
    % --- Data Format Options ---
    s.data_format = 'mat';          % 'mat', 'hdf5', 'both'
    s.data_compression = true;      % Compress saved data files
    s.data_precision = 'double';    % 'single', 'double'
    
    %% ====================================================================
    %  FIGURE SETTINGS (Static Plots)
    %% ====================================================================
    
    % --- Figure Format ---
    s.figure_format = 'png';        % 'png', 'pdf', 'eps', 'fig', 'jpg', 'svg'
    s.figure_dpi = 300;             % Resolution for raster formats (72, 150, 300, 600)
    s.figure_size = [800, 600];     % Figure size [width, height] in pixels
    s.figure_renderer = 'opengl';   % 'opengl', 'painters', 'zbuffer'
    
    % --- Figure Style ---
    s.figure_theme = 'modern';      % 'classic', 'modern', 'paper', 'presentation'
    s.colormap = 'turbo';           % 'turbo', 'parula', 'jet', 'viridis', 'plasma'
    s.font_size = 12;               % Base font size for labels/titles
    s.font_name = 'Helvetica';      % Font family
    s.line_width = 1.5;             % Default line width
    
    % --- Plot Types to Generate ---
    s.plot_contours = true;         % Contour plots of vorticity
    s.plot_surface = false;         % 3D surface plots
    s.plot_quiver = true;           % Velocity vector fields
    s.plot_streamlines = false;     % Streamline plots
    s.plot_diagnostics = true;      % Energy/enstrophy evolution
    
    %% ====================================================================
    %  ANIMATION SETTINGS (Movies/GIFs)
    %% ====================================================================
    
    % --- Animation Control (separate from plot snapshots) ---
    s.animation_enabled = false;    % Enable animation generation
    s.animation_format = 'gif';     % 'gif', 'mp4', 'avi', 'mov'
    s.animation_fps = 30;           % Frames per second (10, 30, 60)
    s.animation_quality = 90;       % Quality setting (1-100 for video)
    s.animation_loop = true;        % Loop GIF animations
    s.animation_loop_count = 0;     % 0 = infinite, N = loop N times
    
    % --- Animation Rendering ---
    s.animation_downsample = 1;     % Spatial downsampling factor (1 = full res)
    s.animation_compression = 'high';  % 'none', 'low', 'medium', 'high'
    s.animation_colorbar = true;    % Include colorbar in animation frames
    
    %% ====================================================================
    %  MONITOR/UI SETTINGS
    %% ====================================================================
    
    % --- Live Monitoring ---
    s.monitor_enabled = true;       % Enable live progress monitor
    s.monitor_theme = 'dark';       % 'dark', 'light', 'auto'
    s.monitor_position = 'right';   % 'left', 'right', 'top', 'bottom'
    s.monitor_update_interval = 1.0; % Update interval in seconds
    
    % --- UI Components ---
    s.ui_mode = 'standard';         % 'standard', 'minimal', 'expert'
    s.terminal_capture = true;      % Capture terminal output in UI
    s.show_warnings = true;         % Display warning messages
    s.interactive_plots = false;    % Enable interactive plot tools
    
    %% ====================================================================
    %  LOGGING SETTINGS
    %% ====================================================================
    
    % --- Log Level Control ---
    s.log_level = 'INFO';           % 'DEBUG', 'INFO', 'WARN', 'ERROR', 'CRITICAL'
    s.log_to_file = true;           % Save log to file
    s.log_to_console = true;        % Print log to console
    s.log_file_name = 'simulation.log';  % Log file name
    
    % --- Master Table ---
    s.append_to_master = true;      % Append run to master_runs.csv
    s.master_table_format = 'csv';  % 'csv', 'excel', 'json'
    
    % --- Error Handling ---
    s.verbose_errors = true;        % Show detailed error messages
    s.halt_on_warning = false;      % Stop simulation on warnings
    s.save_on_error = true;         % Save partial results if simulation fails
    
    %% ====================================================================
    %  METHOD-SPECIFIC SETTINGS
    %% ====================================================================
    
    % --- Finite Difference Settings ---
    s.fd_matrix_free = true;        % Use matrix-free operators (faster for large grids)
    s.fd_precompute_operators = false;  % Precompute differential operators
    s.fd_parallel = false;          % Use parallel computing (requires Parallel Toolbox)
    
    % --- Spectral Method Settings (FRAMEWORK READY) ---
    s.spectral_fft_plan = 'fftw';   % 'fftw', 'builtin'
    s.spectral_optimize_fft = true; % Optimize FFT planning
    s.spectral_save_modes = false;  % Save Fourier modes
    
    % --- Finite Volume Settings (FRAMEWORK READY) ---
    s.fv_flux_cache = true;         % Cache flux computations
    s.fv_adaptive_limiter = false;  % Adaptive slope limiting
    
    %% ====================================================================
    %  PERFORMANCE SETTINGS
    %% ====================================================================
    
    % --- Computational Efficiency ---
    s.use_gpu = false;              % Use GPU acceleration (requires Parallel Toolbox)
    s.num_threads = 0;              % Number of CPU threads (0 = auto)
    s.memory_efficient = false;     % Trade speed for memory savings
    
    % --- Profiling and Benchmarking ---
    s.enable_profiling = false;     % Enable MATLAB profiler
    s.save_timing_data = true;      % Save timing breakdown
    s.benchmark_mode = false;       % Run in benchmark mode (minimal output)
    
    %% ====================================================================
    %  CONVERGENCE STUDY SETTINGS (for mode_convergence)
    %% ====================================================================
    
    s.convergence_plot_errors = true;       % Plot error vs mesh size
    s.convergence_compute_rates = true;     % Compute convergence rates
    s.convergence_save_all_solutions = false;  % Save solutions at all resolutions
    s.convergence_reference_method = 'extrapolation';  % 'extrapolation', 'analytical'
    
    %% ====================================================================
    %  PARAMETER SWEEP SETTINGS (for mode_parameter_sweep)
    %% ====================================================================
    
    s.sweep_parallel = false;       % Run sweep cases in parallel
    s.sweep_plot_comparison = true; % Generate comparison plots
    s.sweep_save_individual = true; % Save individual run data
    s.sweep_summary_table = true;   % Generate summary table
    
    %% ====================================================================
    %  PLOTTING MODE SETTINGS (for mode_plotting)
    %% ====================================================================
    
    s.plotting_regenerate = false;  % Regenerate plots from saved data
    s.plotting_custom_times = [];   % Custom snapshot times to plot
    s.plotting_grid_layout = 'auto'; % 'auto', 'single', 'grid', 'tiled'
    s.plotting_comparison_mode = false;  % Compare multiple runs
    
    %% ====================================================================
    %  SUSTAINABILITY/ENERGY MONITORING (ADVANCED FEATURES)
    %% ====================================================================
    
    s.energy_monitoring = false;    % Monitor computational energy usage
    s.carbon_tracking = false;      % Estimate carbon footprint
    s.power_profiling = false;      % Profile power consumption
    
    %% ====================================================================
    %  VALIDATION AND TESTING
    %% ====================================================================
    
    s.validation_mode = false;      % Run in validation mode
    s.test_suite = 'none';          % 'none', 'basic', 'comprehensive'
    s.check_conservation = true;    % Verify conservation properties
    s.assert_stability = false;     % Halt if simulation becomes unstable
    
    %% ====================================================================
    %  EXPERIMENTAL/FUTURE FEATURES
    %% ====================================================================
    
    % These settings prepare the framework for upcoming features
    
    % --- Adaptive Mesh Refinement (AMR) ---
    s.amr_enabled = false;
    s.amr_refinement_threshold = 0.1;
    s.amr_max_level = 3;
    
    % --- Multi-Physics Coupling ---
    s.coupled_temperature = false;   % Couple with temperature field
    s.coupled_salinity = false;      % Couple with salinity field
    
    % --- Machine Learning Integration ---
    s.ml_acceleration = false;       % Use ML-based surrogate models
    s.ml_model_path = '';
    
    % --- Cloud/Remote Execution ---
    s.remote_execution = false;
    s.remote_server = '';
    s.remote_sync = false;
end
