function Parameters = Default_FD_Parameters()
    % Default_FD_Parameters - User-editable default parameters for Finite Difference
    %
    % Purpose:
    %   Single source of default physics and numerics for FD simulations
    %   Users edit THIS FILE to change defaults (not buried in Analysis.m)
    %
    % Location: Scripts/Config/ (user-editable directory)
    %
    % Structure: Returns Parameters struct (physics + numerics)
    %
    % Usage:
    %   Parameters = Default_FD_Parameters();
    %   Parameters.Nx = 256;  % Override as needed
    
    % ===== PHYSICS =====
    Parameters.nu = 0.001;              % Kinematic viscosity
    Parameters.Lx = 2 * pi;             % Domain size X
    Parameters.Ly = 2 * pi;             % Domain size Y
    
    % ===== GRID =====
    Parameters.Nx = 128;                % Grid points X
    Parameters.Ny = 128;                % Grid points Y
    Parameters.delta = 2;               % Grid spacing scaling factor
    
    % ===== TIME INTEGRATION =====
    Parameters.dt = 0.001;              % Timestep
    Parameters.Tfinal = 1.0;            % Final time
    
    % ===== INITIAL CONDITION =====
    Parameters.ic_type = 'Lamb-Oseen';  % IC type
    Parameters.ic_coeff = [];           % IC coefficients (method-specific)
    
    % ===== SNAPSHOTS =====
    % Snapshot times for output
    Parameters.snap_times = linspace(0, Parameters.Tfinal, 11);
    
    % ===== PROGRESS & PREVIEW =====
    Parameters.progress_stride = 100;   % Console output every N steps (0 = off)
    Parameters.live_preview = false;    % Live figure updates during run
    Parameters.live_stride = 0;         % Update figure every N steps (0 = off)
end
