classdef PathBuilder
    % PathBuilder - Central path construction and directory creation utility
    %
    % Purpose:
    %   Single source of truth for Results/ directory structure
    %   Creates directories idempotently (no error if already exists)
    %   Enforces FD-compliant structure from MECH0020 spec
    %
    % Usage:
    %   paths = PathBuilder.get_run_paths('FD', 'Evolution', run_id);
    %   PathBuilder.ensure_directories(paths);
    
    methods (Static)
        function paths = get_run_paths(method, mode, identifier)
            % Get complete path structure for a run
            % identifier: run_id for Evolution, study_id for Convergence/ParameterSweep
            
            repo_root = PathBuilder.get_repo_root();
            results_root = fullfile(repo_root, 'Results');
            
            % Base path: Results/<method>/<mode>/<identifier>/
            base_path = fullfile(results_root, method, mode, identifier);
            
            % Initialize paths structure
            paths = struct();
            paths.base = base_path;
            paths.method = method;
            paths.mode = mode;
            paths.identifier = identifier;
            
            % Mode-specific subdirectories (FD spec-compliant)
            switch upper(mode)
                case 'EVOLUTION'
                    paths.figures_evolution = fullfile(base_path, 'Figures', 'Evolution');
                    paths.figures_contours = fullfile(base_path, 'Figures', 'Contours');
                    paths.figures_vector = fullfile(base_path, 'Figures', 'Vector');
                    paths.figures_streamlines = fullfile(base_path, 'Figures', 'Streamlines');
                    paths.figures_animation = fullfile(base_path, 'Figures', 'Animation');
                    paths.reports = fullfile(base_path, 'Reports');
                    paths.data = fullfile(base_path, 'Data');
                    
                case 'CONVERGENCE'
                    paths.evolution = fullfile(base_path, 'Evolution');
                    paths.mesh_contours = fullfile(base_path, 'MeshContours');
                    paths.mesh_grids = fullfile(base_path, 'MeshGrids');
                    paths.mesh_plots = fullfile(base_path, 'MeshPlots');
                    paths.convergence_metrics = fullfile(base_path, 'ConvergenceMetrics');
                    paths.reports = fullfile(base_path, 'Reports');
                    
                case 'PARAMETERSWEEP'
                    paths.reports = fullfile(base_path, 'Reports');
                    paths.data = fullfile(base_path, 'Data');
                    % Parameter-specific subdirectories added dynamically
                    
                case 'PLOTTING'
                    % One directory per figure family
                    paths.base = fullfile(results_root, method, mode);
                    
                otherwise
                    error('PathBuilder:UnknownMode', 'Unknown mode: %s', mode);
            end
        end
        
        function ensure_directories(paths)
            % Create all directories in paths struct idempotently
            fields = fieldnames(paths);
            for i = 1:length(fields)
                field_val = paths.(fields{i});
                if ischar(field_val) || isstring(field_val)
                    if ~exist(field_val, 'dir')
                        mkdir(field_val);
                    end
                end
            end
        end
        
        function add_parameter_dir(paths, param_name)
            % Add parameter-specific directory for ParameterSweep mode
            if ~strcmpi(paths.mode, 'ParameterSweep')
                error('PathBuilder:WrongMode', 'add_parameter_dir only valid for ParameterSweep mode');
            end
            param_path = fullfile(paths.base, param_name);
            paths.(matlab.lang.makeValidName(param_name)) = param_path;
            if ~exist(param_path, 'dir')
                mkdir(param_path);
                mkdir(fullfile(param_path, 'Figures'));
            end
        end
        
        function root = get_repo_root()
            % Find repository root (where .git exists or fallback to mfilename path)
            current = fileparts(mfilename('fullpath'));
            % Navigate up to find repo root
            while ~isempty(current)
                if exist(fullfile(current, '.git'), 'dir') || ...
                   exist(fullfile(current, 'MECH0020_COPILOT_AGENT_SPEC.md'), 'file')
                    root = current;
                    return;
                end
                parent = fileparts(current);
                if strcmp(parent, current)
                    break;
                end
                current = parent;
            end
            % Fallback: assume Scripts/IO location
            root = fullfile(fileparts(mfilename('fullpath')), '..', '..');
        end
        
        function master_table_path = get_master_table_path()
            % Get path to master runs table
            repo_root = PathBuilder.get_repo_root();
            master_table_path = fullfile(repo_root, 'Results', 'Runs_Table.csv');
        end
    end
end
