function storage = ensure_results_storage_ready(repo_root, varargin)
% ensure_results_storage_ready - Create/verify core Results storage layout
%
% Purpose:
%   Ensure the Results storage roots exist before runs/tests start.
%   This preflight only prepares storage directories; run-specific folders
%   are still created by PathBuilder during actual mode execution.
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
    methods = {'FD', 'Spectral', 'FV', 'Bathymetry'};
    modes = {'Evolution', 'Convergence', 'ParameterSweep', 'Plotting'};

    n_dir_roots = 1 + numel(methods) + (numel(methods) * numel(modes));
    dir_list = cell(1, n_dir_roots);
    idx = 1;
    dir_list{idx} = results_root;
    for i = 1:numel(methods)
        method_root = fullfile(results_root, methods{i});
        idx = idx + 1;
        dir_list{idx} = method_root;
        for j = 1:numel(modes)
            idx = idx + 1;
            dir_list{idx} = fullfile(method_root, modes{j});
        end
    end

    created_dirs = cell(1, numel(dir_list));
    existing_dirs = cell(1, numel(dir_list));
    n_created = 0;
    n_existing = 0;
    for k = 1:numel(dir_list)
        d = dir_list{k};
        if exist(d, 'dir')
            n_existing = n_existing + 1;
            existing_dirs{n_existing} = d;
        else
            mkdir(d);
            n_created = n_created + 1;
            created_dirs{n_created} = d;
        end
    end

    master_table_path = fullfile(results_root, 'Runs_Table.csv');
    master_parent = fileparts(master_table_path);
    if ~exist(master_parent, 'dir')
        mkdir(master_parent);
        n_created = n_created + 1;
        created_dirs{n_created} = master_parent;
    end

    created_dirs = created_dirs(1:n_created);
    existing_dirs = existing_dirs(1:n_existing);

    if verbose
        fprintf('\n[Storage Preflight] Results storage check\n');
        fprintf('  Repo root:      %s\n', repo_root);
        fprintf('  Results root:   %s\n', results_root);
        fprintf('  Master CSV dir: %s\n', master_parent);
        fprintf('  Created dirs:   %d\n', numel(created_dirs));
        fprintf('  Existing dirs:  %d\n\n', numel(existing_dirs));
    end

    storage = struct();
    storage.repo_root = repo_root;
    storage.results_root = results_root;
    storage.master_table_path = master_table_path;
    storage.created_dirs = created_dirs;
    storage.existing_dirs = existing_dirs;
end
