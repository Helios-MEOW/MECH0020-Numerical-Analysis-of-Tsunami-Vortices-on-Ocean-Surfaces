function initialize_directory_structure(settings, Parameters)
% ========================================================================
% DIRECTORY STRUCTURE INITIALIZATION
% ========================================================================
% Purpose:
%   Creates and verifies the complete directory hierarchy required for
%   organized file management across all simulation modes (evolution,
%   convergence, sweep, animation, experimentation).
%
% Inputs:
%   settings    - Struct containing results_dir, figures.root_dir paths
%   Parameters  - Struct containing analysis_method and energy_monitoring.output_dir
%
% Outputs:
%   None (creates directories on disk)
%
% Directory Structure:
%   Results/
%     └── [Method]/
%         ├── Evolution/
%         ├── Convergence/
%         │   ├── Iterations/
%         │   └── Refined Meshes/
%         ├── Sweep/
%         │   ├── Viscosity/
%         │   ├── Timestep/
%         │   └── Coefficient/
%         ├── Animations/
%         │   ├── Convergence/
%         │   └── Experimentation/
%         └── Experimentation/
%             ├── Double Vortex/
%             ├── Three Vortex/
%             ├── Non-Uniform BC/
%             ├── Gaussian Merger/
%             └── Counter-Rotating Pair/
%   Data/
%   Logs/
%   Cache/
%   [Sustainability Output Directory]/
%
% Notes:
%   - This function is part of the Infrastructure layer and should NOT
%     be modified during normal simulation research.
%   - Directory structure supports organized output for all analysis modes.
%   - Automatically creates missing directories without overwriting existing ones.
%
% ========================================================================

    % Initialize directory collection (pre-allocate with known size)
    % 6 root + 1 method + 5 modes + 3 sweep + 2 animation + 5 test cases + 2 convergence = 24
    test_cases_list = {'Double Vortex', 'Three Vortex', 'Non-Uniform BC', 'Gaussian Merger', 'Counter-Rotating Pair'};
    n_dirs = 24;
    dirs = cell(1, n_dirs);
    method = Parameters.analysis_method;
    idx = 0;
    
    % ====== ROOT DIRECTORIES ======
    idx = idx + 1; dirs{idx} = settings.results_dir;
    idx = idx + 1; dirs{idx} = settings.figures.root_dir;
    idx = idx + 1; dirs{idx} = Parameters.energy_monitoring.output_dir;
    idx = idx + 1; dirs{idx} = 'Data';
    idx = idx + 1; dirs{idx} = 'Logs';
    idx = idx + 1; dirs{idx} = 'Cache';
    
    % ====== METHOD-SPECIFIC DIRECTORIES ======
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method);
    
    % ====== MODE SUBDIRECTORIES (under method) ======
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Evolution');
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Convergence');
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Sweep');
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Animations');
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Experimentation');
    
    % ====== PARAMETER SWEEP SUBDIRECTORIES ======
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Sweep', 'Viscosity');
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Sweep', 'Timestep');
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Sweep', 'Coefficient');
    
    % ====== ANIMATION DIRECTORIES ======
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Animations', 'Convergence');
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Animations', 'Experimentation');
    
    % ====== TEST CASE SUBDIRECTORIES (under Experimentation) ======
    for tc_idx = 1:length(test_cases_list)
        test_case_name = test_cases_list{tc_idx};
        idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Experimentation', test_case_name);
    end
    
    % ====== CONVERGENCE DIRECTORIES ======
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Convergence', 'Iterations');
    idx = idx + 1; dirs{idx} = fullfile(settings.figures.root_dir, method, 'Convergence', 'Refined Meshes');
    
    % Trim to actual count
    dirs = dirs(1:idx);
    
    % ====== CREATE ALL DIRECTORIES ======
    fprintf('\n[INIT] Creating directory structure...\n');
    for d_idx = 1:length(dirs)
        dir_path = dirs{d_idx};
        if ~exist(dir_path, 'dir')
            mkdir(dir_path);
            fprintf('[DIR✓] Created: %s\n', dir_path);
        else
            fprintf('[DIR✓] Exists: %s\n', dir_path);
        end
    end
    
    fprintf('[INIT] Directory structure initialization complete\n\n');
end
