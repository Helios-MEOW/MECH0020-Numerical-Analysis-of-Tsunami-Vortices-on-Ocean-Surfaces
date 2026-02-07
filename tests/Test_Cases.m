function Test_Cases = Get_Test_Cases()
    % Get_Test_Cases - Minimal test configurations for regression testing
    %
    % Purpose:
    %   Provide deterministic, fast test cases for all modes
    %   Fixed seeds for reproducibility
    %   Small grids for speed
    %
    % Output:
    %   Test_Cases - Struct array with test configurations
    %
    % Usage:
    %   cases = Get_Test_Cases();
    %   [Results, paths] = ModeDispatcher(cases(1).Run_Config, cases(1).Parameters, cases(1).Settings);
    
    Test_Cases = [];
    idx = 1;
    
    % ===== FD Evolution Test Case =====
    tc = struct();
    tc.name = 'FD_Evolution_LambOseen_32x32';
    tc.Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');
    tc.Parameters = Parameters();
    tc.Parameters.Nx = 32;
    tc.Parameters.Ny = 32;
    tc.Parameters.Tfinal = 0.1;
    tc.Parameters.dt = 0.001;
    tc.Parameters.snap_times = [0, 0.05, 0.1];
    tc.Settings = Settings();
    tc.Settings.save_figures = false;
    tc.Settings.save_data = false;
    tc.Settings.save_reports = false;
    tc.Settings.append_to_master = false;
    tc.Settings.monitor_enabled = false;
    Test_Cases(idx) = tc;
    idx = idx + 1;
    
    % ===== FD Convergence Test Case =====
    tc = struct();
    tc.name = 'FD_Convergence_Gaussian_16_32';
    tc.Run_Config = Build_Run_Config('FD', 'Convergence', 'Gaussian');
    tc.Parameters = Parameters();
    tc.Parameters.mesh_sizes = [16, 32];
    tc.Parameters.Tfinal = 0.05;
    tc.Parameters.dt = 0.001;
    tc.Parameters.snap_times = [0, 0.05];
    tc.Parameters.convergence_variable = 'max_omega';
    tc.Settings = Settings();
    tc.Settings.save_figures = false;
    tc.Settings.save_data = false;
    tc.Settings.save_reports = false;
    tc.Settings.append_to_master = false;
    tc.Settings.monitor_enabled = false;
    Test_Cases(idx) = tc;
    idx = idx + 1;
    
    % ===== FD ParameterSweep Test Case =====
    tc = struct();
    tc.name = 'FD_ParameterSweep_nu_2vals';
    tc.Run_Config = Build_Run_Config('FD', 'ParameterSweep', 'Lamb-Oseen');
    tc.Parameters = Parameters();
    tc.Parameters.Nx = 32;
    tc.Parameters.Ny = 32;
    tc.Parameters.Tfinal = 0.05;
    tc.Parameters.dt = 0.001;
    tc.Parameters.snap_times = [0, 0.05];
    tc.Parameters.sweep_parameter = 'nu';
    tc.Parameters.sweep_values = [0.001, 0.002];
    tc.Settings = Settings();
    tc.Settings.save_figures = false;
    tc.Settings.save_data = false;
    tc.Settings.save_reports = false;
    tc.Settings.append_to_master = false;
    tc.Settings.monitor_enabled = false;
    Test_Cases(idx) = tc;
    idx = idx + 1;
    
    % Add more test cases as needed
end
