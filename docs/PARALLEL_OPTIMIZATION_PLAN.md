# UI Parallelization and Optimization Plan

## Problem Statement

Current issues with the UI:
1. **Simulation blocks UI thread** - UI freezes during simulation
2. **Live monitor shows nothing** - No real-time updates during run
3. **No terminal progress bar** - Can't see progress in terminal
4. **No independent metrics collection** - CPU/memory monitoring tied to simulation

## Solution: Parallel Computing Architecture

### Components Created

#### 1. ParallelSimulationExecutor.m
**Location:** `Scripts/Infrastructure/Utilities/ParallelSimulationExecutor.m`

**Features:**
- Runs simulation in background worker using `parfeval`
- Independent monitoring timer (10 Hz update rate)
- Real-time CPU and memory usage collection
- Non-blocking UI updates
- Graceful fallback to synchronous execution

**Usage:**
```matlab
executor = ParallelSimulationExecutor(@(payload) app.handle_live_monitor_progress(payload, cfg));
executor.start(run_config, parameters, settings);
% UI remains responsive
[results, paths] = executor.wait_for_completion();
```

#### 2. ProgressBar.m
**Location:** `Scripts/Infrastructure/Utilities/ProgressBar.m`

**Features:**
- Visual progress bar in terminal
- ETA and iteration rate display
- In-place updates (no terminal spam)
- Customizable appearance

**Usage:**
```matlab
pb = ProgressBar(total_iterations, 'Prefix', 'Evolution');
for i = 1:total_iterations
    pb.update(i, 'Message', sprintf('t=%.3f', t));
end
pb.finish();
```

### Required Changes

#### 1. Update UIController.m

**In `execute_single_run` method (line ~1596):**

Replace:
```matlab
[results, paths] = ModeDispatcher(run_config, parameters, settings);
```

With:
```matlab
% Create parallel executor
executor = ParallelSimulationExecutor(...
    @(payload) app.handle_live_monitor_progress(payload, cfg_override));

% Start simulation in background
executor.start(run_config, parameters, settings);

% UI remains responsive - timer handles updates
app.current_executor = executor;  % Store for cancellation

% Wait for completion
[results, paths] = executor.wait_for_completion();
```

**Add to UIController properties:**
```matlab
properties
    current_executor  % ParallelSimulationExecutor instance
end
```

**Add cancellation method:**
```matlab
function cancel_simulation(app)
    if ~isempty(app.current_executor) && app.current_executor.is_running
        app.current_executor.cancel();
        app.append_to_terminal('Simulation cancelled by user', 'warning');
        app.set_run_state('idle', 'Cancelled');
    end
end
```

#### 2. Update mode_evolution.m

**Add progress bar support (line ~90):**

```matlab
% Create progress bar if not in UI mode
use_progress_bar = ~isfield(Settings, 'ui_progress_callback');
if use_progress_bar
    pb = ProgressBar(Nt, 'Prefix', sprintf('[%s Evolution]', Run_Config.method));
end

% In progress reporting section (line ~135):
if mod(n, progress_stride) == 0 || n == Nt
    if use_progress_bar
        pb.update(n, 'Message', sprintf('t=%.3f, |ω|=%.3e', State.t, Metrics.max_vorticity));
    else
        fprintf('[Evolution] %6.2f%% | t = %.3f / %.3f | Method = %s | max|ω| = %.3e\n', ...
            100 * n / Nt, State.t, Tfinal, Run_Config.method, Metrics.max_vorticity);
    end

    progress_callback = emit_progress_payload(progress_callback, Run_Config, ...
        n, Nt, State.t, Metrics, toc(run_timer), NaN);
end

% At end of simulation:
if use_progress_bar
    pb.finish('Message', 'Evolution complete');
end
```

#### 3. Update handle_live_monitor_progress in UIController

**Add support for background updates (line ~2068):**

```matlab
function handle_live_monitor_progress(app, payload, cfg)
    % ... existing code ...

    % Check if this is a background timer update
    is_background = isfield(payload, 'is_background_update') && payload.is_background_update;

    if is_background
        % Update system metrics only
        app.update_system_metrics_display(payload);
        return;
    end

    % Normal progress update from simulation
    % ... rest of existing code ...
end
```

**Add new method:**
```matlab
function update_system_metrics_display(app, payload)
    % Update CPU and memory displays from timer

    if ~isfield(app.handles, 'monitor_cpu_label')
        return;
    end

    if isfield(payload, 'cpu_usage') && isfinite(payload.cpu_usage)
        app.handles.monitor_cpu_label.Text = sprintf('CPU: %.1f%%', payload.cpu_usage);
    end

    if isfield(payload, 'memory_usage') && isfinite(payload.memory_usage)
        app.handles.monitor_memory_label.Text = sprintf('Memory: %.1f MB', payload.memory_usage);
    end

    if isfield(payload, 'elapsed_time')
        app.handles.monitor_elapsed_label.Text = sprintf('Elapsed: %.1f s', payload.elapsed_time);
    end

    drawnow limitrate;
end
```

#### 4. Fix Live Monitor Display

**In `refresh_monitor_dashboard` (find this method):**

Ensure plots are being updated with data:
```matlab
function refresh_monitor_dashboard(app, summary, cfg)
    if ~isfield(app.handles, 'monitor_live_state')
        return;
    end

    state = app.handles.monitor_live_state;

    % Update all plots with collected data
    if isfield(app.handles, 'monitor_plot_vorticity')
        ax = app.handles.monitor_plot_vorticity;
        if ~isempty(state.iters) && ~isempty(state.max_omega)
            plot(ax, state.iters, state.max_omega, 'LineWidth', 2);
            xlabel(ax, 'Iteration');
            ylabel(ax, 'Max Vorticity');
            grid(ax, 'on');
        end
    end

    % ... update other plots similarly ...

    drawnow limitrate;
end
```

### Benefits

1. **Non-blocking UI** - User can interact with UI during simulation
2. **Independent monitoring** - System metrics collected at 10 Hz regardless of simulation speed
3. **Progress visualization** - Terminal progress bar and live monitor both working
4. **Cancellable simulations** - User can stop long-running simulations
5. **Better performance** - Simulation runs at full speed, monitoring is separate

### Testing Checklist

- [ ] Simulation runs in background without blocking UI
- [ ] Live monitor shows real-time updates during simulation
- [ ] Terminal progress bar displays correctly
- [ ] CPU and memory metrics update independently
- [ ] Can cancel running simulation
- [ ] Results tab updates correctly after completion
- [ ] Figures appear in Results tab
- [ ] No Config.mat warnings
- [ ] Parallel pool creates successfully
- [ ] Graceful fallback to synchronous mode if parallel fails

### Performance Notes

**Parallel Overhead:**
- Starting parallel pool: ~5-10 seconds (one-time cost)
- parfeval overhead: <0.1 seconds per simulation
- Monitoring timer: ~1-2% CPU overhead

**Recommended Settings:**
- Monitor update rate: 10 Hz (0.1 second interval)
- Progress bar update: every 0.1 seconds
- Simulation progress callback: every 50th iteration (already optimized)

### Dependencies

**Required Toolboxes:**
- Parallel Computing Toolbox (for `parfeval`, `parpool`)
- MATLAB R2020a or later (for improved parallel features)

**Fallback Behavior:**
- If Parallel Computing Toolbox not available: runs synchronously
- If parallel pool creation fails: runs synchronously with warning
- Monitor timer still works in synchronous mode

### Future Enhancements

1. **Distributed Computing** - Run on cluster for large simulations
2. **GPU Acceleration** - Offload computation to GPU
3. **Batch Processing** - Queue multiple simulations
4. **Live Visualization** - Show vorticity field animation during run
5. **Checkpointing** - Save/restore simulation state

## Implementation Status

✅ ParallelSimulationExecutor created
✅ ProgressBar utility created
✅ filter_graphics_objects fixed
⏳ UIController integration pending
⏳ mode_evolution progress bar integration pending
⏳ Live monitor display fix pending
⏳ Testing pending

