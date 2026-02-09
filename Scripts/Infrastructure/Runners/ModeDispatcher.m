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

    method = upper(Run_Config.method);
    mode = Run_Config.mode;

    % Normalize mode name
    mode_normalized = normalize_mode_name(mode);

    % Route to appropriate method/mode handler with structured error handling
    try
        switch method
            case 'FD'
                [Results, paths] = dispatch_FD_mode(mode_normalized, Run_Config, Parameters, Settings);

            case {'FFT', 'SPECTRAL'}
                % Spectral method not implemented - use structured error
                ErrorHandler.throw('SOL-SP-0001', ...
                    'file', mfilename, ...
                    'line', 50, ...
                    'context', struct('requested_method', method));

            case 'FV'
                % Finite Volume not implemented - use structured error
                ErrorHandler.throw('SOL-FV-0001', ...
                    'file', mfilename, ...
                    'line', 56, ...
                    'context', struct('requested_method', method));

            otherwise
                % Unknown method - use structured error
                ErrorHandler.throw('RUN-EXEC-0001', ...
                    'file', mfilename, ...
                    'line', 62, ...
                    'context', struct('requested_method', method, 'valid_methods', {{'FD', 'Spectral', 'FV'}}));
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
                'line', 78, ...
                'cause', ME, ...
                'context', struct('method', method, 'mode', mode));
        end
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
