function [Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings)
    % ModeDispatcher - Central dispatcher for all methods and modes
    %
    % Purpose:
    %   Single entry point to route runs to appropriate mode modules
    %   Enforces method/mode compatibility
    %   Provides consistent interface across all methods
    %   Uses structured error handling with ErrorHandler
    %
    % Inputs:
    %   Run_Config - method, mode, ic_type, identifiers
    %   Parameters - physics + numerics
    %   Settings - IO, monitoring, logging
    %
    % Outputs:
    %   Results - simulation/study results
    %   paths - directory structure
    %
    % Usage:
    %   [Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);

    % Validate required fields
    if ~isfield(Run_Config, 'method')
        ErrorHandler.throw('RUN-EXEC-0001', ...
            'file', mfilename, ...
            'line', 23, ...
            'message', 'Run_Config.method is required but not provided', ...
            'context', struct('Run_Config_fields', fieldnames(Run_Config)));
    end
    if ~isfield(Run_Config, 'mode')
        ErrorHandler.throw('RUN-EXEC-0002', ...
            'file', mfilename, ...
            'line', 29, ...
            'message', 'Run_Config.mode is required but not provided', ...
            'context', struct('Run_Config_fields', fieldnames(Run_Config)));
    end

    method = normalize_method_token(Run_Config.method);
    mode = Run_Config.mode;

    % Normalize mode name
    mode_normalized = normalize_mode_name(mode);

    % Accepted method aliases (cell-based matching)
    fd_aliases = {'FD', 'Finite Difference', 'Finite_Difference', 'FiniteDifference'};
    spectral_aliases = {'Spectral', 'FFT', 'PseudoSpectral', 'Spectral Method'};
    fv_aliases = {'FV', 'Finite Volume', 'Finite_Volume', 'FiniteVolume'};
    spectral3d_aliases = {'3D Spectral', '3D Spectral Method', '3D FFT', 'Spectral 3D', 'FFT 3D'};
    placeholder_aliases = {'Placeholder', 'Placeholder Method', 'TBD', 'To Be Implemented'};

    % Route to appropriate method/mode handler with structured error handling
    try
        if method_matches(method, fd_aliases)
            Run_Config.method = 'FD';
            [Results, paths] = dispatch_FD_mode(mode_normalized, Run_Config, Parameters, Settings);

        elseif method_matches(method, spectral_aliases)
            % Spectral method not implemented - use structured error
            ErrorHandler.throw('SOL-SP-0001', ...
                'file', mfilename, ...
                'line', 57, ...
                'context', struct('requested_method', Run_Config.method));

        elseif method_matches(method, fv_aliases)
            % Finite Volume not implemented - use structured error
            ErrorHandler.throw('SOL-FV-0001', ...
                'file', mfilename, ...
                'line', 64, ...
                'context', struct('requested_method', Run_Config.method));

        elseif method_matches(method, spectral3d_aliases)
            % 3D Spectral method placeholder - use structured error
            ErrorHandler.throw('SOL-SP-0002', ...
                'file', mfilename, ...
                'line', 71, ...
                'context', struct('requested_method', Run_Config.method));

        elseif method_matches(method, placeholder_aliases)
            % Explicit placeholder method path
            ErrorHandler.throw('SOL-PL-0001', ...
                'file', mfilename, ...
                'line', 78, ...
                'context', struct('requested_method', Run_Config.method));

        else
            % Unknown method - use structured error
            ErrorHandler.throw('RUN-EXEC-0001', ...
                'file', mfilename, ...
                'line', 85, ...
                'context', struct( ...
                    'requested_method', Run_Config.method, ...
                    'valid_methods', {{'FD', 'Spectral', 'FV', '3D Spectral', 'Placeholder'}}, ...
                    'fd_aliases', {fd_aliases}, ...
                    'spectral_aliases', {spectral_aliases}, ...
                    'fv_aliases', {fv_aliases}, ...
                    'spectral3d_aliases', {spectral3d_aliases}, ...
                    'placeholder_aliases', {placeholder_aliases}));
        end

        % Ensure downstream artifacts always have a stable run identifier.
        Results = attach_run_identifier(Results, Run_Config);

        % Finalize manifest/report/sustainability artifacts once per run.
        try
            if exist('RunArtifactsManager', 'class') == 8 || exist('RunArtifactsManager', 'file') == 2
                artifact_summary = RunArtifactsManager.finalize(Run_Config, Parameters, Settings, Results, paths);
                Results.artifacts = artifact_summary;
            end
        catch artifact_error
            warning('ModeDispatcher:ArtifactFinalizationFailed', ...
                'Artifact finalization failed: %s', artifact_error.message);
        end

    catch ME
        % Wrap any errors from mode execution with context
        if strcmp(ME.identifier(1:min(3,end)), 'RUN') || strcmp(ME.identifier(1:min(3,end)), 'SOL')
            % Already a structured error, just rethrow
            rethrow(ME);
        else
            % Unexpected error - wrap with structured error
            ErrorHandler.throw('RUN-EXEC-0003', ...
                'file', mfilename, ...
                'line', 101, ...
                'cause', ME, ...
                'context', struct('method', method, 'mode', mode));
        end
    end
end

function Results = attach_run_identifier(Results, Run_Config)
    % Ensure each run has one canonical identifier for reporting/ledger rows.
    if isfield(Results, 'run_id') && ~isempty(Results.run_id)
        return;
    end

    if isfield(Run_Config, 'run_id') && ~isempty(Run_Config.run_id)
        Results.run_id = Run_Config.run_id;
    elseif isfield(Run_Config, 'study_id') && ~isempty(Run_Config.study_id)
        Results.run_id = Run_Config.study_id;
    else
        Results.run_id = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    end
end

function mode_normalized = normalize_mode_name(mode)
    % Normalize mode name to standard format
    mode_lower = lower(mode);
    
    % Map common variations to standard names
    switch mode_lower
        case {'evolution', 'evolve', 'solve'}
            mode_normalized = 'Evolution';
        case {'convergence', 'converge', 'mesh'}
            mode_normalized = 'Convergence';
        case {'parametersweep', 'parameter_sweep', 'sweep', 'param_sweep'}
            mode_normalized = 'ParameterSweep';
        case {'plotting', 'plot', 'visualize', 'visualization'}
            mode_normalized = 'Plotting';
        otherwise
            % Keep original (will error in mode-specific dispatcher)
            mode_normalized = mode;
    end
end

function tf = method_matches(method, aliases)
    % Return true when method matches any alias in the provided cell array
    tf = false;
    for i = 1:numel(aliases)
        if strcmp(method, normalize_method_token(aliases{i}))
            tf = true;
            return;
        end
    end
end

function method_token = normalize_method_token(method_raw)
    % Normalize user-facing method strings for robust alias matching
    if isstring(method_raw) || ischar(method_raw)
        method_token = char(string(method_raw));
    else
        method_token = '';
    end
    method_token = strtrim(method_token);
    method_token = regexprep(method_token, '[\s_-]+', ' ');
    method_token = upper(method_token);
end

function [Results, paths] = dispatch_FD_mode(mode, Run_Config, Parameters, Settings)
    % Dispatch to FD mode modules
    % Enforces FD modes: Evolution, Convergence, ParameterSweep, Plotting
    % Uses method-agnostic mode functions
    % Uses structured error handling

    % Update Run_Config with normalized mode
    Run_Config.mode = mode;

    try
        switch mode
            case 'Evolution'
                [Results, paths] = mode_evolution(Run_Config, Parameters, Settings);

            case 'Convergence'
                [Results, paths] = mode_convergence(Run_Config, Parameters, Settings);

            case 'ParameterSweep'
                [Results, paths] = mode_parameter_sweep(Run_Config, Parameters, Settings);

            case 'Plotting'
                [Results, paths] = mode_plotting(Run_Config, Parameters, Settings);

            otherwise
                % Invalid FD mode - use structured error
                ErrorHandler.throw('RUN-EXEC-0002', ...
                    'file', mfilename, ...
                    'line', 25, ...
                    'context', struct(...
                        'requested_mode', mode, ...
                        'valid_modes', {{'Evolution', 'Convergence', 'ParameterSweep', 'Plotting'}}));
        end

    catch ME
        % Wrap mode execution errors with context
        if contains(ME.identifier, {'RUN', 'SOL', 'CFG', 'IO'})
            % Already a structured error, just rethrow
            rethrow(ME);
        else
            % Unexpected error - wrap
            ErrorHandler.throw('RUN-EXEC-0003', ...
                'file', mfilename, ...
                'line', 41, ...
                'cause', ME, ...
                'context', struct('method', 'FD', 'mode', mode));
        end
    end
end
