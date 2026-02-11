function [passed, details] = test_ui_warning_regressions()
% test_ui_warning_regressions - Regressions for previously observed UI warnings/errors.

    passed = false;
    details = '';
    app = [];
    known_warn = '';

    try
        app = UIController('StartupMode', 'ui');

        % 1) IC preview should not emit constant-Z contour warnings.
        items = app.handles.ic_dropdown.Items;
        lastwarn('');
        for k = 1:numel(items)
            app.handles.ic_dropdown.Value = items{k};
            app.on_ic_changed();
            drawnow;
        end
        [msg, ~] = lastwarn;
        known_warn = char(string(msg));
        assert(isempty(strfind(lower(known_warn), 'contour not rendered for constant zdata')), ...
            'IC preview emitted constant-Z contour warning.');

        % 2) Mode changes should not throw callback exceptions.
        modes = {'Evolution', 'Convergence', 'Sweep', 'Animation', 'Experimentation'};
        for k = 1:numel(modes)
            app.handles.mode_dropdown.Value = modes{k};
            app.on_mode_changed();
            drawnow;
        end

        % 3) Minimal run should not emit decomposition save warning.
        app.handles.method_dropdown.Value = 'Finite Difference';
        app.handles.mode_dropdown.Value = 'Evolution';
        app.on_method_changed();
        app.on_mode_changed();

        app.handles.Nx.Value = 32;
        app.handles.Ny.Value = 32;
        app.handles.dt.Value = 0.01;
        app.handles.t_final.Value = 0.05;
        app.handles.num_snapshots.Value = 3;

        app.handles.save_csv.Value = false;
        app.handles.save_mat.Value = true;
        app.handles.figures_save_png.Value = false;
        app.handles.figures_save_fig.Value = false;
        app.handles.create_animations.Value = false;
        app.handles.enable_monitoring.Value = false;
        app.handles.sustainability_auto_log.Value = false;

        lastwarn('');
        app.collect_configuration_from_ui();
        app.validate_launch_configuration();
        app.execute_single_run(app.config);
        [msg, ~] = lastwarn;
        known_warn = char(string(msg));
        assert(isempty(strfind(known_warn, 'Saving a decomposition is not supported')), ...
            'Run emitted decomposition serialization warning.');

        passed = true;
        details = 'UI warning regressions passed.';
    catch ME
        details = sprintf('%s (%s) [lastwarn=%s]', ME.message, ME.identifier, known_warn);
    end

    try
        if ~isempty(app) && isvalid(app)
            app.cleanup();
            delete(app);
        end
    catch
    end
end
