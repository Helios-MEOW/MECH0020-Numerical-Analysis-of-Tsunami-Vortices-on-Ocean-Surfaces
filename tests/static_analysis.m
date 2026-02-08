% static_analysis.m - Robust Static Code Analysis for MECH0020 Repository
%
% PURPOSE:
%   Crash-safe static analysis with structured issue reporting.
%   Runs MATLAB Code Analyzer and custom checks, streams results to disk,
%   and generates comprehensive reports with issue codes.
%
% USAGE:
%   >> cd tests
%   >> static_analysis
%
% OUTPUT:
%   - Console: Progress and summary
%   - JSON: tests/static_analysis_report.json (machine-readable)
%   - Markdown: tests/static_analysis_report.md (human-readable)
%   
% EXIT CODES:
%   0 = PASS (no issues)
%   1 = FAIL (issues found; see reports for details)
%   2 = ERROR (analyzer crashed; check console/JSON for exception details)
%
% ISSUE CODE TAXONOMY:
%   MLAB-xxx: MATLAB Code Analyzer issues (mapped from checkcode)
%   REPO-xxx: Repository structure/entry point issues
%   CUST-xxx: Custom code pattern checks
%   ANLZ-xxx: Analyzer internal errors
%
% AUTHOR: MECH0020 Static Analysis System
% VERSION: 2.0 (Crash-hardened)

function static_analysis()
    % Main entry point - wrapped in global exception handler
    exit_code = 2; % Default to ERROR until we succeed
    
    try
        exit_code = run_analysis_safe();
    catch ME
        % Catastrophic failure - analyzer itself crashed
        fprintf(2, '\n');
        fprintf(2, '═══════════════════════════════════════════════════════════════\n');
        fprintf(2, '  ✗✗✗ ANALYZER FATAL ERROR ✗✗✗\n');
        fprintf(2, '═══════════════════════════════════════════════════════════════\n');
        fprintf(2, 'Exception: %s\n', ME.message);
        fprintf(2, 'Location: %s\n', ME.stack(1).name);
        fprintf(2, 'Line: %d\n', ME.stack(1).line);
        fprintf(2, '\nStack trace:\n');
        for i = 1:min(3, length(ME.stack))
            fprintf(2, '  [%d] %s (line %d)\n', i, ME.stack(i).name, ME.stack(i).line);
        end
        fprintf(2, '═══════════════════════════════════════════════════════════════\n\n');
        exit_code = 2;
    end
    
    % Exit with appropriate code for CI (only if not running in desktop)
    if ~usejava('desktop')
        exit(exit_code);
    end
end

function exit_code = run_analysis_safe()
    % Main analysis logic with phase tracking and incremental reporting
    
    clc;
    
    % Initialize
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  STATIC CODE ANALYSIS v2.0 (Crash-Hardened)\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');
    
    test_dir = fileparts(mfilename('fullpath'));
    repo_root = fileparts(test_dir);
    
    fprintf('Repository: %s\n', repo_root);
    fprintf('Started: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    
    % Phase tracking
    phase_start = tic;
    current_phase = 'INIT';
    
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
    
    % Output files
    json_file = fullfile(test_dir, 'static_analysis_report.json');
    md_file = fullfile(test_dir, 'static_analysis_report.md');
    
    % Issue counter
    issue_id = 0;
    
    try
        % ===== PHASE 1: FILE COLLECTION =====
        current_phase = 'FILE_COLLECTION';
        fprintf('───────────────────────────────────────────────────────────────\n');
        fprintf('[PHASE 1] Collecting MATLAB files...\n');
        fprintf('───────────────────────────────────────────────────────────────\n\n');
        
        phase_start = tic;
        
        scan_dirs = {'Scripts', 'utilities', 'tests'};
        file_list = collect_files_safe(repo_root, scan_dirs);
        
        n_files = length(file_list);
        fprintf('  Found %d MATLAB files\n', n_files);
        
        report.phases.file_collection = struct(...
            'status', 'COMPLETE', ...
            'files_found', n_files, ...
            'elapsed_sec', toc(phase_start));
        
        fprintf('  Elapsed: %.2f sec\n\n', report.phases.file_collection.elapsed_sec);
        
        % ===== PHASE 2: MATLAB CODE ANALYZER =====
        current_phase = 'CODE_ANALYZER';
        fprintf('───────────────────────────────────────────────────────────────\n');
        fprintf('[PHASE 2] Running MATLAB Code Analyzer (per-file, crash-safe)...\n');
        fprintf('───────────────────────────────────────────────────────────────\n\n');
        
        phase_start = tic;
        
        mlab_issues = run_code_analyzer_safe(file_list, repo_root);
        
        report.phases.code_analyzer = struct(...
            'status', 'COMPLETE', ...
            'files_analyzed', n_files, ...
            'issues_found', length(mlab_issues), ...
            'elapsed_sec', toc(phase_start));
        
        fprintf('  Issues found: %d\n', length(mlab_issues));
        fprintf('  Elapsed: %.2f sec\n\n', report.phases.code_analyzer.elapsed_sec);
        
        % Add to report
        report.issues.all = [report.issues.all, mlab_issues];
        
        % ===== PHASE 3: CUSTOM CHECKS =====
        current_phase = 'CUSTOM_CHECKS';
        fprintf('───────────────────────────────────────────────────────────────\n');
        fprintf('[PHASE 3] Running custom repository checks...\n');
        fprintf('───────────────────────────────────────────────────────────────\n\n');
        
        phase_start = tic;
        
        custom_issues = run_custom_checks_safe(repo_root);
        
        report.phases.custom_checks = struct(...
            'status', 'COMPLETE', ...
            'issues_found', length(custom_issues), ...
            'elapsed_sec', toc(phase_start));
        
        fprintf('  Issues found: %d\n', length(custom_issues));
        fprintf('  Elapsed: %.2f sec\n\n', report.phases.custom_checks.elapsed_sec);
        
        % Add to report
        report.issues.all = [report.issues.all, custom_issues];
        
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
        
        % ===== PHASE 5: WRITE REPORTS =====
        current_phase = 'REPORTING';
        fprintf('───────────────────────────────────────────────────────────────\n');
        fprintf('[PHASE 5] Writing reports...\n');
        fprintf('───────────────────────────────────────────────────────────────\n\n');
        
        % Write JSON (incremental, structured)
        write_json_report(json_file, report);
        fprintf('  JSON report: %s\n', json_file);
        
        % Write Markdown (human-readable)
        write_markdown_report(md_file, report);
        fprintf('  Markdown report: %s\n\n', md_file);
        
        % ===== FINAL SUMMARY =====
        fprintf('═══════════════════════════════════════════════════════════════\n');
        fprintf('  ANALYSIS SUMMARY\n');
        fprintf('═══════════════════════════════════════════════════════════════\n\n');
        
        fprintf('Total issues: %d (CRITICAL: %d, MAJOR: %d, MINOR: %d)\n\n', ...
            report.summary.total, report.summary.critical, ...
            report.summary.major, report.summary.minor);
        
        % Determine exit code
        if report.summary.total == 0
            fprintf('═══════════════════════════════════════════════════════════════\n');
            fprintf('  ✓ STATIC ANALYSIS PASSED\n');
            fprintf('═══════════════════════════════════════════════════════════════\n\n');
            exit_code = 0;
        else
            fprintf('═══════════════════════════════════════════════════════════════\n');
            fprintf('  ✗ STATIC ANALYSIS FOUND ISSUES\n');
            fprintf('  Review: %s\n', md_file);
            fprintf('═══════════════════════════════════════════════════════════════\n\n');
            exit_code = 1;
        end
        
    catch ME
        % Phase-specific error
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
        
        exit_code = 2;
    end
end

%% ========================================================================
%  LOCAL FUNCTIONS (Crash-Safe Implementations)
%% ========================================================================

function file_list = collect_files_safe(repo_root, scan_dirs)
    % Collect .m files with pre-allocation to avoid memory issues
    
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
    
    % Pre-allocate cell array
    file_list = cell(total_count, 1);
    idx = 0;
    
    % Collect files
    for i = 1:length(scan_dirs)
        dir_path = fullfile(repo_root, scan_dirs{i});
        if exist(dir_path, 'dir')
            files_in_dir = dir(fullfile(dir_path, '**', '*.m'));
            for j = 1:length(files_in_dir)
                idx = idx + 1;
                file_list{idx} = fullfile(files_in_dir(j).folder, files_in_dir(j).name);
            end
        end
    end
    
    % Add root files
    for j = 1:length(root_files)
        idx = idx + 1;
        file_list{idx} = fullfile(root_files(j).folder, root_files(j).name);
    end
    
    % Sort for deterministic order
    file_list = sort(file_list);
end

function issues = run_code_analyzer_safe(file_list, repo_root)
    % Run checkcode per-file with exception handling
    
    issues = [];
    issue_id = 0;
    
    n_files = length(file_list);
    analyzed = 0;
    errors = 0;
    
    for i = 1:n_files
        filepath = file_list{i};
        
        % Skip test files (optional - remove if you want to analyze tests too)
        if contains(filepath, filesep, 'Ignorecase', true) && ...
           (contains(filepath, 'test', 'IgnoreCase', true) || ...
            contains(filepath, 'TEST'))
            continue;
        end
        
        try
            % Run checkcode with struct output
            info = checkcode(filepath, '-id');
            analyzed = analyzed + 1;
            
            if ~isempty(info)
                % Process each issue
                for j = 1:length(info)
                    issue_id = issue_id + 1;
                    
                    % Map to our issue code taxonomy
                    [code, severity, remediation] = map_checkcode_issue(info(j).id);
                    
                    rel_path = strrep(filepath, [repo_root filesep], '');
                    
                    issue_struct = struct(...
                        'id', issue_id, ...
                        'code', code, ...
                        'severity', severity, ...
                        'category', 'CODE_ANALYZER', ...
                        'file', rel_path, ...
                        'line', info(j).line, ...
                        'column', info(j).column, ...
                        'message', info(j).message, ...
                        'rule_id', info(j).id, ...
                        'remediation', remediation);
                    
                    issues = [issues, issue_struct]; %#ok<AGROW>
                end
            end
            
            % Progress (every 10 files)
            if mod(i, 10) == 0
                fprintf('  Progress: %d/%d files analyzed (%d issues so far)\n', ...
                    analyzed, n_files, length(issues));
            end
            
        catch ME
            % checkcode failed for this file
            errors = errors + 1;
            issue_id = issue_id + 1;
            
            rel_path = strrep(filepath, [repo_root filesep], '');
            
            issue_struct = struct(...
                'id', issue_id, ...
                'code', 'ANLZ-001', ...
                'severity', 'MAJOR', ...
                'category', 'ANALYZER_ERROR', ...
                'file', rel_path, ...
                'line', 0, ...
                'column', 0, ...
                'message', sprintf('checkcode failed: %s', ME.message), ...
                'rule_id', 'ANLZ-001', ...
                'remediation', 'File may have syntax errors or be unreadable');
            
            issues = [issues, issue_struct]; %#ok<AGROW>
        end
    end
    
    fprintf('  Analyzed: %d files\n', analyzed);
    fprintf('  Errors: %d files\n', errors);
end

function [code, severity, remediation] = map_checkcode_issue(checkcode_id)
    % Map MATLAB checkcode IDs to our taxonomy
    
    % Critical issues
    if any(strcmp(checkcode_id, {'NODEF', 'NOSEM', 'INUSD', 'MCNPR', 'MCVID'}))
        severity = 'CRITICAL';
        code = sprintf('MLAB-CRIT-%s', checkcode_id);
        
        switch checkcode_id
            case 'NODEF'
                remediation = 'Function is called but not defined. Add function definition or check spelling.';
            case 'NOSEM'
                remediation = 'Missing semicolon may cause excessive output. Add semicolon.';
            case 'INUSD'
                remediation = 'Variable set but never used. Remove or use the variable.';
            case 'MCNPR'
                remediation = 'File name must match function name for proper calling.';
            case 'MCVID'
                remediation = 'Invalid identifier. Use valid MATLAB variable/function names.';
            otherwise
                remediation = 'Critical issue detected. Review and fix immediately.';
        end
        
    % Major issues
    elseif any(strcmp(checkcode_id, {'NBRAK', 'NOPRT', 'AGROW', 'SAGROW', 'PSIZE', 'GVMIS'}))
        severity = 'MAJOR';
        code = sprintf('MLAB-MAJR-%s', checkcode_id);
        
        switch checkcode_id
            case 'NBRAK'
                remediation = 'Unbalanced brackets. Check syntax carefully.';
            case 'NOPRT'
                remediation = 'Function has no output. Consider returning a value or making it a script.';
            case 'AGROW'
                remediation = 'Variable growing inside loop. Pre-allocate for better performance.';
            case 'SAGROW'
                remediation = 'Variable growing inside loop (string). Pre-allocate or use string array.';
            case 'PSIZE'
                remediation = 'Variable size changes. Pre-allocate for better performance.';
            case 'GVMIS'
                remediation = 'Global variable mismatch. Declare global consistently.';
            otherwise
                remediation = 'Significant issue. Review for correctness and performance.';
        end
        
    % Minor issues (style, best practices)
    else
        severity = 'MINOR';
        code = sprintf('MLAB-MINR-%s', checkcode_id);
        remediation = 'Style or best practice issue. Consider addressing for code quality.';
    end
end

function issues = run_custom_checks_safe(repo_root)
    % Run repository-specific custom checks with exception handling
    
    issues = [];
    issue_id = 0;
    
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
            issue_id = issue_id + 1;
            issue_struct = struct(...
                'id', issue_id, ...
                'code', 'REPO-001', ...
                'severity', 'CRITICAL', ...
                'category', 'STRUCTURE', ...
                'file', '', ...
                'line', 0, ...
                'column', 0, ...
                'message', sprintf('Missing required directory: %s', required_dirs{i}), ...
                'rule_id', 'REPO-001', ...
                'remediation', 'Create the missing directory structure.');
            issues = [issues, issue_struct]; %#ok<AGROW>
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
            issue_id = issue_id + 1;
            issue_struct = struct(...
                'id', issue_id, ...
                'code', 'REPO-002', ...
                'severity', 'CRITICAL', ...
                'category', 'ENTRY_POINT', ...
                'file', entry_points{i}, ...
                'line', 0, ...
                'column', 0, ...
                'message', sprintf('Missing entry point: %s', entry_points{i}), ...
                'rule_id', 'REPO-002', ...
                'remediation', 'Ensure all required entry point files exist.');
            issues = [issues, issue_struct]; %#ok<AGROW>
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
                        issue_id = issue_id + 1;
                        issue_struct = struct(...
                            'id', issue_id, ...
                            'code', 'CUST-001', ...
                            'severity', 'MAJOR', ...
                            'category', 'PATTERN', ...
                            'file', 'Scripts/UI/UIController.m', ...
                            'line', i, ...
                            'column', 0, ...
                            'message', sprintf('Potentially problematic Position usage: %s', strip(line)), ...
                            'rule_id', 'CUST-001', ...
                            'remediation', 'Use Units=''normalized'' instead of absolute Position for cross-platform compatibility.');
                        issues = [issues, issue_struct]; %#ok<AGROW>
                    end
                end
            end
        catch ME
            % Error reading UIController
            issue_id = issue_id + 1;
            issue_struct = struct(...
                'id', issue_id, ...
                'code', 'ANLZ-002', ...
                'severity', 'MAJOR', ...
                'category', 'ANALYZER_ERROR', ...
                'file', 'Scripts/UI/UIController.m', ...
                'line', 0, ...
                'column', 0, ...
                'message', sprintf('Failed to check UIController: %s', ME.message), ...
                'rule_id', 'ANLZ-002', ...
                'remediation', 'File may be corrupted or unreadable.');
            issues = [issues, issue_struct]; %#ok<AGROW>
        end
    else
        issue_id = issue_id + 1;
        issue_struct = struct(...
            'id', issue_id, ...
            'code', 'REPO-002', ...
            'severity', 'CRITICAL', ...
            'category', 'ENTRY_POINT', ...
            'file', 'Scripts/UI/UIController.m', ...
            'line', 0, ...
            'column', 0, ...
            'message', 'UIController.m not found', ...
            'rule_id', 'REPO-002', ...
            'remediation', 'Ensure UIController.m exists in Scripts/UI/');
        issues = [issues, issue_struct]; %#ok<AGROW>
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
        fprintf(fid, '*Generated by MECH0020 Static Analysis System v2.0*\n');
        
        fclose(fid);
    catch ME
        fprintf(2, 'Warning: Could not write Markdown report: %s\n', ME.message);
        if fid ~= -1
            fclose(fid);
        end
    end
end
