# Live Execution Monitoring System

## Overview

A comprehensive real-time monitoring dashboard has been implemented for the tsunami vortex analysis code. This system provides live visibility into long-running simulations while tracking its own performance overhead.

## Features

### 1. **Six-Panel Dashboard**

The monitoring dashboard displays real-time information across six panels:

#### Panel 1: Computation Progress
- Visual progress bar
- Current iteration count / Total iterations
- Percentage complete

#### Panel 2: Elapsed Time Plot
- Line plot showing elapsed time vs iteration number
- Helps identify performance trends during execution

#### Panel 3: Performance Metrics
- **Average Time/Iteration**: Mean computational time per step
- **Estimated Time Remaining**: Predicted completion time
- **Memory Usage**: Current MATLAB memory consumption (MB)
- **Monitor Overhead**: Percentage of runtime spent on monitoring itself

#### Panel 4: Computational Load
- **Total Operations**: Total iteration count
- **Grid Size**: Current spatial resolution (Nx × Ny)
- **Time Steps**: Number of temporal steps
- **Current Phase**: Active execution stage (e.g., "Time Integration", "Convergence: Bracketing")

#### Panel 5: Iteration Speed Plot
- Real-time plot of iterations/second vs iteration number
- Shows computational performance over time

#### Panel 6: Key Physics Metrics
- **Max Vorticity**: Peak absolute vorticity value
- **Total Energy**: Enstrophy (energy proxy)
- **Convergence**: Grid convergence metric (when applicable)
- **Status**: Color-coded progress indicator
  - Gray: Starting (0-25%)
  - Yellow: Early progress (25-50%)
  - Blue: Mid-progress (50-75%)
  - Green: Late progress (75-99%)
  - Dark Green: Complete (100%)

### 2. **Self-Monitoring Overhead Tracking**

The system measures its own performance impact by:
- Timing each dashboard update call
- Calculating cumulative monitoring time
- Reporting overhead as a percentage of total runtime
- Target: <5% overhead

### 3. **Automatic Integration**

The monitoring system automatically activates when:
- The global `monitor_figure` variable exists and is valid
- Updates occur approximately 100 times during time-stepping loops
- Updates are strategic to minimize performance impact

## Implementation Details

### Modified Files

#### 1. **Analysis.m**
- Added global variables: `script_start_time`, `monitor_figure`, `monitor_data`
- Initialization section (lines ~68-85):
  ```matlab
  monitor_data = struct();
  monitor_data.start_time = datetime('now');
  monitor_data.iterations_completed = 0;
  monitor_data.total_iterations = 0;
  monitor_data.current_phase = 'Initializing';
  monitor_data.performance.monitor_overhead = 0;
  
  monitor_figure = create_live_monitor_dashboard();
  ```

- Dashboard creation function: `create_live_monitor_dashboard()` (lines ~2755-2820)
  - Creates 1200×700 pixel figure with 2×3 subplot grid
  - Initializes all text objects with unique tags for efficient updates

- Dashboard update function: `update_live_monitor(iteration, total, phase, metrics)` (lines ~2821-2974)
  - Updates all six panels with current metrics
  - Calculates performance statistics
  - Tracks memory usage
  - Measures and reports its own overhead

#### 2. **Finite_Difference_Analysis.m**
- Added monitoring calls in main time-stepping loop (lines ~120-165)
- Monitors every Nth iteration where N = max(1, round(Nt/100))
- Passes real-time physics metrics:
  ```matlab
  metrics.grid_size = [Nx, Ny];
  metrics.time_steps = Nt;
  metrics.max_vorticity = max(abs(omega(:)));
  metrics.total_energy = sum(omega(:).^2) * dx * dy;
  ```

## Usage

### Running with Monitoring

Simply run your Analysis.m script as usual:

```matlab
Analysis
```

The monitoring dashboard will automatically appear and update throughout execution.

### Testing the System

For a quick test with minimal computational cost:

1. Open `Analysis.m`
2. Set these parameters:
   ```matlab
   Parameters.Nx = 64;
   Parameters.Ny = 64;
   Parameters.Tfinal = 1.0;  % 1 second simulation
   Parameters.dt = 0.01;
   run_mode = "evolution";
   ```
3. Run the script
4. Watch the dashboard update in real-time

### Disabling Monitoring

To run without the monitoring dashboard:

1. Comment out the dashboard creation:
   ```matlab
   % monitor_figure = create_live_monitor_dashboard();
   monitor_figure = [];  % Disable monitoring
   ```

OR

2. Close the monitoring figure manually - updates will stop automatically

## Performance Impact

### Overhead Measurement
- Monitoring overhead is calculated as: `(monitor_time / total_time) × 100%`
- Displayed in Panel 3: "Performance Metrics"
- Typically <1% for large simulations (Nx, Ny > 128, Nt > 1000)
- May reach 2-5% for very small/fast simulations

### Optimization Strategies
- Updates occur every ~1% of total iterations (max 100 updates)
- Uses `findobj` with tags for efficient graphics updates
- Uses `drawnow limitrate` to prevent excessive redraws
- Checks figure validity before each update to avoid errors

## Dashboard Layout

```
╔═══════════════════════════════════════════════════════════╗
║  [1] Progress Bar    │  [2] Elapsed Time   │  [3] Perf.  ║
║  ══════════ 45%      │       /\            │  Avg: 0.02s ║
║  450/1000 iter       │      /  \           │  Rem: 11s   ║
║                      │     /    \          │  Mem: 2.3GB ║
║                      │    /      \         │  OH: 0.8%   ║
╠══════════════════════╪═════════════════════╪══════════════╣
║  [4] Comp. Load      │  [5] Iter Speed     │  [6] Physics║
║  Ops: 1000           │       /\            │  ω: 1.2e-2  ║
║  Grid: 128×128       │      /  \           │  E: 3.4e-5  ║
║  Steps: 1000         │     /    \          │  Conv: N/A  ║
║  Phase: Time Int.    │    /      \         │  Status: ●  ║
╚═══════════════════════════════════════════════════════════╝
```

## Function Reference

### `create_live_monitor_dashboard()`
**Purpose**: Creates the monitoring figure with 6 subplots

**Returns**: Figure handle (stored in `monitor_figure`)

**Key Features**:
- 1200×700 pixel window
- Light gray background (#F2F2F2)
- No menubar/toolbar for cleaner interface
- All text objects tagged for efficient updates

### `update_live_monitor(iteration, total, phase, metrics)`
**Purpose**: Updates all dashboard panels with current simulation state

**Parameters**:
- `iteration` (int): Current iteration number
- `total` (int): Total iterations to complete
- `phase` (string): Current execution phase description
- `metrics` (struct): Physics metrics structure with fields:
  - `grid_size` ([Nx, Ny]): Spatial grid dimensions
  - `time_steps` (int): Number of temporal steps
  - `max_vorticity` (double): Peak absolute vorticity
  - `total_energy` (double): Total enstrophy
  - `convergence_metric` (double): Grid convergence error (NaN if N/A)

**Returns**: None (updates global `monitor_data` structure)

**Performance**: Typically 1-10ms per call depending on system

## Troubleshooting

### Dashboard Not Appearing
**Issue**: Script runs but no monitoring window appears
**Solution**: 
- Check that `monitor_figure = create_live_monitor_dashboard();` is not commented out
- Ensure MATLAB has graphics capabilities (not running in -nodisplay mode)

### Errors About Missing Variables
**Issue**: "Undefined variable 'monitor_figure'"
**Solution**: 
- Run Analysis.m from the beginning (don't run cells individually)
- Ensure global declarations are at the top of the file

### Dashboard Freezes/Doesn't Update
**Issue**: Figure appears but doesn't update during simulation
**Solution**:
- Check that `use_live_monitor` variable is true
- Ensure `monitor_update_stride` is not set too high
- Verify `drawnow limitrate` is not being blocked by other graphics

### High Overhead Percentage
**Issue**: Monitor overhead >5%
**Solution**:
- Increase `monitor_update_stride` in Finite_Difference_Analysis.m
- Reduce update frequency (e.g., Nt/50 instead of Nt/100)
- Check if other graphics (live preview) are also enabled

## Future Enhancements

Potential improvements for future versions:

1. **Adaptive Update Frequency**: Automatically adjust update rate based on measured overhead
2. **Animation Preview**: Show live vorticity contour in dashboard
3. **Multi-Mode Tracking**: Better integration with convergence/sweep modes
4. **Log Export**: Save monitoring data to file for post-analysis
5. **Email Notifications**: Send alerts when simulations complete or encounter errors
6. **GPU Monitoring**: Track GPU utilization if GPU computing is enabled

## Technical Notes

### Global Variable Usage
The system uses three global variables:
- `script_start_time`: tic() timer for total elapsed time
- `monitor_figure`: Figure handle for dashboard
- `monitor_data`: Struct containing all monitoring state

This approach allows nested functions (like Finite_Difference_Analysis) to access monitoring infrastructure without parameter passing.

### Graphics Tag System
Each text/plot object in the dashboard has a unique tag:
- `'progress_text'`: Progress bar text display
- `'elapsed_plot'`: Time vs iteration line
- `'avg_time'`, `'est_remaining'`, `'memory'`, `'overhead'`: Performance metrics
- `'grid_size'`, `'time_steps'`, `'ops'`, `'phase'`: Computational load
- `'speed_plot'`: Iterations/second line
- `'max_vort'`, `'energy'`, `'convergence'`, `'status'`: Physics metrics

This allows `findobj(fig, 'Tag', 'progress_text')` for efficient lookups without storing handles.

### Color Coding Scheme
Status indicator colors by progress:
- 0-25%: `[0.5 0.5 0.5]` - Gray (Starting)
- 25-50%: `[1.0 0.9 0.0]` - Yellow (Early)
- 50-75%: `[0.0 0.5 1.0]` - Blue (Mid)
- 75-99%: `[0.0 0.8 0.0]` - Green (Late)
- 100%: `[0.0 0.5 0.0]` - Dark Green (Complete)

## Contact & Support

For issues, improvements, or questions about the monitoring system:
- Check function documentation in Analysis.m (lines 2755-2974)
- Review implementation in Finite_Difference_Analysis.m (lines 120-165)
- Consult this guide for troubleshooting steps

---

**Version**: 1.0  
**Last Updated**: January 2026  
**Compatibility**: MATLAB R2020a or later  
**Dependencies**: None (uses built-in MATLAB graphics)
