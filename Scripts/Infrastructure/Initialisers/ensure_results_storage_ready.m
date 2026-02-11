function storage = ensure_results_storage_ready(repo_root, varargin)
% ensure_results_storage_ready - Create/verify Results + Figures storage layout
%
% Purpose:
%   Ensure the shared Results and Figures storage roots exist before
%   runs/tests start. This preflight prepares common roots; run-specific
%   folders are still created by PathBuilder during mode execution.
%
% Inputs:
%   repo_root (optional) - repository root path
%
% Name-Value:
%   'Verbose' (default true) - print created/existing directories summary
%
% Outputs:
%   storage struct with fields:
%     .repo_root
%     .results_root
%     .figures_root
%     .master_table_path
%     .created_dirs
%     .existing_dirs

    p = inputParser;
    addOptional(p, 'repo_root', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'Verbose', true, @islogical);
    parse(p, repo_root, varargin{:});

    repo_root = char(string(p.Results.repo_root));
    verbose = p.Results.Verbose;

    if isempty(repo_root)
        if exist('PathBuilder', 'class') == 8 || exist('PathBuilder', 'file') == 2
            repo_root = PathBuilder.get_repo_root();
        else
            this_dir = fileparts(mfilename('fullpath'));
            repo_root = fileparts(fileparts(fileparts(this_dir)));
        end
    end

    results_root = fullfile(repo_root, 'Results');
    figures_root = fullfile(repo_root, 'Figures');

    result_dir_list = build_results_layout(results_root);
    figure_dir_list = build_figure_layout(figures_root);

    [created_results_dirs, existing_results_dirs] = ensure_directory_list(result_dir_list);
    [created_figure_dirs, existing_figure_dirs] = ensure_directory_list(figure_dir_list);

    master_table_path = fullfile(results_root, 'Runs_Table.csv');
    master_parent = fileparts(master_table_path);
    if ~exist(master_parent, 'dir')
        mkdir(master_parent);
        created_results_dirs{end + 1} = master_parent;
    end

    created_dirs = [created_results_dirs, created_figure_dirs];
    existing_dirs = [existing_results_dirs, existing_figure_dirs];

    if verbose
        fprintf('\n[Storage Preflight] Results + figures storage check\n');
        fprintf('  Repo root:      %s\n', repo_root);
        fprintf('  Results root:   %s\n', results_root);
        fprintf('  Figures root:   %s\n', figures_root);
        fprintf('  Master CSV dir: %s\n', master_parent);
        fprintf('  Created (Results/Figures): %d / %d\n', ...
            numel(created_results_dirs), numel(created_figure_dirs));
        fprintf('  Existing (Results/Figures): %d / %d\n\n', ...
            numel(existing_results_dirs), numel(existing_figure_dirs));
    end

    storage = struct();
    storage.repo_root = repo_root;
    storage.results_root = results_root;
    storage.figures_root = figures_root;
    storage.master_table_path = master_table_path;
    storage.created_results_dirs = created_results_dirs;
    storage.existing_results_dirs = existing_results_dirs;
    storage.created_figure_dirs = created_figure_dirs;
    storage.existing_figure_dirs = existing_figure_dirs;
    storage.created_dirs = created_dirs;
    storage.existing_dirs = existing_dirs;
end

function dir_list = build_results_layout(results_root)
    methods = {'FD', 'Spectral', 'FV', 'Bathymetry'};
    modes = {'Evolution', 'Convergence', 'ParameterSweep', 'Plotting'};

    n_dir_roots = 2 + numel(methods) + (numel(methods) * numel(modes));
    dir_list = cell(1, n_dir_roots);
    idx = 1;
    dir_list{idx} = results_root;
    idx = idx + 1;
    dir_list{idx} = fullfile(results_root, 'Sustainability');
    for i = 1:numel(methods)
        method_root = fullfile(results_root, methods{i});
        idx = idx + 1;
        dir_list{idx} = method_root;
        for j = 1:numel(modes)
            idx = idx + 1;
            dir_list{idx} = fullfile(method_root, modes{j});
        end
    end
end

function dir_list = build_figure_layout(figures_root)
    % Figure tree mirrors the latest layout used by directory initializer.
    methods = {'Finite Difference', 'Spectral', 'Finite Volume', 'Bathymetry'};
    mode_roots = {'Evolution', 'Convergence', 'Sweep', 'ParameterSweep', 'Animations', 'Experimentation'};
    sweep_families = {'Viscosity', 'Timestep', 'Coefficient'};
    animation_mode_dirs = {'solve', 'Convergence', 'Experimentation'};
    experimentation_cases = {'Double Vortex', 'Three Vortex', 'Non-Uniform BC', 'Gaussian Merger', 'Counter-Rotating Pair'};

    dir_list = {figures_root};
    for i = 1:numel(methods)
        method_root = fullfile(figures_root, methods{i});
        dir_list{end + 1} = method_root; %#ok<AGROW>

        for m = 1:numel(mode_roots)
            dir_list{end + 1} = fullfile(method_root, mode_roots{m}); %#ok<AGROW>
        end

        for s = 1:numel(sweep_families)
            dir_list{end + 1} = fullfile(method_root, 'Sweep', sweep_families{s}); %#ok<AGROW>
            dir_list{end + 1} = fullfile(method_root, 'ParameterSweep', sweep_families{s}); %#ok<AGROW>
        end

        for a = 1:numel(animation_mode_dirs)
            dir_list{end + 1} = fullfile(method_root, 'Animations', animation_mode_dirs{a}); %#ok<AGROW>
        end

        for c = 1:numel(experimentation_cases)
            dir_list{end + 1} = fullfile(method_root, 'Experimentation', experimentation_cases{c}); %#ok<AGROW>
        end

        dir_list{end + 1} = fullfile(method_root, 'Convergence', 'Iterations'); %#ok<AGROW>
        dir_list{end + 1} = fullfile(method_root, 'Convergence', 'Refined Meshes'); %#ok<AGROW>
    end
end

function [created_dirs, existing_dirs] = ensure_directory_list(dir_list)
    created_dirs = {};
    existing_dirs = {};

    for k = 1:numel(dir_list)
        d = dir_list{k};
        if exist(d, 'dir')
            existing_dirs{end + 1} = d; %#ok<AGROW>
        else
            mkdir(d);
            created_dirs{end + 1} = d; %#ok<AGROW>
        end
    end
end
