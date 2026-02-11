classdef SystemProfileCollector
    % SystemProfileCollector - Gather machine metadata and collector status.

    methods (Static)
        function profile = collect(Settings)
            profile = struct();
            profile.timestamp_utc = char(datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z'''));
            profile.machine_id = SystemProfileCollector.resolve_machine_id(Settings);
            profile.machine_label = SystemProfileCollector.resolve_machine_label(Settings, profile.machine_id);
            profile.hostname = SystemProfileCollector.first_nonempty({getenv('COMPUTERNAME'), getenv('HOSTNAME')}, 'unknown_host');
            profile.os = SystemProfileCollector.resolve_os();
            profile.matlab_version = version;
            profile.matlab_release = char(version('-release'));
            profile.cpu_arch = computer('arch');
            profile.cpu_cores = feature('numcores');
            profile.ram_total_gb = SystemProfileCollector.get_total_ram_gb();

            collectors = SystemProfileCollector.resolve_collectors(Settings);
            profile.collectors = collectors;
            profile.source_quality = SystemProfileCollector.source_quality(collectors);
        end
    end

    methods (Static, Access = private)
        function machine_id = resolve_machine_id(Settings)
            requested = '';
            if isfield(Settings, 'sustainability') && isfield(Settings.sustainability, 'machine_id')
                requested = char(string(Settings.sustainability.machine_id));
            end
            if isempty(requested) || strcmpi(requested, 'auto')
                machine_id = SystemProfileCollector.first_nonempty( ...
                    {getenv('COMPUTERNAME'), getenv('HOSTNAME')}, ...
                    'unknown_machine');
            else
                machine_id = requested;
            end
        end

        function machine_label = resolve_machine_label(Settings, machine_id)
            machine_label = '';
            if isfield(Settings, 'sustainability') && isfield(Settings.sustainability, 'machine_label')
                machine_label = char(string(Settings.sustainability.machine_label));
            end
            if isempty(machine_label)
                machine_label = machine_id;
            end
        end

        function os_name = resolve_os()
            if ispc
                os_name = 'Windows';
            elseif ismac
                os_name = 'macOS';
            elseif isunix
                os_name = 'Linux';
            else
                os_name = 'Unknown';
            end
        end

        function ram_gb = get_total_ram_gb()
            ram_gb = NaN;
            if ispc
                try
                    mem = memory;
                    ram_gb = mem.MaxPossibleArrayBytes / 1024 / 1024 / 1024;
                catch
                    ram_gb = NaN;
                end
            end
        end

        function collectors = resolve_collectors(Settings)
            collectors = struct();
            collectors.matlab = true;
            collectors.cpuz = false;
            collectors.hwinfo = false;
            collectors.icue = false;
            collectors.cpuz_source = '';
            collectors.hwinfo_source = '';
            collectors.icue_source = '';

            if ~isfield(Settings, 'sustainability') || ~isstruct(Settings.sustainability)
                return;
            end

            if isfield(Settings.sustainability, 'external_collectors')
                flags = Settings.sustainability.external_collectors;
                if isfield(flags, 'cpuz'), collectors.cpuz = logical(flags.cpuz); end
                if isfield(flags, 'hwinfo'), collectors.hwinfo = logical(flags.hwinfo); end
                if isfield(flags, 'icue'), collectors.icue = logical(flags.icue); end
            end

            if isfield(Settings.sustainability, 'collector_paths')
                paths = Settings.sustainability.collector_paths;
                [collectors.cpuz, collectors.cpuz_source] = ...
                    SystemProfileCollector.check_collector_path(paths, 'cpuz', collectors.cpuz);
                [collectors.hwinfo, collectors.hwinfo_source] = ...
                    SystemProfileCollector.check_collector_path(paths, 'hwinfo', collectors.hwinfo);
                [collectors.icue, collectors.icue_source] = ...
                    SystemProfileCollector.check_collector_path(paths, 'icue', collectors.icue);
            end
        end

        function [enabled, source_path] = check_collector_path(path_struct, field_name, default_enabled)
            enabled = default_enabled;
            source_path = '';
            if isfield(path_struct, field_name)
                candidate = char(string(path_struct.(field_name)));
                if ~isempty(candidate)
                    if exist(candidate, 'file')
                        enabled = true;
                        source_path = candidate;
                    else
                        enabled = false;
                    end
                end
            end
        end

        function quality = source_quality(collectors)
            if collectors.cpuz || collectors.hwinfo || collectors.icue
                quality = 'enriched_external_collectors';
            else
                quality = 'baseline_matlab_only';
            end
        end

        function out = first_nonempty(candidates, fallback)
            out = fallback;
            for i = 1:numel(candidates)
                candidate = char(string(candidates{i}));
                if ~isempty(candidate)
                    out = candidate;
                    return;
                end
            end
        end
    end
end
