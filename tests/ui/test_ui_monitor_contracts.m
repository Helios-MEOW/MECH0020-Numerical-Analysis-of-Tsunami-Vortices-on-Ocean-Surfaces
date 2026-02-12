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
        assert(all(arrayfun(@(h) strcmpi(string(h.Title.Interpreter), "latex"), app.handles.monitor_axes)), ...
            'Monitor tile titles must default to LaTeX interpreter.');
        assert(isfield(app.handles, 'monitor_numeric_table') && isvalid(app.handles.monitor_numeric_table), ...
            'Missing numeric monitor tile table.');
        assert(numel(app.handles.monitor_numeric_table.ColumnName) == 1, ...
            'Numeric monitor tile must expose a single summary column.');
        assert(isfield(app.handles, 'ic_preview_axes') && isvalid(app.handles.ic_preview_axes), ...
            'IC preview axes handle is missing.');
        assert(strcmpi(string(app.handles.ic_preview_axes.XLabel.Interpreter), "latex") && ...
            strcmpi(string(app.handles.ic_preview_axes.YLabel.Interpreter), "latex"), ...
            'IC preview axis labels must use LaTeX interpreter.');

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
        line(app.handles.monitor_axes(1), [0 1], [1 2], 'Tag', 'stale_monitor_line_test');
        app.handles.monitor_numeric_table.Data = {'Stale row should be removed'};
        app.reset_live_monitor_history_for_run(cfg_eval);
        assert(isempty(findobj(app.handles.monitor_axes(1), 'Tag', 'stale_monitor_line_test')), ...
            'Run-start monitor reset must clear stale plot history.');
        data_after_reset = app.handles.monitor_numeric_table.Data;
        reset_lines = lower(string(data_after_reset(:, 1)));
        assert(~any(contains(reset_lines, 'stale row should be removed')), ...
            'Run-start monitor reset must clear stale numeric table rows.');
        status_after_reset = find(contains(reset_lines, '[session] status:'), 1, 'first');
        assert(~isempty(status_after_reset) && contains(reset_lines(status_after_reset), 'running'), ...
            'Run-start monitor reset must repopulate status from fresh runtime session state.');
        app.refresh_monitor_dashboard(summary_stub, cfg_eval);
        axis_titles = arrayfun(@(h) lower(char(string(h.Title.String))), app.handles.monitor_axes, 'UniformOutput', false);
        assert(~any(cellfun(@(t) contains(t, '(n/a)'), axis_titles)), ...
            'Evolution monitor selection should avoid N/A tiles when applicable metrics exist.');
        data_eval = app.handles.monitor_numeric_table.Data;
        data_eval_lines = lower(string(data_eval(:, 1)));
        runtime_idx = find(contains(data_eval_lines, '[iteration] runtime:'), 1, 'first');
        method_idx = find(contains(data_eval_lines, '[session] method:'), 1, 'first');
        iter_idx = find(contains(data_eval_lines, '[iteration] iteration:'), 1, 'first');
        machine_idx = find(contains(data_eval_lines, '[system] machine:'), 1, 'first');
        assert(~isempty(runtime_idx) && ~isempty(method_idx) && runtime_idx < method_idx, ...
            'Runtime row should be ranked above method metadata.');
        assert(~isempty(iter_idx) && ~isempty(machine_idx) && iter_idx < machine_idx, ...
            'Iteration row should be ranked above machine metadata.');
        conv_tol_idx = find(contains(data_eval_lines, '[convergence] tolerance:'), 1, 'first');
        assert(~isempty(conv_tol_idx) && contains(data_eval_lines(conv_tol_idx), 'n/a'), ...
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
        table_lines = lower(string(table_data(:, 1)));
        status_idx = find(contains(table_lines, '[session] status:'), 1, 'first');
        assert(~isempty(status_idx) && contains(table_lines(status_idx), 'running'), ...
            'Numeric monitor table status should reflect runtime progress payload.');
        axis_titles = arrayfun(@(h) lower(char(string(h.Title.String))), app.handles.monitor_axes, 'UniformOutput', false);
        cpu_axis_idx = find(contains(axis_titles, 'cpu usage'), 1, 'first');
        assert(~isempty(cpu_axis_idx), 'CPU usage tile should be part of ranked monitor selection.');
        assert(strcmp(string(app.handles.monitor_axes(cpu_axis_idx).YAxis.TickLabelFormat), "%.2f"), ...
            'CPU usage axis must use 2-decimal tick precision.');

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
