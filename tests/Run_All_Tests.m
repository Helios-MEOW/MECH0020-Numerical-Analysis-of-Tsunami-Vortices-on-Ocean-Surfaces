% Run_All_Tests_Omnipotent.m - Comprehensive Test Suite for MECH0020
%
% Purpose:
%   Single omnipotent test harness integrating all test types
%   Deterministic exit codes for CI/CD
%   Structured reporting with error codes
%   Color-coded terminal output
%
% Test Types:
%   1. Static Analysis (checkcode + custom checks)
%   2. Unit Tests (minimal cases for each mode)
%   3. Integration Smoke Tests (dispatcher + entrypoints)
%   4. UI Contract  Checks (component/callback structure validation)
%
% Exit Codes:
%   0 - PASS (all tests passed)
%   1 - FAIL (some tests failed)
%   2 - ERROR (test harness failure)
%
% Outputs:
%   - Console: Color-coded summary
%   - JSON Report: Artifacts/TestReports/omnipotent_test_report_<timestamp>.json
%   - Markdown Report: Artifacts/TestReports/omnipotent_test_report_<timestamp>.md
%
% Usage:
%   >> cd tests
%   >> Run_All_Tests_Omnipotent
%   >> Run_All_Tests_Omnipotent('Verbose', true)
%   >> Run_All_Tests_Omnipotent('SkipStatic', true)  % Skip static analysis

function exit_code = Run_All_Tests(varargin)
    %% Parse Options
    p = inputParser;
    addParameter(p, 'Verbose', false, @islogical);
    addParameter(p, 'SkipStatic', false, @islogical);
    addParameter(p, 'SkipIntegration', false, @islogical);
    addParameter(p, 'SkipUI', false, @islogical);
    parse(p, varargin{:});
    opts = p.Results;

    %% Initialize
    clc;

    fprintf('\n');
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  MECH0020 OMNIPOTENT TEST SUITE\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');

    test_start_time = tic;
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    % Setup paths
    test_dir = fileparts(mfilename('fullpath'));
    repo_root = fileparts(test_dir);
    add_all_paths(repo_root);

    % Create artifacts directory
    artifacts_dir = fullfile(repo_root, 'Artifacts', 'TestReports');
    if ~exist(artifacts_dir, 'dir')
        try
            mkdir(artifacts_dir);
        catch ME
            fprintf(2, 'ERROR: Could not create Artifacts/TestReports directory\n');
            fprintf(2, '  %s\n', ME.message);
            exit_code = 2;
            return;
        end
    end

    % Initialize report structure
    report = struct();
    report.metadata = struct();
    report.metadata.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    report.metadata.repo_root = repo_root;
    report.metadata.matlab_version = version;
    report.metadata.test_suite_version = '1.0 (Omnipotent)';

    report.summary = struct();
    report.summary.total_phases = 0;
    report.summary.passed_phases = 0;
    report.summary.failed_phases = 0;
    report.summary.skipped_phases = 0;

    report.phases = struct();

    %% Phase 1: Static Analysis
    if ~opts.SkipStatic
        print_phase_header('PHASE 1', 'Static Analysis (checkcode + custom checks)');

        phase_start = tic;
        try
            % Run static_analysis.m with report mode (never fails)
            % ExitOnComplete=false prevents premature MATLAB termination
            static_analysis('Mode', 'CI', 'FailOnIssues', false, 'Verbose', opts.Verbose, 'ExitOnComplete', false);

            % Read static analysis report
            static_report_path = fullfile(test_dir, 'static_analysis_report.json');
            if exist(static_report_path, 'file')
                static_report = jsondecode(fileread(static_report_path));
                report.phases.static_analysis = struct();
                report.phases.static_analysis.status = 'COMPLETE';
                report.phases.static_analysis.elapsed_sec = toc(phase_start);
                report.phases.static_analysis.total_issues = static_report.summary.total;
                report.phases.static_analysis.critical_issues = static_report.summary.critical;
                report.phases.static_analysis.passed = (static_report.summary.critical == 0);

                if report.phases.static_analysis.passed
                    print_result('PASS', sprintf('No critical issues (%d total issues)', ...
                        static_report.summary.total));
                else
                    print_result('FAIL', sprintf('%d critical issues found', ...
                        static_report.summary.critical));
                end
            else
                report.phases.static_analysis.status = 'ERROR';
                report.phases.static_analysis.passed = false;
                print_result('ERROR', 'Could not find static analysis report');
            end

        catch ME
            report.phases.static_analysis.status = 'ERROR';
            report.phases.static_analysis.error = ME.message;
            report.phases.static_analysis.passed = false;
            print_result('ERROR', sprintf('Static analysis crashed: %s', ME.message));
        end

        report.summary.total_phases = report.summary.total_phases + 1;
        if report.phases.static_analysis.passed
            report.summary.passed_phases = report.summary.passed_phases + 1;
        else
            report.summary.failed_phases = report.summary.failed_phases + 1;
        end
    else
        report.summary.skipped_phases = report.summary.skipped_phases + 1;
        print_phase_header('PHASE 1', 'Static Analysis (SKIPPED)');
    end

    %% Phase 2: Unit Tests (Mode Integration)
    print_phase_header('PHASE 2', 'Unit Tests (Mode Integration)');

    phase_start = tic;
    try
        % Load test cases
        Test_Cases = Get_Test_Cases();
        n_tests = length(Test_Cases);

        fprintf('  Found %d test cases\n\n', n_tests);

        test_results = struct();
        test_results.cases = Test_Cases;
        test_results.passed = false(n_tests, 1);
        test_results.errors = cell(n_tests, 1);
        test_results.wall_times = zeros(n_tests, 1);
        test_results.error_codes = cell(n_tests, 1);

        for i = 1:n_tests
            tc = Test_Cases(i);
            fprintf('  [%d/%d] %s ... ', i, n_tests, tc.name);

            try
                tic;
                [Results, ~] = ModeDispatcher(tc.Run_Config, tc.Parameters, tc.Settings);
                test_results.wall_times(i) = toc;

                if ~isempty(Results)
                    test_results.passed(i) = true;
                    print_result('PASS', sprintf('%.2f s', test_results.wall_times(i)));
                else
                    test_results.passed(i) = false;
                    test_results.errors{i} = 'Empty results returned';
                    test_results.error_codes{i} = 'TST-0001';
                    print_result('FAIL', 'Empty results');
                end

            catch ME
                test_results.passed(i) = false;
                test_results.errors{i} = ME.message;

                % Map exception to error code
                if contains(ME.identifier, 'RUN')
                    test_results.error_codes{i} = 'RUN-EXEC-0003';
                elseif contains(ME.identifier, 'CFG')
                    test_results.error_codes{i} = 'CFG-VAL-0001';
                else
                    test_results.error_codes{i} = 'TST-0001';
                end

                print_result('FAIL', sprintf('[%s] %s', test_results.error_codes{i}, ME.message));
            end
        end

        n_passed = sum(test_results.passed);
        report.phases.unit_tests = struct();
        report.phases.unit_tests.status = 'COMPLETE';
        report.phases.unit_tests.elapsed_sec = toc(phase_start);
        report.phases.unit_tests.total_tests = n_tests;
        report.phases.unit_tests.passed_tests = n_passed;
        report.phases.unit_tests.failed_tests = n_tests - n_passed;
        report.phases.unit_tests.passed = (n_passed == n_tests);

        fprintf('\n');
        if report.phases.unit_tests.passed
            print_result('PASS', sprintf('All %d tests passed', n_tests));
        else
            print_result('FAIL', sprintf('%d/%d tests failed', n_tests - n_passed, n_tests));
        end

    catch ME
        report.phases.unit_tests.status = 'ERROR';
        report.phases.unit_tests.error = ME.message;
        report.phases.unit_tests.passed = false;
        print_result('ERROR', sprintf('Unit test harness failed: %s', ME.message));
    end

    report.summary.total_phases = report.summary.total_phases + 1;
    if report.phases.unit_tests.passed
        report.summary.passed_phases = report.summary.passed_phases + 1;
    else
        report.summary.failed_phases = report.summary.failed_phases + 1;
    end

    %% Phase 3: Integration Smoke Tests
    if ~opts.SkipIntegration
        print_phase_header('PHASE 3', 'Integration Smoke Tests');

        phase_start = tic;
        integration_passed = true;

        % Test 1: Dispatcher entrypoint exists and accepts valid config
        fprintf('  [1/2] Dispatcher smoke test ... ');
        try
            Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');
            Params = Parameters();
            Params.Nx = 16;
            Params.Ny = 16;
            Params.Tfinal = 0.01;
            Settings_obj = Settings();
            Settings_obj.save_figures = false;
            Settings_obj.save_data = false;
            Settings_obj.monitor_enabled = false;

            [~, ~] = ModeDispatcher(Run_Config, Params, Settings_obj);
            print_result('PASS', 'Dispatcher works');
        catch ME
            integration_passed = false;
            print_result('FAIL', sprintf('[RUN-EXEC-0003] %s', ME.message));
        end

        % Test 2: Required infrastructure modules  exist
        fprintf('  [2/2] Infrastructure modules ... ');
        try
            required_functions = {
                'Build_Run_Config', ...
                'Parameters', ...
                'Settings', ...
                'PathBuilder', ...
                'ErrorRegistry', ...
                'ErrorHandler'
            };

            missing = {};
            for i = 1:length(required_functions)
                if ~exist(required_functions{i}, 'file') && ~exist(required_functions{i}, 'class')
                    missing{end+1} = required_functions{i}; %#ok<AGROW>
                end
            end

            if isempty(missing)
                print_result('PASS', 'All infrastructure modules found');
            else
                integration_passed = false;
                print_result('FAIL', sprintf('[SYS-BOOT-0003] Missing: %s', strjoin(missing, ', ')));
            end
        catch ME
            integration_passed = false;
            print_result('FAIL', sprintf('[SYS-BOOT-0003] %s', ME.message));
        end

        report.phases.integration = struct();
        report.phases.integration.status = 'COMPLETE';
        report.phases.integration.elapsed_sec = toc(phase_start);
        report.phases.integration.passed = integration_passed;

        fprintf('\n');
        if integration_passed
            print_result('PASS', 'Integration smoke tests passed');
        else
            print_result('FAIL', 'Some integration tests failed');
        end

        report.summary.total_phases = report.summary.total_phases + 1;
        if report.phases.integration.passed
            report.summary.passed_phases = report.summary.passed_phases + 1;
        else
            report.summary.failed_phases = report.summary.failed_phases + 1;
        end
    else
        report.summary.skipped_phases = report.summary.skipped_phases + 1;
        print_phase_header('PHASE 3', 'Integration Smoke Tests (SKIPPED)');
    end

    %% Phase 4: UI Contract Checks
    if ~opts.SkipUI
        print_phase_header('PHASE 4', 'UI Contract Checks');

        phase_start = tic;
ui_passed = true;

        % Test 1: UIController exists
        fprintf('  [1/3] UIController exists ... ');
        try
            if exist('UIController', 'file') || exist('UIController', 'class')
                print_result('PASS', 'UIController found');
            else
                ui_passed = false;
                print_result('FAIL', '[SYS-BOOT-0003] UIController.m not found');
            end
        catch ME
            ui_passed = false;
            print_result('FAIL', sprintf('[UI-CB-0001] %s', ME.message));
        end

        % Test 2: UI_Layout_Config exists
        fprintf('  [2/3] UI_Layout_Config exists ... ');
        try
            if exist('UI_Layout_Config', 'file') || exist('UI_Layout_Config', 'class')
                print_result('PASS', 'UI_Layout_Config found');
            else
                ui_passed = false;
                print_result('FAIL', '[UI-LAY-0001] UI_Layout_Config.m not found');
            end
        catch ME
            ui_passed = false;
            print_result('FAIL', sprintf('[UI-LAY-0001] %s', ME.message));
        end

        % Test 3: Simulated user startup flow (select UI mode)
        fprintf('  [3/3] UI user startup flow ... ');
        try
            [flow_passed, flow_details] = test_ui_user_flow();
            if flow_passed
                print_result('PASS', flow_details);
            else
                ui_passed = false;
                print_result('FAIL', sprintf('[UI-CB-0001] %s', flow_details));
            end
        catch ME
            ui_passed = false;
            print_result('FAIL', sprintf('[UI-CB-0001] %s', ME.message));
        end

        report.phases.ui_contract = struct();
        report.phases.ui_contract.status = 'COMPLETE';
        report.phases.ui_contract.elapsed_sec = toc(phase_start);
        report.phases.ui_contract.passed = ui_passed;

        fprintf('\n');
        if ui_passed
            print_result('PASS', 'UI contract checks passed');
        else
            print_result('FAIL', 'Some UI contract checks failed');
        end

        report.summary.total_phases = report.summary.total_phases + 1;
        if report.phases.ui_contract.passed
            report.summary.passed_phases = report.summary.passed_phases + 1;
        else
            report.summary.failed_phases = report.summary.failed_phases + 1;
        end
    else
        report.summary.skipped_phases = report.summary.skipped_phases + 1;
        print_phase_header('PHASE 4', 'UI Contract Checks (SKIPPED)');
    end

    %% Final Summary
    total_elapsed = toc(test_start_time);

    fprintf('\n');
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  FINAL SUMMARY\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');

    fprintf('Total Phases:    %d\n', report.summary.total_phases);
    fprintf('Passed:          %d\n', report.summary.passed_phases);
    fprintf('Failed:          %d\n', report.summary.failed_phases);
    fprintf('Skipped:         %d\n', report.summary.skipped_phases);
    fprintf('Total Time:      %.2f s\n\n', total_elapsed);

    % Determine overall status
    all_passed = (report.summary.failed_phases == 0);

    if all_passed
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

    %% Write Reports
    fprintf('Writing test reports...\n');

    % JSON report
    json_path = fullfile(artifacts_dir, sprintf('omnipotent_test_report_%s.json', timestamp));
    try
        json_str = jsonencode(report);
        fid = fopen(json_path, 'w');
        fprintf(fid, '%s', json_str);
        fclose(fid);
        fprintf('  JSON:     %s\n', json_path);
    catch ME
        fprintf(2, '  ERROR writing JSON: %s\n', ME.message);
    end

    % Markdown report
    md_path = fullfile(artifacts_dir, sprintf('omnipotent_test_report_%s.md', timestamp));
    try
        write_markdown_report(md_path, report);
        fprintf('  Markdown: %s\n\n', md_path);
    catch ME
        fprintf(2, '  ERROR writing Markdown: %s\n', ME.message);
    end

    %% Return exit code (NO exit call - it terminates MATLAB)
    % The exit_code is returned as the function output
    % Caller or CI wrapper must interpret the return value
    if exit_code ~= 0
        warning('MECH0020:TestsFailed', 'Tests completed with failures. Exit code: %d', exit_code);
    end
end

%% Helper Functions
function add_all_paths(repo_root)
    addpath(fullfile(repo_root, 'Scripts', 'Drivers'));
    addpath(fullfile(repo_root, 'Scripts', 'Modes'));
    addpath(fullfile(repo_root, 'Scripts', 'Modes', 'Convergence'));
    addpath(fullfile(repo_root, 'Scripts', 'Solvers'));
    % Note: Scripts\Solvers\FD doesn't exist - FD code is in Scripts\Methods\FiniteDifference
    addpath(fullfile(repo_root, 'Scripts', 'Methods', 'FiniteDifference'));
    addpath(fullfile(repo_root, 'Scripts', 'Methods', 'FiniteVolume'));
    addpath(fullfile(repo_root, 'Scripts', 'Methods', 'Spectral'));
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
end

function print_phase_header(phase_num, description)
    fprintf('\n');
    fprintf('───────────────────────────────────────────────────────────────\n');
    fprintf('[%s] %s\n', phase_num, description);
    fprintf('───────────────────────────────────────────────────────────────\n\n');
end

function print_result(status, message)
    % Print with basic color indication via text prefix
    switch status
        case 'PASS'
            prefix = '✓';
        case 'FAIL'
            prefix = '✗';
        case 'ERROR'
            prefix = '⚠';
        otherwise
            prefix = '•';
    end

    fprintf('%s %s\n', prefix, message);
end

function write_markdown_report(filepath, report)
    fid = fopen(filepath, 'w');

    fprintf(fid, '# Omnipotent Test Suite Report\n\n');
    fprintf(fid, '**Timestamp:** %s  \n', report.metadata.timestamp);
    fprintf(fid, '**MATLAB:** %s  \n', report.metadata.matlab_version);
    fprintf(fid, '**Suite Version:** %s  \n\n', report.metadata.test_suite_version);

    fprintf(fid, '## Summary\n\n');
    fprintf(fid, '| Metric | Count |\n');
    fprintf(fid, '|--------|-------|\n');
    fprintf(fid, '| Total Phases | %d |\n', report.summary.total_phases);
    fprintf(fid, '| Passed | %d |\n', report.summary.passed_phases);
    fprintf(fid, '| Failed | %d |\n', report.summary.failed_phases);
    fprintf(fid, '| Skipped | %d |\n\n', report.summary.skipped_phases);

    fprintf(fid, '## Phase Details\n\n');

    phases = fieldnames(report.phases);
    for i = 1:length(phases)
        phase_name = phases{i};
        phase = report.phases.(phase_name);

        status_icon = '✓';
        if ~phase.passed
            status_icon = '✗';
        end

        fprintf(fid, '### %s %s\n\n', status_icon, strrep(phase_name, '_', ' '));
        fprintf(fid, '- **Status:** %s  \n', phase.status);
        if isfield(phase, 'elapsed_sec')
            fprintf(fid, '- **Time:** %.2f sec  \n', phase.elapsed_sec);
        end
        if isfield(phase, 'error')
            fprintf(fid, '- **Error:** %s  \n', phase.error);
        end
        fprintf(fid, '\n');
    end

    fprintf(fid, '---\n\n');
    fprintf(fid, '*Generated by MECH0020 Omnipotent Test Suite v1.0*\n');

    fclose(fid);
end
