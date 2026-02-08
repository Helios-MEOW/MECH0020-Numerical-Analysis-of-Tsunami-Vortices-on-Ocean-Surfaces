% static_analysis.m - Static code analysis for MECH0020 repository
%
% Purpose:
%   Run MATLAB Code Analyzer and custom checks
%   Detect common issues (missing files, undefined vars, etc.)
%
% Usage:
%   >> cd tests
%   >> static_analysis
%
% Output:
%   Console report of issues found
%   Exit code 0 if no critical issues, 1 otherwise

clc; clear;

fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('  STATIC CODE ANALYSIS\n');
fprintf('═══════════════════════════════════════════════════════════════\n\n');

test_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(test_dir);

fprintf('Repository root: %s\n\n', repo_root);

% ===== COLLECT MATLAB FILES =====
fprintf('Scanning for .m files across entire repository...\n');

% Scan multiple directories (everything a user would download in the zip)
scan_dirs = {'Scripts', 'utilities', 'tests'};
all_m_files = [];

for i = 1:length(scan_dirs)
    dir_path = fullfile(repo_root, scan_dirs{i});
    if exist(dir_path, 'dir')
        files_in_dir = dir(fullfile(dir_path, '**', '*.m'));
        all_m_files = [all_m_files; files_in_dir]; %#ok<AGROW>
    end
end

% Also check for any .m files in the root directory
root_m_files = dir(fullfile(repo_root, '*.m'));
all_m_files = [all_m_files; root_m_files];

n_files = length(all_m_files);
fprintf('  Found %d MATLAB files\n\n', n_files);

% ===== RUN CODE ANALYZER =====
fprintf('───────────────────────────────────────────────────────────────\n');
fprintf('  MATLAB CODE ANALYZER (checkcode)\n');
fprintf('───────────────────────────────────────────────────────────────\n\n');

total_issues = 0;
critical_issues = 0;

for i = 1:n_files
    filepath = fullfile(all_m_files(i).folder, all_m_files(i).name);
    
    % Skip test files and temporary files
    if contains(filepath, 'test') || contains(filepath, 'TEST')
        continue;
    end
    
    try
        % Run checkcode
        info = checkcode(filepath, '-id');
        
        if ~isempty(info)
            n_issues = length(info);
            total_issues = total_issues + n_issues;
            
            % Check for critical issues
            for j = 1:n_issues
                if contains(info(j).id, 'NOSEM') || ...
                   contains(info(j).id, 'NODEF') || ...
                   contains(info(j).id, 'INUSD')
                    critical_issues = critical_issues + 1;
                end
            end
            
            % Print file issues (limit to critical only for brevity)
            rel_path = strrep(filepath, [repo_root filesep], '');
            critical_in_file = sum(arrayfun(@(x) contains(x.id, 'NOSEM') || ...
                                             contains(x.id, 'NODEF') || ...
                                             contains(x.id, 'INUSD'), info));
            
            if critical_in_file > 0
                fprintf('%s: %d issues (%d critical)\n', rel_path, n_issues, critical_in_file);
            end
        end
    catch
        % checkcode failed (syntax error or file unreadable)
        fprintf('ERROR analyzing: %s\n', all_m_files(i).name);
        critical_issues = critical_issues + 1;
    end
end

fprintf('\n');
fprintf('Total issues: %d (across %d files)\n', total_issues, n_files);
fprintf('Critical issues: %d\n\n', critical_issues);

% ===== CUSTOM CHECKS =====
fprintf('───────────────────────────────────────────────────────────────\n');
fprintf('  CUSTOM CHECKS\n');
fprintf('───────────────────────────────────────────────────────────────\n\n');

custom_issues = 0;

% Check 1: Missing required directories
fprintf('[1/3] Checking required directories...\n');
required_dirs = {
    fullfile(repo_root, 'Scripts', 'Drivers');
    fullfile(repo_root, 'Scripts', 'Solvers');
    fullfile(repo_root, 'Scripts', 'Infrastructure');
    fullfile(repo_root, 'Scripts', 'Editable');
    fullfile(repo_root, 'Scripts', 'UI');
    fullfile(repo_root, 'Data');
    fullfile(repo_root, 'tests');
};

for i = 1:length(required_dirs)
    if ~exist(required_dirs{i}, 'dir')
        fprintf('  ✗ Missing directory: %s\n', required_dirs{i});
        custom_issues = custom_issues + 1;
    end
end
fprintf('  ✓ Directory check complete\n\n');

% Check 2: Entry points exist
fprintf('[2/3] Checking entry point files...\n');
entry_points = {
    fullfile(repo_root, 'Scripts', 'Drivers', 'Analysis.m');
    fullfile(repo_root, 'Scripts', 'Infrastructure', 'Runners', 'ModeDispatcher.m');
    fullfile(repo_root, 'Scripts', 'Editable', 'Parameters.m');
    fullfile(repo_root, 'Scripts', 'Editable', 'Settings.m');
    fullfile(repo_root, 'Scripts', 'UI', 'UIController.m');
    fullfile(repo_root, 'Scripts', 'UI', 'UI_Layout_Config.m');
};

for i = 1:length(entry_points)
    if ~exist(entry_points{i}, 'file')
        fprintf('  ✗ Missing entry point: %s\n', entry_points{i});
        custom_issues = custom_issues + 1;
    end
end
fprintf('  ✓ Entry point check complete\n\n');

% Check 3: No Position usage in UIController (except allowed cases)
fprintf('[3/3] Checking for leftover Position usage in UIController...\n');
ui_file = fullfile(repo_root, 'Scripts', 'UI', 'UIController.m');
if exist(ui_file, 'file')
    ui_text = fileread(ui_file);
    ui_lines = splitlines(string(ui_text));
    
    position_count = 0;
    for i = 1:length(ui_lines)
        line = ui_lines(i);
        
        % Strip comments more robustly: find first unquoted %
        % Simple approach: split on % and take first part (ignores strings for simplicity)
        line_without_comment = line;
        pct_idx = strfind(char(line), '%');
        if ~isempty(pct_idx)
            % Take everything before the first %
            line_without_comment = extractBefore(line, pct_idx(1));
        end
        
        % Now check for Position in the code part only
        if contains(line_without_comment, 'Position') && ...
           ~contains(line_without_comment, 'dialog_fig') && ...
           ~contains(line_without_comment, 'inspector_fig') && ...
           ~contains(line_without_comment, 'rectangle')
            position_count = position_count + 1;
            fprintf('  Line %d: %s\n', i, strip(line));
        end
    end
    
    if position_count > 0
        fprintf('  ✗ Found %d potentially problematic Position usages\n', position_count);
        custom_issues = custom_issues + position_count;
    else
        fprintf('  ✓ No problematic Position usage found\n');
    end
else
    fprintf('  ✗ UIController.m not found\n');
    custom_issues = custom_issues + 1;
end

fprintf('\n');

% ===== SUMMARY =====
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('  ANALYSIS SUMMARY\n');
fprintf('═══════════════════════════════════════════════════════════════\n\n');

fprintf('MATLAB Code Analyzer:\n');
fprintf('  Total issues: %d\n', total_issues);
fprintf('  Critical: %d\n\n', critical_issues);

fprintf('Custom Checks:\n');
fprintf('  Issues found: %d\n\n', custom_issues);

total_critical = critical_issues + custom_issues;

if total_critical == 0
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  ✓ STATIC ANALYSIS PASSED\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');
    exit_code = 0;
else
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  ✗ STATIC ANALYSIS FOUND ISSUES\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');
    exit_code = 1;
end

% Exit with appropriate code for CI
if ~usejava('desktop')
    exit(exit_code);
end
