function [ok, msg] = test_ui_dialog_latex_symbols()
% test_ui_dialog_latex_symbols - Verify LaTeX math rendering helpers for UI labels/dialogs.

    ok = false;
    msg = '';
    app = [];

    try
        ensure_ui_test_paths();
        app = UIController('StartupMode', 'ui');

        required_labels = {'label_Nx', 'label_Ny', 'label_Lx', 'label_Ly', 'label_dt', 'label_Tfinal', 'label_nu'};
        for idx = 1:numel(required_labels)
            name = required_labels{idx};
            assert(isfield(app.handles, name) && isvalid(app.handles.(name)), ...
                'Missing expected math label handle: %s', name);
            assert(strcmpi(string(app.handles.(name).Interpreter), "latex"), ...
                'Expected LaTeX interpreter on %s.', name);
        end

        info = app.show_alert_latex('$\Delta t$ test', 'LaTeX Alert Dry Run', 'Emit', false, 'Icon', 'info');
        assert(isstruct(info) && isfield(info, 'interpreter') && strcmpi(string(info.interpreter), "latex"), ...
            'show_alert_latex must report latex interpreter in dry-run mode.');
        assert(contains(string(info.message), '\Delta t'), ...
            'show_alert_latex dry-run payload should preserve LaTeX token text.');

        choice = app.show_confirm_latex('$\nu$ check', 'LaTeX Confirm Dry Run', {'Yes', 'No'}, 'Yes', 'No', 'Emit', false);
        assert(strcmpi(string(choice), "Yes"), ...
            'show_confirm_latex dry-run should return the configured default choice.');

        ok = true;
        msg = 'LaTeX dialog/label checks passed.';
    catch ME
        msg = sprintf('%s (%s)', ME.message, ME.identifier);
    end

    try
        if ~isempty(app) && isvalid(app)
            app.cleanup();
            delete(app);
        end
    catch
    end
end
