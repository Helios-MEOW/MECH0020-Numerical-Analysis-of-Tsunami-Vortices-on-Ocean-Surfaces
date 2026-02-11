classdef RunArtifactsManager
    % RunArtifactsManager - Centralized post-run artifact finalization.
    %
    % Responsibilities:
    %   - Ensure canonical run directories exist.
    %   - Write run_manifest.json in Config/.
    %   - Build report_payload.json and HTML/PDF reports in Reports/.
    %   - Append one row to global sustainability ledger.

    methods (Static)
        function artifact_summary = finalize(Run_Config, Parameters, Settings, Results, paths)
            paths = RunArtifactsManager.ensure_common_paths(paths);
            run_id = RunArtifactsManager.resolve_run_id(Run_Config, Results);

            manifest = RunArtifactsManager.build_manifest(run_id, Run_Config, Parameters, Settings, Results, paths);
            manifest_path = fullfile(paths.config, 'run_manifest.json');
            RunArtifactsManager.write_json(manifest_path, manifest);

            payload = RunArtifactsManager.build_report_payload(run_id, Run_Config, Parameters, Results, paths);
            reporting_enabled = RunArtifactsManager.reporting_enabled(Settings);
            report_artifacts = struct();
            if reporting_enabled
                report_artifacts = RunReportPipeline.generate(payload, paths, Settings);
            else
                % Always emit payload for consistency, even when rich reports are disabled.
                payload_path = fullfile(paths.reports, 'report_payload.json');
                if ~exist(paths.reports, 'dir')
                    mkdir(paths.reports);
                end
                RunArtifactsManager.write_json(payload_path, payload);
                report_artifacts.payload_path = payload_path;
                report_artifacts.engine = 'disabled';
                report_artifacts.html_path = '';
                report_artifacts.pdf_path = '';
            end

            [ledger_path, ledger_row] = SustainabilityLedger.append_run(Run_Config, Parameters, Settings, Results, paths);

            artifact_summary = struct();
            artifact_summary.run_id = run_id;
            artifact_summary.manifest_path = manifest_path;
            artifact_summary.report_artifacts = report_artifacts;
            artifact_summary.sustainability_ledger_path = ledger_path;
            artifact_summary.sustainability_row = ledger_row;
        end
    end

    methods (Static, Access = private)
        function paths = ensure_common_paths(paths)
            defaults = {'config', 'reports', 'logs', 'sustainability'};
            for i = 1:numel(defaults)
                key = defaults{i};
                if ~isfield(paths, key) || isempty(paths.(key))
                    paths.(key) = fullfile(paths.base, RunArtifactsManager.upper_first(key));
                end
                target = paths.(key);
                if ~exist(target, 'dir')
                    mkdir(target);
                end
            end
        end

        function tf = reporting_enabled(Settings)
            tf = false;
            if isfield(Settings, 'save_reports')
                tf = logical(Settings.save_reports);
            end
            if isfield(Settings, 'reporting') && isfield(Settings.reporting, 'enabled')
                tf = logical(Settings.reporting.enabled);
            end
        end

        function run_id = resolve_run_id(Run_Config, Results)
            if isfield(Results, 'run_id') && ~isempty(Results.run_id)
                run_id = char(string(Results.run_id));
                return;
            end
            if isfield(Run_Config, 'run_id') && ~isempty(Run_Config.run_id)
                run_id = char(string(Run_Config.run_id));
                return;
            end
            if isfield(Run_Config, 'study_id') && ~isempty(Run_Config.study_id)
                run_id = char(string(Run_Config.study_id));
                return;
            end
            run_id = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
        end

        function manifest = build_manifest(run_id, Run_Config, Parameters, Settings, Results, paths)
            manifest = struct();
            manifest.schema_version = '1.0';
            manifest.generated_at_utc = char(datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z'''));
            manifest.run_id = run_id;
            manifest.method = RunArtifactsManager.safe_field(Run_Config, 'method', 'unknown');
            manifest.mode = RunArtifactsManager.safe_field(Run_Config, 'mode', 'unknown');
            manifest.ic_type = RunArtifactsManager.safe_field(Run_Config, 'ic_type', '');
            manifest.paths = RunArtifactsManager.compact_struct(paths);
            manifest.parameters = RunArtifactsManager.compact_struct(Parameters);
            manifest.settings = RunArtifactsManager.compact_struct(Settings);
            manifest.results = RunArtifactsManager.compact_struct(Results);
        end

        function payload = build_report_payload(run_id, Run_Config, Parameters, Results, paths)
            payload = struct();
            payload.title = sprintf('Simulation Report: %s', run_id);

            payload.summary = struct();
            payload.summary.run_id = run_id;
            payload.summary.method = RunArtifactsManager.safe_field(Run_Config, 'method', 'unknown');
            payload.summary.mode = RunArtifactsManager.safe_field(Run_Config, 'mode', 'unknown');
            payload.summary.ic_type = RunArtifactsManager.safe_field(Run_Config, 'ic_type', '');
            payload.summary.generated_at_utc = char(datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z'''));

            payload.configuration = struct();
            payload.configuration.Nx = RunArtifactsManager.safe_number(Parameters, 'Nx', NaN);
            payload.configuration.Ny = RunArtifactsManager.safe_number(Parameters, 'Ny', NaN);
            payload.configuration.dt = RunArtifactsManager.safe_number(Parameters, 'dt', NaN);
            payload.configuration.Tfinal = RunArtifactsManager.safe_number(Parameters, 'Tfinal', NaN);
            payload.configuration.nu = RunArtifactsManager.safe_number(Parameters, 'nu', NaN);
            payload.configuration.output_root = RunArtifactsManager.safe_field(Parameters, 'output_root', 'Results');

            payload.metrics = struct();
            payload.metrics.wall_time_s = RunArtifactsManager.safe_number_multi(Results, {'wall_time', 'total_time', 'wall_time_s'});
            payload.metrics.total_steps = RunArtifactsManager.safe_number(Results, 'total_steps', NaN);
            payload.metrics.max_omega = RunArtifactsManager.safe_number(Results, 'max_omega', NaN);
            payload.metrics.final_energy = RunArtifactsManager.safe_number(Results, 'final_energy', NaN);
            payload.metrics.final_enstrophy = RunArtifactsManager.safe_number(Results, 'final_enstrophy', NaN);
            payload.metrics.status = RunArtifactsManager.safe_field(Results, 'status', 'completed');

            payload.paths = struct();
            payload.paths.base = RunArtifactsManager.safe_field(paths, 'base', '');
            payload.paths.data = RunArtifactsManager.safe_field(paths, 'data', '');
            payload.paths.figures_root = RunArtifactsManager.safe_field(paths, 'figures_root', '');
            payload.paths.media = RunArtifactsManager.safe_field(paths, 'media', '');
            payload.paths.reports = RunArtifactsManager.safe_field(paths, 'reports', '');
            payload.paths.logs = RunArtifactsManager.safe_field(paths, 'logs', '');
        end

        function out = compact_struct(in_struct)
            out = struct();
            if ~isstruct(in_struct)
                return;
            end

            fields = fieldnames(in_struct);
            for i = 1:numel(fields)
                key = fields{i};
                value = in_struct.(key);
                if isstruct(value)
                    out.(key) = RunArtifactsManager.compact_struct(value);
                elseif isstring(value) || ischar(value) || islogical(value)
                    out.(key) = value;
                elseif isnumeric(value)
                    if isscalar(value)
                        out.(key) = value;
                    elseif numel(value) <= 16
                        out.(key) = value;
                    else
                        out.(key) = sprintf('[numeric %s]', mat2str(size(value)));
                    end
                elseif iscell(value)
                    out.(key) = sprintf('[cell %s]', mat2str(size(value)));
                else
                    out.(key) = sprintf('[%s]', class(value));
                end
            end
        end

        function value = safe_field(s, field_name, default_value)
            value = default_value;
            if isstruct(s) && isfield(s, field_name) && ~isempty(s.(field_name))
                value = s.(field_name);
            end
        end

        function value = safe_number(s, field_name, default_value)
            value = default_value;
            if isstruct(s) && isfield(s, field_name)
                candidate = s.(field_name);
                if isnumeric(candidate) && isscalar(candidate)
                    value = candidate;
                end
            end
        end

        function value = safe_number_multi(s, fields)
            value = NaN;
            for i = 1:numel(fields)
                value = RunArtifactsManager.safe_number(s, fields{i}, NaN);
                if ~isnan(value)
                    return;
                end
            end
        end

        function write_json(path_str, payload)
            encoded = jsonencode(payload);
            fid = fopen(path_str, 'w');
            if fid == -1
                error('RunArtifactsManager:WriteFailed', 'Could not write JSON: %s', path_str);
            end
            fprintf(fid, '%s', encoded);
            fclose(fid);
        end

        function out = upper_first(in)
            token = char(string(in));
            if isempty(token)
                out = token;
                return;
            end
            out = [upper(token(1)), token(2:end)];
        end
    end
end
