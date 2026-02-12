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
        assert(isfield(app.handles, 'btn_retry_cpuz') && isvalid(app.handles.btn_retry_cpuz) && ...
            isfield(app.handles, 'btn_retry_hwinfo') && isvalid(app.handles.btn_retry_hwinfo) && ...
            isfield(app.handles, 'btn_retry_icue') && isvalid(app.handles.btn_retry_icue), ...
            'Collector retry buttons must be present in Live Monitor panel.');
        assert(isfield(app.handles, 'collector_probe_status') && isvalid(app.handles.collector_probe_status), ...
            'collector_probe_status label is missing.');
        assert(isfield(app.handles, 'defaults_source_info') && isvalid(app.handles.defaults_source_info), ...
            'defaults_source_info label is missing.');
        defaults_info_text = lower(string(app.handles.defaults_source_info.Text));
        assert(contains(defaults_info_text, 'create_default_parameters'), ...
            'Defaults provenance label must reference create_default_parameters.m.');

        app.collect_configuration_from_ui();
        assert(isfield(app.config, 'sweep_parameter') && ~isempty(app.config.sweep_parameter), ...
            'Config must provide sweep_parameter defaults when UI controls are absent.');
        assert(isfield(app.config, 'sweep_values') && numel(app.config.sweep_values) >= 1, ...
            'Config must provide sweep_values defaults when UI controls are absent.');
        assert(isfield(app.config, 'experimentation') && isstruct(app.config.experimentation), ...
            'Config must provide experimentation defaults when UI controls are absent.');
        assert(isfield(app.config, 'defaults_source') && isstruct(app.config.defaults_source) && ...
            isfield(app.config.defaults_source, 'summary') && ...
            contains(lower(string(app.config.defaults_source.summary)), 'create_default_parameters'), ...
            'Config must expose defaults provenance.');

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

        % Metric applicability/ranking: evolution should avoid N/A tiles and
        % convergence mode should include active convergence residual.
        summary_stub = struct('results', struct());
        cfg_eval = app.config;
        cfg_eval.mode = 'evolution';
        cfg_eval.method = 'finite_difference';
        app.refresh_monitor_dashboard(summary_stub, cfg_eval);
        axis_titles = arrayfun(@(h) lower(char(string(h.Title.String))), app.handles.monitor_axes, 'UniformOutput', false);
        assert(~any(cellfun(@(t) contains(t, '(n/a)'), axis_titles)), ...
            'Evolution monitor selection should avoid N/A tiles when applicable metrics exist.');
        data_eval = app.handles.monitor_numeric_table.Data;
        runtime_idx = find(strcmp(data_eval(:, 1), 'Runtime'), 1, 'first');
        method_idx = find(strcmp(data_eval(:, 1), 'Method'), 1, 'first');
        iter_idx = find(strcmp(data_eval(:, 1), 'Iteration'), 1, 'first');
        machine_idx = find(strcmp(data_eval(:, 1), 'Machine'), 1, 'first');
        assert(~isempty(runtime_idx) && ~isempty(method_idx) && runtime_idx < method_idx, ...
            'Runtime row should be ranked above method metadata.');
        assert(~isempty(iter_idx) && ~isempty(machine_idx) && iter_idx < machine_idx, ...
            'Iteration row should be ranked above machine metadata.');
        conv_tol_idx = find(strcmp(data_eval(:, 1), 'Convergence tol'), 1, 'first');
        assert(~isempty(conv_tol_idx) && strcmp(data_eval{conv_tol_idx, 2}, 'N/A'), ...
            'Convergence tolerance row should be N/A outside convergence mode.');

        cfg_eval.mode = 'convergence';
        app.refresh_monitor_dashboard(summary_stub, cfg_eval);
        axis_titles = arrayfun(@(h) lower(char(string(h.Title.String))), app.handles.monitor_axes, 'UniformOutput', false);
        conv_idx = find(contains(axis_titles, 'convergence residual'), 1, 'first');
        assert(~isempty(conv_idx), 'Convergence mode should include convergence residual tile in ranked selection.');
        assert(~contains(axis_titles{conv_idx}, '(n/a)'), ...
            'Convergence residual plot should be active in convergence mode.');

        app.handles.cpuz_enable.Value = true;
        app.retry_collector_connection('cpuz');
        cpuz_state = lower(char(string(app.handles.metrics_source_cpuz.Text)));
        assert(any(strcmp(cpuz_state, {'connected', 'not found'})), ...
            'CPU-Z retry probe should update source status to connected/not found.');
        app.handles.cpuz_enable.Value = false;
        app.update_checklist();

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
