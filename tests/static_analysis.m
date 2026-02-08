% static_analysis.m - Robust Static Code Analysis for MECH0020 Repository
%
% PURPOSE:
%   Crash-safe static analysis with structured issue reporting.
%   Runs MATLAB Code Analyzer and custom checks, writes reports to disk.
%
% USAGE:
%   >> cd tests
%   >> static_analysis()                    % Report mode (always succeeds)
%   >> static_analysis('FailOnIssues', true) % Gate mode (exit 1 if issues)
%   >> static_analysis('Mode', 'CI', 'FailOnIssues', false, 'Verbose', true)
%
% OUTPUT:
%   - Console: Per-file progress and line-level details with impact labels
%   - JSON: tests/static_analysis_report.json (machine-readable, consolidated at end)
%   - Markdown: tests/static_analysis_report.md (human-readable, consolidated at end)
%   
% EXIT CODES (when FailOnIssues=true):
%   0 = PASS (no critical issues)
%   1 = FAIL (critical issues found; see reports)
%   (Never exits with code 2 in report mode; runtime errors captured as findings)
%
% PARAMETERS:
%   'Mode' - 'Interactive' (default) or 'CI' (more verbose output)
%   'FailOnIssues' - false (default, report mode) or true (gate mode)
%   'Verbose' - false (default) or true (detailed per-file output)
%   'MaxIssuesPerFile' - Maximum issues to display per file (default: 10)
%   'MaxFilesDetailed' - Maximum files to show detailed issues (default: 20)
%
% ISSUE CODE TAXONOMY:
%   MLAB-xxx: MATLAB Code Analyzer issues (mapped from checkcode)
%   REPO-xxx: Repository structure/entry point issues
%   CUST-xxx: Custom code pattern checks
%   SA-RUNTIME-0001: Analyzer internal error (runtime exception)
%
% AUTHOR: MECH0020 Static Analysis System
% VERSION: 3.1 (Report/Gate split, unique IDs, file count reconciliation)

function static_analysis(varargin)
    % Parse optional parameters
    p = inputParser;
    addParameter(p, 'Mode', 'Interactive', @(x) ismember(x, {'Interactive', 'CI'}));
    addParameter(p, 'FailOnIssues', false, @islogical);
    addParameter(p, 'Verbose', false, @islogical);
    addParameter(p, 'MaxIssuesPerFile', 10, @isnumeric);
    addParameter(p, 'MaxFilesDetailed', 20, @isnumeric);
    parse(p, varargin{:});
    
    opts = p.Results;
    
    % Main entry point - wrapped in global exception handler
    analyzer_had_runtime_error = false;
    runtime_error_details = struct();
    
    try
        [report, analyzer_had_runtime_error, runtime_error_details] = run_analysis_safe(opts);
    catch ME
        % Catastrophic failure - analyzer itself crashed
        % In report mode, we capture this and still write a report
        analyzer_had_runtime_error = true;
        runtime_error_details.exception = ME.message;
        runtime_error_details.location = ME.stack(1).name;
        runtime_error_details.line = ME.stack(1).line;
        runtime_error_details.stack = ME.stack;
        
        fprintf(2, '\n');
        fprintf(2, '═══════════════════════════════════════════════════════════════\n');
        fprintf(2, '  ✗✗✗ ANALYZER RUNTIME ERROR ✗✗✗\n');
        fprintf(2, '═══════════════════════════════════════════════════════════════\n');
        fprintf(2, 'Exception: %s\n', ME.message);
        fprintf(2, 'Location: %s\n', ME.stack(1).name);
        fprintf(2, 'Line: %d\n', ME.stack(1).line);
        fprintf(2, '\nStack trace:\n');
        for i = 1:min(3, length(ME.stack))
            fprintf(2, '  [%d] %s (line %d)\n', i, ME.stack(i).name, ME.stack(i).line);
        end
        fprintf(2, '═══════════════════════════════════════════════════════════════\n\n');
        
        % Create minimal report
        test_dir = fileparts(mfilename('fullpath'));
        report = create_error_report(runtime_error_details, test_dir);
    end
    
    % Determine exit behavior based on mode
    if opts.FailOnIssues
        % Gate mode: exit with code 1 if critical issues found
        if analyzer_had_runtime_error || report.summary.critical > 0
            if ~usejava('desktop')
                exit(1);
            end
        else
            if ~usejava('desktop')
                exit(0);
            end
        end
    else
        % Report mode: ALWAYS exit 0 (never fail the step)
        if ~usejava('desktop')
            exit(0);
        end
    end
end

function [report, analyzer_had_runtime_error, runtime_error_details] = run_analysis_safe(opts)
    % Main analysis logic with phase tracking and consolidated reporting
    
    clc;
    
    % Initialize
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  STATIC CODE ANALYSIS v3.1 (Crash-Hardened)\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');
    
    test_dir = fileparts(mfilename('fullpath'));
    repo_root = fileparts(test_dir);
    
    fprintf('Repository: %s\n', repo_root);
    fprintf('Mode: %s | FailOnIssues: %d | Verbose: %d\n', ...
        opts.Mode, opts.FailOnIssues, opts.Verbose);
    fprintf('Started: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    
    % Phase tracking
    phase_start = tic;
    current_phase = 'INIT';
    analyzer_had_runtime_error = false;
    runtime_error_details = struct();
    
    % Initialize report structure
    report = struct();
    report.metadata = struct();
    report.metadata.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    report.metadata.repo_root = repo_root;
    report.metadata.matlab_version = version;
    report.metadata.hostname = getenv('HOSTNAME');
    if isempty(report.metadata.hostname)
        report.metadata.hostname = getenv('COMPUTERNAME');
    end
    if isempty(report.metadata.hostname)
        report.metadata.hostname = 'unknown';
    end
    
    report.phases = struct();
    report.issues = struct('all', [], 'by_severity', struct(), 'by_file', struct());
    report.summary = struct('total', 0, 'critical', 0, 'major', 0, 'minor', 0);
    
    % File count reconciliation structure
    report.file_counts = struct('found', 0, 'analyzed', 0, 'excluded', 0, 'errors', 0);
    
    % Output files
    json_file = fullfile(test_dir, 'static_analysis_report.json');
    md_file = fullfile(test_dir, 'static_analysis_report.md');
    
    % Global issue counter (passed through all phases for unique IDs)
    global_issue_id = 0;
    
    try
        % ===== PHASE 1: FILE COLLECTION =====
        current_phase = 'FILE_COLLECTION';
        fprintf('───────────────────────────────────────────────────────────────\n');
        fprintf('[PHASE 1] Collecting MATLAB files...\n');
        fprintf('───────────────────────────────────────────────────────────────\n\n');
        
        phase_start = tic;
        
        scan_dirs = {'Scripts', 'utilities', 'tests'};
        [file_list, excluded_files] = collect_files_safe(repo_root, scan_dirs);
        
        n_files = length(file_list);
        n_excluded = length(excluded_files);
        report.file_counts.found = n_files + n_excluded;
        report.file_counts.excluded = n_excluded;
        
        fprintf('  Found %d MATLAB files (%d excluded)\n', n_files, n_excluded);
        
        report.phases.file_collection = struct(...
            'status', 'COMPLETE', ...
            'files_found', n_files, ...
            'files_excluded', n_excluded, ...
            'elapsed_sec', toc(phase_start));
        
        fprintf('  Elapsed: %.2f sec\n\n', report.phases.file_collection.elapsed_sec);
        
        % ===== PHASE 2: MATLAB CODE ANALYZER =====
        current_phase = 'CODE_ANALYZER';
        fprintf('───────────────────────────────────────────────────────────────\n');
        fprintf('[PHASE 2] Running MATLAB Code Analyzer (per-file, crash-safe)...\n');
        fprintf('───────────────────────────────────────────────────────────────\n\n');
        
        phase_start = tic;
        
        [mlab_issues, stats, global_issue_id] = run_code_analyzer_safe(...
            file_list, repo_root, global_issue_id, opts);
        
        report.file_counts.analyzed = stats.analyzed;
        report.file_counts.errors = stats.errors;
        
        report.phases.code_analyzer = struct(...
            'status', 'COMPLETE', ...
            'files_analyzed', stats.analyzed, ...
            'files_errors', stats.errors, ...
            'issues_found', length(mlab_issues), ...
            'elapsed_sec', toc(phase_start));
        
        fprintf('  Issues found: %d\n', length(mlab_issues));
        fprintf('  Elapsed: %.2f sec\n\n', report.phases.code_analyzer.elapsed_sec);
        
        % Add to report
        report.issues.all = mlab_issues;
        
        % ===== PHASE 3: CUSTOM CHECKS =====
        current_phase = 'CUSTOM_CHECKS';
        fprintf('───────────────────────────────────────────────────────────────\n');
        fprintf('[PHASE 3] Running custom repository checks...\n');
        fprintf('───────────────────────────────────────────────────────────────\n\n');
        
        phase_start = tic;
        
        [custom_issues, global_issue_id] = run_custom_checks_safe(repo_root, global_issue_id);
        
        report.phases.custom_checks = struct(...
            'status', 'COMPLETE', ...
            'issues_found', length(custom_issues), ...
            'elapsed_sec', toc(phase_start));
        
        fprintf('  Issues found: %d\n', length(custom_issues));
        fprintf('  Elapsed: %.2f sec\n\n', report.phases.custom_checks.elapsed_sec);
        
        % Add to report (concatenate struct arrays)
        if ~isempty(custom_issues)
            if isempty(report.issues.all)
                report.issues.all = custom_issues;
            else
                report.issues.all = [report.issues.all, custom_issues];
            end
        end
        
        % ===== PHASE 4: AGGREGATE AND CLASSIFY =====
        current_phase = 'AGGREGATION';
        fprintf('───────────────────────────────────────────────────────────────\n');
        fprintf('[PHASE 4] Aggregating and classifying issues...\n');
        fprintf('───────────────────────────────────────────────────────────────\n\n');
        
        % Count by severity
        for i = 1:length(report.issues.all)
            issue = report.issues.all(i);
            switch issue.severity
                case 'CRITICAL'
                    report.summary.critical = report.summary.critical + 1;
                case 'MAJOR'
                    report.summary.major = report.summary.major + 1;
                case 'MINOR'
                    report.summary.minor = report.summary.minor + 1;
            end
        end
        
        report.summary.total = length(report.issues.all);
        
        fprintf('  Total issues: %d\n', report.summary.total);
        fprintf('  CRITICAL: %d\n', report.summary.critical);
        fprintf('  MAJOR: %d\n', report.summary.major);
        fprintf('  MINOR: %d\n\n', report.summary.minor);
        
        % File count reconciliation
        fprintf('  File counts: Found=%d, Analyzed=%d, Excluded=%d, Errors=%d\n', ...
            report.file_counts.found, report.file_counts.analyzed, ...
            report.file_counts.excluded, report.file_counts.errors);
        
        % Verify reconciliation
        computed_found = report.file_counts.analyzed + report.file_counts.excluded + report.file_counts.errors;
        if computed_found == report.file_counts.found
            fprintf('  ✓ File count reconciliation OK\n\n');
        else
            fprintf('  ⚠ WARNING: File count mismatch (expected %d, got %d)\n\n', ...
                report.file_counts.found, computed_found);
        end
        
        % ===== PHASE 5: WRITE REPORTS =====
        current_phase = 'REPORTING';
        fprintf('───────────────────────────────────────────────────────────────\n');
        fprintf('[PHASE 5] Writing consolidated reports...\n');
        fprintf('───────────────────────────────────────────────────────────────\n\n');
        
        % Write JSON (consolidated at end of all analysis)
        write_json_report(json_file, report);
        fprintf('  JSON report: %s\n', json_file);
        
        % Write Markdown (consolidated at end of all analysis)
        write_markdown_report(md_file, report);
        fprintf('  Markdown report: %s\n\n', md_file);
        
        % ===== FINAL SUMMARY =====
        fprintf('═══════════════════════════════════════════════════════════════\n');
        fprintf('  ANALYSIS SUMMARY\n');
        fprintf('═══════════════════════════════════════════════════════════════\n\n');
        
        fprintf('Total issues: %d (CRITICAL: %d, MAJOR: %d, MINOR: %d)\n\n', ...
            report.summary.total, report.summary.critical, ...
            report.summary.major, report.summary.minor);
        
        % Determine status message
        if report.summary.total == 0
            fprintf('═══════════════════════════════════════════════════════════════\n');
            fprintf('  ✓ STATIC ANALYSIS PASSED\n');
            fprintf('═══════════════════════════════════════════════════════════════\n\n');
        else
            fprintf('═══════════════════════════════════════════════════════════════\n');
            fprintf('  ✗ STATIC ANALYSIS FOUND ISSUES\n');
            fprintf('  Review: %s\n', md_file);
            fprintf('═══════════════════════════════════════════════════════════════\n\n');
        end
        
    catch ME
        % Phase-specific error
        analyzer_had_runtime_error = true;
        runtime_error_details.exception = ME.message;
        runtime_error_details.phase = current_phase;
        if ~isempty(ME.stack)
            runtime_error_details.location = ME.stack(1).name;
            runtime_error_details.line = ME.stack(1).line;
        end
        
        fprintf(2, '\n✗ ERROR in phase: %s\n', current_phase);
        fprintf(2, '  Message: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf(2, '  Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        
        % Try to save partial report
        report.phases.(lower(current_phase)) = struct('status', 'FAILED', 'error', ME.message);
        try
            write_json_report(json_file, report);
            fprintf(2, '  Partial report saved: %s\n', json_file);
        catch
            fprintf(2, '  Could not save partial report\n');
        end
    end
end

%% ========================================================================
%  LOCAL FUNCTIONS (Crash-Safe Implementations)
%% ========================================================================

function [file_list, excluded_files] = collect_files_safe(repo_root, scan_dirs)
    % Collect .m files with pre-allocation to avoid memory issues
    % Returns both included and excluded files for reconciliation
    
    % Pre-scan to count files
    total_count = 0;
    for i = 1:length(scan_dirs)
        dir_path = fullfile(repo_root, scan_dirs{i});
        if exist(dir_path, 'dir')
            temp_files = dir(fullfile(dir_path, '**', '*.m'));
            total_count = total_count + length(temp_files);
        end
    end
    
    % Add root .m files
    root_files = dir(fullfile(repo_root, '*.m'));
    total_count = total_count + length(root_files);
    
    % Pre-allocate cell arrays
    file_list = cell(total_count, 1);
    excluded_files = cell(total_count, 1);
    idx = 0;
    exc_idx = 0;
    
    % Collect files with exclusion logic
    for i = 1:length(scan_dirs)
        dir_path = fullfile(repo_root, scan_dirs{i});
        if exist(dir_path, 'dir')
            files_in_dir = dir(fullfile(dir_path, '**', '*.m'));
            for j = 1:length(files_in_dir)
                filepath = fullfile(files_in_dir(j).folder, files_in_dir(j).name);
                
                % Check if should be excluded (test files)
                % FIX #1: Use lowercase comparison instead of invalid IgnoreCase param
                filepath_lower = lower(filepath);
                if contains(filepath_lower, [filesep 'test' filesep]) || ...
                   contains(filepath_lower, [filesep 'tests' filesep])
                    exc_idx = exc_idx + 1;
                    excluded_files{exc_idx} = filepath;
                else
                    idx = idx + 1;
                    file_list{idx} = filepath;
                end
            end
        end
    end
    
    % Add root files
    for j = 1:length(root_files)
        filepath = fullfile(root_files(j).folder, root_files(j).name);
        idx = idx + 1;
        file_list{idx} = filepath;
    end
    
    % Trim unused cells
    file_list = file_list(1:idx);
    excluded_files = excluded_files(1:exc_idx);
    
    % Sort for deterministic order
    file_list = sort(file_list);
    excluded_files = sort(excluded_files);
end

function [issues, stats, global_issue_id] = run_code_analyzer_safe(file_list, repo_root, global_issue_id, opts)
    % Run checkcode per-file with exception handling
    % FIX #2: Use cell array accumulation instead of growing arrays
    % FIX #3: Accept and return global_issue_id for unique IDs across phases
    % FIX #7: Add per-file terminal output with impact labels
    % FIX #9: Use checkcode with -struct flag
    
    issues_cell = cell(0);  % FIX #2: Cell array accumulation
    
    n_files = length(file_list);
    analyzed = 0;
    errors = 0;
    
    files_detailed_count = 0;  % Track how many files we've shown detailed output for
    
    for i = 1:n_files
        filepath = file_list{i};
        rel_path = strrep(filepath, [repo_root filesep], '');
        
        try
            % FIX #9: Run checkcode with -struct flag for better output
            info = checkcode(filepath, '-id', '-struct');
            analyzed = analyzed + 1;
            
            % Count issues by severity for this file
            n_issues = length(info);
            n_crit = 0;
            n_maj = 0;
            n_min = 0;
            
            if ~isempty(info)
                % Process each issue
                for j = 1:length(info)
                    global_issue_id = global_issue_id + 1;  % FIX #3: Increment global counter
                    
                    % Map to our issue code taxonomy with impact label
                    [code, severity, remediation, impact] = map_checkcode_issue(info(j).id);
                    
                    % Count by severity
                    switch severity
                        case 'CRITICAL'
                            n_crit = n_crit + 1;
                        case 'MAJOR'
                            n_maj = n_maj + 1;
                        case 'MINOR'
                            n_min = n_min + 1;
                    end
                    
                    issue_struct = struct(...
                        'id', global_issue_id, ...
                        'code', code, ...
                        'severity', severity, ...
                        'impact', impact, ...
                        'category', 'CODE_ANALYZER', ...
                        'file', rel_path, ...
                        'line', info(j).line, ...
                        'column', info(j).column, ...
                        'message', info(j).message, ...
                        'rule_id', info(j).id, ...
                        'remediation', remediation);
                    
                    issues_cell{end+1} = issue_struct;  % FIX #2: Cell array append
                end
            end
            
            % FIX #7: Per-file terminal output with impact labels
            if n_issues == 0
                status_str = 'PASS';
            elseif n_crit > 0
                status_str = 'FAIL';
            else
                status_str = 'WARN';
            end
            
            fprintf('  [%s] %s: %d issues (CRIT: %d, MAJ: %d, MIN: %d)\n', ...
                status_str, rel_path, n_issues, n_crit, n_maj, n_min);
            
            % Show line-level details if verbose and under limit
            if opts.Verbose && n_issues > 0 && files_detailed_count < opts.MaxFilesDetailed
                files_detailed_count = files_detailed_count + 1;
                n_show = min(n_issues, opts.MaxIssuesPerFile);
                for j = 1:n_show
                    [~, severity, ~, impact] = map_checkcode_issue(info(j).id);
                    fprintf('    Line %d: [%s] %s | Impact: %s | %s\n', ...
                        info(j).line, info(j).id, severity, impact, info(j).message);
                end
                if n_issues > opts.MaxIssuesPerFile
                    fprintf('    ... (%d more issues suppressed)\n', n_issues - opts.MaxIssuesPerFile);
                end
            end
            
        catch ME
            % checkcode failed for this file
            errors = errors + 1;
            global_issue_id = global_issue_id + 1;  % FIX #3: Increment global counter
            
            % FIX #8: Change issue code to SA-RUNTIME-0001
            issue_struct = struct(...
                'id', global_issue_id, ...
                'code', 'SA-RUNTIME-0001', ...
                'severity', 'MAJOR', ...
                'impact', 'ANALYZER_FAILURE', ...
                'category', 'ANALYZER_ERROR', ...
                'file', rel_path, ...
                'line', 0, ...
                'column', 0, ...
                'message', sprintf('checkcode failed: %s', ME.message), ...
                'rule_id', 'SA-RUNTIME-0001', ...
                'remediation', 'File may have syntax errors or be unreadable');
            
            issues_cell{end+1} = issue_struct;  % FIX #2: Cell array append
            
            fprintf('  [FAIL] %s: Analyzer error - %s\n', rel_path, ME.message);
        end
        
        % Progress (every 20 files)
        if mod(i, 20) == 0
            fprintf('  Progress: %d/%d files analyzed (%d issues so far)\n', ...
                analyzed, n_files, length(issues_cell));
        end
    end
    
    fprintf('\n');
    fprintf('  Analyzed: %d files\n', analyzed);
    fprintf('  Errors: %d files\n', errors);
    
    % FIX #2: Convert cell array to struct array at end
    if ~isempty(issues_cell)
        issues = vertcat(issues_cell{:});
    else
        issues = [];
    end
    
    % Return statistics
    stats = struct('analyzed', analyzed, 'errors', errors);
end

function [code, severity, remediation, impact] = map_checkcode_issue(checkcode_id)
    % Map MATLAB checkcode IDs to our taxonomy
    % FIX #7: Add impact labels (RUNTIME_ERROR_LIKELY, LOGIC_RISK, PERFORMANCE_STYLE, UNKNOWN)
    
    % Critical issues (Runtime error likely)
    if any(strcmp(checkcode_id, {'NODEF', 'NBRAK', 'MCNPR', 'MCVID'}))
        severity = 'CRITICAL';
        code = sprintf('MLAB-CRIT-%s', checkcode_id);
        impact = 'RUNTIME_ERROR_LIKELY';
        
        switch checkcode_id
            case 'NODEF'
                remediation = 'Function is called but not defined. Add function definition or check spelling.';
            case 'NBRAK'
                remediation = 'Unbalanced brackets. Check syntax carefully.';
            case 'MCNPR'
                remediation = 'File name must match function name for proper calling.';
            case 'MCVID'
                remediation = 'Invalid identifier. Use valid MATLAB variable/function names.';
            otherwise
                remediation = 'Critical issue detected. Review and fix immediately.';
        end
        
    % Logic risk issues
    elseif any(strcmp(checkcode_id, {'INUSD', 'GVMIS', 'NOPRT'}))
        severity = 'MAJOR';
        code = sprintf('MLAB-MAJR-%s', checkcode_id);
        impact = 'LOGIC_RISK';
        
        switch checkcode_id
            case 'INUSD'
                remediation = 'Variable set but never used. Remove or use the variable.';
            case 'GVMIS'
                remediation = 'Global variable mismatch. Declare global consistently.';
            case 'NOPRT'
                remediation = 'Function has no output. Consider returning a value or making it a script.';
            otherwise
                remediation = 'Logic issue. Review for correctness.';
        end
        
    % Performance/style issues
    elseif any(strcmp(checkcode_id, {'AGROW', 'SAGROW', 'PSIZE', 'NOSEM'}))
        severity = 'MAJOR';
        code = sprintf('MLAB-MAJR-%s', checkcode_id);
        impact = 'PERFORMANCE_STYLE';
        
        switch checkcode_id
            case 'AGROW'
                remediation = 'Variable growing inside loop. Pre-allocate for better performance.';
            case 'SAGROW'
                remediation = 'Variable growing inside loop (string). Pre-allocate or use string array.';
            case 'PSIZE'
                remediation = 'Variable size changes. Pre-allocate for better performance.';
            case 'NOSEM'
                remediation = 'Missing semicolon may cause excessive output. Add semicolon.';
            otherwise
                remediation = 'Performance or style issue. Consider addressing for code quality.';
        end
        
    % Minor issues (style, best practices)
    else
        severity = 'MINOR';
        code = sprintf('MLAB-MINR-%s', checkcode_id);
        impact = 'UNKNOWN';
        remediation = 'Style or best practice issue. Consider addressing for code quality.';
    end
end

function [issues, global_issue_id] = run_custom_checks_safe(repo_root, global_issue_id)
    % Run repository-specific custom checks with exception handling
    % FIX #2: Use cell array accumulation instead of growing arrays
    % FIX #3: Accept and return global_issue_id for unique IDs across phases
    % FIX #8: Change ANLZ-002 to SA-RUNTIME-0001
    
    issues_cell = cell(0);  % FIX #2: Cell array accumulation
    
    % Check 1: Required directories
    fprintf('  [1/3] Required directories...\n');
    required_dirs = {
        'Scripts/Drivers';
        'Scripts/Solvers';
        'Scripts/Infrastructure';
        'Scripts/Editable';
        'Scripts/UI';
        'Data';
        'tests';
    };
    
    for i = 1:length(required_dirs)
        dir_path = fullfile(repo_root, required_dirs{i});
        if ~exist(dir_path, 'dir')
            global_issue_id = global_issue_id + 1;  % FIX #3: Increment global counter
            issue_struct = struct(...
                'id', global_issue_id, ...
                'code', 'REPO-001', ...
                'severity', 'CRITICAL', ...
                'impact', 'RUNTIME_ERROR_LIKELY', ...
                'category', 'STRUCTURE', ...
                'file', '', ...
                'line', 0, ...
                'column', 0, ...
                'message', sprintf('Missing required directory: %s', required_dirs{i}), ...
                'rule_id', 'REPO-001', ...
                'remediation', 'Create the missing directory structure.');
            issues_cell{end+1} = issue_struct;  % FIX #2: Cell array append
        end
    end
    
    % Check 2: Required entry points
    fprintf('  [2/3] Entry point files...\n');
    entry_points = {
        'Scripts/Drivers/Analysis.m';
        'Scripts/Infrastructure/Runners/ModeDispatcher.m';
        'Scripts/Editable/Parameters.m';
        'Scripts/Editable/Settings.m';
        'Scripts/UI/UIController.m';
        'Scripts/UI/UI_Layout_Config.m';
    };
    
    for i = 1:length(entry_points)
        file_path = fullfile(repo_root, entry_points{i});
        if ~exist(file_path, 'file')
            global_issue_id = global_issue_id + 1;  % FIX #3: Increment global counter
            issue_struct = struct(...
                'id', global_issue_id, ...
                'code', 'REPO-002', ...
                'severity', 'CRITICAL', ...
                'impact', 'RUNTIME_ERROR_LIKELY', ...
                'category', 'ENTRY_POINT', ...
                'file', entry_points{i}, ...
                'line', 0, ...
                'column', 0, ...
                'message', sprintf('Missing entry point: %s', entry_points{i}), ...
                'rule_id', 'REPO-002', ...
                'remediation', 'Ensure all required entry point files exist.');
            issues_cell{end+1} = issue_struct;  % FIX #2: Cell array append
        end
    end
    
    % Check 3: Position usage in UIController (repo-specific pattern check)
    fprintf('  [3/3] UIController Position usage...\n');
    ui_file = fullfile(repo_root, 'Scripts', 'UI', 'UIController.m');
    
    if exist(ui_file, 'file')
        try
            ui_text = fileread(ui_file);
            ui_lines = splitlines(string(ui_text));
            
            % Allowlist patterns
            allowed_patterns = {'dialog_fig', 'inspector_fig', 'rectangle'};
            
            for i = 1:length(ui_lines)
                line = ui_lines(i);
                
                % Strip comments
                pct_idx = strfind(char(line), '%');
                if ~isempty(pct_idx)
                    line = extractBefore(line, pct_idx(1));
                end
                
                % Check for Position usage
                if contains(line, 'Position', 'IgnoreCase', false)
                    % Check if it's in allowlist
                    is_allowed = false;
                    for j = 1:length(allowed_patterns)
                        if contains(line, allowed_patterns{j})
                            is_allowed = true;
                            break;
                        end
                    end
                    
                    if ~is_allowed
                        global_issue_id = global_issue_id + 1;  % FIX #3: Increment global counter
                        issue_struct = struct(...
                            'id', global_issue_id, ...
                            'code', 'CUST-001', ...
                            'severity', 'MAJOR', ...
                            'impact', 'LOGIC_RISK', ...
                            'category', 'PATTERN', ...
                            'file', 'Scripts/UI/UIController.m', ...
                            'line', i, ...
                            'column', 0, ...
                            'message', sprintf('Potentially problematic Position usage: %s', strip(line)), ...
                            'rule_id', 'CUST-001', ...
                            'remediation', 'Use Units=''normalized'' instead of absolute Position for cross-platform compatibility.');
                        issues_cell{end+1} = issue_struct;  % FIX #2: Cell array append
                    end
                end
            end
        catch ME
            % Error reading UIController - FIX #8: Use SA-RUNTIME-0001
            global_issue_id = global_issue_id + 1;  % FIX #3: Increment global counter
            issue_struct = struct(...
                'id', global_issue_id, ...
                'code', 'SA-RUNTIME-0001', ...
                'severity', 'MAJOR', ...
                'impact', 'ANALYZER_FAILURE', ...
                'category', 'ANALYZER_ERROR', ...
                'file', 'Scripts/UI/UIController.m', ...
                'line', 0, ...
                'column', 0, ...
                'message', sprintf('Failed to check UIController: %s', ME.message), ...
                'rule_id', 'SA-RUNTIME-0001', ...
                'remediation', 'File may be corrupted or unreadable.');
            issues_cell{end+1} = issue_struct;  % FIX #2: Cell array append
        end
    else
        global_issue_id = global_issue_id + 1;  % FIX #3: Increment global counter
        issue_struct = struct(...
            'id', global_issue_id, ...
            'code', 'REPO-002', ...
            'severity', 'CRITICAL', ...
            'impact', 'RUNTIME_ERROR_LIKELY', ...
            'category', 'ENTRY_POINT', ...
            'file', 'Scripts/UI/UIController.m', ...
            'line', 0, ...
            'column', 0, ...
            'message', 'UIController.m not found', ...
            'rule_id', 'REPO-002', ...
            'remediation', 'Ensure UIController.m exists in Scripts/UI/');
        issues_cell{end+1} = issue_struct;  % FIX #2: Cell array append
    end
    
    % FIX #2: Convert cell array to struct array at end
    if ~isempty(issues_cell)
        issues = vertcat(issues_cell{:});
    else
        issues = [];
    end
end

function write_json_report(filepath, report)
    % Write JSON report (MATLAB's jsonencode is safe and efficient)
    
    try
        json_str = jsonencode(report);
        
        % Write to file
        fid = fopen(filepath, 'w');
        if fid == -1
            error('Could not open file for writing: %s', filepath);
        end
        fprintf(fid, '%s', json_str);
        fclose(fid);
    catch ME
        fprintf(2, 'Warning: Could not write JSON report: %s\n', ME.message);
    end
end

function write_markdown_report(filepath, report)
    % Write human-readable markdown report
    
    try
        fid = fopen(filepath, 'w');
        if fid == -1
            error('Could not open file for writing: %s', filepath);
        end
        
        % Header
        fprintf(fid, '# Static Analysis Report\n\n');
        fprintf(fid, '**Generated:** %s  \n', report.metadata.timestamp);
        fprintf(fid, '**MATLAB Version:** %s  \n', report.metadata.matlab_version);
        fprintf(fid, '**Hostname:** %s  \n\n', report.metadata.hostname);
        
        % Summary
        fprintf(fid, '## Summary\n\n');
        fprintf(fid, '| Metric | Count |\n');
        fprintf(fid, '|--------|-------|\n');
        fprintf(fid, '| **Total Issues** | %d |\n', report.summary.total);
        fprintf(fid, '| CRITICAL | %d |\n', report.summary.critical);
        fprintf(fid, '| MAJOR | %d |\n', report.summary.major);
        fprintf(fid, '| MINOR | %d |\n\n', report.summary.minor);
        
        % Phase timing
        fprintf(fid, '## Phase Execution\n\n');
        fprintf(fid, '| Phase | Status | Details |\n');
        fprintf(fid, '|-------|--------|---------|  \n');
        
        phase_names = fieldnames(report.phases);
        for i = 1:length(phase_names)
            phase_name = phase_names{i};
            phase = report.phases.(phase_name);
            if isfield(phase, 'elapsed_sec')
                fprintf(fid, '| %s | %s | %.2f sec |\n', ...
                    upper(phase_name), phase.status, phase.elapsed_sec);
            else
                fprintf(fid, '| %s | %s | - |\n', upper(phase_name), phase.status);
            end
        end
        fprintf(fid, '\n');
        
        % Issues by severity
        if report.summary.total > 0
            severities = {'CRITICAL', 'MAJOR', 'MINOR'};
            
            for s = 1:length(severities)
                sev = severities{s};
                sev_issues = report.issues.all(strcmp({report.issues.all.severity}, sev));
                
                if ~isempty(sev_issues)
                    fprintf(fid, '## %s Issues (%d)\n\n', sev, length(sev_issues));
                    
                    for i = 1:length(sev_issues)
                        issue = sev_issues(i);
                        fprintf(fid, '### [%s] %s\n\n', issue.code, issue.category);
                        if ~isempty(issue.file)
                            fprintf(fid, '**File:** `%s`  \n', issue.file);
                            if issue.line > 0
                                fprintf(fid, '**Line:** %d  \n', issue.line);
                            end
                        end
                        fprintf(fid, '**Message:** %s  \n', issue.message);
                        fprintf(fid, '**Remediation:** %s  \n\n', issue.remediation);
                    end
                end
            end
        else
            fprintf(fid, '## ✓ No Issues Found\n\n');
            fprintf(fid, 'All checks passed successfully.\n\n');
        end
        
        % Footer
        fprintf(fid, '---\n\n');
        fprintf(fid, '*Generated by MECH0020 Static Analysis System v3.1*\n');
        
        fclose(fid);
    catch ME
        fprintf(2, 'Warning: Could not write Markdown report: %s\n', ME.message);
        if fid ~= -1
            fclose(fid);
        end
    end
end

function report = create_error_report(runtime_error_details, test_dir)
    % Create minimal error report when analyzer crashes catastrophically
    
    report = struct();
    report.metadata = struct();
    report.metadata.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    report.metadata.repo_root = fileparts(test_dir);
    report.metadata.matlab_version = version;
    report.metadata.hostname = 'unknown';
    report.metadata.analyzer_crashed = true;
    
    report.phases = struct();
    report.issues = struct('all', [], 'by_severity', struct(), 'by_file', struct());
    report.summary = struct('total', 1, 'critical', 1, 'major', 0, 'minor', 0);
    report.file_counts = struct('found', 0, 'analyzed', 0, 'excluded', 0, 'errors', 1);
    
    % Create catastrophic error issue
    issue = struct(...
        'id', 1, ...
        'code', 'SA-RUNTIME-0001', ...
        'severity', 'CRITICAL', ...
        'impact', 'ANALYZER_FAILURE', ...
        'category', 'ANALYZER_CRASH', ...
        'file', '', ...
        'line', 0, ...
        'column', 0, ...
        'message', sprintf('Analyzer crashed: %s', runtime_error_details.exception), ...
        'rule_id', 'SA-RUNTIME-0001', ...
        'remediation', 'Fix analyzer internal error before analyzing code.');
    
    report.issues.all = issue;
end
