function [passed, details] = test_ui_terminal_parameter_summary()
% test_ui_terminal_parameter_summary - Ensure launch logs parameters first.

    passed = false;
    details = '';
    app = [];

    try
        ensure_ui_test_paths();
        app = UIController('StartupMode', 'ui');

        % Keep the launch short by forcing a validation failure after summary logging.
        app.handles.Nx.Value = 4;
        app.handles.Ny.Value = 4;
        app.handles.dt.Value = 0.001;
        app.handles.t_final.Value = 0.1;

        app.launch_simulation();

        logs = string(app.terminal_log);
        idx_summary = find(contains(logs, '=== Selected Run Parameters ==='), 1, 'first');
        idx_start = find(contains(logs, 'Starting '), 1, 'first');
        idx_fail = find(contains(logs, 'Launch failed:'), 1, 'first');

        assert(~isempty(idx_summary), 'Parameter summary header was not logged.');
        assert(~isempty(idx_fail), 'Expected launch failure line was not logged.');
        assert(any(contains(logs, 'Method:', 'IgnoreCase', true)), 'Method line missing from summary.');
        assert(any(contains(logs, 'Grid:', 'IgnoreCase', true)), 'Grid line missing from summary.');
        assert(any(contains(logs, 'Time:', 'IgnoreCase', true)), 'Time line missing from summary.');

        if ~isempty(idx_start)
            assert(idx_summary < idx_start, 'Parameter summary must precede the start line.');
        end
        assert(idx_summary < idx_fail, 'Parameter summary must appear before failure/result lines.');

        passed = true;
        details = 'Terminal launch parameter summary passed.';
    catch ME
        details = sprintf('%s (%s)', ME.message, ME.identifier);
    end

    try
        if ~isempty(app) && isvalid(app)
            app.cleanup();
            delete(app);
        end
    catch
    end
end
