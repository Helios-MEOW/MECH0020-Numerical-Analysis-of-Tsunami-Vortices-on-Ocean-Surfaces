%% LIVE MONITOR UPDATE - REAL-TIME DATA REFRESH
% Updates the live monitoring dashboard with iteration metrics and performance data

function update_live_monitor(iteration, total, phase, metrics)
    % Updates the live monitoring dashboard (uifigure)

    monitor_start = tic;
    global script_start_time monitor_figure monitor_data; %#ok<GVMIS>

    if isempty(monitor_figure) || ~isvalid(monitor_figure)
        return;
    end
    if ~isfield(monitor_data, 'ui') || isempty(monitor_data.ui)
        return;
    end

    ui = monitor_data.ui;
    colors = ui.colors;

    % Update monitor data
    monitor_data.iterations_completed = iteration;
    monitor_data.total_iterations = total;
    monitor_data.current_phase = phase;
    if isempty(script_start_time) || ~(isa(script_start_time, 'uint64') || isnumeric(script_start_time))
        script_start_time = tic;
    end
    try
        elapsed_time = toc(script_start_time);
    catch
        script_start_time = tic;
        elapsed_time = toc(script_start_time);
    end

    % Calculate performance metrics
    if iteration > 0
        avg_time_per_iter = elapsed_time / iteration;
        remaining_iters = total - iteration;
        est_remaining = avg_time_per_iter * remaining_iters;

        if length(monitor_data.performance.iteration_times) < iteration
            monitor_data.performance.iteration_times(end+1) = elapsed_time;
        end

        mem_info = memory;
        mem_used_mb = mem_info.MemUsedMATLAB / 1024^2;
        monitor_data.performance.memory_usage(end+1) = mem_used_mb;
    else
        avg_time_per_iter = 0;
        est_remaining = 0;
        mem_used_mb = 0;
    end

    % Progress bar
    progress_pct = iteration / max(total, 1) * 100;
    set(ui.progress_bar, 'XData', [0 progress_pct/100 progress_pct/100 0]);
    ui.progress_text.String = sprintf('%.1f%% Complete | %d / %d', progress_pct, iteration, total);
    ui.progress_text.Color = colors.text_main;

    % Performance metrics
    ui.avg_time.Text = sprintf('Avg Time/Iter: %.3f s', avg_time_per_iter);
    ui.est_remaining.Text = sprintf('Est. Remaining: %.1f s (%.1f min)', est_remaining, est_remaining/60);
    ui.memory.Text = sprintf('Memory Usage: %.1f MB', mem_used_mb);

    % Computational load
    if isfield(metrics, 'grid_size')
        ui.grid_size.Text = sprintf('Grid Size: %d x %d', metrics.grid_size(1), metrics.grid_size(2));
        total_ops = metrics.grid_size(1) * metrics.grid_size(2) * iteration;
        ui.total_ops.Text = sprintf('Total Operations: %.2e', total_ops);
    end
    if isfield(metrics, 'time_steps')
        ui.time_steps.Text = sprintf('Time Steps: %d', metrics.time_steps);
    end
    ui.phase.Text = sprintf('Current Phase: %s', phase);

    % Time plot
    n_points = numel(monitor_data.performance.iteration_times);
    if n_points > 0
        ui.time_line.XData = 1:n_points;
        ui.time_line.YData = monitor_data.performance.iteration_times;
    end

    % Speed plot
    if n_points > 0
        speeds = 1 ./ diff([0; monitor_data.performance.iteration_times(:)]);
        ui.speed_line.XData = 1:numel(speeds);
        ui.speed_line.YData = speeds;
    end

    % Key metrics
    if isfield(metrics, 'max_vorticity')
        ui.max_vort.Text = sprintf('Max Vorticity: %.4f', metrics.max_vorticity);
    end
    if isfield(metrics, 'total_energy')
        ui.total_energy.Text = sprintf('Total Energy: %.4e', metrics.total_energy);
    end
    if isfield(metrics, 'convergence_metric')
        ui.convergence.Text = sprintf('Convergence: %.2e', metrics.convergence_metric);
    end

    % Convergence status vs tolerance (if provided)
    if isfield(metrics, 'convergence_metric') && isfield(metrics, 'tolerance')
        if isfinite(metrics.convergence_metric) && isfinite(metrics.tolerance)
            if metrics.convergence_metric <= metrics.tolerance
                ui.conv_status.Text = sprintf('Convergence Status: MET (tol=%.1e)', metrics.tolerance);
                ui.conv_status.FontColor = [0.2 1.0 0.6];
            else
                ui.conv_status.Text = sprintf('Convergence Status: NOT MET (tol=%.1e)', metrics.tolerance);
                ui.conv_status.FontColor = [1.0 0.7 0.3];
            end
        else
            ui.conv_status.Text = 'Convergence Status: N/A';
            ui.conv_status.FontColor = colors.text_dim;
        end
    else
        ui.conv_status.Text = 'Convergence Status: N/A';
        ui.conv_status.FontColor = colors.text_dim;
    end

    % Status
    if progress_pct >= 100
        status_str = 'COMPLETE';
        status_color = [0.2 1.0 0.6];
    elseif progress_pct >= 75
        status_str = 'NEARLY DONE';
        status_color = [0.2 0.8 1.0];
    elseif progress_pct >= 50
        status_str = 'RUNNING';
        status_color = [0.4 0.6 1.0];
    elseif progress_pct >= 25
        status_str = 'IN PROGRESS';
        status_color = [1.0 0.7 0.3];
    else
        status_str = 'STARTING';
        status_color = [0.7 0.7 0.7];
    end
    ui.status.Text = sprintf('Status: %s', status_str);
    ui.status.FontColor = status_color;

    % Monitor overhead
    monitor_time = toc(monitor_start);
    monitor_data.performance.monitor_overhead = monitor_data.performance.monitor_overhead + monitor_time;
    overhead_pct = (monitor_data.performance.monitor_overhead / max(elapsed_time, 0.001)) * 100;
    ui.overhead.Text = sprintf('Monitor Overhead: %.2f%% (%.3f s)', overhead_pct, monitor_data.performance.monitor_overhead);

    drawnow limitrate;
end
