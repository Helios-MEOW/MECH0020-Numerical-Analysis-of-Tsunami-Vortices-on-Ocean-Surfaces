% Analysis.m - Main entry point for MECH0020 Tsunami Vortex Simulation
%
% Purpose:
%   Thin dispatcher-based driver (MECH0020 compliant)
%   Uses ModeDispatcher and structured configs
%   Can run in Standard mode or UI mode

clc; clear; close all;

% ===== SETUP PATHS =====
script_dir = fileparts(mfilename('fullpath'));
repo_root = fullfile(script_dir, '..', '..');

addpath(fullfile(repo_root, 'Scripts', 'Drivers'));
addpath(fullfile(repo_root, 'Scripts', 'Solvers'));
addpath(fullfile(repo_root, 'Scripts', 'Solvers', 'FD'));
addpath(fullfile(repo_root, 'Scripts', 'Modes'));
addpath(fullfile(repo_root, 'Scripts', 'Modes', 'Convergence'));
addpath(fullfile(repo_root, 'Scripts', 'Methods', 'FiniteDifference'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Builds'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'DataRelatedHelpers'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Initialisers'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Runners'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Utilities'));
addpath(fullfile(repo_root, 'Scripts', 'Editable'));
addpath(fullfile(repo_root, 'Scripts', 'UI'));
addpath(fullfile(repo_root, 'Scripts', 'Plotting'));
addpath(fullfile(repo_root, 'Scripts', 'Sustainability'));
addpath(fullfile(repo_root, 'utilities'));

% ===== MODE SELECTION =====
% Launch UI startup dialog for mode selection
% User can choose between UI Mode (3-tab interface) or Standard Mode (CLI)

fprintf('========================================\n');
fprintf('MECH0020 TSUNAMI VORTEX SIMULATION\n');
fprintf('========================================\n\n');

% Launch UIController which shows startup dialog
app = UIController();

% Check if user chose traditional/standard mode
if isappdata(0, 'ui_mode') && strcmp(getappdata(0, 'ui_mode'), 'traditional')
    rmappdata(0, 'ui_mode');
    fprintf('\nUser selected Standard Mode from startup dialog.\n');
    fprintf('Running in command-line mode with dispatcher architecture.\n\n');
    % Continue to standard mode below
else
    % UI mode was selected - UIController handles everything
    fprintf('UI mode selected. Simulation runs within UI.\n');
    return;  % Exit script, user works in UI
end

% ===== STANDARD MODE =====
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('  MECH0020 TSUNAMI VORTEX SIMULATION - STANDARD MODE\n');
fprintf('═══════════════════════════════════════════════════════════════\n\n');

% ===== PREFLIGHT CONFIRMATION =====
fprintf('───────────────────────────────────────────────────────────────\n');
fprintf('  PREFLIGHT CHECK\n');
fprintf('───────────────────────────────────────────────────────────────\n\n');

% Ask user if they have edited parameters
response = input('Have you edited parameters in this script? (Y/N): ', 's');

if isempty(response) || ~strcmpi(response, 'y')
    fprintf('\n');
    ErrorHandler.log('WARN', 'CFG-VAL-0003', ...
        'message', 'Running with default parameters. Edit Analysis.m lines 60-78 to customize.', ...
        'file', mfilename);
    fprintf('\n');

    cont_response = input('Continue anyway? (Y/N): ', 's');
    if ~strcmpi(cont_response, 'y')
        fprintf('\nAborted by user.\n');
        return;
    end
    fprintf('\n');
else
    ErrorHandler.log_success('Parameters edited - proceeding with custom configuration');
    fprintf('\n');
end

% ===== BUILD CONFIGURATION =====
% Use builder functions from Scripts/Infrastructure/

% Run_Config: method, mode, IC
Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');

% Parameters: physics + numerics (from Editable defaults)
Parameters = Parameters();
% Override as needed:
Parameters.Nx = 128;
Parameters.Ny = 128;
Parameters.Tfinal = 1.0;
Parameters.dt = 0.001;

% Settings: operational (from Editable defaults)
Settings = Settings();
% Override as needed:
Settings.save_figures = true;
Settings.save_data = true;
Settings.save_reports = true;
Settings.append_to_master = true;
Settings.monitor_enabled = true;
Settings.monitor_theme = 'dark';

% ===== CONFIGURATION REPORT =====
fprintf('───────────────────────────────────────────────────────────────\n');
fprintf('  CONFIGURATION REPORT\n');
fprintf('───────────────────────────────────────────────────────────────\n\n');

fprintf('[METHOD & MODE]\n');
fprintf('  Method:              %s\n', Run_Config.method);
fprintf('  Mode:                %s\n', Run_Config.mode);
fprintf('  Initial Condition:   %s\n\n', Run_Config.ic_type);

fprintf('[GRID & DOMAIN]\n');
fprintf('  Nx × Ny:             %d × %d\n', Parameters.Nx, Parameters.Ny);
fprintf('  Lx × Ly:             %.2f × %.2f\n', Parameters.Lx, Parameters.Ly);
fprintf('  dx × dy:             %.4f × %.4f\n', ...
    Parameters.Lx/Parameters.Nx, Parameters.Ly/Parameters.Ny);
fprintf('  Total Grid Points:   %d\n\n', Parameters.Nx * Parameters.Ny);

fprintf('[TIME INTEGRATION]\n');
fprintf('  dt:                  %.6f\n', Parameters.dt);
fprintf('  Tfinal:              %.2f\n', Parameters.Tfinal);
fprintf('  Steps:               %d\n', ceil(Parameters.Tfinal / Parameters.dt));
fprintf('  Snapshots:           %d\n\n', length(Parameters.snap_times));

fprintf('[PHYSICS]\n');
fprintf('  Viscosity (nu):      %.6f\n\n', Parameters.nu);

% CFL check
dx = Parameters.Lx / Parameters.Nx;
dy = Parameters.Ly / Parameters.Ny;
max_velocity_est = 1.0;  % Conservative estimate
cfl = max_velocity_est * Parameters.dt / min(dx, dy);
fprintf('[STABILITY]\n');
fprintf('  CFL number (est):    %.4f', cfl);
if cfl < 0.5
    fprintf('  ✓ SAFE\n');
elseif cfl < 1.0
    fprintf('  ⚠ CAUTION\n');
else
    fprintf('  ✗ UNSTABLE\n');
end
fprintf('\n');

fprintf('[OUTPUT SETTINGS]\n');
fprintf('  Save Figures:        %s\n', bool2str(Settings.save_figures));
fprintf('  Save Data:           %s\n', bool2str(Settings.save_data));
fprintf('  Save Reports:        %s\n', bool2str(Settings.save_reports));
fprintf('  Append to Master:    %s\n', bool2str(Settings.append_to_master));
fprintf('  Monitor Enabled:     %s\n\n', bool2str(Settings.monitor_enabled));

fprintf('───────────────────────────────────────────────────────────────\n\n');

pause(1);  % Give user time to review

% ===== RUN SIMULATION VIA DISPATCHER =====
ErrorHandler.log_info('Launching simulation via ModeDispatcher...');
fprintf('\n');

try
    % Dispatch to appropriate mode module
    [Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);

    % ===== DISPLAY RESULTS =====
    fprintf('\n═══════════════════════════════════════════════════════════════\n');
    fprintf('  SIMULATION COMPLETE\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');

    ErrorHandler.log_success(sprintf('Simulation completed successfully (%.2f s)', Results.wall_time));
    fprintf('\n');

    fprintf('Run ID:              %s\n', Results.run_id);
    fprintf('Wall Time:           %.2f s\n', Results.wall_time);
    fprintf('Final Time:          %.4f\n', Results.final_time);
    fprintf('Max Vorticity:       %.4e\n\n', Results.max_omega);

    fprintf('Output Directory:    %s\n', paths.base);
    if isfield(paths, 'reports')
        fprintf('Report:              %s\n', fullfile(paths.reports, 'Report.txt'));
    end
    fprintf('Master Table:        %s\n\n', PathBuilder.get_master_table_path());

catch ME
    % Simulation failed - use structured error logging
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


% ===== EXAMPLE: OTHER MODES =====
% Uncomment to try other modes:

% % Convergence study
% Run_Config = Build_Run_Config('FD', 'Convergence', 'Gaussian');
% Parameters.mesh_sizes = [32, 64, 128];
% [Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);

% % Parameter sweep
% Run_Config = Build_Run_Config('FD', 'ParameterSweep', 'Lamb-Oseen');
% Parameters.sweep_parameter = 'nu';
% Parameters.sweep_values = [0.0005, 0.001, 0.002];
% [Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);

% % Plotting mode (recreate from existing run)
% Run_Config = Build_Run_Config('FD', 'Plotting', 'Lamb-Oseen', 'source_run_id', '<run_id>');
% Parameters.plot_types = {'contours', 'streamlines', 'evolution'};
% [Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);


%% Helper Function
function str = bool2str(val)
    % Convert boolean to 'Yes'/'No' string
    if val
        str = 'Yes';
    else
        str = 'No';
    end
end
