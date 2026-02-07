% Run_All_Tests.m - Master test runner for MECH0020 repository
%
% Purpose:
%   Single entry point for all testing
%   Runs all methods and modes with minimal test cases
%   Produces pass/fail summary
%
% Usage:
%   >> cd tests
%   >> Run_All_Tests
%
% Output:
%   Console summary of test results
%   Optional: test_results.mat with detailed results

clc; clear; close all;

fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('  MECH0020 COMPREHENSIVE TEST SUITE\n');
fprintf('═══════════════════════════════════════════════════════════════\n\n');

% ===== SETUP PATHS =====
test_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(test_dir);

% Add all Scripts subdirectories to path
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
addpath(fullfile(repo_root, 'tests'));

fprintf('Repository root: %s\n', repo_root);
fprintf('Test directory: %s\n\n', test_dir);

% ===== LOAD TEST CASES =====
fprintf('Loading test cases...\n');
Test_Cases = Get_Test_Cases();
n_tests = length(Test_Cases);
fprintf('  Found %d test cases\n\n', n_tests);

% ===== RUN TESTS =====
test_results = struct();
test_results.cases = Test_Cases;
test_results.passed = false(n_tests, 1);
test_results.errors = cell(n_tests, 1);
test_results.wall_times = zeros(n_tests, 1);

fprintf('───────────────────────────────────────────────────────────────\n');
fprintf('  RUNNING TESTS\n');
fprintf('───────────────────────────────────────────────────────────────\n\n');

for i = 1:n_tests
    tc = Test_Cases(i);
    fprintf('[%d/%d] %s\n', i, n_tests, tc.name);
    
    try
        % Run test
        tic;
        [Results, paths] = ModeDispatcher(tc.Run_Config, tc.Parameters, tc.Settings);
        test_results.wall_times(i) = toc;
        
        % Validation
        if ~isempty(Results)
            test_results.passed(i) = true;
            fprintf('  ✓ PASSED (%.2f s)\n', test_results.wall_times(i));
        else
            test_results.passed(i) = false;
            test_results.errors{i} = 'Empty results returned';
            fprintf('  ✗ FAILED: Empty results\n');
        end
        
    catch ME
        % Test failed
        test_results.passed(i) = false;
        test_results.errors{i} = ME.message;
        fprintf('  ✗ FAILED: %s\n', ME.message);
        fprintf('    Stack: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
    
    fprintf('\n');
end

% ===== SUMMARY =====
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('  TEST SUMMARY\n');
fprintf('═══════════════════════════════════════════════════════════════\n\n');

n_passed = sum(test_results.passed);
n_failed = n_tests - n_passed;
pass_rate = 100 * n_passed / n_tests;

fprintf('Total Tests: %d\n', n_tests);
fprintf('Passed:      %d (%.1f%%)\n', n_passed, pass_rate);
fprintf('Failed:      %d\n\n', n_failed);

if n_failed > 0
    fprintf('Failed Tests:\n');
    for i = 1:n_tests
        if ~test_results.passed(i)
            fprintf('  - %s\n', Test_Cases(i).name);
            fprintf('    Error: %s\n', test_results.errors{i});
        end
    end
    fprintf('\n');
end

fprintf('Total Wall Time: %.2f s\n\n', sum(test_results.wall_times));

% ===== SAVE RESULTS =====
save(fullfile(test_dir, 'test_results.mat'), 'test_results');
fprintf('Results saved to: %s\n\n', fullfile(test_dir, 'test_results.mat'));

% ===== EXIT STATUS =====
if n_passed == n_tests
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  ✓ ALL TESTS PASSED\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');
    exit_code = 0;
else
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  ✗ SOME TESTS FAILED\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');
    exit_code = 1;
end

% Return exit code (for CI/CD)
if usejava('desktop')
    % Interactive mode - don't exit
else
    % Non-interactive mode - exit with code
    exit(exit_code);
end
