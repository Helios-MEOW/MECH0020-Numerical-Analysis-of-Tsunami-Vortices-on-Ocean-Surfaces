function [Results, paths] = FD_Convergence_Mode(Run_Config, Parameters, Settings)
    % FD_Convergence_Mode - Grid convergence study for Finite Difference
    %
    % Purpose:
    %   Orchestrates mesh refinement convergence study
    %   Runs multiple simulations with increasing grid resolution
    %   Computes convergence order and asymptotic behavior
    %
    % Inputs:
    %   Run_Config - method, mode, ic_type, study_id
    %   Parameters - physics + numerics + convergence settings
    %   Settings - IO, monitoring, logging
    %
    % Outputs:
    %   Results - convergence metrics (order, QoI vs mesh)
    %   paths - directory structure
    %
    % Convergence Parameters (in Parameters struct):
    %   mesh_sizes - array of grid sizes [32, 64, 128, 256, ...]
    %   convergence_variable - QoI to track ('max_omega', 'energy', 'enstrophy')
    
    % ===== SETUP =====
    if ~isfield(Run_Config, 'study_id') || isempty(Run_Config.study_id)
        Run_Config.study_id = RunIDGenerator.generate(Run_Config, Parameters);
    end
    
    paths = PathBuilder.get_run_paths(Run_Config.method, Run_Config.mode, Run_Config.study_id);
    PathBuilder.ensure_directories(paths);
    
    config_path = fullfile(paths.base, 'Config.mat');
    save(config_path, 'Run_Config', 'Parameters', 'Settings');
    
    % ===== CONVERGENCE SETTINGS =====
    if ~isfield(Parameters, 'mesh_sizes')
        Parameters.mesh_sizes = [32, 64, 128, 256];
    end
    if ~isfield(Parameters, 'convergence_variable')
        Parameters.convergence_variable = 'max_omega';
    end
    
    mesh_sizes = Parameters.mesh_sizes;
    n_meshes = length(mesh_sizes);
    
    % ===== MONITORING =====
    MonitorInterface.start(Run_Config, Settings);
    
    % ===== CONVERGENCE STUDY =====
    tic;
    
    % Storage for convergence data
    QoI_values = zeros(n_meshes, 1);
    h_values = zeros(n_meshes, 1);
    wall_times = zeros(n_meshes, 1);
    
    base_params = Parameters;
    
    for i = 1:n_meshes
        N = mesh_sizes(i);
        fprintf('\n--- Mesh %d/%d: N=%d ---\n', i, n_meshes, N);
        
        % Update grid parameters
        params_i = base_params;
        params_i.Nx = N;
        params_i.Ny = N;
        params_i.mode = 'convergence';
        
        % Run simulation
        tic_mesh = tic;
        [fig_h, analysis] = Finite_Difference_Analysis(params_i);
        wall_times(i) = toc(tic_mesh);
        
        % Extract QoI
        QoI_values(i) = extract_qoi(analysis, Parameters.convergence_variable);
        h_values(i) = base_params.Lx / N;
        
        % Save mesh-specific results
        mesh_name = sprintf('mesh_N%d', N);
        mesh_path = fullfile(paths.mesh_plots, sprintf('%s.png', mesh_name));
        if ishandle(fig_h) && Settings.save_figures
            saveas(fig_h, mesh_path);
            close(fig_h);
        end
        
        % Save grid visualization
        save_grid_visualization(analysis, N, paths.mesh_grids, mesh_name);
    end
    
    total_time = toc;
    
    % ===== CONVERGENCE ANALYSIS =====
    % Compute convergence order (log-log slope)
    if n_meshes >= 2
        % Use last two points for order estimate
        log_h = log(h_values);
        log_QoI = log(abs(QoI_values - QoI_values(end)));
        
        % Linear fit in log-log space
        p = polyfit(log_h(1:end-1), log_QoI(1:end-1), 1);
        convergence_order = p(1);
        
        % Asymptotic value estimate
        asymptotic_value = QoI_values(end);
    else
        convergence_order = NaN;
        asymptotic_value = NaN;
    end
    
    % ===== RESULTS =====
    Results = struct();
    Results.study_id = Run_Config.study_id;
    Results.mesh_sizes = mesh_sizes;
    Results.QoI_values = QoI_values;
    Results.h_values = h_values;
    Results.wall_times = wall_times;
    Results.convergence_order = convergence_order;
    Results.asymptotic_value = asymptotic_value;
    Results.total_time = total_time;
    
    % ===== SAVE CONVERGENCE PLOTS =====
    if Settings.save_figures
        generate_convergence_plots(Results, Parameters, Run_Config, paths);
    end
    
    % ===== SAVE DATA =====
    if Settings.save_data
        save(fullfile(paths.base, 'convergence_data.mat'), 'Results', '-v7.3');
    end
    
    % ===== GENERATE REPORT =====
    if Settings.save_reports
        RunReportGenerator.generate(Run_Config.study_id, Run_Config, Parameters, Settings, Results, paths);
    end
    
    % ===== APPEND TO MASTER TABLE =====
    if Settings.append_to_master
        MasterRunsTable.append_run(Run_Config.study_id, Run_Config, Parameters, Results);
    end
    
    % ===== MONITORING COMPLETE =====
    Run_Summary = struct();
    Run_Summary.total_time = total_time;
    Run_Summary.status = 'completed';
    Run_Summary.convergence_order = convergence_order;
    MonitorInterface.stop(Run_Summary);
end

function qoi = extract_qoi(analysis, var_name)
    % Extract quantity of interest from analysis results
    switch var_name
        case 'max_omega'
            qoi = analysis.peak_vorticity;
        case 'energy'
            qoi = analysis.kinetic_energy(end);
        case 'enstrophy'
            qoi = analysis.enstrophy(end);
        otherwise
            warning('Unknown convergence variable: %s', var_name);
            qoi = NaN;
    end
end

function save_grid_visualization(analysis, N, grid_dir, mesh_name)
    % Save visualization of grid
    fig = figure('Visible', 'off');
    
    omega = analysis.omega_snaps(:, :, end);
    contourf(omega, 20, 'LineStyle', 'none');
    colorbar;
    title(sprintf('Grid N=%d', N));
    
    saveas(fig, fullfile(grid_dir, sprintf('%s.png', mesh_name)));
    close(fig);
end

function generate_convergence_plots(Results, Parameters, Run_Config, paths)
    % Generate convergence analysis plots
    
    % Plot 1: QoI vs mesh size
    fig1 = figure('Visible', 'off');
    plot(Results.mesh_sizes, Results.QoI_values, 'o-', 'LineWidth', 2);
    xlabel('Mesh Size N');
    ylabel(Parameters.convergence_variable);
    title('Convergence: QoI vs Mesh Size');
    grid on;
    fig_name = sprintf('%s__convergence_qoi.png', Run_Config.study_id);
    saveas(fig1, fullfile(paths.convergence_metrics, fig_name));
    close(fig1);
    
    % Plot 2: Log-log convergence
    fig2 = figure('Visible', 'off');
    loglog(Results.h_values, abs(Results.QoI_values - Results.asymptotic_value), 'o-', 'LineWidth', 2);
    xlabel('Grid Spacing h');
    ylabel('|QoI - QoI_{asymptotic}|');
    title(sprintf('Convergence Order: %.2f', Results.convergence_order));
    grid on;
    fig_name = sprintf('%s__convergence_order.png', Run_Config.study_id);
    saveas(fig2, fullfile(paths.convergence_metrics, fig_name));
    close(fig2);
    
    % Plot 3: Wall time vs mesh size
    fig3 = figure('Visible', 'off');
    semilogy(Results.mesh_sizes, Results.wall_times, 's-', 'LineWidth', 2);
    xlabel('Mesh Size N');
    ylabel('Wall Time (s)');
    title('Computational Cost vs Mesh Size');
    grid on;
    fig_name = sprintf('%s__walltime.png', Run_Config.study_id);
    saveas(fig3, fullfile(paths.convergence_metrics, fig_name));
    close(fig3);
end
