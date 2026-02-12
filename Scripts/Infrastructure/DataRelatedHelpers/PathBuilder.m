classdef PathBuilder
    % PathBuilder - Canonical run-path contract for Results artifacts.
    %
    % This class defines the repository-wide output layout:
    %   Results/<Method>/<Mode>/<RunId>/
    %       Config/
    %       Data/
    %       Figures/
    %       Media/
    %       Reports/
    %       Logs/
    %       Sustainability/

    methods (Static)
        function paths = get_run_paths(method, mode, identifier, varargin)
            % get_run_paths - Build full directory map for one run/study.
            %
            % Inputs:
            %   method     - user-facing token (FD/Spectral/FV/Bathymetry/...)
            %   mode       - user-facing token (Evolution/Convergence/...)
            %   identifier - run_id / study_id / plotting job id
            %
            % Optional:
            %   output_root (default "Results")

            if nargin >= 4 && ~isempty(varargin{1})
                output_root = char(string(varargin{1}));
            else
                output_root = 'Results';
            end

            repo_root = PathBuilder.get_repo_root();
            results_root = fullfile(repo_root, output_root);
            method_token = PathBuilder.normalize_method_token(method);
            mode_token = PathBuilder.normalize_mode_token(mode);

            if strcmpi(mode_token, 'Evolution')
                % Evolution runs are one-off executions stored under a shared mode root.
                base_path = fullfile(results_root, method_token, mode_token);
            else
                % Study modes retain per-run/per-study subdirectories.
                base_path = fullfile(results_root, method_token, mode_token, identifier);
            end

            paths = struct();
            paths.repo_root = repo_root;
            paths.output_root = output_root;
            paths.results_root = results_root;
            paths.base = base_path;
            paths.method = method_token;
            paths.mode = mode_token;
            paths.identifier = identifier;

            % Canonical sub-tree used by all modes.
            paths.config = fullfile(base_path, 'Config');
            paths.data = fullfile(base_path, 'Data');
            paths.figures_root = fullfile(base_path, 'Figures');
            paths.media = fullfile(base_path, 'Media');
            paths.reports = fullfile(base_path, 'Reports');
            paths.logs = fullfile(base_path, 'Logs');
            paths.sustainability = fullfile(base_path, 'Sustainability');

            % Common canonical children.
            paths.media_animation = fullfile(paths.media, 'Animation');
            paths.media_frames = fullfile(paths.media, 'Frames');
            paths.logs_runtime = fullfile(paths.logs, 'Runtime');
            paths.logs_status = fullfile(paths.logs, 'Status');

            % Backward-compat aliases.
            paths.figures = paths.figures_root;

            switch upper(mode_token)
                case 'EVOLUTION'
                    paths.figures_evolution = fullfile(paths.figures_root, 'Evolution');
                    paths.figures_contours = fullfile(paths.figures_root, 'Contours');
                    paths.figures_vector = fullfile(paths.figures_root, 'Vector');
                    paths.figures_streamlines = fullfile(paths.figures_root, 'Streamlines');
                    paths.figures_animation = fullfile(paths.figures_root, 'Animation');

                case 'CONVERGENCE'
                    paths.figures_convergence = fullfile(paths.figures_root, 'Convergence');
                    paths.figures_iterations = fullfile(paths.figures_convergence, 'Iterations');
                    paths.figures_refined_meshes = fullfile(paths.figures_convergence, 'Refined Meshes');
                    % Legacy aliases retained for old scripts/readers.
                    paths.evolution = fullfile(paths.figures_root, 'Evolution');
                    paths.mesh_contours = fullfile(paths.figures_root, 'MeshContours');
                    paths.mesh_grids = fullfile(paths.figures_root, 'MeshGrids');
                    paths.mesh_plots = fullfile(paths.figures_root, 'MeshPlots');
                    paths.convergence_metrics = fullfile(paths.figures_root, 'ConvergenceMetrics');

                case 'PARAMETERSWEEP'
                    paths.figures_sweep = fullfile(paths.figures_root, 'ParameterSweep');

                case 'PLOTTING'
                    paths.figures_evolution = fullfile(paths.figures_root, 'Evolution');

                otherwise
                    ErrorHandler.throw('RUN-EXEC-0002', ...
                        'file', 'PathBuilder', ...
                        'line', 92, ...
                        'context', struct( ...
                            'requested_mode', mode, ...
                            'valid_modes', {{'Evolution', 'Convergence', 'ParameterSweep', 'Plotting'}}));
            end
        end

        function ensure_directories(paths)
            % ensure_directories - Idempotently create directory fields.

            fields = fieldnames(paths);
            metadata_fields = { ...
                'repo_root', 'output_root', 'results_root', ...
                'method', 'mode', 'identifier'};

            for i = 1:numel(fields)
                field_name = fields{i};
                if ismember(field_name, metadata_fields)
                    continue;
                end

                target = paths.(field_name);
                if ~(ischar(target) || isstring(target))
                    continue;
                end
                target = char(string(target));
                if isempty(target)
                    continue;
                end

                if ~exist(target, 'dir')
                    try
                        mkdir(target);
                    catch ME
                        ErrorHandler.throw('IO-FS-0001', ...
                            'file', 'PathBuilder', ...
                            'line', 128, ...
                            'cause', ME, ...
                            'context', struct('target_directory', target));
                    end
                end
            end
        end

        function [paths, param_path] = add_parameter_dir(paths, param_name)
            % add_parameter_dir - Add dynamic per-parameter folders for sweeps.

            if ~strcmpi(paths.mode, 'ParameterSweep')
                ErrorHandler.throw('RUN-EXEC-0002', ...
                    'file', 'PathBuilder', ...
                    'line', 141, ...
                    'message', 'add_parameter_dir only valid for ParameterSweep mode', ...
                    'context', struct('current_mode', paths.mode));
            end

            param_token = matlab.lang.makeValidName(char(string(param_name)));
            param_path = fullfile(paths.base, 'Data', param_token);
            paths.(param_token) = param_path;

            if ~exist(param_path, 'dir')
                try
                    mkdir(param_path);
                    mkdir(fullfile(param_path, 'Figures'));
                catch ME
                    ErrorHandler.throw('IO-FS-0001', ...
                        'file', 'PathBuilder', ...
                        'line', 157, ...
                        'cause', ME, ...
                        'context', struct('target_directory', param_path));
                end
            end
        end

        function root = get_repo_root()
            % get_repo_root - Locate repository root from this class path.

            current = fileparts(mfilename('fullpath'));
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

            % Conservative fallback from Scripts/Infrastructure/DataRelatedHelpers.
            root = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');
        end

        function master_table_path = get_master_table_path()
            % get_master_table_path - Path to consolidated runs CSV.
            repo_root = PathBuilder.get_repo_root();
            master_table_path = fullfile(repo_root, 'Results', 'Runs_Table.csv');
        end
    end

    methods (Static, Access = private)
        function token = normalize_method_token(raw_method)
            token = upper(strtrim(char(string(raw_method))));
            token = regexprep(token, '[\s_-]+', ' ');
            switch token
                case {'FD', 'FINITE DIFFERENCE', 'FINITE DIFFERENTIAL', 'FINITE_DIFFERENCE'}
                    token = 'FD';
                case {'SPECTRAL', 'FFT', 'PSEUDOSPECTRAL', 'PSEUDO SPECTRAL'}
                    token = 'Spectral';
                case {'FV', 'FINITE VOLUME', 'FINITE_VOLUME'}
                    token = 'FV';
                case {'BATHYMETRY', 'VARIABLE BATHYMETRY'}
                    token = 'Bathymetry';
                case {'PLOTTING'}
                    token = 'Plotting';
                otherwise
                    token = regexprep(token, '\s+', '');
            end
        end

        function token = normalize_mode_token(raw_mode)
            token = lower(strtrim(char(string(raw_mode))));
            token = regexprep(token, '[\s_-]+', '');
            switch token
                case {'evolution', 'evolve', 'solve'}
                    token = 'Evolution';
                case {'convergence', 'converge', 'mesh'}
                    token = 'Convergence';
                case {'parametersweep', 'sweep', 'paramsweep'}
                    token = 'ParameterSweep';
                case {'plotting', 'plot', 'visualization', 'visualise'}
                    token = 'Plotting';
                otherwise
                    token = char(string(raw_mode));
            end
        end
    end
end
