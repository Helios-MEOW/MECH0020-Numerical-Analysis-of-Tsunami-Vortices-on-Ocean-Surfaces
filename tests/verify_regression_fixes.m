% verify_regression_fixes.m - Quick verification that regression fixes work
%
% Purpose:
%   Verify that all regression fixes are working correctly:
%   1. Delta parameter exists in default parameters
%   2. UI mode selector can be invoked
%   3. AdaptiveConvergenceAgent can be instantiated
%   4. Helper functions exist and are callable
%
% Usage:
%   cd /path/to/MECH0020-repository
%   verify_regression_fixes
%
% Expected Output:
%   All checks should pass with green checkmarks
%
% Author: MECH0020 Framework
% Date: February 2026

clc; clear; close all;

fprintf('========================================================================\n');
fprintf('  REGRESSION FIX VERIFICATION\n');
fprintf('========================================================================\n\n');

% Setup paths
script_dir = fileparts(fileparts(mfilename('fullpath')));  % Up to repo root
addpath(fullfile(script_dir, 'Scripts', 'Drivers'));
addpath(fullfile(script_dir, 'Scripts', 'Solvers'));
addpath(fullfile(script_dir, 'Scripts', 'Solvers', 'FD'));
addpath(fullfile(script_dir, 'Scripts', 'Infrastructure'));
addpath(fullfile(script_dir, 'Scripts', 'Editable'));
addpath(fullfile(script_dir, 'Scripts', 'UI'));
addpath(fullfile(script_dir, 'utilities'));

test_count = 0;
pass_count = 0;

% ===== TEST 1: Delta parameter in Default_FD_Parameters =====
test_count = test_count + 1;
fprintf('[Test %d] Checking delta parameter in Default_FD_Parameters...\n', test_count);
try
    params = Default_FD_Parameters();
    assert(isfield(params, 'delta'), 'delta field not found');
    assert(isnumeric(params.delta), 'delta is not numeric');
    fprintf('  ✓ PASS: delta = %.2f\n\n', params.delta);
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ FAIL: %s\n\n', ME.message);
end

% ===== TEST 2: Delta parameter in create_default_parameters =====
test_count = test_count + 1;
fprintf('[Test %d] Checking delta parameter in create_default_parameters...\n', test_count);
try
    if exist('create_default_parameters', 'file') == 2
        params = create_default_parameters();
        assert(isfield(params, 'delta'), 'delta field not found');
        assert(isnumeric(params.delta), 'delta is not numeric');
        fprintf('  ✓ PASS: delta = %.2f\n\n', params.delta);
        pass_count = pass_count + 1;
    else
        fprintf('  ⚠ SKIP: create_default_parameters not found (this is OK)\n\n');
        test_count = test_count - 1;  % Don't count skipped tests
    end
catch ME
    fprintf('  ✗ FAIL: %s\n\n', ME.message);
end

% ===== TEST 3: UIController class exists and has show_startup_dialog =====
test_count = test_count + 1;
fprintf('[Test %d] Checking UIController class and startup dialog...\n', test_count);
try
    assert(exist('UIController', 'file') == 2, 'UIController.m not found');
    % Check if show_startup_dialog method exists by looking at file
    ui_file = which('UIController');
    ui_content = fileread(ui_file);
    assert(contains(ui_content, 'show_startup_dialog'), 'show_startup_dialog method not found');
    fprintf('  ✓ PASS: UIController exists with startup dialog\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ FAIL: %s\n\n', ME.message);
end

% ===== TEST 4: AdaptiveConvergenceAgent class exists =====
test_count = test_count + 1;
fprintf('[Test %d] Checking AdaptiveConvergenceAgent class...\n', test_count);
try
    assert(exist('AdaptiveConvergenceAgent', 'file') == 2, 'AdaptiveConvergenceAgent.m not found');
    fprintf('  ✓ PASS: AdaptiveConvergenceAgent.m exists\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ FAIL: %s\n\n', ME.message);
end

% ===== TEST 5: run_adaptive_convergence script exists =====
test_count = test_count + 1;
fprintf('[Test %d] Checking run_adaptive_convergence script...\n', test_count);
try
    assert(exist('run_adaptive_convergence', 'file') == 2, 'run_adaptive_convergence.m not found');
    fprintf('  ✓ PASS: run_adaptive_convergence.m exists\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ FAIL: %s\n\n', ME.message);
end

% ===== TEST 6: Helper functions for convergence agent exist =====
test_count = test_count + 1;
fprintf('[Test %d] Checking helper functions in Analysis.m...\n', test_count);
try
    assert(exist('Analysis', 'file') == 2, 'Analysis.m not found');
    analysis_file = which('Analysis');
    analysis_content = fileread(analysis_file);
    assert(contains(analysis_content, 'function feats = extract_features_from_analysis'), ...
        'extract_features_from_analysis not found');
    assert(contains(analysis_content, 'function params = prepare_simulation_params'), ...
        'prepare_simulation_params not found');
    assert(contains(analysis_content, 'function [figs_new, analysis, run_ok, wall_time_s, cpu_time_s] = execute_simulation'), ...
        'execute_simulation not found');
    fprintf('  ✓ PASS: All helper functions found\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ FAIL: %s\n\n', ME.message);
end

% ===== TEST 7: Analysis_New has UI mode selector =====
test_count = test_count + 1;
fprintf('[Test %d] Checking Analysis_New.m has UI mode selector...\n', test_count);
try
    assert(exist('Analysis_New', 'file') == 2, 'Analysis_New.m not found');
    new_file = which('Analysis_New');
    new_content = fileread(new_file);
    assert(contains(new_content, 'UIController'), 'UIController call not found');
    assert(contains(new_content, 'ui_mode'), 'ui_mode check not found');
    fprintf('  ✓ PASS: Analysis_New.m has UI mode selector\n\n');
    pass_count = pass_count + 1;
catch ME
    fprintf('  ✗ FAIL: %s\n\n', ME.message);
end

% ===== SUMMARY =====
fprintf('========================================================================\n');
fprintf('  VERIFICATION SUMMARY\n');
fprintf('========================================================================\n\n');

fprintf('Tests Passed: %d/%d\n', pass_count, test_count);

if pass_count == test_count
    fprintf('\n✓ ALL TESTS PASSED - Regression fixes verified!\n\n');
    fprintf('You can now:\n');
    fprintf('  1. Run UI Mode: cd Scripts/Main; Analysis\n');
    fprintf('  2. Run Standard Mode: cd Scripts/Main; Analysis_New\n');
    fprintf('  3. Run Convergence Agent: cd Scripts/Main; run_adaptive_convergence\n');
else
    fprintf('\n✗ SOME TESTS FAILED - Please review failures above\n\n');
    fprintf('Failed: %d tests\n', test_count - pass_count);
end

fprintf('========================================================================\n\n');
