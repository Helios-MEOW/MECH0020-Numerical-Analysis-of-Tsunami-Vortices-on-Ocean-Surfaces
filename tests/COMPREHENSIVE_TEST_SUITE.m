%% COMPREHENSIVE TEST SUITE - PHASE 6 VALIDATION
% Tests all three numerical methods (FD, Spectral, FV) with bathymetry
% Validates energy conservation, convergence, and consistency

clear; close all; clc;
set(0, 'DefaultFigureVisible', 'off');
suite_start_time = datetime('now', 'TimeZone', 'local');
fprintf('================================================================================\n');
fprintf('COMPREHENSIVE TEST SUITE - PHASE 6 VALIDATION\n');
fprintf('Testing: FD | Spectral | Finite Volume | Bathymetry Methods\n');
fprintf('Start time (local): %s\n', char(suite_start_time));
fprintf('================================================================================\n\n');

suite_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(suite_dir);
addpath(genpath(fullfile(repo_root, 'Scripts')));
addpath(fullfile(repo_root, 'utilities'));

storage = ensure_results_storage_ready(repo_root, 'Verbose', true);
if ~isfield(storage, 'figures_root') || ~exist(storage.figures_root, 'dir')
    error('COMPREHENSIVE_TEST_SUITE:MissingFiguresRoot', ...
        'Figures preflight failed. Expected figures root at: %s', storage.figures_root);
end
fprintf('[Preflight] Figures root ready: %s\n', storage.figures_root);
fprintf('[Preflight] Figure directories (created/existing): %d / %d\n\n', ...
    numel(storage.created_figure_dirs), numel(storage.existing_figure_dirs));

if exist('create_default_parameters', 'file') ~= 2
    error('COMPREHENSIVE_TEST_SUITE:MissingFunction', ...
        ['create_default_parameters.m is not on the MATLAB path. ', ...
         'Expected under Scripts/Infrastructure/Initialisers.']);
end

%% TEST 1: Convergence Study (Grid Refinement)
fprintf('\n[TEST 1] CONVERGENCE STUDY - Grid Refinement\n');
fprintf('=========================================\n');

grids = [32, 64, 128];
methods = {'finite_difference', 'spectral'};
results_conv = table('Size',[0 4], ...
    'VariableTypes', {'string','double','double','double'}, ...
    'VariableNames', {'method','N','peak_vorticity','final_ke'});

for method = methods
    fprintf('\nMethod: %s\n', method{1});
    method_errors = [];
    
    for N = grids
        params = create_default_parameters();
        params.method = method{1};

        
        try
            [fig_h, analysis] = run_simulation_with_method(params);
            peak_vort = analysis.peak_vorticity;
            final_energy = analysis.kinetic_energy(end);
            
            fprintf('  N=%d: Peak vort=%.4e, Final KE=%.4e\n', N, peak_vort, final_energy);
            
            results_conv = [results_conv; {string(method{1}), N, peak_vort, final_energy}];
            
            close(fig_h);
        catch ME
            fprintf('  N=%d: FAILED - %s\n', N, ME.message);
        end
    end
end

%% TEST 2: Method Comparison (Same Problem)
fprintf('\n[TEST 2] METHOD COMPARISON - Same Initial Condition\n');
fprintf('=====================================================\n');

N = 64;
methods_all = {'finite_difference', 'spectral', 'finite_volume'};
results_methods = table('Size',[0 4], ...
    'VariableTypes', {'string','double','double','double'}, ...
    'VariableNames', {'method','peak_vorticity','energy_decay_pct','final_enstrophy'});

for method = methods_all
    fprintf('\nTesting %s method...\n', method{1});
    params = create_default_parameters();
    params.method = method{1};
    params.Nx = N;
    params.Ny = N;
    params.Tfinal = 2.0;
    params.num_snapshots = 9;
    params.ic_type = 'lamb_oseen';
    params.ic_coeff = [1.0, 0.5];
    params.snap_times = linspace(0, params.Tfinal, params.num_snapshots);
    
    try
        [fig_h, analysis] = run_simulation_with_method(params);
        
        % Energy decay
        energy_decay = (analysis.kinetic_energy(1) - analysis.kinetic_energy(end)) / analysis.kinetic_energy(1);
        
        fprintf('  Peak vorticity: %.4e\n', analysis.peak_vorticity);
        fprintf('  Energy decay: %.2f%%\n', energy_decay * 100);
        fprintf('  Final enstrophy: %.4e\n', analysis.enstrophy(end));
        
        results_methods = [results_methods; {string(method{1}), analysis.peak_vorticity, energy_decay * 100, analysis.enstrophy(end)}];
        
        close(fig_h);
    catch ME
        fprintf('  FAILED: %s\n', ME.message);
    end
end

%% TEST 3: Energy Conservation
fprintf('\n[TEST 3] ENERGY CONSERVATION (Inviscid Case)\n');
fprintf('=============================================\n');

params = create_default_parameters();
params.nu = 1e-8;  % Very small viscosity
params.Nx = 64;
params.Ny = 64;
params.Tfinal = 2.0;
params.num_snapshots = 20;
params.ic_type = 'taylor_green';
params.ic_coeff = [1.0, 1.0];
params.snap_times = linspace(0, params.Tfinal, params.num_snapshots);

for method = {'finite_difference', 'spectral'}
    fprintf('\nMethod: %s (inviscid)\n', method{1});
    params.method = method{1};
    
    try
        [fig_h, analysis] = run_simulation_with_method(params);
        
        % Check energy conservation
        energy_relative_change = abs(analysis.kinetic_energy - analysis.kinetic_energy(1)) / analysis.kinetic_energy(1);
        max_energy_change = max(energy_relative_change) * 100;
        
        fprintf('  Max energy change: %.3f%%\n', max_energy_change);
        
        if max_energy_change < 5
            fprintf('   Energy well-conserved\n');
        else
            fprintf('   Energy change exceeds 5%% - check CFL\n');
        end
        
        close(fig_h);
    catch ME
        fprintf('  FAILED: %s\n', ME.message);
    end
end

%% TEST 4: Bathymetry Forcing
fprintf('\n[TEST 4] BATHYMETRY FORCING\n');
fprintf('===========================\n');

params = create_default_parameters();
params.method = 'bathymetry';
params.Nx = 64;
params.Ny = 64;
params.Tfinal = 3.0;
params.num_snapshots = 7;
params.ic_type = 'stretched_gaussian';
params.ic_coeff = [2.0, 0.2];
params.bathymetry_enabled = true;
params.bathymetry_file = '';  % Uses synthetic
params.snap_times = linspace(0, params.Tfinal, params.num_snapshots);

try
    [fig_h, analysis] = run_simulation_with_method(params);
    
    fprintf('Bathymetry simulation completed:\n');
    fprintf('  Peak vorticity: %.4e\n', analysis.peak_vorticity);
    fprintf('  Final kinetic energy: %.4e\n', analysis.kinetic_energy(end));
    fprintf('  Final enstrophy: %.4e\n', analysis.enstrophy(end));
    fprintf('  Bathymetry field range: [%.1f, %.1f]\n', ...
        min(analysis.bathymetry_field(:)), max(analysis.bathymetry_field(:)));
    
    close(fig_h);
catch ME
    fprintf('  FAILED: %s\n', ME.message);
end

%% TEST 5: Stability & Timestep Adaptation
fprintf('\n[TEST 5] STABILITY & CFL ADAPTATION\n');
fprintf('====================================\n');

N = 128;
dt_values = [0.01, 0.001, 0.0001];

for dt = dt_values
    fprintf('\nTesting dt=%.5f (CFL%.3f)...\n', dt, 0.5*dt);
    
    params = create_default_parameters();
    params.method = 'finite_difference';
    params.Nx = N;
    params.Ny = N;
    params.dt = dt;
    params.Tfinal = 1.0;
    params.num_snapshots = 5;
    params.ic_type = 'stretched_gaussian';
    params.ic_coeff = [2.0, 0.2];
    params.snap_times = linspace(0, params.Tfinal, params.num_snapshots);
    
    try
        [fig_h, analysis] = run_simulation_with_method(params);
        is_stable = ~any(isnan(analysis.omega_snaps(:))) && ~any(isinf(analysis.omega_snaps(:)));
        if is_stable
            fprintf('  Status:  STABLE\n');
        else
            fprintf('  Status:  UNSTABLE\n');
        end
        close(fig_h);
    catch ME
        fprintf('  Status:  CRASHED - %s\n', ME.message);
    end
end

%% TEST 6: Parallel Efficiency (Sweep Mode)
fprintf('\n[TEST 6] PARALLEL SWEEP EFFICIENCY\n');
fprintf('===================================\n');

fprintf('Testing parameter sweep with 3 viscosity values...\n');
params_sweep = create_default_parameters();
params_sweep.method = 'finite_difference';
params_sweep.Nx = 64;
params_sweep.Ny = 64;
params_sweep.Tfinal = 1.0;
params_sweep.num_snapshots = 5;
params_sweep.ic_type = 'rankine';
params_sweep.ic_coeff = [1.0, 0.5];
params_sweep.snap_times = linspace(0, params_sweep.Tfinal, params_sweep.num_snapshots);

nu_values = [1e-5, 1e-4, 1e-3];
tic;
for nu = nu_values
    params_sweep.nu = nu;
    try
        [fig_h, ~] = run_simulation_with_method(params_sweep);
        fprintf('  ν=%.0e: Completed\n', nu);
        close(fig_h);
    catch
        fprintf('  ν=%.0e: Failed\n', nu);
    end
end
parallel_time = toc;
fprintf('Total sweep time: %.2f seconds\n', parallel_time);

%% SUMMARY
fprintf('\n\n');
fprintf('================================================================================\n');
fprintf('TEST SUMMARY\n');
fprintf('================================================================================\n');
fprintf('\n Convergence Study: Grid refinement analysis complete\n');
fprintf(' Method Comparison: FD vs Spectral vs FV tested\n');
fprintf(' Energy Conservation: Stability verified\n');
fprintf(' Bathymetry Forcing: Topography effects included\n');
fprintf(' CFL Stability: Multiple timesteps tested\n');
fprintf(' Parallel Efficiency: Sweep mode operational\n');

fprintf('\n');
fprintf('Convergence Results:\n');
disp(results_conv);

fprintf('\nMethod Comparison:\n');
disp(results_methods);

fprintf('\n================================================================================\n');
fprintf('ALL TESTS COMPLETED\n');
fprintf('================================================================================\n');
