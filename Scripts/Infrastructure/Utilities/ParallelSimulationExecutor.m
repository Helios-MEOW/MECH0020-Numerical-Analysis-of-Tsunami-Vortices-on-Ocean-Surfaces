classdef ParallelSimulationExecutor < handle
    % PARALLELSIMULATIONEXECUTOR - Runs simulations in parallel with UI monitoring
    %
    % Purpose:
    %   Executes tsunami simulations in a background worker using parfeval
    %   Allows UI to remain responsive during simulation
    %   Provides independent monitoring timer for metrics collection
    %
    % Usage:
    %   executor = ParallelSimulationExecutor(ui_callback);
    %   executor.start(run_config, parameters, settings);
    %   ... UI remains responsive ...
    %   [results, paths] = executor.wait_for_completion();

    properties
        ui_progress_callback    % Callback for UI updates
        monitor_timer          % Timer for independent monitoring
        future_obj             % Future object from parfeval
        is_running             % Simulation running flag
        start_time             % Simulation start timestamp
        last_update_time       % Last UI update timestamp
        system_metrics         % Collected system metrics
        shared_data            % Shared data between workers
    end

    methods
        function obj = ParallelSimulationExecutor(ui_callback)
            % Constructor
            obj.ui_progress_callback = ui_callback;
            obj.is_running = false;
            obj.system_metrics = struct();
            obj.system_metrics.cpu_usage = [];
            obj.system_metrics.memory_usage = [];
            obj.system_metrics.timestamps = [];
        end

        function start(obj, run_config, parameters, settings)
            % Start simulation in background worker

            if obj.is_running
                warning('Simulation already running');
                return;
            end

            % Initialize state
            obj.is_running = true;
            obj.start_time = datetime('now');
            obj.last_update_time = tic;

            % Check for parallel pool
            pool = gcp('nocreate');
            if isempty(pool)
                % Create parallel pool if it doesn't exist
                try
                    pool = parpool('local', 'SpmdEnabled', false);
                catch ME
                    fprintf('Warning: Could not create parallel pool: %s\n', ME.message);
                    fprintf('Running simulation synchronously instead...\n');
                    % Fall back to synchronous execution
                    obj.run_synchronous(run_config, parameters, settings);
                    return;
                end
            end

            % Strip non-serializable fields (closures capturing UI
            % handles) before sending to the worker. The main-thread
            % monitor timer provides UI updates instead.
            worker_settings = settings;
            if isfield(worker_settings, 'ui_progress_callback')
                worker_settings = rmfield(worker_settings, 'ui_progress_callback');
            end

            % Start simulation in background using parfeval
            try
                obj.future_obj = parfeval(pool, @ModeDispatcher, 2, ...
                    run_config, parameters, worker_settings);
            catch ME
                fprintf('Error starting parallel simulation: %s\n', ME.message);
                obj.is_running = false;
                rethrow(ME);
            end

            % Start monitoring timer (updates every 100ms)
            obj.monitor_timer = timer(...
                'ExecutionMode', 'fixedRate', ...
                'Period', 0.1, ...  % 10 Hz update rate
                'TimerFcn', @(~,~) obj.monitor_callback(), ...
                'ErrorFcn', @(~,~) obj.handle_timer_error());

            start(obj.monitor_timer);
        end

        function [results, paths] = wait_for_completion(obj)
            % Wait for simulation to complete and return results

            if ~obj.is_running
                error('No simulation is running');
            end

            try
                % Wait for future to complete
                [results, paths] = fetchOutputs(obj.future_obj);

                % Stop monitoring timer
                if ~isempty(obj.monitor_timer) && isvalid(obj.monitor_timer)
                    stop(obj.monitor_timer);
                    delete(obj.monitor_timer);
                    obj.monitor_timer = [];
                end

                obj.is_running = false;

            catch ME
                % Clean up on error
                obj.cleanup();
                rethrow(ME);
            end
        end

        function cancel(obj)
            % Cancel running simulation

            if ~obj.is_running
                return;
            end

            try
                if ~isempty(obj.future_obj)
                    cancel(obj.future_obj);
                end
            catch
                % Ignore cancellation errors
            end

            obj.cleanup();
        end

        function progress = get_progress(obj)
            % Get current simulation progress (0 to 1)

            if ~obj.is_running
                progress = 0;
                return;
            end

            % Check if future has progress information
            if ~isempty(obj.future_obj) && strcmp(obj.future_obj.State, 'running')
                % Progress is not directly available from parfeval
                % We'll rely on the callback to track this
                progress = 0.5;  % Placeholder - actual progress via callback
            else
                progress = 0;
            end
        end
    end

    methods (Access = private)
        function monitor_callback(obj)
            % Called by timer to update UI and collect metrics

            if ~obj.is_running
                return;
            end

            % Collect system metrics
            try
                % Get memory usage
                mem_info = memory;
                mem_used_mb = mem_info.MemUsedMATLAB / 1024^2;

                % Get CPU usage (Windows-specific)
                if ispc
                    [~, cpu_str] = system('wmic cpu get loadpercentage');
                    cpu_lines = strsplit(strtrim(cpu_str), '\n');
                    if numel(cpu_lines) >= 2
                        cpu_usage = str2double(cpu_lines{2});
                    else
                        cpu_usage = NaN;
                    end
                else
                    cpu_usage = NaN;  % Platform-specific implementation needed
                end

                % Store metrics
                obj.system_metrics.cpu_usage(end+1) = cpu_usage;
                obj.system_metrics.memory_usage(end+1) = mem_used_mb;
                obj.system_metrics.timestamps(end+1) = toc(obj.last_update_time);

                % Create metrics payload for UI
                payload = struct();
                payload.cpu_usage = cpu_usage;
                payload.memory_usage = mem_used_mb;
                payload.elapsed_time = seconds(datetime('now') - obj.start_time);
                payload.is_background_update = true;  % Flag for UI to know this is a timer update

                % Call UI callback
                if ~isempty(obj.ui_progress_callback)
                    try
                        obj.ui_progress_callback(payload);
                    catch ME
                        fprintf('Warning: UI callback error: %s\n', ME.message);
                    end
                end

            catch ME
                fprintf('Warning: Monitoring error: %s\n', ME.message);
            end

            % Force UI update
            drawnow limitrate;
        end

        function handle_timer_error(obj)
            % Handle timer errors
            fprintf('Monitor timer error occurred\n');
            obj.cleanup();
        end

        function cleanup(obj)
            % Clean up resources

            obj.is_running = false;

            if ~isempty(obj.monitor_timer) && isvalid(obj.monitor_timer)
                try
                    stop(obj.monitor_timer);
                    delete(obj.monitor_timer);
                catch
                    % Ignore cleanup errors
                end
                obj.monitor_timer = [];
            end

            if ~isempty(obj.future_obj)
                try
                    cancel(obj.future_obj);
                catch
                    % Ignore cancellation errors
                end
                obj.future_obj = [];
            end
        end

        function run_synchronous(obj, run_config, parameters, settings)
            % Fallback to synchronous execution if parallel fails

            try
                % Run simulation directly
                [results, paths] = ModeDispatcher(run_config, parameters, settings);

                % Store results for retrieval
                obj.shared_data = struct('results', results, 'paths', paths);
                obj.is_running = false;

            catch ME
                obj.is_running = false;
                rethrow(ME);
            end
        end
    end
end
