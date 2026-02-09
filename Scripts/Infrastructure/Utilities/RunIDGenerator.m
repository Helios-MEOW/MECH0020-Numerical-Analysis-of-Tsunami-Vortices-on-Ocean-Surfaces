classdef RunIDGenerator
    % RunIDGenerator - Generate unique, reproducible run identifiers
    %
    % Purpose:
    %   Create run IDs that encode method, mode, IC, and key parameters
    %   Support "recreate from PNG" workflow via parseable format
    %
    % Format: <timestamp>_<method>_<mode>_<IC>_<grid>_<dt>_<hash>
    % Example: 20260206T153042Z_FD_Evolution_LambOseen_g256_dt1e-3_hA1B2
    %
    % Usage:
    %   run_id = RunIDGenerator.generate(Run_Config, Parameters);
    %   config_info = RunIDGenerator.parse(run_id);
    
    methods (Static)
        function run_id = generate(Run_Config, Parameters)
            % Generate unique run ID from configuration
            
            % Timestamp (UTC ISO 8601 basic format)
            timestamp = datestr(datetime('now', 'TimeZone', 'UTC'), 'yyyymmddTHHMMSS');
            timestamp = [timestamp 'Z'];  % Add UTC marker
            
            % Method and mode
            method = Run_Config.method;
            mode = Run_Config.mode;
            
            % Initial condition
            if isfield(Run_Config, 'ic_type')
                ic = Run_Config.ic_type;
            elseif isfield(Parameters, 'ic_type')
                ic = Parameters.ic_type;
            else
                ic = 'Unknown';
            end
            ic = strrep(ic, ' ', '');  % Remove spaces
            
            % Grid size encoding
            if isfield(Parameters, 'Nx') && isfield(Parameters, 'Ny')
                if Parameters.Nx == Parameters.Ny
                    grid_str = sprintf('g%d', Parameters.Nx);
                else
                    grid_str = sprintf('g%dx%d', Parameters.Nx, Parameters.Ny);
                end
            else
                grid_str = 'gUnknown';
            end
            
            % Timestep encoding
            if isfield(Parameters, 'dt')
                dt_str = sprintf('dt%.0e', Parameters.dt);
                dt_str = strrep(dt_str, 'e-0', 'e-');
                dt_str = strrep(dt_str, 'e+0', 'e');
            else
                dt_str = 'dtUnknown';
            end
            
            % Short hash of full config (for uniqueness)
            config_str = RunIDGenerator.struct_to_string(Run_Config) + ...
                         RunIDGenerator.struct_to_string(Parameters);
            hash_val = mod(RunIDGenerator.hash_string(config_str), 65536);
            hash_str = sprintf('h%04X', hash_val);
            
            % Assemble run ID
            run_id = sprintf('%s_%s_%s_%s_%s_%s_%s', ...
                timestamp, method, mode, ic, grid_str, dt_str, hash_str);
        end
        
        function info = parse(run_id)
            % Parse run_id back into components
            % Returns struct with: timestamp, method, mode, ic, grid, dt, hash
            
            parts = strsplit(run_id, '_');
            info = struct();
            
            if length(parts) >= 7
                info.timestamp = parts{1};
                info.method = parts{2};
                info.mode = parts{3};
                info.ic_type = parts{4};
                info.grid_str = parts{5};
                info.dt_str = parts{6};
                info.hash_str = parts{7};
                
                % Parse grid
                grid_match = regexp(info.grid_str, 'g(\d+)x?(\d*)', 'tokens');
                if ~isempty(grid_match)
                    info.Nx = str2double(grid_match{1}{1});
                    if ~isempty(grid_match{1}{2})
                        info.Ny = str2double(grid_match{1}{2});
                    else
                        info.Ny = info.Nx;
                    end
                end
                
                % Parse dt
                dt_match = regexp(info.dt_str, 'dt([\d.e+-]+)', 'tokens');
                if ~isempty(dt_match)
                    info.dt = str2double(dt_match{1}{1});
                end
            else
                warning('RunIDGenerator:InvalidFormat', 'Could not parse run_id: %s', run_id);
            end
        end
        
        function filename = make_figure_filename(run_id, figure_type, variant)
            % Create standardized figure filename
            % Format: <run_id>__<figure_type>__<variant>.png
            %
            % Example: 20260206T153042Z_FD_Evolution_LambOseen_g256_dt1e-3_hA1B2__contour__t0.5.png
            
            if nargin < 3
                variant = '';
            end
            
            if isempty(variant)
                filename = sprintf('%s__%s.png', run_id, figure_type);
            else
                filename = sprintf('%s__%s__%s.png', run_id, figure_type, variant);
            end
        end
        
        function run_id = extract_from_filename(filename)
            % Extract run_id from figure filename
            % Assumes format: <run_id>__<figure_type>__<variant>.png
            
            [~, name, ~] = fileparts(filename);
            parts = strsplit(name, '__');
            if ~isempty(parts)
                run_id = parts{1};
            else
                run_id = '';
            end
        end
    end
    
    methods (Static, Access = private)
        function str = struct_to_string(s)
            % Convert struct to deterministic string representation
            if ~isstruct(s)
                str = string(s);
                return;
            end
            
            fields = sort(fieldnames(s));
            str = "";  % Use string type (double quotes) for + operator
            for i = 1:length(fields)
                val = s.(fields{i});
                if isnumeric(val)
                    if isscalar(val)
                        str = str + sprintf('%s=%g;', fields{i}, val);
                    else
                        % Arrays: flatten to string representation
                        str = str + sprintf('%s=[%s];', fields{i}, strjoin(string(val(:)'), ','));
                    end
                elseif ischar(val) || isstring(val)
                    str = str + sprintf('%s=%s;', fields{i}, val);
                end
            end
        end
        
        function hash = hash_string(str)
            % Simple hash function for string
            hash = 0;
            for i = 1:min(length(str), 1000)  % Limit to avoid long strings
                hash = mod(hash * 31 + double(str(i)), 2^32);
            end
        end
    end
end
