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
    
    % No ANSI constants needed - ColorPrintf handles all coloring
    
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
            % Dark theme header - uses ColorPrintf for colored output
            ColorPrintf.monitor_header(Run_Config.method, Run_Config.mode, Run_Config.ic_type);
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
        
        function print_dark_update(Run_Status, ~)
            % Dark theme update line - uses ColorPrintf
            ColorPrintf.monitor_update(Run_Status.step, Run_Status.time, ...
                Run_Status.dt, Run_Status.CFL, Run_Status.max_omega, 0);
        end
        
        function print_light_update(Run_Status, ~)
            % Light theme update line
            fprintf('[Step %d]  t=%.4f  dt=%.2e  CFL=%.3f  |w|max=%.2e\n', ...
                Run_Status.step, Run_Status.time, Run_Status.dt, ...
                Run_Status.CFL, Run_Status.max_omega);
        end
        
        function print_dark_footer(Run_Summary, ~)
            % Dark theme footer - uses ColorPrintf
            ColorPrintf.monitor_footer(Run_Summary.total_time);
        end
        
        function print_light_footer(Run_Summary, ~)
            % Light theme footer
            fprintf('\n---------------------------------------------------\n');
            fprintf('Simulation completed  |  Total time: %.2fs\n\n', Run_Summary.total_time);
        end
    end
end
