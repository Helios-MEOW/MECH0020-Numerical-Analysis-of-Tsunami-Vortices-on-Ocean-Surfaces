function [Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings)
    % ModeDispatcher - Central dispatcher for all methods and modes
    %
    % Purpose:
    %   Single entry point to route runs to appropriate mode modules
    %   Enforces method/mode compatibility
    %   Provides consistent interface across all methods
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
        error('ModeDispatcher:MissingMethod', 'Run_Config.method is required');
    end
    if ~isfield(Run_Config, 'mode')
        error('ModeDispatcher:MissingMode', 'Run_Config.mode is required');
    end
    
    method = upper(Run_Config.method);
    mode = Run_Config.mode;
    
    % Normalize mode name
    mode_normalized = normalize_mode_name(mode);
    
    % Route to appropriate method/mode handler
    switch method
        case 'FD'
            [Results, paths] = dispatch_FD_mode(mode_normalized, Run_Config, Parameters, Settings);
            
        case {'FFT', 'SPECTRAL'}
            % Future: Spectral method modes
            error('ModeDispatcher:NotImplemented', 'Spectral method not yet implemented');
            
        case 'FV'
            % Future: Finite Volume modes
            error('ModeDispatcher:NotImplemented', 'Finite Volume method not yet implemented');
            
        otherwise
            error('ModeDispatcher:UnknownMethod', 'Unknown method: %s', method);
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
    
    % Update Run_Config with normalized mode
    Run_Config.mode = mode;
    
    switch mode
        case 'Evolution'
            [Results, paths] = FD_Evolution_Mode(Run_Config, Parameters, Settings);
            
        case 'Convergence'
            [Results, paths] = FD_Convergence_Mode(Run_Config, Parameters, Settings);
            
        case 'ParameterSweep'
            [Results, paths] = FD_ParameterSweep_Mode(Run_Config, Parameters, Settings);
            
        case 'Plotting'
            [Results, paths] = FD_Plotting_Mode(Run_Config, Parameters, Settings);
            
        otherwise
            error('ModeDispatcher:InvalidFDMode', ...
                'Invalid FD mode: %s. Valid modes: Evolution, Convergence, ParameterSweep, Plotting', mode);
    end
end
