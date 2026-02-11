function test_spectral_fv_dispatcher_smoke()
% test_spectral_fv_dispatcher_smoke - Checkpoint smoke tests for Spectral/FV dispatcher paths.

    test_dir = fileparts(mfilename('fullpath'));
    repo_root = fileparts(test_dir);
    addpath(genpath(fullfile(repo_root, 'Scripts')));
    addpath(fullfile(repo_root, 'utilities'));

    set(0, 'DefaultFigureVisible', 'off');

    params = Parameters();
    params.Nx = 16;
    params.Ny = 16;
    params.Nz = 8;
    params.Lz = 1.0;
    params.dt = 0.0025;
    params.Tfinal = 0.01;
    params.snap_times = [0, 0.005, 0.01];
    params.num_snapshots = 3;

    settings = Settings();
    settings.save_figures = false;
    settings.save_data = false;
    settings.save_reports = false;
    settings.append_to_master = false;
    settings.monitor_enabled = false;

    % 1) Spectral evolution smoke
    rc_sp = Build_Run_Config('Spectral', 'Evolution', params.ic_type);
    [res_sp, ~] = ModeDispatcher(rc_sp, params, settings);
    assert(isfield(res_sp, 'max_omega') && isfinite(res_sp.max_omega), 'Spectral evolution dispatcher smoke failed');

    % 2) Spectral convergence smoke with explicit k-levels
    rc_sp_conv = Build_Run_Config('Spectral', 'Convergence', params.ic_type);
    params_sp_conv = params;
    params_sp_conv.spectral_convergence = struct();
    params_sp_conv.spectral_convergence.levels = [ ...
        struct('label', 'k16', 'kx', make_kvec(16, params.Lx), 'ky', make_kvec(16, params.Ly)), ...
        struct('label', 'k32', 'kx', make_kvec(32, params.Lx), 'ky', make_kvec(32, params.Ly))];
    [res_sp_conv, ~] = ModeDispatcher(rc_sp_conv, params_sp_conv, settings);
    assert(isfield(res_sp_conv, 'refinement_axis') && strcmpi(res_sp_conv.refinement_axis, 'dk'), ...
        'Spectral convergence did not report dk refinement axis');

    % 3) FV evolution smoke (3D layered)
    rc_fv = Build_Run_Config('FV', 'Evolution', params.ic_type);
    [res_fv, ~] = ModeDispatcher(rc_fv, params, settings);
    assert(isfield(res_fv, 'max_omega') && isfinite(res_fv.max_omega), 'FV evolution dispatcher smoke failed');

    % 4) FV convergence blocked path
    rc_fv_conv = Build_Run_Config('FV', 'Convergence', params.ic_type);
    blocked_ok = false;
    try
        ModeDispatcher(rc_fv_conv, params, settings);
    catch ME
        blocked_ok = contains(ME.identifier, 'SOL') || contains(ME.message, 'SOL-FV-0001') || contains(ME.message, 'not enabled');
    end
    assert(blocked_ok, 'FV convergence should be blocked in this checkpoint');

    fprintf('[test_spectral_fv_dispatcher_smoke] PASS\n');
end

function k = make_kvec(N, L)
    k = (2 * pi / L) * [0:(N/2 - 1), (-N/2):-1];
end
