function [fig_handle, analysis] = run_simulation_with_method(Parameters)
% RUN_SIMULATION_WITH_METHOD Method dispatcher for numerical simulations
%
% This function routes simulation calls to the appropriate numerical method
% based on Parameters.method field, providing a seamless interface for all methods.
%
% Usage:
%   [fig_handle, analysis] = run_simulation_with_method(Parameters)
%
% Input:
%   Parameters - struct with 'method' field specifying which solver to use:
%       'finite_difference' or 'fd'         -> Finite_Difference_Analysis
%       'spectral' or 'fft'                 -> Spectral_Analysis (with wrapper)
%       'finite_volume' or 'fv'             -> Finite_Volume_Analysis (pending)
%       'bathymetry' or 'variable_bathymetry' -> Variable_Bathymetry_Analysis (pending)
%
% Output:
%   fig_handle - handle to generated figure
%   analysis   - struct with results (omega_snaps, psi_snaps, metrics, etc.)
%
% Author: Method Dispatcher Framework
% Date: February 2026

    % Normalize method name
    if isstring(Parameters.method) || ischar(Parameters.method)
        method_normalized = lower(char(Parameters.method));
    else
        method_normalized = 'finite_difference';  % Default
    end
    
    % Route to appropriate solver
    switch method_normalized
        case {'fd', 'finite_difference', 'finite difference'}
            fprintf('[Dispatcher] Routing to Finite Difference method\n');
            [fig_handle, analysis] = Finite_Difference_Analysis(Parameters);
            
        case {'spectral', 'fft', 'pseudospectral'}
            fprintf('[Dispatcher] Routing to Spectral (FFT) method\n');
            [fig_handle, analysis] = Spectral_Analysis(Parameters);
            
        case {'fv', 'finite_volume', 'finite volume'}
            fprintf('[Dispatcher] Routing to Finite Volume method\n');
            if exist('Finite_Volume_Analysis.m', 'file') == 2
                [fig_handle, analysis] = Finite_Volume_Analysis(Parameters);
            else
                warning('Finite_Volume_Analysis.m not found. Falling back to Finite Difference.');
                [fig_handle, analysis] = Finite_Difference_Analysis(Parameters);
            end
            
        case {'bathymetry', 'variable_bathymetry', 'variable bathymetry'}
            fprintf('[Dispatcher] Routing to Variable Bathymetry method\n');
            if exist('Variable_Bathymetry_Analysis.m', 'file') == 2
                [fig_handle, analysis] = Variable_Bathymetry_Analysis(Parameters);
            else
                warning('Variable_Bathymetry_Analysis.m not found. Falling back to Finite Difference.');
                [fig_handle, analysis] = Finite_Difference_Analysis(Parameters);
            end
            
        otherwise
            warning('Unknown method: %s. Using Finite Difference as default.', method_normalized);
            [fig_handle, analysis] = Finite_Difference_Analysis(Parameters);
    end
    
    % Ensure analysis struct has method field for tracking
    if ~isfield(analysis, 'method')
        analysis.method = method_normalized;
    end
end
