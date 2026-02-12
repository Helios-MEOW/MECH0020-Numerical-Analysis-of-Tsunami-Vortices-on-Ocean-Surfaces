function [passed, details] = test_fd_evolution_ui_traditional_parity()
% test_fd_evolution_ui_traditional_parity - Verify FD evolution parity between UI runtime inputs and standard path.

    passed = false;
    details = '';
    app = [];

    try
        ensure_ui_test_paths();
        repo_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        addpath(fullfile(repo_root, 'Scripts', 'Editable'), '-begin');
        app = UIController('StartupMode', 'ui');
        app.handles.method_dropdown.Value = 'Finite Difference';
        app.handles.mode_dropdown.Value = 'Evolution';
        app.on_method_changed();
        app.on_mode_changed();
        app.collect_configuration_from_ui();

        cfg = app.config;
        cfg.Nx = 32;
        cfg.Ny = 32;
        cfg.dt = 0.005;
        cfg.Tfinal = 0.05;
        cfg.t_final = cfg.Tfinal;
        cfg.num_snapshots = 9;
        cfg.save_csv = false;
        cfg.save_mat = false;
        cfg.figures_save_png = true;
        cfg.figures_save_fig = false;
        cfg.enable_monitoring = false;

        [run_cfg_ui, params_ui, settings_ui] = app.build_runtime_inputs(cfg);
        settings_ui.save_reports = false;
        settings_ui.append_to_master = false;
        settings_ui.output_root = fullfile('Results', '__tmp_fd_ui_parity_ui');
        [res_ui, ~] = ModeDispatcher(run_cfg_ui, params_ui, settings_ui);

        params_std = create_default_parameters();
        params_std.Nx = cfg.Nx;
        params_std.Ny = cfg.Ny;
        params_std.Lx = cfg.Lx;
        params_std.Ly = cfg.Ly;
        params_std.dt = cfg.dt;
        params_std.Tfinal = cfg.Tfinal;
        params_std.t_final = cfg.Tfinal;
        params_std.nu = cfg.nu;
        params_std.ic_type = cfg.ic_type;
        params_std.ic_coeff = params_ui.ic_coeff;
        params_std.num_plot_snapshots = cfg.num_snapshots;
        params_std.num_snapshots = cfg.num_snapshots;
        params_std.snap_times = linspace(0, params_std.Tfinal, params_std.num_snapshots);
        params_std.plot_snap_times = params_std.snap_times;

        settings_std = Settings();
        settings_std.monitor_enabled = false;
        settings_std.save_data = false;
        settings_std.save_figures = true;
        settings_std.save_reports = false;
        settings_std.append_to_master = false;
        settings_std.output_root = fullfile('Results', '__tmp_fd_ui_parity_std');

        run_cfg_std = Build_Run_Config('FD', 'Evolution', params_std.ic_type);
        [res_std, ~] = ModeDispatcher(run_cfg_std, params_std, settings_std);

        assert(strcmp(run_cfg_ui.method, 'FD') && strcmp(run_cfg_ui.mode, 'Evolution'), ...
            'UI dispatch config must map to FD/Evolution.');
        assert(abs(res_ui.max_omega - res_std.max_omega) <= 1e-9, ...
            'UI vs standard FD evolution max|omega| mismatch.');
        assert(isfield(res_ui, 'figure_layout_rows') && isfield(res_ui, 'figure_layout_cols') && ...
            res_ui.figure_layout_rows == 3 && res_ui.figure_layout_cols == 3, ...
            'UI-run FD evolution figure layout must be 3x3 for 9 snapshots.');
        assert(isfield(res_std, 'figure_layout_rows') && isfield(res_std, 'figure_layout_cols') && ...
            res_std.figure_layout_rows == 3 && res_std.figure_layout_cols == 3, ...
            'Standard-run FD evolution figure layout must be 3x3 for 9 snapshots.');

        passed = true;
        details = 'FD evolution UI/traditional parity passed.';
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
