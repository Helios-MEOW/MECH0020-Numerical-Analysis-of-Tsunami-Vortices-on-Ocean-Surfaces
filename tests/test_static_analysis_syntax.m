% test_static_analysis_syntax.m - Validate syntax of refactored static_analysis.m

function test_static_analysis_syntax()
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  TESTING: static_analysis.m Syntax Validation\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');
    
    % Test 1: File exists
    fprintf('[1/4] Checking file exists...\n');
    test_dir = fileparts(mfilename('fullpath'));
    file_path = fullfile(test_dir, 'static_analysis.m');
    assert(exist(file_path, 'file') == 2, 'static_analysis.m not found');
    fprintf('  ✓ File exists\n\n');
    
    % Test 2: MATLAB syntax check
    fprintf('[2/4] Running MATLAB syntax check...\n');
    try
        info = checkcode(file_path, '-id');
        critical_errors = 0;
        for i = 1:length(info)
            % Check for syntax errors
            if any(strcmp(info(i).id, {'NODEF', 'NBRAK', 'MCNPR'}))
                critical_errors = critical_errors + 1;
                fprintf('  ✗ CRITICAL: %s (line %d): %s\n', ...
                    info(i).id, info(i).line, info(i).message);
            end
        end
        if critical_errors == 0
            fprintf('  ✓ No critical syntax errors\n');
            fprintf('  Total checkcode issues: %d (non-critical)\n\n', length(info));
        else
            error('Found %d critical syntax errors', critical_errors);
        end
    catch ME
        error('Syntax check failed: %s', ME.message);
    end
    
    % Test 3: Function signature parsing
    fprintf('[3/4] Verifying function signatures...\n');
    text = fileread(file_path);
    
    % Check main function
    assert(contains(text, 'function static_analysis(varargin)'), ...
        'Main function signature missing or incorrect');
    fprintf('  ✓ Main function: static_analysis(varargin)\n');
    
    % Check critical helper functions
    required_funcs = {
        'function [report, analyzer_had_runtime_error, runtime_error_details] = run_analysis_safe(opts)';
        'function [file_list, excluded_files] = collect_files_safe(repo_root, scan_dirs)';
        'function [issues, stats, global_issue_id] = run_code_analyzer_safe(file_list, repo_root, global_issue_id, opts)';
        'function [code, severity, remediation, impact] = map_checkcode_issue(checkcode_id)';
        'function [issues, global_issue_id] = run_custom_checks_safe(repo_root, global_issue_id)';
    };
    
    for i = 1:length(required_funcs)
        % Normalize whitespace for comparison
        pattern = strrep(required_funcs{i}, '  ', ' ');
        if ~contains(text, pattern)
            % Try with different spacing
            pattern_alt = strrep(pattern, ', ', ',');
            assert(contains(text, pattern_alt), ...
                sprintf('Function signature not found: %s', required_funcs{i}));
        end
        fprintf('  ✓ Found: %s\n', required_funcs{i});
    end
    fprintf('\n');
    
    % Test 4: All 9 fixes verification
    fprintf('[4/4] Verifying all 9 critical fixes...\n');
    
    fixes = struct();
    fixes(1).name = 'lowercase filepath check';
    fixes(1).pattern = 'filepath_lower = lower(filepath)';
    
    fixes(2).name = 'cell array accumulation';
    fixes(2).pattern = 'issues_cell = cell(0)';
    
    fixes(3).name = 'global issue ID';
    fixes(3).pattern = 'global_issue_id = 0';
    
    fixes(4).name = 'consolidated comments';
    fixes(4).pattern = 'consolidated at end';
    
    fixes(5).name = 'FailOnIssues parameter';
    fixes(5).pattern = '''FailOnIssues'', false';
    
    fixes(6).name = 'file count reconciliation';
    fixes(6).pattern = 'report.file_counts';
    
    fixes(7).name = 'impact labels';
    fixes(7).pattern = 'RUNTIME_ERROR_LIKELY';
    
    fixes(8).name = 'SA-RUNTIME-0001 code';
    fixes(8).pattern = 'SA-RUNTIME-0001';
    
    fixes(9).name = 'checkcode -struct flag';
    fixes(9).pattern = 'checkcode(filepath, ''-id'', ''-struct'')';
    
    all_passed = true;
    for i = 1:length(fixes)
        if contains(text, fixes(i).pattern)
            fprintf('  ✓ Fix #%d: %s\n', i, fixes(i).name);
        else
            fprintf('  ✗ Fix #%d MISSING: %s\n', i, fixes(i).name);
            all_passed = false;
        end
    end
    
    assert(all_passed, 'Some fixes are missing!');
    fprintf('\n');
    
    % Summary
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  ✓ ALL TESTS PASSED\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');
    
    fprintf('static_analysis.m refactoring verified successfully.\n');
    fprintf('Total lines: %d (target: 900-1000)\n', ...
        length(splitlines(string(text))));
end
