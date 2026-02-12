function artifacts = probe_backend_frontend_bridge(varargin)
% probe_backend_frontend_bridge - Validate MATLAB backend -> Python frontend bridge path.
%
% Usage:
%   artifacts = probe_backend_frontend_bridge();
%   artifacts = probe_backend_frontend_bridge('OutputDir', 'Artifacts/TestReports/UIBridgeProbe');

    p = inputParser;
    addParameter(p, 'OutputDir', fullfile('Artifacts', 'TestReports', 'UIBridgeProbe'), @(x) ischar(x) || isstring(x));
    addParameter(p, 'EnablePopup', false, @(x) islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    output_dir = char(string(p.Results.OutputDir));
    enable_popup = logical(p.Results.EnablePopup);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    input_json = fullfile(output_dir, sprintf('bridge_probe_input_%s.json', stamp));
    output_json = fullfile(output_dir, sprintf('bridge_probe_output_%s.json', stamp));
    report_md = fullfile(output_dir, sprintf('bridge_probe_report_%s.md', stamp));

    telemetry = struct( ...
        'method', 'finite_difference', ...
        'mode', 'evolution', ...
        'iteration', 42, ...
        'runtime_s', 1.275, ...
        'max_omega', 0.913);
    fid = fopen(input_json, 'w');
    fwrite(fid, jsonencode(telemetry), 'char');
    fclose(fid);

    script_path = fullfile('prototypes', 'ui_bridge', 'python_backend_bridge_probe.py');
    popup_flag = '--no-popup';
    if enable_popup
        popup_flag = '';
    end

    cmd = sprintf('python \"%s\" --input \"%s\" --output \"%s\" %s', ...
        script_path, input_json, output_json, popup_flag);
    [exit_code, cmd_out] = system(cmd);

    probe_ok = exit_code == 0 && exist(output_json, 'file') == 2;
    payload = struct();
    if probe_ok
        payload_text = fileread(output_json);
        payload = jsondecode(payload_text);
    end

    artifacts = struct( ...
        'timestamp', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), ...
        'probe_ok', probe_ok, ...
        'exit_code', exit_code, ...
        'command', cmd, ...
        'command_output', strtrim(cmd_out), ...
        'input_json', input_json, ...
        'output_json', output_json, ...
        'report_md', report_md, ...
        'popup_attempted', false, ...
        'popup_ok', false, ...
        'summary_text', '');

    if isstruct(payload)
        if isfield(payload, 'popup_attempted')
            artifacts.popup_attempted = logical(payload.popup_attempted);
        end
        if isfield(payload, 'popup_ok')
            artifacts.popup_ok = logical(payload.popup_ok);
        end
        if isfield(payload, 'summary_text')
            artifacts.summary_text = char(string(payload.summary_text));
        end
    end

    lines = {};
    lines{end + 1} = '# Backend-Frontend Bridge Probe'; %#ok<AGROW>
    lines{end + 1} = ''; %#ok<AGROW>
    lines{end + 1} = ['Timestamp: ', artifacts.timestamp]; %#ok<AGROW>
    lines{end + 1} = ['Probe OK: ', tf_text(artifacts.probe_ok)]; %#ok<AGROW>
    lines{end + 1} = ['Exit code: ', num2str(artifacts.exit_code)]; %#ok<AGROW>
    lines{end + 1} = ['Popup attempted: ', tf_text(artifacts.popup_attempted)]; %#ok<AGROW>
    lines{end + 1} = ['Popup OK: ', tf_text(artifacts.popup_ok)]; %#ok<AGROW>
    lines{end + 1} = ''; %#ok<AGROW>
    lines{end + 1} = '## Command'; %#ok<AGROW>
    lines{end + 1} = ['- ', artifacts.command]; %#ok<AGROW>
    lines{end + 1} = ['- stdout: ', artifacts.command_output]; %#ok<AGROW>
    lines{end + 1} = ''; %#ok<AGROW>
    lines{end + 1} = '## Artifacts'; %#ok<AGROW>
    lines{end + 1} = ['- input_json: ', artifacts.input_json]; %#ok<AGROW>
    lines{end + 1} = ['- output_json: ', artifacts.output_json]; %#ok<AGROW>
    lines{end + 1} = ['- report_md: ', artifacts.report_md]; %#ok<AGROW>
    if ~isempty(strtrim(artifacts.summary_text))
        lines{end + 1} = ''; %#ok<AGROW>
        lines{end + 1} = '## Python Summary'; %#ok<AGROW>
        lines{end + 1} = ['```text', newline, artifacts.summary_text, newline, '```']; %#ok<AGROW>
    end

    fid = fopen(report_md, 'w');
    fprintf(fid, '%s\n', strjoin(lines, newline));
    fclose(fid);
end

function t = tf_text(tf)
    if tf
        t = 'PASS';
    else
        t = 'FAIL';
    end
end
