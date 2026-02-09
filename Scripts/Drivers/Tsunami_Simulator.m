function Tsunami_Simulator()
    % Tsunami_Simulator - SINGLE ENTRY POINT for all tsunami vortex simulations
    %
    % Purpose:
    %   Central driver that dispatches to ONE of the mode scripts
    %   Modes internally select methods via switch/case
    %   This is the ONLY file that should be run by users
    %
    % Architecture:
    %   Driver (Tsunami_Simulator) → Mode (e.g., mode_evolution)
    %                              → Method (e.g., fd_init/step/diagnostics)
    %
    % NO method-specific mode files (no FD_Evolution, Spectral_Convergence, etc.)
    % Each mode script is method-agnostic
    %
    % Usage:
    %   1. Edit Scripts/Editable/Parameters.m and Settings.m
    %   2. Run: Tsunami_Simulator()
    %   3. Follow prompts to select mode and method
    %
    % Modes:
    %   - Evolution: Time evolution simulation
    %   - Convergence: Grid refinement study
    %   - ParameterSweep: Parameter sensitivity study
    %   - Plotting: Visualize existing results
    %
    % Methods:
    %   - FD: Finite Difference (fully supported)
    %   - Spectral: FFT-based (stub only - not yet implemented)
    %   - FV: Finite Volume (stub only - not yet implemented)

    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  MECH0020 TSUNAMI VORTEX SIMULATOR\n');
    fprintf('  Method-Agnostic Mode Architecture\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');

    % ===== LOAD CONFIGURATION =====
    fprintf('[1/4] Loading configuration...\n');

    % Load editable parameters and settings
    Parameters = Parameters();  % From Scripts/Editable/Parameters.m
    Settings = Settings();      % From Scripts/Editable/Settings.m

    % ===== MODE SELECTION =====
    fprintf('\n[2/4] Select Mode:\n');
    fprintf('  1. Evolution        - Time evolution simulation\n');
    fprintf('  2. Convergence      - Grid refinement study\n');
    fprintf('  3. ParameterSweep   - Parameter sensitivity study\n');
    fprintf('  4. Plotting         - Visualize existing results\n');

    mode_choice = input('Enter mode number [1]: ', 's');
    if isempty(mode_choice)
        mode_choice = '1';
    end

    switch mode_choice
        case '1'
            mode_name = 'Evolution';
        case '2'
            mode_name = 'Convergence';
        case '3'
            mode_name = 'ParameterSweep';
        case '4'
            mode_name = 'Plotting';
        otherwise
            error('Invalid mode selection: %s', mode_choice);
    end

    fprintf('Selected mode: %s\n', mode_name);

    % ===== METHOD SELECTION =====
    fprintf('\n[3/4] Select Method:\n');
    fprintf('  1. FD        - Finite Difference (fully supported)\n');
    fprintf('  2. Spectral  - FFT-based (NOT YET IMPLEMENTED)\n');
    fprintf('  3. FV        - Finite Volume (NOT YET IMPLEMENTED)\n');

    method_choice = input('Enter method number [1]: ', 's');
    if isempty(method_choice)
        method_choice = '1';
    end

    switch method_choice
        case '1'
            method_name = 'FD';
        case '2'
            method_name = 'Spectral';
        case '3'
            method_name = 'FV';
        otherwise
            error('Invalid method selection: %s', method_choice);
    end

    fprintf('Selected method: %s\n', method_name);

    % ===== COMPATIBILITY CHECK =====
    fprintf('\n[4/4] Checking compatibility...\n');
    [compat_status, compat_reason] = compatibility_matrix(method_name, mode_name);

    switch lower(compat_status)
        case 'blocked'
            error('INCOMPATIBLE: %s + %s\nReason: %s', method_name, mode_name, compat_reason);
        case 'experimental'
            fprintf('⚠ WARNING: %s + %s is EXPERIMENTAL\n', method_name, mode_name);
            fprintf('Reason: %s\n', compat_reason);
            cont = input('Continue anyway? (Y/N) [N]: ', 's');
            if ~strcmpi(cont, 'y')
                fprintf('Aborted by user.\n');
                return;
            end
        case 'supported'
            fprintf('✓ Compatibility confirmed: %s + %s\n', method_name, mode_name);
    end

    % ===== BUILD RUN_CONFIG =====
    % Default IC type (can be overridden in Parameters.m or below)
    if ~isfield(Parameters, 'ic_type') || isempty(Parameters.ic_type)
        ic_type = 'Lamb-Oseen';
    else
        ic_type = Parameters.ic_type;
    end

    Run_Config = Build_Run_Config(method_name, mode_name, ic_type);

    % ===== DISPATCH TO MODE =====
    fprintf('\n═══════════════════════════════════════════════════════════════\n');
    fprintf('  LAUNCHING: %s + %s\n', method_name, mode_name);
    fprintf('═══════════════════════════════════════════════════════════════\n\n');

    try
        switch lower(mode_name)
            case 'evolution'
                [Results, paths] = mode_evolution(Run_Config, Parameters, Settings);

            case 'convergence'
                [Results, paths] = mode_convergence(Run_Config, Parameters, Settings);

            case 'parametersweep'
                [Results, paths] = mode_parameter_sweep(Run_Config, Parameters, Settings);

            case 'plotting'
                [Results, paths] = mode_plotting(Run_Config, Parameters, Settings);

            otherwise
                error('Unknown mode: %s', mode_name);
        end

        % ===== SUCCESS =====
        fprintf('\n═══════════════════════════════════════════════════════════════\n');
        fprintf('  SIMULATION COMPLETE\n');
        fprintf('═══════════════════════════════════════════════════════════════\n\n');

        fprintf('Run ID:       %s\n', Results.run_id);
        if isfield(Results, 'wall_time')
            fprintf('Wall Time:    %.2f s\n', Results.wall_time);
        end
        if isfield(paths, 'base')
            fprintf('Output Dir:   %s\n', paths.base);
        end
        fprintf('\n');

    catch ME
        % ===== FAILURE =====
        fprintf('\n');
       ErrorHandler.log('ERROR', 'RUN-EXEC-0003', ...
            'message', sprintf('Simulation failed: %s', ME.message), ...
            'file', mfilename, ...
            'context', struct('mode', mode_name, 'method', method_name, ...
                              'error_id', ME.identifier));

        fprintf('\nFull error details:\n');
        fprintf('  Identifier: %s\n', ME.identifier);
        fprintf('  Message:    %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('  Location:   %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        fprintf('\n');

        rethrow(ME);
    end
end
