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
    params.Lx = 10;             % Domain size X
    params.Ly = 10;             % Domain size Y
    
    % ===== GRID =====
    params.Nx = 128;                % Grid points X
    params.Ny = 128;                % Grid points Y
    params.delta = 2;               % Grid spacing scaling factor
    
    % ===== TIME INTEGRATION =====
    params.dt = 0.001;              % Timestep
    params.Tfinal = 9.0;            % Final time
    
    % ===== INITIAL CONDITION =====
    params.ic_type = 'streched-gaussian';  % IC type
    params.ic_coeff = [2 0.2];           % IC coefficients (method-specific)
    
    % ===== SNAPSHOTS =====
    % Snapshot times for output
    params.num_snapshots = 10;          % Number of snapshots to save
    params.snap_times = linspace(0, params.Tfinal, params.num_snapshots);
    
    % ===== PROGRESS & PREVIEW =====
    params.progress_stride = 100;   % Console output every N steps (0 = off)
    params.live_preview = false;    % Live figure updates during run
    params.live_stride = 0;         % Update figure every N steps (0 = off)
end
