function State = fd_step(State, cfg, ctx)
    % fd_step - Advance FD solution by one time step using RK4
    %
    % Purpose:
    %   Performs single RK4 step for vorticity equation:
    %   ∂ω/∂t = -u·∇ω + ν∇²ω
    %   Uses Arakawa scheme for advection term
    %
    % Inputs:
    %   State - Current state (from fd_init or previous fd_step)
    %   cfg - Configuration (must contain .dt, .nu)
    %   ctx - Context (mode-specific data, unused here)
    %
    % Output:
    %   State - Updated state with new omega, psi, t, step
    %
    % Usage:
    %   State = fd_step(State, cfg, ctx);

    dt = cfg.dt;
    nu = cfg.nu;
    s = State.setup;

    % Extract current omega (as column vector for RHS evaluation)
    omega_vec = State.omega(:);

    % RK4 integration
    k1 = rhs_fd_arakawa(omega_vec, s.A, s.dx, s.dy, nu, s.shift_xp, s.shift_xm, s.shift_yp, s.shift_ym, s.Nx, s.Ny, s.delta);
    k2 = rhs_fd_arakawa(omega_vec + 0.5*dt*k1, s.A, s.dx, s.dy, nu, s.shift_xp, s.shift_xm, s.shift_yp, s.shift_ym, s.Nx, s.Ny, s.delta);
    k3 = rhs_fd_arakawa(omega_vec + 0.5*dt*k2, s.A, s.dx, s.dy, nu, s.shift_xp, s.shift_xm, s.shift_yp, s.shift_ym, s.Nx, s.Ny, s.delta);
    k4 = rhs_fd_arakawa(omega_vec + dt*k3, s.A, s.dx, s.dy, nu, s.shift_xp, s.shift_xm, s.shift_yp, s.shift_ym, s.Nx, s.Ny, s.delta);

    % Update omega
    omega_vec = omega_vec + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
    State.omega = reshape(omega_vec, s.Ny, s.Nx);

    % Update streamfunction (solve Poisson equation)
    psi_vec = s.delta^2 * (s.A \ omega_vec);
    State.psi = reshape(psi_vec, s.Ny, s.Nx);

    % Update time and step counter
    State.t = State.t + dt;
    State.step = State.step + 1;
end

function dwdt = rhs_fd_arakawa(omega_in, A, dx, dy, nu, shift_xp, shift_xm, shift_yp, shift_ym, Nx, Ny, delta)
    % rhs_fd_arakawa - Compute RHS of vorticity equation using Arakawa scheme
    %
    % Extracted from Finite_Difference_Analysis.m (no mathematical changes)
    % Computes: dω/dt = -J(ψ,ω) + ν∇²ω
    % where J is the Arakawa Jacobian (energy-conserving)

    omega2d = reshape(omega_in, Ny, Nx);

    % Solve Poisson equation for streamfunction: ∇²ψ = -ω
    psi_vec = delta^2 * (A \ omega_in);
    psi2d = reshape(psi_vec, Ny, Nx);

    % Velocity from streamfunction: u = -∂ψ/∂y, v = ∂ψ/∂x
    u = -(shift_yp(psi2d) - shift_ym(psi2d)) / (2*dy);
    v =  (shift_xp(psi2d) - shift_xm(psi2d)) / (2*dx);

    % Vorticity gradients
    dwdx = (shift_xp(omega2d) - shift_xm(omega2d)) / (2*dx);
    dwdy = (shift_yp(omega2d) - shift_ym(omega2d)) / (2*dy);

    % Advection term (Arakawa-style conservative form)
    adv = u .* dwdx + v .* dwdy;

    % Diffusion term: ν∇²ω (5-point stencil)
    d2wdx2 = (shift_xp(omega2d) - 2*omega2d + shift_xm(omega2d)) / dx^2;
    d2wdy2 = (shift_yp(omega2d) - 2*omega2d + shift_ym(omega2d)) / dy^2;
    diff = nu * (d2wdx2 + d2wdy2);

    % Combine: dω/dt = -advection + diffusion
    dwdt2d = -adv + diff;
    dwdt = dwdt2d(:);
end
