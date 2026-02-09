function State = fd_init(cfg, ctx)
    % fd_init - Initialize Finite Difference method state
    %
    % Purpose:
    %   Creates initial state for FD method including:
    %   - Grid setup and operators
    %   - Initial vorticity field
    %   - Poisson solver matrix
    %   - Shift operators for Arakawa scheme
    %
    % Inputs:
    %   cfg - Configuration struct with fields:
    %         .Nx, .Ny - Grid resolution
    %         .Lx, .Ly - Domain size
    %         .nu - Viscosity
    %         .dt - Time step
    %         .ic_type - Initial condition type
    %         .ic_coeff - IC coefficients (optional)
    %         .omega - Pre-computed omega (optional)
    %   ctx - Context struct (mode-specific data)
    %
    % Output:
    %   State - Initial state struct with fields:
    %           .omega - Vorticity field (Ny × Nx)
    %           .psi - Streamfunction field (Ny × Nx)
    %           .t - Current time (0.0)
    %           .setup - FD operators and grid data
    %
    % Usage:
    %   State = fd_init(cfg, ctx);

    % ===== GRID AND OPERATOR SETUP =====
    setup = fd_setup_internal(cfg);

    % ===== INITIAL CONDITION =====
    % Use pre-computed omega if available
    if isfield(cfg, 'omega') && ~isempty(cfg.omega)
        omega0 = cfg.omega;
    else
        % Compute from IC type
        if isfield(cfg, 'ic_coeff')
            ic_coeff = cfg.ic_coeff;
        else
            ic_coeff = [];
        end
        omega0 = initialise_omega(setup.X, setup.Y, cfg.ic_type, ic_coeff);
    end
    omega = reshape(omega0, setup.Ny, setup.Nx);

    % ===== INITIAL STREAMFUNCTION =====
    psi_vec = setup.delta^2 * (setup.A \ omega(:));
    psi = reshape(psi_vec, setup.Ny, setup.Nx);

    % ===== PACK STATE =====
    State = struct();
    State.omega = omega;
    State.psi = psi;
    State.t = 0.0;
    State.step = 0;
    State.setup = setup;
end

function setup = fd_setup_internal(cfg)
    % Internal setup function - extracted from Finite_Difference_Analysis
    % Creates grid, operators, and Poisson solver matrix

    Nx = cfg.Nx;
    Ny = cfg.Ny;
    Lx = cfg.Lx;
    Ly = cfg.Ly;

    % Grid spacing
    dx = Lx / Nx;
    dy = Ly / Ny;
    delta = dx;  % Assume square cells

    % Meshgrid
    x = linspace(0, Lx - dx, Nx);
    y = linspace(0, Ly - dy, Ny);
    [X, Y] = meshgrid(x, y);

    % Poisson solver matrix (periodic boundaries)
    % ∇²ψ = -ω using 5-point stencil
    ex = ones(Nx, 1);
    ey = ones(Ny, 1);

    % 1D Laplacian with periodic BC
    Tx = spdiags([ex -2*ex ex], [-1 0 1], Nx, Nx);
    Tx(1, end) = 1;  % Periodic
    Tx(end, 1) = 1;

    Ty = spdiags([ey -2*ey ey], [-1 0 1], Ny, Ny);
    Ty(1, end) = 1;  % Periodic
    Ty(end, 1) = 1;

    % 2D Laplacian: A = (1/dx²) Tx ⊗ I + (1/dy²) I ⊗ Ty
    Ix = speye(Nx);
    Iy = speye(Ny);
    A = (1/dx^2) * kron(Tx, Iy) + (1/dy^2) * kron(Ix, Ty);

    % Pack setup
    setup = struct();
    setup.Nx = Nx;
    setup.Ny = Ny;
    setup.Lx = Lx;
    setup.Ly = Ly;
    setup.dx = dx;
    setup.dy = dy;
    setup.delta = delta;
    setup.X = X;
    setup.Y = Y;
    setup.x = x;
    setup.y = y;
    setup.A = A;  % Poisson solver matrix

    % Shift operators for Arakawa scheme
    setup.shift_xp = @(A) circshift(A, [0, +1]);
    setup.shift_xm = @(A) circshift(A, [0, -1]);
    setup.shift_yp = @(A) circshift(A, [+1, 0]);
    setup.shift_ym = @(A) circshift(A, [-1, 0]);
end
