function State = fv_step(State, ~, ~)
    % fv_step - Advance FV solution by one time step
    %
    % Purpose:
    %   Performs single time step for FV method
    %   Currently a STUB - not fully implemented
    %
    % Status: ⚠️ STUB - throws SOL-FV-0001 error

    ErrorHandler.throw('SOL-FV-0001', ...
        'file', mfilename, ...
        'line', 12, ...
        'message', 'Finite Volume method is not yet implemented.', ...
        'context', struct('requested_method', 'FiniteVolume'));
end
