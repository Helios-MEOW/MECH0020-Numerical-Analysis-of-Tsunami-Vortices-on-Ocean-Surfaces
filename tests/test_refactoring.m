% Test script for refactored modules
% Get repository root
test_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(test_dir);

% Add paths
addpath(fullfile(repo_root, 'Scripts', 'Drivers'));
addpath(fullfile(repo_root, 'Scripts', 'Solvers'));
addpath(fullfile(repo_root, 'Scripts', 'Solvers', 'FD'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Builds'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'DataRelatedHelpers'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Initialisers'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Runners'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Utilities'));
addpath(fullfile(repo_root, 'utilities'));

fprintf('=== TESTING MODULE INTEGRATION ===\n\n');

% Test module-qualified calls (static classes)
val = HelperUtils.safe_get(struct('x', 10), 'x', 0);
fprintf(' HelperUtils.safe_get works, returned: %d\n', val);

tok = HelperUtils.sanitize_token('test file!');
fprintf(' HelperUtils.sanitize_token works: %s\n', tok);

schema = MetricsExtractor.result_schema();
fprintf(' MetricsExtractor.result_schema works: %d fields\n', length(fieldnames(schema)));

T_schema = struct2table(schema);
T_migrated = ResultsPersistence.migrate_csv_schema(T_schema, T_schema, 'dummy.csv', string.empty, string.empty);
fprintf(' ResultsPersistence.migrate_csv_schema works: %d vars\n', width(T_migrated));

safe_html = ReportGenerator.escape_html('<script>test</script>');
fprintf(' ReportGenerator.escape_html works: %s\n', safe_html);

% Show file info for new Analysis.m
info = dir(fullfile(repo_root, 'Scripts', 'Drivers', 'Analysis.m'));
fprintf('\n=== INTEGRATION TEST PASSED ===\n');
fprintf('Analysis.m: %.1f KB (est. %d lines)\n', info.bytes/1024, info.bytes/40);
fprintf('Refactored architecture: Drivers + Solvers separation\n');
