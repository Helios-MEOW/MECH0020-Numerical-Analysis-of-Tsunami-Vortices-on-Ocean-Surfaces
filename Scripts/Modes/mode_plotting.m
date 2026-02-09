function [Results, paths] = mode_plotting(Run_Config, ~, ~)
    % mode_plotting - METHOD-AGNOSTIC Plotting Mode
    %
    % Purpose:
    %   Loads existing simulation data and generates visualizations
    %   Method-agnostic (works with data from any method)
    %
    % Inputs:
    %   Run_Config - .source_run_id (required), .plot_types
    %   Parameters - plot settings
    %   Settings - IO settings
    %
    % Outputs:
    %   Results - plotting summary
    %   paths - directory structure

    % ===== VALIDATION =====
    if ~isfield(Run_Config, 'source_run_id') || isempty(Run_Config.source_run_id)
        error('Plotting mode requires Run_Config.source_run_id');
    end

    % ===== LOAD SOURCE DATA =====
    source_run_id = Run_Config.source_run_id;
    fprintf('[Plotting] Loading data from run: %s\n', source_run_id);

    % Attempt to load results (method-agnostic path search)
    data_path = find_run_data(source_run_id);
    if isempty(data_path)
        error('Could not find data for run_id: %s', source_run_id);
    end

    load(data_path, 'analysis');

    % ===== SETUP OUTPUT =====
    if ~isfield(Run_Config, 'run_id') || isempty(Run_Config.run_id)
        Run_Config.run_id = sprintf('plot_%s', source_run_id);
    end

    paths = PathBuilder.get_run_paths('Plotting', 'Plotting', Run_Config.run_id);
    PathBuilder.ensure_directories(paths);

    % ===== GENERATE PLOTS =====
    fprintf('[Plotting] Generating visualizations...\n');

    % Plot types
    if ~isfield(Run_Config, 'plot_types')
        plot_types = {'contours', 'evolution'};
    else
        plot_types = Run_Config.plot_types;
    end

    for k = 1:length(plot_types)
        switch lower(plot_types{k})
            case 'contours'
                generate_contour_plots(analysis, paths);
            case 'evolution'
                generate_evolution_plots(analysis, paths);
            case 'streamlines'
                generate_streamline_plots(analysis, paths);
            otherwise
                warning('Unknown plot type: %s', plot_types{k});
        end
    end

    % ===== RESULTS =====
    Results = struct();
    Results.source_run_id = source_run_id;
    Results.plot_types = plot_types;
    Results.status = 'completed';

    fprintf('[Plotting] Completed for run: %s\n', source_run_id);
end

%% ===== LOCAL FUNCTIONS =====

function data_path = find_run_data(run_id)
    % Search for run data (method-agnostic)
    search_dirs = {'Data/Output/FD/Evolution', 'Data/Output/Spectral/Evolution', 'Data/Output/FV/Evolution'};

    for k = 1:length(search_dirs)
        candidate = fullfile(search_dirs{k}, run_id, 'Data', 'results.mat');
        if exist(candidate, 'file')
            data_path = candidate;
            return;
        end
    end

    data_path = '';
end

function generate_contour_plots(analysis, paths)
    % Generate contour plots from snapshots
    if ~isfield(analysis, 'omega_snaps')
        return;
    end

    omega_snaps = analysis.omega_snaps;
    Nsnap = size(omega_snaps, 3);

    fig = figure('Position', [100, 100, 1200, 800]);
    ncols = min(4, Nsnap);
    nrows = ceil(Nsnap / ncols);

    for k = 1:Nsnap
        subplot(nrows, ncols, k);
        contourf(omega_snaps(:, :, k), 20, 'LineColor', 'none');
        axis equal tight;
        colormap(turbo);
        colorbar;
        title(sprintf('Snapshot %d', k));
    end

    sgtitle('Vorticity Contours');
    saveas(fig, fullfile(paths.figures_evolution, 'contours.png'));
    close(fig);
end

function generate_evolution_plots(analysis, paths)
    % Generate time evolution plots
    if ~isfield(analysis, 'time_vec')
        return;
    end

    fig = figure('Position', [100, 100, 1000, 600]);

    if isfield(analysis, 'kinetic_energy')
        subplot(2, 1, 1);
        plot(analysis.time_vec, analysis.kinetic_energy, 'LineWidth', 2);
        grid on;
        xlabel('Time');
        ylabel('Kinetic Energy');
        title('Energy Evolution');
    end

    if isfield(analysis, 'enstrophy')
        subplot(2, 1, 2);
        plot(analysis.time_vec, analysis.enstrophy, 'LineWidth', 2);
        grid on;
        xlabel('Time');
        ylabel('Enstrophy');
        title('Enstrophy Evolution');
    end

    sgtitle('Time Evolution');
    saveas(fig, fullfile(paths.figures_evolution, 'evolution.png'));
    close(fig);
end

function generate_streamline_plots(~, ~)
    % Generate streamline plots
    fprintf('[Plotting] Streamline plots not yet implemented\n');
end
