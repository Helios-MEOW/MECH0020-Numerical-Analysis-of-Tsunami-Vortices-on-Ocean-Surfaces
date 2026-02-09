function Metrics = fv_diagnostics(State, cfg, ctx)
    % fv_diagnostics - Compute diagnostic metrics for FV method
    %
    % Purpose:
    %   Extracts diagnostic metrics from FV state
    %   Currently a STUB - not fully implemented
    %
    % Status: ⚠️ STUB - throws SOL-FV-0001 error

    ErrorHandler.throw('SOL-FV-0001', ...
        'file', mfilename, ...
        'line', 12, ...
        'message', 'Finite Volume method is not yet implemented.', ...
        'context', struct('requested_method', 'FiniteVolume'));
end
