function Tsunami_Vorticity_Emulator(varargin)
% TSUNAMI_VORTICITY_EMULATOR - Unified entry point for MECH0020 Tsunami Vortex Simulation
%
% Purpose:
%   Single unified driver for all tsunami vortex simulations
%   Combines functionality from Analysis.m, Tsunami_Simulator.m, and MECH0020_Run.m
%   Supports UI mode (3-tab interface) and Standard mode (CLI dispatcher)
%   Batch-friendly: no blocking input() calls when arguments are provided
%
% Usage:
%   Tsunami_Vorticity_Emulator()                    % Interactive: shows startup dialog
%   Tsunami_Vorticity_Emulator('Mode', 'UI')        % Direct UI launch
%   Tsunami_Vorticity_Emulator('Mode', 'Standard')  % Direct Standard mode (defaults)
%   Tsunami_Vorticity_Emulator('Mode', 'Standard', ...
%       'Method', 'FD', ...
%       'SimMode', 'Evolution', ...
%       'IC', 'Lamb-Oseen', ...
%       'Nx', 128, 'Ny', 128, ...
%       'dt', 0.001, 'Tfinal', 1.0)                 % Fully parameterised batch run
%
% Name-Value Arguments:
%   'Mode'      - 'UI' | 'Standard' | 'Interactive' (default: 'Interactive')
%   'Method'    - 'FD' | 'Spectral' | 'FV' (default: 'FD')
%   'SimMode'   - 'Evolution' | 'Convergence' | 'ParameterSweep' | 'Plotting'
%   'IC'        - Initial condition type (default: 'Lamb-Oseen')
%   'Nx'        - Grid points X (default: from Parameters.m)
%   'Ny'        - Grid points Y (default: from Parameters.m)
%   'dt'        - Timestep (default: from Parameters.m)
%   'Tfinal'    - Final time (default: from Parameters.m)
%   'nu'        - Viscosity (default: from Parameters.m)
%   'SaveFigs'  - Save figures (default: from Settings.m)
%   'SaveData'  - Save data (default: from Settings.m)
%   'Monitor'   - Enable monitor (default: from Settings.m)
%
% Configuration:
%   Edit Scripts/Editable/Parameters.m for physics/numerics
%   Edit Scripts/Editable/Settings.m for operational settings
%
% Modes:
%   - Evolution: Time evolution simulation
%   - Convergence: Grid refinement study
%   - ParameterSweep: Parameter sensitivity study
%   - Plotting: Visualize existing results
%
% Methods:
%   - FD: Finite Difference (fully supported)
%   - Spectral: FFT-based (framework ready, core implementation pending)
%   - FV: Finite Volume (framework ready, core implementation pending)
%
% Initial Conditions (9 types available):
%   - Lamb-Oseen: Classic viscous vortex
%   - Rankine: Piecewise constant vortex
%   - Lamb-Dipole: Counter-rotating vortex pair
%   - Taylor-Green: Periodic cellular flow
%   - Stretched-Gaussian: Anisotropic Gaussian vortex
%   - Elliptical-Vortex: Elliptical vortex core
%   - Random-Turbulence: Multi-scale turbulent field
%   - Gaussian: Simple Gaussian vortex
%   - Custom: User-defined (see ic_factory.m)
%
% Outputs:
%   Results saved to Data/Results/ with unique run ID
%   Master table updated in Data/Results/master_runs.csv
%
% See also: Parameters, Settings, ModeDispatcher, UIController
%
% Author: MECH0020 Analysis Framework
% Date: February 2026

    % ===== PARSE ARGUMENTS =====
    p = inputParser;
    addParameter(p, 'Mode',     'Interactive', @ischar);
    addParameter(p, 'Method',   'FD',          @ischar);
    addParameter(p, 'SimMode',  'Evolution',   @ischar);
    addParameter(p, 'IC',       '',            @ischar);
    addParameter(p, 'Nx',       0,             @isnumeric);
    addParameter(p, 'Ny',       0,             @isnumeric);
    addParameter(p, 'dt',       0,             @isnumeric);
    addParameter(p, 'Tfinal',   0,             @isnumeric);
    addParameter(p, 'nu',       0,             @isnumeric);
    addParameter(p, 'SaveFigs', -1,            @isnumeric);
    addParameter(p, 'SaveData', -1,            @isnumeric);
    addParameter(p, 'Monitor',  -1,            @isnumeric);
    parse(p, varargin{:});
    opts = p.Results;

    % ===== SETUP PATHS =====
    setup_paths();

    % ===== ROUTE BY MODE =====
    switch lower(opts.Mode)
        case 'ui'
            run_ui_mode();

        case 'standard'
            run_standard_mode(opts);

        case 'interactive'
            run_interactive_mode(opts);

        otherwise
            error('MECH0020:InvalidMode', ...
                'Unknown mode: %s. Use ''UI'', ''Standard'', or ''Interactive''.', opts.Mode);
    end
end

%% ========================================================================
%  SETUP
%% ========================================================================
function setup_paths()
    % Add all required directories to MATLAB path
    script_dir = fileparts(mfilename('fullpath'));
    repo_root  = fullfile(script_dir, '..', '..');

    addpath(fullfile(repo_root, 'Scripts', 'Drivers'));
    addpath(fullfile(repo_root, 'Scripts', 'Solvers'));
    addpath(fullfile(repo_root, 'Scripts', 'Modes'));
    addpath(fullfile(repo_root, 'Scripts', 'Modes', 'Convergence'));
    addpath(fullfile(repo_root, 'Scripts', 'Methods', 'FiniteDifference'));
    addpath(fullfile(repo_root, 'Scripts', 'Methods', 'Spectral'));
    addpath(fullfile(repo_root, 'Scripts', 'Methods', 'FiniteVolume'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Builds'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Compatibility'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'DataRelatedHelpers'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Initialisers'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Runners'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Utilities'));
    addpath(fullfile(repo_root, 'Scripts', 'Editable'));
    addpath(fullfile(repo_root, 'Scripts', 'UI'));
    addpath(fullfile(repo_root, 'Scripts', 'Plotting'));
    addpath(fullfile(repo_root, 'Scripts', 'Sustainability'));
    addpath(fullfile(repo_root, 'utilities'));
end

%% ========================================================================
%  INTERACTIVE MODE (startup dialog via UIController)
%% ========================================================================
function run_interactive_mode(opts)
    ColorPrintf.header('MECH0020 TSUNAMI VORTICITY EMULATOR');
    fprintf('  Unified Driver for Tsunami Vortex Simulations\n');
    fprintf('  Version 2.0 - Enhanced Parameter Control\n\n');

    % Launch UIController which shows startup dialog
    app = UIController();  %#ok<NASGU>

    % Check if user chose traditional/standard mode via appdata flag
    if isappdata(0, 'ui_mode') && strcmp(getappdata(0, 'ui_mode'), 'traditional')
        rmappdata(0, 'ui_mode');
        ColorPrintf.info('User selected Standard Mode from startup dialog.');
        ColorPrintf.info('Running in command-line mode with dispatcher architecture.');
        run_standard_mode(opts);
    else
        ColorPrintf.info('UI mode selected. Simulation runs within UI.');
    end
end

%% ========================================================================
%  UI MODE (direct launch)
%% ========================================================================
function run_ui_mode()
    ColorPrintf.header('MECH0020 TSUNAMI VORTICITY EMULATOR - UI MODE');
    app = UIController();  %#ok<NASGU>
    ColorPrintf.success('UI launched successfully.');
end

%% ========================================================================
%  STANDARD MODE (CLI dispatcher, batch-friendly)
%% ========================================================================
function run_standard_mode(opts)
    ColorPrintf.header('MECH0020 TSUNAMI VORTICITY EMULATOR - STANDARD MODE');

    % ===== BUILD CONFIGURATION =====
    params = Parameters();
    settings = Settings();

    % Apply overrides from command-line arguments
    if opts.Nx > 0,     params.Nx     = opts.Nx;     end
    if opts.Ny > 0,     params.Ny     = opts.Ny;     end
    if opts.dt > 0,     params.dt     = opts.dt;     end
    if opts.Tfinal > 0, params.Tfinal = opts.Tfinal; end
    if opts.nu > 0,     params.nu     = opts.nu;     end

    if opts.SaveFigs >= 0, settings.save_figures    = logical(opts.SaveFigs); end
    if opts.SaveData >= 0, settings.save_data       = logical(opts.SaveData); end
    if opts.Monitor  >= 0, settings.monitor_enabled = logical(opts.Monitor);  end

    % If Tfinal was overridden, regenerate snap_times to match
    if opts.Tfinal > 0
        n_snaps = length(params.snap_times);
        params.snap_times = linspace(0, params.Tfinal, max(n_snaps, 3));
    end

    % IC type: use argument or fall back to Parameters default
    ic_type = opts.IC;
    if isempty(ic_type)
        if isfield(params, 'ic_type') && ~isempty(params.ic_type)
            ic_type = params.ic_type;
        else
            ic_type = 'Lamb-Oseen';
        end
    end

    % Build Run_Config
    Run_Config = Build_Run_Config(opts.Method, opts.SimMode, ic_type);

    % ===== CONFIGURATION REPORT =====
    print_config_report(Run_Config, params, settings);

    % ===== RUN SIMULATION VIA DISPATCHER =====
    ColorPrintf.info('Launching simulation via ModeDispatcher...');
    fprintf('\n');

    try
        [Results, paths] = ModeDispatcher(Run_Config, params, settings);

        % ===== DISPLAY RESULTS =====
        ColorPrintf.header('SIMULATION COMPLETE');
        ColorPrintf.success(sprintf('Simulation completed successfully (%.2f s)', Results.wall_time));
        fprintf('\n');
        fprintf('Run ID:              %s\n', Results.run_id);
        fprintf('Wall Time:           %.2f s\n', Results.wall_time);
        fprintf('Final Time:          %.4f\n',   Results.final_time);
        fprintf('Max Vorticity:       %.4e\n\n', Results.max_omega);
        fprintf('Output Directory:    %s\n',     paths.base);
        if isfield(paths, 'reports')
            fprintf('Report:              %s\n', fullfile(paths.reports, 'Report.txt'));
        end
        fprintf('Master Table:        %s\n\n', PathBuilder.get_master_table_path());

    catch ME
        fprintf('\n');
        ErrorHandler.log('ERROR', 'RUN-EXEC-0003', ...
            'message', sprintf('Simulation failed: %s', ME.message), ...
            'file', mfilename, ...
            'context', struct('error_id', ME.identifier));

        fprintf('\nFull error details:\n');
        fprintf('  Identifier: %s\n', ME.identifier);
        fprintf('  Message:    %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('  Location:   %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        fprintf('\n');
        rethrow(ME);
    end
end

%% ========================================================================
%  CONFIGURATION REPORT
%% ========================================================================
function print_config_report(Run_Config, params, settings)
    ColorPrintf.section('CONFIGURATION REPORT');

    fprintf('[METHOD & MODE]\n');
    fprintf('  Method:              %s\n', Run_Config.method);
    fprintf('  Mode:                %s\n', Run_Config.mode);
    fprintf('  Initial Condition:   %s\n\n', Run_Config.ic_type);

    fprintf('[GRID & DOMAIN]\n');
    fprintf('  Nx x Ny:             %d x %d\n', params.Nx, params.Ny);
    fprintf('  Lx x Ly:             %.2f x %.2f\n', params.Lx, params.Ly);
    dx = params.Lx / params.Nx;
    dy = params.Ly / params.Ny;
    fprintf('  dx x dy:             %.4f x %.4f\n', dx, dy);
    fprintf('  Total Grid Points:   %d\n\n', params.Nx * params.Ny);

    fprintf('[TIME INTEGRATION]\n');
    fprintf('  dt:                  %.6f\n', params.dt);
    fprintf('  Tfinal:              %.2f\n', params.Tfinal);
    fprintf('  Steps:               %d\n', ceil(params.Tfinal / params.dt));
    fprintf('  Plot Snapshots:      %d\n', length(params.snap_times));
    if isfield(params, 'animation_num_frames')
        fprintf('  Animation Frames:    %d\n', params.animation_num_frames);
    end
    fprintf('\n');

    fprintf('[PHYSICS]\n');
    fprintf('  Viscosity (nu):      %.6f\n\n', params.nu);

    % CFL check
    max_velocity_est = 1.0;
    cfl = max_velocity_est * params.dt / min(dx, dy);
    fprintf('[STABILITY]\n');
    fprintf('  CFL number (est):    %.4f', cfl);
    if cfl < 0.5
        ColorPrintf.success_inline('  SAFE');
    elseif cfl < 1.0
        ColorPrintf.warn_inline('  CAUTION');
    else
        ColorPrintf.error_inline('  UNSTABLE');
    end
    fprintf('\n\n');

    fprintf('[OUTPUT SETTINGS]\n');
    fprintf('  Save Figures:        %s\n', bool2str(settings.save_figures));
    fprintf('  Save Data:           %s\n', bool2str(settings.save_data));
    fprintf('  Save Reports:        %s\n', bool2str(settings.save_reports));
    fprintf('  Append to Master:    %s\n', bool2str(settings.append_to_master));
    fprintf('  Monitor Enabled:     %s\n\n', bool2str(settings.monitor_enabled));

    fprintf('-----------------------------------------------------------\n\n');
    pause(0.5);  % Brief pause for user to review
end

function str = bool2str(val)
    if val, str = 'Yes'; else, str = 'No'; end
end
