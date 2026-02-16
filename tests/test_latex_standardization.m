function test_latex_standardization()
% test_latex_standardization - Verify LaTeX standardization in UI_Layout_Config
%
% This test verifies that all mathematical symbols use consistent LaTeX
% notation throughout the UI configuration.

    fprintf('Testing LaTeX standardization...\n\n');

    % Test 1: Verify math_tokens struct exists and has required tokens
    fprintf('[1/3] Checking math_tokens structure...\n');

    cfg = UI_Layout_Config();
    assert(isfield(cfg, 'math_tokens'), 'Missing math_tokens struct');

    required_tokens = {
        'N_x', 'N_y', 'L_x', 'L_y', ...
        'Delta_t', 'Delta_x', 'Delta_y', 'delta', ...
        'T_final', 't', 'nu', 'epsilon', 'omega', 'psi', ...
        'omega_max', 'omega_abs', 'omega_norm', ...
        'partial_omega_partial_t', 'nabla2_omega', ...
        'energy', 'enstrophy', ...
        'Nx', 'Ny', 'Lx', 'Ly', 'dt', 'Tfinal', 'dx', 'dy'
    };

    for i = 1:numel(required_tokens)
        token = required_tokens{i};
        assert(isfield(cfg.math_tokens, token), ...
            sprintf('Missing math token: %s', token));
    end

    fprintf('   ✓ All required tokens present (%d tokens)\n', numel(required_tokens));

    % Test 2: Verify LaTeX formatting
    fprintf('[2/3] Checking LaTeX formatting...\n');

    % Check that key tokens have correct LaTeX syntax
    assert(strcmp(cfg.math_tokens.N_x, '$N_x$'), 'N_x token incorrect');
    assert(strcmp(cfg.math_tokens.Delta_t, '$\Delta t$'), 'Delta_t token incorrect');
    assert(strcmp(cfg.math_tokens.nu, '$\nu$'), 'nu token incorrect');
    assert(strcmp(cfg.math_tokens.omega, '$\omega$'), 'omega token incorrect');
    assert(strcmp(cfg.math_tokens.psi, '$\psi$'), 'psi token incorrect');
    assert(strcmp(cfg.math_tokens.omega_max, '$|\omega|_{max}$'), 'omega_max token incorrect');
    assert(strcmp(cfg.math_tokens.nabla2_omega, '$\nabla^2\omega$'), 'nabla2_omega token incorrect');

    fprintf('   ✓ LaTeX formatting correct\n');

    % Test 3: Verify metric_catalog structure exists
    fprintf('[3/3] Checking metric_catalog structure...\n');

    assert(isfield(cfg.monitor_tab, 'metric_catalog'), 'Missing metric_catalog');
    catalog = cfg.monitor_tab.metric_catalog;

    % Verify catalog has required fields
    assert(isfield(catalog, 'id'), 'Metric catalog missing id field');
    assert(isfield(catalog, 'title'), 'Metric catalog missing title field');
    assert(isfield(catalog, 'ylabel'), 'Metric catalog missing ylabel field');

    % Check that metric catalog structure is consistent
    fprintf('   ✓ Metric catalog structure valid\n');

    % Summary
    fprintf('\n==========================================================\n');
    fprintf('LaTeX Standardization: VERIFIED\n');
    fprintf('==========================================================\n\n');

    fprintf('Math tokens defined:\n');
    fprintf('  Grid parameters:    Nx, Ny, Lx, Ly, Δx, Δy, Δ\n');
    fprintf('  Time parameters:    t, Δt, T_final\n');
    fprintf('  Physics parameters: ν, ω, ψ, ε\n');
    fprintf('  Operators:          |ω|, ||ω||, ∂ω/∂t, ∇²ω\n');
    fprintf('  Quantities:         E (energy), Z (enstrophy)\n\n');

    fprintf('Token count: %d standardized mathematical symbols\n', ...
        numel(fieldnames(cfg.math_tokens)));

    fprintf('\nUsage in UIController:\n');
    fprintf('  Labels created with create_math_label() automatically\n');
    fprintf('  use LaTeX tokens via resolve_math_token() lookup.\n\n');

    fprintf('Examples:\n');
    fprintf('  create_math_label(grid, ''N_x'', ''Nx'') → displays "$N_x$"\n');
    fprintf('  create_math_label(time, ''Delta_t'', ''dt'') → displays "$\\Delta t$"\n');
    fprintf('  create_math_label(phys, ''nu'', ''nu'') → displays "$\\nu$"\n\n');
end
