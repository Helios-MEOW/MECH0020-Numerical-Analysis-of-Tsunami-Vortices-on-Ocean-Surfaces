function test_mode_evolution_progress_callback()
% test_mode_evolution_progress_callback - Ensure evolution emits live progress payloads.

    repo_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(fullfile(repo_root, 'Scripts')));
    addpath(fullfile(repo_root, 'utilities'));

    params = create_default_parameters();
    settings = Settings();

    params.Nx = 32;
    params.Ny = 32;
    params.dt = 0.005;
    params.Tfinal = 0.05;
    params.t_final = params.Tfinal;
    params.num_plot_snapshots = 4;
    params.num_snapshots = params.num_plot_snapshots;
    params.snap_times = linspace(0, params.Tfinal, params.num_snapshots);
    params.plot_snap_times = params.snap_times;
    params.progress_stride = 1;

    settings.save_data = false;
    settings.save_figures = false;
    settings.save_reports = false;
    settings.append_to_master = false;
    settings.monitor_enabled = false;
    settings.output_root = fullfile('Results', '__tmp_progress_callback');

    progress_iters = zeros(1, 0);
    progress_times = zeros(1, 0);
    settings.ui_progress_callback = @capture_payload;

    run_cfg = Build_Run_Config('FD', 'Evolution', char(string(params.ic_type)));
    [results, ~] = ModeDispatcher(run_cfg, params, settings);

    assert(~isempty(progress_iters), 'Expected at least one progress callback payload.');
    assert(progress_iters(1) == 0, 'First callback payload should report iteration 0.');
    assert(progress_iters(end) == results.total_steps, ...
        'Final callback payload should report last simulation iteration.');
    assert(all(diff(progress_iters) >= 0), 'Progress callback iterations must be monotonic.');
    assert(all(diff(progress_times) >= 0), 'Progress callback times must be monotonic.');

    function capture_payload(payload)
        if ~isstruct(payload)
            return;
        end
        if isfield(payload, 'iteration')
            progress_iters(end + 1) = payload.iteration; %#ok<AGROW>
        end
        if isfield(payload, 'time')
            progress_times(end + 1) = payload.time; %#ok<AGROW>
        end
    end
end
