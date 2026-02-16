# Weeks 1-3 Implementation Fixes

**Date:** 2026-02-15
**Status:** Ready for Implementation
**Focus:** Finite Difference and Spectral Methods Only

---

## Summary of Changes

### ✅ WEEK 1 - Critical Fixes (COMPLETED/IN PROGRESS)

1. **✅ Terminal Color Coding** - ALREADY IMPLEMENTED
   - System uses `uihtml` with HTML color formatting
   - Colors working: Success (green), Error (red), Warning (yellow), Info (cyan)
   - Location: `UIController.m` lines 5766-5814

2. **🔧 Remove Stray Figures** - IN PROGRESS
   - Figure suppression already implemented in `launch_simulation()`
   - Need to verify no figures launch during UI initialization
   - Add safeguards for IC preview

3. **📹 Video Playback Controls** - TO IMPLEMENT
   - Add play/pause/stop/speed/loop/scrubber controls
   - Integrate with existing animation preview system

### 📋 WEEK 2 - UI Enhancements

4. **Magnified Stencil View (FD only)**
5. **Standardize LaTeX Variable Names**
6. **Add Tooltips to Complex Parameters**

### 📊 WEEK 3 - Report System Overhaul

7. **Enhanced HTML Reports (Plotly.js)**
8. **PDF Export Capability**
9. **Interactive Plots and Animations**

---

## WEEK 1 IMPLEMENTATION

### Fix 1: Terminal Color Coding ✅

**STATUS: ALREADY WORKING**

The terminal color system is fully functional:
- `render_terminal_html()` generates colored HTML
- `terminal_type_color()` maps types to hex colors
- `uihtml` component displays the colored terminal

**Verification Test:**
```matlab
app = UIController();
app.append_to_terminal('This is a success message', 'success');  % Green
app.append_to_terminal('This is an error message', 'error');      % Red
app.append_to_terminal('This is a warning message', 'warning');   % Yellow
app.append_to_terminal('This is an info message', 'info');        % Cyan
```

---

### Fix 2: Remove Stray Figures 🔧

**ISSUE:** Figures may appear during:
1. UI initialization
2. IC preview generation
3. Grid/Domain visualization updates

**SOLUTION:** Add figure suppression guards

#### Modification 1: `UIController.m` Constructor

**Add after line 100:**
```matlab
% Suppress figure windows during UI construction
set(0, 'DefaultFigureVisible', 'off');
```

**Add before line 191 (just before `app.fig.Visible = 'on';`):**
```matlab
% Re-enable figure visibility for captures (UI will manage)
% Figures created by simulations are still suppressed via launch_simulation()
```

#### Modification 2: IC Preview - Prevent External Figures

**Find `update_ic_preview()` method and ensure it uses only uiaxes:**

Replace any `figure()` calls with direct `uiaxes` plotting.

**Search pattern:**
```matlab
Grep for: "figure\(" in UIController.m
```

Replace with:
```matlab
% Use app.handles.ic_preview_axes directly, no external figures
```

#### Modification 3: Grid/Domain Plots - Verify uiaxes Usage

**Find `update_grid_domain_plots()` and ensure all plots target uiaxes.**

**Code Review Checklist:**
- [ ] No `figure()` calls in `update_ic_preview()`
- [ ] No `figure()` calls in `update_grid_domain_plots()`
- [ ] No `figure()` calls in any UI callback
- [ ] All plots use `app.handles.*_axes` as parent

---

### Fix 3: Video Playback Controls 📹

**CURRENT STATE:**
- Animation preview exists with MP4/AVI/GIF triplet display
- NO playback controls (play/pause/stop/speed/loop)
- Timer system partially implemented (`time_video_timer`, `time_video_state`)

**IMPLEMENTATION:**

#### Step 1: Add Playback Control UI Components

**Location:** `create_config_tab()` - Time/Simulation Settings section
**Insert after animation preview creation (around line 800-900):**

```matlab
% ===== VIDEO PLAYBACK CONTROLS =====
% Add controls below each format preview
controls_grid = uigridlayout(preview_panel, [1, 6]);
controls_grid.ColumnWidth = {'fit', 'fit', 'fit', '1x', 80, 'fit'};
controls_grid.Padding = [2 2 2 2];
controls_grid.ColumnSpacing = 4;

% Play/Pause button
app.handles.video_play_btn = uibutton(controls_grid, 'push', ...
    'Text', '▶ Play', ...
    'ButtonPushedFcn', @(~,~) app.toggle_video_playback());
app.handles.video_play_btn.Layout.Column = 1;

% Stop button
app.handles.video_stop_btn = uibutton(controls_grid, 'push', ...
    'Text', '⬛ Stop', ...
    'ButtonPushedFcn', @(~,~) app.stop_video());
app.handles.video_stop_btn.Layout.Column = 2;

% Speed dropdown
app.handles.video_speed = uidropdown(controls_grid, ...
    'Items', {'0.25x', '0.5x', '1x', '2x', '5x'}, ...
    'Value', '1x', ...
    'ValueChangedFcn', @(~,~) app.set_video_speed());
app.handles.video_speed.Layout.Column = 3;

% Frame slider
app.handles.video_slider = uislider(controls_grid, ...
    'Limits', [1, 100], ...
    'Value', 1, ...
    'ValueChangedFcn', @(~,~) app.seek_video_frame());
app.handles.video_slider.Layout.Column = 4;

% Loop checkbox
app.handles.video_loop = uicheckbox(controls_grid, ...
    'Text', '🔄 Loop', ...
    'Value', true);
app.handles.video_loop.Layout.Column = 5;

% Frame counter label
app.handles.video_frame_label = uilabel(controls_grid, ...
    'Text', 'Frame 0/0', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 10);
app.handles.video_frame_label.Layout.Column = 6;
```

#### Step 2: Add Playback Control Methods

**Location:** After `create_report_tab()` method, add new methods:

```matlab
function toggle_video_playback(app)
    % Toggle play/pause for animation preview
    if ~app.has_valid_handle('video_play_btn')
        return;
    end

    if ~app.is_video_loaded()
        app.show_alert_latex('No video loaded. Run a simulation with animations enabled.', ...
            'Video Not Loaded', 'Icon', 'warning');
        return;
    end

    % Check if playing
    if app.is_video_playing()
        % Pause
        app.pause_video();
        app.handles.video_play_btn.Text = '▶ Play';
    else
        % Play
        app.play_video();
        app.handles.video_play_btn.Text = '⏸ Pause';
    end
end

function play_video(app)
    % Start video playback timer
    if isempty(app.time_video_timer) || ~isvalid(app.time_video_timer)
        % Create timer
        speed_multiplier = app.parse_speed_multiplier();
        base_fps = app.get_video_fps();
        period = 1 / (base_fps * speed_multiplier);

        app.time_video_timer = timer(...
            'Period', max(0.01, period), ...
            'ExecutionMode', 'fixedRate', ...
            'TimerFcn', @(~,~) app.advance_video_frame());
    end

    if strcmp(app.time_video_timer.Running, 'off')
        start(app.time_video_timer);
    end
end

function pause_video(app)
    % Pause video playback
    if ~isempty(app.time_video_timer) && isvalid(app.time_video_timer)
        if strcmp(app.time_video_timer.Running, 'on')
            stop(app.time_video_timer);
        end
    end
end

function stop_video(app)
    % Stop and reset to frame 1
    app.pause_video();
    app.time_video_state.current_frame = 1;
    app.update_video_display();
    app.handles.video_slider.Value = 1;
    app.handles.video_frame_label.Text = sprintf('Frame 1/%d', app.time_video_state.total_frames);
    if app.has_valid_handle('video_play_btn')
        app.handles.video_play_btn.Text = '▶ Play';
    end
end

function set_video_speed(app)
    % Update playback speed
    if app.is_video_playing()
        app.pause_video();
        app.play_video();  % Restart with new speed
    end
end

function seek_video_frame(app)
    % Jump to specific frame via slider
    if ~app.is_video_loaded()
        return;
    end

    target_frame = round(app.handles.video_slider.Value);
    app.time_video_state.current_frame = target_frame;
    app.update_video_display();
    app.handles.video_frame_label.Text = sprintf('Frame %d/%d', ...
        target_frame, app.time_video_state.total_frames);
end

function advance_video_frame(app)
    % Timer callback - advance to next frame
    if ~app.is_video_loaded()
        app.pause_video();
        return;
    end

    app.time_video_state.current_frame = app.time_video_state.current_frame + 1;

    % Check if reached end
    if app.time_video_state.current_frame > app.time_video_state.total_frames
        if app.handles.video_loop.Value
            % Loop back to start
            app.time_video_state.current_frame = 1;
        else
            % Stop at end
            app.time_video_state.current_frame = app.time_video_state.total_frames;
            app.pause_video();
            app.handles.video_play_btn.Text = '▶ Play';
        end
    end

    % Update display
    app.update_video_display();
    app.handles.video_slider.Value = app.time_video_state.current_frame;
    app.handles.video_frame_label.Text = sprintf('Frame %d/%d', ...
        app.time_video_state.current_frame, app.time_video_state.total_frames);
end

function update_video_display(app)
    % Update video preview image with current frame
    if ~app.is_video_loaded()
        return;
    end

    frame_idx = app.time_video_state.current_frame;

    % Update each format preview (MP4, AVI, GIF)
    formats = {'mp4', 'avi', 'gif'};
    for fmt_idx = 1:numel(formats)
        fmt = formats{fmt_idx};
        ax_field = sprintf('video_%s_axes', fmt);

        if app.has_valid_handle(ax_field) && isfield(app.time_video_state, fmt)
            video_data = app.time_video_state.(fmt);
            if isfield(video_data, 'frames') && numel(video_data.frames) >= frame_idx
                cdata = video_data.frames{frame_idx};
                % Find image object in axes and update CData
                img_handles = findobj(app.handles.(ax_field), 'Type', 'image');
                if ~isempty(img_handles)
                    img_handles(1).CData = cdata;
                else
                    % Create image if doesn't exist
                    image(app.handles.(ax_field), cdata);
                    axis(app.handles.(ax_field), 'image');
                    axis(app.handles.(ax_field), 'off');
                end
            end
        end
    end
end

function fps = get_video_fps(app)
    % Get FPS from loaded video or default to 24
    fps = 24;  % Default
    if isfield(app.time_video_state, 'fps') && app.time_video_state.fps > 0
        fps = app.time_video_state.fps;
    elseif app.has_valid_handle('animation_fps')
        fps = app.handles.animation_fps.Value;
    end
end

function multiplier = parse_speed_multiplier(app)
    % Parse speed from dropdown ('0.5x' -> 0.5)
    if ~app.has_valid_handle('video_speed')
        multiplier = 1.0;
        return;
    end

    speed_str = app.handles.video_speed.Value;
    % Extract number from '0.5x' -> 0.5
    num_str = strrep(speed_str, 'x', '');
    multiplier = str2double(num_str);

    if ~isfinite(multiplier) || multiplier <= 0
        multiplier = 1.0;
    end
end

function loaded = is_video_loaded(app)
    % Check if video data is loaded
    loaded = ~isempty(app.time_video_state) && ...
        isstruct(app.time_video_state) && ...
        isfield(app.time_video_state, 'total_frames') && ...
        app.time_video_state.total_frames > 0;
end

function playing = is_video_playing(app)
    % Check if video is currently playing
    playing = ~isempty(app.time_video_timer) && ...
        isvalid(app.time_video_timer) && ...
        strcmp(app.time_video_timer.Running, 'on');
end
```

#### Step 3: Initialize Video State

**Location:** Constructor (`UIController`), add after line 109:

```matlab
% Initialize video playback state
app.time_video_state = struct(...
    'current_frame', 1, ...
    'total_frames', 0, ...
    'fps', 24, ...
    'mp4', struct('frames', {}), ...
    'avi', struct('frames', {}), ...
    'gif', struct('frames', {}));
```

#### Step 4: Load Video on Simulation Completion

**Location:** After simulation completes, load video frames

**Add method:**
```matlab
function load_video_for_preview(app, animation_path)
    % Load video file into frame cache for playback
    if ~exist(animation_path, 'file')
        return;
    end

    [~, ~, ext] = fileparts(animation_path);
    format = lower(strrep(ext, '.', ''));

    try
        if strcmp(format, 'gif')
            % Load GIF frames
            [frames_data, cmap] = imread(animation_path, 'Frames', 'all');
            num_frames = size(frames_data, 4);
            frame_cell = cell(1, num_frames);
            for i = 1:num_frames
                frame = frames_data(:,:,:,i);
                if ~isempty(cmap)
                    frame = ind2rgb(frame, cmap);
                end
                frame_cell{i} = frame;
            end
            app.time_video_state.(format).frames = frame_cell;
        else
            % Load MP4/AVI using VideoReader
            vid = VideoReader(animation_path);
            frame_cell = {};
            while hasFrame(vid)
                frame_cell{end+1} = readFrame(vid); %#ok<AGROW>
            end
            app.time_video_state.(format).frames = frame_cell;
            app.time_video_state.fps = vid.FrameRate;
        end

        app.time_video_state.total_frames = numel(frame_cell);
        app.time_video_state.current_frame = 1;

        % Update slider range
        if app.has_valid_handle('video_slider')
            app.handles.video_slider.Limits = [1, app.time_video_state.total_frames];
            app.handles.video_slider.Value = 1;
        end

        % Update display
        app.update_video_display();
        app.handles.video_frame_label.Text = sprintf('Frame 1/%d', app.time_video_state.total_frames);

        app.append_to_terminal(sprintf('Loaded %d frames for %s preview', ...
            app.time_video_state.total_frames, upper(format)), 'success');
    catch ME
        app.append_to_terminal(sprintf('Failed to load video: %s', ME.message), 'error');
    end
end
```

#### Step 5: Cleanup on Close

**Location:** `cleanup()` method, add timer cleanup:

```matlab
% Stop and delete video timer
if ~isempty(app.time_video_timer) && isvalid(app.time_video_timer)
    stop(app.time_video_timer);
    delete(app.time_video_timer);
end
```

---

## WEEK 2 IMPLEMENTATION

### Fix 4: Magnified Stencil View (FD Only) 🔬

**LOCATION:** Grid & Domain tab, bottom-right quadrant

**Current:** Resolution preview
**New:** Toggle between resolution preview and FD stencil

#### Implementation

**Add to `update_grid_domain_plots()` method:**

```matlab
% Bottom-right: Stencil/Resolution toggle
if strcmp(app.handles.method_dropdown.Value, 'Finite Difference')
    app.render_fd_stencil(app.handles.grid_stencil_axes);
else
    app.render_resolution_preview(app.handles.grid_resolution_axes);
end
```

**New method: `render_fd_stencil()`**

```matlab
function render_fd_stencil(app, ax)
    % Render 5-point FD computational stencil with LaTeX labels
    C = app.layout_cfg.colors;

    cla(ax);
    hold(ax, 'on');

    % Center point
    scatter(ax, 0, 0, 200, 'filled', 'MarkerFaceColor', C.accent_blue);

    % Neighboring points
    scatter(ax, [1, -1, 0, 0], [0, 0, 1, -1], 120, 'filled', ...
        'MarkerFaceColor', C.accent_cyan);

    % Draw arrows
    quiver(ax, 0, 0, 0.8, 0, 0, 'LineWidth', 2.5, 'Color', C.fg_text, ...
        'MaxHeadSize', 0.6, 'AutoScale', 'off');
    quiver(ax, 0, 0, -0.8, 0, 0, 'LineWidth', 2.5, 'Color', C.fg_text, ...
        'MaxHeadSize', 0.6, 'AutoScale', 'off');
    quiver(ax, 0, 0, 0, 0.8, 0, 'LineWidth', 2.5, 'Color', C.fg_text, ...
        'MaxHeadSize', 0.6, 'AutoScale', 'off');
    quiver(ax, 0, 0, 0, -0.8, 0, 'LineWidth', 2.5, 'Color', C.fg_text, ...
        'MaxHeadSize', 0.6, 'AutoScale', 'off');

    % Labels with LaTeX
    text(ax, 0, 0, '  $\omega_{i,j}$', 'Interpreter', 'latex', ...
        'FontSize', 14, 'Color', C.fg_text, 'HorizontalAlignment', 'left');
    text(ax, 1, 0, '  $\omega_{i+1,j}$', 'Interpreter', 'latex', ...
        'FontSize', 12, 'Color', C.fg_text);
    text(ax, -1, 0, '  $\omega_{i-1,j}$', 'Interpreter', 'latex', ...
        'FontSize', 12, 'Color', C.fg_text);
    text(ax, 0, 1, '  $\omega_{i,j+1}$', 'Interpreter', 'latex', ...
        'FontSize', 12, 'Color', C.fg_text);
    text(ax, 0, -1, '  $\omega_{i,j-1}$', 'Interpreter', 'latex', ...
        'FontSize', 12, 'Color', C.fg_text);

    % Direction labels
    text(ax, 1.3, 0, '$i \rightarrow$', 'Interpreter', 'latex', ...
        'FontSize', 11, 'Color', C.fg_muted);
    text(ax, 0, 1.3, '$j \uparrow$', 'Interpreter', 'latex', ...
        'FontSize', 11, 'Color', C.fg_muted);

    axis(ax, 'equal');
    xlim(ax, [-1.6, 1.6]);
    ylim(ax, [-1.6, 1.6]);
    ax.XColor = 'none';
    ax.YColor = 'none';
    ax.Color = C.bg_panel_alt;
    title(ax, 'FD Stencil (5-point)', 'Interpreter', 'latex', ...
        'Color', C.fg_text, 'FontSize', 12);

    % Add equation annotation
    annotation_text = {
        '$\nabla^2\omega \approx \frac{\omega_{i+1,j} - 2\omega_{i,j} + \omega_{i-1,j}}{\Delta x^2}$',
        '$ + \frac{\omega_{i,j+1} - 2\omega_{i,j} + \omega_{i,j-1}}{\Delta y^2}$'
    };
    text(ax, 0, -1.4, annotation_text, 'Interpreter', 'latex', ...
        'FontSize', 9, 'Color', C.fg_muted, 'HorizontalAlignment', 'center');

    hold(ax, 'off');
end
```

---

### Fix 5: Standardize LaTeX Variable Names 📝

**ACTION:** Update all UI labels in `UI_Layout_Config.m`

**Current inconsistencies:**
- Some use Unicode (ω, ν, Δ)
- Some use ASCII (omega, nu, delta)
- Some use LaTeX ($\omega$, $\nu$, $\Delta$)

**Standard:** **ALL mathematical symbols use LaTeX**

#### Changes to `UI_Layout_Config.m`

**Find and replace throughout:**

```matlab
% TIME LABELS
'dt' → '$\Delta t$'
't_final' → '$T_{final}$'
'Tfinal' → '$T_{final}$'

% GRID LABELS
'Nx' → '$N_x$'
'Ny' → '$N_y$'
'Lx' → '$L_x$'
'Ly' → '$L_y$'
'delta' → '$\Delta$' or '$\Delta x$' (context-dependent)

% PHYSICS LABELS
'nu' → '$\nu$' (viscosity)
'omega' → '$\omega$' (vorticity)
'psi' → '$\psi$' (streamfunction)

% DERIVATIVES
'domega/dt' → '$\partial\omega/\partial t$'
'd2omega/dx2' → '$\partial^2\omega/\partial x^2$'

% NORMS
'|omega|' → '$|\omega|$'
'||omega||' → '$\|\omega\|$'
```

**Example update in `ui_text.config.time`:**

**Before:**
```matlab
cfg.ui_text.config.time = struct( ...
    'panel_title', 'Time and Physics', ...
    'dt_label', 'dt', ...
    'tfinal_label', 'Tfinal', ...
    'nu_label', 'nu (viscosity)');
```

**After:**
```matlab
cfg.ui_text.config.time = struct( ...
    'panel_title', 'Time and Physics', ...
    'dt_label', '$\Delta t$', ...
    'tfinal_label', '$T_{final}$', ...
    'nu_label', '$\nu$ (viscosity)');
```

**Apply to ALL sections:**
- `ui_text.config.grid`
- `ui_text.config.time`
- `ui_text.config.initial_condition`
- `ui_text.monitor.numeric_tile`
- `metric_catalog` (titles, xlabels, ylabels)

---

### Fix 6: Add Tooltips to Complex Parameters 💡

**IMPLEMENTATION:** Add `Tooltip` property to UI components

**Target components:**
- Grid parameters (Nx, Ny, Lx, Ly, delta)
- Time parameters (dt, Tfinal, nu)
- Convergence parameters (tolerance, criterion)
- Sustainability parameters (collectors)

#### Example Tooltips

**Add after component creation:**

```matlab
% Grid tooltips
app.handles.Nx.Tooltip = sprintf(...
    'Number of grid points in x-direction.\nRecommended: 32-256 for FD, 16-128 for Spectral');

app.handles.dt.Tooltip = sprintf(...
    'Time step size.\nMust satisfy CFL condition: dt ≤ min(dx²/nu, dx/|u|)');

app.handles.nu.Tooltip = sprintf(...
    'Kinematic viscosity (ν).\nTypical range: 1e-6 to 1e-2');

app.handles.conv_tolerance.Tooltip = sprintf(...
    'Convergence tolerance.\nSimulation stops when metric < tolerance');

app.handles.cpuz_enable.Tooltip = sprintf(...
    'Enable CPU-Z external collector for detailed CPU metrics.\nRequires CPU-Z running with port access');
```

**Systematic Application:**

**Location:** In `create_config_tab()`, after each component is created, add:

```matlab
app.handles.<component>.Tooltip = 'Description here';
```

**Complete Tooltip List:** (See separate document `UI_TOOLTIPS.md`)

---

## WEEK 3 IMPLEMENTATION

### Fix 7: Enhanced HTML Reports (Plotly.js) 📊

**GOAL:** Create interactive, ANSYS-style HTML reports with:
- Interactive plots (zoom, pan, hover)
- Tabbed sections
- Embedded animations
- Dark theme
- PDF export capability

#### Step 1: Create Enhanced Report Template

**New file:** `Scripts/Infrastructure/Utilities/EnhancedReportGenerator.m`

```matlab
classdef EnhancedReportGenerator
    methods(Static)
        function report_path = generate_interactive_report(run_data, config, paths)
            % Generate ANSYS-style interactive HTML report with Plotly.js

            report_dir = fullfile(paths.base, 'Reports');
            if ~exist(report_dir, 'dir')
                mkdir(report_dir);
            end

            timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
            report_filename = sprintf('interactive_report_%s.html', timestamp);
            report_path = fullfile(report_dir, report_filename);

            % Build HTML with Plotly.js integration
            html = EnhancedReportGenerator.build_html_structure(run_data, config, paths);

            % Write to file
            fid = fopen(report_path, 'w', 'n', 'UTF-8');
            if fid < 0
                error('Failed to create report file: %s', report_path);
            end
            fprintf(fid, '%s', html);
            fclose(fid);
        end

        function html = build_html_structure(run_data, config, paths)
            % Build complete HTML document
            html = [...
                EnhancedReportGenerator.html_header(), ...
                EnhancedReportGenerator.html_navigation(), ...
                EnhancedReportGenerator.html_summary(run_data, config), ...
                EnhancedReportGenerator.html_setup(config), ...
                EnhancedReportGenerator.html_monitoring(run_data), ...
                EnhancedReportGenerator.html_results(run_data, paths), ...
                EnhancedReportGenerator.html_footer()
            ];
        end

        function html = html_header()
            html = sprintf(['<!DOCTYPE html>\n', ...
                '<html lang="en">\n', ...
                '<head>\n', ...
                '  <meta charset="UTF-8">\n', ...
                '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n', ...
                '  <title>Tsunami Vortex Simulation Report</title>\n', ...
                '  <!-- Plotly.js -->\n', ...
                '  <script src="https://cdn.plot.ly/plotly-2.27.0.min.js"></script>\n', ...
                '  <!-- MathJax for LaTeX -->\n', ...
                '  <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>\n', ...
                '  <style>\n', ...
                '    :root {\n', ...
                '      --bg-dark: #0e1117;\n', ...
                '      --bg-panel: #1a1d24;\n', ...
                '      --bg-panel-alt: #262b36;\n', ...
                '      --fg-text: #e8eaed;\n', ...
                '      --fg-muted: #9aa0a6;\n', ...
                '      --accent-cyan: #5bb4ff;\n', ...
                '      --accent-green: #5cff8a;\n', ...
                '      --accent-yellow: #ffd166;\n', ...
                '      --accent-red: #ff6b6b;\n', ...
                '    }\n', ...
                '    * { margin: 0; padding: 0; box-sizing: border-box; }\n', ...
                '    body {\n', ...
                '      font-family: "Segoe UI", Arial, sans-serif;\n', ...
                '      background: var(--bg-dark);\n', ...
                '      color: var(--fg-text);\n', ...
                '      line-height: 1.6;\n', ...
                '    }\n', ...
                '    .container { max-width: 1400px; margin: 0 auto; padding: 20px; }\n', ...
                '    header {\n', ...
                '      background: linear-gradient(135deg, #1a1d24, #262b36);\n', ...
                '      padding: 30px;\n', ...
                '      border-bottom: 3px solid var(--accent-cyan);\n', ...
                '      margin-bottom: 30px;\n', ...
                '    }\n', ...
                '    h1 { font-size: 2.5em; margin-bottom: 10px; color: var(--accent-cyan); }\n', ...
                '    h2 {\n', ...
                '      font-size: 1.8em;\n', ...
                '      margin: 30px 0 15px;\n', ...
                '      padding-bottom: 10px;\n', ...
                '      border-bottom: 2px solid var(--accent-cyan);\n', ...
                '    }\n', ...
                '    h3 { font-size: 1.3em; margin: 20px 0 10px; color: var(--accent-green); }\n', ...
                '    .nav-tabs {\n', ...
                '      display: flex;\n', ...
                '      gap: 10px;\n', ...
                '      margin-bottom: 20px;\n', ...
                '      border-bottom: 2px solid var(--bg-panel-alt);\n', ...
                '    }\n', ...
                '    .nav-tab {\n', ...
                '      padding: 12px 24px;\n', ...
                '      background: var(--bg-panel);\n', ...
                '      color: var(--fg-muted);\n', ...
                '      cursor: pointer;\n', ...
                '      border: none;\n', ...
                '      border-radius: 6px 6px 0 0;\n', ...
                '      font-size: 1em;\n', ...
                '      transition: all 0.3s;\n', ...
                '    }\n', ...
                '    .nav-tab:hover { background: var(--bg-panel-alt); color: var(--fg-text); }\n', ...
                '    .nav-tab.active {\n', ...
                '      background: var(--accent-cyan);\n', ...
                '      color: #0e1117;\n', ...
                '      font-weight: bold;\n', ...
                '    }\n', ...
                '    .tab-content { display: none; }\n', ...
                '    .tab-content.active { display: block; }\n', ...
                '    .kpi-grid {\n', ...
                '      display: grid;\n', ...
                '      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));\n', ...
                '      gap: 20px;\n', ...
                '      margin: 20px 0;\n', ...
                '    }\n', ...
                '    .kpi-card {\n', ...
                '      background: var(--bg-panel);\n', ...
                '      padding: 20px;\n', ...
                '      border-radius: 8px;\n', ...
                '      border-left: 4px solid var(--accent-cyan);\n', ...
                '    }\n', ...
                '    .kpi-label { color: var(--fg-muted); font-size: 0.9em; }\n', ...
                '    .kpi-value {\n', ...
                '      font-size: 2em;\n', ...
                '      font-weight: bold;\n', ...
                '      color: var(--accent-green);\n', ...
                '      margin-top: 5px;\n', ...
                '    }\n', ...
                '    .plot-container {\n', ...
                '      background: var(--bg-panel);\n', ...
                '      padding: 20px;\n', ...
                '      border-radius: 8px;\n', ...
                '      margin: 20px 0;\n', ...
                '    }\n', ...
                '    table {\n', ...
                '      width: 100%%;\n', ...
                '      border-collapse: collapse;\n', ...
                '      margin: 20px 0;\n', ...
                '      background: var(--bg-panel);\n', ...
                '    }\n', ...
                '    th, td {\n', ...
                '      padding: 12px;\n', ...
                '      text-align: left;\n', ...
                '      border-bottom: 1px solid var(--bg-panel-alt);\n', ...
                '    }\n', ...
                '    th {\n', ...
                '      background: var(--bg-panel-alt);\n', ...
                '      font-weight: bold;\n', ...
                '      color: var(--accent-cyan);\n', ...
                '    }\n', ...
                '    .animation-container {\n', ...
                '      background: var(--bg-panel);\n', ...
                '      padding: 20px;\n', ...
                '      border-radius: 8px;\n', ...
                '      text-align: center;\n', ...
                '    }\n', ...
                '    .animation-container video {\n', ...
                '      max-width: 100%%;\n', ...
                '      border-radius: 6px;\n', ...
                '    }\n', ...
                '  </style>\n', ...
                '</head>\n', ...
                '<body>\n']);
        end

        % Additional methods for each section...
        % (Summary, Setup, Monitoring, Results, Footer)
        % See full implementation in separate file
    end
end
```

**Full implementation:** Create complete `EnhancedReportGenerator.m` with:
- Interactive Plotly.js convergence charts
- Tabbed navigation (Summary, Setup, Monitoring, Results)
- KPI cards with metrics
- Embedded MP4/GIF animations
- MathJax LaTeX rendering
- Dark theme matching UI

#### Step 2: Integrate with UIController

**Location:** `generate_report_to_tab()` method

**Replace current implementation:**

```matlab
function generate_report_to_tab(app)
    % Generate enhanced interactive report
    if ~isfield(app.config, 'run_id') || isempty(app.config.run_id)
        app.show_alert_latex('No simulation run yet. Launch a simulation first.', ...
            'No Data', 'Icon', 'warning');
        return;
    end

    % Collect run data
    run_data = struct();
    run_data.run_id = app.config.run_id;
    run_data.method = app.config.method;
    run_data.mode = app.config.mode;
    run_data.monitor_series = app.handles.monitor_live_state;
    run_data.final_metrics = app.collect_final_metrics();

    % Generate report
    report_html = EnhancedReportGenerator.build_html_structure(run_data, app.config, struct());

    % Display in Report tab
    app.report_html_cache = report_html;
    app.handles.report_html.HTMLSource = report_html;
    app.handles.report_export_btn.Enable = 'on';

    app.append_to_terminal('Interactive report generated.', 'success');
end
```

---

### Fix 8: PDF Export Capability 📄

**IMPLEMENTATION:** Use MATLAB's `webwrite` + browser print API

**Method:** Add PDF export button to Report tab

```matlab
function export_report_pdf(app)
    % Export report to PDF via browser print dialog
    if isempty(app.report_html_cache)
        app.show_alert_latex('Generate report first.', 'No Report', 'Icon', 'warning');
        return;
    end

    % Add print CSS media query to HTML
    html_with_print = strrep(app.report_html_cache, '</style>', [...
        '@media print {\n', ...
        '  .nav-tabs { display: none; }\n', ...
        '  .tab-content { display: block !important; }\n', ...
        '  body { background: white; color: black; }\n', ...
        '}\n', ...
        '</style>']);

    % Save to temp file
    temp_html = fullfile(tempdir, 'tsunami_report_print.html');
    fid = fopen(temp_html, 'w', 'n', 'UTF-8');
    fprintf(fid, '%s', html_with_print);
    fclose(fid);

    % Open in default browser with print instruction
    web(temp_html, '-browser');

    app.show_alert_latex(['Report opened in browser.\n\n', ...
        'Use Ctrl+P (Windows) or Cmd+P (Mac) to print to PDF.'], ...
        'PDF Export', 'Icon', 'info');
end
```

**Alternative:** MATLAB Report Generator (requires toolbox)

```matlab
% If Report Generator Toolbox available:
import mlreportgen.dom.*
import mlreportgen.report.*

rpt = Report('TsunamiReport', 'pdf');
% ... add content ...
close(rpt);
rptview(rpt);
```

---

## TESTING CHECKLIST

### Week 1 Tests

- [ ] **Terminal Colors:** Launch UI, check colored messages in Live Monitor
- [ ] **Figure Suppression:** Launch simulation, verify NO external figures appear
- [ ] **Video Controls:** Run animation, test play/pause/stop/loop/speed/scrubber

### Week 2 Tests

- [ ] **FD Stencil:** Select FD method, verify stencil appears in Grid tab
- [ ] **LaTeX Labels:** Check all labels render correctly (no raw $\omega$ text)
- [ ] **Tooltips:** Hover over parameters, verify tooltips appear

### Week 3 Tests

- [ ] **Interactive Report:** Generate report, test Plotly.js zoom/pan
- [ ] **PDF Export:** Export to PDF, verify layout correct
- [ ] **Embedded Animation:** Check video plays in report

---

## DEPLOYMENT CHECKLIST

### Pre-Deployment

- [ ] Create backup branch: `git checkout -b backup-pre-week1-3-fixes`
- [ ] Test on clean MATLAB workspace
- [ ] Document all changes in commit messages

### Deployment Steps

1. **Week 1:**
   - Commit video playback controls
   - Commit figure suppression fixes
   - Test in UI mode

2. **Week 2:**
   - Commit LaTeX standardization
   - Commit stencil view
   - Commit tooltips

3. **Week 3:**
   - Commit `EnhancedReportGenerator.m`
   - Update `UIController.m` report integration
   - Test report generation

### Post-Deployment

- [ ] Update `UI_ANALYSIS_AND_IMPROVEMENT_PLAN.md` with completion status
- [ ] Update Notion Implementation Tasks database
- [ ] Record any issues or edge cases discovered

---

## NEXT STEPS (Weeks 4-6)

### Week 4: Boundary Conditions (FD & Spectral)
- Implement no-slip BC for FD
- Implement lid-driven cavity for FD
- Test with Spectral method

### Week 5: Adaptive Convergence Enhancement
- Read `AdaptiveConvergenceAgent.m`
- Implement Pure/Balanced/Sustainability modes
- Add spectral-specific convergence logic

### Week 6: Testing & Documentation
- Comprehensive UI tests
- Method compatibility testing (FD & Spectral only)
- Documentation updates

---

**END OF WEEKS 1-3 IMPLEMENTATION PLAN**
