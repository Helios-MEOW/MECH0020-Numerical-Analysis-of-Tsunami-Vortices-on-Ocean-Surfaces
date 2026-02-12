function repo_root = ensure_ui_test_paths()
% ensure_ui_test_paths - Prepend this repository's MATLAB paths for UI tests.

    this_dir = fileparts(mfilename('fullpath'));
    repo_root = fileparts(fileparts(this_dir));

    rel_paths = {
        fullfile('Scripts', 'UI')
        fullfile('Scripts', 'Drivers')
        fullfile('Scripts', 'Modes')
        fullfile('Scripts', 'Modes', 'Convergence')
        fullfile('Scripts', 'Solvers')
        fullfile('Scripts', 'Methods', 'FiniteDifference')
        fullfile('Scripts', 'Methods', 'FiniteVolume')
        fullfile('Scripts', 'Methods', 'Spectral')
        fullfile('Scripts', 'Infrastructure', 'Builds')
        fullfile('Scripts', 'Infrastructure', 'DataRelatedHelpers')
        fullfile('Scripts', 'Infrastructure', 'Initialisers')
        fullfile('Scripts', 'Infrastructure', 'Runners')
        fullfile('Scripts', 'Infrastructure', 'Utilities')
        fullfile('Scripts', 'Plotting')
        fullfile('Scripts', 'Sustainability')
        'utilities'
        'tests'
        fullfile('tests', 'ui')
    };

    for i = 1:numel(rel_paths)
        p = fullfile(repo_root, rel_paths{i});
        if isfolder(p)
            addpath(p, '-begin');
        end
    end
    rehash path;

    expected = fullfile(repo_root, 'Scripts', 'UI', 'UIController.m');
    resolved = which('UIController');

    if isempty(resolved)
        error('ensure_ui_test_paths:UIControllerMissing', ...
            'UIController could not be resolved after path setup.');
    end

    expected_norm = lower(strrep(expected, '/', filesep));
    resolved_norm = lower(strrep(resolved, '/', filesep));
    if ~strcmp(expected_norm, resolved_norm)
        error('ensure_ui_test_paths:UnexpectedUIControllerPath', ...
            'Resolved UIController from unexpected path: %s (expected: %s).', ...
            resolved, expected);
    end
end
