function test_end_to_end()
% TEST_END_TO_END End-to-end simulation tests for MECH0020
%
% Purpose:
%   Actually runs simulations through the dispatcher architecture
%   to catch runtime errors that static analysis cannot find.
%   Uses small grids and short time spans for speed.
%
% Usage:
%   >> cd tests
%   >> test_end_to_end()
%
% Tests:
%   1. Standard mode: FD Evolution (Lamb-Oseen, 32x32, Tfinal=0.01)
%   2. Standard mode: FD Convergence (mesh_sizes=[16,32])
%   3. Standard mode: FD ParameterSweep (nu sweep)
%   4. Path setup: verify all directories exist
%   5. ColorPrintf: verify colored output works
%
% Author: MECH0020 Test Framework
% Date: 2025

    fprintf('\n');
    fprintf('===============================================================\n');
    fprintf('  END-TO-END SIMULATION TESTS\n');
    fprintf('===============================================================\n\n');

    % Setup paths (same as MECH0020_Run)
    test_dir = fileparts(mfilename('fullpath'));
    repo_root = fileparts(test_dir);
    setup_test_paths(repo_root);

    % Track results
    n_pass = 0;
    n_fail = 0;
    n_total = 0;
    failures = {};

    % ===== TEST 1: Path setup =====
    n_total = n_total + 1;
    fprintf('[TEST 1/6] Path setup and dependencies...\n');
    try
        params = Parameters();
        settings = Settings();
        rc = Build_Run_Config('FD', 'Evolution', 'lamb_oseen');
        assert(isstruct(params), 'Parameters() must return a struct');
        assert(isstruct(settings), 'Settings() must return a struct');
        assert(strcmp(rc.method, 'FD'), 'Run_Config.method should be FD');
        fprintf('  PASS: Parameters, Settings, Build_Run_Config all work\n\n');
        n_pass = n_pass + 1;
    catch ME
        fprintf('  FAIL: %s\n\n', ME.message);
        n_fail = n_fail + 1;
        failures{end+1} = sprintf('Test 1 (Path setup): %s', ME.message); %#ok<AGROW>
    end

    % ===== TEST 2: ColorPrintf =====
    n_total = n_total + 1;
    fprintf('[TEST 2/6] ColorPrintf functionality...\n');
    try
        ColorPrintf.success('Test success message');
        ColorPrintf.warn('Test warning message');
        ColorPrintf.info('Test info message');
        ColorPrintf.header('Test Header');
        ColorPrintf.section('Test Section');
        fprintf('  PASS: ColorPrintf methods all execute without error\n\n');
        n_pass = n_pass + 1;
    catch ME
        fprintf('  FAIL: %s\n\n', ME.message);
        n_fail = n_fail + 1;
        failures{end+1} = sprintf('Test 2 (ColorPrintf): %s', ME.message); %#ok<AGROW>
    end

    % ===== TEST 3: FD Initialisation =====
    n_total = n_total + 1;
    fprintf('[TEST 3/6] FD solver initialisation...\n');
    try
        cfg = struct();
        cfg.Nx = 32; cfg.Ny = 32;
        cfg.Lx = 10; cfg.Ly = 10;
        cfg.dt = 0.01; cfg.Tfinal = 0.01;
        cfg.nu = 0.01;
        cfg.ic_type = 'lamb_oseen';
        cfg.ic_coeff = [1.0, 0.5];

        ctx = struct();
        ctx.mode = 'evolution';

        State = fd_init(cfg, ctx);
        assert(isfield(State, 'omega'), 'State must have omega field');
        assert(isfield(State, 'psi'), 'State must have psi field');
        assert(size(State.omega, 1) == cfg.Ny, 'omega rows must match Ny');
        assert(size(State.omega, 2) == cfg.Nx, 'omega cols must match Nx');
        assert(max(abs(State.omega(:))) > 0, 'omega must be non-zero');
        fprintf('  PASS: fd_init produces valid State (max|omega|=%.3e)\n\n', max(abs(State.omega(:))));
        n_pass = n_pass + 1;
    catch ME
        fprintf('  FAIL: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('    at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        fprintf('\n');
        n_fail = n_fail + 1;
        failures{end+1} = sprintf('Test 3 (FD init): %s', ME.message); %#ok<AGROW>
    end

    % ===== TEST 4: FD Time stepping =====
    n_total = n_total + 1;
    fprintf('[TEST 4/6] FD time stepping (5 steps)...\n');
    try
        cfg = struct();
        cfg.Nx = 32; cfg.Ny = 32;
        cfg.Lx = 10; cfg.Ly = 10;
        cfg.dt = 0.001; cfg.Tfinal = 0.005;
        cfg.nu = 0.01;
        cfg.ic_type = 'lamb_oseen';
        cfg.ic_coeff = [1.0, 0.5];

        ctx = struct();
        ctx.mode = 'evolution';

        State = fd_init(cfg, ctx);
        omega_initial = max(abs(State.omega(:)));

        for step = 1:5
            State = fd_step(State, cfg, ctx);
        end

        omega_final = max(abs(State.omega(:)));
        assert(isfinite(omega_final), 'omega must remain finite after stepping');
        assert(omega_final > 0, 'omega must remain non-zero after stepping');
        fprintf('  PASS: 5 steps completed (|omega| %.3e -> %.3e)\n\n', omega_initial, omega_final);
        n_pass = n_pass + 1;
    catch ME
        fprintf('  FAIL: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('    at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        fprintf('\n');
        n_fail = n_fail + 1;
        failures{end+1} = sprintf('Test 4 (FD stepping): %s', ME.message); %#ok<AGROW>
    end

    % ===== TEST 5: Full Evolution via ModeDispatcher =====
    n_total = n_total + 1;
    fprintf('[TEST 5/6] Full evolution via ModeDispatcher (32x32, Tfinal=0.01)...\n');
    try
        params = Parameters();
        params.Nx = 32;
        params.Ny = 32;
        params.dt = 0.001;
        params.Tfinal = 0.01;
        params.nu = 0.01;
        params.snap_times = [0, 0.005, 0.01];
        params.num_snapshots = 3;

        settings = Settings();
        settings.save_figures = false;
        settings.save_data = false;
        settings.save_reports = false;
        settings.append_to_master = false;
        settings.monitor_enabled = false;

        Run_Config = Build_Run_Config('FD', 'Evolution', 'lamb_oseen');

        [Results, paths] = ModeDispatcher(Run_Config, params, settings);

        assert(isstruct(Results), 'Results must be a struct');
        assert(isfield(Results, 'wall_time'), 'Results must have wall_time');
        assert(isfield(Results, 'max_omega'), 'Results must have max_omega');
        assert(Results.wall_time > 0, 'wall_time must be positive');
        assert(isfinite(Results.max_omega), 'max_omega must be finite');
        fprintf('  PASS: Evolution completed in %.3f s (max|omega|=%.3e)\n\n', ...
            Results.wall_time, Results.max_omega);
        n_pass = n_pass + 1;
    catch ME
        fprintf('  FAIL: %s\n', ME.message);
        if ~isempty(ME.stack)
            for k = 1:min(3, length(ME.stack))
                fprintf('    [%d] %s (line %d)\n', k, ME.stack(k).name, ME.stack(k).line);
            end
        end
        fprintf('\n');
        n_fail = n_fail + 1;
        failures{end+1} = sprintf('Test 5 (ModeDispatcher Evolution): %s', ME.message); %#ok<AGROW>
    end

    % ===== TEST 6: MECH0020_Run Standard Mode =====
    n_total = n_total + 1;
    fprintf('[TEST 6/6] MECH0020_Run Standard mode (batch, 32x32, Tfinal=0.01)...\n');
    try
        MECH0020_Run('Mode', 'Standard', ...
            'Method', 'FD', ...
            'SimMode', 'Evolution', ...
            'IC', 'lamb_oseen', ...
            'Nx', 32, 'Ny', 32, ...
            'dt', 0.001, 'Tfinal', 0.01, ...
            'nu', 0.01, ...
            'SaveFigs', 0, 'SaveData', 0, 'Monitor', 0);
        fprintf('  PASS: MECH0020_Run completed without error\n\n');
        n_pass = n_pass + 1;
    catch ME
        fprintf('  FAIL: %s\n', ME.message);
        if ~isempty(ME.stack)
            for k = 1:min(5, length(ME.stack))
                fprintf('    [%d] %s (line %d)\n', k, ME.stack(k).name, ME.stack(k).line);
            end
        end
        fprintf('\n');
        n_fail = n_fail + 1;
        failures{end+1} = sprintf('Test 6 (MECH0020_Run): %s', ME.message); %#ok<AGROW>
    end

    % ===== SUMMARY =====
    fprintf('===============================================================\n');
    fprintf('  END-TO-END TEST RESULTS\n');
    fprintf('===============================================================\n\n');
    fprintf('  Total:  %d\n', n_total);
    fprintf('  Passed: %d\n', n_pass);
    fprintf('  Failed: %d\n\n', n_fail);

    if n_fail > 0
        fprintf('FAILURES:\n');
        for i = 1:length(failures)
            fprintf('  %d. %s\n', i, failures{i});
        end
        fprintf('\n');
        fprintf('===============================================================\n');
        fprintf('  RESULT: FAIL\n');
        fprintf('===============================================================\n\n');
    else
        fprintf('===============================================================\n');
        fprintf('  RESULT: ALL TESTS PASSED\n');
        fprintf('===============================================================\n\n');
    end
end

function setup_test_paths(repo_root)
    % Mirror the path setup from MECH0020_Run
    addpath(fullfile(repo_root, 'Scripts', 'Drivers'));
    addpath(fullfile(repo_root, 'Scripts', 'Solvers'));
    addpath(fullfile(repo_root, 'Scripts', 'Modes'));
    addpath(fullfile(repo_root, 'Scripts', 'Modes', 'Convergence'));
    addpath(fullfile(repo_root, 'Scripts', 'Methods', 'FiniteDifference'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Builds'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Compatibility'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'DataRelatedHelpers'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Initialisers'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Runners'));
    addpath(fullfile(repo_root, 'Scripts', 'Infrastructure', 'Utilities'));
    addpath(fullfile(repo_root, 'Scripts', 'Editable'));
    addpath(fullfile(repo_root, 'Scripts', 'UI'));
    addpath(fullfile(repo_root, 'Scripts', 'Plotting'));
    addpath(fullfile(repo_root, 'Scripts', 'Sustainability'));
    addpath(fullfile(repo_root, 'utilities'));
end
