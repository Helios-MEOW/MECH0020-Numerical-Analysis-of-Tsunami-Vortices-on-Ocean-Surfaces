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
        assert(isfield(app.handles, 'config_left_panel') && isvalid(app.handles.config_left_panel), ...
            'Missing config_left_panel handle.');
        assert(isfield(app.handles, 'config_right_panel') && isvalid(app.handles.config_right_panel), ...
            'Missing config_right_panel handle.');
        assert(strcmpi(string(app.handles.config_left_panel.Scrollable), "on"), ...
            'Configuration panel must be scrollable.');
        assert(strcmpi(string(app.handles.config_right_panel.Scrollable), "on"), ...
            'Initial Conditions/Preview panel must be scrollable.');
        assert(app.layout_cfg.config_tab.check_grid.rows_cols(1) == 3, ...
            'Readiness checklist must use compact 3-row layout.');
        assert(isfield(app.handles, 'run_status') && isvalid(app.handles.run_status), ...
            'run_status handle is missing.');
        status_tab = ancestor(app.handles.run_status, 'matlab.ui.container.Tab');
        assert(~isempty(status_tab) && isequal(status_tab, app.tabs.monitoring), ...
            'run_status must live in Live Monitor tab.');

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

        % Metric applicability: convergence residual must be gated by mode.
        summary_stub = struct('results', struct());
        cfg_eval = app.config;
        cfg_eval.mode = 'evolution';
        cfg_eval.method = 'finite_difference';
        app.refresh_monitor_dashboard(summary_stub, cfg_eval);
        conv_title = lower(char(string(app.handles.monitor_axes(8).Title.String)));
        assert(contains(conv_title, '(n/a)'), ...
            'Convergence residual plot should be marked N/A outside convergence mode.');
        data_eval = app.handles.monitor_numeric_table.Data;
        conv_tol_idx = find(strcmp(data_eval(:, 1), 'Convergence tol'), 1, 'first');
        assert(~isempty(conv_tol_idx) && strcmp(data_eval{conv_tol_idx, 2}, 'N/A'), ...
            'Convergence tolerance row should be N/A outside convergence mode.');

        cfg_eval.mode = 'convergence';
        app.refresh_monitor_dashboard(summary_stub, cfg_eval);
        conv_title = lower(char(string(app.handles.monitor_axes(8).Title.String)));
        assert(~contains(conv_title, '(n/a)'), ...
            'Convergence residual plot should be active in convergence mode.');

        % Runtime payload path: supplied monitor series should drive tile/table values.
        cfg_eval.mode = 'evolution';
        live_summary = struct();
        live_summary.results = struct('max_omega', 1.2);
        live_summary.monitor_series = struct( ...
            't', [0.0, 0.5, 1.0], ...
            'iters', [1, 6, 10], ...
            'iter_rate', [10, 10, 8], ...
            'max_omega', [1.2, 0.9, 0.7], ...
            'energy_proxy', [1.4, 0.8, 0.49], ...
            'enstrophy_proxy', [1.3, 0.85, 0.59], ...
            'cpu_proxy', [35, 42, 40], ...
            'memory_series', [900, 910, 920], ...
            'conv_x', [1, 6, 10], ...
            'conv_residual', [0.1, 0.05, 0.02], ...
            'status_text', 'Running 10/10 (100.0%%)');
        app.refresh_monitor_dashboard(live_summary, cfg_eval);
        iter_lines = findobj(app.handles.monitor_axes(1), 'Type', 'line');
        assert(~isempty(iter_lines), 'Iterations tile should render live line data.');
        assert(numel(iter_lines(1).YData) == 3 && iter_lines(1).YData(end) == 10, ...
            'Iterations tile must use runtime iteration payload.');
        table_data = app.handles.monitor_numeric_table.Data;
        status_idx = find(strcmp(table_data(:, 1), 'Status'), 1, 'first');
        assert(~isempty(status_idx) && contains(lower(string(table_data{status_idx, 2})), 'running'), ...
            'Numeric monitor table status should reflect runtime progress payload.');

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
