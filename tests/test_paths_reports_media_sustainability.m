function test_paths_reports_media_sustainability()
% test_paths_reports_media_sustainability - Regression checks for hardened run artifacts.
%
% Coverage:
%   1) Canonical Results-root path invariant
%   2) run_manifest.json + report_payload.json + HTML/PDF report presence
%   3) Sustainability ledger row append (exactly one row for the run_id)
%   4) Plotting mode source lookup via canonical Results tree
%   5) Animation format MWE generates MP4 successfully

    fprintf('\n[HARDENING] Starting integration regression test...\n');

    test_dir = fileparts(mfilename('fullpath'));
    repo_root = fileparts(test_dir);
    addpath(genpath(fullfile(repo_root, 'Scripts')));
    addpath(fullfile(repo_root, 'utilities'));

    set(0, 'DefaultFigureVisible', 'off');

    params = Parameters();
    settings = Settings();
    params.Nx = 8;
    params.Ny = 8;
    params.dt = 0.01;
    params.Tfinal = 0.01;
    params.num_plot_snapshots = 2;
    params.snap_times = [0, params.Tfinal];
    params.num_snapshots = 2;

    settings.save_figures = false;
    settings.save_data = true;
    settings.save_reports = true;
    settings.reporting.enabled = true;
    settings.append_to_master = false;
    settings.monitor_enabled = false;

    rc = Build_Run_Config('FD', 'Evolution', params.ic_type);
    [results, paths] = ModeDispatcher(rc, params, settings);

    assert(isfield(results, 'run_id') && ~isempty(results.run_id), 'Missing results.run_id');
    run_id = char(string(results.run_id));
    fprintf('[HARDENING] Run id: %s\n', run_id);

    expected_root = fullfile(repo_root, 'Results');
    assert(startsWith(paths.base, expected_root), ...
        'Run wrote outside canonical Results root: %s', paths.base);

    manifest_path = fullfile(paths.config, 'run_manifest.json');
    payload_path = fullfile(paths.reports, 'report_payload.json');
    html_path = fullfile(paths.reports, 'run_report.html');
    pdf_path = fullfile(paths.reports, 'run_report.pdf');

    assert(exist(manifest_path, 'file') == 2, 'Missing manifest: %s', manifest_path);
    assert(exist(payload_path, 'file') == 2, 'Missing report payload: %s', payload_path);
    assert(exist(html_path, 'file') == 2, 'Missing report HTML: %s', html_path);
    assert(exist(pdf_path, 'file') == 2, 'Missing report PDF: %s', pdf_path);

    ledger_path = fullfile(repo_root, 'Results', 'Sustainability', 'runs_sustainability.csv');
    assert(exist(ledger_path, 'file') == 2, 'Missing sustainability ledger: %s', ledger_path);
    ledger_table = readtable(ledger_path, 'TextType', 'string');
    row_count = sum(strcmp(string(ledger_table.run_id), string(run_id)));
    assert(row_count == 1, 'Expected exactly one sustainability row for run_id %s, got %d', run_id, row_count);

    % Plotting-mode canonical source lookup check.
    plot_run_id = ['plot_', run_id];
    rc_plot = Build_Run_Config('FD', 'Plotting', params.ic_type, ...
        'source_run_id', run_id, ...
        'run_id', plot_run_id);
    [~, plot_paths] = ModeDispatcher(rc_plot, params, settings);
    assert(startsWith(plot_paths.base, fullfile(repo_root, 'Results', 'Plotting', 'Plotting')), ...
        'Plotting output path is non-canonical: %s', plot_paths.base);

    % Media MWE check (MP4 should be available unless toolchain is broken).
    media_out = fullfile(repo_root, 'Artifacts', 'tests', 'media_mwe_regression');
    mwe = AnimationFormatMWE('OutputDir', media_out, 'Frames', 16, 'FrameRate', 12, 'Quality', 90);
    formats = string({mwe.results.format});
    success_flags = [mwe.results.success];
    mp4_idx = find(formats == "mp4", 1, 'first');
    assert(~isempty(mp4_idx), 'Media MWE did not include MP4 case');
    assert(success_flags(mp4_idx), 'Media MWE MP4 export failed');

    fprintf('[HARDENING] Integration regression test PASSED.\n');
end
