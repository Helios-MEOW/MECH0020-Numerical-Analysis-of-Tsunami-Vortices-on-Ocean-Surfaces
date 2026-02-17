# Real-time simulation and UI integration in MATLAB  

**Continuous monitoring:** Run the solver on MATLAB’s background thread or parallel pool and use a timer or DataQueue to push metrics to the UI. For example, start the main simulation in a `parfeval` or separate `parpool` job and use `parallel.pool.DataQueue` to send performance data (CPU, time, etc.) back to the UI. In the UI app, set up a `timer` object that polls this queue at very short intervals to update displays. This decouples the solver from the UI so the simulation speed is not blocked by graphics updates. Ensure graphics updates are throttled (e.g. only every N steps) so they do not slow the computation.  

**UI figure integration:** Use MATLAB’s `uifigure` and `uiaxes` instead of manual axes. Create a dropdown or tab container for figures within the app. When your code produces a new figure, plot directly into a `uiaxes` handle in the UI. For example:  
```matlab
figTab = uitab(tabGroup, 'Title', 'Figure1');
ax = uiaxes(figTab);
plot(ax, x,y); % draws in the UI figure  
```  
This way, figures appear in the app window. To store them in a menu, you can dynamically add `uitab` or dropdown entries each time a plot is created.  

**Remove terminal outputs:** Scan the repo for any `disp`, `fprintf`, `clc` or `pause` commands and replace them with UI status updates (e.g. a `uilabel` or `statusBar.Text`). Any `input()` or `menu()` calls in the code should be removed. Ensure the main loop does not rely on console input. Instead, provide controls (buttons, checkboxes) in the UI for any runtime options.  

**Parallel pool usage:** A `parpool(…)` call spawns workers, but by default MATLAB’s UI is blocked until those workers finish. To show progress, either use `parallel.pool.DataQueue` or `parfor` with `drawnow`. If the pool is not needed, remove it and rely on vectorized code. If you keep it, call `parpool('IdleTimeout', Inf)` at startup so it stays open but don’t repeatedly create it. In the app, indicate worker count but do not rely on it; just ensure the code runs on the workers without requiring UI approval.  

**Summary of changes:**  
- Use `parfeval` or background job for the solver, and a DataQueue/timer for live metrics.  
- Use App Designer components (`uifigure`, `uiaxes`, `tabs`) to display plots and stats.  
- Remove all `fprintf`/`disp` and console interactions; update UI elements instead.  
- If a parallel pool is used, start it once and then run computations asynchronously; otherwise simplify to single-threaded vector code.  
- Verify that turning off the UI (or switching tabs) does not pause the simulation loop.  

These steps ensure the solver runs at full speed with continuous UI updates, and that all visuals go into the MATLAB app rather than the terminal or separate figure windows.  

