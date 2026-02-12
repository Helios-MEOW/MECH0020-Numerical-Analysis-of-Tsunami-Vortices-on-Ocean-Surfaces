function artifacts = capture_ui_acceptance(varargin)
% capture_ui_acceptance - Capture deterministic UI screenshots for acceptance checks.
%
% Usage:
%   artifacts = capture_ui_acceptance();
%   artifacts = capture_ui_acceptance('OutputDir', 'Artifacts/TestReports/UIShots');

    p = inputParser;
    addParameter(p, 'OutputDir', '', @(x) ischar(x) || isstring(x));
    parse(p, varargin{:});

    output_dir = char(string(p.Results.OutputDir));
    ensure_ui_test_paths();
    artifacts = struct('config_shot', '', 'monitor_shot', '', 'timestamp', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), ...
        'checks', struct(), 'report_json', '', 'report_md', '');
    app = [];

    try
        app = UIController('StartupMode', 'ui');
        app.fig.WindowState = 'maximized';
        drawnow;
        pause(1.0);

        % Deterministic state prior to capture.
        app.handles.method_dropdown.Value = 'Finite Difference';
        app.handles.mode_dropdown.Value = 'Evolution';
        app.on_method_changed();
        app.on_mode_changed();
        app.on_ic_changed();
        app.collect_configuration_from_ui();
        drawnow;

        % Config tab capture.
        app.tab_group.SelectedTab = app.tabs.config;
        drawnow;
        pause(0.8);
        artifacts.config_shot = run_windows_capture('config', output_dir);

        % Monitor tab capture.
        app.tab_group.SelectedTab = app.tabs.monitoring;
        drawnow;
        pause(0.8);
        artifacts.monitor_shot = run_windows_capture('monitor', output_dir);
        artifacts.checks = run_acceptance_checks(app);
        [artifacts.report_json, artifacts.report_md] = write_acceptance_reports(artifacts, output_dir);

    catch ME
        warning('capture_ui_acceptance:CaptureFailed', '%s\n%s', ...
            ME.message, getReport(ME, 'basic', 'hyperlinks', 'off'));
    end

    try
        if ~isempty(app) && isvalid(app)
            app.cleanup();
            delete(app);
        end
    catch
    end

    disp('UI_ACCEPTANCE_CAPTURE');
    disp(artifacts);
end

function shot_path = run_windows_capture(label, output_dir)
    shot_path = '';
    script_path = fullfile(getenv('USERPROFILE'), '.codex', 'skills', 'screenshot', 'scripts', 'take_screenshot.ps1');
    if ~isfile(script_path)
        error('Screenshot script not found: %s', script_path);
    end

    if ~isempty(output_dir)
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        target = fullfile(output_dir, sprintf('ui_acceptance_%s_%s.png', label, char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))));
        cmd = sprintf('powershell -ExecutionPolicy Bypass -File "%s" -Path "%s" -ActiveWindow', script_path, target);
        fallback_cmd = sprintf('powershell -ExecutionPolicy Bypass -File "%s" -Path "%s"', script_path, target);
    else
        cmd = sprintf('powershell -ExecutionPolicy Bypass -File "%s" -Mode temp -ActiveWindow', script_path);
        fallback_cmd = sprintf('powershell -ExecutionPolicy Bypass -File "%s" -Mode temp', script_path);
    end

    [status, output_txt] = system(cmd);
    if status ~= 0
        [status, output_txt] = system(fallback_cmd);
        if status ~= 0
            error('Screenshot command failed: %s', output_txt);
        end
    end

    lines = splitlines(string(output_txt));
    lines = lines(strlength(strtrim(lines)) > 0);
    if isempty(lines)
        error('Screenshot command returned no output path.');
    end
    shot_path = char(lines(end));
end

function checks = run_acceptance_checks(app)
    checks = struct();
    mode_panels = findall(app.fig, 'Type', 'uipanel', 'Title', 'Mode-Specific Controls');
    checks.mode_panel_absent = isempty(mode_panels);

    checks.ic_equation_no_raw_tex = false;
    if isfield(app.handles, 'ic_equation') && isvalid(app.handles.ic_equation)
        eq_h = app.handles.ic_equation;
        if isprop(eq_h, 'HTMLSource')
            eq_html = char(string(eq_h.HTMLSource));
            checks.ic_equation_no_raw_tex = isempty(strfind(eq_html, '$$'));
        elseif isprop(eq_h, 'ImageSource')
            eq_img = char(string(eq_h.ImageSource));
            checks.ic_equation_no_raw_tex = ~isempty(eq_img) && isfile(eq_img);
        end
    end

    checks.ic_preview_visible = isfield(app.handles, 'ic_preview_axes') && ...
        isvalid(app.handles.ic_preview_axes) && strcmpi(app.handles.ic_preview_axes.Visible, 'on');

    checks.monitor_contract_8_plus_1 = isfield(app.handles, 'monitor_axes') && ...
        numel(app.handles.monitor_axes) == 8 && isfield(app.handles, 'monitor_numeric_table') && ...
        isvalid(app.handles.monitor_numeric_table);

    checks.config_left_scrollable = isfield(app.handles, 'config_left_panel') && ...
        isvalid(app.handles.config_left_panel) && ...
        strcmpi(string(app.handles.config_left_panel.Scrollable), "on");
    checks.config_right_scrollable = isfield(app.handles, 'config_right_panel') && ...
        isvalid(app.handles.config_right_panel) && ...
        strcmpi(string(app.handles.config_right_panel.Scrollable), "on");
    checks.run_status_in_monitor = false;
    if isfield(app.handles, 'run_status') && isvalid(app.handles.run_status)
        status_tab = ancestor(app.handles.run_status, 'matlab.ui.container.Tab');
        checks.run_status_in_monitor = ~isempty(status_tab) && isequal(status_tab, app.tabs.monitoring);
    end

    checks.sustainability_controls_present = isfield(app.handles, 'enable_monitoring') && ...
        isvalid(app.handles.enable_monitoring) && isfield(app.handles, 'sample_interval') && ...
        isvalid(app.handles.sample_interval);

    checks.launch_import_export_one_row = false;
    checks.launch_import_export_equal_width = false;
    if isfield(app.handles, 'btn_launch') && isvalid(app.handles.btn_launch) && ...
            isfield(app.handles, 'btn_import') && isvalid(app.handles.btn_import) && ...
            isfield(app.handles, 'btn_export') && isvalid(app.handles.btn_export)
        p1 = app.handles.btn_launch.Position;
        p2 = app.handles.btn_import.Position;
        p3 = app.handles.btn_export.Position;
        checks.launch_import_export_one_row = abs(p1(2) - p2(2)) < 2 && abs(p2(2) - p3(2)) < 2;
        checks.launch_import_export_equal_width = abs(p1(3) - p2(3)) < 2 && abs(p2(3) - p3(3)) < 2;
    end
end

function [json_path, md_path] = write_acceptance_reports(artifacts, output_dir)
    json_path = '';
    md_path = '';
    if isempty(output_dir)
        output_dir = fullfile('Artifacts', 'TestReports', 'UIAcceptance');
    end
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    json_path = fullfile(output_dir, sprintf('ui_acceptance_report_%s.json', stamp));
    md_path = fullfile(output_dir, sprintf('ui_acceptance_report_%s.md', stamp));

    fid = fopen(json_path, 'w');
    fwrite(fid, jsonencode(artifacts), 'char');
    fclose(fid);

    keys = fieldnames(artifacts.checks);
    lines = {};
    lines{end + 1} = '# UI Acceptance Report'; %#ok<AGROW>
    lines{end + 1} = ''; %#ok<AGROW>
    lines{end + 1} = ['Timestamp: ', artifacts.timestamp]; %#ok<AGROW>
    lines{end + 1} = ['Config screenshot: ', artifacts.config_shot]; %#ok<AGROW>
    lines{end + 1} = ['Monitor screenshot: ', artifacts.monitor_shot]; %#ok<AGROW>
    lines{end + 1} = ''; %#ok<AGROW>
    lines{end + 1} = '## Checklist'; %#ok<AGROW>
    for i = 1:numel(keys)
        k = keys{i};
        v = artifacts.checks.(k);
        if v
            status = 'PASS';
        else
            status = 'FAIL';
        end
        lines{end + 1} = sprintf('- [%s] %s', status, k); %#ok<AGROW>
    end
    fid = fopen(md_path, 'w');
    fprintf(fid, '%s\n', strjoin(lines, newline));
    fclose(fid);
end
