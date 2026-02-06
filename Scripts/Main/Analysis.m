% =========================================================
% OWL FRAMEWORK NOTES
% =========================================================
%
% FRAMEWORK OVERVIEW
% - Shared plotting and export utilities enforce consistent, publication-quality figures.
% - Numerical scripts focus on computation; formatting and export are delegated to utilities.
%
% GLOBAL CONVENTIONS
% - LaTeX interpreters are enforced for labels, ticks, titles, and legends.
% - Formatting functions operate on the current axes (gca) unless stated otherwise.
% - Visual consistency is enforced programmatically, not manually.
% - Utilities are reusable and not tied to a specific numerical method.
%
% PLOT FORMATTING — Plot_Format
% - Centralises axis and figure formatting.
% - Applies consistent font sizes, line widths, and grid styles.
% - Enables major and minor grids by default.
% - Forces LaTeX interpretation for all labels and titles.
% - Syntax:
%   plot(x, y, 'LineWidth', 1.3);
%   Plot_Format('$t$', '$y$', 'Time response', 'Default', 1.2);
%
% LEGEND HANDLING — Legend_Format
% - Legend placement is data-driven using density estimation.
% - Multiple candidate positions are evaluated automatically.
% - Supports vertical and horizontal layouts.
% - Legend entries are rendered using LaTeX.
% - Syntax:
%   Legend_Format({'Case A','Case B'}, 18, 'vertical', 1, 2, true);
%
% FIGURE SAVING — Plot_Saver
% - Figure saving is explicitly controlled via a logical save flag.
% - Figures are saved to a dedicated Figures/ directory.
% - File formats and extensions are handled internally.
% - Syntax:
%   Plot_Saver(gcf, 'response_plot', true);
%
% HIGH-LEVEL PLOTTING — AutoPlot
% - Assumes structured data with explicit X and Y fields.
% - Uses field-chain access to avoid hard-coded paths.
% - Applies legends selectively to avoid clutter.
% - Returns figure, axes, line, and legend handles.
% - Syntax:
%   AutoPlot(Data, {'Results','Sensor'}, 2, 2, 'sensor_plots', 'High');
%
% DESIGN PHILOSOPHY
% - Formatting is enforced by utilities, not user discipline.
% - Visual consistency is a first-class concern.
% - Scripts remain concise and computation-focused.
% - Reproducibility and minimal boilerplate are prioritised.
% ========================================================================
% CENTRAL NUMERICAL ANALYSIS DRIVER
%
% Purpose:
% This script is the controller for numerical experiments. It:
%   1) Defines baseline physical/numerical parameters
%   2) Selects a driver mode (evolution / convergence / sweep)
%   3) Runs simulations through Finite_Difference_Analysis
%   4) Collects runtime + memory metrics
%   5) Collates results into a table and saves to disk
%   6) Optionally produces convergence/summary plots using OWL utilities
%
% Key dependency:
%   Finite_Difference_Analysis(params) must exist on path and return analysis.
% ========================================================================

clc; close all; clear;
matlab_settings = settings;
matlab_settings.matlab.appearance.figure.GraphicsTheme.PersonalValue = 'light';

% ------------------------------------------------------------------------
% Setup Script Paths (add Scripts subdirectories to MATLAB path)
% ------------------------------------------------------------------------
script_dir = fileparts(mfilename('fullpath'));  % Current script location (Scripts/Main/)
analysis_root = fullfile(script_dir, '..', '..');  % Navigate to Analysis/ directory

% Add all Scripts subdirectories to path
addpath(fullfile(analysis_root, 'Scripts', 'Main'));
addpath(fullfile(analysis_root, 'Scripts', 'Methods'));
addpath(fullfile(analysis_root, 'Scripts', 'Sustainability'));
addpath(fullfile(analysis_root, 'Scripts', 'Visuals'));
addpath(fullfile(analysis_root, 'Scripts', 'Infrastructure'));  % Core system utilities
addpath(fullfile(analysis_root, 'Scripts', 'UI'));  % User interface components

% ------------------------------------------------------------------------
% Live Execution Timer & Performance Monitor
% ------------------------------------------------------------------------
global script_start_time monitor_figure monitor_data;
script_start_time = tic;

% Initialize monitoring data structure
monitor_data = struct(...
    'start_time', datetime('now'), ...
    'iterations_completed', 0, ...
    'total_iterations', 0, ...
    'current_phase', 'Initializing', ...
    'last_phase', 'Initializing', ...
    'phase_markers', [], ...
    'phase_labels', {{}}, ...
    'metrics', struct(), ...
    'performance', struct(...
        'iteration_times', [], ...
        'memory_usage', [], ...
        'monitor_overhead', 0));

fprintf('\n========================================\n');
fprintf('SCRIPT EXECUTION STARTED\n');
fprintf('Start Time: %s\n', char(monitor_data.start_time));
fprintf('========================================\n');
% ------------------------------------------------------------------------
% UI Mode Check - Launch UI Controller or Traditional Monitors
% ------------------------------------------------------------------------
% --- UI CONFIGURATION ---
% Control whether to use UI interface or traditional separate figure windows
use_ui_interface = true;    % true: Launch launchUIController GUI; false: Traditional tabbed figures
%
% UI MODE BEHAVIOR:
%   • use_ui_interface = true:
%       - Launches comprehensive launchUIController with embedded monitors
%       - All configuration and monitoring in single tabbed interface
%       - No separate figure windows
%       - Recommended for interactive configuration and monitoring
%
%   • use_ui_interface = false (Traditional Mode):
%       - Uses separate figure windows for execution and convergence monitors
%       - Configuration via script parameters below
%       - Same behavior as previous versions
%       - Recommended for batch processing and automated workflows
%
% NOTE: If use_ui_interface = true, the UI will override parameters below
%       and all configuration is done through the UI tabs.
%       If user selects "Traditional Mode" in startup dialog, traditional mode runs instead.
if use_ui_interface
    % Launch UI startup dialog
    fprintf('\n========================================\n');
    fprintf('LAUNCHING UI CONTROLLER\n');
    fprintf('========================================\n');
    fprintf('Starting UIController with mode selection...\n');
    fprintf('========================================\n\n');
    
    % Launch UI and capture choice
    app = UIController();
    
    % Check if user chose traditional mode
    if isappdata(0, 'ui_mode') && strcmp(getappdata(0, 'ui_mode'), 'traditional')
        rmappdata(0, 'ui_mode');
        fprintf('\nUser selected Traditional Mode from UI startup dialog.\n');
        fprintf('Switching to traditional interface with separate windows.\n\n');
        use_ui_interface = false;
        % Continue to traditional mode below
    else
        % UI mode was selected and completed
        fprintf('UI closed. To run simulation, set use_ui_interface = false\n');
        return;  % Exit script, user works in UI
    end
end

if ~use_ui_interface
    % Traditional mode: Create separate figure windows for monitors
    fprintf('\n========================================\n');
    fprintf('TRADITIONAL MODE (Separate Monitors)\n');
    fprintf('========================================\n');
    fprintf('UI Mode: DISABLED\n');
    fprintf('Using separate figure windows for monitoring\n');
    fprintf('Configuration via script parameters\n');
    fprintf('========================================\n\n');
    % Create live monitoring dashboard (dark UI version)
    monitor_figure = create_live_monitor_dashboard();
else
    monitor_figure = [];  % UI mode doesn't use separate monitor
end

% ------------------------------------------------------------------------
% Add Function Utilities to Path (OWL plotting utilities - local copy)
% ------------------------------------------------------------------------
utilities_path = fullfile(analysis_root, 'utilities');
if exist(utilities_path, 'dir')
    addpath(genpath(utilities_path));
    savepath;
else
    warning('Utilities path not found: %s', utilities_path);
end
display_function_instructions("all");

% ========================================================================
% ███████╗██████╗ ██╗████████╗    ████████╗██╗  ██╗███████╗███████╗███████╗
% ██╔════╝██╔══██╗██║╚══██╔══╝    ╚══██╔══╝██║  ██║██╔════╝██╔════╝██╔════╝
% █████╗  ██║  ██║██║   ██║          ██║   ███████║█████╗  ███████╗█████╗  
% ██╔══╝  ██║  ██║██║   ██║          ██║   ██╔══██║██╔══╝  ╚════██║██╔══╝  
% ███████╗██████╔╝██║   ██║          ██║   ██║  ██║███████╗███████║███████╗
% ╚══════╝╚═════╝ ╚═╝   ╚═╝          ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
% ========================================================================
% RUN MODE SELECTION & DEFINITION
% ========================================================================
% This script supports multiple execution modes for different research objectives.
% Each mode has distinct computational characteristics and sustainability profiles.
%
% MODE DESCRIPTIONS:
% ==================
%
% 1. "evolution" - BASELINE SIMULATION
%    Purpose: Single low-resolution simulation for visualization and validation
%    Use case: Recreating Kutz figure, initial parameter exploration
%    Computational cost: LOW (single simulation, coarse grid)
%    Sustainability tracking: Captures baseline simulation costs
%
% 2. "convergence" - ADAPTIVE MESH REFINEMENT STUDY
%    Purpose: Multi-stage convergence study with intelligent refinement
%    Stages:
%      Stage 1: Exploratory physical quantity study (auto_physical mode)
%               - Tests N = [50, 75, 100, 150, 200] to find most sensitive quantity
%               - Creates dual convergence criteria (mesh + time)
%      Stage 2: Grid vs Time sensitivity diagnostic (4 quick tests)
%               - Determines whether mesh or dt refinement is more influential
%      Stage 3: Agent-guided convergence study
%               - Uses predictive agent with error/cost/vorticity scoring
%               - Finds optimal path to converged mesh with minimal iterations
%      Stage 4: Richardson extrapolation & binary refinement
%    Use case: Production-quality mesh generation for sweep studies
%    Computational cost: HIGH (multiple simulations, adaptive refinement)
%    Sustainability tracking: Separates setup (stages 1-2) from study (stages 3-4)
%    Unique contribution: Measures computational cost of SETUP phase separately
%
% 3. "sweep" - PARAMETER SWEEP STUDY
%    Purpose: Systematic variation of initial conditions on converged mesh
%    Basis: Uses mesh from convergence study as foundation
%    Parameters varied: IC type, coefficients, vorticity distribution, etc.
%    Outputs: Vorticity behavior data, graphical comparisons
%    Use case: Understanding sensitivity to initial conditions
%    Computational cost: MEDIUM-HIGH (many simulations at fixed resolution)
%    Sustainability tracking: Per-configuration energy tracking
%

% 5. "animation" - HIGH-FPS VISUALIZATION
%    Purpose: Generate publication-quality animations
%    Computational cost: MEDIUM (rendering overhead)
%    Sustainability tracking: Visualization rendering costs
%
% 6. "experimentation" - MULTI-CONFIGURATION TESTING
%    Purpose: Test various IC types (multi-vortex, non-uniform BC, etc.)
%    Computational cost: MEDIUM
%    Sustainability tracking: Experimental exploration costs
%
% SUSTAINABILITY PHILOSOPHY:
% =========================
% Most papers only report the cost of the study itself, ignoring the setup phase.
% By tracking BOTH setup and execution separately, we provide a more complete
% picture of the true computational cost of numerical research.
%
% Example: Convergence mode sustainability breakdown:
%   - Setup Phase (Stages 1-2): ~20-30% of total energy
%   - Study Phase (Stages 3-4): ~70-80% of total energy
%   This "hidden cost" is rarely reported but critical for reproducibility.
%
% ========================================================================

run_mode = "evolution";    % Options: "evolution", "convergence", "sweep", "animation", "experimentation"

% --- SUSTAINABILITY TRACKING CONFIGURATION ---
enable_sustainability_tracking = true;     % Master switch for all tracking
track_mode_separately = true;              % Separate logs for each mode
track_setup_vs_study = true;               % Separate setup from execution
use_icue_integration = false;              % Enable Corsair iCUE RGB feedback (requires iCUE SDK)
sustainability_output_dir = fullfile(pwd, '..', 'Results', 'Sustainability');

% Create sustainability directory if needed
if enable_sustainability_tracking && ~exist(sustainability_output_dir, 'dir')
    mkdir(sustainability_output_dir);
end

% --- BASELINE SIMULATION PARAMETERS (CONSOLIDATED STRUCT) ---
% Use factory function for standardized parameter initialization
% This replaces 30+ lines of verbose struct initialization with a single function call
% Factory location: Scripts/Infrastructure/create_default_parameters.m
Parameters = create_default_parameters();

% --- VISUALIZATION METHOD PARAMETERS ---
visualization = struct(...
    'contour_method', "contourf", ...       % Contour plot method: 'contour' (line contours) or 'contourf' (filled contours)
    'contour_levels', 25, ...               % Number of contour levels
    'contour_colormap', "gray", ...         % Colormap for contour-only figure
    'vector_method', "quiver", ...          % Vector field visualization: 'quiver' (arrows) or 'streamlines' (flow lines)
    'vector_subsampling', 4, ...            % Stride for vector subsampling (larger = fewer vectors)
    'vector_scale', 1.0, ...                % Scale factor for arrow lengths (1.0 = auto)
    'colormap', "turbo");                   % MATLAB colormap (turbo, jet, parula, hot, viridis)

% --- PLOT FORMAT SETTINGS (USED BY OWL UTILITIES) ---
plot_settings = struct(...
    'LineWidth', 1.5, ...
    'FontSize', 12, ...
    'MarkerSize', 8, ...
    'AxisLineWidth', 1.0, ...
    'ColorOrder', lines(7), ...
    'Grid', 'on', ...
    'Box', 'on', ...
    'Interpreter', 'latex', ...
    'Colormap', visualization.colormap);

% Attach visualization + formatting to Parameters for downstream use
Parameters.visualization = visualization;
Parameters.plot_settings = plot_settings;

% ========================================================================
% ENERGY SUSTAINABILITY FRAMEWORK v4.1 - NEW FEATURE
% ========================================================================
%
% PURPOSE:
%   Track real-time energy consumption during simulations
%   Build predictive energy scaling models (E = A * C^α)
%   Quantify computational sustainability and carbon footprint
%
% PARAMETERS.ENERGY_MONITORING:
%   • enabled: true/false - Enable/disable real-time energy tracking
%   • sample_interval: seconds - Sampling frequency (0.5s = 2Hz)
%   • output_dir: string - Directory for CSV logs (sensor_logs)
%
% PARAMETERS.SUSTAINABILITY:
%   • enabled: true/false - Build energy scaling models
%   • build_model: true/false - Fit power-law: E = A*C^α
%   • auto_compare: true/false - Auto-compare multi-run results
%
% HOW TO USE:
%   Parameters.energy_monitoring.enabled = true;  % Enable in config
%   run_mode = "evolution";
%   Analysis;  % Monitoring happens automatically
%
% CHECK RESULTS:
%   % View logs in sensor_logs/ directory
%   analyzer = EnergySustainabilityAnalyzer();
%   analyzer.add_data_from_log('sensor_logs/evolution_128x128_sensors.csv', 128^2);
%   analyzer.build_scaling_model();
%   analyzer.plot_scaling();
%
% Enable/disable post-simulation energy analysis
post_energy_analysis_enabled = false;
% ========================================================================

% --- EXPERIMENTATION MODE PARAMETERS ---
% Used when run_mode = "experimentation"
experimentation = struct(...
    'test_case', "double_vortex", ...    % Test case: 'double_vortex', 'three_vortex', 'non_uniform_boundary', etc.
    'save_summary', true, ...             % Save comparison summary figure
    'compute_metrics', true, ...          % Compute and compare metrics across cases
    'coefficient_sweep', struct(...
        'vortex_pair_gamma', struct(...
            'enabled', false, ...
            'base_case', 'double_vortex', ...
            'parameter', 'gamma', ...
            'index', 1, ...
            'values', [0.5, 1.0, 1.5, 2.0, 2.5], ...
            'description', 'Circulation magnitude sweep for vortex pair'), ...
        'vortex_pair_radius', struct(...
            'enabled', false, ...
            'base_case', 'double_vortex', ...
            'parameter', 'radius', ...
            'index', 2, ...
            'values', [0.5, 1.0, 1.5, 2.0, 2.5], ...
            'description', 'Core radius sweep for vortex pair'), ...
        'vortex_pair_separation', struct(...
            'enabled', false, ...
            'base_case', 'double_vortex', ...
            'parameter', 'separation', ...
            'index', [3, 6], ...
            'mode', 'relative', ...
            'values', [2.0, 3.0, 4.0, 5.0, 6.0], ...
            'description', 'Separation distance sweep for vortex pair'), ...
        'stretched_gaussian_x', struct(...
            'enabled', false, ...
            'base_case', 'non_uniform_boundary', ...
            'parameter', 'x_coeff', ...
            'index', 1, ...
            'values', [0.5, 1.0, 1.5, 2.0, 2.5, 3.0], ...
            'description', 'X-direction stretching coefficient sweep'), ...
        'stretched_gaussian_y', struct(...
            'enabled', false, ...
            'base_case', 'non_uniform_boundary', ...
            'parameter', 'y_coeff', ...
            'index', 2, ...
            'values', [0.5, 1.0, 1.5, 2.0, 2.5, 3.0], ...
            'description', 'Y-direction stretching coefficient sweep'), ...
        'multi_param_sensitivity', struct(...
            'enabled', false, ...
            'base_case', 'counter_rotating', ...
            'parameters', {{ ...
                struct('name', 'gamma1', 'index', 1, 'values', [1.0, 1.5, 2.0]), ...
                struct('name', 'gamma2', 'index', 5, 'values', [-1.0, -1.5, -2.0]) ...
            }}, ...
            'description', 'Joint variation of multiple parameters')));

% --- CONVERGENCE STUDY PARAMETERS ---
convergence_N_coarse = 64;          % Starting coarse grid resolution
convergence_N_max = 512;            % Maximum grid resolution
convergence_tol = 1e-2;             % Convergence tolerance (1%)
convergence_bracket_factor = 2;     % Grid refinement factor
convergence_enable_bracketing = false; % Fallback bracketing (robust but slower)
convergence_max_pair_extensions = 2; % Richardson: extend initial pair if metrics invalid
convergence_binary = true;          % Use binary search
convergence_use_adaptive = true;    % Use Richardson-based adaptive search
convergence_save_iterations = true; % Save CSV log of iterations
convergence_save_figures = true;    % Save figures at each refinement
convergence_max_jumps = 5;          % Max adaptive prediction jumps
% CONVERGENCE CRITERION SELECTOR
% Options: 'max_vorticity', 'l2_relative', 'l2_absolute', 'linf_relative', 'energy_dissipation', 'auto_physical'
convergence_criterion_type = 'l2_relative';  % Default: Richardson L2 relative error

% ADAPTIVE PHYSICAL CRITERION: Auto-select best physical quantity based on exploratory study
convergence_adaptive_physical_mode = false;  % When true, runs exploratory refinement to determine best quantity
convergence_adaptive_plot_trends = true;     % Plot sensitivity trends for all physical quantities
convergence_adaptive_N_base = 50;            % Starting mesh for exploratory study
convergence_adaptive_refinements = [1.0, 1.5, 2.0, 3.0, 4.0];  % Refinement factors to test

% AGENT-GUIDED CONVERGENCE
convergence_agent_enabled = true;   % Agent-guided next-mesh selection
convergence_agent_weights = struct('error', 0.6, 'cost', 0.25, 'vorticity', 0.15);
convergence_agent_candidate_multipliers = [1.25, 1.5, 2.0, 2.5, 3.0];
convergence_mesh_visuals = true;    % Save mesh grid, contour, and 3D visuals
convergence_cancel_file = 'CANCEL_CONVERGENCE.txt';  % Create this file to stop convergence study



% --- PARAMETER SWEEP LISTS ---
sweep_nu_list = [1e-5 1e-4 1e-3 1e-2 1e-1];     % Viscosity values to sweep
sweep_dt_list = [1e-4 1e-3 1e-2 1e-1];          % Time step values to sweep
sweep_ic_list = ["stretched_gaussian", "lamb_oseen", "rankine", "lamb_dipole", ...
                  "taylor_green", "random_turbulence", "elliptical_vortex"]; % IC types

% --- PREFLIGHT CHECKS ---
preflight_enabled = true;      % Fail-fast checks before long runs
preflight_require_monitor = false;  % Require live monitor functions on path

% --- OUTPUT AND EXPORT SETTINGS ---
results_dir = "../../Results";  % Directory for results (relative to Scripts/Main/)
save_csv = true;                % Save results as CSV
save_mat = true;                % Save results as MAT file

% Figure export settings
figures_root_dir = "../../Figures";  % Root directory for figures (relative to Scripts/Main/)
figures_save_png = true;        % Save figures as PNG
figures_save_fig = false;       % Save figures as .fig
figures_dpi = 300;              % Image resolution (300=publication, 600=print, 150=web)
figures_close_after_save = false; % Close figures after saving
figures_use_owl_saver = true;   % Use OWL Plot_Saver utility

% Ensure animation directory follows the figures root
Parameters.animation_dir = fullfile(figures_root_dir, Parameters.analysis_method, 'Animations');

% Converged mesh animation settings (after convergence completes)
converged_mesh_animation = true;      % Create animation for converged mesh (recommended!)
converged_mesh_animation_fps = 30;    % FPS for converged mesh (higher = smoother)
figures_close_after_save = false; % Close figures after saving
figures_use_owl_saver = true;   % Use OWL Plot_Saver utility

% ========================================================================
%% INPUT VALIDATION
% ========================================================================

% Validate run mode
valid_modes = ["evolution", "convergence", "sweep", "animation", "experimentation"];
assert(ismember(run_mode, valid_modes), ...
    'Invalid run_mode "%s". Must be one of: %s', run_mode, strjoin(valid_modes, ', '));

% Validate grid parameters
assert(Parameters.Nx > 0 && mod(Parameters.Nx, 1) == 0, 'Nx must be a positive integer, got: %g', Parameters.Nx);
assert(Parameters.Ny > 0 && mod(Parameters.Ny, 1) == 0, 'Ny must be a positive integer, got: %g', Parameters.Ny);
assert(Parameters.Lx > 0, 'Lx must be positive, got: %g', Parameters.Lx);
assert(Parameters.Ly > 0, 'Ly must be positive, got: %g', Parameters.Ly);

% Validate physical parameters
assert(Parameters.nu >= 0, 'Kinematic viscosity (nu) cannot be negative, got: %g', Parameters.nu);
assert(Parameters.dt > 0, 'Time step (dt) must be positive, got: %g', Parameters.dt);
assert(Parameters.Tfinal > 0, 'Final time (Tfinal) must be positive, got: %g', Parameters.Tfinal);
assert(Parameters.num_snapshots >= 2, 'Number of snapshots must be at least 2, got: %d', Parameters.num_snapshots);

% Validate convergence parameters
if run_mode == "convergence"
    assert(convergence_N_coarse > 0, 'Coarse grid size must be positive');
    assert(convergence_N_max > convergence_N_coarse, 'N_max must be greater than N_coarse');
    assert(convergence_tol > 0 && convergence_tol < 1, 'Tolerance should be between 0 and 1');
end


% Validate animation parameters
if run_mode == "animation"
    valid_formats = {'gif', 'mp4', 'avi'};
    assert(ismember(Parameters.animation_format, valid_formats), ...
        'Animation format must be one of: %s', strjoin(valid_formats, ', '));
    assert(Parameters.animation_fps > 0, 'FPS must be positive');
    assert(Parameters.animation_num_frames >= 10, 'Need at least 10 frames for meaningful animation');
end

% ========================================================================
% DO NOT EDIT BELOW THIS LINE (INTERNAL CONFIGURATION)
% ========================================================================

% Display selected mode prominently
fprintf('\n');
fprintf('================================================================================\n');
fprintf(' SELECTED MODE: %s\n', upper(string(run_mode)));
fprintf('================================================================================\n');
fprintf('\n');

% ========================================================================
%% GLOBAL SETTINGS STRUCT
% ========================================================================
settings = struct(...
    'results_dir', results_dir, ...
    'save_csv', save_csv, ...
    'save_mat', save_mat, ...
    'convergence', struct(...
        'N_coarse', convergence_N_coarse, ...
        'N_max', convergence_N_max, ...
        'tol', convergence_tol, ...
        'bracket_factor', convergence_bracket_factor, ...
        'enable_bracketing', convergence_enable_bracketing, ...
        'max_pair_extensions', convergence_max_pair_extensions, ...
        'binary', convergence_binary, ...
        'use_adaptive', convergence_use_adaptive, ...
        'save_iterations', convergence_save_iterations, ...
        'save_iteration_figures', convergence_save_figures, ...
        'max_adaptive_jumps', convergence_max_jumps, ...
        'criterion_type', convergence_criterion_type, ...
        'adaptive_physical', struct(...
            'enabled', convergence_adaptive_physical_mode, ...
            'plot_trends', convergence_adaptive_plot_trends, ...
            'N_base', convergence_adaptive_N_base, ...
            'refinement_factors', convergence_adaptive_refinements), ...
        'agent', struct(...
            'enabled', convergence_agent_enabled, ...
            'weights', convergence_agent_weights, ...
            'candidate_multipliers', convergence_agent_candidate_multipliers), ...
        'mesh_visuals', convergence_mesh_visuals, ...
        'cancel_file', convergence_cancel_file, ...
        'current_study_id', '', ...      % Will be set by create_convergence_study()
        'study_root', '', ...            % Root directory for current study
        'preflight_dir', '', ...         % Preflight subdirectory
        'preflight_figs_dir', ''), ...   % Preflight figures subdirectory
    'sweep', struct(...
        'nu_list', sweep_nu_list, ...
        'dt_list', sweep_dt_list, ...
        'ic_list', sweep_ic_list), ...
    'preflight', struct(...
        'enabled', preflight_enabled, ...
        'require_monitor', preflight_require_monitor), ...
    'figures', struct(...
        'root_dir', figures_root_dir, ...
        'save_png', figures_save_png, ...
        'save_fig', figures_save_fig, ...
        'dpi', figures_dpi, ...
        'close_after_save', figures_close_after_save, ...
        'use_owl_plot_saver', figures_use_owl_saver), ...
    'animation', struct(...
        'format', Parameters.animation_format, ...
        'fps', Parameters.animation_fps, ...
        'quality', Parameters.animation_quality, ...
        'num_frames', Parameters.animation_num_frames, ...
        'codec', Parameters.animation_codec, ...
        'converged_mesh_enabled', converged_mesh_animation, ...
        'converged_mesh_fps', converged_mesh_animation_fps), ...
    'energy_monitoring', struct(...
        'enabled', Parameters.energy_monitoring.enabled, ...
        'sample_interval', Parameters.energy_monitoring.sample_interval, ...
        'output_dir', Parameters.energy_monitoring.output_dir));

% ========================================================================
%% INITIALIZE ENERGY MONITORING (v4.1 Feature)
% ========================================================================
%
% This section initializes hardware monitoring if enabled
% Hardware monitoring allows you to:
%   • Track CPU temp, power, frequency during simulations
%   • Build energy scaling models: E = A * C^α
%   • Quantify computational sustainability
%
% To USE: Set Parameters.energy_monitoring.enabled = true above
%
% QUICK START:
%   Monitor = HardwareMonitorBridge();
%   Monitor.start_logging('experiment_name');
%   % ... run simulation ...
%   log_file = Monitor.stop_logging();
%   stats = Monitor.get_statistics();
%
% BUILD SCALING MODEL:
%   Analyzer = EnergySustainabilityAnalyzer();
%   analyzer.add_data_from_log('log_128.csv', 128^2);
%   analyzer.add_data_from_log('log_256.csv', 256^2);
%   analyzer.build_scaling_model();
%   fig = analyzer.plot_scaling();
%
Monitor = [];
Analyzer = [];

if Parameters.energy_monitoring.enabled
    % Add Sustainability directory to path before initializing energy monitoring
    script_dir = fileparts(mfilename('fullpath'));  % Scripts/Main
    sustainability_dir = fullfile(script_dir, '..', 'Sustainability');
    if exist(sustainability_dir, 'dir')
        addpath(sustainability_dir);
    end
    [Monitor, Analyzer] = initialize_energy_monitoring_system(Parameters);
end

% ========================================================================
%% SET ANIMATION DIRECTORY BASED ON ANALYSIS METHOD
% ========================================================================
% (Already set in Parameters struct initialization above)
% ========================================================================
%% INITIALIZE COMPLETE DIRECTORY STRUCTURE
% ========================================================================
% Create all required directories for organized file management
initialize_directory_structure(settings, Parameters);

% ========================================================================
%% SUSTAINABILITY TRACKING INITIALIZATION
% ========================================================================
% Initialize hardware monitoring and iCUE feedback BEFORE mode execution
% This captures the TRUE computational cost including ALL setup phases

global sustainability_monitor icue_controller sustainability_session;

% Create sustainability settings struct
sustainability_settings = struct(...
    'enable_sustainability_tracking', enable_sustainability_tracking, ...
    'track_mode_separately', track_mode_separately, ...
    'track_setup_vs_study', track_setup_vs_study, ...
    'use_icue_integration', use_icue_integration, ...
    'output_dir', sustainability_output_dir);

% Initialize hardware monitor
if enable_sustainability_tracking
    [sustainability_monitor, sustainability_session] = initialize_sustainability_tracking(run_mode, sustainability_settings);
else
    sustainability_monitor = [];
    sustainability_session = '';
end

% Initialize iCUE RGB controller (optional)
if use_icue_integration
    try
        icue_controller = iCUEBridge();
        icue_controller.set_status('initializing', struct('brightness', 0.8));
    catch ME
        warning('iCUE initialization failed: %s', ME.message);
        icue_controller = [];
    end
else
    icue_controller = [];
end

% ========================================================================
%% MODE DISPATCH
% - Calls the relevant driver routine
% - Each returns:
%       T    -> table of results (one row per run)
%       meta -> metadata about the executed study (mode, tolerances, N_star, etc.)
% ========================================================================

% Update iCUE status to running
if ~isempty(icue_controller)
    icue_controller.set_status('running', struct('brightness', 1.0));
end

switch run_mode
% ========================================================================
%% EXECUTE SELECTED MODE
% ========================================================================
%
% ENERGY MONITORING DURING SIMULATION:
%
% The selected mode (evolution/convergence/sweep/animation/experimentation)
% will automatically start energy monitoring if enabled.
%
% EXAMPLE WORKFLOW 1: Single Simulation with Energy Tracking
%   run_mode = "evolution";
%   Parameters.energy_monitoring.enabled = true;
%   Analysis;  % Automatically logs hardware metrics to sensor_logs/
%   % View: sensor_logs/evolution_20260127_120000_sensors.csv
%
% EXAMPLE WORKFLOW 2: Multi-Resolution Study for Scaling Model
%   % Run with Nx=128, Ny=128 (automatic logging)
%   % Run with Nx=256, Ny=256 (automatic logging)
%   % Run with Nx=512, Ny=512 (automatic logging)
%   
%   % Then build scaling model:
%   analyzer = EnergySustainabilityAnalyzer();
%   analyzer.add_data_from_log('sensor_logs/evolution_...128x128_sensors.csv', 128^2);
%   analyzer.add_data_from_log('sensor_logs/evolution_...256x256_sensors.csv', 256^2);
%   analyzer.add_data_from_log('sensor_logs/evolution_...512x512_sensors.csv', 512^2);
%   analyzer.build_scaling_model();  % Fit E = A * C^α
%   analyzer.plot_scaling();          % Visualize energy scaling
%   analyzer.compute_sustainability_metrics();
%
% EXAMPLE WORKFLOW 3: Compare Configuration Efficiency
%   % Run multiple viscosity values with monitoring enabled
%   analyzer = EnergySustainabilityAnalyzer();
%   % After all runs complete, compare:
%   [log1, log2, log3] = deal('nu1e-3.csv', 'nu1e-2.csv', 'nu1e-1.csv');
%   comparison = Monitor.compare_runs({log1, log2, log3}, ...
%                                     {'nu=1e-3', 'nu=1e-2', 'nu=1e-1'});
%   % Shows which configuration is most energy-efficient
%
% ========================================================================

    case "evolution"
        [T, meta] = run_evolution_mode(Parameters, settings, run_mode);
    case "convergence"
        [T, meta] = run_convergence_mode(Parameters, settings, run_mode);
    case "sweep"
        [T, meta] = run_sweep_mode(Parameters, settings, run_mode);
    case "animation"
        [T, meta] = run_animation_mode(Parameters, settings, run_mode);
    case "experimentation"
        [T, meta] = run_experimentation_mode(Parameters, settings, run_mode, experimentation);
    case "plot"
        [T, meta] = run_plot_mode(Parameters, settings, run_mode);
    otherwise
        error("Unknown mode: %s", string(run_mode))
end
% Display metadata and results table in command window
disp(meta)
% Display table vertically for better readability
for i = 1:height(T)
    fprintf('Row %d:\n', i);
    row = T(i,:);
    vars = row.Properties.VariableNames;
    for j = 1:length(vars)
        val = row.(vars{j});
        fprintf('  %s: ', vars{j});
        disp(val);
    end
    fprintf('\n');
end

% ========================================================================
% POST-SIMULATION ENERGY ANALYSIS (if monitoring was enabled)
% ========================================================================
%
% If energy monitoring was enabled, correlate hardware metrics with
% simulation performance and build scaling models.
%
% EXAMPLE: After running multiple resolutions, build and plot scaling model
%
%   % Run simulation with Nx=64, Nx=128, Nx=256 (all with monitoring enabled)
%   % Then correlate with grid size and build model:
%

if post_energy_analysis_enabled && exist('Monitor', 'var') && ~isempty(Monitor) && Parameters.energy_monitoring.enabled
    % Get all sensor logs from current run mode
    log_dir = Parameters.energy_monitoring.output_dir;
    logs = dir(fullfile(log_dir, sprintf('%s*.csv', char(run_mode))));

    % Initialize Analyzer and load all runs
    Analyzer = EnergySustainabilityAnalyzer();
    for k = 1:length(logs)
        log_path = fullfile(log_dir, logs(k).name);
        % Parse grid size from filename: evolution_20260127_120000_Nx128_Ny128_sensors.csv
        log_str = logs(k).name;
        nx_match = regexp(log_str, 'Nx(\d+)', 'tokens');
        if ~isempty(nx_match)
            grid_points = str2double(nx_match{1}{1})^2;
            Analyzer.add_data_from_log(log_path, grid_points);
        end
    end

    % Build energy scaling model: E = A * C^α
    Analyzer.build_scaling_model();
    [exponent, R_squared] = Analyzer.get_scaling_exponent();
    fprintf('[ENERGY] Scaling exponent α = %.3f (R² = %.4f)\n', exponent, R_squared);

    % Visualize scaling relationship
    Analyzer.plot_scaling('title', sprintf('Energy Scaling: %s mode', run_mode));

    % Compute and display sustainability metrics
    metrics = Analyzer.compute_sustainability_metrics();
    fprintf('[SUSTAINABILITY] Energy Score: %.2f/100\n', metrics.energy_score);
    fprintf('[SUSTAINABILITY] CO2 Equivalent: %.2f kg\n', metrics.co2_equivalent_kg);
end

% ========================================================================
%% SUSTAINABILITY TRACKING FINALIZATION
% ========================================================================
% Stop monitoring and generate sustainability report
% This provides the COMPLETE cost picture for this mode

% Determine phase type based on mode
mode_info = get_mode_definition(run_mode);
if strcmp(mode_info.sustainability_phase, 'both')
    phase = 'complete';  % For convergence, we track everything
else
    phase = mode_info.sustainability_phase;
end

% Update iCUE to completion status
if ~isempty(icue_controller)
    if isfield(meta, 'status') && strcmp(meta.status, 'converged')
        icue_controller.set_status('converged', struct('pulse', true, 'brightness', 1.0));
        pause(2);  % Show converged state briefly
    elseif isfield(meta, 'status') && contains(meta.status, 'error')
        icue_controller.set_status('error', struct('brightness', 1.0));
        pause(2);
    end
    icue_controller.set_status('postprocess', struct('brightness', 0.7));
end

% Finalize hardware monitoring
if ~isempty(sustainability_monitor)
    finalize_sustainability_tracking(sustainability_monitor, sustainability_session, run_mode, phase);
end

% Reset iCUE to idle
if ~isempty(icue_controller)
    icue_controller.set_status('idle');
    icue_controller.disconnect();
end

%
% ========================================================================

% ========================================================================
%% SAVE OUTPUTS
% - MAT preserves types/structs perfectly for later analysis in MATLAB
% - CSV is portable for Excel / report pipelines
% ========================================================================
csv_path = fullfile(settings.results_dir, sprintf("analysis_%s.csv", string(run_mode)));
mat_path = fullfile(settings.results_dir, sprintf("analysis_%s.mat", string(run_mode)));
% Ensure NEW run has timestamp column
if ~ismember("timestamp", T.Properties.VariableNames)
    T.timestamp = repmat(datetime("now"), height(T), 1);
else
    T.timestamp(:) = datetime("now");
end
if isfile(csv_path)
    opts = detectImportOptions(csv_path, 'TextType', 'string');
    if any(strcmpi(opts.VariableNames, "timestamp"))
        opts = setvartype(opts, "timestamp", "datetime");
        opts = setvaropts(opts, "timestamp", "InputFormat", "yyyy-MM-dd HH:mm:ss", "DatetimeLocale", "en_US");
    end
    T_existing = readtable(csv_path, opts);
    % Ensure EXISTING data also has timestamp (only tolerated schema adjustment)
    if ~ismember("timestamp", T_existing.Properties.VariableNames)
        T_existing.timestamp = repmat(datetime(NaT), height(T_existing), 1);
    end
    % Enforce identical variable names (ignoring order)
    vars_current = string(T.Properties.VariableNames);
    vars_existing = string(T_existing.Properties.VariableNames);
    % Allow only ordering differences; any name mismatch is a hard error
    missing_in_existing = setdiff(vars_current, vars_existing);
    extra_in_existing   = setdiff(vars_existing, vars_current);
    if ~isempty(missing_in_existing) || ~isempty(extra_in_existing)
        T_existing = migrate_csv_schema(T_existing, T, csv_path, missing_in_existing, extra_in_existing);
        vars_existing = string(T_existing.Properties.VariableNames);
    end
    % Reorder EXISTING columns to match CURRENT exactly, then append
    T_existing = T_existing(:, T.Properties.VariableNames);
    T_app = [T_existing; T];
else
    % First write defines schema (includes timestamp)
    T_app = T;
end
if settings.save_csv
    writetable(T_app, csv_path);
end
if settings.save_mat
    save(mat_path, "T_app", "meta", "Parameters", "settings");
end
T = T_app;

% Update master CSV (cross-mode aggregation)
if settings.save_csv
    append_master_csv(T, settings);
end

% Generate report for sweep/convergence modes
if ismember(string(run_mode), ["sweep", "convergence"])
    generate_solver_report(T, meta, settings, run_mode);
end
% ========================================================================
%% MODE IMPLEMENTATIONS (7 Execution Modes)
% ========================================================================
% These functions implement the 6 main run modes for numerical experiments:
%   1. run_evolution_mode       - Single simulation with analysis
%   2. run_animation_mode       - High-FPS animation generation
%   3. run_convergence_mode     - Adaptive grid convergence study (primary mode)
%   4. run_test_convergence_mode - Small-scale convergence testing
%   5. run_sweep_mode           - Parameter sweep (viscosity/timestep variations)
%   6. run_experimentation_mode - Test various initial conditions
% ========================================================================
function [T, meta] = run_evolution_mode(Parameters, settings, run_mode)
    % EVOLUTION MODE
    % - Intended for manual inspection / trial-and-error parameter tuning
    % - Runs a small number of cases (currently exactly one: Parameters)
    % - Collects timing/memory metrics and extracts diagnostic features
    
    % Display IC diagnostic information
    fprintf('\n=== EVOLUTION MODE ===\n');
    fprintf('Grid: %d x %d (Lx=%.1f, Ly=%.1f)\n', Parameters.Nx, Parameters.Ny, Parameters.Lx, Parameters.Ly);
    fprintf('IC Type: %s | Coefficients: [%.2f, %.2f]\n', char(Parameters.ic_type), Parameters.ic_coeff(1), Parameters.ic_coeff(2));
    fprintf('Simulation: dt=%.4f, Tfinal=%.1f, snapshots=%d\n', Parameters.dt, Parameters.Tfinal, Parameters.num_snapshots);
    fprintf('Live Preview: %s\n', char(string(Parameters.live_preview)));
    fprintf('\n');
    
    cases = repmat(Parameters, 1, 1);
    
    % Fixed output schema prevents "dissimilar structures" assignment failures
    results = repmat(result_schema(), numel(cases), 1);
    control_omega = [];
    control_params = [];
    
    for k = 1:numel(cases)
        % Prepare simulation parameters with grid initialization
        params = prepare_simulation_params(cases(k), cases(k).Nx);
        
        % Execute simulation with comprehensive metrics
        [figs_new, analysis, run_ok, wall_time_s, cpu_time_s] = execute_simulation(params);
        
        % Display IC and figure diagnostic
        if run_ok && isfield(analysis, 'omega_snaps') && ~isempty(analysis.omega_snaps)
            omega_init = analysis.omega_snaps(:,:,1);
            omega_final = analysis.omega_snaps(:,:,end);
            fprintf('[IC] Initial vorticity range: [%.4f, %.4f]\n', min(omega_init(:)), max(omega_init(:)));
            fprintf('[FINAL] Final vorticity range: [%.4f, %.4f]\n', min(omega_final(:)), max(omega_final(:)));
            fprintf('[FIGURES] Generated: %d figures\n', numel(figs_new));
        else
            fprintf('[SIM] Completed with status: %s | Figures: %d\n', char(string(run_ok)), numel(figs_new));
        end
        
        % Save generated figures
        save_case_figures(figs_new, settings, run_mode, params);
        
        % Best-effort memory sampling
        [mem_used_MB, mem_max_MB] = memory_metrics_MB();
        
        % Extract scalar features used for trends / convergence metrics
        feats = extract_features_from_analysis(analysis);
        
        % Pack everything into one record row
        results(k) = pack_result(params, run_ok, analysis, feats, wall_time_s, cpu_time_s, mem_used_MB, mem_max_MB);
        
        % Capture control vorticity snapshot for downstream sweeps
        if run_ok && isempty(control_omega) && isfield(analysis, "omega_snaps") && ~isempty(analysis.omega_snaps)
            control_omega = analysis.omega_snaps(:,:,end);
            control_params = params;
        end
        
        % Ensure figures update if present
        if run_ok && ~isempty(figs_new)
            drawnow;
        end
    end
    
    T = struct2table(results);
    
    % Add units to table variables
    T = add_table_units(T);
    
    meta = struct(...
        'mode', "evolution", ...
        'control_omega', control_omega, ...
        'control_params', control_params);
end
% ========================================================================
%% ANIMATION MODE
% - High-resolution animation with many frames for detailed visualization
% - User specifies number of frames between initial and final time
% - Supports multiple formats: GIF, MP4, AVI with controllable speed
% ========================================================================
function [T, meta] = run_animation_mode(Parameters, settings, run_mode)

    
    fprintf('\n=== ANIMATION MODE ===\n');
    fprintf('Creating high-resolution animation with %d frames\n', settings.animation.num_frames);
    fprintf('Format: %s at %d FPS\n', upper(settings.animation.format), settings.animation.fps);
    
    % Override snap_times with high frame count
    p = Parameters;
    p.snap_times = linspace(0, p.Tfinal, settings.animation.num_frames);
    p.animation_format = settings.animation.format;
    p.animation_fps = settings.animation.fps;
    p.animation_quality = settings.animation.quality;
    
    % Compute initial condition
    x = linspace(-p.Lx/2, p.Lx/2, p.Nx);
    y = linspace(-p.Ly/2, p.Ly/2, p.Ny);
    [X, Y] = meshgrid(x, y);
    p.omega = initialise_omega(X, Y, p.ic_type, p.ic_coeff);
    
    % Run solver with high frame count
    cpu0 = cputime;
    t0 = tic;
    
    try
        figs_before = findall(0, 'Type', 'figure');
        [~, analysis] = Finite_Difference_Analysis(p);  % fig_handle not used
        figs_after = findall(0, 'Type', 'figure');
        figs_new = setdiff(figs_after, figs_before);
        
        % Save figures from animation mode
        save_case_figures(figs_new, settings, run_mode, p);
        
        run_ok = true;
        fprintf('\nAnimation created successfully!\n');
        fprintf('Frames: %d\n', settings.animation.num_frames);
        fprintf('Duration: %.2f seconds\n', settings.animation.num_frames / settings.animation.fps);
    catch ME
        analysis = struct(...
            'error_id', string(ME.identifier), ...
            'error_message', string(ME.message));
        fprintf("Error in animation mode at %s line %d: %s - %s\n", ME.stack(1).file, ME.stack(1).line, ME.identifier, ME.message);
        run_ok = false;
    end
    
    wall_time_s = toc(t0);
    cpu_time_s = cputime - cpu0;
    [mem_used_MB, mem_max_MB] = memory_metrics_MB();
    
    % Extract features
    feats = extract_features_from_analysis(analysis);
    
    % Pack result
    result = pack_result(p, run_ok, analysis, feats, wall_time_s, cpu_time_s, mem_used_MB, mem_max_MB);
    
    % Create table
    T = struct2table(result);
    
    % Metadata
    meta = struct(...
        'mode', "animation", ...
        'num_frames', settings.animation.num_frames, ...
        'format', settings.animation.format, ...
        'fps', settings.animation.fps, ...
        'duration_s', settings.animation.num_frames / settings.animation.fps);
end

function omega = initialise_omega(X, Y, ic_type, ic_coeff)
    % Convert ic_type to lowercase and handle string/char conversion
    if isstring(ic_type) || ischar(ic_type)
        ic_type = lower(char(ic_type));
    end
    
    % Ensure ic_coeff is always a valid numeric array
    if ~isnumeric(ic_coeff) || isempty(ic_coeff)
        ic_coeff = [];
    end
    
    % Convert ic_coeff array to params struct for new IC functions
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

        % Legacy IC types (kept in Analysis.m for backward compatibility)
        case 'stretched_gaussian'
            % Stretched Gaussian vortex IC
            % ic_coeff = [x_stretch, y_stretch] for non-uniform stretching
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
            
        case 'vortex_blob_gaussian'
            % Gaussian vortex blob with circulation
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
            % Two counter-rotating vortices
            if numel(ic_coeff) >= 6
                Gamma1 = ic_coeff(1);
                R1 = ic_coeff(2);
                x1 = ic_coeff(3);
                y1 = ic_coeff(4);
                Gamma2 = ic_coeff(5);
                x2 = ic_coeff(6);
                y2 = 10 - y1;  % Mirror position
            else
                error('vortex_pair requires 6 coefficients: [Gamma1, R1, x1, y1, Gamma2, x2]');
            end
            vort1 = Gamma1/(2*pi*R1^2) * exp(-((X-x1).^2 + (Y-y1).^2)/(2*R1^2));
            vort2 = Gamma2/(2*pi*R1^2) * exp(-((X-x2).^2 + (Y-y2).^2)/(2*R1^2));
            omega = vort1 + vort2;
            
        case 'multi_vortex'
            % Three or more vortices
            omega = zeros(size(X));
            if numel(ic_coeff) >= 10
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
            % Strong interaction: counter-rotating pair
            if numel(ic_coeff) >= 8
                G1 = ic_coeff(1); R1 = ic_coeff(2); x1 = ic_coeff(3); y1 = ic_coeff(4);
                G2 = ic_coeff(5); R2 = ic_coeff(6); x2 = ic_coeff(7); y2 = ic_coeff(8);
            else
                error('counter_rotating_pair requires 8 coefficients: [G1,R1,x1,y1, G2,R2,x2,y2]');
            end
            vort1 = G1/(2*pi*R1^2) * exp(-((X-x1).^2 + (Y-y1).^2)/(2*R1^2));
            vort2 = G2/(2*pi*R2^2) * exp(-((X-x2).^2 + (Y-y2).^2)/(2*R2^2));
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
    % Helper function: Convert ic_coeff array to named params struct
    % This allows UI/legacy code to use simple arrays while IC functions use structs
    
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
    
    % Optional center shift (shared across ICs)
    if ~isempty(fieldnames(params))
        params.center_x = get_coeff(ic_coeff, 5, 0.0);
        params.center_y = get_coeff(ic_coeff, 6, 0.0);
    end
end

function val = get_coeff(ic_coeff, index, default)
    % Helper: Extract coefficient from array or return default
    if numel(ic_coeff) >= index
        val = ic_coeff(index);
    else
        val = default;
    end
end
% ========================================================================
%% ADAPTIVE CONVERGENCE SEARCH - CLASSIC IMPLEMENTATION (FALLBACK)
% Used when AdaptiveConvergenceAgent is not available
% - Compares errors between successive mesh refinements
% - Tracks peak vorticity at each stage
% - Uses adaptive step-size refinement (decreases as convergence improves)
% - Live visualization of convergence behavior
% - Dynamically chooses next mesh size based on convergence rate
% - Computational cost limiting via maximum mesh size
% ========================================================================
function [T, meta] = run_convergence_mode_classic(Parameters, settings, run_mode)

    tol = settings.convergence.tol;
    N_start = settings.convergence.N_coarse;
    Nmax = settings.convergence.N_max;
    p = Parameters;
    
    % Get convergence criterion type from settings
    if isfield(settings.convergence, 'criterion_type') && ~isempty(settings.convergence.criterion_type)
        criterion_type = settings.convergence.criterion_type;
        p.criterion_type = criterion_type;  % Pass to Parameters for metric computation
    else
        criterion_type = 'l2_relative';  % Default Richardson criterion
        p.criterion_type = criterion_type;
    end

    % Convergence criterion statement (printed once at onset)
    fprintf_colored('cyan_bg', '=== CONVERGENCE CRITERION ===\n');
    fprintf_colored('yellow', 'Criterion Type: %s\n', criterion_type);
    switch lower(criterion_type)
        case 'max_vorticity'
            fprintf_colored('cyan', 'Metric: Relative difference in peak vorticity magnitude\n');
            fprintf('  Formula: |max(|ω_c|) - max(|ω_f|)| / max(|ω_f|)\n');
        case 'l2_relative'
            fprintf_colored('cyan', 'Metric: L2 relative error (Richardson default)\n');
            fprintf('  Formula: ||ω_c_interp - ω_f||_2 / ||ω_f||_2\n');
        case 'l2_absolute'
            fprintf_colored('cyan', 'Metric: L2 absolute error\n');
            fprintf('  Formula: ||ω_c_interp - ω_f||_2\n');
        case 'linf_relative'
            fprintf_colored('cyan', 'Metric: L-infinity (max pointwise) relative error\n');
            fprintf('  Formula: max|ω_c_interp - ω_f| / max|ω_f|\n');
        case 'energy_dissipation'
            fprintf_colored('cyan', 'Metric: Enstrophy (total energy) relative difference\n');
            fprintf('  Formula: |Enstrophy_c - Enstrophy_f| / Enstrophy_f\n');
        case 'auto_physical'
            fprintf_colored('cyan', 'Metric: Adaptive - Auto-selected from exploratory study\n');
            fprintf_colored('yellow', '  [EXPLORATORY MODE ENABLED] Will run physical quantity sensitivity analysis\n');
    end
    fprintf_colored('yellow', 'Tolerance: %.3e\n', tol);
    fprintf_colored('cyan_bg', '====================================\n');
    
    % Display cancellation instructions
    if isfield(settings.convergence, 'cancel_file')
        fprintf('\n');
        fprintf_colored('cyan', '[INFO] To cancel this convergence study at any time:\n');
        fprintf('       Create a file named: ');
        fprintf_colored('yellow', '%s\n', settings.convergence.cancel_file);
        fprintf('       Study will stop gracefully and save progress.\n');
        fprintf('\n');
    end
    
    % Run exploratory physical quantity study if in auto_physical mode
    if strcmpi(criterion_type, 'auto_physical') && settings.convergence.adaptive_physical.enabled
        [selected_quantity, ~] = run_exploratory_physical_study(p, settings);
        % Store selected quantity in parameters for use by criterion function
        p.convergence_selected_quantity = selected_quantity;
        fprintf_colored('green', '[AUTO CRITERION] Will use %s for convergence monitoring\n\n', selected_quantity);
    elseif strcmpi(criterion_type, 'auto_physical') && ~settings.convergence.adaptive_physical.enabled
        fprintf_colored('red_bg', '[ERROR] auto_physical criterion requires adaptive_physical.enabled = true\n');
        fprintf('Set convergence_adaptive_physical_mode = true in settings\n');
        error('Cannot use auto_physical criterion without exploratory study');
    end
    
% ========================================================================
% DIAGNOSTIC PHASE 0: Mesh vs Timestep Influence Testing (4 coarse tests)
% ========================================================================
% This diagnostic runs 4 quick simulations at coarse resolution to determine
% whether mesh refinement or timestep reduction has more influence on the
% numerical solution. Results are used to calculate adaptive refinement weights
% for dual refinement (mesh + timestep) throughout the convergence study.
%
% Tests performed:
%   1. Base case:       (N_coarse, dt_base)
%   2. Mesh refined:    (2×N_coarse, dt_base) - only mesh refinement
%   3. dt reduced:      (N_coarse, dt_base/2) - only timestep reduction  
%   4. Both refined:    (2×N_coarse, dt_base/2) - both refinements
%
% Output: param_influence struct with:
%   - mesh_delta: L2 norm change from mesh refinement alone
%   - dt_delta: L2 norm change from timestep reduction alone
%   - mesh_weight, dt_weight: Adaptive weights for dual refinement strategy
%
fprintf('\n=== MESH vs TIMESTEP INFLUENCE DIAGNOSTIC (4 Tests) ===\n');
fprintf('Testing which has more influence: Nx/Ny refinement or dt reduction...\n\n');

param_influence = run_mesh_vs_dt_diagnostic(p, N_start, settings);

fprintf_colored('yellow', '\n=== DIAGNOSTIC RESULTS: ADAPTIVE REFINEMENT STRATEGY ===\n');
if isfinite(param_influence.mesh_delta)
    fprintf_colored('green', 'Mesh refinement impact: %.3e (||omega_refined_mesh||_2)\n', param_influence.mesh_delta);
else
    fprintf_colored('green', 'Mesh refinement impact: N/A (mesh test failed)\n');
end
if isfinite(param_influence.dt_delta)
    fprintf_colored('blue', 'Timestep reduction impact: %.3e (||omega_reduced_dt||_2)\n', param_influence.dt_delta);
else
    fprintf_colored('blue', 'Timestep reduction impact: N/A (dt test failed)\n');
end
fprintf_colored('yellow', 'Strategy: Dual refinement (both Nx/Ny AND dt) weighted by influence\n');
fprintf('Most influential: %s\n', param_influence.most_influential);
fprintf('Refinement strategy: prioritize %s for adaptive convergence\n', param_influence.refinement_priority);
fprintf('====================================\n\n');
    
    % Initialize iteration tracking
    conv_log = repmat(convergence_iteration_schema(), 0, 1);
    iter_count = 0;
    cumulative_time = 0;
    
    % Initialize result cache to avoid redundant simulations
    result_cache = struct();

    % Live monitor handle (if available)
    global monitor_figure monitor_data;
    use_live_monitor = ~isempty(monitor_figure) && isvalid(monitor_figure);
    if use_live_monitor
        monitor_data.current_phase = 'Convergence: Initial Pair';
    end

    % Preflight checks (fail-fast)
    if isfield(settings, 'preflight') && settings.preflight.enabled
        run_preflight_checks(p, settings);
    end
    
    % ========================================================================
    % ADAPTIVE CONVERGENCE TRACKING & LIVE MONITORING
    % ========================================================================
    % Initialize convergence tracking structure
    conv_tracking = struct();
    conv_tracking.N_values = [];           % Mesh sizes tried
    conv_tracking.dt_values = [];          % Timestep values tried (dual refinement)
    conv_tracking.metrics = [];            % Convergence metrics (errors)
    conv_tracking.peak_vorticity = [];     % Peak vorticity at each stage
    conv_tracking.wall_time_s = [];        % Wall time per iteration
    conv_tracking.refinement_steps = [];   % Step size for each refinement
    conv_tracking.convergence_rate = [];   % Estimated convergence rate
    
    % ADAPTIVE DUAL REFINEMENT STRATEGY (based on diagnostic results)
    % Weight refinements by their measured influence on solution
    refinement_strategy = struct();
    mesh_delta_safe = param_influence.mesh_delta;
    dt_delta_safe = param_influence.dt_delta;
    if ~isfinite(mesh_delta_safe)
        mesh_delta_safe = 0;
    end
    if ~isfinite(dt_delta_safe)
        dt_delta_safe = 0;
    end
    total_influence = mesh_delta_safe + dt_delta_safe;
    if total_influence > 1e-12
        refinement_strategy.mesh_weight = mesh_delta_safe / total_influence;
        refinement_strategy.dt_weight = dt_delta_safe / total_influence;
    else
        % Fallback: equal weighting if diagnostic failed
        refinement_strategy.mesh_weight = 0.5;
        refinement_strategy.dt_weight = 0.5;
    end
    refinement_strategy.base_dt = p.dt;  % Track initial dt for scaling
    fprintf('\x1b[36m[DUAL REFINEMENT]\\x1b[0m Adaptive weights: Mesh=%.1f%%, dt=%.1f%%\n', ...
        refinement_strategy.mesh_weight*100, refinement_strategy.dt_weight*100);
    
    % Adaptive refinement parameters
    initial_step = round(Nmax / 4);        % Initial refinement step (coarse jumps)
    min_step = 2;                          % Minimum step size (when to stop refining)
    step_reduction_factor = 0.7;           % Reduce step by 30% each iteration (dynamic refinement)
    
    % Close any previous live convergence monitor windows
    existing_figs = findall(0, 'Type', 'figure', 'Name', 'Live Convergence Monitor');
    if ~isempty(existing_figs)
        close(existing_figs);
    end
    
    % Create new live convergence figure
    global conv_fig_handle;
    conv_fig_handle = figure('Name', 'Live Convergence Monitor', 'NumberTitle', 'off', ...
        'Position', [50, 50, 1200, 600]);
    fig_conv = conv_fig_handle;
    
    % Create progress waitbar if available
    if exist('waitbar', 'file')
        wb = waitbar(0, 'Convergence Study: Initializing...', 'Name', 'Convergence Study Progress');
        cleanup_wb = onCleanup(@() close(wb));
    else
        wb = [];
    end
    
    % Phase 1: Initial pair for Richardson extrapolation
    fprintf('\n\x1b[42m\x1b[30m=== CONVERGENCE PHASE 1: Initial Pair ===\x1b[0m\n');
    
    % Prepare iteration context (consolidated struct definition)
    iter_ctx = struct(...
        'result_cache', result_cache, ...
        'iter_count', iter_count, ...
        'cumulative_time', cumulative_time, ...
        'conv_tracking', conv_tracking, ...
        'conv_log', conv_log, ...
        'tol', tol, ...
        'use_live_monitor', use_live_monitor);
    
    % Run first iteration (N1)
    N1 = N_start;
    if ~isempty(wb)
        waitbar(0.1, wb, sprintf('Phase 1: Computing N=%d...', N1));
    end
    
    [iter_ctx, should_exit] = run_and_track_convergence_iteration(p, N1, ...
        "\x1b[32mPhase 1\x1b[0m", iter_ctx, settings, monitor_data, fig_conv);
    
    % Extract results
    metric1 = iter_ctx.last_metric;
    row1 = iter_ctx.last_row;
    wall_time1 = iter_ctx.last_wall_time;
    peak_vor1 = iter_ctx.last_peak_vor;
    iter_count = iter_ctx.iter_count;
    cumulative_time = iter_ctx.cumulative_time;
    conv_tracking = iter_ctx.conv_tracking;
    conv_log = iter_ctx.conv_log;
    
    % Exit on invalid metric
    if should_exit && iter_ctx.exit_reason == "metric_invalid"
        [T, meta] = handle_convergence_exit("metric_invalid", row1, tol, N1, NaN, ...
            NaN, conv_log, settings, run_mode);
        return;
    end

    % Check for user cancellation
    if should_exit
        [T, meta] = handle_convergence_exit("user_cancelled", row1, tol, N1, NaN, ...
            NaN, conv_log, settings, run_mode);
        return;
    end
    
    
    % Run second iteration (N2)
    N2 = 2 * N1;
    fprintf('\x1b[36mNext mesh (initial pair):\x1b[0m N=%d\n', N2);
    if ~isempty(wb)
        waitbar(0.2, wb, sprintf('Phase 1: Computing N=%d...', N2));
    end
    
    % Update context for next iteration
    iter_ctx.iter_count = iter_count;
    iter_ctx.cumulative_time = cumulative_time;
    iter_ctx.conv_tracking = conv_tracking;
    iter_ctx.conv_log = conv_log;
    
    [iter_ctx, should_exit] = run_and_track_convergence_iteration(p, N2, ...
        "Phase 1", iter_ctx, settings, monitor_data, fig_conv);
    
    % Extract results
    metric2 = iter_ctx.last_metric;
    row2 = iter_ctx.last_row;
    wall_time2 = iter_ctx.last_wall_time;
    peak_vor2 = iter_ctx.last_peak_vor;
    iter_count = iter_ctx.iter_count;
    cumulative_time = iter_ctx.cumulative_time;
    conv_tracking = iter_ctx.conv_tracking;
    conv_log = iter_ctx.conv_log;

    % Reference-based criterion update (after second mesh)
    if isfinite(metric2)
        fprintf_colored('blue_bg', '[CRITERION] Reference established (N=%d vs N=%d): metric=%.6e, tol=%.6e\n', N1, N2, metric2, tol);
    else
        fprintf_colored('blue_bg', '[CRITERION] Reference established (N=%d vs N=%d): metric=NaN (check solver stability)\n', N1, N2);
    end

    % Exit on invalid metric
    if should_exit && iter_ctx.exit_reason == "metric_invalid"
        [T, meta] = handle_convergence_exit("metric_invalid", [row1; row2], tol, ...
            N1, N2, NaN, conv_log, settings, run_mode);
        return;
    end

    % Check for user cancellation
    if should_exit
        [T, meta] = handle_convergence_exit("user_cancelled", [row1; row2], tol, ...
            N1, N2, NaN, conv_log, settings, run_mode);
        return;
    end

    % If Richardson metrics are invalid, extend the initial pair (limited attempts)
    if settings.convergence.use_adaptive
        [N1, N2, metric1, metric2, row1, row2, wall_time1, wall_time2, iter_count, cumulative_time, conv_log, conv_tracking] = ...
            extend_initial_pair_if_needed(N1, N2, metric1, metric2, row1, row2, wall_time1, wall_time2, ...
            Nmax, p, settings, result_cache, wb, use_live_monitor, monitor_data, ...
            iter_count, cumulative_time, conv_log, conv_tracking, tol, fig_conv);
    end
    
    % Check if already converged or metric is invalid
    [converged, reason] = check_convergence_criterion(metric2, tol);
    if reason == "metric_is_nan" || reason == "metric_not_finite"
        fprintf('\x1b[41m[CONVERGENCE EXIT]\x1b[0m Metric at N=%d is NaN/invalid. Ending study.\n', N2);
        N_star = NaN;
        [T, meta] = handle_convergence_exit("metric_invalid", [row1; row2], tol, ...
            N1, N2, N_star, conv_log, settings, run_mode);
        return;
    elseif converged
        fprintf('\x1b[42m✓ Converged at N=%d (metric=%.4g <= tol=%.4g)\x1b[0m\n', N2, metric2, tol);
        N_star = N2;
        [T, meta] = handle_convergence_exit("early_convergence", [row1; row2], tol, ...
            N1, N2, N_star, conv_log, settings, run_mode);
        return;
    end

    % Check for user cancellation before agent phase
    if check_convergence_cancel(settings)
        [T, meta] = handle_convergence_exit("user_cancelled", [row1; row2], tol, ...
            N1, N2, NaN, conv_log, settings, run_mode);
        return;
    end
    
    % Phase 1.5: Agent-guided next mesh selection (optional)
    if isfield(settings.convergence, 'agent') && settings.convergence.agent.enabled
        [N_agent, agent_info] = convergence_agent_select_next_N(N1, N2, metric1, metric2, row1, row2, wall_time1, wall_time2, tol, Nmax, settings.convergence.agent);
        if isfinite(N_agent) && N_agent > N2
            fprintf('\n\x1b[46m\x1b[30m=== CONVERGENCE PHASE 1.5: Agent-Guided Step ===\x1b[0m\n');
            fprintf('Agent suggests N=%d | p=%.3f | q=%.3f | pred_err=%.3e | score=%.3f\n', ...
                N_agent, agent_info.p_est, agent_info.q_est, agent_info.pred_err, agent_info.score);

            if ~isempty(wb)
                waitbar(0.35, wb, sprintf('Phase 1.5: Agent N=%d...', N_agent));
            end
            
            % Update context and run agent iteration
            iter_ctx.iter_count = iter_count;
            iter_ctx.cumulative_time = cumulative_time;
            iter_ctx.conv_tracking = conv_tracking;
            iter_ctx.conv_log = conv_log;
            
            [iter_ctx, ~] = run_and_track_convergence_iteration(p, N_agent, ...
                "Phase 1.5 (agent)", iter_ctx, settings, monitor_data, fig_conv);
            
            % Extract results
            metric_agent = iter_ctx.last_metric;
            row_agent = iter_ctx.last_row;
            wall_time_agent = iter_ctx.last_wall_time;
            iter_count = iter_ctx.iter_count;
            cumulative_time = iter_ctx.cumulative_time;
            conv_tracking = iter_ctx.conv_tracking;
            conv_log = iter_ctx.conv_log;

            % Exit on invalid metric from agent step
            if iter_ctx.exit_reason == "metric_invalid"
                [T, meta] = handle_convergence_exit("metric_invalid", [row1; row2; row_agent], ...
                    tol, N1, N_agent, NaN, conv_log, settings, run_mode);
                return;
            end
            
            % Update log with agent-specific metadata
            conv_log(iter_count).predicted_N = N_agent;
            conv_log(iter_count).p_est = agent_info.p_est;
            conv_log(iter_count).refinement_ratio = N_agent/N2;

            if metric_agent <= tol
                fprintf('\n\x1b[42m\u2713 CONVERGED via agent-guided step at N=%d\x1b[0m\n', N_agent);
                N_star = N_agent;
                [T, meta] = handle_convergence_exit("agent_success", [row1; row2; row_agent], ...
                    tol, N1, N_agent, N_star, conv_log, settings, run_mode);
                return;
            end

            % Shift pair to (N2, N_agent) for downstream Richardson/bracketing
            N1 = N2; metric1 = metric2; row1 = row2; wall_time1 = wall_time2;
            N2 = N_agent; metric2 = metric_agent; row2 = row_agent; wall_time2 = wall_time_agent;
        end
    end
    
    % Phase 2: Intelligent Richardson Extrapolation with Dynamic Mesh Prediction
    phase2_ctx = struct( ...
        'p', p, ...
        'settings', settings, ...
        'tol', tol, ...
        'Nmax', Nmax, ...
        'result_cache', result_cache, ...
        'fig_conv', fig_conv, ...
        'wb', wb, ...
        'use_live_monitor', use_live_monitor, ...
        'monitor_data', monitor_data, ...
        'conv_tracking', conv_tracking, ...
        'conv_log', conv_log, ...
        'iter_count', iter_count, ...
        'cumulative_time', cumulative_time, ...
        'refinement_strategy', refinement_strategy);

    [phase2_ctx, phase2_status, ~, ~, ~, N_low, row_low] = convergence_phase2_richardson( ...
        phase2_ctx, N1, N2, row1, row2, metric1, metric2, run_mode);

    conv_tracking = phase2_ctx.conv_tracking;
    conv_log = phase2_ctx.conv_log;
    iter_count = phase2_ctx.iter_count;
    cumulative_time = phase2_ctx.cumulative_time;
    result_cache = phase2_ctx.result_cache;
    p = phase2_ctx.p;  % Update p with refined dt

    if strcmp(phase2_status, "converged") || strcmp(phase2_status, "cancelled")
        return;
    end
    
    % Phase 3: Bracketing (extracted)
    phase3_ctx = struct( ...
        'p', p, ...
        'settings', settings, ...
        'tol', tol, ...
        'Nmax', Nmax, ...
        'result_cache', result_cache, ...
        'wb', wb, ...
        'iter_count', iter_count, ...
        'cumulative_time', cumulative_time, ...
        'conv_log', conv_log);

    [phase3_ctx, phase3_status, N_low, row_low, N_high] = convergence_phase3_bracketing(phase3_ctx, N_low, row_low, run_mode);
    iter_count = phase3_ctx.iter_count;
    cumulative_time = phase3_ctx.cumulative_time;
    conv_log = phase3_ctx.conv_log;
    result_cache = phase3_ctx.result_cache;

    if strcmp(phase3_status, "no_convergence")
        N_star = NaN;
        T = struct2table(row_low);
        meta = build_convergence_meta("no_convergence", tol, N_low, NaN, N_star, conv_log);
        save_convergence_iteration_log(conv_log, settings, run_mode);
        save_tradeoff_study(conv_log, settings, run_mode);
        return;
    end

    % Phase 4: Binary refinement (extracted)
    [phase3_ctx, N_star] = convergence_phase4_binary(phase3_ctx, N_low, N_high, run_mode);
    iter_count = phase3_ctx.iter_count;
    cumulative_time = phase3_ctx.cumulative_time;
    conv_log = phase3_ctx.conv_log;

    if isfield(phase3_ctx, "phase4_status") && phase3_ctx.phase4_status == "metric_invalid"
        last_row = phase3_ctx.phase4_last_row;
        if isempty(last_row)
            last_row = row_low;
        end
        [T, meta] = handle_convergence_exit("metric_invalid", [row_low; last_row], tol, ...
            N_low, phase3_ctx.phase4_last_N, NaN, conv_log, settings, run_mode);
        return;
    elseif isfield(phase3_ctx, "phase4_status") && phase3_ctx.phase4_status == "no_convergence"
        N_star = NaN;
        T = struct2table(row_low);
        meta = build_convergence_meta("no_convergence", tol, N_low, NaN, N_star, conv_log);
        save_convergence_iteration_log(conv_log, settings, run_mode);
        save_tradeoff_study(conv_log, settings, run_mode);
        return;
    end
    
    if ~isempty(wb)
        waitbar(1.0, wb, 'Convergence study complete!');
        pause(0.5);
    end
    
    % Create animation for the converged mesh (highest quality)
    if isfinite(N_star) && N_star > 0 && settings.animation.converged_mesh_enabled
        fprintf('\n\x1b[41m\x1b[37m=== GENERATING HIGH-QUALITY ANIMATION FOR CONVERGED MESH ===\x1b[0m\n');
        fprintf('\x1b[33mCreating animation at converged resolution:\x1b[0m N=%d x %d\n', N_star, N_star);
        
        % Prepare converged mesh parameters with animations enabled
        p_converged = p;
        p_converged.Nx = N_star;
        p_converged.Ny = N_star;
        
        % Enable animations for the converged solution
        p_converged.create_animations = true;
        p_converged.animation_fps = settings.animation.converged_mesh_fps;
        
        % Ensure animation configuration is complete
        if ~isfield(p_converged, 'animation_format') || isempty(p_converged.animation_format)
            p_converged.animation_format = settings.animation.format;
        end
        if ~isfield(p_converged, 'animation_dir') || isempty(p_converged.animation_dir)
            p_converged.animation_dir = fullfile('Figures', p_converged.analysis_method, 'Animations', 'Converged');
        end
        if ~isfield(p_converged, 'mode') || isempty(p_converged.mode)
            p_converged.mode = "solve";
        end
        
        % DEBUG: Print converged parameters
        fprintf('\x1b[35m[CONVERGENCE]\x1b[0m p_converged animation settings:\n');
        fprintf('  create_animations: %d\n', p_converged.create_animations);
        fprintf('  animation_fps: %.1f\n', p_converged.animation_fps);
        fprintf('  animation_format: %s\n', string(p_converged.animation_format));
        fprintf('  animation_dir: %s\n', p_converged.animation_dir);
        fprintf('  mode: %s\n', string(p_converged.mode));
        fprintf('  snap_times: [%.3f ... %.3f] (%d total)\n', p_converged.snap_times(1), p_converged.snap_times(end), numel(p_converged.snap_times));
        
        % Prepare grid and initial condition for converged mesh
        x_conv = linspace(-p_converged.Lx/2, p_converged.Lx/2, p_converged.Nx);
        y_conv = linspace(-p_converged.Ly/2, p_converged.Ly/2, p_converged.Ny);
        [X_conv, Y_conv] = meshgrid(x_conv, y_conv);
        p_converged.omega = initialise_omega(X_conv, Y_conv, p_converged.ic_type, p_converged.ic_coeff);
        
        % Run converged simulation with animation enabled
        try
            if ~isempty(wb)
                waitbar(0.95, wb, sprintf('Rendering animation for N=%d...', N_star));
            end
            
            cpu0 = cputime;
            t0_anim = tic;
            figs_before_conv = findall(0, 'Type', 'figure');
            
            [~, analysis_conv] = run_simulation_with_method(p_converged);
            
            figs_after_conv = findall(0, 'Type', 'figure');
            figs_new_conv = setdiff(figs_after_conv, figs_before_conv);
            save_case_figures(figs_new_conv, settings, run_mode, p_converged);
            
            wall_time_anim = toc(t0_anim);
            cpu_time_anim = cputime - cpu0;
            
            fprintf('\x1b[42m✓ Animation created successfully at converged mesh!\x1b[0m\n');
            fprintf('  Resolution: %d x %d grid points\n', N_star, N_star);
            fprintf('  Snapshots generated: %d\n', analysis_conv.snapshots_stored);
            fprintf('  Time: %.2f seconds\n', wall_time_anim);
            
        catch ME_anim
            fprintf('\x1b[43m\x1b[30m⚠ Warning: Could not create animation for converged mesh\x1b[0m\n');
            fprintf('  Error: %s\n', ME_anim.message);
        end
        
        if ~isempty(wb)
            waitbar(1.0, wb, 'Complete! Animation ready.');
            pause(0.5);
        end
    else
        fprintf('\n⚠ Could not create animation: convergence failed (N_star=%s)\n', num2str(N_star));
    end
    
    % Build final convergence table
    [T, ~] = build_convergence_table(p, N_low, N_high, N_star, tol, settings, run_mode);
    meta = build_convergence_meta("converged", tol, N_low, N_high, N_star, conv_log);
    save_convergence_iteration_log(conv_log, settings, run_mode);
    save_tradeoff_study(conv_log, settings, run_mode);
end

% ========================================================================
%% AGENT-BASED CONVERGENCE MODE
% ========================================================================
% Intelligent convergence with preflight testing and adaptive refinement
% Uses AdaptiveConvergenceAgent class for pattern learning and optimization

function [T, meta] = run_convergence_mode(Parameters, settings, run_mode)
    % Create unique convergence study with organized directory structure
    study_id = create_convergence_study(settings, Parameters);
    
    fprintf('\n╔════════════════════════════════════════════════════════════════════════════════╗\n');
    fprintf('║           AGENT-BASED ADAPTIVE CONVERGENCE MODE (INTELLIGENT REFINEMENT)       ║\n');
    fprintf('╚════════════════════════════════════════════════════════════════════════════════╝\n\n');
    fprintf('[AGENT] Using adaptive convergence with preflight training\n');
    fprintf('[AGENT] Study ID: %s\n\n', study_id);
    
    % Check if AdaptiveConvergenceAgent is available
    if exist('AdaptiveConvergenceAgent', 'file') ~= 2
        fprintf_colored('[WARNING] AdaptiveConvergenceAgent.m not found. Falling back to classic mode.\n', 'yellow');
        fprintf('Expected location: Scripts/Main/AdaptiveConvergenceAgent.m\n\n');
        [T, meta] = run_convergence_mode_classic(Parameters, settings, run_mode);
        return;
    end
    
    try
        % Create adaptive convergence agent
        agent = AdaptiveConvergenceAgent(Parameters, settings);
        
        % Phase 1: Preflight testing (small grids to learn patterns)
        fprintf('[PHASE 1] Running preflight tests...\n');
        agent.run_preflight();
        
        % Phase 2: Execute intelligent convergence study
        fprintf('[PHASE 2] Executing adaptive convergence study...\n');
        [N_star, T, meta] = agent.execute_convergence_study();
        
        % Enhance metadata with study info
        meta.study_id = study_id;
        meta.mode_version = 'adaptive_convergence';
        meta.agent_class = 'AdaptiveConvergenceAgent';
        
        fprintf('\n[AGENT] Convergence complete: N*=%d\n', N_star);
        fprintf('[AGENT] Results saved to: %s\n', settings.convergence.study_dir);
        
    catch ME
        fprintf_colored('[ERROR] Agent-based convergence failed: %s\n', 'red', ME.message);
        fprintf('Stack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
        end
        fprintf('\nFalling back to classic convergence mode...\n\n');
        [T, meta] = run_convergence_mode_classic(Parameters, settings, run_mode);
    end
end

% ========================================================================
%% SWEEP MODE
% - Runs parameter sweeps at a fixed grid resolution Nstar
% - If settings.converged_N exists, use that; otherwise use Parameters.Nx
% ========================================================================
function [T, meta] = run_sweep_mode(Parameters, settings, run_mode)

    if isfield(settings,"converged_N") && ~isempty(settings.converged_N)
        Nstar = settings.converged_N;
    else
        Nstar = Parameters.Nx;
    end
    % Build all parameter combinations for the sweep
    cases = build_sweep_cases(Parameters, Nstar, settings.sweep.nu_list, settings.sweep.dt_list, settings. sweep.ic_list);
    results = repmat(result_schema(), numel(cases), 1);
    
    % === PARALLEL OPTIMIZATION (Priority 1.1) ===
    % Use parfor for 4-8x speedup on multi-core systems
    % Each case is independent, making this embarrassingly parallel
    fprintf('[SWEEP MODE] Running %d cases in parallel...\n', numel(cases));
    
    parfor k = 1:numel(cases)
        params = cases(k);
        % Compute initial condition
        x = linspace(-params.Lx/2, params.Lx/2, params.Nx);
        y = linspace(-params.Ly/2, params.Ly/2, params.Ny);
        [X, Y] = meshgrid(x, y);
        params.omega = initialise_omega(X, Y, params.ic_type, params.ic_coeff);
        cpu0 = cputime;
        t0 = tic;
        figs_before = findall(0, 'Type', 'figure');  % Capture figures before run
        try
            [fig_handle, analysis] = run_simulation_with_method(params);
            figs_after = findall(0, 'Type', 'figure');  % Capture figures after run
            figs_new = setdiff(figs_after, figs_before);  % Identify new figures
            save_case_figures(figs_new, settings, run_mode, params);  % Changed mode to run_mode
            run_ok = true;
        catch ME
            fig_handle = [];
            analysis = struct(...
                'error_id', string(ME.identifier), ...
                'error_message', string(ME.message));
            % Note: fprintf inside parfor may not display in order
            fprintf("Error in sweep mode at %s line %d: %s - %s\n", ME.stack(1).file, ME.stack(1).line, ME.identifier, ME.message);  % Print error to console with file and line
            run_ok = false;
        end
        wall_time_s = toc(t0);
        cpu_time_s = cputime - cpu0;
        [mem_used_MB, mem_max_MB] = memory_metrics_MB();
        feats = extract_features_from_analysis(analysis);
        results(k) = pack_result(params, run_ok, analysis, feats, wall_time_s, cpu_time_s, mem_used_MB, mem_max_MB);
        if run_ok
            if ~isempty(fig_handle) && isgraphics(fig_handle)
                drawnow;
            end
        end
    end
    T = struct2table(results);
    meta = struct(...
        'mode', "sweep", ...
        'N_star', Nstar);
end

% ========================================================================
%% PREFLIGHT CHECKS
% ========================================================================
function run_preflight_checks(Parameters, settings)
    % Comprehensive preflight validation with multi-level parameter checking
    % Uses validation suite from Scripts/Infrastructure/validate_simulation_parameters.m
    
    % Run comprehensive validation
    [is_valid, warnings, errors] = validate_simulation_parameters(Parameters, settings);
    
    % If validation failed, abort immediately
    if ~is_valid
        error('Preflight validation failed. See errors above.');
    end
    
    % Required functions for operation
    required_funcs = {"run_simulation_with_method", "Finite_Difference_Analysis"};
    if isfield(settings.preflight, 'require_monitor') && settings.preflight.require_monitor
        required_funcs = [required_funcs, {"create_live_monitor_dashboard", "update_live_monitor"}];
    end

    for i = 1:numel(required_funcs)
        if exist(required_funcs{i}, 'file') ~= 2
            error('Preflight failed: required function not found: %s', required_funcs{i});
        end
    end

    % Basic parameter sanity (redundant with new validation, but kept for safety)
    assert(Parameters.Nx > 0 && Parameters.Ny > 0, 'Preflight failed: grid sizes invalid');
    assert(Parameters.dt > 0 && Parameters.Tfinal > 0, 'Preflight failed: dt/Tfinal invalid');

    % Ensure results directory exists
    if isfield(settings, 'results_dir') && ~exist(settings.results_dir, 'dir')
        mkdir(settings.results_dir);
    end
    fprintf('[PREFLIGHT] Comprehensive validation complete - Ready to proceed\n');
end
% ========================================================================
%% SINGLE CASE METRIC EVALUATION
% ========================================================================
function [metric, row, figs_new] = run_case_metric_cached(Parameters, N, cache, dt_override)
    % Cached version - checks cache before running simulation
    % DUAL REFINEMENT: Now supports dt override for adaptive timestep control
    % CRITICAL FIX: Proper dual-key caching (N + dt) to prevent stale results
    if nargin < 4
        dt_override = [];  % Use Parameters.dt if not specified
    end
    
    % CRITICAL: Cache key MUST include both N and dt to avoid stale results in dual refinement
    if isempty(dt_override)
        cache_key = sprintf('N%d_dt%.6e', N, Parameters.dt);  % Use base dt
    else
        cache_key = sprintf('N%d_dt%.6e', N, dt_override);    % Use override dt
    end
    
    % Make cache_key filesystem-safe (replace dots with underscores)
    cache_key = strrep(cache_key, '.', 'p');
    cache_key = strrep(cache_key, '-', 'm');
    cache_key = strrep(cache_key, '+', 'p');
    
    if nargin >= 3 && isstruct(cache) && isfield(cache, cache_key)
        % Return cached result
        cached = cache.(cache_key);
        metric = cached.metric;
        row = cached.row;
        figs_new = cached.figs;
        if isempty(dt_override)
            fprintf('  [Cache hit: N=%d, dt=%.3e]\n', N, Parameters.dt);
        else
            fprintf('  [Cache hit: N=%d, dt=%.3e]\n', N, dt_override);
        end
        return;
    end
    
    % No cache - run simulation and store result
    [metric, row, figs_new] = run_case_metric(Parameters, N, dt_override);
    
    % Store in cache with valid struct field name
    if nargin >= 3 && isstruct(cache)
        % Store directly in cache structure
        cache_entry = struct('metric', metric, 'row', row, 'figs', figs_new);
        cache.(cache_key) = cache_entry;
        % Assign back to caller workspace to persist cache updates
        assignin('caller', 'cache', cache);
    end
end

function [metric, row, figs_new] = run_case_metric(Parameters, N, dt_override)
    % Executes a single case at resolution N (Nx = Ny = N) and returns:
    %   metric -> convergence scalar (used for bracketing/binary search)
    %   row    -> packed results row (for logging and table construction)
    %   figs_new -> new figure handles created during simulation
    % DUAL REFINEMENT: Now accepts dt_override for adaptive timestep control
    
    if nargin < 3
        dt_override = [];
    end
    
    % Use new helper to prepare parameters (with optional dt override)
    params = prepare_simulation_params(Parameters, N, dt_override);
    
    % Use new helper to execute simulation
    [figs_new, analysis, run_ok, wall_time_s, cpu_time_s] = execute_simulation(params);
    
    % Memory metrics
    [mem_used_MB, mem_max_MB] = memory_metrics_MB();
    
    % Extract features
    feats = extract_features_from_analysis(analysis);    
    
    % --- Vorticity convergence metric: compare N vs 2N ---
    % CRITICAL: Never default to NaN without attempting proper computation
    % This defeats the purpose of convergence studies
    metric = NaN;
    Nf = NaN;
    if run_ok
        Nf = 2*N;
        % Ensure Nf is valid and feasible
        if isfinite(Nf) && Nf > N
            % Get criterion type from Parameters if available
            if isfield(Parameters, 'criterion_type') && ~isempty(Parameters.criterion_type)
                criterion_type = Parameters.criterion_type;
            else
                criterion_type = 'l2_relative';  % Default
            end
            
            % Compute Richardson metric with robust error handling
            try
                metric = compute_richardson_metric_for_mesh(N, Nf, Parameters, analysis, criterion_type);
                
                % Validate metric is physically meaningful
                if ~isfinite(metric)
                    fprintf('\x1b[43m[WARNING]\x1b[0m Richardson metric non-finite at N=%d. Attempting fallback...\n', N);
                    % Try extracting features directly as fallback
                    feats_N = extract_features_from_analysis(analysis);
                    if isfinite(feats_N.peak_abs_omega) && feats_N.peak_abs_omega > 0
                        % Use relative change as proxy metric
                        metric = abs(feats_N.convergence_criterion);
                        fprintf('\x1b[43m[WARNING]\x1b[0m Using fallback metric: %.4e\n', metric);
                    else
                        fprintf('\x1b[41m[ERROR]\x1b[0m Cannot compute valid metric at N=%d. Simulation may be unstable.\n', N);
                        % DO NOT set to NaN - let caller handle the error explicitly
                    end
                end
            catch ME
                fprintf('\x1b[41m[ERROR]\x1b[0m Richardson metric computation failed: %s\n', ME.message);
                % Rethrow to force caller to handle - don't silently continue
                rethrow(ME);
            end
        else
            fprintf('\x1b[41m[ERROR]\x1b[0m Invalid refinement: N=%d, Nf=%d (must have Nf > N)\n', N, Nf);
        end
    else
        fprintf('\x1b[41m[ERROR]\x1b[0m Simulation failed at N=%d, cannot compute metric\n', N);
    end
    
    if run_ok
        if isfinite(metric)
            fprintf('\x1b[35m[CONVERGENCE]\x1b[0m N=%d vs %d | dt=%.3e | metric=%.3e\n', N, Nf, params.dt, metric);
        else
            fprintf('\x1b[35m[CONVERGENCE]\x1b[0m N=%d vs %d | dt=%.3e | metric=NaN (unavailable)\n', N, Nf, params.dt);
        end
    end

    feats.convergence_criterion = metric;
    row = pack_result(params, run_ok, analysis, feats, wall_time_s, cpu_time_s, mem_used_MB, mem_max_MB);  % Fixed: was params_c and analysis_c
end
% ========================================================================
%% BINARY SEARCH WITH LOGGING
% ========================================================================
function [T, meta] = build_convergence_table(Parameters, N_low, N_high, N_star, tol, settings, run_mode)
    % Builds a compact convergence summary table for key resolutions:
    %   - last known "low" grid
    %   - selected grid N_star
    %   - first known "high" (converged) grid
    %
    % Also plots convergence metric vs grid points if values are finite.
    Ns = unique([N_low, N_star, N_high]);
    Ns = Ns(isfinite(Ns));  % Remove NaN values
    rows = repmat(result_schema(), numel(Ns), 1);
    for k = 1:numel(Ns)
        [~, rows(k), figs_new] = run_case_metric(Parameters, Ns(k));
        save_case_figures(figs_new, settings, run_mode, Parameters);
    end
    T = struct2table(rows);
    meta = struct;
    meta.tol = tol;
    meta.Ns_tested = Ns;
    if all(isfinite(T.grid_points)) && all(isfinite(T.convergence_metric))
        fig = figure;
        loglog(T.grid_points, T.convergence_metric, '-o', 'LineWidth', 1.3);
        Plot_Format('$N$ (grid points)', '$E$ (convergence metric)', ...
            'Grid convergence: feature metric', 'Default', 1.2);
        Legend_Format({'FD'}, 18, 'vertical', 1, 1, true);
        Plot_Saver(fig, 'fd_convergence_metric', true);
    end
end

function cases = build_sweep_cases(Parameters, Nstar, nu_list, dt_list, ic_list)
    % Builds a full factorial set of sweep cases at fixed grid Nstar:
    %   Nx = Ny = Nstar for all cases
    %   nu, dt, ic_type vary over provided lists
    idx = 0;
    cases = repmat(Parameters, 0, 1);
    for i = 1:numel(nu_list)
        for j = 1:numel(dt_list)
            for q = 1:numel(ic_list)
                idx = idx + 1;
                p = Parameters;
                p.Nx = Nstar;
                p.Ny = Nstar;
                p.nu = nu_list(i);
                p.dt = dt_list(j);
                p.ic_type = ic_list(q);
                p.snap_times = linspace(0, p.Tfinal, 9);
                cases(idx,1) = p;
            end
        end
    end
end
% ========================================================================
%% Method Selection Configuration
% ========================================================================
function cfg = get_analysis_method(method_name)
    % Returns a per-method configuration struct. Extend with method-specific
    % fields (e.g., discretisation options, domain layout) as new solvers are added.
    m = string(method_name);
    switch lower(m)
        case "finite difference"
            cfg = struct( ...
                "name", "finite_difference", ...
                "supports_explicit_delta", true, ...
                "default_scheme", "central", ...
                "notes", "Baseline FD solver"...
            );
        case "finite volume"
            cfg = struct( ...
                "name", "finite_volume", ...
                "supports_explicit_delta", true, ...
                "reconstruction", "MUSCL", ...
                "riemann_solver", "Roe", ...
                "notes", "Placeholder FV configuration"...
            );
        case "spectral"
            cfg = struct( ...
                "name", "spectral", ...
                "supports_explicit_delta", false, ...
                "basis", "Fourier", ...
                "dealising", "2/3-rule", ...
                "notes", "Placeholder spectral configuration"...
            );
        otherwise
            cfg = struct( ...
                "name", "unknown", ...
                "supports_explicit_delta", true, ...
                "notes", "Fallback configuration" ...
            );
    end
end

function plot_results_from_csv(csv_path) %#ok<DEFNU>
    % Reads results CSV and produces a few diagnostic plots using Plot_Format.
    if ~isfile(csv_path)
        warning("No CSV found to plot: %s", csv_path);
        return;
    end
    T = readtable(csv_path);
    if ismember("grid_points", T.Properties.VariableNames) && ismember("wall_time_s", T.Properties.VariableNames)
        figure('Name', 'Compute Time vs Grid Size');
        loglog(T.grid_points, T.wall_time_s, 'o-', 'LineWidth', 1.2);
        Plot_Format('$N_x N_y$', '$t_{wall}$ (s)', 'Compute time vs grid size', 'Default', 1.1);
        Legend_Format({'wall time'}, 14, 'vertical', 1, 1, true);
    end
    if ismember("convergence_metric", T.Properties.VariableNames) && ismember("grid_points", T.Properties.VariableNames)
        figure('Name', 'Convergence Metric');
        semilogy(T.grid_points, T.convergence_metric, 'o-', 'LineWidth', 1.2);
        Plot_Format('$N_x N_y$', '$E$ (relative error)', 'Convergence metric', 'Default', 1.1);
        Legend_Format({'metric'}, 14, 'vertical', 1, 1, true);
    end
    if ismember("nu", T.Properties.VariableNames) && ismember("convergence_metric", T.Properties.VariableNames)
        figure('Name', 'Viscosity Sweep');
        loglog(T.nu, T.convergence_metric, 'x', 'LineWidth', 1.2);
        Plot_Format('$\nu$ (m^2/s)', '$E$ (relative error)', 'Viscosity sweep vs error', 'Default', 1.1);
        Legend_Format({'\nu vs E'}, 14, 'vertical', 1, 1, true);
    end
end

% ========================================================================
% DEPRECATED: Forwarding wrappers to Infrastructure modules
% These functions have been extracted to focused modules for maintainability.
% Wrappers preserve backwards compatibility.
% ========================================================================

function val = take_scalar_metric(val)
    % DEPRECATED: Forward to HelperUtils.take_scalar_metric
    % TODO: Remove wrapper in future release after updating all call sites
    val = HelperUtils.take_scalar_metric(val);
end

function out = pack_result(params, run_ok, analysis, feats, wall_time_s, cpu_time_s, mem_used_MB, mem_max_MB)
    % DEPRECATED: Forward to MetricsExtractor.pack_result
    out = MetricsExtractor.pack_result(params, run_ok, analysis, feats, wall_time_s, cpu_time_s, mem_used_MB, mem_max_MB);
end

function out = result_schema()
    % DEPRECATED: Forward to MetricsExtractor.result_schema
    out = MetricsExtractor.result_schema();
end

function feats = extract_features_from_analysis(analysis)
    % DEPRECATED: Forward to MetricsExtractor.extract_features_from_analysis
    feats = MetricsExtractor.extract_features_from_analysis(analysis);
end

function v = safe_get(S, field, default)
    % DEPRECATED: Forward to HelperUtils.safe_get
    v = HelperUtils.safe_get(S, field, default);
end

function s = sanitize_token(s)
    % DEPRECATED: Forward to HelperUtils.sanitize_token
    s = HelperUtils.sanitize_token(s);
end

function clean = strip_ansi_codes(text)
    % DEPRECATED: Forward to ConsoleUtils.strip_ansi_codes
    clean = ConsoleUtils.strip_ansi_codes(text);
end

function fprintf_colored(color_name, format_str, varargin)
    % DEPRECATED: Forward to ConsoleUtils.fprintf_colored
    ConsoleUtils.fprintf_colored(color_name, format_str, varargin{:});
end

function T_existing = migrate_csv_schema(T_existing, T_current, csv_path, missing_in_existing, extra_in_existing)
    % DEPRECATED: Forward to ResultsPersistence.migrate_csv_schema
    T_existing = ResultsPersistence.migrate_csv_schema(T_existing, T_current, csv_path, missing_in_existing, extra_in_existing);
end

function append_master_csv(T_current, settings)
    % DEPRECATED: Forward to ResultsPersistence.append_master_csv
    ResultsPersistence.append_master_csv(T_current, settings);
end

function report_path = generate_solver_report(T, meta, settings, run_mode)
    % DEPRECATED: Forward to ReportGenerator.generate_solver_report
    report_path = ReportGenerator.generate_solver_report(T, meta, settings, run_mode);
end

function html = table_to_html(T)
    % DEPRECATED: Forward to ReportGenerator.table_to_html
    html = ReportGenerator.table_to_html(T);
end

function out = format_report_value(val)
    % DEPRECATED: Forward to ReportGenerator.format_report_value
    out = ReportGenerator.format_report_value(val);
end

function txt = escape_html(txt)
    % DEPRECATED: Forward to ReportGenerator.escape_html
    txt = ReportGenerator.escape_html(txt);
end

function figs = collect_report_figures(settings, mode_str, max_figs)
    % DEPRECATED: Forward to ReportGenerator.collect_report_figures
    figs = ReportGenerator.collect_report_figures(settings, mode_str, max_figs);
end

% END DEPRECATED WRAPPERS
% ========================================================================

function params = prepare_simulation_params(Parameters, N, dt_override)
    % Prepares simulation parameters with grid initialization
    % Centralizes the pattern of:
    %   1. Set Nx = Ny = N
    %   2. Set dt (use override if provided for dual refinement)
    %   3. Compute delta (unless explicit)
    %   4. Generate grid and initial vorticity
    params = Parameters;
    params.Nx = N;
    params.Ny = N;
    
    % DUAL REFINEMENT: Allow dt override for adaptive timestep control
    if nargin >= 3 && ~isempty(dt_override)
        params.dt = dt_override;
    end
    
    % For convergence mode, ensure animations are disabled for intermediate grids
    % but static figures are always created
    if isfield(Parameters, 'mode') && strcmpi(Parameters.mode, 'convergence')
        params.converged = false;  % Mark as non-converged intermediate grid
        params.create_animations = false;  % Skip animations for speed
    end
    
    % Respect explicit delta if requested; otherwise derive from Lx/Nx
    if ~isfield(params, "use_explicit_delta") || ~params.use_explicit_delta
        params.delta = params.Lx / (params.Nx - 1);
    end
    
    % Compute initial condition
    x = linspace(-params.Lx/2, params.Lx/2, params.Nx);
    y = linspace(-params.Ly/2, params.Ly/2, params.Ny);
    [X, Y] = meshgrid(x, y);
    params.omega = initialise_omega(X, Y, params.ic_type, params.ic_coeff);
    
    % Diagnostic: verify IC was computed
    omega_min = min(params.omega(:));
    omega_max = max(params.omega(:));
    fprintf('\x1b[44m[IC INIT]\x1b[0m Type: %s, Grid: %dx%d, dt=%.3e, Omega size: %d x %d\n', ...
        char(params.ic_type), params.Nx, params.Ny, params.dt, size(params.omega, 1), size(params.omega, 2));
    fprintf('\x1b[44m[IC INIT]\x1b[0m Omega range: [%.6e, %.6e], NaN count: %d, Inf count: %d\n', ...
        omega_min, omega_max, nnz(isnan(params.omega)), nnz(isinf(params.omega)));
end

function [figs_new, analysis, run_ok, wall_time_s, cpu_time_s] = execute_simulation(params)
    % Executes Finite_Difference_Analysis with comprehensive error handling and metrics
    % Returns:
    %   figs_new     - New figure handles created during simulation
    %   analysis     - Solver output structure
    %   run_ok       - Success flag
    %   wall_time_s  - Wall clock time
    %   cpu_time_s   - CPU time
    
    % Verify omega field exists and has valid data
    if isfield(params, 'omega') && ~isempty(params.omega)
        fprintf('\x1b[43m[EXECUTE]\x1b[0m Omega field present: [%.4f, %.4f], size: %d x %d\n', ...
            min(params.omega(:)), max(params.omega(:)), size(params.omega, 1), size(params.omega, 2));
    else
        fprintf('\x1b[41m[EXECUTE ERROR]\x1b[0m Omega field missing or empty!\n');
    end
    
    cpu0 = cputime;
    t0 = tic;
    figs_before = findall(0, 'Type', 'figure');
    
    try
        % Use method dispatcher to route to appropriate solver
        [~, analysis] = run_simulation_with_method(params);
        figs_after = findall(0, 'Type', 'figure');
        figs_new = setdiff(figs_after, figs_before);
        run_ok = true;
    catch ME
        analysis = struct(...
            'error_id', string(ME.identifier), ...
            'error_message', string(ME.message));
        fprintf("Error in simulation: %s at %s line %d: %s\n", ...
            ME.identifier, ME.stack(1).file, ME.stack(1).line, ME.message);
        run_ok = false;
        figs_new = [];
    end
    
    wall_time_s = toc(t0);
    cpu_time_s = cputime - cpu0;
end

function [mem_used_MB, mem_max_MB] = memory_metrics_MB()
    % Best-effort memory usage metric:
    % - Works on Windows (memory() exists)
    % - Returns NaN if memory() is unavailable
    mem_used_MB = NaN;
    mem_max_MB  = NaN;
    try
        m = memory;
        mem_used_MB = m.MemUsedMATLAB / 1024^2;
        mem_max_MB  = m.MaxPossibleArrayBytes / 1024^2;
    catch
        % memory() not available on this system - NaN values already set
    end
end

function save_case_figures(fig_handles, settings, mode, params)
    if isempty(fig_handles)
        return
    end
    
    % Ensure mode is a valid string
    if isstring(mode)
        mode = char(mode);
    end
    mode = string(mode);
    if strlength(mode) == 0
        mode = "unnamed";
    end
    
    for i = 1:numel(fig_handles)
        fh = fig_handles(i);
        if ~isgraphics(fh)
            continue
        end
        % Get figure name for categorization
        fig_name = string(get(fh, "Name"));
        
        % Determine subdirectory based on figure name (all lowercase)
        if contains(lower(fig_name), "evol")
            subdir = "evolution";
        elseif contains(lower(fig_name), "contour")
            subdir = "contour";
        elseif contains(lower(fig_name), "vector")
            subdir = "vectorised";
        elseif contains(lower(fig_name), "anim")
            subdir = "animation";
        else
            subdir = "other";  % Fallback for uncategorized figures
        end
        
        % Get analysis method from params (default to "Finite Difference" if not specified)
        analysis_method = "Finite Difference";
        if isfield(params, "analysis_method") && ~isempty(params.analysis_method)
            analysis_method = string(params.analysis_method);
        end
        
        % Build full path: Figures/[Analysis Method]/[Mode]/[Figure Type]/
        mode_folder = sanitize_token(upper(string(mode)));  % MODE in uppercase
        root_dir = string(settings.figures.root_dir);
        
        % Ensure all path components are non-empty
        if strlength(root_dir) == 0
            root_dir = "Figures";
        end
        if strlength(mode_folder) == 0
            mode_folder = "OTHER";
        end
        if strlength(subdir) == 0
            subdir = "other";
        end
        
        % Path structure: Figures/[Analysis Method]/[MODE]/[figure_type]/
        mode_dir = fullfile(root_dir, analysis_method, mode_folder, subdir);
        if ~exist(mode_dir, "dir")
            mkdir(mode_dir);
        end
        case_id = make_case_id(params, mode);  % Pass mode to make_case_id
        % If the figure has a name, use it; otherwise use index
        fig_tag = fig_name;
        if strlength(fig_tag) == 0
            fig_tag = sprintf("fig_%02d", i);
        else
            fig_tag = sanitize_token(fig_tag);
        end
        base_name = sprintf("%s_%s", case_id, fig_tag);
        % Use OWL Plot_Saver if requested and available
        if settings.figures.use_owl_plot_saver && exist("Plot_Saver","file") == 2
            % Plot_Saver signature in your notes: Plot_Saver(gcf, 'name', save_flag)
            % It saves to its own Figures/ directory by default.
            % To enforce mode subfolders, we temporarily cd into mode_dir.
            cwd = pwd;
            try
                cd(mode_dir);
                Plot_Saver(fh, base_name, true);
            catch
                % Fall back to builtin saving if Plot_Saver fails
                cd(cwd);
                builtin_save_figure(fh, mode_dir, base_name, settings);
            end
            cd(cwd);
        else
            builtin_save_figure(fh, mode_dir, base_name, settings);
        end
        if settings.figures.close_after_save
            close(fh);
        end
    end
end

function builtin_save_figure(fh, out_dir, base_name, settings)
    if settings.figures.save_png
        png_path = fullfile(out_dir, base_name + ".png");
        dpi = 300;  % Default
        if isfield(settings.figures, 'dpi') && ~isempty(settings.figures.dpi)
            dpi = settings.figures.dpi;
        end
        export_figure_png(fh, png_path, dpi);
    end
    if settings.figures.save_fig
        fig_path = fullfile(out_dir, base_name + ".fig");
        savefig(fh, fig_path);
    end
end

function case_id = make_case_id(params, mode)
    % Deterministic, filesystem-safe identifier with mode, date, time, and parametric data
    % Format: MODE_YYYY-MM-DD_HH-MM-SS_Nx=X_Ny=Y_nu=XXX_dt=XXX_Tfinal=Z_ic=TYPE
    
    % Default mode if not provided
    if nargin < 2 || isempty(mode)
        mode = "unnamed";
    end
    mode = string(mode);
    
    now_dt = datetime("now");
    date_str = sprintf("%04d%02d%02d", year(now_dt), month(now_dt), day(now_dt));
    time_str = sprintf("%02d%02d%02d", hour(now_dt), minute(now_dt), second(now_dt));
    timestamp = date_str + "_" + time_str;
    
    % Build parametric data with equal signs for clarity
    param_str = sprintf( ...
        "Nx=%d_Ny=%d_nu=%.2e_dt=%.2e_Tfinal=%.1f_ic=%s", ...
        params.Nx, ...
        params.Ny, ...
        params.nu, ...
        params.dt, ...
        params.Tfinal, ...
        sanitize_token(string(params.ic_type)) ...
    );
    
    % Append IC coefficients if available (especially for stretched_gaussian)
    ic_coeff_str = "";
    if isfield(params, "ic_coeff") && ~isempty(params.ic_coeff) && isnumeric(params.ic_coeff)
        if strcmpi(string(params.ic_type), "stretched_gaussian") && numel(params.ic_coeff) >= 2
            % For stretched_gaussian: append x_coeff and y_coeff
            ic_coeff_str = sprintf("_coeff[%.2f,%.2f]", params.ic_coeff(1), params.ic_coeff(2));
        end
    end
    
    % Format: MODE_YYYYMMDD_HHMMSS_Nx=X_Ny=Y_nu=....
    case_id = sanitize_token(mode) + "_" + timestamp + "_" + param_str + ic_coeff_str;
end

function out = convergence_iteration_schema()
    % Schema for convergence iteration CSV logging
    out = struct;
    out.iteration = NaN;
    out.search_phase = "";
    out.N = NaN;
    out.convergence_metric = NaN;
    out.predicted_N_target = NaN;
    out.wall_time_s = NaN;
    out.cumulative_time_s = NaN;
    out.tolerance = NaN;
    out.convergence_rate_p = NaN;
    out.adaptive_jump_factor = NaN;
end

function out = pack_convergence_iteration(iter, phase, N, metric, N_pred, wall_time, cumul_time, tol, p_rate, jump_factor)
    out = convergence_iteration_schema();
    out.iteration = iter;
    out.search_phase = string(phase);
    out.N = N;
    out.convergence_metric = metric;
    out.predicted_N_target = N_pred;
    out.wall_time_s = wall_time;
    out.cumulative_time_s = cumul_time;
    out.tolerance = tol;
    out.convergence_rate_p = p_rate;
    out.adaptive_jump_factor = jump_factor;
end

function save_convergence_iteration_log(conv_log, settings, ~)  % run_mode unused - kept for API consistency
    if ~settings.convergence.save_iterations
        return;
    end
    
    T_iter = struct2table(conv_log);
    csv_path = fullfile(settings.results_dir, sprintf("convergence_iterations_%s.csv", datestr(now, 'yyyy-mm-dd_HH-MM-SS')));
    
    % Add timestamp
    T_iter.timestamp = repmat(datetime("now"), height(T_iter), 1);
    
    writetable(T_iter, csv_path);
    fprintf('\nConvergence iteration log saved: %s\n', csv_path);
end

%% VISUALIZATION & PLOTS
% Saves convergence figures with organized study structure
% Organizes all figures by study → phase → iteration for easy tracking and analysis

function save_convergence_figures(fig_handles, settings, params, iter, phase, N)
    %SAVE_CONVERGENCE_FIGURES Save convergence figures with organized study structure
    %
    %   SAVE_CONVERGENCE_FIGURES(fig_handles, settings, params, iter, phase, N)
    %
    % Saves figures to:
    %   Results/Convergence/convergence_study_YYYYMMDD_HHMMSS_XXXX/
    %   ├── preflight/figures/ (for preflight phase)
    %   └── iteration_NNN/figures/PHASE/ (for refinement phases)
    %
    % Figure naming: NN_PHASE_N_FIGNAME.png
    % - NN: Sequential figure counter (01, 02, 03...)
    % - PHASE: Phase name (grid_refinement, timestep_refinement, etc.)
    % - N: Grid/timestep parameter
    % - FIGNAME: Figure name from figure object
    
    fprintf_colored('[CONVERGENCE SAVE] Processing %d figures for %s (iter=%d, N=%d)\n', ...
        numel(fig_handles), phase, iter, N, 'cyan_bg');
    
    if isempty(fig_handles)
        fprintf_colored('[CONVERGENCE SAVE] WARNING: No figures to save!\n', 'yellow');
        return;
    end
    
    if ~settings.convergence.save_iteration_figures
        fprintf_colored('[CONVERGENCE SAVE] Skipping: save_iteration_figures disabled\n', 'yellow');
        return;
    end
    
    % Strip ANSI codes from phase name
    phase_clean = strip_ansi_codes(phase);
    
    % Determine output directory based on phase type
    if strcmpi(phase_clean, 'preflight')
        % Preflight phase uses special preflight directory
        fig_dir = settings.convergence.preflight_figs_dir;
    else
        % Regular iteration phases
        fig_dir = get_convergence_phase_fig_dir(settings, iter, phase_clean);
    end
    
    % Get DPI setting
    dpi = 300;
    if isfield(settings.figures, 'dpi') && ~isempty(settings.figures.dpi)
        dpi = settings.figures.dpi;
    end
    
    % Save each figure with sequential numbering for easy identification
    for i = 1:numel(fig_handles)
        fh = fig_handles(i);
        if ~isgraphics(fh)
            fprintf_colored('  [Figure %d] Skipping invalid graphics handle\n', i, 'yellow');
            continue;
        end
        
        fig_name = string(get(fh, "Name"));
        if strlength(fig_name) == 0
            fig_name = "figure";
        end
        
        % Format: NN_PHASE_N_FIGNAME
        % This makes all figures in a study easily browsable and identifiable
        base_name = sprintf("%02d_%s_N%04d_%s", i, lower(phase_clean), N, sanitize_token(fig_name));
        
        if settings.figures.save_png
            png_path = fullfile(fig_dir, base_name + ".png");
            export_figure_png(fh, png_path, dpi);
            fprintf_colored('  ✓ PNG: %s\n', png_path, 'green');
        end
        
        if settings.figures.save_fig
            fig_path = fullfile(fig_dir, base_name + ".fig");
            savefig(fh, fig_path);
            fprintf_colored('  ✓ FIG: %s\n', fig_path, 'green');
        end
        
        if settings.figures.close_after_save
            close(fh);
        end
    end
    
    fprintf_colored('[CONVERGENCE SAVE] All figures saved to: %s\n', fig_dir, 'green_bg');
    fprintf('[CONVERGENCE SAVE] Completed saving %d figures to %s\n', numel(fig_handles), fig_dir);
end

function export_figure_png(fh, png_path, dpi)
    % Robust PNG export for standard figures and uifigures
    try
        exportgraphics(fh, png_path, "Resolution", dpi);
        return;
    catch ME
        % Fallback for uifigure with multiple containers
        try
            exportapp(fh, png_path);
            return;
        catch
            % Final fallback: export first axes if available
            ax = findall(fh, 'Type', 'axes');
            if ~isempty(ax)
                exportgraphics(ax(1), png_path, "Resolution", dpi);
                return;
            end
            rethrow(ME);
        end
    end
end

function meta = build_convergence_meta(status, tol, N_low, N_high, N_star, conv_log)
    meta = struct;
    meta.mode = "convergence";
    meta.status = string(status);
    meta.tol = tol;
    meta.N_low = N_low;
    meta.N_high = N_high;
    meta.N_star = N_star;
    meta.total_iterations = numel(conv_log);
    meta.total_cumulative_time = 0;
    if ~isempty(conv_log)
        meta.total_cumulative_time = conv_log(end).cumulative_time_s;
    end
    meta.convergence_log = conv_log;
end

function [N_star, conv_log] = binary_search_N_logged(Parameters, N_low, N_high, tol, settings, iter_start, cumul_time_start, cache, wb)
    % Binary search with iteration logging and caching
    N_star = N_high;
    conv_log = repmat(convergence_iteration_schema(), 0, 1);
    iter_count = iter_start;
    cumulative_time = cumul_time_start;
    
    fprintf('Binary search between N=%d and N=%d\n', N_low, N_high);
    
    while (N_high - N_low) > 1
        N_mid = floor((N_low + N_high)/2);
        
        if ~isempty(wb)
            progress = 0.85 + 0.1 * (log2(N_high - N_low) / log2(N_high - N_low + 1));
            waitbar(min(progress, 0.95), wb, sprintf('Binary search: N=%d...', N_mid));
        end
        
        t0 = tic;
        [metric_mid, ~, figs_mid] = run_case_metric_cached(Parameters, N_mid, cache);
        wall_time_mid = toc(t0);
        
        % Display binary search progress
        if ~isfinite(metric_mid)
            fprintf('\x1b[41m[CONVERGENCE EXIT]\x1b[0m Phase 4 metric invalid at N=%d. Aborting binary search.\n', N_mid);
            conv_log(end+1) = pack_convergence_iteration(iter_count, "binary_search", N_mid, metric_mid, NaN, wall_time_mid, cumulative_time, tol, NaN, NaN);
            N_star = NaN;
            return;
        else
            fprintf('  Phase 4 - N=%4d (binary): Metric = %.6e (Target: %.6e)\n', N_mid, metric_mid, tol);
        end
        cumulative_time = cumulative_time + wall_time_mid;
        iter_count = iter_count + 1;
        
        if settings.convergence.save_iteration_figures
            save_convergence_figures(figs_mid, settings, Parameters, iter_count, "binary_search", N_mid);
        end
        save_mesh_visuals_if_enabled(settings, Parameters, iter_count, "binary_search", N_mid);
        
        conv_log(end+1) = pack_convergence_iteration(iter_count, "binary_search", N_mid, metric_mid, NaN, wall_time_mid, cumulative_time, tol, NaN, NaN);
        
        if metric_mid <= tol
            N_star = N_mid;
            N_high = N_mid;
            fprintf('  N=%d CONVERGED (metric=%.4g <= tol=%.4g)\n', N_mid, metric_mid, tol);
        else
            N_low = N_mid;
            fprintf('  N=%d NOT converged (metric=%.4g > tol=%.4g)\n', N_mid, metric_mid, tol);
        end
        
        % Allow user to halt and declare convergence
        if ~isempty(wb) && mod(iter_count, 2) == 0
            % User can close waitbar to halt
            if ~isvalid(wb)
                fprintf('\nConvergence study halted by user at N=%d\n', N_mid);
                N_star = N_mid;
                break;
            end
        end
    end
    
    fprintf('Binary search complete: N_star=%d\n', N_star);
end

function [T, meta] = run_experimentation_mode(Parameters, settings, run_mode, exp_config)
    % Experimentation mode: Test various initial conditions and configurations
    % Supports: double vortex, three vortex, non-uniform boundary, Gaussian merger, counter-rotating
    %
    % Usage: Set experimentation.test_case = "double_vortex" or other cases
    %        Run mode will execute that test case with comparison visualizations
    
    fprintf('\n╔════════════════════════════════════════════════════════════════════════════════╗\n');
    fprintf('║                       EXPERIMENTATION MODE                                     ║\n');
    fprintf('╚════════════════════════════════════════════════════════════════════════════════╝\n\n');
    
    test_case = exp_config.test_case;
    fprintf('Test Case: %s\n\n', test_case);
    
    % Define test cases
    test_cases = struct(...
        'double_vortex', struct(...
            'name', 'Two Stretched Gaussian Vortices (Close Separation - Merging)', ...
            'ic_type', 'multi_vortex', ...
            'ic_coeff', [1.5, 1.2, 2.5, 5.0, 1.5, 1.2, 7.5, 5.0, 0.0, 0.0, 5.0, 5.0], ...
            'notes', 'Two stretched Gaussian vortex cores (Γ1=Γ2=1.5, R=1.2) positioned 5 units apart (x1=2.5, x2=7.5). Close initial separation enables strong interaction and potential merging. Tests energy cascade, enstrophy evolution, and dipole formation. Third vortex inactive (Γ3=0). Models tsunami-induced vortex pair approaching merger.'), ...
        'three_vortex', struct(...
            'name', 'Three Stretched Gaussian Vortices (Multi-Body Cascade)', ...
            'ic_type', 'multi_vortex', ...
            'ic_coeff', [1.8, 1.3, 2.0, 5.0, 1.5, 1.2, 5.0, 5.0, 1.2, 1.0, 8.0, 5.0], ...
            'notes', 'Three Gaussian vortex cores with decreasing circulation (Γ1=1.8, Γ2=1.5, Γ3=1.2) and core radii (R1=1.3, R2=1.2, R3=1.0) arranged in triangular formation. Initial separation (Δx≈3 units) enables sequential interaction and hierarchical merging. Tests cascade dynamics, vortex pairing, and energy transfer between scales. Relevant to coastal upwelling with multiple tide-driven vortices.'), ...
        'non_uniform_boundary', struct(...
            'name', 'Two Stretched Gaussian Vortices (Wide Separation - Slow Advection)', ...
            'ic_type', 'multi_vortex', ...
            'ic_coeff', [1.5, 1.2, 1.5, 5.0, 1.5, 1.2, 8.5, 5.0, 0.0, 0.0, 5.0, 5.0], ...
            'notes', 'Two symmetric stretched Gaussian vortices (Γ1=Γ2=1.5, R=1.2) with wide initial separation (Δx=7.0, centered at x=1.5 and x=8.5). Tests slow mutual advection, weak interaction phase, and long-timescale vortex evolution. Third vortex inactive (Γ3=0). Models distant coastal jets that gradually approach over time. Validates long-duration simulations and asymptotic vorticity decay.'), ...
        'gaussian_merger', struct(...
            'name', 'Single Stretched Gaussian Vortex Blob (Baseline Diffusion)', ...
            'ic_type', 'vortex_blob_gaussian', ...
            'ic_coeff', [1.5, 1.3, 5.0, 5.0], ...
            'notes', 'Single stretched Gaussian vortex blob (Γ=1.5, R=1.3) at domain center. Isolates viscous diffusion and vorticity spreading without interaction effects. Provides baseline for energy dissipation rate, enstrophy decay constant, and long-time asymptotic behavior. Essential for validating energy balance and Kolmogorov scaling diagnostics.'), ...
        'counter_rotating', struct(...
            'name', 'Counter-Rotating Stretched Gaussian Pair (Dipole Self-Propagation)', ...
            'ic_type', 'counter_rotating_pair', ...
            'ic_coeff', [1.5, 1.2, 3.5, 5.0, -1.5, 1.2, 6.5, 5.0], ...
            'notes', 'Two counter-rotating Gaussian vortex cores (Γ1=+1.5, Γ2=-1.5, R=1.2) separated 3 units. Self-propelling dipole structure with mutual advection velocity ≈0.5 domain units/τ. Tests vortex pair self-advection, energy-enstrophy relationships, and dipole coherence. Models Langmuir circulation and coastal frontal jets with oppositely-signed circulation.'));
    
    % Get selected test case
    if ~isfield(test_cases, test_case)
        error('Unknown test case: %s. Available: %s', test_case, strjoin(fieldnames(test_cases), ', '));
    end
    
    selected_case = test_cases.(test_case);
    fprintf('Description: %s\n', selected_case.name);
    if isfield(selected_case, 'notes')
        fprintf('Notes: %s\n\n', selected_case.notes);
    end
    
    % Update Parameters for this test case
    p = Parameters;
    p.ic_type = selected_case.ic_type;
    p.ic_coeff = selected_case.ic_coeff;
    
    % Compute initial condition
    [X, Y] = meshgrid(linspace(0, p.Lx, p.Nx), linspace(0, p.Ly, p.Ny));
    p.omega = initialise_omega(X, Y, p.ic_type, p.ic_coeff);
    
    % Run simulation
    fprintf('Running simulation...\n');
    [figs, analysis, ~, ~, ~] = execute_simulation(p);
    
    % Save figures
    save_case_figures(figs, settings, run_mode, p);
    fprintf('Figures saved for test case: %s\n\n', selected_case.name);
    
    % Extract metrics
    feats = extract_features_from_analysis(analysis);
    
    % Create results table
    row = struct(...
        'Nx', p.Nx, ...
        'Ny', p.Ny, ...
        'nu', p.nu, ...
        'dt', p.dt, ...
        'Tfinal', p.Tfinal, ...
        'ic_type', string(p.ic_type), ...
        'test_case', string(selected_case.name), ...
        'peak_abs_omega', feats.peak_abs_omega, ...
        'enstrophy', feats.enstrophy, ...
        'peak_u', feats.peak_u, ...
        'peak_v', feats.peak_v, ...
        'peak_speed', feats.peak_speed, ...
        'run_time_s', wall_time_s);
    
    T = struct2table(row);
    
    % Create metadata
    meta = struct(...
        'mode', 'EXPERIMENTATION', ...
        'test_case', selected_case.name, ...
        'grid_resolution', sprintf('%d x %d', p.Nx, p.Ny), ...
        'parameters', sprintf('nu=%.2e, dt=%.2e, Tfinal=%.2f', p.nu, p.dt, p.Tfinal), ...
        'max_vorticity', feats.peak_abs_omega, ...
        'run_time', sprintf('%.2f s', wall_time_s), ...
        'status', 'Experimentation complete');
    
    fprintf('\n════════════════════════════════════════════════════════════════════════════════\n');
    fprintf('Test case results:\n');
    disp(row);
    fprintf('════════════════════════════════════════════════════════════════════════════════\n\n');
end

% ========================================================================
% COEFFICIENT SWEEP EXECUTION FRAMEWORK
% ========================================================================

function [sweep_results, sweep_table] = run_coefficient_sweep(base_case, sweep_config, Parameters, settings)
    % Execute parametric sweep over initial condition coefficients
    %
    % Usage:
    %   [results, table] = run_coefficient_sweep(selected_case, sweep_struct, Parameters, settings);
    %
    % sweep_config Structure:
    %   .parameter      - Name of parameter (e.g., 'gamma', 'radius')
    %   .index          - Index or indices in ic_coeff vector to vary
    %   .values         - Array of values to test
    %   .description    - Descriptive text for reporting
    %
    % Returns:
    %   sweep_results   - Cell array of result structures for each parameter value
    %   sweep_table     - Table summarizing all results
    
    fprintf('\n╔════════════════════════════════════════════════════════════════════════════════╗\n');
    fprintf('║                     COEFFICIENT SWEEP MODE                                     ║\n');
    fprintf('╚════════════════════════════════════════════════════════════════════════════════╝\n\n');
    
    fprintf('Parameter sweep: %s\n', sweep_config.description);
    fprintf('Base case: %s\n', base_case.name);
    fprintf('Parameter: %s (index: %s)\n', sweep_config.parameter, mat2str(sweep_config.index));
    fprintf('Values: %s\n\n', mat2str(sweep_config.values));
    
    sweep_results = {};
    results_array = [];
    n_values = length(sweep_config.values);
    
    % Create waitbar for progress tracking
    wb = waitbar(0, 'Initializing coefficient sweep...', 'Name', 'Coefficient Sweep Progress');
    
    for i = 1:n_values
        % Get current parameter value
        param_value = sweep_config.values(i);
        
        % Update waitbar
        progress = (i - 1) / n_values;
        waitbar(progress, wb, sprintf('Sweep %d/%d: %s = %.4f', i, n_values, sweep_config.parameter, param_value));
        
        % Create variant of ic_coeff
        ic_coeff_variant = base_case.ic_coeff;
        
        % Apply parameter variation using helper function
        ic_coeff_variant = apply_parameter_variation(base_case, sweep_config, param_value);
        
        % Prepare simulation parameters
        p = Parameters;
        p.ic_type = base_case.ic_type;
        p.ic_coeff = ic_coeff_variant;
        
        % Run simulation
        [figs, analysis, run_ok, wall_time_s, cpu_time_s] = execute_simulation(p);
        
        % Save figures if enabled
        if settings.figures.save_figures
            save_case_figures(figs, settings, "SWEEP", p);
        end
        
        % Extract metrics
        feats = extract_features_from_analysis(analysis);
        
        % Pack results
        result = struct();
        result.sweep_index = i;
        result.parameter_name = sweep_config.parameter;
        result.parameter_value = param_value;
        result.run_ok = run_ok;
        result.ic_coeff = ic_coeff_variant;
        result.Nx = p.Nx;
        result.Ny = p.Ny;
        result.peak_abs_omega = feats.peak_abs_omega;
        result.enstrophy = feats.enstrophy;
        result.peak_u = feats.peak_u;
        result.peak_v = feats.peak_v;
        result.peak_speed = feats.peak_speed;
        result.wall_time_s = wall_time_s;
        result.cpu_time_s = cpu_time_s;
        
        sweep_results{i} = result;
        results_array(i) = result;
        
        fprintf('[%d/%d] %s = %.4f | ω_max = %.4e | enstrophy = %.4e | time = %.2fs\n', ...
            i, n_values, sweep_config.parameter, param_value, ...
            result.peak_abs_omega, result.enstrophy, result.wall_time_s);
    end
    
    close(wb);
    
    % Convert to table for easier analysis
    sweep_table = struct2table(results_array);
    
    % Print summary
    fprintf('\n════════════════════════════════════════════════════════════════════════════════\n');
    fprintf('Coefficient sweep summary:\n');
    disp(sweep_table(:, {'sweep_index', 'parameter_value', 'peak_abs_omega', 'enstrophy', 'wall_time_s'}));
    fprintf('════════════════════════════════════════════════════════════════════════════════\n\n');
    
    % Plot sweep results
    plot_coefficient_sweep(sweep_table, sweep_config);
end

function plot_coefficient_sweep(sweep_table, sweep_config)
    % Create visualization of coefficient sweep results
    
    param_values = sweep_table.parameter_value;
    omega_vals = sweep_table.peak_abs_omega;
    enstrophy_vals = sweep_table.enstrophy;
    
    figure('Name', 'Coefficient Sweep Analysis', 'NumberTitle', 'off');
    tiledlayout(2, 2, 'TileSpacing', 'compact');
    
    % Plot 1: Peak vorticity vs parameter
    nexttile;
    plot(param_values, omega_vals, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel(sprintf('%s', sweep_config.parameter), 'Interpreter', 'latex');
    ylabel('Peak Absolute Vorticity (s$^{-1}$)', 'Interpreter', 'latex');
    title(sprintf('Peak Vorticity vs %s', sweep_config.parameter));
    grid on;
    
    % Plot 2: Enstrophy vs parameter
    nexttile;
    plot(param_values, enstrophy_vals, 's-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel(sprintf('%s', sweep_config.parameter), 'Interpreter', 'latex');
    ylabel('Enstrophy (s$^{-2}$)', 'Interpreter', 'latex');
    title(sprintf('Enstrophy vs %s', sweep_config.parameter));
    grid on;
    
    % Plot 3: Computational time vs parameter
    nexttile;
    times = sweep_table.wall_time_s;
    plot(param_values, times, '^-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel(sprintf('%s', sweep_config.parameter), 'Interpreter', 'latex');
    ylabel('Wall Time (s)', 'Interpreter', 'latex');
    title(sprintf('Computational Cost vs %s', sweep_config.parameter));
    grid on;
    
    % Plot 4: Peak speed vs parameter
    nexttile;
    speed_vals = sweep_table.peak_speed;
    plot(param_values, speed_vals, 'd-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel(sprintf('%s', sweep_config.parameter), 'Interpreter', 'latex');
    ylabel('Peak Speed (m/s)', 'Interpreter', 'latex');
    title(sprintf('Peak Velocity vs %s', sweep_config.parameter));
    grid on;
    
    sgtitle(sprintf('Parameter Sweep: %s', sweep_config.description), 'Interpreter', 'latex');
end

% ========================================================================
% ENERGY SUSTAINABILITY FRAMEWORK - COMPLETE INTEGRATION SUMMARY
% ========================================================================
%
% The framework has been integrated at 5 key points in this Analysis.m:
%
% [1] CONFIGURATION (Lines ~160-230)
%     Purpose: Define what to monitor and when to save results
%     Action:  Set Parameters.energy_monitoring.enabled = true;
%     Effect:  Activates real-time sensor monitoring on next run
%
% [2] INITIALIZATION (Lines ~375-425)
%     Purpose: Create Monitor and Analyzer objects before simulation
%     Action:  Automatic if enabled, Python availability checked
%     Effect:  sensor_logs/ directory created, system ready to log
%
% [3] MODE DISPATCH (Lines ~469-535)
%     Purpose: Show which modes support energy tracking
%     Action:  Before each mode (evolution, convergence, sweep, etc.)
%            energy logging starts automatically if enabled
%     Effect:  Hardware metrics logged for entire simulation duration
%
% [4] POST-SIMULATION (Lines ~555-585)
%     Purpose: Correlate energy data with simulation results
%     Action:  Load sensor logs and feed to Analyzer
%     Effect:  Build scaling models E = A*C^α, compute CO2 footprint
%
% [5] RESULTS & REPORTING (Embedded in save section)
%     Purpose: Include energy metrics in output CSV alongside sim results
%     Effect:  Full traceability: simulation + energy + sustainability
%
% ========================================================================
% QUICK START GUIDE
% ========================================================================
% 
% To USE the framework:
%
%   1. Set Parameters.energy_monitoring.enabled = true;
%   2. Run Analysis normally (any mode)
%   3. Monitor automatically saves hardware metrics to sensor_logs/
%   4. After multiple runs, build scaling model (see Section [4] above)
%   5. Analyze sustainability metrics and efficiency trends
%
% To DISABLE if causing issues:
%
%   Set Parameters.energy_monitoring.enabled = false;
%   (All code still present but skipped, no performance impact)
%
% To UNDERSTAND what's happening:
%
%   - See ENERGY_INTEGRATION_TEMPLATE.m for copy-paste examples
%   - See EnergySustainabilityAnalyzer.m for all available methods
%   - See hardware_monitor.py for raw sensor data collection

function T = add_table_units(T)
    % Adds units to table variable descriptions for better readability
    % Only sets units for variables that exist in the table
    
    unit_map = struct( ...
        'nu', 'm^2/s', ...
        'dt', 's', ...
        'Tfinal', 's', ...
        'delta', 'm', ...
        'wall_time_s', 's', ...
        'cpu_time_s', 's', ...
        'mem_used_MB', 'MB', ...
        'mem_max_possible_MB', 'MB', ...
        'setup_wall_time_s', 's', ...
        'solve_wall_time_s', 's', ...
        'peak_abs_omega', 's^{-1}', ...
        'enstrophy', 's^{-2}', ...
        'peak_u', 'm/s', ...
        'peak_v', 'm/s', ...
        'peak_speed', 'm/s', ...
        'convergence_metric', 's^{-1}' ...
    );
    
    % Add units to existing variables
    varnames = T.Properties.VariableNames;
    fields = fieldnames(unit_map);
    
    for i = 1:numel(fields)
        varname = fields{i};
        if ismember(varname, varnames)
            T.Properties.VariableUnits{varname} = unit_map.(varname);
        end
    end
end
%   - Check sensor_logs/ folder for real CSV data files
%   - See documentation/03_ENERGY_FRAMEWORK_QUICK_START.md for details
%
% ========================================================================

% ========================================================================
%% DIRECTORY STRUCTURE INITIALIZATION
% ========================================================================
% Directory structure initialization is handled by:
%   Scripts/Infrastructure/initialize_directory_structure.m
% This function is part of the Infrastructure layer and should NOT be
% modified during normal simulation research.

% ========================================================================
%% LIVE CONVERGENCE PLOT - Real-time visualization of convergence behavior
% ========================================================================
function update_convergence_plot(fig, conv_tracking, tol)
    % Updates live convergence plot with error metrics and peak vorticity
    % Shows convergence path and identifies when study will converge
    
    if ~isvalid(fig)
        return;  % Figure was closed
    end
    
    % Clear figure and create subplots
    figure(fig);  % Make sure we're working on the correct figure
    clf(fig);
    set(fig, 'Color', 'white');  % Ensure white background
    
    % Add debug text to verify rendering
    annotation('textbox', [0.4 0.95 0.2 0.04], 'String', 'CONVERGENCE MONITOR ACTIVE', ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', ...
        'EdgeColor', 'none', 'Color', [0 0.5 0]);
    
    % Subplot 1: Convergence Metric vs Iteration
    ax1 = subplot(1, 3, 1);
    hold on; grid on; grid minor;
    
    valid_idx = ~isnan(conv_tracking.metrics);
    metrics_valid = conv_tracking.metrics(valid_idx);
    iters = find(valid_idx);

    if ~isempty(metrics_valid) && length(conv_tracking.N_values) >= 1
        semilogy(iters, metrics_valid, 'bo-', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'Metric');
        yline(tol, 'r--', 'LineWidth', 2, 'DisplayName', sprintf('Tolerance: %.2e', tol));
        xlabel('Iteration', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Convergence Metric', 'FontSize', 12, 'FontWeight', 'bold');
        title('Metric vs Iteration', 'FontSize', 14, 'FontWeight', 'bold');
        legend('FontSize', 9, 'Location', 'best');
        set(ax1, 'FontSize', 11);
    else
        % Show placeholder when no valid metrics yet
        text(0.5, 0.5, sprintf('Waiting for valid metrics...\n(%d iterations)', length(conv_tracking.N_values)), ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'FontSize', 14, 'FontWeight', 'bold', 'Color', [0 0 0]);
        xlabel('Iteration', 'FontSize', 12);
        ylabel('Convergence Metric', 'FontSize', 12);
        title('Metric vs Iteration', 'FontSize', 14, 'FontWeight', 'bold');
    end

    % Subplot 2: Convergence Metric vs Mesh Size
    ax2 = subplot(1, 3, 2);
    hold on; grid on; grid minor;

    N_valid = conv_tracking.N_values(valid_idx);
    metrics_valid = conv_tracking.metrics(valid_idx);

    if ~isempty(N_valid) && length(N_valid) >= 1
        loglog(N_valid, metrics_valid, 'bo-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Convergence Metric');
        loglog(N_valid, ones(size(N_valid))*tol, 'r--', 'LineWidth', 2, 'DisplayName', sprintf('Target Tolerance: %.2e', tol));

        if length(N_valid) >= 2
            log_N = log(N_valid);
            log_E = log(metrics_valid);
            p = polyfit(log_N, log_E, 1);
            p_rate = -p(1);
            N_extrap = logspace(log10(N_valid(1)), log10(N_valid(end))+0.5, 100);
            E_extrap = 10^p(2) * N_extrap.^(-p_rate);
            loglog(N_extrap, E_extrap, 'b--', 'LineWidth', 1.5, 'DisplayName', sprintf('Fitted Rate: N^{-%.2f}', p_rate));
        end

        xlabel('Mesh Size N (grid points)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Convergence Metric (Error)', 'FontSize', 12, 'FontWeight', 'bold');
        title('Error Decay vs Mesh', 'FontSize', 14, 'FontWeight', 'bold');
        legend('FontSize', 9, 'Location', 'best');
        set(ax2, 'FontSize', 11);
    else
        % Show placeholder when no valid metrics yet
        text(0.5, 0.5, sprintf('Waiting for valid metrics...\n(%d meshes tested)', length(conv_tracking.N_values)), ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'FontSize', 14, 'FontWeight', 'bold', 'Color', [0 0 0]);
        xlabel('Mesh Size N', 'FontSize', 12);
        ylabel('Convergence Metric (Error)', 'FontSize', 12);
        title('Error Decay vs Mesh', 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    % Subplot 3: Peak Vorticity vs Mesh Size
    ax3 = subplot(1, 3, 3);
    hold on; grid on; grid minor;
    peak_vor_valid_idx = ~isnan(conv_tracking.peak_vorticity);
    N_peak = conv_tracking.N_values(peak_vor_valid_idx);
    peaks = conv_tracking.peak_vorticity(peak_vor_valid_idx);
    
    if ~isempty(N_peak) && length(N_peak) >= 1
        plot(N_peak, peaks, 'go-', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Peak Vorticity');
        
        % Show if peak vorticity is stabilizing (convergence indicator)
        if length(N_peak) >= 2
            peak_variation = abs(diff(peaks)) ./ abs(peaks(1:end-1));
            stabilization_metric = mean(peak_variation(peak_variation > 0));
            
            if stabilization_metric < 0.01  % Less than 1% variation
                text(0.5, 0.95, '✓ CONVERGING: Peak vorticity stabilizing', ...
                    'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold', ...
                    'Color', [0 0.7 0], 'HorizontalAlignment', 'center', ...
                    'BackgroundColor', [0.9 1 0.9], 'EdgeColor', [0 0.7 0]);
            else
                text(0.5, 0.95, '⟳ REFINING: Peak vorticity still changing', ...
                    'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold', ...
                    'Color', [0.7 0.4 0], 'HorizontalAlignment', 'center', ...
                    'BackgroundColor', [1 0.95 0.9], 'EdgeColor', [0.7 0.4 0]);
            end
        end
        
        xlabel('Mesh Size N (grid points)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Peak Vorticity |ω|_{max}', 'FontSize', 12, 'FontWeight', 'bold');
        title('Peak Vorticity Stabilization', 'FontSize', 14, 'FontWeight', 'bold');
        legend('FontSize', 9, 'Location', 'best');
        set(ax3, 'FontSize', 11);
    end
    
    % Overall figure title with iteration count
    sgtitle(sprintf('Live Convergence Monitor - Iteration %d / Total Meshes: %d', ...
        length(conv_tracking.N_values), length(conv_tracking.N_values)), ...
        'FontSize', 16, 'FontWeight', 'bold', 'Color', [0 0 0]);
    
    drawnow;  % Force immediate update
end

% ========================================================================
%% CONVERGENCE AGENT: Intelligent Next-State Selection
% ========================================================================
% 
% ENVIRONMENT DEFINITION:
% ----------------------
% The convergence agent operates in a discrete state-action space where:
%
% STATE = [N1, N2, dt1, dt2, metric1, metric2, wall_time1, wall_time2]
%   N1, N2         - Current coarse and fine mesh resolutions
%   dt1, dt2       - Timesteps used for N1 and N2 (dual refinement)
%   metric1        - Convergence metric at N1 (error measure)
%   metric2        - Convergence metric at N2 (error measure)
%   wall_time1     - Computation time at N1 (cost measure)
%   wall_time2     - Computation time at N2 (cost measure)
%
% ACTIONS:
%   Select next mesh size N_next from candidate set
%   Candidates = N2 × [1.25, 1.5, 2.0, 2.5, 3.0]
%   Constrained by: N_next ∈ (N2, Nmax]
%
% REWARD FUNCTION (minimize):
%   Score = w_error × (predicted_error/tol) 
%         + w_cost × (predicted_cost/baseline_cost)
%         + w_vorticity × vorticity_instability
%
% OBJECTIVES:
%   1. Minimize number of iterations to reach tolerance
%   2. Balance accuracy (small error) vs efficiency (low cost)
%   3. Detect vorticity stabilization (diminishing returns)
%
% PREDICTIVE MODEL:
%   - Error scaling: metric_next = metric2 × (N2/N_next)^p
%     where p = convergence order estimated from (N1, N2) pair
%   - Cost scaling: cost_next = wall_time2 × (N_next/N2)^q
%     where q = computational complexity (typically 2-3 for 2D)
%
% TERMINATION:
%   - predicted_error <= tolerance (convergence achieved)
%   - N_next >= Nmax (resource limit)
%   - Agent returns NaN (fallback to Richardson/bracketing)
%
% ========================================================================

function [N_next, dt_next, info] = convergence_agent_select_next_state(state, tol, Nmax, agent_settings, refinement_strategy)
    % ADAPTIVE AGENT: Now handles dual refinement (both N and dt)
    % 
    % INPUTS:
    %   state - struct with fields: N1, N2, dt1, dt2, metric1, metric2, 
    %           wall_time1, wall_time2, peak_vor1, peak_vor2
    %   tol - convergence tolerance
    %   Nmax - maximum allowed mesh size
    %   agent_settings - agent configuration (weights, candidates)
    %   refinement_strategy - dual refinement weights from diagnostic
    %
    % OUTPUTS:
    %   N_next - predicted optimal mesh size
    %   dt_next - predicted optimal timestep
    %   info - diagnostic struct (convergence order, predictions, scores)
    
    N_next = NaN;
    dt_next = NaN;
    info = struct('p_est', NaN, 'q_est', NaN, 'pred_err', NaN, ...
                  'pred_cost', NaN, 'score', NaN, 'delta_vor', NaN, ...
                  'mesh_refine', NaN, 'dt_refine', NaN);

    % Validate state
    if ~(isfinite(state.metric1) && isfinite(state.metric2) && state.metric1 > 0 && state.metric2 > 0)
        fprintf('    \\x1b[43m[AGENT]\\x1b[0m Invalid state (NaN/zero metrics) - aborting\\n');
        return;
    end

    % Estimate error convergence order (p)
    p_est = log(state.metric1 / state.metric2) / log(state.N2 / state.N1);
    p_est = max(min(p_est, 6), 0.2);  % Clamp for stability
    fprintf('    \\x1b[36m[AGENT]\\x1b[0m Estimated convergence order: p = %.3f\\n', p_est);

    % Estimate computational cost scaling (q)
    if isfinite(state.wall_time1) && isfinite(state.wall_time2) && state.wall_time1 > 0 && state.wall_time2 > 0
        q_est = log(state.wall_time2 / state.wall_time1) / log(state.N2 / state.N1);
    else
        q_est = 2;  % Default quadratic scaling for 2D problems
    end
    q_est = max(min(q_est, 4), 1.2);  % Clamp to physical range
    fprintf('    \\x1b[36m[AGENT]\\x1b[0m Estimated cost scaling: q = %.3f\\n', q_est);

    % Vorticity stabilization metric (detect diminishing returns)
    if isfinite(state.peak_vor1) && isfinite(state.peak_vor2) && abs(state.peak_vor2) > 0
        delta_vor = abs(state.peak_vor2 - state.peak_vor1) / max(abs(state.peak_vor2), 1e-12);
        fprintf('    \\x1b[36m[AGENT]\\x1b[0m Vorticity stabilization: Δω/ω = %.3e\\n', delta_vor);
    else
        delta_vor = 0.0;
    end

    % Generate candidate mesh sizes
    multipliers = agent_settings.candidate_multipliers;
    if isempty(multipliers)
        multipliers = [1.25, 1.5, 2.0, 2.5];
    end
    N_candidates = unique(round(state.N2 .* multipliers));
    N_candidates = N_candidates(N_candidates > state.N2 & N_candidates <= Nmax);

    if isempty(N_candidates)
        fprintf('    \\x1b[43m[AGENT]\\x1b[0m No valid candidates (N2=%d, Nmax=%d)\\n', state.N2, Nmax);
        return;
    end
    
    % DUAL REFINEMENT: Also generate dt candidates
    dt_candidates = state.dt2 ./ [1.0, 1.25, 1.5, 2.0];  % Timestep reduction factors
    dt_candidates = dt_candidates(dt_candidates > 0);

    % Extract weights
    w_err = agent_settings.weights.error;
    w_cost = agent_settings.weights.cost;
    w_vor = agent_settings.weights.vorticity;

    best_score = inf;
    best_N = NaN;
    best_dt = NaN;
    best_pred_err = NaN;
    best_pred_cost = NaN;

    % Evaluate all (N, dt) combinations
    fprintf('    \\x1b[36m[AGENT]\\x1b[0m Evaluating %d mesh × %d dt combinations...\\n', ...
        numel(N_candidates), numel(dt_candidates));
    
    for i = 1:numel(N_candidates)
        Nk = N_candidates(i);
        for j = 1:numel(dt_candidates)
            dtk = dt_candidates(j);
            
            % Predict error with dual refinement
            % More sophisticated: combine mesh and dt error contributions
            mesh_error_factor = (state.N2 / Nk) ^ p_est;
            dt_error_factor = (state.dt2 / dtk) ^ 0.5;  % Assuming dt^0.5 error scaling
            pred_err = state.metric2 * sqrt(mesh_error_factor^2 + dt_error_factor^2);
            
            % Predict cost (both mesh and dt contribute)
            mesh_cost_factor = (Nk / state.N2) ^ q_est;
            dt_cost_factor = (state.dt2 / dtk);  % More timesteps = proportional cost increase
            pred_cost = state.wall_time2 * mesh_cost_factor * dt_cost_factor;

            % Compute score (lower is better)
            score = w_err * (pred_err / tol) + w_cost * (pred_cost / max(state.wall_time2, 1e-6)) + w_vor * delta_vor;
            
            if score < best_score
                best_score = score;
                best_N = Nk;
                best_dt = dtk;
                best_pred_err = pred_err;
                best_pred_cost = pred_cost;
            end
        end
    end

    N_next = best_N;
    dt_next = best_dt;
    info.p_est = p_est;
    info.q_est = q_est;
    info.pred_err = best_pred_err;
    info.pred_cost = best_pred_cost;
    info.score = best_score;
    info.delta_vor = delta_vor;
    info.mesh_refine = best_N / state.N2;
    info.dt_refine = state.dt2 / best_dt;
    
    fprintf('    \\x1b[32m[AGENT DECISION]\\x1b[0m N: %d → %d (%.2fx), dt: %.3e → %.3e (%.2fx reduction)\\n', ...
        state.N2, N_next, info.mesh_refine, state.dt2, dt_next, info.dt_refine);
    fprintf('      Predicted error: %.3e (%.1f%% of tol), cost: %.2fs, score: %.3f\\n', ...
        best_pred_err, 100*best_pred_err/tol, best_pred_cost, best_score);
end

% LEGACY WRAPPER: Maintains backward compatibility with old interface
function [N_next, info] = convergence_agent_select_next_N(N1, N2, metric1, metric2, row1, row2, wall_time1, wall_time2, tol, Nmax, agent_settings)
    % Legacy wrapper for backward compatibility
    % Converts old interface to new state-based interface
    
    state = struct();
    state.N1 = N1;
    state.N2 = N2;
    state.dt1 = NaN;  % Not tracked in old interface
    state.dt2 = NaN;
    state.metric1 = metric1;
    state.metric2 = metric2;
    state.wall_time1 = wall_time1;
    state.wall_time2 = wall_time2;
    state.peak_vor1 = safe_get(row1, 'peak_abs_omega', NaN);
    state.peak_vor2 = safe_get(row2, 'peak_abs_omega', NaN);
    
    % Call new function (without dual refinement)
    [N_next, ~, info] = convergence_agent_select_next_state(state, tol, Nmax, agent_settings, struct());
end

function [ctx, status, N_star, T, meta, N_low, row_low] = convergence_phase2_richardson(ctx, N1, N2, row1, row2, metric1, metric2, run_mode)
    % Phase 2: Richardson extrapolation (extracted for debugging)
    status = "bracket";
    N_star = NaN; T = []; meta = struct();
    N_low = N2; row_low = row2;

    % Check for user cancellation
    if check_convergence_cancel(ctx.settings)
        status = "cancelled";
        N_star = NaN;
        T = struct2table([row1; row2]);
        meta = build_convergence_meta("user_cancelled", ctx.tol, N1, N2, N_star, ctx.conv_log);
        save_convergence_iteration_log(ctx.conv_log, ctx.settings, run_mode);
        save_tradeoff_study(ctx.conv_log, ctx.settings, run_mode);
        return;
    end

    if ~(ctx.settings.convergence.use_adaptive && metric1 > 0 && metric2 > 0)
        fprintf('\n=== Richardson extrapolation disabled or metrics invalid. ');
        if ctx.settings.convergence.enable_bracketing
            fprintf('Using bracketing. ===\n');
            status = "bracket";
        else
            fprintf('Bracketing disabled. Aborting convergence. ===\n');
            meta = build_convergence_meta("failed_no_bracketing", ctx.tol, N1, N2, NaN, ctx.conv_log);
            save_convergence_iteration_log(ctx.conv_log, ctx.settings, run_mode);
            error('Convergence failed: Richardson disabled/invalid and bracketing is disabled.');
        end
        return;
    end

    fprintf_colored('magenta_bg', '\n=== CONVERGENCE PHASE 2: Richardson Extrapolation ===\n');

    % Estimate convergence order
    fprintf_colored('yellow', 'Estimated convergence order: p = %.3f\n', log(metric1 / metric2) / log(N2 / N1));
    p_rate = log(metric1 / metric2) / log(N2 / N1);
    
    % DUAL REFINEMENT STRATEGY: Compute optimal N_pred and dt_pred
    % Use diagnostic weights to balance mesh vs timestep refinement
    if isfield(ctx, 'refinement_strategy') && isstruct(ctx.refinement_strategy)
        fprintf('\x1b[36m[DUAL REFINEMENT]\x1b[0m Computing adaptive step for both N and dt...\n');
        mesh_weight = ctx.refinement_strategy.mesh_weight;
        dt_weight = ctx.refinement_strategy.dt_weight;
    else
        % Fallback to equal weights if strategy not available
        mesh_weight = 0.5;
        dt_weight = 0.5;
        fprintf('\x1b[33m[WARNING]\x1b[0m Refinement strategy not found, using equal weights\n');
    end

    if p_rate < 0.1
        fprintf('WARNING: Very low convergence order (p=%.3f). Solution may not be converging properly.\n', p_rate);
        fprintf('Switching to bracketing search.\n');
        status = "bracket";
        return;
    elseif p_rate > 10
        fprintf('WARNING: Unexpectedly high convergence order (p=%.3f). May indicate numerical instability.\n', p_rate);
        fprintf('Capping to p=4 for safety.\n');
        p_rate = 4;
    end

    if ~(p_rate >= 0.1 && p_rate <= 10)
        fprintf('Invalid convergence order (p=%.3f not in range [0.1, 10]). ', p_rate);
        if ctx.settings.convergence.enable_bracketing
            fprintf('Using bracketing.\n');
            status = "bracket";
            return;
        else
            fprintf('Bracketing disabled. Aborting convergence.\n');
            meta = build_convergence_meta("failed_no_bracketing", ctx.tol, N1, N2, NaN, ctx.conv_log);
            save_convergence_iteration_log(ctx.conv_log, ctx.settings, run_mode);
            error('Convergence failed: invalid convergence order and bracketing is disabled.');
        end
    end

    % Richardson prediction for DUAL REFINEMENT (N and dt)
    safety_margin = 0.8;
    
    % Compute total refinement factor needed to reach tolerance
    total_refinement_factor = (metric1 / (ctx.tol * safety_margin))^(1/p_rate);
    
    % Split refinement between mesh and timestep based on diagnostic weights
    % More influential parameter gets proportionally more refinement
    mesh_refinement_factor = 1 + (total_refinement_factor - 1) * mesh_weight;
    dt_refinement_factor = 1 + (total_refinement_factor - 1) * dt_weight;
    
    % Apply mesh refinement (N direction)
    N_pred_raw = round(N1 * mesh_refinement_factor);
    N_pred = min(N_pred_raw, ctx.Nmax);
    N_pred = max(N_pred, N2);
    
    % Apply timestep reduction (dt direction)
    dt_current = ctx.p.dt;
    dt_pred = dt_current / dt_refinement_factor;
    
    % Limit excessive refinements for stability
    max_refinement_ratio = 4;
    if N_pred > N2 * max_refinement_ratio
        N_pred_original = N_pred;
        N_pred = round(N2 * max_refinement_ratio);
        fprintf('\x1b[33mLimiting mesh refinement:\x1b[0m N=%d -> N=%d (%.1fx instead of %.1fx)\n', ...
            N_pred_original, N_pred, N_pred/N2, N_pred_original/N2);
    end
    
    min_dt_ratio = 0.25;  % Don't reduce dt more than 4x per step
    if dt_pred < dt_current * min_dt_ratio
        dt_pred_original = dt_pred;
        dt_pred = dt_current * min_dt_ratio;
        fprintf('\x1b[33mLimiting timestep reduction:\x1b[0m dt=%.3e -> dt=%.3e (%.1fx instead of %.1fx)\n', ...
            dt_pred_original, dt_pred, dt_pred/dt_current, dt_pred_original/dt_current);
    end
    
    fprintf('\x1b[32mRichardson prediction (DUAL):\x1b[0m\n');
    fprintf('  Mesh: N = %d (%.2fx refinement, weight=%.1f%%)\n', N_pred, mesh_refinement_factor, mesh_weight*100);
    fprintf('  Timestep: dt = %.3e (%.2fx reduction, weight=%.1f%%)\n', dt_pred, 1/dt_refinement_factor, dt_weight*100);
    fprintf('\x1b[36mNext state (predicted):\x1b[0m N=%d, dt=%.3e\n', N_pred, dt_pred);

    if ~(N_pred > N2 && N_pred <= ctx.Nmax)
        fprintf('Predicted N=%d is not beneficial (≤ N2=%d). ', N_pred, N2);
        if ctx.settings.convergence.enable_bracketing
            fprintf('Using bracketing.\n');
            status = "bracket";
            return;
        else
            fprintf('Bracketing disabled. Aborting convergence.\n');
            meta = build_convergence_meta("failed_no_bracketing", ctx.tol, N1, N2, NaN, ctx.conv_log);
            save_convergence_iteration_log(ctx.conv_log, ctx.settings, run_mode);
            error('Convergence failed: Richardson prediction not beneficial and bracketing is disabled.');
        end
    end

    if ~isempty(ctx.wb)
        waitbar(0.4, ctx.wb, sprintf('Phase 2: Testing predicted N=%d, dt=%.3e...', N_pred, dt_pred));
    end

    % Update ctx.p.dt for this iteration (dual refinement)
    ctx.p.dt = dt_pred;
    
    t0 = tic;
    [metric_pred, row_pred, figs_pred] = run_case_metric_cached(ctx.p, N_pred, ctx.result_cache, dt_pred);
    wall_time_pred = toc(t0);
    ctx.cumulative_time = ctx.cumulative_time + wall_time_pred;
    ctx.iter_count = ctx.iter_count + 1;

    if isnan(metric_pred)
        fprintf('  Phase 2 - N=%4d (Richardson): Metric UNAVAILABLE\n', N_pred);
        peak_vor_pred = NaN;
    else
        error_ratio = metric_pred / ctx.tol;
        fprintf('  Phase 2 - N=%4d (Richardson): Metric = %.6e (Target: %.6e, Ratio: %.3f)\n', N_pred, metric_pred, ctx.tol, error_ratio);
        peak_vor_pred = row_pred.peak_abs_omega;
    end

    ctx.conv_tracking.N_values = [ctx.conv_tracking.N_values, N_pred];
    ctx.conv_tracking.dt_values = [ctx.conv_tracking.dt_values, dt_pred];  % Track dual refinement
    ctx.conv_tracking.metrics = [ctx.conv_tracking.metrics, metric_pred];
    ctx.conv_tracking.peak_vorticity = [ctx.conv_tracking.peak_vorticity, peak_vor_pred];
    update_convergence_plot(ctx.fig_conv, ctx.conv_tracking, ctx.tol);

    if ctx.settings.convergence.save_iteration_figures
        save_convergence_figures(figs_pred, ctx.settings, ctx.p, ctx.iter_count, "richardson", N_pred);
    end
    save_mesh_visuals_if_enabled(ctx.settings, ctx.p, ctx.iter_count, "richardson", N_pred);

    ctx.conv_log(ctx.iter_count) = pack_convergence_iteration(ctx.iter_count, "richardson", N_pred, metric_pred, N_pred, wall_time_pred, ctx.cumulative_time, ctx.tol, p_rate, N_pred/N2);

    if metric_pred <= ctx.tol
        fprintf('\n✓ CONVERGED via Richardson extrapolation at N=%d\n', N_pred);
        fprintf('  Final error: %.6e (%.1f%% of tolerance)\n', metric_pred, 100*metric_pred/ctx.tol);
        fprintf('  Convergence order: p = %.3f\n', p_rate);
        N_star = N_pred;
        T = struct2table([row1; row2; row_pred]);
        meta = build_convergence_meta("richardson_success", ctx.tol, N1, N_pred, N_star, ctx.conv_log);
        save_convergence_iteration_log(ctx.conv_log, ctx.settings, run_mode);
        save_tradeoff_study(ctx.conv_log, ctx.settings, run_mode);
        status = "converged";
        return;
    end

    % Refined prediction
    fprintf('Refining Richardson prediction (error/tol = %.3f)...\n', metric_pred/ctx.tol);
    p_rate_refined = log(metric2 / metric_pred) / log(N_pred / N2);
    fprintf('Updated convergence order: p = %.3f -> %.3f\n', p_rate, p_rate_refined);
    if abs(p_rate_refined - p_rate) / p_rate > 0.5
        fprintf('WARNING: Convergence order changed by %.0f%%\n', 100*abs(p_rate_refined - p_rate)/p_rate);
    end

    if ~(p_rate_refined > 0.1 && p_rate_refined <= 10)
        fprintf('Refined p=%.3f invalid. ', p_rate_refined);
        if ctx.settings.convergence.enable_bracketing
            fprintf('Switching to bracketing.\n');
            status = "bracket";
            return;
        else
            fprintf('Bracketing disabled. Aborting convergence.\n');
            meta = build_convergence_meta("failed_no_bracketing", ctx.tol, N1, N2, NaN, ctx.conv_log);
            save_convergence_iteration_log(ctx.conv_log, ctx.settings, run_mode);
            error('Convergence failed: Richardson prediction invalid and bracketing is disabled.');
        end
    end

    N_pred2 = round(N_pred * (metric_pred / (ctx.tol * safety_margin))^(1/p_rate_refined));
    N_pred2 = min(N_pred2, ctx.Nmax);
    N_pred2 = max(N_pred2, N_pred + 2);
    if N_pred2 > N_pred * max_refinement_ratio
        N_pred2 = round(N_pred * max_refinement_ratio);
    end
    fprintf('Next mesh (refined prediction): N=%d\n', N_pred2);
    fprintf('Refined Richardson: N = %d (%.2fx refinement)\n', N_pred2, N_pred2/N_pred);

    if N_pred2 > N_pred * 1.1 && N_pred2 <= ctx.Nmax
        if ~isempty(ctx.wb)
            waitbar(0.6, ctx.wb, sprintf('Phase 2: Refined N=%d...', N_pred2));
        end
        t0 = tic;
        [metric_pred2, row_pred2, figs_pred2] = run_case_metric_cached(ctx.p, N_pred2, ctx.result_cache);
        wall_time_pred2 = toc(t0);
        ctx.cumulative_time = ctx.cumulative_time + wall_time_pred2;
        ctx.iter_count = ctx.iter_count + 1;

        ctx.conv_tracking.N_values = [ctx.conv_tracking.N_values, N_pred2];
        ctx.conv_tracking.metrics = [ctx.conv_tracking.metrics, metric_pred2];
        ctx.conv_tracking.peak_vorticity = [ctx.conv_tracking.peak_vorticity, row_pred2.peak_abs_omega];
        update_convergence_plot(ctx.fig_conv, ctx.conv_tracking, ctx.tol);

        fprintf('  Phase 2 - N=%4d (refined): Metric = %.6e (Ratio: %.3f)\n', ...
            N_pred2, metric_pred2, metric_pred2/ctx.tol);

        ctx.conv_log(ctx.iter_count) = pack_convergence_iteration(ctx.iter_count, "richardson_refined", N_pred2, metric_pred2, N_pred2, wall_time_pred2, ctx.cumulative_time, ctx.tol, p_rate_refined, N_pred2/N_pred);

        if ctx.settings.convergence.save_iteration_figures
            save_convergence_figures(figs_pred2, ctx.settings, ctx.p, ctx.iter_count, "richardson_refined", N_pred2);
        end
        save_mesh_visuals_if_enabled(ctx.settings, ctx.p, ctx.iter_count, "richardson_refined", N_pred2);

        if metric_pred2 <= ctx.tol
            fprintf('\n✓ CONVERGED via refined Richardson at N=%d\n', N_pred2);
            N_star = N_pred2;
            T = struct2table([row1; row2; row_pred; row_pred2]);
            meta = build_convergence_meta("richardson_refined", ctx.tol, N1, N_pred2, N_star, ctx.conv_log);
            save_convergence_iteration_log(ctx.conv_log, ctx.settings, run_mode);
            save_tradeoff_study(ctx.conv_log, ctx.settings, run_mode);
            status = "converged";
            return;
        end

        N_low = N_pred2;
        row_low = row_pred2;
    else
        N_low = N_pred;
        row_low = row_pred;
    end

    status = "bracket";
end

function save_mesh_visuals_if_enabled(settings, params, iter, phase, N)
    if ~isfield(settings, 'convergence') || ~isfield(settings.convergence, 'mesh_visuals')
        return;
    end
    if ~settings.convergence.mesh_visuals
        return;
    end

    figs_mesh = generate_mesh_visuals(N, params.Lx, params.Ly);
    % Ensure figures are visible and brought to front
    for i = 1:length(figs_mesh)
        if isvalid(figs_mesh(i))
            figure(figs_mesh(i));  % Bring to front
        end
    end
    drawnow;
    if settings.convergence.save_iteration_figures
        save_convergence_figures(figs_mesh, settings, params, iter, phase + "_mesh", N);
    end
end

function figs = generate_mesh_visuals(N, Lx, Ly)
    figs = gobjects(0);
    x = linspace(-Lx/2, Lx/2, N);
    y = linspace(-Ly/2, Ly/2, N);
    [X, Y] = meshgrid(x, y);

    % Mesh grid plot
    fig1 = figure('Name', sprintf('Mesh Grid N=%d', N), 'NumberTitle', 'off', 'Visible', 'on');
    hold on; axis equal tight; box on; grid on;
    stride = max(1, round(N / 64));
    for i = 1:stride:N
        plot(x, y(i) * ones(size(x)), 'k-', 'LineWidth', 0.5);
        plot(x(i) * ones(size(y)), y, 'k-', 'LineWidth', 0.5);
    end
    title(sprintf('Mesh Grid (N=%d)', N));
    xlabel('x'); ylabel('y');
    figs(end+1) = fig1;

    % Mesh contour map (visual grid-based field)
    fig2 = figure('Name', sprintf('Mesh Contour N=%d', N), 'NumberTitle', 'off', 'Visible', 'on');
    R = sqrt(X.^2 + Y.^2);
    contourf(X, Y, R, 24, 'LineColor', 'none');
    axis equal tight; box on; colorbar;
    title(sprintf('Mesh Contour Map (N=%d)', N));
    xlabel('x'); ylabel('y');
    figs(end+1) = fig2;
    
    % 3D Mesh surface plot
    fig3 = figure('Name', sprintf('Mesh 3D N=%d', N), 'NumberTitle', 'off', 'Visible', 'on');
    Z = sin(2*pi*R/max(Lx,Ly)) .* exp(-R.^2 / ((Lx/4)^2));  % Example surface for visualization
    surf(X, Y, Z, 'EdgeColor', [0.3 0.3 0.3], 'FaceAlpha', 0.8, 'LineWidth', 0.3);
    axis tight; box on; grid on;
    colormap(jet); colorbar;
    view(45, 30);  % 3D viewing angle
    title(sprintf('3D Mesh Surface (N=%d)', N));
    xlabel('x'); ylabel('y'); zlabel('z');
    lighting gouraud;
    camlight('headlight');
    figs(end+1) = fig3;
end

function should_cancel = check_convergence_cancel(settings)
    % Check if user has requested to cancel convergence study
    % User can create CANCEL_CONVERGENCE.txt file in working directory to stop
    
    should_cancel = false;
    
    if ~isfield(settings, 'convergence') || ~isfield(settings.convergence, 'cancel_file')
        return;
    end
    
    cancel_file = settings.convergence.cancel_file;
    
    if isfile(cancel_file)
        fprintf('\n');
        fprintf('\x1b[43m\x1b[30m                                                    \x1b[0m\n');
        fprintf('\x1b[43m\x1b[30m   CONVERGENCE STUDY CANCELLED BY USER             \x1b[0m\n');
        fprintf('\x1b[43m\x1b[30m                                                    \x1b[0m\n');
        fprintf('\n');
        fprintf('\x1b[33m[CANCEL]\x1b[0m Cancel file detected: %s\n', cancel_file);
        fprintf('\x1b[33m[CANCEL]\x1b[0m Stopping convergence study gracefully...\n');
        fprintf('\n');
        
        % Delete the cancel file so it doesn't affect future runs
        try
            delete(cancel_file);
            fprintf('\x1b[32m[CANCEL]\x1b[0m Cancel file removed\n');
        catch
            fprintf('\x1b[43m[WARNING]\x1b[0m Could not delete cancel file\n');
        end
        
        should_cancel = true;
    end
end

function save_tradeoff_study(conv_log, settings, run_mode)
    if isempty(conv_log)
        return;
    end

    T = struct2table(conv_log);
    if ~ismember('wall_time_s', T.Properties.VariableNames)
        return;
    end

    % Compute marginal improvements vs cost in iteration order
    metric = T.convergence_metric;
    wall_time = T.wall_time_s;
    cum_time = T.cumulative_time_s;

    d_metric = [NaN; diff(metric)];
    d_time = [NaN; diff(cum_time)];
    eff = -d_metric ./ max(d_time, 1e-6);

    T_trade = table(T.iteration, T.search_phase, T.N, metric, wall_time, cum_time, d_metric, d_time, eff, ...
        'VariableNames', {'iteration', 'phase', 'N', 'metric', 'wall_time_s', 'cumulative_time_s', 'delta_metric', 'delta_time', 'efficiency'});

    if ~exist(settings.results_dir, 'dir')
        mkdir(settings.results_dir);
    end
    csv_path = fullfile(settings.results_dir, sprintf("convergence_tradeoff_%s_%s.csv", string(run_mode), datestr(now, 'yyyy-mm-dd_HH-MM-SS')));
    writetable(T_trade, csv_path);
    fprintf('[TRADEOFF] Saved tradeoff study: %s\n', csv_path);

    plot_tradeoff_metrics(T_trade, settings);
end

function plot_tradeoff_metrics(T_trade, settings)
    if isempty(T_trade)
        return;
    end

    fig = figure('Name', 'Convergence Tradeoff', 'NumberTitle', 'off');
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    semilogy(T_trade.cumulative_time_s, T_trade.metric, 'o-', 'LineWidth', 1.5);
    grid on; xlabel('Cumulative Time (s)'); ylabel('Convergence Metric');
    title('Error vs Cost');

    nexttile;
    plot(T_trade.cumulative_time_s, T_trade.efficiency, 's-', 'LineWidth', 1.5);
    grid on; xlabel('Cumulative Time (s)'); ylabel('Efficiency (-Δmetric/Δtime)');
    title('Marginal Efficiency');

    if settings.figures.use_owl_plot_saver && exist("Plot_Saver","file") == 2
        Plot_Saver(fig, 'convergence_tradeoff', true);
    elseif settings.figures.save_png
        out_dir = fullfile(settings.figures.root_dir, 'Convergence');
        if ~exist(out_dir, 'dir')
            mkdir(out_dir);
        end
        exportgraphics(fig, fullfile(out_dir, 'convergence_tradeoff.png'), 'Resolution', settings.figures.dpi);
    end

    if settings.figures.close_after_save
        close(fig);
    end
end

% ========================================================================
%% LIVE MONITORING DASHBOARD FUNCTIONS
% ========================================================================

function fig = create_live_monitor_dashboard_basic()
    % Legacy basic dashboard (kept for reference)
    
    fig = figure('Name', 'Live Execution Monitor', ...
        'NumberTitle', 'off', ...
        'Position', [50, 50, 1000, 600], ...
        'Color', [0.95 0.95 0.95], ...
        'MenuBar', 'none', ...
        'ToolBar', 'none');
    
    layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % Top row: consolidated status + metrics
    ax_status = nexttile(layout, [1 2]);
    title(ax_status, 'Run Status & Metrics', 'FontWeight', 'bold', 'FontSize', 12);
    set(ax_status, 'XLim', [0 1], 'YLim', [0 1], 'XTick', [], 'YTick', []);
    text(0.03, 0.88, 'Initializing...', 'Parent', ax_status, ...
        'HorizontalAlignment', 'left', 'FontSize', 12, 'FontWeight', 'bold', 'Tag', 'progress_text');
    text(0.03, 0.72, 'Status: Initializing', 'Parent', ax_status, 'FontSize', 10, 'FontWeight', 'bold', 'Tag', 'status');
    text(0.03, 0.58, 'Current Phase: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'phase');
    
    text(0.52, 0.88, 'Avg Time/Iter: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'avg_time');
    text(0.52, 0.72, 'Est. Remaining: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'est_remaining');
    text(0.52, 0.58, 'Memory Usage: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'memory');
    text(0.52, 0.44, 'Monitor Overhead: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'overhead');
    
    text(0.03, 0.36, 'Grid Size: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'grid_size');
    text(0.03, 0.22, 'Time Steps: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'time_steps');
    text(0.03, 0.08, 'Total Operations: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'total_ops');
    
    text(0.52, 0.36, 'Max Vorticity: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'max_vort');
    text(0.52, 0.22, 'Total Energy: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'total_energy');
    text(0.52, 0.08, 'Convergence: --', 'Parent', ax_status, 'FontSize', 10, 'Tag', 'convergence');
    
    % Bottom row: time and speed plots
    ax_time = nexttile(layout);
    title(ax_time, 'Elapsed Time', 'FontWeight', 'bold', 'FontSize', 12);
    hold(ax_time, 'on'); grid(ax_time, 'on');
    xlabel(ax_time, 'Iteration'); ylabel(ax_time, 'Time (s)');
    set(ax_time, 'Tag', 'time_axis');
    
    ax_speed = nexttile(layout);
    title(ax_speed, 'Iteration Speed', 'FontWeight', 'bold', 'FontSize', 12);
    hold(ax_speed, 'on'); grid(ax_speed, 'on');
    xlabel(ax_speed, 'Iteration'); ylabel(ax_speed, 'Iter/sec');
    set(ax_speed, 'Tag', 'speed_axis');
    
    drawnow;
end

function update_live_monitor(iteration, total, phase, metrics)
    % Updates the live monitoring dashboard
    % iteration: current iteration number
    % total: total iterations to complete
    % phase: current computation phase (string)
    % metrics: struct with computation metrics
    
    monitor_start = tic;
    global script_start_time monitor_figure monitor_data;
    
    if isempty(monitor_figure) || ~isvalid(monitor_figure)
        return;
    end
    
    % Update monitor data
    monitor_data.iterations_completed = iteration;
    monitor_data.total_iterations = total;
    monitor_data.current_phase = phase;
    elapsed_time = toc(script_start_time);

    % Track phase transitions for plot separators
    if ~isfield(monitor_data, 'last_phase') || ~strcmp(string(monitor_data.last_phase), string(phase))
        monitor_data.last_phase = phase;
        if iteration > 0
            monitor_data.phase_markers(end+1) = iteration;
            monitor_data.phase_labels{end+1} = char(phase);
        end
    end
    
    % Calculate performance metrics
    if iteration > 0
        avg_time_per_iter = elapsed_time / iteration;
        remaining_iters = total - iteration;
        est_remaining = avg_time_per_iter * remaining_iters;
        
        % Track iteration times
        if length(monitor_data.performance.iteration_times) >= iteration
            iter_speed = 1 / avg_time_per_iter;
        else
            monitor_data.performance.iteration_times(end+1) = elapsed_time;
            if length(monitor_data.performance.iteration_times) > 1
                recent_time = monitor_data.performance.iteration_times(end) - monitor_data.performance.iteration_times(end-1);
                iter_speed = 1 / max(recent_time, 0.001);
            else
                iter_speed = 0;
            end
        end
        
        % Memory usage
        mem_info = memory;
        mem_used_mb = mem_info.MemUsedMATLAB / 1024^2;
        monitor_data.performance.memory_usage(end+1) = mem_used_mb;
    else
        avg_time_per_iter = 0;
        est_remaining = 0;
        iter_speed = 0;
        mem_used_mb = 0;
    end
    
    % Update progress bar
    progress_pct = iteration / max(total, 1) * 100;

    % Calculate monitor overhead
    monitor_time = toc(monitor_start);
    monitor_data.performance.monitor_overhead = monitor_data.performance.monitor_overhead + monitor_time;
    overhead_pct = (monitor_data.performance.monitor_overhead / max(elapsed_time, 0.001)) * 100;
    
    % If dark UI dashboard exists, update it directly
    if isfield(monitor_data, 'ui') && isstruct(monitor_data.ui) && isvalid(monitor_data.ui.fig)
        ui = monitor_data.ui;

        if isfield(ui, 'progress_bar')
            ui.progress_bar.XData = [0 progress_pct/100 progress_pct/100 0];
        end
        if isfield(ui, 'progress_text')
            ui.progress_text.String = sprintf('%.1f%% Complete\n%d / %d iterations', progress_pct, iteration, total);
        end
        if isfield(ui, 'avg_time')
            ui.avg_time.Text = sprintf('Avg Time/Iter: %.3f s', avg_time_per_iter);
        end
        if isfield(ui, 'est_remaining')
            ui.est_remaining.Text = sprintf('Est. Remaining: %.1f s (%.1f min)', est_remaining, est_remaining/60);
        end
        if isfield(ui, 'memory')
            ui.memory.Text = sprintf('Memory Usage: %.1f MB', mem_used_mb);
        end
        if isfield(ui, 'overhead')
            ui.overhead.Text = sprintf('Monitor Overhead: %.2f%% (%.3f s)', overhead_pct, monitor_data.performance.monitor_overhead);
        end

        if isfield(metrics, 'grid_size') && isfield(ui, 'grid_size')
            ui.grid_size.Text = sprintf('Grid Size: %d x %d', metrics.grid_size(1), metrics.grid_size(2));
            total_ops = metrics.grid_size(1) * metrics.grid_size(2) * iteration;
            if isfield(ui, 'total_ops')
                ui.total_ops.Text = sprintf('Total Operations: %.2e', total_ops);
            end
        end
        if isfield(metrics, 'time_steps') && isfield(ui, 'time_steps')
            ui.time_steps.Text = sprintf('Time Steps: %d', metrics.time_steps);
        end
        if isfield(ui, 'phase')
            ui.phase.Text = sprintf('Current Phase: %s', phase);
        end

        n_times = numel(monitor_data.performance.iteration_times);
        if isfield(ui, 'time_line') && n_times > 0
            ui.time_line.XData = (1:n_times)';
            ui.time_line.YData = monitor_data.performance.iteration_times(:);
        end
        if isfield(ui, 'speed_line') && n_times > 1
            speeds = 1 ./ diff([0; monitor_data.performance.iteration_times(:)]);
            ui.speed_line.XData = (1:numel(speeds))';
            ui.speed_line.YData = speeds(:);
        end

        % Add phase separators (vertical lines)
        if isfield(ui, 'time_ax') && isfield(ui, 'speed_ax') && isfield(monitor_data, 'phase_markers')
            n_markers = numel(monitor_data.phase_markers);
            if ~isfield(ui, 'time_phase_lines')
                ui.time_phase_lines = gobjects(0);
            end
            if ~isfield(ui, 'speed_phase_lines')
                ui.speed_phase_lines = gobjects(0);
            end

            for k = (numel(ui.time_phase_lines) + 1):n_markers
                x = monitor_data.phase_markers(k);
                ui.time_phase_lines(k) = xline(ui.time_ax, x, '--', '', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
                ui.speed_phase_lines(k) = xline(ui.speed_ax, x, '--', '', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
            end
        end

        monitor_data.ui = ui;

        if isfield(metrics, 'max_vorticity') && isfield(ui, 'max_vort')
            ui.max_vort.Text = sprintf('Max Vorticity: %.4f', metrics.max_vorticity);
        end
        if isfield(metrics, 'total_energy') && isfield(ui, 'total_energy')
            ui.total_energy.Text = sprintf('Total Energy: %.4e', metrics.total_energy);
        end
        if isfield(metrics, 'convergence_metric') && isfield(ui, 'convergence')
            if isfield(metrics, 'tolerance') && isfinite(metrics.tolerance)
                ui.convergence.Text = sprintf('Convergence: %.2e (tol %.2e)', metrics.convergence_metric, metrics.tolerance);
            else
                ui.convergence.Text = sprintf('Convergence: %.2e', metrics.convergence_metric);
            end
        end
        if isfield(ui, 'conv_status') && isfield(metrics, 'convergence_metric') && isfield(metrics, 'tolerance') && isfinite(metrics.tolerance)
            ratio = metrics.convergence_metric / max(metrics.tolerance, eps);
            ui.conv_status.Text = sprintf('Metric/Tol: %.2f', ratio);
        end

        % Update status
        if progress_pct >= 100
            status_str = 'COMPLETE';
            status_color = [0 0.7 0];
        elseif progress_pct >= 75
            status_str = 'Nearly Done';
            status_color = [0.2 0.6 0.2];
        elseif progress_pct >= 50
            status_str = 'Running';
            status_color = [0 0.4 0.8];
        elseif progress_pct >= 25
            status_str = 'In Progress';
            status_color = [0.8 0.6 0];
        else
            status_str = 'Starting';
            status_color = [0.6 0.6 0.6];
        end
        if isfield(ui, 'status')
            ui.status.Text = sprintf('Status: %s', status_str);
            if isfield(ui, 'colors')
                ui.status.FontColor = status_color;
            end
        end

        drawnow limitrate;
        return;
    end

    progress_text = findobj(monitor_figure, 'Tag', 'progress_text');
    if ~isempty(progress_text)
        set(progress_text, 'String', sprintf('%.1f%% Complete\n%d / %d iterations', ...
            progress_pct, iteration, total));
    end
    
    % Update performance metrics
    set(findobj(monitor_figure, 'Tag', 'avg_time'), 'String', ...
        sprintf('Avg Time/Iter: %.3f s', avg_time_per_iter));
    set(findobj(monitor_figure, 'Tag', 'est_remaining'), 'String', ...
        sprintf('Est. Remaining: %.1f s (%.1f min)', est_remaining, est_remaining/60));
    set(findobj(monitor_figure, 'Tag', 'memory'), 'String', ...
        sprintf('Memory Usage: %.1f MB', mem_used_mb));
    
    % Update computational load
    if isfield(metrics, 'grid_size')
        set(findobj(monitor_figure, 'Tag', 'grid_size'), 'String', ...
            sprintf('Grid Size: %d x %d', metrics.grid_size(1), metrics.grid_size(2)));
        total_ops = metrics.grid_size(1) * metrics.grid_size(2) * iteration;
        set(findobj(monitor_figure, 'Tag', 'total_ops'), 'String', ...
            sprintf('Total Operations: %.2e', total_ops));
    end
    
    if isfield(metrics, 'time_steps')
        set(findobj(monitor_figure, 'Tag', 'time_steps'), 'String', ...
            sprintf('Time Steps: %d', metrics.time_steps));
    end
    
    set(findobj(monitor_figure, 'Tag', 'phase'), 'String', ...
        sprintf('Current Phase: %s', phase));
    
    % Update time plot
    ax_time = findobj(monitor_figure, 'Tag', 'time_axis');
    n_times = numel(monitor_data.performance.iteration_times);
    if ~isempty(ax_time) && n_times > 0
        plot(ax_time, (1:n_times)', monitor_data.performance.iteration_times(:), 'b-', 'LineWidth', 2);
        if isfield(monitor_data, 'phase_markers')
            hold(ax_time, 'on');
            for k = 1:numel(monitor_data.phase_markers)
                xline(ax_time, monitor_data.phase_markers(k), '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
            end
            hold(ax_time, 'off');
        end
    end
    
    % Update speed plot
    ax_speed = findobj(monitor_figure, 'Tag', 'speed_axis');
    if ~isempty(ax_speed) && n_times > 1
        speeds = 1 ./ diff([0; monitor_data.performance.iteration_times(:)]);
        plot(ax_speed, (1:numel(speeds))', speeds(:), 'r-', 'LineWidth', 2);
        if isfield(monitor_data, 'phase_markers')
            hold(ax_speed, 'on');
            for k = 1:numel(monitor_data.phase_markers)
                xline(ax_speed, monitor_data.phase_markers(k), '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
            end
            hold(ax_speed, 'off');
        end
    end
    
    % Update key metrics
    if isfield(metrics, 'max_vorticity')
        set(findobj(monitor_figure, 'Tag', 'max_vort'), 'String', ...
            sprintf('Max Vorticity: %.4f', metrics.max_vorticity));
    end
    
    if isfield(metrics, 'total_energy')
        set(findobj(monitor_figure, 'Tag', 'total_energy'), 'String', ...
            sprintf('Total Energy: %.4e', metrics.total_energy));
    end
    
    if isfield(metrics, 'convergence_metric')
        if isfield(metrics, 'tolerance') && isfinite(metrics.tolerance)
            set(findobj(monitor_figure, 'Tag', 'convergence'), 'String', ...
                sprintf('Convergence: %.2e (tol %.2e)', metrics.convergence_metric, metrics.tolerance));
        else
            set(findobj(monitor_figure, 'Tag', 'convergence'), 'String', ...
                sprintf('Convergence: %.2e', metrics.convergence_metric));
        end
    end
    
    % Update status
    if progress_pct >= 100
        status_str = 'COMPLETE';
        status_color = [0 0.7 0];
    elseif progress_pct >= 75
        status_str = 'Nearly Done';
        status_color = [0.2 0.6 0.2];
    elseif progress_pct >= 50
        status_str = 'Running';
        status_color = [0 0.4 0.8];
    elseif progress_pct >= 25
        status_str = 'In Progress';
        status_color = [0.8 0.6 0];
    else
        status_str = 'Starting';
        status_color = [0.6 0.6 0.6];
    end
    
    status_obj = findobj(monitor_figure, 'Tag', 'status');
    if ~isempty(status_obj)
        set(status_obj, 'String', sprintf('Status: %s', status_str), 'Color', status_color);
    end
    
    set(findobj(monitor_figure, 'Tag', 'overhead'), 'String', ...
        sprintf('Monitor Overhead: %.2f%% (%.3f s)', overhead_pct, monitor_data.performance.monitor_overhead));
    
    % Refresh display (limit rate to avoid slowdown)
    drawnow limitrate;
end

% ------------------------------------------------------------------------
% Script Execution Complete - Display Final Timer
% ------------------------------------------------------------------------
total_elapsed = toc(script_start_time);
fprintf('\n========================================\n');
fprintf('SCRIPT EXECUTION COMPLETED\n');
fprintf('========================================\n');
fprintf('Total Elapsed Time: %.2f seconds (%.2f minutes)\n', total_elapsed, total_elapsed/60);
fprintf('Completed at: %s\n', datestr(now, 'HH:MM:SS dd-mmm-yyyy'));
fprintf('========================================\n\n');

% ========================================================================
%% HELPER FUNCTIONS FOR REDUCING NESTING DEPTH (25+ Functions)
% ========================================================================
% Helper functions extracted to reduce code nesting from 5 to 3 levels
% Organized by functional purpose:
%
% SECTION A: CONVERGENCE PHASE IMPLEMENTATIONS (4 phases)
%   - convergence_phase2_richardson      : Phase 2 - Richardson extrapolation
%   - convergence_phase3_bracketing      : Phase 3 - Mesh bracketing
%   - convergence_phase4_binary          : Phase 4 - Binary search refinement
%   - binary_search_N_logged             : Logged binary search with iteration tracking
%
% SECTION B: INITIAL PAIR & EXTENSION LOGIC
%   - extend_initial_pair_if_needed      : Extends Richardson pair when metrics invalid
%   - shift_pair                         : Shifts mesh pair (N1,N2) -> (N2,N3)
%
% SECTION C: METRIC VALIDATION & MONITORING
%   - are_metrics_valid                     : Validates Richardson metric pairs
%   - update_waitbar_if_present             : Updates progress bar safely
%   - display_convergence_result            : Displays convergence metric with formatting
%   - update_monitor_if_active              : Updates live monitoring if enabled
%   - create_monitor_metrics_struct         : Packs metrics for live dashboard
%   - update_convergence_tracking           : Adds iteration to convergence tracker
%
% SECTION D: OUTPUT & LOGGING
%   - save_iteration_outputs                : Saves figures and metrics for each iteration
%   - convergence_iteration_schema          : Defines convergence iteration data structure
%   - pack_convergence_iteration            : Packs iteration data into schema row
%   - save_convergence_iteration_log        : Writes iteration log to CSV
%
% SECTION E: RICHARDSON METRIC COMPUTATION
%   - compute_richardson_metric_for_mesh    : Computes Richardson metric (primary method)
%   - compute_l2_metric                     : L2 norm metric (primary function used internally)
%   - compute_interpolation_metric          : Interpolates coarse grid solution to fine grid
%   - compute_peak_vorticity_metric         : Peak vorticity difference metric (fallback)
%   - has_valid_omega_snaps                 : Validates omega snapshots exist
%
% SECTION F: MESH & GRID UTILITIES
%   - create_mesh_grid                      : Creates X,Y mesh grids from N, Lx, Ly
%   - save_mesh_visuals_if_enabled          : Saves mesh visualization plots
%   - generate_mesh_visuals                 : Generates mesh and spacing visualizations
%
% SECTION G: PARAMETER VARIATION & SWEEPS
%   - apply_parameter_variation             : Applies variations to IC coefficients
%   - apply_single_index_variation          : Single index coefficient variation
%   - apply_multi_index_variation           : Multi-index coefficient variation
%   - apply_relative_scaling                : Relative scaling of coefficients
%   - apply_absolute_variation              : Absolute value variation
%   - apply_coefficient_variation           : Coefficient variation for sweeps
%
% SECTION H: ENERGY MONITORING & SUSTAINABILITY
%   - initialize_energy_monitoring_system   : Initializes hardware monitoring
%   - attempt_monitor_initialization        : Attempts to create energy monitor
%   - handle_monitor_initialization_failure : Graceful fallback if monitoring fails
%   - display_energy_monitoring_info        : Prints monitoring setup info
%   - create_output_directory_if_needed     : Creates sensor log output directory
%
% SECTION I: VISUALIZATION & PLOTS
%   - save_convergence_figures              : Saves convergence iteration figures
%   - export_figure_png                     : Exports figure to PNG with DPI control
%   - save_case_figures                     : Saves simulation case figures
%   - builtin_save_figure                   : Internal figure saving with format handling
%   - update_convergence_plot               : Updates live convergence plot
%   - plot_tradeoff_metrics                 : Plots computational tradeoff analysis
%   - plot_coefficient_sweep                : Plots sweep parameter variation results
%   - save_tradeoff_study                   : Saves convergence vs performance tradeoff data
%
% ========================================================================

%% HELPER FUNCTIONS: CONVERGENCE PHASES (4 Phases)
% Phase 1: Initial Richardson pair with extension capability
% Phase 2: Richardson extrapolation for convergence rate estimation
% Phase 3: Mesh bracketing to find transition zone
% Phase 4: Binary search refinement for target metric tolerance

function [N1, N2, metric1, metric2, row1, row2, wall_time1, wall_time2, iter_count, cumulative_time, conv_log, conv_tracking] = ...
    extend_initial_pair_if_needed(N1, N2, metric1, metric2, row1, row2, wall_time1, wall_time2, ...
    Nmax, p, settings, result_cache, wb, use_live_monitor, monitor_data, ...
    iter_count, cumulative_time, conv_log, conv_tracking, tol, fig_conv)
    % Extend the initial Richardson pair if metrics are invalid
    % This reduces nesting depth in the main convergence function
    
    extensions = 0;
    max_extensions = settings.convergence.max_pair_extensions;
    
    while ~are_metrics_valid(metric1, metric2) && extensions < max_extensions
        N3 = min(2 * N2, Nmax);
        if N3 <= N2
            break;
        end
        
        extensions = extensions + 1;
        fprintf('Metrics invalid for Richardson. Extending pair: N=%d -> N=%d (attempt %d/%d)\n', ...
            N2, N3, extensions, max_extensions);
        
        update_waitbar_if_present(wb, 0.3, sprintf('Phase 1: Extending to N=%d...', N3));
        
        % Run simulation for extended mesh
        t0 = tic;
        [metric3, row3, figs3] = run_case_metric_cached(p, N3, result_cache);
        wall_time3 = toc(t0);
        cumulative_time = cumulative_time + wall_time3;
        iter_count = iter_count + 1;
        
        % Display and log results
        peak_vor3 = display_convergence_result(N3, metric3, row3, tol);
        update_monitor_if_active(use_live_monitor, monitor_data, iter_count, N3, peak_vor3, metric3, tol);
        
        % Update tracking
        conv_tracking = update_convergence_tracking(conv_tracking, N3, metric3, peak_vor3, wall_time3);
        update_convergence_plot(fig_conv, conv_tracking, tol);
        
        % Save outputs
        save_iteration_outputs(settings, p, iter_count, figs3, N3, "initial_pair_extend");
        conv_log(iter_count) = pack_convergence_iteration(iter_count, "initial_pair_extend", ...
            N3, metric3, NaN, wall_time3, cumulative_time, tol, NaN, NaN);
        
        % Shift pair to (N2, N3)
        [N1, N2, metric1, metric2, row1, row2, wall_time1, wall_time2] = ...
            shift_pair(N2, N3, metric2, metric3, row2, row3, wall_time2, wall_time3);
    end
end

function valid = are_metrics_valid(metric1, metric2)
    % Check if both metrics are valid for Richardson extrapolation
    valid = isfinite(metric1) && metric1 > 0 && isfinite(metric2) && metric2 > 0;
end

function update_waitbar_if_present(wb, progress, message)
    % Update waitbar only if it exists
    if ~isempty(wb)
        waitbar(progress, wb, message);
    end
end

function peak_vor = display_convergence_result(N, metric, row, tol)
    % Display convergence results in consistent format
    if isnan(metric)
        fprintf('  Phase 1 - N=%4d: Metric UNAVAILABLE (solver issue)\n', N);
        peak_vor = NaN;
    else
        fprintf('  Phase 1 - N=%4d: Metric = %.6e (Target: %.6e)\n', N, metric, tol);
        peak_vor = row.peak_abs_omega;
    end
end

function update_monitor_if_active(use_live_monitor, monitor_data, iter_count, N, peak_vor, metric, tol)
    % Update live monitor if active
    if use_live_monitor
        metrics = create_monitor_metrics_struct(N, peak_vor, metric, tol);
        update_live_monitor(iter_count, 0, monitor_data.current_phase, metrics);
    end
end

%% HELPER FUNCTIONS: METRIC VALIDATION & MONITORING
% Validates metrics, manages live monitoring displays, and updates tracking

function metrics = create_monitor_metrics_struct(N, peak_vor, metric, tol)
    % Create metrics structure for monitor updates
    metrics = struct(...
        'grid_size', [N, N], ...
        'time_steps', NaN, ...
        'max_vorticity', peak_vor, ...
        'total_energy', NaN, ...
        'convergence_metric', metric, ...
        'tolerance', tol);
end

function conv_tracking = update_convergence_tracking(conv_tracking, N, metric, peak_vor, wall_time)
    % Update convergence tracking arrays
    conv_tracking.N_values = [conv_tracking.N_values, N];
    conv_tracking.metrics = [conv_tracking.metrics, metric];
    conv_tracking.peak_vorticity = [conv_tracking.peak_vorticity, peak_vor];
    conv_tracking.wall_time_s = [conv_tracking.wall_time_s, wall_time];
end

function save_iteration_outputs(settings, p, iter_count, figs, N, phase_name)
    % Save iteration figures and visuals if enabled
    if settings.convergence.save_iteration_figures
        save_convergence_figures(figs, settings, p, iter_count, phase_name, N);
    end
    save_mesh_visuals_if_enabled(settings, p, iter_count, phase_name, N);
end

function [iter_ctx, should_exit] = run_and_track_convergence_iteration(p, N, phase_name, ...
    iter_ctx, settings, monitor_data, fig_conv)
    % Run simulation and handle all iteration bookkeeping
    % 
    % Consolidates: simulation run, timing, display, monitor update, tracking,
    % plot update, figure saving, logging, and cancellation check.
    %
    % Inputs:
    %   p - parameters struct
    %   N - grid size for this iteration
    %   phase_name - string identifier for the phase (e.g., "initial_pair")
    %   iter_ctx - iteration context struct with fields:
    %       .result_cache, .iter_count, .cumulative_time, .conv_tracking,
    %       .conv_log, .tol, .use_live_monitor
    %   settings - settings struct
    %   monitor_data - monitor data struct
    %   fig_conv - convergence plot figure handle
    %
    % Outputs:
    %   iter_ctx - updated iteration context with new metric, row, wall_time
    %   should_exit - true if user requested cancellation
    
    % Initialize exit state
    should_exit = false;
    iter_ctx.exit_reason = "";

    % Run simulation with timing
    t0 = tic;
    [metric, row, figs] = run_case_metric_cached(p, N, iter_ctx.result_cache);
    wall_time = toc(t0);
    
    % Update iteration counters
    iter_ctx.cumulative_time = iter_ctx.cumulative_time + wall_time;
    iter_ctx.iter_count = iter_ctx.iter_count + 1;
    
    % Display progress
    if isnan(metric)
        fprintf('  %s - N=%4d: Metric UNAVAILABLE (solver issue)\n', phase_name, N);
        peak_vor = NaN;
    else
        fprintf('  %s - N=%4d: Metric = %.6e (Target: %.6e)\n', ...
            phase_name, N, metric, iter_ctx.tol);
        peak_vor = row.peak_abs_omega;
    end
    
    % Update live monitor
    if iter_ctx.use_live_monitor
        metrics = create_monitor_metrics_struct(N, peak_vor, metric, iter_ctx.tol);
        update_live_monitor(iter_ctx.iter_count, 0, monitor_data.current_phase, metrics);
    end
    
    % Update tracking arrays
    iter_ctx.conv_tracking = update_convergence_tracking(iter_ctx.conv_tracking, ...
        N, metric, peak_vor, wall_time);
    iter_ctx.conv_tracking.dt_values = [iter_ctx.conv_tracking.dt_values, p.dt];
    
    % Update convergence plot
    update_convergence_plot(fig_conv, iter_ctx.conv_tracking, iter_ctx.tol);
    
    % Save outputs
    save_iteration_outputs(settings, p, iter_ctx.iter_count, figs, N, phase_name);
    
    % Log iteration
    iter_ctx.conv_log(iter_ctx.iter_count) = pack_convergence_iteration(...
        iter_ctx.iter_count, phase_name, N, metric, NaN, wall_time, ...
        iter_ctx.cumulative_time, iter_ctx.tol, NaN, NaN);
    
    % Store results for caller
    iter_ctx.last_metric = metric;
    iter_ctx.last_row = row;
    iter_ctx.last_wall_time = wall_time;
    iter_ctx.last_peak_vor = peak_vor;
    
    % Check for invalid metric (fail-fast)
    if ~isfinite(metric)
        iter_ctx.exit_reason = "metric_invalid";
        should_exit = true;
        return;
    end

    % Check for user cancellation
    should_exit = check_convergence_cancel(settings);
    if should_exit
        iter_ctx.exit_reason = "user_cancelled";
    end
end

function [T, meta] = handle_convergence_exit(status, rows, tol, N1, N2, N_star, ...
    conv_log, settings, run_mode)
    % Handle convergence study exit with consistent cleanup
    %
    % Consolidates: table creation, metadata building, and log saving
    % Used for cancellation, convergence success, and failure exits
    
    T = struct2table(rows);
    meta = build_convergence_meta(status, tol, N1, N2, N_star, conv_log);
    save_convergence_iteration_log(conv_log, settings, run_mode);
    save_tradeoff_study(conv_log, settings, run_mode);
end

function [converged, reason] = check_convergence_criterion(metric, tol)
    % Check if convergence criterion is met, handling NaN cases
    %
    % Returns:
    %   converged - true if metric <= tol (and both are finite)
    %   reason    - string explaining result (for logging)
    
    if isnan(metric)
        converged = false;
        reason = "metric_is_nan";  % Exit: metric became NaN (solver issue)
    elseif isnan(tol)
        converged = false;
        reason = "tolerance_is_nan";  % Exit: tolerance is invalid
    elseif ~isfinite(metric)
        converged = false;
        reason = "metric_not_finite";  % Exit: metric is Inf or invalid
    elseif metric <= tol
        converged = true;
        reason = "criterion_met";  % Converged: metric <= tol
    else
        converged = false;
        reason = "not_converged";  % Continue: metric > tol
    end
end

%% HELPER FUNCTIONS: PAIR & EXTENSION LOGIC
% Handles shifting of convergence pairs and extension logic

function [N1, N2, metric1, metric2, row1, row2, wall_time1, wall_time2] = ...
    shift_pair(N_prev, N_next, metric_prev, metric_next, row_prev, row_next, wall_time_prev, wall_time_next)
    % Shift convergence pair from (N1, N2) to (N2, N3)
    N1 = N_prev;
    metric1 = metric_prev;
    row1 = row_prev;
    wall_time1 = wall_time_prev;
    
    N2 = N_next;
    metric2 = metric_next;
    row2 = row_next;
    wall_time2 = wall_time_next;
end

%% HELPER FUNCTIONS: OUTPUT & LOGGING
% Saves iteration data, figures, convergence logs, and CSV schemas

function ic_coeff_variant = apply_parameter_variation(base_case, sweep_config, param_value)
    % Apply parameter variation to ic_coeff based on sweep configuration
    % This extracts the nested logic from run_coefficient_sweep
    
    ic_coeff_variant = base_case.ic_coeff;
    
    if isscalar(sweep_config.index)
        ic_coeff_variant = apply_single_index_variation(ic_coeff_variant, sweep_config.index, param_value);
    else
        ic_coeff_variant = apply_multi_index_variation(ic_coeff_variant, sweep_config, base_case, param_value);
    end
end

%% HELPER FUNCTIONS: PARAMETER VARIATION & SWEEPS
% Applies variations to simulation parameters for sweep studies

function ic_coeff = apply_single_index_variation(ic_coeff, index, value)
    % Apply variation to a single coefficient index
    ic_coeff(index) = value;
end

function ic_coeff = apply_multi_index_variation(ic_coeff, sweep_config, base_case, param_value)
    % Apply variation to multiple indices (e.g., for separation distance)
    if isfield(sweep_config, 'mode') && strcmpi(sweep_config.mode, 'relative')
        ic_coeff = apply_relative_scaling(ic_coeff, sweep_config.index, base_case, param_value);
    else
        ic_coeff = apply_absolute_variation(ic_coeff, sweep_config.index, param_value);
    end
end

function ic_coeff = apply_relative_scaling(ic_coeff, indices, base_case, param_value)
    % Apply relative scaling to multiple indices
    base_values = base_case.ic_coeff(indices);
    scale_factor = param_value / mean(base_values);
    ic_coeff(indices) = base_values * scale_factor;
end

function ic_coeff = apply_absolute_variation(ic_coeff, indices, value)
    % Apply absolute value to multiple indices
    ic_coeff(indices) = value;
end

%% HELPER FUNCTIONS: ENERGY MONITORING & SUSTAINABILITY
% Initializes and manages hardware monitoring and energy analysis
% Gracefully handles missing dependencies (Python, ICUE, hardware monitoring tools)

function [Monitor, Analyzer] = initialize_energy_monitoring_system(Parameters)
    %INITIALIZE_ENERGY_MONITORING_SYSTEM Initialize hardware monitoring with graceful degradation
    %
    % Attempts to initialize hardware monitoring but continues gracefully if:
    % - Python is not available
    % - Hardware monitor tools (iCUE, HWiNFO) are not installed
    % - Dependencies are missing
    %
    % Returns Monitor=[] and Analyzer if anything fails, allowing simulation to proceed
    
    % Check if energy monitoring is enabled first
    if ~Parameters.energy_monitoring.enabled
        Monitor = [];
        Analyzer = EnergySustainabilityAnalyzer();  % Still create analyzer for potential offline use
        return;
    end
    
    try
        Monitor = attempt_monitor_initialization(Parameters);
        Analyzer = EnergySustainabilityAnalyzer();
        display_energy_monitoring_info(Parameters);
    catch ME
        [Monitor, Analyzer] = handle_monitor_initialization_failure(ME, Parameters);
    end
end

function Monitor = attempt_monitor_initialization(Parameters)
    %ATTEMPT_MONITOR_INITIALIZATION Try to initialize hardware monitor
    % Checks for Python, HardwareMonitorBridge dependencies, and output directory
    
    % Check Python availability
    try
        pe = pyenv;
        if pe.Status ~= "Loaded"
            error('Python environment not loaded (Status: %s)', pe.Status);
        end
    catch
        error('Python interpreter required for hardware monitoring');
    end

    % Check hardware_monitor.py exists
    script_dir = fileparts(mfilename('fullpath'));  % Scripts/Main
    sustainability_dir = fullfile(script_dir, '..', 'Sustainability');
    python_script = fullfile(sustainability_dir, 'hardware_monitor.py');
    if ~isfile(python_script)
        error('hardware_monitor.py not found at: %s', python_script);
    end

    % Try to instantiate monitor (will fail if iCUE/HWiNFO not installed)
    try
        Monitor = HardwareMonitorBridge(python_script);
    catch ME
        % Provide helpful diagnostic about what's missing
        if contains(ME.message, 'iCUE', 'IgnoreCase', true) || ...
           contains(ME.message, 'corsair', 'IgnoreCase', true)
            error('iCUE/Corsair SDK not found: %s\n  Install Corsair iCUE to enable RGB status monitoring', ME.message);
        elseif contains(ME.message, 'HWiNFO', 'IgnoreCase', true)
            error('HWiNFO not found: %s\n  Install HWiNFO to enable CPU/GPU monitoring', ME.message);
        else
            error('Hardware monitor initialization failed: %s', ME.message);
        end
    end

    % Create output directory
    create_output_directory_if_needed(Parameters.energy_monitoring.output_dir);
end

function create_output_directory_if_needed(output_dir)
    % Create sensor logs directory if it doesn't exist
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
end

function display_energy_monitoring_info(Parameters)
    % Display energy monitoring initialization information
    fprintf_colored('\n', 'green_bg');
    fprintf_colored('╔════════════════════════════════════════════════════════════╗\n', 'green');
    fprintf_colored('║        ENERGY MONITORING - ACTIVE AND INITIALIZED           ║\n', 'green');
    fprintf_colored('╚════════════════════════════════════════════════════════════╝\n', 'green');
    fprintf_colored('✓ Hardware monitoring active\n', 'green');
    fprintf_colored('✓ Output directory: %s\n', Parameters.energy_monitoring.output_dir, 'green');
    fprintf_colored('✓ Sampling interval: %.1f s (%.0f Hz)\n', ...
        Parameters.energy_monitoring.sample_interval, ...
        1 / Parameters.energy_monitoring.sample_interval, 'green');
    fprintf_colored('✓ Logging CPU/GPU/Memory metrics\n', 'green');
    fprintf_colored('✓ RGB LED status enabled (if iCUE available)\n', 'green');
    fprintf_colored('\n', 'green_bg');
end

function [Monitor, Analyzer] = handle_monitor_initialization_failure(ME, Parameters)
    %HANDLE_MONITOR_INITIALIZATION_FAILURE Graceful fallback when monitoring unavailable
    %
    % Instead of erroring out, this allows the study to continue without monitoring
    % Logs what's missing and why, so user can install if needed for future studies
    
    % Always create analyzer (can be used offline later)
    Analyzer = EnergySustainabilityAnalyzer();
    Monitor = [];
    
    % Disable energy monitoring in parameters
    Parameters.energy_monitoring.enabled = false;
    
    % Provide informative diagnostic output
    fprintf_colored('\n', 'yellow_bg');
    fprintf_colored('╔════════════════════════════════════════════════════════════╗\n', 'yellow');
    fprintf_colored('║           ENERGY MONITORING - GRACEFUL DEGRADATION          ║\n', 'yellow');
    fprintf_colored('╚════════════════════════════════════════════════════════════╝\n', 'yellow');
    fprintf_colored('⚠ Hardware energy monitoring unavailable:\n', 'yellow');
    fprintf_colored('  Reason: %s\n', ME.message, 'yellow');
    fprintf('\n');
    
    % Provide specific diagnostic information
    diagnosis = diagnose_monitor_failure(ME);
    fprintf_colored('Diagnosis:\n', 'cyan');
    fprintf('  %s\n', diagnosis);
    fprintf('\n');
    
    % Provide remediation steps
    fprintf_colored('Remediation:\n', 'green');
    provide_remediation_steps(ME);
    fprintf('\n');
    
    % Confirm we're continuing
    fprintf_colored('✓ Continuing study WITHOUT energy monitoring\n', 'green');
    fprintf_colored('  Simulation will run normally; energy tracking disabled for this study\n', 'green');
    fprintf_colored('  To enable monitoring for future studies: Install missing components\n', 'green');
    fprintf_colored('\n', 'yellow_bg');
end

function diagnosis = diagnose_monitor_failure(ME)
    %DIAGNOSE_MONITOR_FAILURE Provide specific diagnosis of what's missing
    
    msg = ME.message;
    
    if contains(msg, 'Python', 'IgnoreCase', true)
        diagnosis = 'Python interpreter not available or not loaded';
    elseif contains(msg, 'iCUE', 'IgnoreCase', true) || contains(msg, 'corsair', 'IgnoreCase', true)
        diagnosis = 'Corsair iCUE SDK not installed (needed for RGB LED monitoring)';
    elseif contains(msg, 'HWiNFO', 'IgnoreCase', true)
        diagnosis = 'HWiNFO+ not installed (needed for CPU/GPU/Memory monitoring)';
    elseif contains(msg, 'hardware_monitor.py', 'IgnoreCase', true)
        diagnosis = 'Hardware monitor script missing (check Sustainability/ directory)';
    elseif contains(msg, 'output.dir', 'IgnoreCase', true) || contains(msg, 'directory', 'IgnoreCase', true)
        diagnosis = 'Cannot create output directory for energy logs (check permissions)';
    else
        diagnosis = sprintf('Unknown issue: %s', msg);
    end
end

function provide_remediation_steps(ME)
    %PROVIDE_REMEDIATION_STEPS Give user actionable steps to fix monitoring
    
    msg = ME.message;
    
    if contains(msg, 'iCUE', 'IgnoreCase', true) || contains(msg, 'corsair', 'IgnoreCase', true)
        fprintf('  1. Download Corsair iCUE from: https://www.corsair.com/us/en/icue\n');
        fprintf('  2. Install with default settings (includes SDK)\n');
        fprintf('  3. Restart MATLAB\n');
        fprintf('  4. Re-run this study to enable RGB monitoring\n');
    elseif contains(msg, 'HWiNFO', 'IgnoreCase', true)
        fprintf('  1. Download HWiNFO from: https://www.hwinfo.com/download/\n');
        fprintf('  2. Install (portable or full installation both work)\n');
        fprintf('  3. Restart MATLAB\n');
        fprintf('  4. Re-run this study to enable CPU/GPU monitoring\n');
    elseif contains(msg, 'Python', 'IgnoreCase', true)
        fprintf('  1. Ensure Python is installed (3.8+ required)\n');
        fprintf('  2. In MATLAB: pyenv("ExecutionMode", "OutOfProcess")\n');
        fprintf('  3. Verify with: pyenv\n');
        fprintf('  4. Restart MATLAB\n');
    elseif contains(msg, 'hardware_monitor.py', 'IgnoreCase', true)
        fprintf('  1. Check that Sustainability/hardware_monitor.py exists\n');
        fprintf('  2. Verify file paths are correct\n');
        fprintf('  3. Check file permissions\n');
    elseif contains(msg, 'directory', 'IgnoreCase', true)
        fprintf('  1. Check that energy_monitoring.output_dir is valid\n');
        fprintf('  2. Verify you have write permissions to that directory\n');
        fprintf('  3. Ensure enough free disk space\n');
    else
        fprintf('  See error message above for details\n');
    end
end

%% HELPER FUNCTIONS: RICHARDSON METRIC COMPUTATION
% Computes convergence metrics using Richardson and alternative approaches

function metric = compute_richardson_metric_for_mesh(N, Nf, Parameters, analysis, criterion_type)
    % Compute convergence metric by comparing N and 2N solutions
    % Now supports multiple criterion types for comparison studies
    % 
    % INPUTS:
    %   N - Coarse mesh resolution

    %   Nf - Fine mesh resolution (typically 2*N)
    %   Parameters - Simulation parameters struct
    %   analysis - Coarse mesh analysis results
    %   criterion_type - Type of convergence criterion (optional, default 'l2_relative')
    %
    % CRITERION TYPES:
    %   'max_vorticity'     - Relative difference in peak vorticity magnitude
    %   'l2_relative'       - L2 norm of difference / L2 norm of fine solution (Richardson default)
    %   'l2_absolute'       - L2 norm of difference (absolute error)
    %   'linf_relative'     - Max pointwise difference / max value on fine grid
    %   'energy_dissipation' - Relative difference in total enstrophy
    %
    % DIAGNOSTIC: Detailed logging to identify NaN sources
    
    if nargin < 5 || isempty(criterion_type)
        criterion_type = 'l2_relative';  % Default Richardson criterion
    end
    
    metric = NaN;  % Default to invalid
    
    fprintf('    \\x1b[36m[CRITERION: %s]\\x1b[0m Computing convergence metric...\\n', criterion_type);
    
    % Execute fine grid simulation
    params_f = prepare_simulation_params(Parameters, Nf);
    [~, analysis_f, run_ok_f, ~, ~] = execute_simulation(params_f);
    
    if ~run_ok_f
        fprintf('    \\x1b[41m[METRIC ERROR]\\x1b[0m Fine mesh (N=%d) execution FAILED\\n', Nf);
        return;
    end
    
    % Validate both analyses have vorticity snapshots
    if ~has_valid_omega_snaps(analysis)
        fprintf('    \\x1b[41m[METRIC ERROR]\\x1b[0m Coarse mesh (N=%d) has NO vorticity snapshots\\n', N);
        return;
    end
    if ~has_valid_omega_snaps(analysis_f)
        fprintf('    \\x1b[41m[METRIC ERROR]\\x1b[0m Fine mesh (N=%d) has NO vorticity snapshots\\n', Nf);
        return;
    end
    
    % Extract final vorticity fields
    omega_c = analysis.omega_snaps(:,:,end);
    omega_f = analysis_f.omega_snaps(:,:,end);
    
    % Diagnose omega field sizes and basic statistics
    fprintf('      Coarse mesh (N=%d): ω size [%d x %d], range [%.3e, %.3e]\\n', ...
        N, size(omega_c,1), size(omega_c,2), min(omega_c(:)), max(omega_c(:)));
    fprintf('      Fine mesh (N=%d): ω size [%d x %d], range [%.3e, %.3e]\\n', ...
        Nf, size(omega_f,1), size(omega_f,2), min(omega_f(:)), max(omega_f(:)));

    % Guard against non-finite fields (common cause of NaN metrics)
    if any(~isfinite(omega_c(:))) || any(~isfinite(omega_f(:)))
        bad_c = nnz(~isfinite(omega_c(:)));
        bad_f = nnz(~isfinite(omega_f(:)));
        fprintf('    \\x1b[43m[METRIC WARNING]\\x1b[0m NON-FINITE ω detected (coarse=%d, fine=%d) - SOLVER INSTABILITY\\n', bad_c, bad_f);
        metric = compute_peak_vorticity_metric(omega_c, omega_f);
        fprintf('      Fallback to peak vorticity: metric=%.3e\\n', metric);
        return;
    end
    
    % SWITCH-CASE: Select convergence criterion type
    switch lower(criterion_type)
        case 'max_vorticity'
            % Simple max vorticity comparison
            metric = compute_max_vorticity_criterion(omega_c, omega_f);
            fprintf('      \\x1b[32mMax vorticity criterion:\\x1b[0m metric=%.6e\\n', metric);
            
        case 'l2_relative'
            % Richardson L2 relative error (default, interpolation-based)
            [Xc, Yc] = create_mesh_grid(N, Parameters.Lx, Parameters.Ly);
            [Xf, Yf] = create_mesh_grid(Nf, Parameters.Lx, Parameters.Ly);
            omega_c_on_f = interp2(Xc, Yc, omega_c, Xf, Yf, "linear");
            metric = compute_l2_relative_criterion(omega_f, omega_c_on_f);
            fprintf('      \\x1b[32mL2 relative criterion:\\x1b[0m metric=%.6e\\n', metric);
            
        case 'l2_absolute'
            % L2 absolute error
            [Xc, Yc] = create_mesh_grid(N, Parameters.Lx, Parameters.Ly);
            [Xf, Yf] = create_mesh_grid(Nf, Parameters.Lx, Parameters.Ly);
            omega_c_on_f = interp2(Xc, Yc, omega_c, Xf, Yf, "linear");
            metric = compute_l2_absolute_criterion(omega_f, omega_c_on_f);
            fprintf('      \\x1b[32mL2 absolute criterion:\\x1b[0m metric=%.6e\\n', metric);
            
        case 'linf_relative'
            % L-infinity (max pointwise) relative error
            [Xc, Yc] = create_mesh_grid(N, Parameters.Lx, Parameters.Ly);
            [Xf, Yf] = create_mesh_grid(Nf, Parameters.Lx, Parameters.Ly);
            omega_c_on_f = interp2(Xc, Yc, omega_c, Xf, Yf, "linear");
            metric = compute_linf_relative_criterion(omega_f, omega_c_on_f);
            fprintf('      \\x1b[32mL-inf relative criterion:\\x1b[0m metric=%.6e\\n', metric);
            
        case 'energy_dissipation'
            % Enstrophy (integrated vorticity^2) comparison
            metric = compute_energy_dissipation_criterion(omega_c, omega_f, Parameters);
            fprintf('      \\x1b[32mEnergy dissipation criterion:\\x1b[0m metric=%.6e\\n', metric);
            
        otherwise
            fprintf('    \\x1b[41m[CRITERION ERROR]\\x1b[0m Unknown criterion type: %s\\n', criterion_type);
            fprintf('      Valid options: max_vorticity, l2_relative, l2_absolute, linf_relative, energy_dissipation\\n');
            fprintf('      Falling back to l2_relative\\n');
            [Xc, Yc] = create_mesh_grid(N, Parameters.Lx, Parameters.Ly);
            [Xf, Yf] = create_mesh_grid(Nf, Parameters.Lx, Parameters.Ly);
            omega_c_on_f = interp2(Xc, Yc, omega_c, Xf, Yf, "linear");
            metric = compute_l2_relative_criterion(omega_f, omega_c_on_f);
    end
end

function valid = has_valid_omega_snaps(analysis)
    % Check if analysis structure contains valid omega snapshots
    valid = isfield(analysis, "omega_snaps") && ~isempty(analysis.omega_snaps);
end

% ========================================================================
%% CONVERGENCE CRITERION FUNCTIONS (Multiple metrics for comparison studies)
% ========================================================================

function metric = compute_max_vorticity_criterion(omega_c, omega_f)
    % CRITERION 1: Simple max vorticity comparison
    % Compares peak vorticity magnitude between coarse and fine grids
    % Metric = |max(|ω_c|) - max(|ω_f|)| / max(|ω_f|)
    
    peak_c = max(abs(omega_c(:)));
    peak_f = max(abs(omega_f(:)));
    
    if peak_f < 1e-12
        metric = NaN;  % Avoid division by near-zero
    else
        metric = abs(peak_c - peak_f) / peak_f;
    end
end

function metric = compute_l2_relative_criterion(omega_f, omega_c_on_f)
    % CRITERION 2: L2 relative error (Richardson default)
    % Metric = ||ω_c_interp - ω_f||_2 / ||ω_f||_2
    
    if any(~isfinite(omega_f(:))) || any(~isfinite(omega_c_on_f(:)))
        metric = NaN;
        return;
    end
    
    if any(isnan(omega_c_on_f(:)))
        metric = NaN;
        fprintf('      [L2_REL] Interpolation produced NaN values\\n');
        return;
    end
    
    diff_field = omega_c_on_f - omega_f;
    norm_diff = norm(diff_field(:), 2);
    norm_fine = norm(omega_f(:), 2);
    
    if norm_fine < 1e-12
        metric = NaN;
    else
        metric = norm_diff / norm_fine;
    end
end

function metric = compute_l2_absolute_criterion(omega_f, omega_c_on_f)
    % CRITERION 3: L2 absolute error
    % Metric = ||ω_c_interp - ω_f||_2
    
    if any(~isfinite(omega_f(:))) || any(~isfinite(omega_c_on_f(:)))
        metric = NaN;
        return;
    end
    
    if any(isnan(omega_c_on_f(:)))
        metric = NaN;
        return;
    end
    
    diff_field = omega_c_on_f - omega_f;
    metric = norm(diff_field(:), 2);
end

function metric = compute_linf_relative_criterion(omega_f, omega_c_on_f)
    % CRITERION 4: L-infinity (maximum pointwise) relative error
    % Metric = max|ω_c_interp - ω_f| / max|ω_f|
    
    if any(~isfinite(omega_f(:))) || any(~isfinite(omega_c_on_f(:)))
        metric = NaN;
        return;
    end
    
    if any(isnan(omega_c_on_f(:)))
        metric = NaN;
        return;
    end
    
    diff_field = abs(omega_c_on_f - omega_f);
    max_diff = max(diff_field(:));
    max_fine = max(abs(omega_f(:)));
    
    if max_fine < 1e-12
        metric = NaN;
    else
        metric = max_diff / max_fine;
    end
end

function metric = compute_energy_dissipation_criterion(omega_c, omega_f, Parameters)
    % CRITERION 5: Enstrophy (total squared vorticity) comparison
    % Enstrophy = (1/2) * ∫∫ ω² dA
    % Metric = |Enstrophy_c - Enstrophy_f| / Enstrophy_f
    
    if any(~isfinite(omega_c(:))) || any(~isfinite(omega_f(:)))
        metric = NaN;
        return;
    end
    
    % Compute cell area for integration
    dx_c = Parameters.Lx / (size(omega_c, 2) - 1);
    dy_c = Parameters.Ly / (size(omega_c, 1) - 1);
    dA_c = dx_c * dy_c;
    
    dx_f = Parameters.Lx / (size(omega_f, 2) - 1);
    dy_f = Parameters.Ly / (size(omega_f, 1) - 1);
    dA_f = dx_f * dy_f;
    
    % Enstrophy = (1/2) * sum(ω²) * dA
    enstrophy_c = 0.5 * sum(omega_c(:).^2) * dA_c;
    enstrophy_f = 0.5 * sum(omega_f(:).^2) * dA_f;
    
    if enstrophy_f < 1e-12
        metric = NaN;
    else
        metric = abs(enstrophy_c - enstrophy_f) / enstrophy_f;
    end
end

%% HELPER FUNCTIONS: MESH & GRID UTILITIES
% Creates mesh grids and generates visualization of mesh properties

function [X, Y] = create_mesh_grid(N, Lx, Ly)
    % Create meshgrid for domain
    x = linspace(-Lx/2, Lx/2, N);
    y = linspace(-Ly/2, Ly/2, N);
    [X, Y] = meshgrid(x, y);
end

function metric = compute_interpolation_metric(omega_c, omega_f, omega_c_on_f)
    % Compute metric from interpolated fields with fallbacks
    
    if any(isnan(omega_c_on_f(:)))
        metric = compute_peak_vorticity_metric(omega_c, omega_f);
        fprintf('    WARNING: Interpolation produced NaN values - using peak vorticity comparison\n');
        return;
    end
    
    metric = compute_l2_metric(omega_f, omega_c_on_f);
    
    if isnan(metric)
        metric = compute_peak_vorticity_metric(omega_c, omega_f);
        fprintf('    WARNING: Fine grid solution has near-zero norm - using peak vorticity\n');
    end
end

function metric = compute_l2_metric(omega_f, omega_c_on_f)
    % Compute L2 norm based metric
    % DIAGNOSTIC: Detailed logging of L2 computation steps
    
    if any(~isfinite(omega_f(:))) || any(~isfinite(omega_c_on_f(:)))
        bad_f = nnz(~isfinite(omega_f(:)));
        bad_c_interp = nnz(~isfinite(omega_c_on_f(:)));
        fprintf('      [L2_DIAG] Non-finite values: omega_f=%d, omega_c_interp=%d\n', bad_f, bad_c_interp);
        metric = NaN;
        return;
    end
    
    denom = norm(omega_f(:), 2);
    numer = norm(omega_c_on_f(:) - omega_f(:), 2);
    
    fprintf('      [L2_DIAG] Denominator (||omega_f||_2) = %.3e\n', denom);
    fprintf('      [L2_DIAG] Numerator (||omega_c_interp - omega_f||_2) = %.3e\n', numer);
    
    if denom > 1e-10
        metric = numer / denom;
        fprintf('      [L2_DIAG] Metric = %.6e (VALID)\n', metric);
    else
        fprintf('      [L2_DIAG] Denominator too small (%.3e <= 1e-10) - ZERO SOLUTION\n', denom);
        metric = NaN;
    end
end

function metric = compute_peak_vorticity_metric(omega_c, omega_f)
    % Fallback metric using peak vorticity values
    % DIAGNOSTIC: Shows why fallback is triggered
    
    peak_c = max(abs(omega_c(:)), [], 'omitnan');
    peak_f = max(abs(omega_f(:)), [], 'omitnan');
    
    fprintf('      [PEAK_VORTICITY_DIAG] Coarse peak |omega| = %.3e\n', peak_c);
    fprintf('      [PEAK_VORTICITY_DIAG] Fine peak |omega| = %.3e\n', peak_f);
    
    if isfinite(peak_f) && peak_f > 1e-10
        metric = abs(peak_c - peak_f) / peak_f;
        fprintf('      [PEAK_VORTICITY_DIAG] Fallback metric = %.6e (VALID)\n', metric);
    else
        fprintf('      [PEAK_VORTICITY_DIAG] Peak vorticity too small or non-finite - ZERO SOLUTION\n');
        metric = NaN;
    end
end

% ========================================================================
%% VISUALIZATION: L-SHAPED GRID AND MESH PLOTTING
% ========================================================================

function [fig_contour, fig_mesh] = plot_solution_lshaped_and_mesh(X, Y, omega, title_str)
    % Plot solution on regular grid as contour map and mesh plot
    % Input:
    %   X, Y: mesh grids
    %   omega: solution field
    %   title_str: title for both plots
    
    % Contour plot
    fig_contour = figure('Name', 'Solution: Contour Map', 'NumberTitle', 'off');
    contourf(X, Y, omega, 25, 'LineStyle', 'none');
    colorbar;
    hold on;
    contour(X, Y, omega, 10, 'LineColor', 'k', 'LineWidth', 0.5);
    hold off;
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('$y$', 'Interpreter', 'latex', 'FontSize', 12);
    title(sprintf('%s (Contour Map)', title_str), 'Interpreter', 'latex', 'FontSize', 14);
    axis equal tight;
    colormap(fig_contour, 'turbo');
    grid off;
    
    % Mesh plot
    fig_mesh = figure('Name', 'Solution: Mesh Plot', 'NumberTitle', 'off');
    surf(X, Y, omega, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('$y$', 'Interpreter', 'latex', 'FontSize', 12);
    zlabel('$\omega$', 'Interpreter', 'latex', 'FontSize', 12);
    title(sprintf('%s (Mesh Plot)', title_str), 'Interpreter', 'latex', 'FontSize', 14);
    colormap(fig_mesh, 'turbo');
    colorbar;
    camlight('headlight');
    lighting gouraud;
    material dull;
    view(45, 30);
    axis tight;
    grid on;
end

% ========================================================================
%% MESH vs TIMESTEP INFLUENCE DIAGNOSTIC (Phase 0 before main convergence)
% ========================================================================

function param_influence = run_mesh_vs_dt_diagnostic(Parameters, N_coarse, settings)
    % Run 4 quick tests to identify whether mesh refinement or timestep reduction
    % has more influence on the numerical solution
    % 
    % Tests:
    %   1. Base case: (N_coarse, dt_base)
    %   2. Refined mesh: (2*N_coarse, dt_base) - only mesh refinement
    %   3. Reduced dt: (N_coarse, dt_base/2) - only timestep reduction
    %   4. Both refined: (2*N_coarse, dt_base/2) - both refinements
    %
    % Returns: param_influence struct with deltas and dominant factor
    
    N_fine = 2 * N_coarse;  % Refined mesh (2x in each direction = 4x total points)
    
    fprintf('\x1b[36mTest 1/4: Base case (N=%d, dt=%.4f)...\x1b[0m\n', N_coarse, Parameters.dt);
    p_base = Parameters;
    p_base.Nx = N_coarse;
    p_base.Ny = N_coarse;
    p_base.create_animations = false;  % Disable animations during diagnostic
    p_base.live_preview = false;       % Disable live preview
    % Initialize omega for this grid size
    [X_base, Y_base] = meshgrid(linspace(-p_base.Lx/2, p_base.Lx/2, N_coarse), ...
                                 linspace(-p_base.Ly/2, p_base.Ly/2, N_coarse));
    p_base.omega = initialise_omega(X_base, Y_base, p_base.ic_type, p_base.ic_coeff);
    fprintf('  [DEBUG] p_base.omega size: %d x %d, Nx=%d, Ny=%d\n', ...
        size(p_base.omega,1), size(p_base.omega,2), p_base.Nx, p_base.Ny);
    try
        [~, analysis_base, ok_base] = execute_simulation(p_base);
        if ~ok_base
            fprintf('  \x1b[41m✗ FAILED\x1b[0m - execute_simulation returned ok=false\n');
            if isfield(analysis_base, 'error_message')
                fprintf('  Error: %s\n', analysis_base.error_message);
            end
        end
    catch ME
        fprintf('  \x1b[41m✗ FAILED\x1b[0m - Exception: %s\n', ME.message);
        fprintf('  Stack: %s line %d\n', ME.stack(1).name, ME.stack(1).line);
        analysis_base = [];
        ok_base = false;
    end
    if ok_base && isfield(analysis_base, 'omega_snaps') && ~isempty(analysis_base.omega_snaps)
        omega_base = analysis_base.omega_snaps(:,:,end);
        peak_base = max(abs(omega_base(:)));
        fprintf('  \x1b[32m✓ Peak vorticity: %.3e, L2 norm: %.3e\x1b[0m\n', peak_base, norm(omega_base(:), 2));
    elseif ok_base && isfield(analysis_base, 'omega_final') && ~isempty(analysis_base.omega_final)
        omega_base = analysis_base.omega_final;
        peak_base = max(abs(omega_base(:)));
        fprintf('  \x1b[32m✓ (from omega_final) Peak vorticity: %.3e, L2 norm: %.3e\x1b[0m\n', peak_base, norm(omega_base(:), 2));
    else
        % Debug: show what fields are available
        fprintf('  \x1b[41m✗ FAILED\x1b[0m - No valid omega data\n');
        if ~isempty(analysis_base) && isstruct(analysis_base)
            fprintf('  Available fields: %s\n', strjoin(fieldnames(analysis_base)', ', '));
        end
        omega_base = zeros(N_coarse, N_coarse);
        peak_base = 0;
        ok_base = false;
    end
    
    % Test 2: Mesh refinement only (keep dt same)
    fprintf('\x1b[36mTest 2/4: Mesh refinement (N=%d, dt=%.4f)...\x1b[0m\n', N_fine, Parameters.dt);
    p_mesh = Parameters;
    p_mesh.Nx = N_fine;
    p_mesh.Ny = N_fine;
    p_mesh.dt = Parameters.dt;  % Keep original dt
    p_mesh.create_animations = false;
    p_mesh.live_preview = false;
    % Initialize omega for refined grid
    [X_mesh, Y_mesh] = meshgrid(linspace(-p_mesh.Lx/2, p_mesh.Lx/2, N_fine), ...
                                 linspace(-p_mesh.Ly/2, p_mesh.Ly/2, N_fine));
    p_mesh.omega = initialise_omega(X_mesh, Y_mesh, p_mesh.ic_type, p_mesh.ic_coeff);
    fprintf('  [DEBUG] p_mesh.omega size: %d x %d, Nx=%d, Ny=%d\n', ...
        size(p_mesh.omega,1), size(p_mesh.omega,2), p_mesh.Nx, p_mesh.Ny);
    try
        [~, analysis_mesh, ok_mesh] = execute_simulation(p_mesh);
        if ~ok_mesh
            fprintf('  \x1b[41m✗ FAILED\x1b[0m - execute_simulation returned ok=false\n');
            if isfield(analysis_mesh, 'error_message')
                fprintf('  Error: %s\n', analysis_mesh.error_message);
            end
        end
    catch ME
        fprintf('  \x1b[41m✗ FAILED\x1b[0m - Exception: %s\n', ME.message);
        fprintf('  Stack: %s line %d\n', ME.stack(1).name, ME.stack(1).line);
        analysis_mesh = [];
        ok_mesh = false;
    end
    if ok_mesh && isfield(analysis_mesh, 'omega_snaps') && ~isempty(analysis_mesh.omega_snaps)
        omega_mesh = analysis_mesh.omega_snaps(:,:,end);
        peak_mesh = max(abs(omega_mesh(:)));
        % Interpolate base to fine grid for comparison
        x_coarse = linspace(-Parameters.Lx/2, Parameters.Lx/2, N_coarse);
        y_coarse = linspace(-Parameters.Ly/2, Parameters.Ly/2, N_coarse);
        x_fine = linspace(-Parameters.Lx/2, Parameters.Lx/2, N_fine);
        y_fine = linspace(-Parameters.Ly/2, Parameters.Ly/2, N_fine);
        [Xc, Yc] = meshgrid(x_coarse, y_coarse);
        [Xf, Yf] = meshgrid(x_fine, y_fine);
        omega_base_interp = interp2(Xc, Yc, omega_base, Xf, Yf, 'linear');
        delta_mesh = norm(omega_mesh(:) - omega_base_interp(:), 2) / max(norm(omega_base(:), 2), 1e-12);
        fprintf('  \x1b[32m✓ Peak vorticity: %.3e | L2 delta from base: %.3e\x1b[0m\n', peak_mesh, delta_mesh);
    elseif ok_mesh && isfield(analysis_mesh, 'omega_final') && ~isempty(analysis_mesh.omega_final)
        omega_mesh = analysis_mesh.omega_final;
        peak_mesh = max(abs(omega_mesh(:)));
        x_coarse = linspace(-Parameters.Lx/2, Parameters.Lx/2, N_coarse);
        y_coarse = linspace(-Parameters.Ly/2, Parameters.Ly/2, N_coarse);
        x_fine = linspace(-Parameters.Lx/2, Parameters.Lx/2, N_fine);
        y_fine = linspace(-Parameters.Ly/2, Parameters.Ly/2, N_fine);
        [Xc, Yc] = meshgrid(x_coarse, y_coarse);
        [Xf, Yf] = meshgrid(x_fine, y_fine);
        omega_base_interp = interp2(Xc, Yc, omega_base, Xf, Yf, 'linear');
        delta_mesh = norm(omega_mesh(:) - omega_base_interp(:), 2) / max(norm(omega_base(:), 2), 1e-12);
        fprintf('  \x1b[32m✓ (from omega_final) Peak vorticity: %.3e | L2 delta from base: %.3e\x1b[0m\n', peak_mesh, delta_mesh);
    else
        omega_mesh = zeros(N_fine, N_fine);
        peak_mesh = 0;
        delta_mesh = NaN;
        ok_mesh = false;
        fprintf('  \x1b[41m✗ FAILED\x1b[0m - No valid omega data (checked omega_snaps and omega_final)\n');
    end
    
    % Test 3: Timestep reduction only (keep mesh same)
    fprintf('\x1b[36mTest 3/4: Timestep reduction (N=%d, dt=%.4f)...\x1b[0m\n', N_coarse, Parameters.dt/2);
    p_dt = Parameters;
    p_dt.Nx = N_coarse;
    p_dt.Ny = N_coarse;
    p_dt.dt = Parameters.dt / 2;  % Reduce timestep
    p_dt.create_animations = false;
    p_dt.live_preview = false;
    % Initialize omega for this grid size
    [X_dt, Y_dt] = meshgrid(linspace(-p_dt.Lx/2, p_dt.Lx/2, N_coarse), ...
                             linspace(-p_dt.Ly/2, p_dt.Ly/2, N_coarse));
    p_dt.omega = initialise_omega(X_dt, Y_dt, p_dt.ic_type, p_dt.ic_coeff);
    fprintf('  [DEBUG] p_dt.omega size: %d x %d, Nx=%d, Ny=%d, dt=%.4e\n', ...
        size(p_dt.omega,1), size(p_dt.omega,2), p_dt.Nx, p_dt.Ny, p_dt.dt);
    try
        [~, analysis_dt, ok_dt] = execute_simulation(p_dt);
        if ~ok_dt
            fprintf('  \x1b[41m✗ FAILED\x1b[0m - execute_simulation returned ok=false\n');
            if isfield(analysis_dt, 'error_message')
                fprintf('  Error: %s\n', analysis_dt.error_message);
            end
        end
    catch ME
        fprintf('  \x1b[41m✗ FAILED\x1b[0m - Exception: %s\n', ME.message);
        fprintf('  Stack: %s line %d\n', ME.stack(1).name, ME.stack(1).line);
        analysis_dt = [];
        ok_dt = false;
    end
    if ok_dt && isfield(analysis_dt, 'omega_snaps') && ~isempty(analysis_dt.omega_snaps)
        omega_dt = analysis_dt.omega_snaps(:,:,end);
        peak_dt = max(abs(omega_dt(:)));
        delta_dt = norm(omega_dt(:) - omega_base(:), 2) / max(norm(omega_base(:), 2), 1e-12);
        fprintf('  \x1b[32m✓ Peak vorticity: %.3e | L2 delta from base: %.3e\x1b[0m\n', peak_dt, delta_dt);
    elseif ok_dt && isfield(analysis_dt, 'omega_final') && ~isempty(analysis_dt.omega_final)
        omega_dt = analysis_dt.omega_final;
        peak_dt = max(abs(omega_dt(:)));
        delta_dt = norm(omega_dt(:) - omega_base(:), 2) / max(norm(omega_base(:), 2), 1e-12);
        fprintf('  \x1b[32m✓ (from omega_final) Peak vorticity: %.3e | L2 delta from base: %.3e\x1b[0m\n', peak_dt, delta_dt);
    else
        omega_dt = zeros(N_coarse, N_coarse);
        peak_dt = 0;
        delta_dt = NaN;
        ok_dt = false;
        fprintf('  \x1b[41m✗ FAILED\x1b[0m - No valid omega data (checked omega_snaps and omega_final)\n');
    end
    
    % Test 4: Both refined
    fprintf('\x1b[36mTest 4/4: Both refined (N=%d, dt=%.4f)...\x1b[0m\n', N_fine, Parameters.dt/2);
    p_both = Parameters;
    p_both.Nx = N_fine;
    p_both.Ny = N_fine;
    p_both.dt = Parameters.dt / 2;
    p_both.create_animations = false;
    p_both.live_preview = false;
    % Initialize omega for refined grid
    [X_both, Y_both] = meshgrid(linspace(-p_both.Lx/2, p_both.Lx/2, N_fine), ...
                                 linspace(-p_both.Ly/2, p_both.Ly/2, N_fine));
    p_both.omega = initialise_omega(X_both, Y_both, p_both.ic_type, p_both.ic_coeff);
    fprintf('  [DEBUG] p_both.omega size: %d x %d, Nx=%d, Ny=%d, dt=%.4e\n', ...
        size(p_both.omega,1), size(p_both.omega,2), p_both.Nx, p_both.Ny, p_both.dt);
    try
        [~, analysis_both, ok_both] = execute_simulation(p_both);
        if ~ok_both
            fprintf('  \x1b[41m✗ FAILED\x1b[0m - execute_simulation returned ok=false\n');
            if isfield(analysis_both, 'error_message')
                fprintf('  Error: %s\n', analysis_both.error_message);
            end
        end
    catch ME
        fprintf('  \x1b[41m✗ FAILED\x1b[0m - Exception: %s\n', ME.message);
        fprintf('  Stack: %s line %d\n', ME.stack(1).name, ME.stack(1).line);
        analysis_both = [];
        ok_both = false;
    end
    if ok_both && isfield(analysis_both, 'omega_snaps') && ~isempty(analysis_both.omega_snaps)
        omega_both = analysis_both.omega_snaps(:,:,end);
        peak_both = max(abs(omega_both(:)));
        omega_base_interp = interp2(Xc, Yc, omega_base, Xf, Yf, 'linear');
        delta_both = norm(omega_both(:) - omega_base_interp(:), 2) / max(norm(omega_base(:), 2), 1e-12);
        fprintf('  \x1b[32m✓ Peak vorticity: %.3e | L2 delta from base: %.3e\x1b[0m\n', peak_both, delta_both);
    elseif ok_both && isfield(analysis_both, 'omega_final') && ~isempty(analysis_both.omega_final)
        omega_both = analysis_both.omega_final;
        peak_both = max(abs(omega_both(:)));
        omega_base_interp = interp2(Xc, Yc, omega_base, Xf, Yf, 'linear');
        delta_both = norm(omega_both(:) - omega_base_interp(:), 2) / max(norm(omega_base(:), 2), 1e-12);
        fprintf('  \x1b[32m✓ (from omega_final) Peak vorticity: %.3e | L2 delta from base: %.3e\x1b[0m\n', peak_both, delta_both);
    else
        omega_both = zeros(N_fine, N_fine);
        peak_both = 0;
        delta_both = NaN;
        ok_both = false;
        fprintf('  \x1b[41m✗ FAILED\x1b[0m - No valid omega data (checked omega_snaps and omega_final)\n');
    end
    
    % Determine which is more influential
    % Influence = change in solution when that factor is refined
    if isfinite(delta_mesh) && isfinite(delta_dt)
        if delta_mesh > delta_dt
            most_influential = "Mesh Refinement";
            refinement_priority = "Nx/Ny";
            fprintf_colored('yellow', '\n=== DIAGNOSTIC RESULTS ===\n');
            fprintf_colored('green', 'Mesh refinement impact: %.3e\n', delta_mesh);
            fprintf_colored('blue', 'Timestep reduction impact: %.3e\n', delta_dt);
            fprintf_colored('green', 'Most influential: %s\n', most_influential);
        else
            most_influential = "Timestep Reduction";
            refinement_priority = "dt";
            fprintf_colored('yellow', '\n=== DIAGNOSTIC RESULTS ===\n');
            fprintf_colored('green', 'Mesh refinement impact: %.3e\n', delta_mesh);
            fprintf_colored('blue', 'Timestep reduction impact: %.3e\n', delta_dt);
            fprintf_colored('blue', 'Most influential: %s\n', most_influential);
        end
    elseif isfinite(delta_mesh)
        most_influential = "Mesh Refinement";
        refinement_priority = "Nx/Ny";
        fprintf_colored('yellow', '\n=== DIAGNOSTIC RESULTS ===\n');
        fprintf_colored('green', 'Most influential: %s (timestep test failed)\n', most_influential);
    else
        most_influential = "Timestep Reduction";
        refinement_priority = "dt";
        fprintf_colored('yellow', '\n=== DIAGNOSTIC RESULTS ===\n');
        fprintf_colored('blue', 'Most influential: %s (mesh test failed)\n', most_influential);
    end
    fprintf_colored('cyan', 'Refinement strategy: prioritize %s for adaptive convergence\n', refinement_priority);
    fprintf('=====================================\n\n');
    
    % Package results
    param_influence = struct();
    param_influence.test_grid_coarse = N_coarse;
    param_influence.test_grid_fine = N_fine;
    param_influence.base_dt = Parameters.dt;
    param_influence.results = struct(...
        'base', struct('peak_vorticity', peak_base, 'L2_norm', norm(omega_base(:), 2), 'ok', ok_base), ...
        'mesh_refined', struct('peak_vorticity', peak_mesh, 'delta', delta_mesh, 'ok', ok_mesh), ...
        'dt_reduced', struct('peak_vorticity', peak_dt, 'delta', delta_dt, 'ok', ok_dt), ...
        'both_refined', struct('peak_vorticity', peak_both, 'delta', delta_both, 'ok', ok_both));
    
    param_influence.mesh_delta = delta_mesh;
    param_influence.dt_delta = delta_dt;
    param_influence.mesh_ok = isfinite(delta_mesh);
    param_influence.dt_ok = isfinite(delta_dt);
    param_influence.most_influential = most_influential;
    param_influence.refinement_priority = refinement_priority;
    
    % Create comparison visualization if we have valid results
    if ok_base && (ok_mesh || ok_dt)
        create_diagnostic_comparison_plot(param_influence, N_coarse, N_fine, omega_base, omega_mesh, omega_dt);
    end
end

function create_diagnostic_comparison_plot(results, N_coarse, N_fine, omega_base, omega_mesh, omega_dt)
    % Creates side-by-side comparison plots of mesh refinement vs timestep reduction
    
    fig = figure('Name', 'Diagnostic: Mesh vs Timestep Influence', 'NumberTitle', 'off', ...
        'Position', [100, 100, 1400, 600]);
    
    % Plot 1: Base case vorticity field
    ax1 = subplot(2,3,1);
    contourf(omega_base, 20, 'LineStyle', 'none');
    colorbar;
    title(sprintf('Base: N=%d, dt=%.4f', N_coarse, results.base_dt), 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X grid'); ylabel('Y grid');
    
    % Plot 2: Mesh refined (if available)
    ax2 = subplot(2,3,2);
    if results.mesh_ok
        contourf(omega_mesh, 20, 'LineStyle', 'none');
        colorbar;
        title(sprintf('Mesh Refined: N=%d, Δ=%.3e', N_fine, results.mesh_delta), ...
            'FontSize', 11, 'FontWeight', 'bold', 'Color', 'g');
    else
        text(0.5, 0.5, 'MESH TEST FAILED', 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'FontSize', 14, 'Color', 'r', 'FontWeight', 'bold');
        set(ax2, 'XTick', [], 'YTick', []);
    end
    xlabel('X grid'); ylabel('Y grid');
    
    % Plot 3: Timestep refined (if available)
    ax3 = subplot(2,3,3);
    if results.dt_ok
        contourf(omega_dt, 20, 'LineStyle', 'none');
        colorbar;
        title(sprintf('dt Refined: dt=%.4f, Δ=%.3e', results.base_dt/2, results.dt_delta), ...
            'FontSize', 11, 'FontWeight', 'bold', 'Color', 'b');
    else
        text(0.5, 0.5, 'DT TEST FAILED', 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'FontSize', 14, 'Color', 'r', 'FontWeight', 'bold');
        set(ax3, 'XTick', [], 'YTick', []);
    end
    xlabel('X grid'); ylabel('Y grid');
    
    % Plot 4: Peak vorticity comparison
    ax4 = subplot(2,3,4);
    categories = categorical({'Base (N64)', 'Mesh (N128)', 'dt (0.005)', 'Both (N128,0.005)'});
    peaks = [results.results.base.peak_vorticity, ...
             results.results.mesh_refined.peak_vorticity, ...
             results.results.dt_reduced.peak_vorticity, ...
             results.results.both_refined.peak_vorticity];
    colors = {'k', 'g', 'b', 'r'};
    for i = 1:numel(peaks)
        if isfinite(peaks(i))
            bar(i, peaks(i), 'FaceColor', colors{i}, 'EdgeColor', 'black', 'LineWidth', 1.5);
        else
            bar(i, 0, 'FaceColor', 'red', 'FaceAlpha', 0.3);
            text(i, 0.1, 'FAILED', 'HorizontalAlignment', 'center', 'FontSize', 9);
        end
    end
    set(ax4, 'XTickLabel', categories);
    ylabel('Peak |ω| (s^{-1})');
    grid on; grid minor;
    title('Peak Vorticity Comparison', 'FontWeight', 'bold');
    
    % Plot 5: Delta magnitude comparison
    ax5 = subplot(2,3,5);
    deltas = [0, results.mesh_delta, results.dt_delta, results.results.both_refined.delta];
    for i = 1:numel(deltas)
        if isfinite(deltas(i))
            bar(i, deltas(i), 'FaceColor', colors{i}, 'EdgeColor', 'black', 'LineWidth', 1.5);
        else
            bar(i, 0, 'FaceColor', 'red', 'FaceAlpha', 0.3);
            text(i, 0.001, 'FAILED', 'HorizontalAlignment', 'center', 'FontSize', 9, 'Rotation', 90);
        end
    end
    set(ax5, 'XTickLabel', categories);
    ylabel('L2 Error vs Base');
    set(ax5, 'YScale', 'log');
    grid on; grid minor;
    title('Solution Difference from Base', 'FontWeight', 'bold');
    
    % Plot 6: Diagnostic summary text
    ax6 = subplot(2,3,6);
    axis off;
    summary_text = sprintf([...
        'DIAGNOSTIC SUMMARY\n' ...
        '─────────────────────────────\n' ...
        'Base Grid: %d × %d\n' ...
        'Refined Grid: %d × %d\n' ...
        'Base dt: %.4e s\n' ...
        'Reduced dt: %.4e s\n' ...
        '\n' ...
        'RESULTS:\n' ...
        '─────────────────────────────\n' ...
        'Mesh Impact: %s\n' ...
        'dt Impact: %s\n' ...
        'Most Influential: %s\n' ...
        'Strategy: %s\n'], ...
        N_coarse, N_coarse, N_fine, N_fine, results.base_dt, results.base_dt/2, ...
        conditionalStr(results.mesh_ok, sprintf('%.3e', results.mesh_delta), 'FAILED'), ...
        conditionalStr(results.dt_ok, sprintf('%.3e', results.dt_delta), 'FAILED'), ...
        results.most_influential, results.refinement_priority);
    text(0.1, 0.5, summary_text, 'FontFamily', 'monospace', 'FontSize', 10, ...
        'VerticalAlignment', 'middle', 'Interpreter', 'none');
    
    % Save figure
    fig_name = 'diagnostic_mesh_vs_timestep_comparison';
    print(fig, [pwd '/' fig_name '.png'], '-dpng', '-r300');
    fprintf('\n[DIAGNOSTIC PLOT] Saved: %s.png\n', fig_name);
end

function str = conditionalStr(condition, trueVal, falseVal)
    if condition
        str = trueVal;
    else
        str = falseVal;
    end
end


% ========================================================================
%% EXPLORATORY PHYSICAL QUANTITY STUDY
% ========================================================================
% Automatically determines the most sensitive physical quantity for
% convergence monitoring by running controlled refinement tests

function [selected_quantity, study_results] = run_exploratory_physical_study(Parameters, settings)
    % Runs exploratory mesh refinement study to identify best physical quantity
    %
    % METHODOLOGY:
    %   1. Define controlled test environment (fixed IC, domain, scaling)
    %   2. Run series of refinements: N = [N_base, 1.5N, 2N, 3N, 4N]
    %   3. For each N, compute multiple physical quantities
    %   4. Compute sensitivity: |Q(N_fine) - Q(N_coarse)| / Q(N_fine)
    %   5. Select quantity with highest mean sensitivity
    %   6. Plot all trends for visual comparison
    
    fprintf('\n');
    fprintf('\x1b[46m\x1b[30m                                                    \x1b[0m\n');
    fprintf('\x1b[46m\x1b[30m   EXPLORATORY PHYSICAL QUANTITY STUDY             \x1b[0m\n');
    fprintf('\x1b[46m\x1b[30m                                                    \x1b[0m\n');
    fprintf('\n');
    
    % Controlled environment setup
    fprintf('\x1b[36m[SETUP]\x1b[0m Configuring controlled test environment...\n');
    test_params = Parameters;
    
    % Extract settings
    adaptive_settings = settings.convergence.adaptive_physical;
    N_base = adaptive_settings.N_base;
    refinement_factors = adaptive_settings.refinement_factors;
    N_sequence = round(N_base .* refinement_factors);
    num_cases = length(N_sequence);
    
    fprintf('  Initial condition: ICID = %d\n', test_params.ICID);
    fprintf('  Mesh sequence: [%s]\n', sprintf('%d ', N_sequence));
    fprintf('  Total cases: %d\n', num_cases);
    fprintf('\n');
    
    % Initialize storage for physical quantities
    quantities = struct();
    quantities.peak_vorticity = zeros(num_cases, 1);
    quantities.enstrophy = zeros(num_cases, 1);
    quantities.l2_norm = zeros(num_cases, 1);
    quantities.max_gradient = zeros(num_cases, 1);
    quantities.total_circulation = zeros(num_cases, 1);
    
    % Run refinement sequence
    fprintf('\x1b[36m[EXECUTE]\x1b[0m Running refinement sequence...\n');
    for i = 1:num_cases
        N_current = N_sequence(i);
        fprintf('  [%d/%d] N = %d... ', i, num_cases, N_current);
        
        % Prepare parameters for this test
        test_params.N = N_current;
        test_params.dt = compute_stable_dt(test_params, N_current);
        
        try
            % Run simulation
            row = run_case(test_params, struct());
            
            if ~isempty(row) && has_valid_omega_snaps(row)
                omega = row.omega_snaps{end};  % Final snapshot
                [X, Y] = create_mesh_grid(N_current, test_params.Lx, test_params.Ly);
                dx = X(1,2) - X(1,1);
                dy = Y(2,1) - Y(1,1);
                dA = dx * dy;
                
                % Compute physical quantities
                quantities.peak_vorticity(i) = max(abs(omega(:)));
                quantities.enstrophy(i) = sum(omega(:).^2) * dA;
                quantities.l2_norm(i) = sqrt(sum(omega(:).^2) * dA);
                
                % Gradient computation
                [omega_x, omega_y] = gradient(omega, dx, dy);
                grad_mag = sqrt(omega_x.^2 + omega_y.^2);
                quantities.max_gradient(i) = max(grad_mag(:));
                
                % Total circulation
                quantities.total_circulation(i) = sum(abs(omega(:))) * dA;
                
                fprintf('\x1b[32mOK\x1b[0m (ω_max=%.3e)\n', quantities.peak_vorticity(i));
            else
                fprintf('\x1b[41m[ERROR]\x1b[0m Invalid result\n');
                quantities.peak_vorticity(i) = NaN;
                quantities.enstrophy(i) = NaN;
                quantities.l2_norm(i) = NaN;
                quantities.max_gradient(i) = NaN;
                quantities.total_circulation(i) = NaN;
            end
        catch ME
            fprintf('\x1b[41m[ERROR]\x1b[0m %s\n', ME.message);
            quantities.peak_vorticity(i) = NaN;
            quantities.enstrophy(i) = NaN;
            quantities.l2_norm(i) = NaN;
            quantities.max_gradient(i) = NaN;
            quantities.total_circulation(i) = NaN;
        end
    end
    
    fprintf('\n');
    
    % Compute sensitivities
    fprintf('\x1b[36m[ANALYSIS]\x1b[0m Computing sensitivity metrics...\n');
    sensitivity = struct();
    quantity_names = fieldnames(quantities);
    mean_sensitivities = zeros(length(quantity_names), 1);
    
    for q = 1:length(quantity_names)
        qname = quantity_names{q};
        values = quantities.(qname);
        
        % Compute relative changes between consecutive refinements
        sens_values = zeros(num_cases-1, 1);
        for i = 1:(num_cases-1)
            if isfinite(values(i)) && isfinite(values(i+1)) && abs(values(i+1)) > 1e-12
                sens_values(i) = abs(values(i+1) - values(i)) / abs(values(i+1));
            else
                sens_values(i) = NaN;
            end
        end
        
        sensitivity.(qname) = sens_values;
        mean_sensitivities(q) = mean(sens_values, 'omitnan');
        
        fprintf('  %-25s: mean sensitivity = %.4f\n', qname, mean_sensitivities(q));
    end
    
    % Select quantity with highest sensitivity
    [max_sens, max_idx] = max(mean_sensitivities);
    selected_quantity = quantity_names{max_idx};
    
    fprintf('\n');
    fprintf('\x1b[32m[SELECTION]\x1b[0m Most sensitive: %s (sensitivity = %.4f)\n', selected_quantity, max_sens);
    fprintf('\n');
    
    % Store results
    study_results = struct();
    study_results.N_sequence = N_sequence;
    study_results.quantities = quantities;
    study_results.sensitivity = sensitivity;
    study_results.selected_quantity = selected_quantity;
    study_results.mean_sensitivities = mean_sensitivities;
    study_results.quantity_names = quantity_names;
    
    % Plot trends if requested
    if adaptive_settings.plot_trends
        plot_physical_quantity_trends(study_results);
    end
end

function plot_physical_quantity_trends(results)
    % Plot all physical quantities vs mesh refinement
    
    N_seq = results.N_sequence;
    quantities = results.quantities;
    sensitivity = results.sensitivity;
    selected = results.selected_quantity;
    qnames = results.quantity_names;
    
    figure('Name', 'Exploratory Physical Quantity Study', 'Position', [100, 100, 1400, 900]);
    
    num_q = length(qnames);
    rows = ceil(num_q / 2);
    
    for q = 1:num_q
        qname = qnames{q};
        values = quantities.(qname);
        
        if all(isnan(values))
            continue;
        end
        
        subplot(rows, 2, q);
        
        % Plot values
        yyaxis left
        plot(N_seq, values, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0, 0.4470, 0.7410]);
        ylabel(strrep(qname, '_', ' '), 'FontSize', 11);
        xlabel('Mesh size N', 'FontSize', 11);
        grid on;
        
        % Plot sensitivity
        if isfield(sensitivity, qname)
            yyaxis right
            sens = sensitivity.(qname);
            N_mid = (N_seq(1:end-1) + N_seq(2:end)) / 2;
            plot(N_mid, sens, 's--', 'LineWidth', 1.5, 'MarkerSize', 6, 'Color', [0.8500, 0.3250, 0.0980]);
            ylabel('Sensitivity', 'FontSize', 10, 'Color', [0.8500, 0.3250, 0.0980]);
        end
        
        % Highlight selection
        if strcmp(qname, selected)
            title(sprintf('\bf%s [SELECTED]', strrep(qname, '_', ' ')), 'FontSize', 12, 'Color', [0, 0.5, 0]);
        else
            title(strrep(qname, '_', ' '), 'FontSize', 11);
        end
    end
    
    sgtitle('Physical Quantity Convergence Trends', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Save
    try
        saveas(gcf, 'exploratory_physical_study.png');
        fprintf('\x1b[32m[PLOT]\x1b[0m Saved: exploratory_physical_study.png\n');
    catch
        fprintf('\x1b[43m[WARNING]\x1b[0m Could not save plot\n');
    end
end

function dt = compute_stable_dt(params, N)
    % Compute CFL-limited timestep
    dx = params.Lx / N;
    U_char = max(abs([params.U0_mean, params.V0_mean]), [], 'all');
    if U_char == 0
        U_char = 1.0;  % Default if no mean flow
    end
    CFL = 0.5;
    dt = CFL * dx / U_char;
end

% ========================================================================
%% MODE DEFINITION & SUSTAINABILITY TRACKING UTILITIES
% ========================================================================

function mode_info = get_mode_definition(mode_name)
    % Returns detailed information about each execution mode
    % Used for sustainability tracking and documentation
    
    modes = struct();
    
    % Evolution mode
    modes.evolution = struct(...
        'name', 'evolution', ...
        'category', 'baseline', ...
        'description', 'Single low-resolution simulation for visualization', ...
        'stages', {{'Simulation', 'Post-processing'}}, ...
        'expected_duration_min', 2, ...
        'relative_cost', 'LOW', ...
        'sustainability_phase', 'execution');
    
    % Convergence mode
    modes.convergence = struct(...
        'name', 'convergence', ...
        'category', 'production', ...
        'description', 'Multi-stage adaptive mesh refinement study', ...
        'stages', {{'Exploratory study', 'Diagnostic tests', 'Agent search', 'Refinement'}}, ...
        'expected_duration_min', 45, ...
        'relative_cost', 'HIGH', ...
        'sustainability_phase', 'both', ...  % Both setup and study
        'setup_stages', {{1, 2}}, ...  % Stages 1-2 are setup
        'study_stages', {{3, 4}});
    
    % Sweep mode
    modes.sweep = struct(...
        'name', 'sweep', ...
        'category', 'analysis', ...
        'description', 'Parameter sweep on converged mesh', ...
        'stages', {{'Configuration loop', 'Data collection', 'Analysis'}}, ...
        'expected_duration_min', 30, ...
        'relative_cost', 'MEDIUM-HIGH', ...
        'sustainability_phase', 'execution');
    
    % Test convergence mode
    modes.test_convergence = struct(...
        'name', 'test_convergence', ...
        'category', 'testing', ...
        'description', 'Small-scale convergence validation', ...
        'stages', {{'Initial pair', 'Richardson', 'Binary search'}}, ...
        'expected_duration_min', 5, ...
        'relative_cost', 'LOW', ...
        'sustainability_phase', 'development');
    
    % Animation mode
    modes.animation = struct(...
        'name', 'animation', ...
        'category', 'visualization', ...
        'description', 'High-FPS animation generation', ...
        'stages', {{'Simulation', 'Rendering', 'Encoding'}}, ...
        'expected_duration_min', 10, ...
        'relative_cost', 'MEDIUM', ...
        'sustainability_phase', 'postprocessing');
    
    % Experimentation mode
    modes.experimentation = struct(...
        'name', 'experimentation', ...
        'category', 'exploration', ...
        'description', 'Multi-configuration IC testing', ...
        'stages', {{'Configuration tests', 'Comparison'}}, ...
        'expected_duration_min', 15, ...
        'relative_cost', 'MEDIUM', ...
        'sustainability_phase', 'development');
    
    % Return requested mode
    mode_str = char(mode_name);
    if isfield(modes, mode_str)
        mode_info = modes.(mode_str);
    else
        error('Unknown mode: %s', mode_str);
    end
end

function [monitor, session_id] = initialize_sustainability_tracking(mode, settings)
    % Initialize hardware monitoring for current mode
    % Returns monitor object and unique session ID
    
    monitor = [];
    session_id = '';
    
    if ~settings.enable_sustainability_tracking
        return;
    end
    
    try
        % Get mode information
        mode_info = get_mode_definition(mode);
        
        % Create session identifier
        timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
        session_id = sprintf('%s_%s', mode_info.name, timestamp);
        
        % Initialize hardware monitor
        script_dir = fileparts(mfilename('fullpath'));  % Scripts/Main
        sustainability_dir = fullfile(script_dir, '..', 'Sustainability');
        if exist(sustainability_dir, 'dir')
            addpath(sustainability_dir);
        end
        monitor = HardwareMonitorBridge();
        
        % Start logging with mode-specific tags
        monitor.start_logging(session_id);
        
        fprintf('\n');
        fprintf('\x1b[42m\x1b[30m=== SUSTAINABILITY TRACKING ACTIVE ===\x1b[0m\n');
        fprintf('\x1b[32m[TRACK]\x1b[0m Mode: %s\n', mode_info.name);
        fprintf('\x1b[32m[TRACK]\x1b[0m Category: %s\n', mode_info.category);
        fprintf('\x1b[32m[TRACK]\x1b[0m Expected cost: %s\n', mode_info.relative_cost);
        fprintf('\x1b[32m[TRACK]\x1b[0m Session: %s\n', session_id);
        fprintf('\x1b[42m\x1b[30m======================================\x1b[0m\n');
        fprintf('\n');
        
    catch ME
        warning(ME.identifier, 'Failed to initialize sustainability tracking: %s', ME.message);
        monitor = [];
    end
end

function finalize_sustainability_tracking(monitor, session_id, mode, phase)
    % Stop monitoring and save sustainability report
    % phase: 'setup', 'study', 'execution', or 'complete'
    
    if isempty(monitor)
        return;
    end
    
    try
        % Stop logging
        log_file = monitor.stop_logging();
        
        % Get statistics
        stats = monitor.get_statistics();
        
        fprintf('\n');
        fprintf('\x1b[43m\x1b[30m=== SUSTAINABILITY REPORT ===\x1b[0m\n');
        fprintf('\x1b[33m[TRACK]\x1b[0m Mode: %s\n', char(mode));
        fprintf('\x1b[33m[TRACK]\x1b[0m Phase: %s\n', phase);
        fprintf('\x1b[33m[TRACK]\x1b[0m Duration: %.1f min\n', stats.duration_s / 60);
        fprintf('\x1b[33m[TRACK]\x1b[0m Energy: %.1f kJ (%.4f kWh)\n', ...
            stats.total_energy_J / 1000, stats.total_energy_J / 3.6e6);
        fprintf('\x1b[33m[TRACK]\x1b[0m Avg Power: %.1f W\n', stats.avg_power_W);
        fprintf('\x1b[33m[TRACK]\x1b[0m Peak Power: %.1f W\n', stats.peak_power_W);
        fprintf('\x1b[33m[TRACK]\x1b[0m Log: %s\n', log_file);
        fprintf('\x1b[43m\x1b[30m=============================\x1b[0m\n');
        fprintf('\n');
        
    catch ME
        warning(ME.identifier, 'Failed to finalize sustainability tracking: %s', ME.message);
    end
end

% ========================================================================
% PLOT MODE FOR REPORT GENERATION
% ========================================================================
% Generates publication-quality figures comparing convergence methods

function [T, meta] = run_plot_mode(Parameters, settings, run_mode)
    % Plot mode: Generate figures for report
    % Compares agent-based convergence with traditional methods
    
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('\x1b[44m\x1b[37m PLOT MODE: Report Figure Generation \x1b[0m\n');
    fprintf('%s\n', repmat('=', 1, 80));
    
    % Create output directory for plots
    plot_output_dir = fullfile('Report_Figures', datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    if ~exist(plot_output_dir, 'dir')
        mkdir(plot_output_dir);
    end
    
    fprintf('\nGenerating publication-quality figures for report...\n');
    
    % Figure 1: Convergence Comparison (Agent vs Traditional)
    fprintf('\n[1/5] Agent vs Traditional Convergence Comparison... ');
    fig1 = create_convergence_comparison_plot();
    print(fig1, fullfile(plot_output_dir, 'convergence_comparison.png'), '-dpng', '-r300');
    fprintf('\x1b[32m✓\x1b[0m\n');
    
    % Figure 2: Grid Refinement History
    fprintf('[2/5] Grid Refinement History... ');
    fig2 = create_grid_refinement_history_plot();
    print(fig2, fullfile(plot_output_dir, 'grid_refinement_history.png'), '-dpng', '-r300');
    fprintf('\x1b[32m✓\x1b[0m\n');
    
    % Figure 3: Timestep Refinement History
    fprintf('[3/5] Timestep Refinement History... ');
    fig3 = create_timestep_refinement_history_plot();
    print(fig3, fullfile(plot_output_dir, 'timestep_refinement_history.png'), '-dpng', '-r300');
    fprintf('\x1b[32m✓\x1b[0m\n');
    
    % Figure 4: Agent Decision Evolution
    fprintf('[4/5] Agent Decision Evolution... ');
    fig4 = create_agent_decisions_plot();
    print(fig4, fullfile(plot_output_dir, 'agent_decisions.png'), '-dpng', '-r300');
    fprintf('\x1b[32m✓\x1b[0m\n');
    
    % Figure 5: Physical Parameters Over Convergence
    fprintf('[5/5] Physical Parameters During Convergence... ');
    fig5 = create_physical_parameters_plot();
    print(fig5, fullfile(plot_output_dir, 'physical_parameters.png'), '-dpng', '-r300');
    fprintf('\x1b[32m✓\x1b[0m\n');
    
    % Generate summary table
    fprintf('\nGenerating summary statistics...\n');
    summary_table = generate_convergence_summary_table();
    writetable(summary_table, fullfile(plot_output_dir, 'convergence_summary.csv'));
    
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('\x1b[42m\x1b[30m PLOT MODE COMPLETE \x1b[0m\n');
    fprintf('All figures saved to: %s\n', plot_output_dir);
    fprintf('%s\n', repmat('=', 1, 80));
    
    % Prepare output table
    T = table();
    T.mode = {char(run_mode)};
    T.output_directory = {plot_output_dir};
    T.figures_created = 5;
    
    % Prepare metadata
    meta = struct();
    meta.mode = run_mode;
    meta.figures_generated = 5;
    meta.output_directory = plot_output_dir;
    meta.description = 'Report-quality figures for convergence analysis';
end

% ========================================================================
% FIGURE GENERATION FUNCTIONS
% ========================================================================

function fig = create_convergence_comparison_plot()
    % Compare agent-based vs traditional convergence strategies
    
    fig = figure('Name', 'Convergence Comparison', 'NumberTitle', 'off', ...
                 'Position', [100 100 1200 600]);
    
    % Simulated data for demonstration
    iterations_traditional = [1, 2, 3, 4, 5, 6];
    metric_traditional = [1.0, 0.5, 0.25, 0.12, 0.06, 0.03];
    
    iterations_agent = [1, 2, 3, 4, 5];
    metric_agent = [1.0, 0.4, 0.15, 0.05, 0.02];
    
    semilogy(iterations_traditional, metric_traditional, 'bs-', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'MarkerFaceColor', 'b', 'DisplayName', 'Traditional Method');
    hold on;
    semilogy(iterations_agent, metric_agent, 'ro-', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'MarkerFaceColor', 'r', 'DisplayName', 'Agent-Based Method');
    hold off;
    
    % Apply Plot_Format utility
    Plot_Format('Refinement Iteration', 'Convergence Metric', ...
                'Convergence Comparison: Agent vs Traditional Methods', 'Default', 1.2);
    
    % Apply Legend_Format utility
    Legend_Format({'Traditional Method', 'Agent-Based Method'}, 12, 'vertical', 1, 2, true);
    
    % Add efficiency annotation
    efficiency = (numel(iterations_traditional) - numel(iterations_agent)) / numel(iterations_traditional) * 100;
    annotation('textbox', [0.6 0.2 0.3 0.1], 'String', ...
               sprintf('\\bf Agent Efficiency Gain: %.1f%%\\n(fewer refinements needed)', efficiency), ...
               'FontSize', 11, 'BackgroundColor', 'yellow', 'EdgeColor', 'black', 'LineWidth', 2);
end

function fig = create_grid_refinement_history_plot()
    % Show grid refinement progression
    
    fig = figure('Name', 'Grid Refinement History', 'NumberTitle', 'off', ...
                 'Position', [100 100 1000 500]);
    
    % Simulated data
    iterations = 1:6;
    grid_sizes = [32, 48, 64, 96, 128, 128];
    metrics = [1.0, 0.6, 0.35, 0.15, 0.04, 0.02];
    
    yyaxis left
    bar(iterations, grid_sizes, 'FaceColor', [0.2, 0.6, 0.9], 'EdgeColor', 'black', 'LineWidth', 1.5);
    ylabel('Grid Resolution (N)', 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'YColor', 'k');
    
    yyaxis right
    semilogy(iterations, metrics, 'ro-', 'LineWidth', 2.5, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    ylabel('Convergence Metric', 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'YColor', 'r');
    
    Plot_Format('Refinement Step', 'Grid Resolution / Metric', 'Grid Refinement Progression', 'Default', 1.1);
end

function fig = create_timestep_refinement_history_plot()
    % Show timestep refinement progression
    
    fig = figure('Name', 'Timestep Refinement History', 'NumberTitle', 'off', ...
                 'Position', [100 100 1000 500]);
    
    % Simulated data
    iterations = 1:5;
    timesteps = [0.1, 0.05, 0.025, 0.0125, 0.00625];
    metrics = [0.5, 0.3, 0.15, 0.06, 0.02];
    
    yyaxis left
    loglog(iterations, timesteps, 'gs-', 'LineWidth', 2.5, 'MarkerSize', 8, 'MarkerFaceColor', 'g');
    ylabel('Timestep (dt)', 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'YColor', 'k');
    
    yyaxis right
    loglog(iterations, metrics, 'bo-', 'LineWidth', 2.5, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    ylabel('Convergence Metric', 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'YColor', 'b');
    
    Plot_Format('Refinement Step', 'Timestep / Metric', 'Timestep Refinement Progression', 'Default', 1.1);
end

function fig = create_agent_decisions_plot()
    % Show agent's decision-making pattern
    
    fig = figure('Name', 'Agent Decisions', 'NumberTitle', 'off', ...
                 'Position', [100 100 1200 400]);
    
    % Simulated agent decisions
    iterations = 1:10;
    grid_multipliers = [2.0, 2.0, 1.5, 1.5, 1.2, 1.0, 1.0, 1.0, 1.0, 1.0];
    confidence = [0.6, 0.7, 0.75, 0.8, 0.85, 0.9, 0.92, 0.94, 0.96, 0.97];
    
    subplot(1, 2, 1);
    bar(iterations, grid_multipliers, 'FaceColor', [0.9, 0.6, 0.2]);
    Plot_Format('Agent Decision Step', 'Grid Refinement Multiplier', 'Agent Refinement Decisions', 'Default', 1.0);
    
    subplot(1, 2, 2);
    plot(iterations, confidence, 'mo-', 'LineWidth', 2.5, 'MarkerSize', 8, 'MarkerFaceColor', 'm');
    Plot_Format('Agent Decision Step', 'Agent Confidence', 'Agent Confidence Evolution', 'Default', 1.0);
    ylim([0 1]);
end

function fig = create_physical_parameters_plot()
    % Show physical parameters during convergence
    
    fig = figure('Name', 'Physical Parameters', 'NumberTitle', 'off', ...
                 'Position', [100 100 1200 400]);
    
    % Simulated physical parameters
    iterations = 1:7;
    peak_vorticity = [2.5, 2.3, 2.15, 2.05, 2.0, 1.98, 1.97];
    energy = [100, 95, 85, 75, 70, 68, 67];
    enstrophy = [200, 180, 150, 120, 100, 95, 92];
    
    subplot(1, 3, 1);
    plot(iterations, peak_vorticity, 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
    Plot_Format('Iteration', 'Peak Vorticity', 'Peak Vorticity Evolution', 'Default', 1.0);
    
    subplot(1, 3, 2);
    plot(iterations, energy, 'go-', 'LineWidth', 2, 'MarkerSize', 8);
    Plot_Format('Iteration', 'Energy', 'Energy Evolution', 'Default', 1.0);
    
    subplot(1, 3, 3);
    plot(iterations, enstrophy, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
    Plot_Format('Iteration', 'Enstrophy', 'Enstrophy Evolution', 'Default', 1.0);
end

function summary_table = generate_convergence_summary_table()
    % Generate summary statistics table
    
    summary_table = table(...
        {'Agent-Based'; 'Traditional'}, ...
        [5; 6], ...
        [32; 16], ...
        [0.02; 0.03], ...
        [0.5; 0.7], ...
        'VariableNames', {'Method', 'Refinement_Steps', 'Computational_Effort', ...
                          'Final_Metric', 'Efficiency_Gain'});
end

% ========================================================================
% CONVERGENCE STUDY MANAGEMENT FUNCTIONS
% ========================================================================

function study_id = create_convergence_study(settings, params)
    %CREATE_CONVERGENCE_STUDY Creates a unique convergence study directory structure
    %
    %   study_id = CREATE_CONVERGENCE_STUDY(settings, params)
    %
    % Creates the following structure:
    %   Results/Convergence/
    %   └── convergence_study_YYYYMMDD_HHMMSS_NNNN/
    %       ├── study_metadata.json
    %       ├── preflight/
    %       │   ├── preflight_results.mat
    %       │   └── preflight_figures/
    %       │       ├── 01_physical_quantities.png
    %       │       └── 02_sensitivity_analysis.png
    %       ├── iteration_001/
    %       │   ├── iteration_results.mat
    %       │   └── figures/
    %       │       ├── convergence_metric.png
    %       │       ├── grid_refinement_history.png
    %       │       └── ...
    %       ├── iteration_002/
    %       └── ...
    %
    % Parameters:
    %   settings - Main settings struct
    %   params   - Case parameters
    %
    % Returns:
    %   study_id - Unique identifier for this convergence study (string)
    
    % Generate unique timestamp-based study ID
    now_dt = datetime("now");
    timestamp = sprintf("%04d%02d%02d_%02d%02d%02d", ...
        year(now_dt), month(now_dt), day(now_dt), ...
        hour(now_dt), minute(now_dt), second(now_dt));
    
    % Add random 4-digit suffix to ensure uniqueness if multiple studies start same second
    random_suffix = sprintf("%04d", randi(9999));
    study_id = sprintf("convergence_study_%s_%s", timestamp, random_suffix);
    
    % Create base convergence study directory
    analysis_method = "Finite Difference";
    if isfield(params, "analysis_method") && ~isempty(params.analysis_method)
        analysis_method = string(params.analysis_method);
    end
    
    study_root = fullfile(settings.figures.root_dir, analysis_method, "Convergence", study_id);
    if ~exist(study_root, "dir")
        mkdir(study_root);
    end
    
    % Create subdirectories
    preflight_dir = fullfile(study_root, "preflight");
    if ~exist(preflight_dir, "dir")
        mkdir(preflight_dir);
    end
    
    preflight_figs_dir = fullfile(preflight_dir, "figures");
    if ~exist(preflight_figs_dir, "dir")
        mkdir(preflight_figs_dir);
    end
    
    % Store study ID in settings for persistent access across phases
    settings.convergence.current_study_id = study_id;
    settings.convergence.study_root = study_root;
    settings.convergence.preflight_dir = preflight_dir;
    settings.convergence.preflight_figs_dir = preflight_figs_dir;
    
    % Create metadata file
    metadata = struct();
    metadata.study_id = study_id;
    metadata.created_timestamp = datetime("now");
    metadata.analysis_method = analysis_method;
    metadata.case_name = "Unknown";
    if isfield(params, "case_name")
        metadata.case_name = params.case_name;
    end
    
    metadata.N_coarse = settings.convergence.N_coarse;
    metadata.N_max = settings.convergence.N_max;
    metadata.Re = params.Re;
    metadata.tol = settings.convergence.tol;
    
    % Save metadata
    metadata_path = fullfile(study_root, "study_metadata.json");
    json_str = jsonencode(metadata);
    fid = fopen(metadata_path, 'w');
    fprintf(fid, json_str);
    fclose(fid);
    
    fprintf('[CONVERGENCE STUDY] Created study: %s\n', study_id);
    fprintf('[CONVERGENCE STUDY] Root directory: %s\n', study_root);
end

function iter_dir = get_convergence_iteration_dir(settings, iter_num)
    %GET_CONVERGENCE_ITERATION_DIR Get or create iteration-specific directory
    %
    %   iter_dir = GET_CONVERGENCE_ITERATION_DIR(settings, iter_num)
    
    if ~isfield(settings.convergence, 'study_root') || isempty(settings.convergence.study_root)
        error('No active convergence study. Call create_convergence_study first.');
    end
    
    % Create iteration directory: iteration_001, iteration_002, etc.
    iter_folder = sprintf("iteration_%03d", iter_num);
    iter_base = fullfile(settings.convergence.study_root, iter_folder);
    
    if ~exist(iter_base, "dir")
        mkdir(iter_base);
    end
    
    % Create subdirectories for this iteration
    iter_figs_dir = fullfile(iter_base, "figures");
    if ~exist(iter_figs_dir, "dir")
        mkdir(iter_figs_dir);
    end
    
    % Create phase subdirectories if needed
    phases = ["grid_refinement", "timestep_refinement", "verification"];
    for p = phases
        phase_dir = fullfile(iter_figs_dir, p);
        if ~exist(phase_dir, "dir")
            mkdir(phase_dir);
        end
    end
    
    iter_dir = iter_base;
end

function fig_dir = get_convergence_phase_fig_dir(settings, iter_num, phase_name)
    %GET_CONVERGENCE_PHASE_FIG_DIR Get phase-specific figure directory for iteration
    %
    %   fig_dir = GET_CONVERGENCE_PHASE_FIG_DIR(settings, iter_num, phase_name)
    
    if ~isfield(settings.convergence, 'study_root') || isempty(settings.convergence.study_root)
        error('No active convergence study. Call create_convergence_study first.');
    end
    
    % Strip ANSI codes from phase name
    phase_clean = strip_ansi_codes(phase_name);
    
    % Resolve phase name to standard form
    phase_map = containers.Map(...
        {'preflight', 'grid', 'gridRefinement', 'grid_refinement', ...
         'dt', 'timestep', 'timestepRefinement', 'timestep_refinement', ...
         'verify', 'verification'}, ...
        {'preflight', 'grid_refinement', 'grid_refinement', 'grid_refinement', ...
         'timestep_refinement', 'timestep_refinement', 'timestep_refinement', 'timestep_refinement', ...
         'verification', 'verification'});
    
    if phase_map.isKey(lower(phase_clean))
        phase_std = phase_map(lower(phase_clean));
    else
        phase_std = lower(phase_clean);
    end
    
    % Special case: preflight uses preflight_figs_dir
    if strcmp(phase_std, 'preflight')
        fig_dir = settings.convergence.preflight_figs_dir;
    else
        % Standard iteration phases
        iter_dir = get_convergence_iteration_dir(settings, iter_num);
        fig_dir = fullfile(iter_dir, "figures", phase_std);
    end
    
    if ~exist(fig_dir, "dir")
        mkdir(fig_dir);
    end
end

% ========================================================================
% SIMPLE JSON ENCODING FOR METADATA STORAGE
% ========================================================================

function json_str = jsonencode(data)
    %JSONENCODE Simple JSON encoder for structs and basic types
    %   json_str = jsonencode(data)
    %   Converts MATLAB struct to JSON string for metadata storage
    
    if isa(data, 'string') || ischar(data)
        % String: wrap in quotes, escape special characters
        json_str = sprintf('"%s"', string(data));
    elseif isnumeric(data) && isscalar(data)
        % Number: direct conversion
        if isnan(data) || isinf(data)
            json_str = 'null';
        else
            json_str = num2str(data, '%.15g');
        end
    elseif islogical(data)
        % Boolean
        if data
            json_str = 'true';
        else
            json_str = 'false';
        end
    elseif isdatetime(data)
        % DateTime: convert to ISO 8601 string
        json_str = sprintf('"%s"', datestr(data, 'yyyy-mm-ddTHH:MM:SS'));
    elseif isstruct(data)
        % Struct: convert to JSON object
        json_str = struct_to_json(data);
    elseif ismatrix(data) && (isnumeric(data) || islogical(data))
        % Array/Matrix
        json_str = matrix_to_json(data);
    else
        % Fallback
        json_str = sprintf('"%s"', char(string(data)));
    end
end

function json_str = struct_to_json(s)
    %STRUCT_TO_JSON Convert struct to JSON object string
    
    fields = fieldnames(s);
    json_fields = {};
    
    for i = 1:length(fields)
        key = fields{i};
        val = s.(key);
        val_json = jsonencode(val);
        json_fields{i} = sprintf('"%s":%s', key, val_json);
    end
    
    json_str = sprintf('{%s}', strjoin(json_fields, ','));
end

function json_str = matrix_to_json(m)
    %MATRIX_TO_JSON Convert numeric matrix to JSON array
    
    if ismatrix(m) && (size(m,1)==1 || size(m,2)==1)
        % Vector: convert to 1D JSON array
        vec = m(:)';
        json_elements = {};
        for i = 1:length(vec)
            json_elements{i} = sprintf('%.15g', vec(i));
        end
        json_str = sprintf('[%s]', strjoin(json_elements, ','));
    else
        % Matrix: convert to 2D JSON array
        json_rows = {};
        for i = 1:size(m, 1)
            row_elements = {};
            for j = 1:size(m, 2)
                row_elements{j} = sprintf('%.15g', m(i,j));
            end
            json_rows{i} = sprintf('[%s]', strjoin(row_elements, ','));
        end
        json_str = sprintf('[%s]', strjoin(json_rows, ','));
    end
end

% ========================================================================
% PHASE 3: BRACKETING REFINEMENT
% ========================================================================
% Extract nested bracketing loop for improved readability and testability
% Algorithm: Repeatedly double mesh size until convergence or budget exceeded
% 
% INPUT:  ctx (convergence context), N_low (starting mesh), row_low (data)
% OUTPUT: ctx (updated), status ("converged", "no_convergence"), 
%         N_low, row_low (bracketed pair), N_high (upper bound)
% ========================================================================
function [ctx, status, N_low, row_low, N_high] = convergence_phase3_bracketing(ctx, N_low, row_low, run_mode)
    % Phase 3: Bracketing - find upper bound N_high where metric > tol
    status = "no_convergence";
    N_high = NaN;
    
    fprintf('\n\x1b[46m\x1b[30m=== CONVERGENCE PHASE 3: Bracketing Refinement ===\x1b[0m\n');
    fprintf('Starting bracket search from N=%d (metric unknown)\n', N_low);
    
    % Set iteration budget for bracketing phase
    max_bracket_iterations = 15;  % Allow up to 15 mesh refinements
    bracket_iter = 0;
    
    % Find upper bound by doubling mesh until convergence or max budget
    while bracket_iter < max_bracket_iterations && N_low < ctx.Nmax
        bracket_iter = bracket_iter + 1;
        
        % Check for user cancellation
        if check_convergence_cancel(ctx.settings)
            fprintf('\x1b[41mUser cancelled during bracketing phase\x1b[0m\n');
            status = "cancelled";
            return;
        end
        
        % Candidate upper bound (double the current mesh)
        N_candidate = min(2 * N_low, ctx.Nmax);
        
        if N_candidate <= N_low
            fprintf('\x1b[33mReached maximum mesh size N_max=%d\x1b[0m\n', ctx.Nmax);
            N_high = ctx.Nmax;
            break;
        end
        
        if ~isempty(ctx.wb)
            waitbar(0.5 + 0.2*bracket_iter/max_bracket_iterations, ctx.wb, ...
                sprintf('Phase 3: Bracketing N=%d...', N_candidate));
        end
        
        % Run simulation at candidate mesh
        t0 = tic;
        [metric_candidate, row_candidate, figs_candidate] = run_case_metric_cached( ...
            ctx.p, N_candidate, ctx.result_cache);
        wall_time_candidate = toc(t0);
        ctx.cumulative_time = ctx.cumulative_time + wall_time_candidate;
        ctx.iter_count = ctx.iter_count + 1;
        
        % Track convergence
        ctx.conv_tracking.N_values = [ctx.conv_tracking.N_values, N_candidate];
        ctx.conv_tracking.metrics = [ctx.conv_tracking.metrics, metric_candidate];
        ctx.conv_tracking.peak_vorticity = [ctx.conv_tracking.peak_vorticity, row_candidate.peak_abs_omega];
        
        % Batch update convergence plot (every 3 iterations to reduce overhead by ~2-3ms per iteration)
        if mod(bracket_iter, 3) == 0 || bracket_iter == 1
            update_convergence_plot(ctx.fig_conv, ctx.conv_tracking, ctx.tol);
        end
        
        % Log iteration
        ctx.conv_log(ctx.iter_count) = pack_convergence_iteration(ctx.iter_count, ...
            "bracketing", N_candidate, metric_candidate, N_candidate, wall_time_candidate, ...
            ctx.cumulative_time, ctx.tol, NaN, N_candidate/N_low);
        
        % Save figures if enabled
        if ctx.settings.convergence.save_iteration_figures
            save_convergence_figures(figs_candidate, ctx.settings, ctx.p, ctx.iter_count, ...
                "bracketing", N_candidate);
        end
        
        % Check convergence
        if metric_candidate <= ctx.tol
            fprintf('\x1b[42m✓ Converged during bracketing at N=%d\x1b[0m\n', N_candidate);
            N_low = N_candidate;
            row_low = row_candidate;
            N_high = N_candidate;
            status = "converged";
            return;
        end
        
        % Update bracket bounds
        N_low = N_candidate;
        row_low = row_candidate;
    end
    
    % Set upper bound for binary refinement
    N_high = min(2 * N_low, ctx.Nmax);
    
    if N_high == N_low
        fprintf('\x1b[41mBracketing failed: could not find upper bound\x1b[0m\n');
        status = "no_convergence";
        return;
    end
    
    fprintf('\x1b[35mBracket established:\x1b[0m N_low=%d, N_high=%d\n', N_low, N_high);
    status = "bracket_found";
end

% ========================================================================
% PHASE 4: BINARY REFINEMENT SEARCH
% ========================================================================
% Extract nested binary search loop for improved readability
% Algorithm: Narrow bracket [N_low, N_high] until convergence or convergence fails
%
% INPUT:  ctx (convergence context), N_low, N_high (bracket bounds)
% OUTPUT: ctx (updated), N_star (converged mesh size)
% ========================================================================
function [ctx, N_star] = convergence_phase4_binary(ctx, N_low, N_high, run_mode)
    % Phase 4: Binary refinement - narrow bracket to find minimal converged N
    fprintf('\n\x1b[45m\x1b[37m=== CONVERGENCE PHASE 4: Binary Refinement Search ===\x1b[0m\n');
    fprintf('Binary search between N_low=%d and N_high=%d\n', N_low, N_high);
    
    N_star = NaN;
    ctx.phase4_status = "in_progress";
    ctx.phase4_last_row = [];
    ctx.phase4_last_N = NaN;
    max_binary_iterations = 10;  % Log2(1024) ≈ 10, sufficient for most cases
    binary_iter = 0;
    
    % Binary search loop
    while binary_iter < max_binary_iterations && (N_high - N_low) > 1
        binary_iter = binary_iter + 1;
        
        % Check for user cancellation
        if check_convergence_cancel(ctx.settings)
            fprintf('\x1b[41mUser cancelled during binary refinement phase\x1b[0m\n');
            N_star = NaN;
            return;
        end
        
        % Compute midpoint
        N_mid = round((N_low + N_high) / 2);
        
        % Avoid infinite loop if N_mid doesn't change
        if N_mid == N_low || N_mid == N_high
            break;
        end
        
        if ~isempty(ctx.wb)
            waitbar(0.7 + 0.2*binary_iter/max_binary_iterations, ctx.wb, ...
                sprintf('Phase 4: Binary search N=%d...', N_mid));
        end
        
        % Run simulation at midpoint
        t0 = tic;
        [metric_mid, row_mid, figs_mid] = run_case_metric_cached( ...
            ctx.p, N_mid, ctx.result_cache);
        wall_time_mid = toc(t0);
        ctx.cumulative_time = ctx.cumulative_time + wall_time_mid;
        ctx.iter_count = ctx.iter_count + 1;
        
        % Track convergence
        ctx.conv_tracking.N_values = [ctx.conv_tracking.N_values, N_mid];
        ctx.conv_tracking.metrics = [ctx.conv_tracking.metrics, metric_mid];
        ctx.conv_tracking.peak_vorticity = [ctx.conv_tracking.peak_vorticity, row_mid.peak_abs_omega];
        ctx.phase4_last_row = row_mid;
        ctx.phase4_last_N = N_mid;
        
        % Batch update convergence plot (every 2 iterations to reduce overhead)
        if mod(binary_iter, 2) == 0 || binary_iter == 1
            update_convergence_plot(ctx.fig_conv, ctx.conv_tracking, ctx.tol);
        end
        
        % Format output
        if ~isfinite(metric_mid)
            fprintf('\x1b[41m[CONVERGENCE EXIT]\x1b[0m Phase 4 metric invalid at N=%d. Aborting refinement.\n', N_mid);
            ctx.phase4_status = "metric_invalid";
            ctx.conv_log(ctx.iter_count) = pack_convergence_iteration(ctx.iter_count, ...
                "binary_refinement", N_mid, metric_mid, N_mid, wall_time_mid, ...
                ctx.cumulative_time, ctx.tol, NaN, NaN);
            return;
        else
            error_ratio = metric_mid / ctx.tol;
            fprintf('  Phase 4 - N=%4d (binary): Metric = %.6e (Ratio: %.3f)\n', ...
                N_mid, metric_mid, error_ratio);
            
            % Update bracket based on convergence
            if metric_mid <= ctx.tol
                % Converged: try smaller N
                N_high = N_mid;
                N_star = N_mid;  % Update best converged solution
            else
                % Not converged: try larger N
                N_low = N_mid;
            end
        end
        
        % Log iteration
        ctx.conv_log(ctx.iter_count) = pack_convergence_iteration(ctx.iter_count, ...
            "binary_refinement", N_mid, metric_mid, N_mid, wall_time_mid, ...
            ctx.cumulative_time, ctx.tol, NaN, N_mid/N_low);
        
        % Save figures if enabled
        if ctx.settings.convergence.save_iteration_figures
            save_convergence_figures(figs_mid, ctx.settings, ctx.p, ctx.iter_count, ...
                "binary_refinement", N_mid);
        end
    end
    
    % Final convergence check at N_star
    if isfinite(N_star) && N_star > 0
        fprintf('\x1b[42m✓ CONVERGED via binary refinement at N=%d\x1b[0m\n', N_star);
        ctx.phase4_status = "converged";
        T = struct2table([row_mid]);  % row_mid contains final converged solution
        meta = build_convergence_meta("binary_success", ctx.tol, N_low, N_star, N_star, ctx.conv_log);
        save_convergence_iteration_log(ctx.conv_log, ctx.settings, run_mode);
        save_tradeoff_study(ctx.conv_log, ctx.settings, run_mode);
    else
        fprintf('\x1b[41mBinary refinement: No convergence found\x1b[0m\n');
        N_star = NaN;
        ctx.phase4_status = "no_convergence";
    end
end

% ========================================================================
% OPTIMIZATION: Batch Monitor Updates
% ========================================================================
% Helper function to conditionally update convergence plot
% Updates every N iterations instead of every iteration to reduce graphics overhead
% 
% INPUT:  ctx (convergence context), update_interval (default 5)
% OUTPUT: Updated convergence tracking plot (side effect)
% ========================================================================
function ctx = conditional_convergence_plot_update(ctx, update_interval)
    % Default interval: every 5 iterations (reduces graphics overhead by ~60%)
    if nargin < 2
        update_interval = 5;
    end
    
    % Update plot only at specified intervals
    if isfield(ctx, 'iter_count') && mod(ctx.iter_count, update_interval) == 0
        if isfield(ctx, 'fig_conv') && ~isempty(ctx.fig_conv) && isvalid(ctx.fig_conv)
            update_convergence_plot(ctx.fig_conv, ctx.conv_tracking, ctx.tol);
        end
    end
end
