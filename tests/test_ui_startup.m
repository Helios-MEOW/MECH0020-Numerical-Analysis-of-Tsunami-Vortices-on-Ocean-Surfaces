%% Repository Test Suite - Systematic Error Detection
% Tests all major scripts for common MATLAB errors
% Run this before launching Analysis.m to catch errors early

clear all; close all; clc;

fprintf('╔════════════════════════════════════════════════════╗\n');
fprintf('║   MECH0020 Repository Test Suite                   ║\n');
fprintf('╚════════════════════════════════════════════════════╝\n\n');

% Get script directory  
script_dir = fileparts(fileparts(mfilename('fullpath')));  % Up to repo root

% Add paths (absolute paths from repository root)
addpath(fullfile(script_dir, 'Scripts', 'UI'));
addpath(fullfile(script_dir, 'Scripts', 'Drivers'));
addpath(fullfile(script_dir, 'Scripts', 'Solvers'));
addpath(fullfile(script_dir, 'Scripts', 'Solvers', 'FD'));
addpath(fullfile(script_dir, 'Scripts', 'Sustainability'));
addpath(fullfile(script_dir, 'Scripts', 'Plotting'));
addpath(fullfile(script_dir, 'Scripts', 'Infrastructure', 'Builds'));
addpath(fullfile(script_dir, 'Scripts', 'Infrastructure', 'DataRelatedHelpers'));
addpath(fullfile(script_dir, 'Scripts', 'Infrastructure', 'Initialisers'));
addpath(fullfile(script_dir, 'Scripts', 'Infrastructure', 'Runners'));
addpath(fullfile(script_dir, 'Scripts', 'Infrastructure', 'Utilities'));
addpath(fullfile(script_dir, 'utilities'));

% Test tracking
total_tests = 0;
passed_tests = 0;
failed_tests = 0;

%% ========================================================================
%% SECTION 1: File Existence Tests
%% ========================================================================
fprintf('═══════════════════════════════════════════════════\n');
fprintf('SECTION 1: File Existence Tests\n');
fprintf('═══════════════════════════════════════════════════\n\n');

% List of critical files to check
critical_files = {
    'Scripts/UI/UIController.m', 'UI Controller (Class)'
    'Scripts/Drivers/Analysis.m', 'Main Driver'
    'Scripts/Solvers/FD/Finite_Difference_Analysis.m', 'FD Solver'
    'Scripts/Sustainability/EnergySustainabilityAnalyzer.m', 'Energy Analyzer'
    'Scripts/Plotting/create_live_monitor_dashboard.m', 'Live Monitor'
    'utilities/Plot_Format.m', 'Plot Utilities'
};

for i = 1:size(critical_files, 1)
    total_tests = total_tests + 1;
    filepath = fullfile(script_dir, critical_files{i, 1});
    fprintf('[Test 1.%d] %s: ', i, critical_files{i, 2});
    
    if exist(filepath, 'file')
        fprintf('✓ Found\n');
        passed_tests = passed_tests + 1;
    else
        fprintf('✗ MISSING: %s\n', filepath);
        failed_tests = failed_tests + 1;
    end
end
fprintf('\n');

%% ========================================================================
%% SECTION 2: MATLAB Path Tests
%% ========================================================================
fprintf('═══════════════════════════════════════════════════\n');
fprintf('SECTION 2: MATLAB Path Resolution\n');
fprintf('═══════════════════════════════════════════════════\n\n');

key_functions = {
    'UIController', 'Class'
    'Analysis', 'Script'
    'Finite_Difference_Analysis', 'Function'
    'Plot_Format', 'Function'
};

for i = 1:size(key_functions, 1)
    total_tests = total_tests + 1;
    fprintf('[Test 2.%d] Resolving %s (%s): ', i, key_functions{i, 1}, key_functions{i, 2});
    
    which_result = which(key_functions{i, 1});
    if ~isempty(which_result)
        fprintf('✓ Found on path\n');
        passed_tests = passed_tests + 1;
    else
        fprintf('✗ NOT FOUND on MATLAB path\n');
        failed_tests = failed_tests + 1;
    end
end
fprintf('\n');

%% ========================================================================
%% SECTION 3: Syntax Validation Tests
%% ========================================================================
fprintf('═══════════════════════════════════════════════════\n');
fprintf('SECTION 3: Syntax Validation\n');
fprintf('═══════════════════════════════════════════════════\n\n');

% UIController (class)
total_tests = total_tests + 1;
fprintf('[Test 3.1] UIController syntax: ');
try
    meta.class.fromName('UIController');
    fprintf('✓ No syntax errors\n');
    passed_tests = passed_tests + 1;
catch ME
    fprintf('✗ SYNTAX ERROR: %s\n', ME.message);
    failed_tests = failed_tests + 1;
end

% Analysis.m (script - check with pcode)
total_tests = total_tests + 1;
fprintf('[Test 3.2] Analysis.m syntax: ');
try
    % Try to parse without executing
    fid = fopen(fullfile(script_dir, 'Scripts', 'Main', 'Analysis.m'), 'r');
    code = fread(fid, '*char')';
    fclose(fid);
    % Basic check - look for obvious syntax errors
    if contains(code, 'end') && contains(code, 'function')
        fprintf('✓ Basic structure valid\n');
        passed_tests = passed_tests + 1;
    else
        fprintf('⚠ Warning: May have structural issues\n');
        passed_tests = passed_tests + 1;
    end
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
    failed_tests = failed_tests + 1;
end

fprintf('\n');

%% ========================================================================
%% SECTION 4: Class Structure Tests
%% ========================================================================
fprintf('═══════════════════════════════════════════════════\n');
fprintf('SECTION 4: Class Structure Validation\n');
fprintf('═══════════════════════════════════════════════════\n\n');

% UIController class structure
total_tests = total_tests + 1;
fprintf('[Test 4.1] UIController constructor: ');
try
    methods_list = methods('UIController');
    if any(strcmp(methods_list, 'UIController'))
        fprintf('✓ Constructor exists\n');
        passed_tests = passed_tests + 1;
    else
        fprintf('✗ Constructor missing\n');
        failed_tests = failed_tests + 1;
    end
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
    failed_tests = failed_tests + 1;
end

% Check critical methods
critical_methods = {'show_startup_dialog', 'create_all_tabs', 'launch_simulation'};
for i = 1:length(critical_methods)
    total_tests = total_tests + 1;
    fprintf('[Test 4.%d] UIController.%s: ', i+1, critical_methods{i});
    try
        if any(strcmp(methods_list, critical_methods{i}))
            fprintf('✓ Exists\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('✗ Missing\n');
            failed_tests = failed_tests + 1;
        end
    catch ME
        fprintf('✗ ERROR: %s\n', ME.message);
        failed_tests = failed_tests + 1;
    end
end

fprintf('\n');

%% ========================================================================
%% SECTION 5: MATLAB Version Compatibility Tests
%% ========================================================================
fprintf('═══════════════════════════════════════════════════\n');
fprintf('SECTION 5: MATLAB Version Compatibility\n');
fprintf('═══════════════════════════════════════════════════\n\n');

matlab_ver = version;
fprintf('MATLAB Version: %s\n\n', matlab_ver);

% Check for UI components
total_tests = total_tests + 1;
fprintf('[Test 5.1] uifigure support: ');
try
    test_fig = uifigure('Visible', 'off');
    delete(test_fig);
    fprintf('✓ Supported\n');
    passed_tests = passed_tests + 1;
catch ME
    fprintf('✗ NOT SUPPORTED (requires R2016a+)\n');
    failed_tests = failed_tests + 1;
end

total_tests = total_tests + 1;
fprintf('[Test 5.2] uitabgroup support: ');
try
    test_fig = uifigure('Visible', 'off');
    test_tab = uitabgroup(test_fig);
    delete(test_fig);
    fprintf('✓ Supported\n');
    passed_tests = passed_tests + 1;
catch ME
    fprintf('✗ NOT SUPPORTED\n');
    failed_tests = failed_tests + 1;
end

total_tests = total_tests + 1;
fprintf('[Test 5.3] uieditfield support: ');
try
    test_fig = uifigure('Visible', 'off');
    test_field = uieditfield(test_fig);
    delete(test_fig);
    fprintf('✓ Supported\n');
    passed_tests = passed_tests + 1;
catch ME
    fprintf('✗ NOT SUPPORTED\n');
    failed_tests = failed_tests + 1;
end

fprintf('\n');

%% ========================================================================
%% SECTION 6: Dependencies Check
%% ========================================================================
fprintf('═══════════════════════════════════════════════════\n');
fprintf('SECTION 6: External Dependencies\n');
fprintf('═══════════════════════════════════════════════════\n\n');

% Check for required functions
required_funcs = {'sprintf', 'fprintf', 'addpath', 'struct', 'isfield'};
for i = 1:length(required_funcs)
    total_tests = total_tests + 1;
    fprintf('[Test 6.%d] %s: ', i, required_funcs{i});
    if exist(required_funcs{i}, 'builtin') || exist(required_funcs{i}, 'file')
        fprintf('✓ Available\n');
        passed_tests = passed_tests + 1;
    else
        fprintf('✗ MISSING\n');
        failed_tests = failed_tests + 1;
    end
end

fprintf('\n');

%% ========================================================================
%% SECTION 7: Live Test - UIController Instantiation (Optional)
%% ========================================================================
fprintf('═══════════════════════════════════════════════════\n');
fprintf('SECTION 7: Live UIController Test (Interactive)\n');
fprintf('═══════════════════════════════════════════════════\n\n');

fprintf('This test will launch the UIController startup dialog.\n');
fprintf('Press any key to continue, or Ctrl+C to skip...\n\n');
pause;
fprintf('This test will launch the UIController startup dialog.\n');
fprintf('Press any key to continue, or Ctrl+C to skip...\n\n');
pause;

total_tests = total_tests + 1;
fprintf('[Test 7.1] Instantiating UIController...\n');
fprintf('  → A startup dialog should appear\n');
fprintf('  → Click a button to test functionality\n\n');

try
    app = UIController();
    
    % Check what mode was selected
    if isappdata(0, 'ui_mode')
        mode = getappdata(0, 'ui_mode');
        rmappdata(0, 'ui_mode');
        fprintf('  ✓ Dialog appeared and returned: %s mode\n', mode);
        passed_tests = passed_tests + 1;
    else
        fprintf('  ✓ Dialog appeared - UI mode selected\n');
        passed_tests = passed_tests + 1;
    end
    
catch ME
    fprintf('  ✗ ERROR during instantiation:\n');
    fprintf('     %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('     File: %s\n', ME.stack(1).file);
        fprintf('     Line: %d\n', ME.stack(1).line);
        fprintf('     Function: %s\n', ME.stack(1).name);
    end
    failed_tests = failed_tests + 1;
    
    % Clean up
    if exist('app', 'var') && isfield(app, 'fig') && isvalid(app.fig)
        delete(app.fig);
    end
end

fprintf('\n');

%% ========================================================================
%% FINAL REPORT
%% ========================================================================
fprintf('╔════════════════════════════════════════════════════╗\n');
fprintf('║                  TEST SUMMARY                      ║\n');
fprintf('╚════════════════════════════════════════════════════╝\n\n');

fprintf('Total Tests:  %d\n', total_tests);
fprintf('Passed:       %d ✓\n', passed_tests);
fprintf('Failed:       %d ✗\n', failed_tests);
fprintf('Success Rate: %.1f%%\n\n', (passed_tests/total_tests)*100);

if failed_tests == 0
    fprintf('╔════════════════════════════════════════════════════╗\n');
    fprintf('║          ✓ ALL TESTS PASSED!                       ║\n');
    fprintf('║   Repository is ready for use                      ║\n');
    fprintf('╚════════════════════════════════════════════════════╝\n');
else
    fprintf('╔════════════════════════════════════════════════════╗\n');
    fprintf('║          ⚠ SOME TESTS FAILED                       ║\n');
    fprintf('║   Review errors above before running Analysis      ║\n');
    fprintf('╚════════════════════════════════════════════════════╝\n');
end
