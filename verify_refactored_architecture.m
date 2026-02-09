% verify_refactored_architecture.m - Smoke test for new architecture
%
% Purpose:
%   Verifies that the refactored method-agnostic architecture works
%   Runs minimal smoke tests with mode_evolution + FD method
%
% Tests:
%   1. Mode Evolution with FD method (minimal grid, short time)
%   2. Compatibility matrix blocking (Spectral + Evolution should fail)
%
% Usage:
%   From repo root: matlab -batch "verify_refactored_architecture"

fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('  REFACTORED ARCHITECTURE VERIFICATION\n');
fprintf('═══════════════════════════════════════════════════════════════\n\n');

% Add paths
addpath(genpath('Scripts'));
addpath('tests');

%% TEST 1: Architecture Compliance
fprintf('[TEST 1] Running architecture compliance test...\n');
test_architecture_compliance();
fprintf('[TEST 1] PASSED: Architecture compliance verified\n\n');

%% TEST 2: Compatibility Matrix
fprintf('[TEST 2] Testing compatibility matrix...\n');

% Should be supported
[status, ~] = compatibility_matrix('FD', 'Evolution');
assert(strcmp(status, 'supported'), 'FD + Evolution should be supported');
fprintf('  ✓ FD + Evolution: supported\n');

% Should be blocked
[status, reason] = compatibility_matrix('Spectral', 'Evolution');
assert(strcmp(status, 'blocked'), 'Spectral + Evolution should be blocked');
fprintf('  ✓ Spectral + Evolution: blocked (reason: %s)\n', reason);

fprintf('[TEST 2] PASSED: Compatibility matrix works correctly\n\n');

%% TEST 3: Mode Evolution Smoke Test (FD, minimal)
fprintf('[TEST 3] Running mode_evolution smoke test (FD, 16x16, 10 steps)...\n');

try
    % Minimal configuration
    Run_Config = struct();
    Run_Config.method = 'FD';
    Run_Config.mode = 'Evolution';
    Run_Config.ic_type = 'Gaussian';
    Run_Config.run_id = 'smoke_test_evolution';

    Parameters = struct();
    Parameters.Nx = 16;
    Parameters.Ny = 16;
    Parameters.Lx = 2 * pi;
    Parameters.Ly = 2 * pi;
    Parameters.dt = 0.01;
    Parameters.Tfinal = 0.1;  % Only 10 steps
    Parameters.nu = 0.001;
    Parameters.snap_times = [0, 0.05, 0.1];

    Settings = struct();
    Settings.save_figures = false;
    Settings.save_data = false;
    Settings.save_reports = false;
    Settings.append_to_master = false;
    Settings.monitor_enabled = false;

    % Run Evolution mode
    [Results, paths] = mode_evolution(Run_Config, Parameters, Settings);

    % Verify results
    assert(isfield(Results, 'run_id'), 'Results should have run_id');
    assert(isfield(Results, 'wall_time'), 'Results should have wall_time');
    assert(isfield(Results, 'max_omega'), 'Results should have max_omega');

    fprintf('  ✓ Evolution mode completed successfully\n');
    fprintf('    Run ID: %s\n', Results.run_id);
    fprintf('    Wall time: %.3f s\n', Results.wall_time);
    fprintf('    Max omega: %.3e\n', Results.max_omega);
    fprintf('[TEST 3] PASSED: mode_evolution works correctly\n\n');

catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
    fprintf('    Identifier: %s\n', ME.identifier);
    if ~isempty(ME.stack)
        fprintf('    Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
    fprintf('[TEST 3] FAILED\n\n');
    rethrow(ME);
end

%% TEST 4: Blocked Method Smoke Test
fprintf('[TEST 4] Testing blocked method (Spectral + Evolution should fail)...\n');

try
    Run_Config_blocked = struct();
    Run_Config_blocked.method = 'Spectral';
    Run_Config_blocked.mode = 'Evolution';
    Run_Config_blocked.ic_type = 'Gaussian';
    Run_Config_blocked.run_id = 'smoke_test_spectral_blocked';

    % This should throw SOL-SP-0001
    [Results_blocked, ~] = mode_evolution(Run_Config_blocked, Parameters, Settings);

    % If we reach here, test failed (should have thrown error)
    fprintf('  ✗ FAILED: Spectral method should have thrown error\n');
    fprintf('[TEST 4] FAILED\n\n');
    error('Spectral method did not block as expected');

catch ME
    % Check if correct error was thrown
    if contains(ME.identifier, 'SOL') || contains(ME.message, 'not yet implemented')
        fprintf('  ✓ Spectral method correctly blocked with error: %s\n', ME.identifier);
        fprintf('[TEST 4] PASSED: Blocked methods fail early\n\n');
    else
        % Unexpected error
        fprintf('  ✗ FAILED: Unexpected error: %s\n', ME.message);
        fprintf('[TEST 4] FAILED\n\n');
        rethrow(ME);
    end
end

%% SUMMARY
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('  VERIFICATION COMPLETE\n');
fprintf('═══════════════════════════════════════════════════════════════\n\n');

fprintf('✅ ALL VERIFICATION TESTS PASSED\n');
fprintf('Refactored architecture is functional:\n');
fprintf('  - Method-agnostic modes work correctly\n');
fprintf('  - FD method entrypoints work correctly\n');
fprintf('  - Compatibility matrix blocks invalid combinations\n');
fprintf('  - Blocked methods fail early with clear errors\n\n');

fprintf('Next steps:\n');
fprintf('  1. Run Tsunami_Simulator interactively\n');
fprintf('  2. Test Convergence mode with FD\n');
fprintf('  3. Test ParameterSweep mode with FD\n');
fprintf('  4. Update main README.md with architecture section\n\n');
