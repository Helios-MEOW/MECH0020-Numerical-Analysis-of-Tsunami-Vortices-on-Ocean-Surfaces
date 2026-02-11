%% MATLAB-Python Hardware Monitoring Integration
%  =====================================================
%
%  Purpose: Bridge between MATLAB simulations and Python hardware monitoring
%           Enables real-time energy tracking during numerical analysis
%
%  Usage:
%    >> monitor = HardwareMonitorBridge()
%    >> monitor.start_logging('experimentation_vortex_pair')
%    >> % Run simulation...
%    >> log_file = monitor.stop_logging()
%    >> stats = monitor.get_statistics()
%
% =====================================================

classdef HardwareMonitorBridge < handle
    % Bridge class for MATLAB-Python hardware monitoring integration
    %
    % Design intent:
    %   Keep MATLAB solver code decoupled from sensor polling internals.
    %   MATLAB sees a small API (start/stop/stats/report) while Python
    %   handles device-specific telemetry collection.
    
    properties (SetAccess = private)
        python_script_path     % Path to hardware_monitor.py
        logging_process        % Python subprocess handle
        log_file_path          % Current log file being written
        is_logging = false     % Logging state flag
        simulation_metrics     % Metrics from MATLAB simulation
        hardware_metrics       % Metrics from hardware monitoring
        experiment_name        % Current experiment identifier
        py_logger              % Python SensorDataLogger instance
    end
    
    methods
        function obj = HardwareMonitorBridge(varargin)
            % Initialize hardware monitor bridge
            %
            % Usage:
            %   monitor = HardwareMonitorBridge()
            %   monitor = HardwareMonitorBridge('path/to/hardware_monitor.py')
            
            % Check Python availability
            pe = pyenv;
            if pe.Status == "NotLoaded"
                error('Python is not available. Run: pyenv(''Version'', ''C:\\Python311\\python.exe'')');
            end
            
            % Set hardware_monitor.py path
            if nargin > 0
                obj.python_script_path = varargin{1};
            else
                % Default: same directory as this file
                obj.python_script_path = fullfile(fileparts(mfilename('fullpath')), 'hardware_monitor.py');
            end
            
            % Verify script exists
            if ~isfile(obj.python_script_path)
                error('hardware_monitor.py not found at: %s', obj.python_script_path);
            end
            
            % Add script directory to Python path
            script_dir = fileparts(obj.python_script_path);
            if count(py.sys.path, script_dir) == 0
                insert(py.sys.path, int32(0), script_dir);
            end
            
            % Import the hardware_monitor module
            try
                py.importlib.import_module('hardware_monitor');
            catch ME
                error('Failed to import hardware_monitor module: %s', ME.message);
            end
            
            % Create Python logger instance.
            % Raw sensor logs are stored outside run folders so a single
            % sensor stream can be reused for comparative studies.
            obj.py_logger = py.hardware_monitor.SensorDataLogger(...
                pyargs('output_dir', '../../sensor_logs', 'interval', 0.5));  % Relative to Scripts/Sustainability/
            
            fprintf('[MONITOR] Initialized. Python script: %s\n', obj.python_script_path);
        end
        
        function start_logging(obj, experiment_name)
            % Start hardware monitoring in background
            %
            % Args:
            %   experiment_name (string): Identifier for this experiment
            %
            % Example:
            %   monitor.start_logging('CONVERGENCE_epsilon_0p01')
            
            if obj.is_logging
                warning('Logging already in progress');
                return;
            end
            
            obj.experiment_name = experiment_name;
            
            try
                % Call Python logger's start_logging method
                log_file_py = obj.py_logger.start_logging(char(experiment_name));
                
                % Convert Python Path object to string using Python's str()
                log_file_str = py.str(log_file_py);
                obj.log_file_path = char(log_file_str);
                
                obj.is_logging = true;
                fprintf('[MONITOR] Started logging: %s\n', experiment_name);
            catch ME
                error('Failed to start Python logging: %s', ME.message);
            end
        end
        
        function log_file = stop_logging(obj)
            % Stop hardware monitoring and save data
            %
            % Returns:
            %   log_file (string): Path to saved sensor log CSV
            
            if ~obj.is_logging
                warning('Logging not in progress');
                log_file = '';
                return;
            end
            
            try
                % Call Python logger's stop_logging method
                log_file_py = obj.py_logger.stop_logging();
                
                % Convert Python Path object to string using Python's str()
                log_file_str = py.str(log_file_py);
                obj.log_file_path = char(log_file_str);
                
                obj.is_logging = false;
                log_file = obj.log_file_path;
                
                fprintf('[MONITOR] Stopped logging. File: %s\n', obj.log_file_path);
            catch ME
                error('Failed to stop Python logging: %s', ME.message);
            end
        end
        
        function stats = get_statistics(obj)
            % Get statistics from logged hardware data
            %
            % Returns:
            %   stats (struct): Statistics including energy, temperature, etc.
            
            if isempty(obj.log_file_path)
                error('No log file. Start and stop logging first.');
            end
            
            try
                % Load and analyze CSV file
                T = readtable(obj.log_file_path);
                
                stats = struct();
                stats.num_samples = height(T);
                stats.duration_seconds = T.timestamp(end) - T.timestamp(1);
                
                % Temperature stats
                valid_temps = T.cpu_temp(~isnan(T.cpu_temp));
                if ~isempty(valid_temps)
                    stats.cpu_temp_mean = mean(valid_temps);
                    stats.cpu_temp_max = max(valid_temps);
                    stats.cpu_temp_min = min(valid_temps);
                end
                
                % CPU load stats
                stats.cpu_load_mean = mean(T.cpu_load);
                stats.cpu_load_max = max(T.cpu_load);
                
                % RAM stats
                stats.ram_usage_mean = mean(T.ram_usage);
                stats.ram_usage_max = max(T.ram_usage);
                stats.ram_percent_mean = mean(T.ram_percent);
                
                % Power stats (optional fields depending on platform/tooling)
                valid_powers = T.power_consumption(~isnan(T.power_consumption));
                if ~isempty(valid_powers)
                    stats.power_mean = mean(valid_powers);
                    stats.power_max = max(valid_powers);
                    
                    % Energy integral: E = ∫P dt
                    dt = diff(T.timestamp(1:length(valid_powers)));
                    if length(dt) == length(valid_powers) - 1
                        energy_joules = sum(valid_powers(1:end-1) .* dt);
                        stats.energy_joules = energy_joules;
                        stats.energy_wh = energy_joules / 3600;
                    end
                end
                
                fprintf('[MONITOR] Statistics computed from %d samples over %.1f seconds\n', ...
                    stats.num_samples, stats.duration_seconds);
                
            catch ME
                error('Failed to compute statistics: %s', ME.message);
            end
        end
        
        function report = generate_report(obj, output_file)
            % Generate sustainability analysis report
            %
            % Args:
            %   output_file (string, optional): File to save JSON report
            %
            % Returns:
            %   report (struct): Analysis report
            
            if ~obj.is_logging
                stats = obj.get_statistics();
            else
                warning('Logging still in progress');
                stats = struct();
            end
            
            report = struct();
            report.experiment = obj.experiment_name;
            report.log_file = obj.log_file_path;
            report.timestamp = datetime('now');
            report.hardware_metrics = stats;
            
            if nargin > 1
                % Save machine-readable report for downstream aggregators.
                try
                    json_str = jsonencode(report);
                    fid = fopen(output_file, 'w');
                    fprintf(fid, '%s', json_str);
                    fclose(fid);
                    fprintf('[MONITOR] Report saved: %s\n', output_file);
                catch ME
                    warning(ME.identifier, '%s', ME.message);
                end
            end
        end
        
        function correlate_with_simulation(obj, simulation_metrics)
            % Correlate hardware metrics with simulation metrics
            %
            % Args:
            %   simulation_metrics (struct): Metrics from MATLAB simulation
            %                                (e.g., max_vorticity, convergence_rate)
            %
            % Usage:
            %   sim_metrics = struct('max_vorticity', 5.2, 'grid_size', 256);
            %   monitor.correlate_with_simulation(sim_metrics);
            
            obj.simulation_metrics = simulation_metrics;
            
            % Get hardware stats
            hw_stats = obj.get_statistics();
            obj.hardware_metrics = hw_stats;
            
            % Emit a concise terminal report for exploratory debugging.
            fprintf('\n%s\n', repmat('=', 1, 70));
            fprintf('ENERGY-SIMULATION CORRELATION ANALYSIS\n');
            fprintf('%s\n', repmat('=', 1, 70));
            
            fprintf('\nSimulation Metrics:\n');
            fn = fieldnames(simulation_metrics);
            for i = 1:length(fn)
                fprintf('  %s: %g\n', fn{i}, simulation_metrics.(fn{i}));
            end
            
            fprintf('\nHardware Metrics:\n');
            if isfield(hw_stats, 'energy_wh')
                fprintf('  Energy: %.3f Wh (%.0f J)\n', hw_stats.energy_wh, hw_stats.energy_joules);
            end
            if isfield(hw_stats, 'power_mean')
                fprintf('  Avg Power: %.1f W\n', hw_stats.power_mean);
            end
            if isfield(hw_stats, 'cpu_temp_mean')
                fprintf('  Avg Temp: %.1f°C\n', hw_stats.cpu_temp_mean);
            end
            fprintf('  Duration: %.1f seconds\n', hw_stats.duration_seconds);
            
            fprintf('%s\n\n', repmat('=', 1, 70));
        end
        
        function comparison = compare_runs(~, log_files, labels)
            % Compare energy metrics across multiple runs
            %
            % Args:
            %   log_files (cell array): List of log file paths
            %   labels (cell array): Labels for each run
            %
            % Returns:
            %   comparison (struct): Comparative analysis
            
            if length(log_files) ~= length(labels)
                error('log_files and labels must have same length');
            end
            
            comparison = struct();
            comparison.num_runs = length(log_files);
            comparison.runs = struct();
            
            fprintf('\n%s\n', repmat('=', 1, 70));
            fprintf('COMPARATIVE ANALYSIS: %d RUNS\n', length(log_files));
            fprintf('%s\n', repmat('=', 1, 70));
            
            for i = 1:length(log_files)
                try
                    T = readtable(log_files{i});
                    
                    % Compute stats
                    run_stats = struct();
                    run_stats.duration = T.timestamp(end) - T.timestamp(1);
                    
                    valid_powers = T.power_consumption(~isnan(T.power_consumption));
                    if ~isempty(valid_powers)
                        dt = diff(T.timestamp(1:length(valid_powers)));
                        energy = sum(valid_powers(1:end-1) .* dt);
                        run_stats.energy_joules = energy;
                        run_stats.energy_wh = energy / 3600;
                        run_stats.power_mean = mean(valid_powers);
                    end
                    
                    valid_temps = T.cpu_temp(~isnan(T.cpu_temp));
                    if ~isempty(valid_temps)
                        run_stats.cpu_temp_mean = mean(valid_temps);
                        run_stats.cpu_temp_max = max(valid_temps);
                    end
                    
                    comparison.runs.(matlab.lang.makeValidName(labels{i})) = run_stats;
                    
                    % Print summary
                    fprintf('\nRun %d: %s\n', i, labels{i});
                    fprintf('  Duration:     %.1f s\n', run_stats.duration);
                    if isfield(run_stats, 'energy_wh')
                        fprintf('  Energy:       %.3f Wh\n', run_stats.energy_wh);
                        fprintf('  Avg Power:    %.1f W\n', run_stats.power_mean);
                    end
                    if isfield(run_stats, 'cpu_temp_mean')
                        fprintf('  Avg Temp:     %.1f°C\n', run_stats.cpu_temp_mean);
                    end
                
                catch ME
                    fprintf('  ERROR: %s\n', ME.message);
                end
            end
            
            fprintf('%s\n\n', repmat('=', 1, 70));
        end
    end
end
