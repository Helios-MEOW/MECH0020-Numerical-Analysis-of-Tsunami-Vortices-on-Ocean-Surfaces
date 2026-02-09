function Metrics = fd_diagnostics(State, cfg, ctx)
    % fd_diagnostics - Compute diagnostic metrics for FD method
    %
    % Purpose:
    %   Extracts physical quantities and diagnostic metrics
    %   from current state (vorticity, streamfunction)
    %
    % Inputs:
    %   State - Current state (omega, psi, t, setup)
    %   cfg - Configuration (unused)
    %   ctx - Context (unused)
    %
    % Output:
    %   Metrics - Struct with diagnostic data:
    %             .max_vorticity - Max |ω|
    %             .enstrophy - ∫ ω² dA
    %             .kinetic_energy - ∫ |∇ψ|² dA
    %             .t - Current time
    %
    % Usage:
    %   Metrics = fd_diagnostics(State, cfg, ctx);

    omega = State.omega;
    psi = State.psi;
    s = State.setup;

    % Max vorticity
    max_vorticity = max(abs(omega(:)));

    % Enstrophy: ∫ ω² dA
    enstrophy = sum(omega(:).^2) * s.dx * s.dy;

    % Kinetic energy: (1/2) ∫ |∇ψ|² dA
    % Compute ∇ψ using centered differences
    dpsi_dx = (s.shift_xp(psi) - s.shift_xm(psi)) / (2 * s.dx);
    dpsi_dy = (s.shift_yp(psi) - s.shift_ym(psi)) / (2 * s.dy);
    grad_psi_sq = dpsi_dx.^2 + dpsi_dy.^2;
    kinetic_energy = 0.5 * sum(grad_psi_sq(:)) * s.dx * s.dy;

    % Pack metrics
    Metrics = struct();
    Metrics.max_vorticity = max_vorticity;
    Metrics.enstrophy = enstrophy;
    Metrics.kinetic_energy = kinetic_energy;
    Metrics.t = State.t;
    Metrics.step = State.step;
end
