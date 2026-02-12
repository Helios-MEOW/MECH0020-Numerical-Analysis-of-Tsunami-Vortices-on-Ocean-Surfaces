classdef ExternalCollectorAdapters
    % ExternalCollectorAdapters - Probe/extraction adapters for external monitors.
    %
    % Supported sources:
    %   - cpuz
    %   - hwinfo
    %   - icue

    methods (Static)
        function snapshot = extract_snapshot(source, enabled, preferred_path)
            source_token = lower(char(string(source)));
            snapshot = struct();
            snapshot.source = source_token;
            snapshot.enabled = logical(enabled);
            snapshot.available = false;
            snapshot.path = '';
            snapshot.status = 'disabled';
            snapshot.message = 'collector disabled';
            snapshot.version = '';
            snapshot.timestamp_utc = char(datetime('now', 'TimeZone', 'UTC', ...
                'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z'''));

            if ~snapshot.enabled
                return;
            end

            candidates = ExternalCollectorAdapters.collect_candidates(source_token, preferred_path);
            if isempty(candidates)
                snapshot.status = 'not_configured';
                snapshot.message = 'no candidate paths available';
                return;
            end

            for i = 1:numel(candidates)
                candidate = char(string(candidates{i}));
                if isempty(candidate)
                    continue;
                end
                if exist(candidate, 'file') == 2
                    snapshot.available = true;
                    snapshot.path = candidate;
                    snapshot.status = 'connected';
                    snapshot.message = 'collector executable found';
                    snapshot.version = ExternalCollectorAdapters.read_file_version(candidate);
                    return;
                end
            end

            snapshot.available = false;
            snapshot.path = char(string(candidates{1}));
            snapshot.status = 'not_found';
            snapshot.message = 'collector executable not found';
        end

        function [available, resolved_path, status] = probe(source, enabled, preferred_path)
            snapshot = ExternalCollectorAdapters.extract_snapshot(source, enabled, preferred_path);
            available = snapshot.available;
            resolved_path = snapshot.path;
            status = snapshot.status;
        end

        function paths = default_paths(source)
            switch lower(char(string(source)))
                case 'cpuz'
                    paths = { ...
                        'C:\Program Files\CPUID\CPU-Z\cpuz.exe', ...
                        'C:\Program Files (x86)\CPUID\CPU-Z\cpuz.exe' ...
                    };
                case 'hwinfo'
                    paths = { ...
                        'C:\Program Files\HWiNFO64\HWiNFO64.exe', ...
                        'C:\Program Files\HWiNFO32\HWiNFO32.exe', ...
                        'C:\Program Files\HWiNFO\HWiNFO.exe' ...
                    };
                case 'icue'
                    paths = { ...
                        'C:\Program Files\CORSAIR\CORSAIR iCUE 4 Software\iCUE.exe', ...
                        'C:\Program Files\Corsair\CORSAIR iCUE 3 Software\iCUE.exe', ...
                        'C:\Program Files\Corsair\CORSAIR iCUE Software\iCUE.exe' ...
                    };
                otherwise
                    paths = {};
            end
        end
    end

    methods (Static, Access = private)
        function candidates = collect_candidates(source_token, preferred_path)
            candidates = {};

            preferred_cells = ExternalCollectorAdapters.normalize_path_input(preferred_path);
            for i = 1:numel(preferred_cells)
                token = char(string(preferred_cells{i}));
                if ~isempty(token)
                    candidates{end + 1} = token; %#ok<AGROW>
                end
            end

            defaults = ExternalCollectorAdapters.default_paths(source_token);
            for i = 1:numel(defaults)
                token = char(string(defaults{i}));
                if isempty(token)
                    continue;
                end
                if ~any(strcmpi(candidates, token))
                    candidates{end + 1} = token; %#ok<AGROW>
                end
            end
        end

        function cells = normalize_path_input(path_input)
            cells = {};
            if nargin < 1 || isempty(path_input)
                return;
            end
            if ischar(path_input) || isstring(path_input)
                token = char(string(path_input));
                if ~isempty(token)
                    cells = {token};
                end
                return;
            end
            if iscell(path_input)
                cells = path_input(:).';
            end
        end

        function version = read_file_version(path_str)
            version = '';
            if ~ispc
                return;
            end
            try
                info = System.Diagnostics.FileVersionInfo.GetVersionInfo(path_str);
                version = char(string(info.FileVersion));
            catch
                version = '';
            end
        end
    end
end
