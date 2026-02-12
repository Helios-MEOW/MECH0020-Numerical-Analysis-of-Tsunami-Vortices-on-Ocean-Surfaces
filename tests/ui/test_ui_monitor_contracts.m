function [passed, details] = test_ui_monitor_contracts()
% test_ui_monitor_contracts - Regression checks for UI monitor/layout contracts.

    passed = false;
    details = '';
    app = [];

    try
        ensure_ui_test_paths();
        app = UIController('StartupMode', 'ui');

        assert(isfield(app.handles, 'monitor_axes'), 'Missing monitor_axes handle.');
        assert(numel(app.handles.monitor_axes) == 8, 'Expected 8 plot tiles in monitor_axes.');
        assert(all(arrayfun(@(h) isvalid(h), app.handles.monitor_axes)), 'One or more monitor axes are invalid.');
        assert(isfield(app.handles, 'monitor_numeric_table') && isvalid(app.handles.monitor_numeric_table), ...
            'Missing numeric monitor tile table.');

        cfg = app.layout_cfg.monitor_tab;
        assert(cfg.plot_grid_rows == 3 && cfg.plot_grid_cols == 3, 'Monitor grid must be 3x3.');
        assert(cfg.plot_tile_count == 9, 'Monitor must expose 9 total tiles.');
        assert(cfg.numeric_tile_index == 9, 'Numeric tile index must be 9.');

        assert(isfield(app.handles, 'btn_launch') && isfield(app.handles, 'btn_import') && isfield(app.handles, 'btn_export'), ...
            'Launch/Import/Export buttons missing.');
        assert(app.handles.btn_launch.Layout.Row == 1 && app.handles.btn_import.Layout.Row == 1 && app.handles.btn_export.Layout.Row == 1, ...
            'Launch/Import/Export buttons must align on one row.');

        assert(isfield(app.handles, 'bathy_enable') && isfield(app.handles, 'motion_enable'), ...
            'Bathymetry and motion controls must be separate handles.');

        mode_panels = findall(app.fig, 'Type', 'uipanel', 'Title', 'Mode-Specific Controls');
        assert(isempty(mode_panels), 'Mode-Specific Controls panel must not exist.');
        assert(~isfield(app.handles, 'sweep_parameter'), 'Legacy sweep UI handle should not exist.');
        assert(~isfield(app.handles, 'exp_coeff_selector'), 'Legacy experimentation UI handle should not exist.');

        app.collect_configuration_from_ui();
        assert(isfield(app.config, 'sweep_parameter') && ~isempty(app.config.sweep_parameter), ...
            'Config must provide sweep_parameter defaults when UI controls are absent.');
        assert(isfield(app.config, 'sweep_values') && numel(app.config.sweep_values) >= 1, ...
            'Config must provide sweep_values defaults when UI controls are absent.');
        assert(isfield(app.config, 'experimentation') && isstruct(app.config.experimentation), ...
            'Config must provide experimentation defaults when UI controls are absent.');

        app.handles.mode_dropdown.Value = 'Evolution';
        app.on_mode_changed();
        assert(strcmpi(string(app.handles.conv_N_coarse.Enable), "off"), ...
            'Convergence controls must be disabled outside Convergence mode.');

        app.handles.mode_dropdown.Value = 'Convergence';
        app.handles.conv_agent_enabled.Value = true;
        app.on_mode_changed();
        assert(strcmpi(string(app.handles.conv_N_coarse.Enable), "off"), ...
            'Convergence controls must lock when agent mode is enabled.');

        app.handles.conv_agent_enabled.Value = false;
        app.on_convergence_agent_changed();
        assert(strcmpi(string(app.handles.conv_N_coarse.Enable), "on"), ...
            'Convergence controls must unlock in manual convergence mode.');

        passed = true;
        details = 'UI monitor/layout contracts passed.';
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
