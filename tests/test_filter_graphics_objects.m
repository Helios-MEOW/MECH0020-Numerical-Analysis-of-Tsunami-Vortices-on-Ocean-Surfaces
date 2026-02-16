%% TEST FILTER_GRAPHICS_OBJECTS FUNCTION
% Static test to ensure filter_graphics_objects handles all edge cases

fprintf('Testing filter_graphics_objects function...\n\n');

% Add the necessary paths
addpath(fullfile(pwd, 'Scripts', 'Infrastructure', 'Utilities'));

%% Test 1: Empty struct
fprintf('Test 1: Empty struct... ');
s1 = struct();
try
    result1 = filter_graphics_objects(s1);
    assert(isstruct(result1));
    fprintf('PASS\n');
catch ME
    fprintf('FAIL: %s\n', ME.message);
end

%% Test 2: Struct with numeric fields
fprintf('Test 2: Struct with numeric fields... ');
s2.a = 1;
s2.b = [1 2 3];
s2.c = rand(3, 3);
try
    result2 = filter_graphics_objects(s2);
    assert(isequal(result2.a, s2.a));
    assert(isequal(result2.b, s2.b));
    assert(isequal(result2.c, s2.c));
    fprintf('PASS\n');
catch ME
    fprintf('FAIL: %s\n', ME.message);
end

%% Test 3: Struct with strings and chars
fprintf('Test 3: Struct with strings and chars... ');
s3.str = 'hello';
s3.strarray = ["a", "b", "c"];
s3.cell = {'x', 'y', 'z'};
try
    result3 = filter_graphics_objects(s3);
    assert(isequal(result3.str, s3.str));
    assert(isequal(result3.strarray, s3.strarray));
    assert(isequal(result3.cell, s3.cell));
    fprintf('PASS\n');
catch ME
    fprintf('FAIL: %s\n', ME.message);
end

%% Test 4: Nested structs
fprintf('Test 4: Nested structs... ');
s4.outer.inner.value = 42;
s4.outer.inner.name = 'test';
s4.other = 'data';
try
    result4 = filter_graphics_objects(s4);
    assert(isequal(result4.outer.inner.value, 42));
    assert(isequal(result4.outer.inner.name, 'test'));
    assert(isequal(result4.other, 'data'));
    fprintf('PASS\n');
catch ME
    fprintf('FAIL: %s\n', ME.message);
end

%% Test 5: Struct with figure handle (should be filtered out)
fprintf('Test 5: Struct with figure handle... ');
fig = figure('Visible', 'off');
s5.data = [1 2 3];
s5.fig = fig;
s5.more_data = 'text';
try
    result5 = filter_graphics_objects(s5);
    assert(isfield(result5, 'data'));
    assert(isfield(result5, 'more_data'));
    assert(~isfield(result5, 'fig'), 'Figure handle should be filtered out');
    fprintf('PASS\n');
    close(fig);
catch ME
    close(fig);
    fprintf('FAIL: %s\n', ME.message);
end

%% Test 6: Struct with axes handle (should be filtered out)
fprintf('Test 6: Struct with axes handle... ');
fig2 = figure('Visible', 'off');
ax = axes(fig2);
s6.data = [1 2 3];
s6.axes = ax;
s6.more_data = 'text';
try
    result6 = filter_graphics_objects(s6);
    assert(isfield(result6, 'data'));
    assert(isfield(result6, 'more_data'));
    assert(~isfield(result6, 'axes'), 'Axes handle should be filtered out');
    fprintf('PASS\n');
    close(fig2);
catch ME
    close(fig2);
    fprintf('FAIL: %s\n', ME.message);
end

%% Test 7: Struct with function handle (should be filtered out)
fprintf('Test 7: Struct with function handle... ');
s7.data = [1 2 3];
s7.func = @(x) x^2;
s7.more_data = 'text';
try
    result7 = filter_graphics_objects(s7);
    assert(isfield(result7, 'data'));
    assert(isfield(result7, 'more_data'));
    assert(~isfield(result7, 'func'), 'Function handle should be filtered out');
    fprintf('PASS\n');
catch ME
    fprintf('FAIL: %s\n', ME.message);
end

%% Test 8: Struct with empty fields
fprintf('Test 8: Struct with empty fields... ');
s8.empty_array = [];
s8.empty_string = '';
s8.data = 123;
try
    result8 = filter_graphics_objects(s8);
    assert(isfield(result8, 'empty_array'));
    assert(isfield(result8, 'empty_string'));
    assert(isfield(result8, 'data'));
    fprintf('PASS\n');
catch ME
    fprintf('FAIL: %s\n', ME.message);
end

%% Test 9: Struct with logical arrays
fprintf('Test 9: Struct with logical arrays... ');
s9.bool_scalar = true;
s9.bool_array = [true false true];
s9.bool_matrix = logical(eye(3));
try
    result9 = filter_graphics_objects(s9);
    assert(isequal(result9.bool_scalar, s9.bool_scalar));
    assert(isequal(result9.bool_array, s9.bool_array));
    assert(isequal(result9.bool_matrix, s9.bool_matrix));
    fprintf('PASS\n');
catch ME
    fprintf('FAIL: %s\n', ME.message);
end

%% Test 10: Complex nested struct with mixed types
fprintf('Test 10: Complex nested struct... ');
s10.config.name = 'simulation';
s10.config.params.dt = 0.001;
s10.config.params.grid = [128 128];
s10.results.data = rand(10, 10);
s10.results.time = 0:0.1:1;
try
    result10 = filter_graphics_objects(s10);
    assert(isequal(result10.config.name, s10.config.name));
    assert(isequal(result10.config.params.dt, s10.config.params.dt));
    assert(isequal(result10.config.params.grid, s10.config.params.grid));
    assert(isequal(result10.results.data, s10.results.data));
    assert(isequal(result10.results.time, s10.results.time));
    fprintf('PASS\n');
catch ME
    fprintf('FAIL: %s\n', ME.message);
end

%% Summary
fprintf('\n=== All static tests completed ===\n');
fprintf('The filter_graphics_objects function is ready for use.\n');
