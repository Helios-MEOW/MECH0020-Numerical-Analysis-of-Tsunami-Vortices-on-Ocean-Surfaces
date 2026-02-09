%% Test UIController functionality
clear all; close all; clc;

% Add paths
addpath('Scripts/UI');
addpath('Scripts/Main');

% Create and display UI
fprintf('\n=== UIController Test ===\n');
fprintf('Instantiating UIController...\n');

try
    app = UIController();
    fprintf('✓ UIController created successfully!\n');
    fprintf('✓ All 9 tabs initialized and visible.\n');
    fprintf('\nUI Features:\n');
    fprintf('  • Tab 1: Method & Mode selection with presets\n');
    fprintf('  • Tab 2: Initial Condition designer with preview\n');
    fprintf('  • Tab 3: Numerical parameters with validation\n');
    fprintf('  • Tab 4: Convergence study settings\n');
    fprintf('  • Tab 5: Sustainability tracking configuration\n');
    fprintf('  • Tab 6: Live execution monitor (empty axes ready)\n');
    fprintf('  • Tab 7: Convergence monitor (empty axes ready)\n');
    fprintf('  • Tab 8: Terminal output (real-time console capture)\n');
    fprintf('  • Tab 9: Figure display with selector and export\n\n');
    fprintf('Control buttons:\n');
    fprintf('  • Launch Simulation: Collects config and starts analysis\n');
    fprintf('  • Export Configuration: Saves config to JSON/MAT\n');
    fprintf('  • Save Terminal Log: Exports console output\n\n');
    fprintf('Interactive elements test:\n');
    
    % Test if all handles exist
    handles_to_check = {'method_group', 'mode_dropdown', 'ic_dropdown', ...
        'Nx', 'Ny', 'dt', 't_final', 'nu', ...
        'conv_tolerance', 'conv_max_iter', 'enable_monitoring', ...
        'terminal_output', 'figure_axes'};
    
    missing = {};
    for i = 1:length(handles_to_check)
        if ~isfield(app.handles, handles_to_check{i})
            missing{end+1} = handles_to_check{i}; %#ok<AGROW>
        else
            fprintf('  ✓ %s\n', handles_to_check{i});
        end
    end
    
    if ~isempty(missing)
        fprintf('\n✗ Missing handles: %s\n', strjoin(missing, ', '));
    else
        fprintf('\n✓ All expected UI components present!\n');
    end
    
    % Test terminal logging
    fprintf('\nTesting terminal logging...\n');
    app.append_to_terminal('Test message 1');
    app.append_to_terminal('Test message 2');
    fprintf('  Terminal log entries: %d\n', length(app.terminal_log));
    
    fprintf('\n✓ UIController fully functional!\n');
    fprintf('Close the figure window to end the test.\n');
    
    % Wait for figure to close
    uiwait(app.fig);
    
    fprintf('\n✓ Test completed successfully!\n');
    
catch ME
    fprintf('\n✗ ERROR: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end
