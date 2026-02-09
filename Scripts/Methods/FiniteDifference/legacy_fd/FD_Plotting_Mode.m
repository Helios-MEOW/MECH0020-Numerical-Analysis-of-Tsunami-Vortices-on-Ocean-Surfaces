function [Results, paths] = FD_Plotting_Mode(Run_Config, Parameters, Settings)
    % FD_Plotting_Mode - Standalone plotting/visualization mode
    %
    % Purpose:
    %   Generate figures from saved data
    %   Recreate plots without rerunning simulations
    %   Support "recreate from PNG" workflow
    %
    % Inputs:
    %   Run_Config - method, mode, source_run_id or data_path
    %   Parameters - plotting configuration
    %   Settings - IO, monitoring, logging
    %
    % Outputs:
    %   Results - plotting metadata
    %   paths - directory structure
    %
    % Plotting Parameters:
    %   source_run_id - run to load data from (for recreate-from-PNG)
    %   plot_types - cell array of plot types to generate
    
    % ===== SETUP =====
    paths = PathBuilder.get_run_paths(Run_Config.method, Run_Config.mode, '');
    paths.base = fullfile(PathBuilder.get_repo_root(), 'Results', Run_Config.method, Run_Config.mode);
    
    % Create figure type directories
    if isfield(Parameters, 'plot_types')
        plot_types = Parameters.plot_types;
    else
        plot_types = {'contours', 'streamlines', 'evolution'};
    end
    
    for i = 1:length(plot_types)
        plot_dir = fullfile(paths.base, plot_types{i});
        if ~exist(plot_dir, 'dir')
            mkdir(plot_dir);
        end
        paths.(plot_types{i}) = plot_dir;
    end
    
    % ===== LOAD SOURCE DATA =====
    if isfield(Run_Config, 'source_run_id') && ~isempty(Run_Config.source_run_id)
        % Load from specific run
        source_run_id = Run_Config.source_run_id;
        
        % Find run directory (check Evolution, Convergence, ParameterSweep)
        modes_to_check = {'Evolution', 'Convergence', 'ParameterSweep'};
        data_loaded = false;
        
        for m = 1:length(modes_to_check)
            source_path = fullfile(PathBuilder.get_repo_root(), 'Results', ...
                Run_Config.method, modes_to_check{m}, source_run_id, 'Data', 'results.mat');
            
            if exist(source_path, 'file')
                fprintf('Loading data from: %s\n', source_path);
                loaded = load(source_path);
                analysis = loaded.analysis;
                
                % Load config too
                config_path = fullfile(PathBuilder.get_repo_root(), 'Results', ...
                    Run_Config.method, modes_to_check{m}, source_run_id, 'Config.mat');
                if exist(config_path, 'file')
                    config_data = load(config_path);
                    Parameters_source = config_data.Parameters;
                else
                    Parameters_source = Parameters;
                end
                
                data_loaded = true;
                break;
            end
        end
        
        if ~data_loaded
            error('FD_Plotting_Mode:DataNotFound', ...
                'Could not find data for run_id: %s', source_run_id);
        end
    else
        error('FD_Plotting_Mode:NoSourceSpecified', ...
            'Must specify source_run_id for plotting mode');
    end
    
    % ===== GENERATE PLOTS =====
    tic;
    
    fprintf('Generating plots for run: %s\n', source_run_id);
    
    % Generate requested plot types
    for i = 1:length(plot_types)
        fprintf('  Creating %s plots...\n', plot_types{i});
        
        switch plot_types{i}
            case 'contours'
                generate_contour_plots(analysis, Parameters_source, source_run_id, paths.contours);
            case 'streamlines'
                generate_streamline_plots(analysis, Parameters_source, source_run_id, paths.streamlines);
            case 'evolution'
                generate_evolution_plots(analysis, Parameters_source, source_run_id, paths.evolution);
            otherwise
                warning('Unknown plot type: %s', plot_types{i});
        end
    end
    
    total_time = toc;
    
    % ===== RESULTS =====
    Results = struct();
    Results.source_run_id = source_run_id;
    Results.plot_types = plot_types;
    Results.total_time = total_time;
    Results.plots_generated = true;
    
    fprintf('Plotting completed in %.2f seconds\n', total_time);
end

function generate_contour_plots(analysis, Parameters, run_id, output_dir)
    % Generate vorticity contour plots
    omega_snaps = analysis.omega_snaps;
    time_vec = analysis.time_vec;
    
    Lx = Parameters.Lx;
    Ly = Parameters.Ly;
    Nx = Parameters.Nx;
    Ny = Parameters.Ny;
    x = linspace(0, Lx, Nx);
    y = linspace(0, Ly, Ny);
    [X, Y] = meshgrid(x, y);
    
    n_snaps = size(omega_snaps, 3);
    snap_indices = unique(round(linspace(1, n_snaps, min(5, n_snaps))));
    
    for idx = snap_indices
        fig = figure('Visible', 'off');
        contourf(X, Y, omega_snaps(:, :, idx), 20, 'LineStyle', 'none');
        colorbar;
        title(sprintf('Vorticity at t=%.3f', time_vec(idx)));
        xlabel('x'); ylabel('y');
        
        fig_name = RunIDGenerator.make_figure_filename(run_id, 'contour', sprintf('t%.3f', time_vec(idx)));
        saveas(fig, fullfile(output_dir, fig_name));
        close(fig);
    end
end

function generate_streamline_plots(analysis, Parameters, run_id, output_dir)
    % Generate streamline plots
    omega_snaps = analysis.omega_snaps;
    psi_snaps = analysis.psi_snaps;
    time_vec = analysis.time_vec;
    
    Lx = Parameters.Lx;
    Ly = Parameters.Ly;
    Nx = Parameters.Nx;
    Ny = Parameters.Ny;
    x = linspace(0, Lx, Nx);
    y = linspace(0, Ly, Ny);
    [X, Y] = meshgrid(x, y);
    
    n_snaps = size(omega_snaps, 3);
    snap_indices = unique(round(linspace(1, n_snaps, min(5, n_snaps))));
    
    for idx = snap_indices
        fig = figure('Visible', 'off');
        contourf(X, Y, omega_snaps(:, :, idx), 20, 'LineStyle', 'none');
        hold on;
        contour(X, Y, psi_snaps(:, :, idx), 15, 'k', 'LineWidth', 0.8);
        colorbar;
        title(sprintf('Vorticity + Streamlines at t=%.3f', time_vec(idx)));
        xlabel('x'); ylabel('y');
        
        fig_name = RunIDGenerator.make_figure_filename(run_id, 'streamlines', sprintf('t%.3f', time_vec(idx)));
        saveas(fig, fullfile(output_dir, fig_name));
        close(fig);
    end
end

function generate_evolution_plots(analysis, Parameters, run_id, output_dir)
    % Generate time evolution plots (energy, enstrophy)
    time_vec = analysis.time_vec;
    
    % Energy evolution
    if isfield(analysis, 'kinetic_energy') && ~isempty(analysis.kinetic_energy)
        fig1 = figure('Visible', 'off');
        plot(time_vec, analysis.kinetic_energy, 'LineWidth', 2);
        xlabel('Time'); ylabel('Kinetic Energy');
        title('Energy Evolution');
        grid on;
        fig_name = RunIDGenerator.make_figure_filename(run_id, 'energy', 'evolution');
        saveas(fig1, fullfile(output_dir, fig_name));
        close(fig1);
    end
    
    % Enstrophy evolution
    if isfield(analysis, 'enstrophy') && ~isempty(analysis.enstrophy)
        fig2 = figure('Visible', 'off');
        plot(time_vec, analysis.enstrophy, 'LineWidth', 2);
        xlabel('Time'); ylabel('Enstrophy');
        title('Enstrophy Evolution');
        grid on;
        fig_name = RunIDGenerator.make_figure_filename(run_id, 'enstrophy', 'evolution');
        saveas(fig2, fullfile(output_dir, fig_name));
        close(fig2);
    end
end
