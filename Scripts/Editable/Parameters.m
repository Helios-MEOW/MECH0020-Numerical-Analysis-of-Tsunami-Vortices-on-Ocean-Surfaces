function params = Parameters()
    % Parameters - User-editable default parameters for Finite Difference
    %
    % Purpose:
    %   Single source of default physics and numerics for FD simulations
    %   Users edit THIS FILE to change defaults (not buried in Analysis.m)
    %
    % Location: Scripts/Editable/ (user-editable directory)
    %
    % Structure: Returns Parameters struct (physics + numerics)
    %
    % Usage:
    %   Parameters = Parameters();
    %   Parameters.Nx = 256;  % Override as needed
    
    % ===== PHYSICS =====
    params.nu = 0.001;              % Kinematic viscosity
    params.Lx = 2 * pi;             % Domain size X
    params.Ly = 2 * pi;             % Domain size Y
    
    % ===== GRID =====
    params.Nx = 128;                % Grid points X
    params.Ny = 128;                % Grid points Y
    params.delta = 2;               % Grid spacing scaling factor
    
    % ===== TIME INTEGRATION =====
    params.dt = 0.001;              % Timestep
    params.Tfinal = 1.0;            % Final time
    
    % ===== INITIAL CONDITION =====
    params.ic_type = 'Lamb-Oseen';  % IC type
    params.ic_coeff = [];           % IC coefficients (method-specific)
    
    % ===== SNAPSHOTS =====
    % Snapshot times for output
    params.snap_times = linspace(0, params.Tfinal, 11);
    
    % ===== PROGRESS & PREVIEW =====
    params.progress_stride = 100;   % Console output every N steps (0 = off)
    params.live_preview = false;    % Live figure updates during run
    params.live_stride = 0;         % Update figure every N steps (0 = off)
end
