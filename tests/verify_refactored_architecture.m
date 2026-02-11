% verify_refactored_architecture.m - Smoke test for current method-agnostic architecture
%
% Verifies:
%   1) Architecture compliance checks
%   2) Compatibility matrix state for FD/Spectral/FV
%   3) mode_evolution smoke for FD and Spectral
%   4) mode_convergence blocked path for FV checkpoint

fprintf('\n');
fprintf('===============================================================\n');
fprintf('  REFACTORED ARCHITECTURE VERIFICATION\n');
fprintf('===============================================================\n\n');

addpath(genpath('Scripts'));
addpath('tests');

%% TEST 1: Architecture Compliance
fprintf('[TEST 1] Running architecture compliance test...\n');
test_architecture_compliance();
fprintf('[TEST 1] PASSED\n\n');

%% TEST 2: Compatibility Matrix
fprintf('[TEST 2] Testing compatibility matrix...\n');

[status_fd, ~] = compatibility_matrix('FD', 'Evolution');
assert(strcmp(status_fd, 'supported'), 'FD + Evolution should be supported');
fprintf('  PASS FD + Evolution: %s\n', status_fd);

[status_sp, reason_sp] = compatibility_matrix('Spectral', 'Evolution');
assert(strcmp(status_sp, 'experimental'), 'Spectral + Evolution should be experimental');
fprintf('  PASS Spectral + Evolution: %s (%s)\n', status_sp, reason_sp);

[status_fv, reason_fv] = compatibility_matrix('FV', 'Evolution');
assert(strcmp(status_fv, 'experimental'), 'FV + Evolution should be experimental');
fprintf('  PASS FV + Evolution: %s (%s)\n', status_fv, reason_fv);

[status_fv_conv, reason_fv_conv] = compatibility_matrix('FV', 'Convergence');
assert(strcmp(status_fv_conv, 'blocked'), 'FV + Convergence should remain blocked in this checkpoint');
fprintf('  PASS FV + Convergence: %s (%s)\n', status_fv_conv, reason_fv_conv);

fprintf('[TEST 2] PASSED\n\n');

%% TEST 3: mode_evolution smoke (FD + Spectral)
fprintf('[TEST 3] Running mode_evolution smoke tests...\n');

base_params = struct();
base_params.Nx = 16;
base_params.Ny = 16;
base_params.Lx = 2 * pi;
base_params.Ly = 2 * pi;
base_params.dt = 0.005;
base_params.Tfinal = 0.02;
base_params.nu = 0.001;
base_params.snap_times = [0, 0.01, 0.02];

Settings = struct();
Settings.save_figures = false;
Settings.save_data = false;
Settings.save_reports = false;
Settings.append_to_master = false;
Settings.monitor_enabled = false;

rc_fd = struct('method', 'FD', 'mode', 'Evolution', 'ic_type', 'Gaussian', 'run_id', 'smoke_fd');
[res_fd, ~] = mode_evolution(rc_fd, base_params, Settings);
assert(isfield(res_fd, 'max_omega') && isfinite(res_fd.max_omega), 'FD evolution smoke failed');
fprintf('  PASS FD evolution smoke\n');

rc_sp = struct('method', 'Spectral', 'mode', 'Evolution', 'ic_type', 'Gaussian', 'run_id', 'smoke_spectral');
[res_sp, ~] = mode_evolution(rc_sp, base_params, Settings);
assert(isfield(res_sp, 'max_omega') && isfinite(res_sp.max_omega), 'Spectral evolution smoke failed');
fprintf('  PASS Spectral evolution smoke\n');

fprintf('[TEST 3] PASSED\n\n');

%% TEST 4: mode_convergence blocked path for FV
fprintf('[TEST 4] Validating FV convergence blocked path...\n');

try
    rc_fv = struct('method', 'FV', 'mode', 'Convergence', 'ic_type', 'Gaussian', 'study_id', 'smoke_fv_conv');
    base_params.mesh_sizes = [8, 16];
    [~, ~] = ModeDispatcher(rc_fv, base_params, Settings); %#ok<ASGLU>
    error('Expected FV convergence to be blocked but it executed.');
catch ME
    if contains(ME.identifier, 'SOL') || contains(ME.message, 'not enabled') || contains(ME.message, 'SOL-FV-0001')
        fprintf('  PASS FV convergence correctly blocked\n');
    else
        rethrow(ME);
    end
end

fprintf('[TEST 4] PASSED\n\n');

fprintf('===============================================================\n');
fprintf('  VERIFICATION COMPLETE\n');
fprintf('===============================================================\n\n');
