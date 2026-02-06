function [Results, paths] = FD_Evolution_Mode(Run_Config, Parameters, Settings)
    % FD_Evolution_Mode - Time evolution mode for Finite Difference
    %
    % Purpose:
    %   Orchestrates a single time evolution simulation
    %   Manages directory setup, monitoring, output, and reporting
    %
    % Inputs:
    %   Run_Config - method, mode, ic_type, run_id
    %   Parameters - physics + numerics (from Default_FD_Parameters or user)
    %   Settings - IO, monitoring, logging (from Default_Settings or user)
    %
    % Outputs:
    %   Results - simulation results and metrics
    %   paths - directory structure (from PathBuilder)
    %
    % Usage:
    %   [Results, paths] = FD_Evolution_Mode(Run_Config, Parameters, Settings);
    
    % ===== SETUP =====
    % Generate run ID if not provided
    if ~isfield(Run_Config, 'run_id') || isempty(Run_Config.run_id)
        Run_Config.run_id = RunIDGenerator.generate(Run_Config, Parameters);
    end
    
    % Get directory paths and create them
    paths = PathBuilder.get_run_paths(Run_Config.method, Run_Config.mode, Run_Config.run_id);
    PathBuilder.ensure_directories(paths);
    
    % Save configuration to run directory
    config_path = fullfile(paths.base, 'Config.mat');
    save(config_path, 'Run_Config', 'Parameters', 'Settings');
    
    % ===== MONITORING =====
    MonitorInterface.start(Run_Config, Settings);
    
    % ===== SIMULATION =====
    tic;
    
    % Call Finite_Difference_Analysis (existing solver)
    Parameters.mode = 'evolution';  % Internal mode for FD solver
    [fig_handle, analysis] = Finite_Difference_Analysis(Parameters);
    
    wall_time = toc;
    
    % ===== RESULTS COLLECTION =====
    Results = struct();
    Results.run_id = Run_Config.run_id;
    Results.wall_time = wall_time;
    Results.final_time = Parameters.Tfinal;
    Results.total_steps = length(analysis.time_vec);
    
    % Extract metrics from analysis
    if isfield(analysis, 'peak_vorticity')
        Results.max_omega = analysis.peak_vorticity;
    end
    if isfield(analysis, 'kinetic_energy') && ~isempty(analysis.kinetic_energy)
        Results.final_energy = analysis.kinetic_energy(end);
    end
    if isfield(analysis, 'enstrophy') && ~isempty(analysis.enstrophy)
        Results.final_enstrophy = analysis.enstrophy(end);
    end
    
    % ===== SAVE FIGURES =====
    if Settings.save_figures && ishandle(fig_handle)
        % Save main evolution figure
        fig_name = RunIDGenerator.make_figure_filename(Run_Config.run_id, 'evolution', '');
        fig_path = fullfile(paths.figures_evolution, fig_name);
        saveas(fig_handle, fig_path);
        
        % Generate additional visualizations
        generate_evolution_figures(analysis, Parameters, Run_Config, paths, Settings);
    end
    
    % ===== SAVE DATA =====
    if Settings.save_data
        data_path = fullfile(paths.data, 'results.mat');
        save(data_path, 'analysis', 'Results', '-v7.3');
    end
    
    % ===== GENERATE REPORT =====
    if Settings.save_reports
        RunReportGenerator.generate(Run_Config.run_id, Run_Config, Parameters, Settings, Results, paths);
    end
    
    % ===== APPEND TO MASTER TABLE =====
    if Settings.append_to_master
        MasterRunsTable.append_run(Run_Config.run_id, Run_Config, Parameters, Results);
    end
    
    % ===== MONITORING COMPLETE =====
    Run_Summary = struct();
    Run_Summary.total_time = wall_time;
    Run_Summary.status = 'completed';
    MonitorInterface.stop(Run_Summary);
end

function generate_evolution_figures(analysis, Parameters, Run_Config, paths, Settings)
    % Generate additional evolution figures (contours, vectors, streamlines)
    
    % Get snapshots
    omega_snaps = analysis.omega_snaps;
    psi_snaps = analysis.psi_snaps;
    time_vec = analysis.time_vec;
    
    % Grid
    Nx = Parameters.Nx;
    Ny = Parameters.Ny;
    Lx = Parameters.Lx;
    Ly = Parameters.Ly;
    x = linspace(0, Lx, Nx);
    y = linspace(0, Ly, Ny);
    [X, Y] = meshgrid(x, y);
    
    % Select key snapshots (start, middle, end)
    snap_indices = [1, ceil(size(omega_snaps, 3)/2), size(omega_snaps, 3)];
    
    % Contour figures
    for idx = snap_indices
        fig = figure('Visible', 'off');
        contourf(X, Y, omega_snaps(:, :, idx), 20, 'LineStyle', 'none');
        colorbar;
        title(sprintf('Vorticity at t=%.3f', time_vec(idx)));
        xlabel('x'); ylabel('y');
        
        fig_name = RunIDGenerator.make_figure_filename(Run_Config.run_id, 'contour', sprintf('t%.3f', time_vec(idx)));
        saveas(fig, fullfile(paths.figures_contours, fig_name));
        close(fig);
    end
    
    % Streamline figures
    for idx = snap_indices
        fig = figure('Visible', 'off');
        contourf(X, Y, omega_snaps(:, :, idx), 20, 'LineStyle', 'none');
        hold on;
        contour(X, Y, psi_snaps(:, :, idx), 15, 'k', 'LineWidth', 0.8);
        colorbar;
        title(sprintf('Vorticity + Streamlines at t=%.3f', time_vec(idx)));
        xlabel('x'); ylabel('y');
        
        fig_name = RunIDGenerator.make_figure_filename(Run_Config.run_id, 'streamlines', sprintf('t%.3f', time_vec(idx)));
        saveas(fig, fullfile(paths.figures_streamlines, fig_name));
        close(fig);
    end
end
