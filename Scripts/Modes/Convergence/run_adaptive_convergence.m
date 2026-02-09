% run_adaptive_convergence.m - Standalone runner for Adaptive Convergence Agent
%
% Purpose:
%   Executes intelligent adaptive mesh convergence study using the
%   AdaptiveConvergenceAgent class. This agent learns from preflight tests
%   to intelligently navigate convergence rather than using fixed grid sweeps.
%
% Location: Scripts/Modes/Convergence/ (convergence-specific components)
%
% Features:
%   - Preflight testing to gather training data
%   - Pattern recognition for convergence behavior
%   - Adaptive jump factors based on observed rates
%   - Result caching to avoid redundant runs
%   - Early stopping when criterion met
%   - Sensitivity quantification
%   - Decision trace logging
%
% Usage:
%   cd Scripts/Modes/Convergence
%   run_adaptive_convergence
%
% Outputs:
%   - Convergence trace (saved to Results/convergence_trace.csv)
%   - Selected sequence of (Nx, Ny, dt) and metrics
%   - Final recommended converged configuration
%
% Dependencies:
%   - AdaptiveConvergenceAgent.m (same directory)
%   - Scripts/Infrastructure/* (paths added below)
%
% Author: MECH0020 Framework
% Date: February 2026

clc; clear; close all;

fprintf('========================================================================\n');
fprintf('  ADAPTIVE CONVERGENCE AGENT - INTELLIGENT MESH REFINEMENT\n');
fprintf('========================================================================\n\n');

% ===== SETUP PATHS =====
% Note: This script is in Scripts/Modes/Convergence, so repo_root is 3 levels up
script_dir = fileparts(mfilename('fullpath'));
repo_root = fullfile(script_dir, '..', '..', '..');

% Add all Scripts subdirectories to path
addpath(fullfile(repo_root, 'Scripts', 'Drivers'));
addpath(fullfile(repo_root, 'Scripts', 'Modes'));
addpath(fullfile(repo_root, 'Scripts', 'Modes', 'Convergence'));  % Self + agent
addpath(fullfile(repo_root, 'Scripts', 'Solvers'));
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

% ===== CREATE BASE PARAMETERS =====
% Use create_default_parameters if available, otherwise build manually
if exist('create_default_parameters', 'file') == 2
    Parameters = create_default_parameters();
else
    % Fallback: manual parameter creation
    Parameters = struct();
    Parameters.Lx = 10;
    Parameters.Ly = 10;
    Parameters.Nx = 64;  % Starting point (will be adapted)
    Parameters.Ny = 64;
    Parameters.delta = 2;
    Parameters.nu = 1e-6;
    Parameters.dt = 0.01;
    Parameters.Tfinal = 2.0;  % Shorter for convergence study
    Parameters.num_snapshots = 5;
    Parameters.ic_type = 'stretched_gaussian';
    Parameters.ic_coeff = [2, 0.2];
    Parameters.method = 'finite_difference';
    Parameters.mode = 'solve';
end

% Override for convergence study (shorter time, fewer snapshots)
Parameters.Tfinal = 1.0;
Parameters.num_snapshots = 3;

fprintf('Base Parameters:\n');
fprintf('  Domain: [%.1f x %.1f]\n', Parameters.Lx, Parameters.Ly);
fprintf('  Initial: Nx=%d, Ny=%d\n', Parameters.Nx, Parameters.Ny);
fprintf('  Time: dt=%.4f, Tfinal=%.2f\n', Parameters.dt, Parameters.Tfinal);
fprintf('  IC: %s\n', Parameters.ic_type);
fprintf('  Viscosity: %.2e\n\n', Parameters.nu);

% ===== CREATE SETTINGS FOR CONVERGENCE AGENT =====
settings = struct();

% Convergence settings
settings.convergence = struct();
settings.convergence.tolerance = 1e-3;  % Target convergence tolerance
settings.convergence.save_iteration_figures = true;  % Save figures for each iteration
settings.convergence.study_dir = fullfile(repo_root, 'Data', 'Output', 'Convergence_Study');
settings.convergence.preflight_figs_dir = fullfile(settings.convergence.study_dir, 'preflight');

% Create output directories
if ~exist(settings.convergence.study_dir, 'dir')
    mkdir(settings.convergence.study_dir);
end
if ~exist(settings.convergence.preflight_figs_dir, 'dir')
    mkdir(settings.convergence.preflight_figs_dir);
end

% Figure settings
settings.figures = struct();
settings.figures.close_after_save = true;  % Free memory after saving

fprintf('Convergence Study Settings:\n');
fprintf('  Tolerance: %.2e\n', settings.convergence.tolerance);
fprintf('  Output Dir: %s\n', settings.convergence.study_dir);
fprintf('  Save Iteration Figures: %s\n\n', string(settings.convergence.save_iteration_figures));

% ===== CREATE AND INITIALIZE AGENT =====
fprintf('Initializing Adaptive Convergence Agent...\n');
agent = AdaptiveConvergenceAgent(Parameters, settings);
fprintf('Agent initialized.\n\n');

% ===== RUN PREFLIGHT TESTS =====
fprintf('========================================================================\n');
fprintf('  PHASE 1: PREFLIGHT TESTING\n');
fprintf('========================================================================\n\n');

agent.run_preflight();

fprintf('\n========================================================================\n');
fprintf('  PHASE 2: ADAPTIVE CONVERGENCE EXECUTION\n');
fprintf('========================================================================\n\n');

% ===== EXECUTE CONVERGENCE STUDY =====
[N_star, results_table, metadata] = agent.execute_convergence_study();

% ===== SAVE RESULTS =====
fprintf('\n========================================================================\n');
fprintf('  SAVING RESULTS\n');
fprintf('========================================================================\n\n');

% Save convergence trace
trace_file = fullfile(settings.convergence.study_dir, 'convergence_trace.csv');
if ~isempty(results_table)
    writetable(results_table, trace_file);
    fprintf('Convergence trace saved: %s\n', trace_file);
end

% Save metadata
meta_file = fullfile(settings.convergence.study_dir, 'convergence_metadata.mat');
save(meta_file, 'metadata', 'N_star', 'Parameters', 'settings');
fprintf('Metadata saved: %s\n', meta_file);

% Save learning model details
learning_file = fullfile(settings.convergence.study_dir, 'learning_model.txt');
fid = fopen(learning_file, 'w');
fprintf(fid, 'ADAPTIVE CONVERGENCE AGENT - LEARNING MODEL\n');
fprintf(fid, '==========================================\n\n');
fprintf(fid, 'Convergence Rate (p): %.3f\n', metadata.learning_model.p_convergence);
fprintf(fid, 'Computational Scaling (alpha): %.3f\n', metadata.learning_model.alpha_cost);
fprintf(fid, 'Primary Quantity of Interest: %s\n', metadata.learning_model.primary_qoi);
fprintf(fid, 'Recommended Starting N: %d\n', metadata.learning_model.N_start_recommended);
fprintf(fid, 'Initial Jump Factor: %.2f\n', metadata.learning_model.initial_jump_factor);
fprintf(fid, '\n');
fprintf(fid, 'FINAL RESULTS\n');
fprintf(fid, '=============\n\n');
fprintf(fid, 'Converged Grid Resolution (N*): %d\n', N_star);
fprintf(fid, 'Target Tolerance: %.2e\n', metadata.tolerance);
fprintf(fid, 'Total Iterations: %d\n', metadata.total_iterations);
fprintf(fid, 'Total Time: %.2f seconds\n', metadata.total_time);
fprintf(fid, 'Preflight Runs: %d\n', metadata.preflight_runs);
fclose(fid);
fprintf('Learning model summary saved: %s\n', learning_file);

% ===== FINAL SUMMARY =====
fprintf('\n========================================================================\n');
fprintf('  ADAPTIVE CONVERGENCE STUDY COMPLETE\n');
fprintf('========================================================================\n\n');

fprintf('Converged Grid Resolution: N* = %d x %d\n', N_star, N_star);
fprintf('Target Tolerance: %.2e\n', metadata.tolerance);
fprintf('Total Iterations: %d\n', metadata.total_iterations);
fprintf('Total Time: %.2f seconds\n', metadata.total_time);
fprintf('Learning Model:\n');
fprintf('  Convergence Rate: p = %.2f\n', metadata.learning_model.p_convergence);
fprintf('  Cost Scaling: alpha = %.2f\n', metadata.learning_model.alpha_cost);
fprintf('  Primary QoI: %s\n', metadata.learning_model.primary_qoi);

fprintf('\nOutput Files:\n');
fprintf('  - Convergence Trace: %s\n', trace_file);
fprintf('  - Metadata: %s\n', meta_file);
fprintf('  - Learning Summary: %s\n', learning_file);
fprintf('  - Study Directory: %s\n', settings.convergence.study_dir);

fprintf('\n========================================================================\n\n');
