function [passed, details] = test_ui_terminal_reset_on_launch()
% test_ui_terminal_reset_on_launch - Ensure stale terminal entries are cleared at launch.

    passed = false;
    details = '';
    app = [];

    try
        ensure_ui_test_paths();
        app = UIController('StartupMode', 'ui');

        stale_token = 'STALE_TERMINAL_ENTRY_SHOULD_BE_REMOVED';
        app.append_to_terminal(stale_token, 'debug');
        assert(any(contains(string(app.terminal_log), stale_token)), ...
            'Failed to seed stale terminal entry.');

        % Force a fast validation failure so launch exits quickly but still exercises reset.
        app.handles.Nx.Value = 4;
        app.handles.Ny.Value = 4;
        app.launch_simulation();

        logs = string(app.terminal_log);
        assert(~any(contains(logs, stale_token)), ...
            'Terminal retained stale entries across launch.');
        assert(any(contains(logs, 'Launch failed:')), ...
            'Expected launch failure message was not logged.');

        passed = true;
        details = 'Terminal reset on launch passed.';
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
