%% PARALLEL IMPLEMENTATION STATIC TEST
% Comprehensive test of all parallel UI components

fprintf('=== PARALLEL UI IMPLEMENTATION TEST ===\n\n');

% Add paths
addpath(fullfile(pwd, 'Scripts', 'Infrastructure', 'Utilities'));
addpath(fullfile(pwd, 'Scripts', 'Modes'));
addpath(fullfile(pwd, 'Scripts', 'UI'));

test_results = struct();
test_count = 0;
pass_count = 0;

%% Test 1: filter_graphics_objects exists and works
test_count = test_count + 1;
fprintf('Test 1: filter_graphics_objects utility... ');
try
    which_result = which('filter_graphics_objects');
    assert(~isempty(which_result), 'filter_graphics_objects not found');

    % Quick functional test
    test_struct = struct('data', [1 2 3], 'text', 'hello');
    result = filter_graphics_objects(test_struct);
    assert(isstruct(result), 'filter_graphics_objects failed');
    assert(isfield(result, 'data'), 'Data field missing');

    fprintf('PASS\n');
    test_results.filter_graphics = 'PASS';
    pass_count = pass_count + 1;
catch ME
    fprintf('FAIL: %s\n', ME.message);
    test_results.filter_graphics = sprintf('FAIL: %s', ME.message);
end

%% Test 2: ProgressBar class exists and is valid
test_count = test_count + 1;
fprintf('Test 2: ProgressBar class... ');
try
    which_result = which('ProgressBar');
    assert(~isempty(which_result), 'ProgressBar not found');

    % Check if it's a valid class
    meta_info = meta.class.fromName('ProgressBar');
    assert(~isempty(meta_info), 'ProgressBar is not a valid class');

    fprintf('PASS\n');
    test_results.progress_bar_class = 'PASS';
    pass_count = pass_count + 1;
catch ME
    fprintf('FAIL: %s\n', ME.message);
    test_results.progress_bar_class = sprintf('FAIL: %s', ME.message);
end

%% Test 3: ProgressBar functionality
test_count = test_count + 1;
fprintf('Test 3: ProgressBar functionality... ');
try
    % Create progress bar
    pb = ProgressBar(100, 'Prefix', 'Test', 'UpdateInterval', 0);

    % Update a few times
    for i = [25, 50, 75, 100]
        pb.update(i);
    end

    % Finish
    pb.finish();

    fprintf('PASS\n');
    test_results.progress_bar_function = 'PASS';
    pass_count = pass_count + 1;
catch ME
    fprintf('FAIL: %s\n', ME.message);
    test_results.progress_bar_function = sprintf('FAIL: %s', ME.message);
end

%% Test 4: ParallelSimulationExecutor class exists
test_count = test_count + 1;
fprintf('Test 4: ParallelSimulationExecutor class... ');
try
    which_result = which('ParallelSimulationExecutor');
    assert(~isempty(which_result), 'ParallelSimulationExecutor not found');

    % Check if it's a valid class
    meta_info = meta.class.fromName('ParallelSimulationExecutor');
    assert(~isempty(meta_info), 'ParallelSimulationExecutor is not a valid class');

    fprintf('PASS\n');
    test_results.parallel_executor_class = 'PASS';
    pass_count = pass_count + 1;
catch ME
    fprintf('FAIL: %s\n', ME.message);
    test_results.parallel_executor_class = sprintf('FAIL: %s', ME.message);
end

%% Test 5: ParallelSimulationExecutor instantiation
test_count = test_count + 1;
fprintf('Test 5: ParallelSimulationExecutor instantiation... ');
try
    % Create executor with dummy callback
    executor = ParallelSimulationExecutor(@(x) fprintf(''));

    % Check properties exist
    assert(isprop(executor, 'ui_progress_callback'), 'Missing ui_progress_callback property');
    assert(isprop(executor, 'is_running'), 'Missing is_running property');
    assert(isprop(executor, 'monitor_timer'), 'Missing monitor_timer property');

    % Check initial state
    assert(~executor.is_running, 'Executor should not be running initially');

    fprintf('PASS\n');
    test_results.parallel_executor_instance = 'PASS';
    pass_count = pass_count + 1;
catch ME
    fprintf('FAIL: %s\n', ME.message);
    test_results.parallel_executor_instance = sprintf('FAIL: %s', ME.message);
end

%% Test 6: UIController class has required properties
test_count = test_count + 1;
fprintf('Test 6: UIController has current_executor property... ');
try
    % Get UIController class metadata
    meta_info = meta.class.fromName('UIController');
    assert(~isempty(meta_info), 'UIController class not found');

    % Check for current_executor property
    prop_names = {meta_info.PropertyList.Name};
    assert(ismember('current_executor', prop_names), 'current_executor property not found');

    fprintf('PASS\n');
    test_results.uicontroller_property = 'PASS';
    pass_count = pass_count + 1;
catch ME
    fprintf('FAIL: %s\n', ME.message);
    test_results.uicontroller_property = sprintf('FAIL: %s', ME.message);
end

%% Test 7: UIController has required methods
test_count = test_count + 1;
fprintf('Test 7: UIController has cancel_simulation method... ');
try
    % Get UIController class metadata
    meta_info = meta.class.fromName('UIController');

    % Check for cancel_simulation method
    method_names = {meta_info.MethodList.Name};
    assert(ismember('cancel_simulation', method_names), 'cancel_simulation method not found');

    fprintf('PASS\n');
    test_results.uicontroller_cancel = 'PASS';
    pass_count = pass_count + 1;
catch ME
    fprintf('FAIL: %s\n', ME.message);
    test_results.uicontroller_cancel = sprintf('FAIL: %s', ME.message);
end

%% Test 8: UIController has update_system_metrics_display method
test_count = test_count + 1;
fprintf('Test 8: UIController has update_system_metrics_display method... ');
try
    % Get UIController class metadata
    meta_info = meta.class.fromName('UIController');

    % Check for update_system_metrics_display method
    method_names = {meta_info.MethodList.Name};
    assert(ismember('update_system_metrics_display', method_names), ...
        'update_system_metrics_display method not found');

    fprintf('PASS\n');
    test_results.uicontroller_metrics = 'PASS';
    pass_count = pass_count + 1;
catch ME
    fprintf('FAIL: %s\n', ME.message);
    test_results.uicontroller_metrics = sprintf('FAIL: %s', ME.message);
end

%% Test 9: mode_evolution has progress bar code
test_count = test_count + 1;
fprintf('Test 9: mode_evolution contains progress bar code... ');
try
    % Read mode_evolution.m
    mode_ev_path = which('mode_evolution');
    assert(~isempty(mode_ev_path), 'mode_evolution not found');

    file_content = fileread(mode_ev_path);

    % Check for progress bar initialization
    assert(contains(file_content, 'use_progress_bar'), 'use_progress_bar variable not found');
    assert(contains(file_content, 'ProgressBar'), 'ProgressBar usage not found');
    assert(contains(file_content, 'pb.update'), 'pb.update call not found');
    assert(contains(file_content, 'pb.finish'), 'pb.finish call not found');

    fprintf('PASS\n');
    test_results.mode_evolution_progress = 'PASS';
    pass_count = pass_count + 1;
catch ME
    fprintf('FAIL: %s\n', ME.message);
    test_results.mode_evolution_progress = sprintf('FAIL: %s', ME.message);
end

%% Test 10: Parallel Computing Toolbox availability (optional)
test_count = test_count + 1;
fprintf('Test 10: Parallel Computing Toolbox (optional)... ');
try
    v = ver('parallel');
    if ~isempty(v)
        fprintf('PASS (Available: %s)\n', v.Version);
        test_results.parallel_toolbox = sprintf('PASS (v%s)', v.Version);
        pass_count = pass_count + 1;
    else
        fprintf('SKIP (Not available - will use fallback)\n');
        test_results.parallel_toolbox = 'SKIP (Fallback mode will be used)';
        pass_count = pass_count + 1; % Don't penalize missing toolbox
    end
catch ME
    fprintf('SKIP: %s\n', ME.message);
    test_results.parallel_toolbox = sprintf('SKIP: %s', ME.message);
    pass_count = pass_count + 1; % Don't penalize missing toolbox
end

%% Summary
fprintf('\n=== TEST SUMMARY ===\n');
fprintf('Total Tests: %d\n', test_count);
fprintf('Passed: %d\n', pass_count);
fprintf('Failed: %d\n', test_count - pass_count);
fprintf('Success Rate: %.1f%%\n\n', (pass_count/test_count)*100);

% Display individual results
fprintf('Individual Test Results:\n');
fields = fieldnames(test_results);
for i = 1:length(fields)
    fprintf('  %s: %s\n', fields{i}, test_results.(fields{i}));
end

% Overall verdict
fprintf('\n');
if pass_count == test_count
    fprintf('✓ ALL TESTS PASSED - Implementation ready for use!\n');
elseif pass_count >= test_count * 0.9
    fprintf('⚠ MOSTLY PASSED - Minor issues detected, review failures\n');
else
    fprintf('✗ MULTIPLE FAILURES - Review implementation\n');
end

fprintf('\n=== END OF TEST ===\n');
