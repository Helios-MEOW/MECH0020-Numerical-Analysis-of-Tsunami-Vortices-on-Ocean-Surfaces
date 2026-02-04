%% TEST: Method Dispatcher Integration
% This script tests that the method dispatcher correctly routes simulations
% to Finite Difference, Spectral, Finite Volume, and Variable Bathymetry methods

clear; close all; clc;
fprintf('========================================\n');
fprintf('METHOD DISPATCHER TEST SUITE\n');
fprintf('========================================\n\n');

% Add paths
addpath(genpath('./Scripts'));
addpath(genpath('./utilities'));

%% Test 1: Finite Difference Method
fprintf('[Test 1] Finite Difference Method...\n');
params_fd = create_default_parameters();
params_fd.method = 'finite_difference';
params_fd.Nx = 64;
params_fd.Ny = 64;
params_fd.Tfinal = 1.0;
params_fd.num_snapshots = 3;
params_fd.ic_type = 'stretched_gaussian';
params_fd.ic_coeff = [2.0, 0.2];
params_fd.snap_times = linspace(0, params_fd.Tfinal, params_fd.num_snapshots);

try
    [fig_fd, analysis_fd] = run_simulation_with_method(params_fd);
    fprintf('   FD simulation completed\n');
    fprintf('    Method used: %s\n', analysis_fd.method);
    fprintf('    Omega range: [%.4f, %.4f]\n', min(analysis_fd.omega_snaps(:)), max(analysis_fd.omega_snaps(:)));
    close(fig_fd);
catch ME
    fprintf('   FD simulation failed: %s\n', ME.message);
end

%% Test 2: Spectral Method
fprintf('\n[Test 2] Spectral (FFT) Method...\n');
params_spectral = create_default_parameters();
params_spectral.method = 'spectral';
params_spectral.Nx = 64;
params_spectral.Ny = 64;
params_spectral.Tfinal = 1.0;
params_spectral.num_snapshots = 3;
params_spectral.ic_type = 'stretched_gaussian';
params_spectral.ic_coeff = [2.0, 0.2];
params_spectral.snap_times = linspace(0, params_spectral.Tfinal, params_spectral.num_snapshots);

try
    [fig_spectral, analysis_spectral] = run_simulation_with_method(params_spectral);
    fprintf('   Spectral simulation completed\n');
    fprintf('    Method used: %s\n', analysis_spectral.method);
    fprintf('    Omega range: [%.4f, %.4f]\n', min(analysis_spectral.omega_snaps(:)), max(analysis_spectral.omega_snaps(:)));
    close(fig_spectral);
catch ME
    fprintf('   Spectral simulation failed: %s\n', ME.message);
end

%% Test 3: Finite Volume Method (Placeholder)
fprintf('\n[Test 3] Finite Volume Method...\n');
params_fv = create_default_parameters();
params_fv.method = 'finite_volume';
params_fv.Nx = 64;
params_fv.Ny = 64;
params_fv.Tfinal = 1.0;
params_fv.num_snapshots = 3;
params_fv.ic_type = 'stretched_gaussian';
params_fv.ic_coeff = [2.0, 0.2];
params_fv.snap_times = linspace(0, params_fv.Tfinal, params_fv.num_snapshots);

try
    [fig_fv, analysis_fv] = run_simulation_with_method(params_fv);
    fprintf('   FV simulation completed\n');
    fprintf('    Method used: %s\n', analysis_fv.method);
    fprintf('    Omega range: [%.4f, %.4f]\n', min(analysis_fv.omega_snaps(:)), max(analysis_fv.omega_snaps(:)));
    close(fig_fv);
catch ME
    fprintf('   FV simulation failed: %s\n', ME.message);
end

%% Test 4: Variable Bathymetry Method (Placeholder)
fprintf('\n[Test 4] Variable Bathymetry Method...\n');
params_bathy = create_default_parameters();
params_bathy.method = 'bathymetry';
params_bathy.Nx = 64;
params_bathy.Ny = 64;
params_bathy.Tfinal = 1.0;
params_bathy.num_snapshots = 3;
params_bathy.ic_type = 'stretched_gaussian';
params_bathy.ic_coeff = [2.0, 0.2];
params_bathy.snap_times = linspace(0, params_bathy.Tfinal, params_bathy.num_snapshots);

try
    [fig_bathy, analysis_bathy] = run_simulation_with_method(params_bathy);
    fprintf('   Bathymetry simulation completed\n');
    fprintf('    Method used: %s\n', analysis_bathy.method);
    fprintf('    Omega range: [%.4f, %.4f]\n', min(analysis_bathy.omega_snaps(:)), max(analysis_bathy.omega_snaps(:)));
    close(fig_bathy);
catch ME
    fprintf('   Bathymetry simulation failed: %s\n', ME.message);
end

fprintf('\n========================================\n');
fprintf('TEST SUITE COMPLETE\n');
fprintf('========================================\n');
