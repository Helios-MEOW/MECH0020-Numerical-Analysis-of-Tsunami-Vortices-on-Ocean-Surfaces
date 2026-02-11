function test_architecture_compliance()
    % test_architecture_compliance - Verify method-agnostic architecture rules
    %
    % Purpose:
    %   Ensures repository complies with strict architectural rules:
    %   1. Exactly N mode scripts (one per mode) in Scripts/Modes/ tree
    %   2. NO mode-per-method files (no FD_Evolution, Spectral_Convergence, etc.)
    %   3. Each method has one self-contained script entrypoint
    %   4. Tsunami_Vorticity_Emulator exists as single driver entry point
    %   5. compatibility_matrix exists
    %
    % Usage:
    %   test_architecture_compliance()
    %
    % Exit codes:
    %   0 - All tests passed
    %   1 - One or more tests failed

    fprintf('\n');
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  ARCHITECTURE COMPLIANCE TEST\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');

    % Add Scripts to path for compatibility_matrix
    addpath(genpath('Scripts'));

    test_count = 0;
    pass_count = 0;
    fail_count = 0;

    % ===== TEST 1: Mode scripts exist and are method-agnostic =====
    test_count = test_count + 1;
    fprintf('[TEST %d] Checking mode scripts existence...\n', test_count);

    required_mode_paths = {
        fullfile('Scripts', 'Modes', 'mode_evolution.m'), ...
        fullfile('Scripts', 'Modes', 'Convergence', 'mode_convergence.m'), ...
        fullfile('Scripts', 'Modes', 'mode_parameter_sweep.m'), ...
        fullfile('Scripts', 'Modes', 'mode_plotting.m')
    };

    modes_ok = true;
    for k = 1:length(required_mode_paths)
        mode_file = required_mode_paths{k};
        if ~exist(mode_file, 'file')
            fprintf('  ✗ FAIL: %s not found\n', mode_file);
            modes_ok = false;
        else
            [~, mode_name, mode_ext] = fileparts(mode_file);
            fprintf('  ✓ PASS: %s%s exists\n', mode_name, mode_ext);
        end
    end

    if modes_ok
        pass_count = pass_count + 1;
        fprintf('  → Test PASSED: All mode scripts exist\n\n');
    else
        fail_count = fail_count + 1;
        fprintf('  → Test FAILED: Missing mode scripts\n\n');
    end

    % ===== TEST 2: NO mode-per-method files =====
    test_count = test_count + 1;
    fprintf('[TEST %d] Checking for mode-per-method files (should NOT exist)...\n', test_count);

    % Search for files like FD_Evolution, Spectral_Convergence, etc.
    forbidden_patterns = {'FD_*_Mode.m', 'Spectral_*_Mode.m', 'FV_*_Mode.m'};
    forbidden_found = false;

    for k = 1:length(forbidden_patterns)
        files = dir(fullfile('Scripts', '**', forbidden_patterns{k}));
        % Exclude legacy_fd directory
        files = files(~contains({files.folder}, 'legacy_fd'));

        if ~isempty(files)
            fprintf('  ✗ FAIL: Found forbidden file(s) matching %s:\n', forbidden_patterns{k});
            for f = 1:length(files)
                fprintf('    - %s\n', fullfile(files(f).folder, files(f).name));
            end
            forbidden_found = true;
        end
    end

    if ~forbidden_found
        fprintf('  ✓ PASS: No mode-per-method files found (except in legacy_fd/)\n');
        fprintf('  → Test PASSED: Architecture rule enforced\n\n');
        pass_count = pass_count + 1;
    else
        fprintf('  → Test FAILED: Mode-per-method files exist (violates architecture)\n\n');
        fail_count = fail_count + 1;
    end

    % ===== TEST 3: Method entrypoints exist =====
    test_count = test_count + 1;
    fprintf('[TEST %d] Checking single-script method modules...\n', test_count);

    method_entrypoints = {
        'Scripts/Methods/FiniteDifference/FiniteDifferenceMethod.m', ...
        'Scripts/Methods/Spectral/SpectralMethod.m', ...
        'Scripts/Methods/FiniteVolume/FiniteVolumeMethod.m'
    };

    entrypoints_ok = true;
    for k = 1:length(method_entrypoints)
        if ~exist(method_entrypoints{k}, 'file')
            fprintf('  ✗ FAIL: %s not found\n', method_entrypoints{k});
            entrypoints_ok = false;
        end
    end

    if entrypoints_ok
        fprintf('  ✓ PASS: All method modules exist\n');
        fprintf('  → Test PASSED: one-script-per-method rule satisfied\n\n');
        pass_count = pass_count + 1;
    else
        fprintf('  → Test FAILED: Missing method module(s)\n\n');
        fail_count = fail_count + 1;
    end

    % ===== TEST 4: Tsunami_Vorticity_Emulator exists =====
    test_count = test_count + 1;
    fprintf('[TEST %d] Checking Tsunami_Vorticity_Emulator entry point...\n', test_count);

    driver_files = dir(fullfile('Scripts', 'Drivers', '*.m'));
    driver_names = {driver_files.name};
    has_entry = any(strcmp(driver_names, 'Tsunami_Vorticity_Emulator.m'));
    has_single_driver = numel(driver_files) == 1;

    if has_entry && has_single_driver
        fprintf('  ✓ PASS: Tsunami_Vorticity_Emulator.m exists and is the only driver file\n');
        fprintf('  → Test PASSED: Single entry point available\n\n');
        pass_count = pass_count + 1;
    else
        if ~has_entry
            fprintf('  ✗ FAIL: Tsunami_Vorticity_Emulator.m not found\n');
        end
        if ~has_single_driver
            fprintf('  ✗ FAIL: Scripts/Drivers contains %d .m files (expected 1)\n', numel(driver_files));
            fprintf('          Files: %s\n', strjoin(driver_names, ', '));
        end
        fprintf('  → Test FAILED: Driver layout violates single-entrypoint rule\n\n');
        fail_count = fail_count + 1;
    end

    % ===== TEST 5: Compatibility matrix exists =====
    test_count = test_count + 1;
    fprintf('[TEST %d] Checking compatibility matrix...\n', test_count);

    if exist('Scripts/Infrastructure/Compatibility/compatibility_matrix.m', 'file')
        fprintf('  ✓ PASS: compatibility_matrix.m exists\n');

        % Test that it works
        try
            [status, reason] = compatibility_matrix('FD', 'Evolution');
            if strcmp(status, 'supported')
                fprintf('  ✓ PASS: compatibility_matrix returns valid results\n');
                fprintf('  → Test PASSED: Compatibility matrix functional\n\n');
                pass_count = pass_count + 1;
            else
                fprintf('  ✗ FAIL: unexpected status for FD+Evolution: %s\n', status);
                fprintf('  → Test FAILED\n\n');
                fail_count = fail_count + 1;
            end
        catch ME
            fprintf('  ✗ FAIL: compatibility_matrix error: %s\n', ME.message);
            fprintf('  → Test FAILED\n\n');
            fail_count = fail_count + 1;
        end
    else
        fprintf('  ✗ FAIL: compatibility_matrix.m not found\n');
        fprintf('  → Test FAILED\n\n');
        fail_count = fail_count + 1;
    end

    % ===== SUMMARY =====
    fprintf('═══════════════════════════════════════════════════════════════\n');
    fprintf('  SUMMARY\n');
    fprintf('═══════════════════════════════════════════════════════════════\n\n');

    fprintf('Total tests:  %d\n', test_count);
    fprintf('Passed:       %d\n', pass_count);
    fprintf('Failed:       %d\n\n', fail_count);

    if fail_count == 0
        fprintf('✅ ALL ARCHITECTURE TESTS PASSED\n');
        fprintf('Architecture complies with method-agnostic design.\n\n');
        exit_code = 0;
    else
        fprintf('❌ ARCHITECTURE TESTS FAILED\n');
        fprintf('Fix violations before proceeding.\n\n');
        exit_code = 1;
    end

    % Return exit code (NO exit call - it terminates MATLAB)
    fprintf('Exit code: %d\n\n', exit_code);
    if exit_code ~= 0
        warning('MECH0020:ArchitectureViolation', 'Architecture tests failed. Exit code: %d', exit_code);
    end
end
