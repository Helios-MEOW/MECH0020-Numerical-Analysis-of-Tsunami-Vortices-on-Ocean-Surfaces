classdef MonitorInterface
    % MonitorInterface - Single entry point for all monitoring
    %
    % Purpose:
    %   Unified interface for live execution monitoring
    %   Called by any solver/mode to show progress
    %   Supports both Standard mode (dark theme terminal) and UI mode
    %
    % Usage:
    %   MonitorInterface.start(Run_Config, Settings);
    %   MonitorInterface.update(Run_Status);
    %   MonitorInterface.stop(Run_Summary);
    
    properties (Constant, Access = private)
        % ANSI color codes for terminal
        COLOR_RESET = '\033[0m';
        COLOR_GREEN = '\033[92m';
        COLOR_CYAN = '\033[96m';
        COLOR_YELLOW = '\033[93m';
        COLOR_RED = '\033[91m';
        COLOR_GRAY = '\033[90m';
    end
    
    methods (Static)
        function start(Run_Config, Settings)
            % Initialize monitor for a new run
            % Run_Config: method, mode, ic_type, run_id
            % Settings: monitor_enabled, monitor_theme, etc.
            
            if ~Settings.monitor_enabled
                return;
            end
            
            % Store in persistent state
            persistent monitor_state;
            monitor_state = struct();
            monitor_state.Run_Config = Run_Config;
            monitor_state.Settings = Settings;
            monitor_state.start_time = datetime('now');
            monitor_state.iteration = 0;
            
            % Display header
            if strcmp(Settings.monitor_theme, 'dark')
                MonitorInterface.print_dark_header(Run_Config);
            else
                MonitorInterface.print_light_header(Run_Config);
            end
        end
        
        function update(Run_Status)
            % Update monitor with current simulation state
            % Run_Status: step, time, dt, metrics (CFL, max_omega, etc.)
            
            persistent monitor_state;
            if isempty(monitor_state) || ~monitor_state.Settings.monitor_enabled
                return;
            end
            
            % Update iteration counter
            monitor_state.iteration = monitor_state.iteration + 1;
            
            % Throttle updates (update every 10th call to avoid spam)
            if mod(monitor_state.iteration, 10) ~= 0
                return;
            end
            
            % Display update
            if strcmp(monitor_state.Settings.monitor_theme, 'dark')
                MonitorInterface.print_dark_update(Run_Status, monitor_state);
            else
                MonitorInterface.print_light_update(Run_Status, monitor_state);
            end
        end
        
        function stop(Run_Summary)
            % Finalize monitor and display summary
            % Run_Summary: total_time, final_metrics, status
            
            persistent monitor_state;
            if isempty(monitor_state) || ~monitor_state.Settings.monitor_enabled
                return;
            end
            
            % Display footer
            if strcmp(monitor_state.Settings.monitor_theme, 'dark')
                MonitorInterface.print_dark_footer(Run_Summary, monitor_state);
            else
                MonitorInterface.print_light_footer(Run_Summary, monitor_state);
            end
            
            % Clear state
            monitor_state = [];
        end
    end
    
    methods (Static, Access = private)
        function print_dark_header(Run_Config)
            % Dark theme header
            fprintf('\n');
            fprintf('%s╔═══════════════════════════════════════════════════════╗%s\n', ...
                MonitorInterface.COLOR_CYAN, MonitorInterface.COLOR_RESET);
            fprintf('%s║         TSUNAMI VORTEX SIMULATION MONITOR            ║%s\n', ...
                MonitorInterface.COLOR_CYAN, MonitorInterface.COLOR_RESET);
            fprintf('%s╚═══════════════════════════════════════════════════════╝%s\n', ...
                MonitorInterface.COLOR_CYAN, MonitorInterface.COLOR_RESET);
            fprintf('%sMethod:%s %s  %s|%s  %sMode:%s %s  %s|%s  %sIC:%s %s\n', ...
                MonitorInterface.COLOR_GREEN, MonitorInterface.COLOR_RESET, Run_Config.method, ...
                MonitorInterface.COLOR_GRAY, MonitorInterface.COLOR_RESET, ...
                MonitorInterface.COLOR_GREEN, MonitorInterface.COLOR_RESET, Run_Config.mode, ...
                MonitorInterface.COLOR_GRAY, MonitorInterface.COLOR_RESET, ...
                MonitorInterface.COLOR_GREEN, MonitorInterface.COLOR_RESET, Run_Config.ic_type);
            fprintf('%s─────────────────────────────────────────────────────────%s\n', ...
                MonitorInterface.COLOR_GRAY, MonitorInterface.COLOR_RESET);
        end
        
        function print_light_header(Run_Config)
            % Light theme header (fallback)
            fprintf('\n');
            fprintf('═══════════════════════════════════════════════════════\n');
            fprintf('         TSUNAMI VORTEX SIMULATION MONITOR            \n');
            fprintf('═══════════════════════════════════════════════════════\n');
            fprintf('Method: %s  |  Mode: %s  |  IC: %s\n', ...
                Run_Config.method, Run_Config.mode, Run_Config.ic_type);
            fprintf('───────────────────────────────────────────────────────\n');
        end
        
        function print_dark_update(Run_Status, state)
            % Dark theme update line
            elapsed = seconds(datetime('now') - state.start_time);
            
            fprintf('\r%s[Step %d]%s  t=%.4f  dt=%.2e  %sCFL=%.3f%s  %s|ω|ₘₐₓ=%.2e%s  %sElapsed: %.1fs%s', ...
                MonitorInterface.COLOR_GREEN, Run_Status.step, MonitorInterface.COLOR_RESET, ...
                Run_Status.time, Run_Status.dt, ...
                MonitorInterface.COLOR_YELLOW, Run_Status.CFL, MonitorInterface.COLOR_RESET, ...
                MonitorInterface.COLOR_CYAN, Run_Status.max_omega, MonitorInterface.COLOR_RESET, ...
                MonitorInterface.COLOR_GRAY, elapsed, MonitorInterface.COLOR_RESET);
        end
        
        function print_light_update(Run_Status, state)
            % Light theme update line
            elapsed = seconds(datetime('now') - state.start_time);
            
            fprintf('\r[Step %d]  t=%.4f  dt=%.2e  CFL=%.3f  |ω|ₘₐₓ=%.2e  Elapsed: %.1fs', ...
                Run_Status.step, Run_Status.time, Run_Status.dt, ...
                Run_Status.CFL, Run_Status.max_omega, elapsed);
        end
        
        function print_dark_footer(Run_Summary, state)
            % Dark theme footer
            fprintf('\n%s─────────────────────────────────────────────────────────%s\n', ...
                MonitorInterface.COLOR_GRAY, MonitorInterface.COLOR_RESET);
            fprintf('%s✓ Simulation completed%s  |  Total time: %.2fs\n', ...
                MonitorInterface.COLOR_GREEN, MonitorInterface.COLOR_RESET, Run_Summary.total_time);
            fprintf('\n');
        end
        
        function print_light_footer(Run_Summary, state)
            % Light theme footer
            fprintf('\n───────────────────────────────────────────────────────\n');
            fprintf('✓ Simulation completed  |  Total time: %.2fs\n', Run_Summary.total_time);
            fprintf('\n');
        end
    end
end
