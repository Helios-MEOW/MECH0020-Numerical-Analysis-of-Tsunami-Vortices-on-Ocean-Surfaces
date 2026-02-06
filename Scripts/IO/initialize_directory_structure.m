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

    % Initialize directory collection
    dirs = {};
    method = Parameters.analysis_method;
    
    % ====== ROOT DIRECTORIES ======
    dirs{end+1} = settings.results_dir;
    dirs{end+1} = settings.figures.root_dir;
    dirs{end+1} = Parameters.energy_monitoring.output_dir;
    dirs{end+1} = 'Data';
    dirs{end+1} = 'Logs';
    dirs{end+1} = 'Cache';
    
    % ====== METHOD-SPECIFIC DIRECTORIES ======
    dirs{end+1} = fullfile(settings.figures.root_dir, method);
    
    % ====== MODE SUBDIRECTORIES (under method) ======
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Evolution');
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Convergence');
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Sweep');
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Animations');
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Experimentation');
    
    % ====== PARAMETER SWEEP SUBDIRECTORIES ======
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Sweep', 'Viscosity');
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Sweep', 'Timestep');
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Sweep', 'Coefficient');
    
    % ====== ANIMATION DIRECTORIES ======
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Animations');
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Animations', 'Convergence');
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Animations', 'Experimentation');
    
    % ====== TEST CASE SUBDIRECTORIES (under Experimentation) ======
    test_cases_list = {'Double Vortex', 'Three Vortex', 'Non-Uniform BC', 'Gaussian Merger', 'Counter-Rotating Pair'};
    for tc_idx = 1:length(test_cases_list)
        test_case_name = test_cases_list{tc_idx};
        dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Experimentation', test_case_name);
    end
    
    % ====== CONVERGENCE DIRECTORIES ======
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Convergence', 'Iterations');
    dirs{end+1} = fullfile(settings.figures.root_dir, method, 'Convergence', 'Refined Meshes');
    
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
