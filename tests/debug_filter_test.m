%% DEBUG FILTER TEST
% Simple test to debug why figure handles aren't being filtered

addpath(fullfile(pwd, 'Scripts', 'Infrastructure', 'Utilities'));

fprintf('=== DEBUG FILTER TEST ===\n\n');

%% Test with figure handle
fprintf('Creating figure handle...\n');
fig = figure('Visible', 'off');

s.data = [1 2 3];
s.fig = fig;
s.name = 'test';

fprintf('Original struct fields:\n');
disp(fieldnames(s));

fprintf('\nChecking data field:\n');
fprintf('  isgraphics([1 2 3]) = ');
disp(isgraphics([1 2 3]));
fprintf('  any(isgraphics([1 2 3])) = %d\n', any(isgraphics([1 2 3])));

fprintf('\nChecking figure handle type:\n');
fprintf('  isgraphics(fig) = %d\n', isgraphics(fig));
fprintf('  isa(fig, ''matlab.ui.Figure'') = %d\n', isa(fig, 'matlab.ui.Figure'));
fprintf('  class(fig) = %s\n', class(fig));

fprintf('\nFiltering struct...\n');
result = filter_graphics_objects(s);

fprintf('\nResult struct fields:\n');
disp(fieldnames(result));

if isfield(result, 'fig')
    fprintf('\nERROR: Figure handle was NOT filtered out!\n');
    fprintf('  Type of result.fig: %s\n', class(result.fig));
else
    fprintf('\nSUCCESS: Figure handle was filtered out.\n');
end

close(fig);

fprintf('\n=== TEST COMPLETE ===\n');
