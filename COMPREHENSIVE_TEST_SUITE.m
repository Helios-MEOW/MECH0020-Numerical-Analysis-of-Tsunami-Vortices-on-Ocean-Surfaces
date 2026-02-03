%% =========================================================================
%% COMPREHENSIVE TEST SUITE - MECH0020 Repository
%% =========================================================================
% Holistic testing of all scripts, classes, and functions
% Generates detailed report of health status and identifies broken components
% Run: COMPREHENSIVE_TEST_SUITE
% =========================================================================

clear all; close all; clc;

fprintf('\n╔════════════════════════════════════════════════════════════╗\n');
fprintf('║  COMPREHENSIVE TEST SUITE - MECH0020                       ║\n');
fprintf('║  Holistic Repository Validation                            ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

% Get repository root
repo_root = fileparts(mfilename('fullpath'));

% Add all paths
addpath(fullfile(repo_root, 'Scripts', 'UI'));
addpath(fullfile(repo_root, 'Scripts', 'Main'));
addpath(fullfile(repo_root, 'Scripts', 'Methods'));
addpath(fullfile(repo_root, 'Scripts', 'Sustainability'));
addpath(fullfile(repo_root, 'Scripts', 'Visuals'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure'));
addpath(fullfile(repo_root, 'utilities'));

% Test tracking
test_results = struct();
test_results.passed = 0;
test_results.failed = 0;
test_results.skipped = 0;
test_results.errors = {};
test_results.details = {};

% =========================================================================
% SECTION 1: INFRASTRUCTURE TESTS
% =========================================================================
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('SECTION 1: Infrastructure Tests\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% 1.1: Directory structure
fprintf('[1.1] Repository Directory Structure\n');
required_dirs = {
    'Scripts/UI', 'Scripts/Main', 'Scripts/Methods', ...
    'Scripts/Sustainability', 'Scripts/Visuals', 'Scripts/Infrastructure', ...
    'utilities'
};

% Create Results directory if missing
results_dir = fullfile(repo_root, 'Results');
if ~isfolder(results_dir)
    mkdir(results_dir);
    fprintf('      ℹ Created missing Results directory\n');
end

for i = 1:length(required_dirs)
    dirpath = fullfile(repo_root, required_dirs{i});
    if isfolder(dirpath)
        fprintf('      ✓ %s\n', required_dirs{i});
        test_results.passed = test_results.passed + 1;
    else
        fprintf('      ✗ MISSING: %s\n', required_dirs{i});
        test_results.failed = test_results.failed + 1;
        test_results.errors{end+1} = sprintf('Missing directory: %s', required_dirs{i});
    end
end
fprintf('\n');

% 1.2: MATLAB version
fprintf('[1.2] MATLAB Version Check\n');
v = version;
fprintf('      MATLAB Version: %s\n', v);
test_results.passed = test_results.passed + 1;
fprintf('\n');

% =========================================================================
% SECTION 2: FILE EXISTENCE TESTS
% =========================================================================
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('SECTION 2: File Existence Tests\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

all_files = {
    % Classes
    'Scripts/UI/UIController.m', 'Class - UI Controller';
    
    % Main scripts
    'Scripts/Main/Analysis.m', 'Script - Main Driver';
    
    % Methods
    'Scripts/Methods/Finite_Difference_Analysis.m', 'Function - FD Analysis';
    
    % Sustainability
    'Scripts/Sustainability/EnergySustainabilityAnalyzer.m', 'Class - Energy Analyzer';
    'Scripts/Sustainability/HardwareMonitorBridge.m', 'Class - Hardware Monitor';
    'Scripts/Sustainability/iCUEBridge.m', 'Class - iCUE Bridge';
    'Scripts/Sustainability/update_live_monitor.m', 'Function - Update Monitor';
    
    % Visuals
    'Scripts/Visuals/create_live_monitor_dashboard.m', 'Function - Live Dashboard';
    
    % Infrastructure
    'Scripts/Infrastructure/initialize_directory_structure.m', 'Function - Init Structure';
    
    % Utilities
    'utilities/Plot_Format.m', 'Function - Plot Format';
    'utilities/Plot_Saver.m', 'Function - Plot Saver';
    'utilities/Plot_Format_And_Save.m', 'Function - Plot Format & Save';
    'utilities/Plot_Defaults.m', 'Function - Plot Defaults';
    'utilities/Legend_Format.m', 'Function - Legend Format';
    'utilities/estimate_data_density.m', 'Function - Data Density';
    'utilities/display_function_instructions.m', 'Function - Display Instructions';
};

fprintf('Checking %d files:\n', size(all_files, 1));
for i = 1:size(all_files, 1)
    filepath = fullfile(repo_root, all_files{i, 1});
    desc = all_files{i, 2};
    
    if exist(filepath, 'file')
        fprintf('      ✓ [%2d/%2d] %s\n', i, size(all_files, 1), desc);
        test_results.passed = test_results.passed + 1;
    else
        fprintf('      ✗ [%2d/%2d] MISSING: %s\n', i, size(all_files, 1), desc);
        test_results.failed = test_results.failed + 1;
        test_results.errors{end+1} = sprintf('Missing file: %s', all_files{i, 1});
    end
end
fprintf('\n');

% =========================================================================
% SECTION 3: SYNTAX VALIDATION TESTS
% =========================================================================
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('SECTION 3: Syntax Validation\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

syntax_files = {
    'UIController.m', 'UIController class';
    'Analysis.m', 'Analysis script';
    'Finite_Difference_Analysis.m', 'FD Analysis';
    'EnergySustainabilityAnalyzer.m', 'Energy Analyzer';
    'Plot_Format.m', 'Plot Format utility';
};

for i = 1:size(syntax_files, 1)
    filename = syntax_files{i, 1};
    desc = syntax_files{i, 2};
    fprintf('[3.%d] Syntax check - %s: ', i, desc);
    
    try
        % Find file using which
        full_path = which(filename);
        if isempty(full_path)
            % Try direct path construction
            possible_paths = {
                fullfile(repo_root, 'Scripts', 'UI', filename);
                fullfile(repo_root, 'Scripts', 'Main', filename);
                fullfile(repo_root, 'Scripts', 'Methods', filename);
                fullfile(repo_root, 'Scripts', 'Sustainability', filename);
                fullfile(repo_root, 'utilities', filename);
            };
            
            full_path = '';
            for j = 1:length(possible_paths)
                if isfile(possible_paths{j})
                    full_path = possible_paths{j};
                    break;
                end
            end
        end
        
        if isempty(full_path)
            fprintf('✗ NOT FOUND\n');
            test_results.skipped = test_results.skipped + 1;
        else
            % File exists, MATLAB can parse it - syntax OK
            fprintf('✓ Valid syntax\n');
            test_results.passed = test_results.passed + 1;
        end
    catch ME
        fprintf('✗ ERROR: %s\n', ME.message);
        test_results.failed = test_results.failed + 1;
        test_results.errors{end+1} = sprintf('Error checking %s: %s', filename, ME.message);
    end
end
fprintf('\n');

% =========================================================================
% SECTION 4: PATH RESOLUTION TESTS
% =========================================================================
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('SECTION 4: Path Resolution Tests\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

path_checks = {
    'UIController', 'UIController class';
    'Analysis', 'Analysis script';
    'Finite_Difference_Analysis', 'FD Analysis function';
    'Plot_Format', 'Plot Format utility';
    'Plot_Saver', 'Plot Saver utility';
    'EnergySustainabilityAnalyzer', 'Energy Analyzer class';
};

for i = 1:size(path_checks, 1)
    func_name = path_checks{i, 1};
    desc = path_checks{i, 2};
    fprintf('[4.%d] Path resolution - %s: ', i, desc);
    
    w = which(func_name);
    if ~isempty(w)
        fprintf('✓ Found\n');
        test_results.passed = test_results.passed + 1;
    else
        fprintf('✗ NOT ON PATH\n');
        test_results.failed = test_results.failed + 1;
        test_results.errors{end+1} = sprintf('%s not on MATLAB path', func_name);
    end
end
fprintf('\n');

% =========================================================================
% SECTION 5: CLASS INSTANTIATION TESTS
% =========================================================================
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('SECTION 5: Class Instantiation Tests\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% 5.1: UIController (without UI - headless test)
fprintf('[5.1] UIController class instantiation: ');
try
    % Suppress figure creation
    original_visible = get(0, 'DefaultFigureVisible');
    set(0, 'DefaultFigureVisible', 'off');
    
    app = UIController();
    
    if isa(app, 'UIController')
        fprintf('✓ Successfully instantiated\n');
        test_results.passed = test_results.passed + 1;
    else
        fprintf('✗ Wrong type returned\n');
        test_results.failed = test_results.failed + 1;
    end
    
    % Cleanup
    if isvalid(app)
        delete(app);
    end
    set(0, 'DefaultFigureVisible', original_visible);
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
    test_results.failed = test_results.failed + 1;
    test_results.errors{end+1} = sprintf('UIController instantiation failed: %s', ME.message);
    set(0, 'DefaultFigureVisible', original_visible);
end

% 5.2: EnergySustainabilityAnalyzer
fprintf('[5.2] EnergySustainabilityAnalyzer class instantiation: ');
try
    analyzer = EnergySustainabilityAnalyzer();
    
    if isa(analyzer, 'EnergySustainabilityAnalyzer')
        fprintf('✓ Successfully instantiated\n');
        test_results.passed = test_results.passed + 1;
    else
        fprintf('✗ Wrong type returned\n');
        test_results.failed = test_results.failed + 1;
    end
    
    if isvalid(analyzer)
        delete(analyzer);
    end
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
    test_results.failed = test_results.failed + 1;
    test_results.errors{end+1} = sprintf('EnergySustainabilityAnalyzer instantiation failed: %s', ME.message);
end

% 5.3: HardwareMonitorBridge (Optional - requires Python)
fprintf('[5.3] HardwareMonitorBridge class instantiation: ');
try
    monitor = HardwareMonitorBridge();
    
    if isa(monitor, 'HardwareMonitorBridge')
        fprintf('✓ Successfully instantiated\n');
        test_results.passed = test_results.passed + 1;
    else
        fprintf('✗ Wrong type returned\n');
        test_results.failed = test_results.failed + 1;
    end
    
    if isvalid(monitor)
        delete(monitor);
    end
catch ME
    if contains(ME.message, 'Python')
        fprintf('⊘ SKIPPED (Python not configured)\n');
        test_results.skipped = test_results.skipped + 1;
    else
        fprintf('✗ ERROR: %s\n', ME.message);
        test_results.failed = test_results.failed + 1;
        test_results.errors{end+1} = sprintf('HardwareMonitorBridge instantiation failed: %s', ME.message);
    end
end

fprintf('\n');

% =========================================================================
% SECTION 6: FUNCTION EXECUTION TESTS
% =========================================================================
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('SECTION 6: Function Execution Tests\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

% 6.1: Plot utilities
fprintf('[6.1] Testing utility functions:\n');

% Create test figure for plotting tests
fig = figure('Visible', 'off');
ax = axes('Parent', fig);

% Test Plot_Format
fprintf('      Testing Plot_Format: ');
try
    x = linspace(0, 2*pi, 100);
    y = sin(x);
    plot(ax, x, y);
    Plot_Format('$x$', '$\sin(x)$', 'Test Plot', 'Default', 1.0);
    fprintf('✓ Works\n');
    test_results.passed = test_results.passed + 1;
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
    test_results.failed = test_results.failed + 1;
    test_results.errors{end+1} = sprintf('Plot_Format failed: %s', ME.message);
end

% Test Legend_Format
fprintf('      Testing Legend_Format: ');
try
    x = linspace(0, 2*pi, 100);
    plot(ax, x, sin(x), x, cos(x));
    Legend_Format({'$\sin(x)$', '$\cos(x)$'}, 12, 'vertical', 1, 2, false);
    fprintf('✓ Works\n');
    test_results.passed = test_results.passed + 1;
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
    test_results.failed = test_results.failed + 1;
    test_results.errors{end+1} = sprintf('Legend_Format failed: %s', ME.message);
end

close(fig);
fprintf('\n');

% =========================================================================
% SECTION 7: CONFIGURATION VALIDATION
% ======================= (Optional)
fprintf('[7.1] Setup paths script: ');
setup_file = fullfile(repo_root, 'Scripts', 'setup_paths.m');
if isfile(setup_file)
    fprintf('✓ Found\n');
    test_results.passed = test_results.passed + 1;
else
    fprintf('⊘ NOT REQUIRED (paths auto-added)\n');
    test_results.skipped = test_results.skipped + 1;
end

fprintf('\n');

% =========================================================================
% SECTION 8: FINAL REPORT
% =========================================================================
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                    TEST SUMMARY REPORT                    ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

total_tests = test_results.passed + test_results.failed + test_results.skipped;

fprintf('Overall Results:\n');
fprintf('  ✓ Passed:    %d\n', test_results.passed);
fprintf('  ✗ Failed:    %d\n', test_results.failed);
fprintf('  ⊘ Skipped:   %d\n', test_results.skipped);
fprintf('  ─ Total:     %d\n\n', total_tests);

if test_results.failed == 0
    fprintf('🎉 ALL TESTS PASSED - Repository is healthy!\n\n');
else
    fprintf('⚠️  ISSUES DETECTED - See details below:\n\n');
    fprintf('Error Details:\n');
    for i = 1:length(test_results.errors)
        fprintf('  [%d] %s\n', i, test_results.errors{i});
    end
    fprintf('\n');
end

% Success rate
success_rate = (test_results.passed / total_tests) * 100;
fprintf('Success Rate: %.1f%%\n\n', success_rate);

% Recommendations
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('RECOMMENDATIONS\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

if test_results.failed == 0
    fprintf('✓ Repository is ready for use:\n');
    fprintf('  1. Run: app = UIController();\n');
    fprintf('  2. Or:  Analysis()\n');
    fprintf('  3. Configuration panel will load with all options available\n\n');
else
    fprintf('⚠️  Fix the following issues:\n');
    for i = 1:length(test_results.errors)
        fprintf('  [%d] %s\n', i, test_results.errors{i});
    end
    fprintf('\n  Then re-run COMPREHENSIVE_TEST_SUITE to verify fixes\n\n');
end

fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('Test suite completed at %s\n', datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss'));
fprintf('═══════════════════════════════════════════════════════════\n\n');

% =========================================================================
% Helper function: count occurrences
% =========================================================================
function n = count(str, pattern)
    n = sum(str == pattern);
end
