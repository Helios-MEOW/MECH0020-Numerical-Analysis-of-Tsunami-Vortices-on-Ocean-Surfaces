function [Results, paths] = FD_ParameterSweep_Mode(Run_Config, Parameters, Settings)
    % FD_ParameterSweep_Mode - Parameter sweep study for Finite Difference
    %
    % Purpose:
    %   Systematically vary one or more parameters
    %   Run simulations across parameter space
    %   Generate comparative visualizations
    %
    % Inputs:
    %   Run_Config - method, mode, ic_type, study_id
    %   Parameters - physics + numerics + sweep configuration
    %   Settings - IO, monitoring, logging
    %
    % Outputs:
    %   Results - sweep results (parameter values, QoI for each)
    %   paths - directory structure
    %
    % Sweep Parameters (in Parameters struct):
    %   sweep_parameter - parameter name to vary ('nu', 'dt', etc.)
    %   sweep_values - array of values to test
    
    % ===== SETUP =====
    if ~isfield(Run_Config, 'study_id') || isempty(Run_Config.study_id)
        Run_Config.study_id = RunIDGenerator.generate(Run_Config, Parameters);
    end
    
    paths = PathBuilder.get_run_paths(Run_Config.method, Run_Config.mode, Run_Config.study_id);
    PathBuilder.ensure_directories(paths);
    
    % ===== SWEEP SETTINGS =====
    if ~isfield(Parameters, 'sweep_parameter')
        error('FD_ParameterSweep_Mode:MissingSweepParam', 'sweep_parameter not specified');
    end
    if ~isfield(Parameters, 'sweep_values')
        error('FD_ParameterSweep_Mode:MissingSweepValues', 'sweep_values not specified');
    end
    
    sweep_param = Parameters.sweep_parameter;
    sweep_values = Parameters.sweep_values;
    n_values = length(sweep_values);
    
    % Add parameter-specific directory
    PathBuilder.add_parameter_dir(paths, sweep_param);
    
    config_path = fullfile(paths.base, 'Config.mat');
    save(config_path, 'Run_Config', 'Parameters', 'Settings');
    
    % ===== MONITORING =====
    MonitorInterface.start(Run_Config, Settings);
    
    % ===== PARAMETER SWEEP =====
    tic;
    
    % Storage for sweep data
    sweep_results = cell(n_values, 1);
    QoI_array = zeros(n_values, 1);
    wall_times = zeros(n_values, 1);
    
    base_params = Parameters;
    
    for i = 1:n_values
        val = sweep_values(i);
        fprintf('\n--- Sweep %d/%d: %s=%.4g ---\n', i, n_values, sweep_param, val);
        
        % Update swept parameter
        params_i = base_params;
        params_i.(sweep_param) = val;
        params_i.mode = 'parametersweep';
        
        % Run simulation
        tic_sweep = tic;
        [fig_h, analysis] = Finite_Difference_Analysis(params_i);
        wall_times(i) = toc(tic_sweep);
        
        % Store results
        sweep_results{i} = analysis;
        
        % Extract QoI (use max_omega as default)
        if isfield(analysis, 'peak_vorticity')
            QoI_array(i) = analysis.peak_vorticity;
        else
            QoI_array(i) = NaN;
        end
        
        % Save figure
        if ishandle(fig_h) && Settings.save_figures
            sweep_name = sprintf('%s_%.4g', sweep_param, val);
            param_fig_dir = fullfile(paths.(matlab.lang.makeValidName(sweep_param)), 'Figures');
            if ~exist(param_fig_dir, 'dir')
                mkdir(param_fig_dir);
            end
            fig_path = fullfile(param_fig_dir, sprintf('%s.png', sweep_name));
            saveas(fig_h, fig_path);
            close(fig_h);
        end
    end
    
    total_time = toc;
    
    % ===== RESULTS =====
    Results = struct();
    Results.study_id = Run_Config.study_id;
    Results.sweep_parameter = sweep_param;
    Results.sweep_values = sweep_values;
    Results.QoI_array = QoI_array;
    Results.wall_times = wall_times;
    Results.sweep_results = sweep_results;
    Results.total_time = total_time;
    
    % ===== SAVE SWEEP PLOTS =====
    if Settings.save_figures
        generate_sweep_plots(Results, Run_Config, paths);
    end
    
    % ===== SAVE DATA =====
    if Settings.save_data
        save(fullfile(paths.data, 'sweep_data.mat'), 'Results', '-v7.3');
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
    MonitorInterface.stop(Run_Summary);
end

function generate_sweep_plots(Results, Run_Config, paths)
    % Generate parameter sweep analysis plots
    
    % Plot 1: QoI vs parameter value
    fig1 = figure('Visible', 'off');
    plot(Results.sweep_values, Results.QoI_array, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel(Results.sweep_parameter);
    ylabel('QoI (max vorticity)');
    title(sprintf('Parameter Sweep: %s', Results.sweep_parameter));
    grid on;
    fig_name = sprintf('%s__sweep_qoi.png', Run_Config.study_id);
    saveas(fig1, fullfile(paths.reports, fig_name));
    close(fig1);
    
    % Plot 2: Wall time vs parameter value
    fig2 = figure('Visible', 'off');
    plot(Results.sweep_values, Results.wall_times, 's-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel(Results.sweep_parameter);
    ylabel('Wall Time (s)');
    title('Computational Cost vs Parameter');
    grid on;
    fig_name = sprintf('%s__sweep_walltime.png', Run_Config.study_id);
    saveas(fig2, fullfile(paths.reports, fig_name));
    close(fig2);
    
    % Plot 3: Comparative visualization (if small number of sweeps)
    if length(Results.sweep_values) <= 6
        fig3 = figure('Visible', 'off', 'Position', [100 100 1200 800]);
        n_vals = length(Results.sweep_values);
        for i = 1:n_vals
            subplot(2, 3, i);
            analysis = Results.sweep_results{i};
            omega = analysis.omega_snaps(:, :, end);
            contourf(omega, 20, 'LineStyle', 'none');
            colorbar;
            title(sprintf('%s=%.4g', Results.sweep_parameter, Results.sweep_values(i)));
        end
        fig_name = sprintf('%s__sweep_comparison.png', Run_Config.study_id);
        saveas(fig3, fullfile(paths.reports, fig_name));
        close(fig3);
    end
end
