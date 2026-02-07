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

% ===== RUN SIMULATION VIA DISPATCHER =====
fprintf('Configuration:\n');
fprintf('  Method: %s\n', Run_Config.method);
fprintf('  Mode: %s\n', Run_Config.mode);
fprintf('  IC: %s\n', Run_Config.ic_type);
fprintf('  Grid: %dx%d\n', Parameters.Nx, Parameters.Ny);
fprintf('  Time: dt=%.4f, Tfinal=%.2f\n\n', Parameters.dt, Parameters.Tfinal);

% Dispatch to appropriate mode module
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);

% ===== DISPLAY RESULTS =====
fprintf('\n═══════════════════════════════════════════════════════════════\n');
fprintf('  SIMULATION COMPLETE\n');
fprintf('═══════════════════════════════════════════════════════════════\n\n');

fprintf('Run ID: %s\n', Results.run_id);
fprintf('Wall Time: %.2f s\n', Results.wall_time);
fprintf('Final Time: %.4f\n', Results.final_time);
fprintf('Max Vorticity: %.4e\n\n', Results.max_omega);

fprintf('Output Directory: %s\n', paths.base);
fprintf('Report: %s\n', fullfile(paths.reports, 'Report.txt'));
fprintf('Master Table: %s\n\n', PathBuilder.get_master_table_path());

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
