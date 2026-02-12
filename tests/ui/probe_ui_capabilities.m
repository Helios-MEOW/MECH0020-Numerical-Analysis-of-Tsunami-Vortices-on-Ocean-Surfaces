function artifacts = probe_ui_capabilities(varargin)
% probe_ui_capabilities - Empirical UI capability probe for LaTeX/animation support.
%
% Usage:
%   artifacts = probe_ui_capabilities();
%   artifacts = probe_ui_capabilities('OutputDir', 'Artifacts/TestReports/UICapabilityProbe');

    p = inputParser;
    addParameter(p, 'OutputDir', fullfile('Artifacts', 'TestReports', 'UICapabilityProbe'), @(x) ischar(x) || isstring(x));
    parse(p, varargin{:});
    output_dir = char(string(p.Results.OutputDir));

    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    artifacts = struct( ...
        'timestamp', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), ...
        'latex_uiaxes', false, ...
        'latex_uilabel', false, ...
        'animatedline_uiaxes', false, ...
        'frame_capture_uiaxes', false, ...
        'latex_classic_axes', false, ...
        'animatedline_classic_axes', false, ...
        'frame_capture_classic_axes', false, ...
        'ui_frame_png', '', ...
        'classic_frame_png', '', ...
        'report_json', '', ...
        'report_md', '', ...
        'recommendation', '');

    fig_ui = [];
    fig_classic = [];
    cleanup = onCleanup(@() local_cleanup(fig_ui, fig_classic));

    % --- Probe uifigure/uiaxes path ---
    try
        fig_ui = uifigure('Visible', 'off', 'Name', 'UI Capability Probe', 'Position', [100 100 900 600]); %#ok<NASGU>
        grid = uigridlayout(fig_ui, [2 2]); %#ok<NASGU>
        ax_ui = uiaxes(fig_ui);
        ax_ui.Position = [40 170 380 380];
        title(ax_ui, '$\omega(x,y,t)$', 'Interpreter', 'latex');
        xlabel(ax_ui, '$x$', 'Interpreter', 'latex');
        ylabel(ax_ui, '$y$', 'Interpreter', 'latex');
        artifacts.latex_uiaxes = strcmpi(string(ax_ui.Title.Interpreter), "latex") && ...
            strcmpi(string(ax_ui.XLabel.Interpreter), "latex") && ...
            strcmpi(string(ax_ui.YLabel.Interpreter), "latex");

        try
            lbl = uilabel(fig_ui, 'Text', '$\omega_{max}$'); %#ok<NASGU>
            lbl.Position = [460 500 380 30];
            if isprop(lbl, 'Interpreter')
                lbl.Interpreter = 'latex';
                artifacts.latex_uilabel = strcmpi(string(lbl.Interpreter), "latex");
            else
                artifacts.latex_uilabel = false;
            end
        catch
            artifacts.latex_uilabel = false;
        end

        try
            h = animatedline(ax_ui, 'LineWidth', 1.4, 'Color', [0.05 0.65 0.95]); %#ok<NASGU>
            t = linspace(0, 2*pi, 60);
            for k = 1:numel(t)
                addpoints(h, t(k), sin(t(k)));
            end
            drawnow;
            artifacts.animatedline_uiaxes = true;
        catch
            artifacts.animatedline_uiaxes = false;
        end

        try
            ui_frame = getframe(ax_ui);
            ui_png = fullfile(output_dir, sprintf('ui_capability_uiaxes_%s.png', stamp));
            imwrite(ui_frame.cdata, ui_png);
            artifacts.frame_capture_uiaxes = true;
            artifacts.ui_frame_png = ui_png;
        catch
            artifacts.frame_capture_uiaxes = false;
        end
    catch
        artifacts.latex_uiaxes = false;
        artifacts.animatedline_uiaxes = false;
        artifacts.frame_capture_uiaxes = false;
    end

    % --- Probe classic figure/axes path ---
    try
        fig_classic = figure('Visible', 'off', 'Name', 'Classic Capability Probe', 'Position', [120 120 700 500]); %#ok<NASGU>
        ax_cl = axes(fig_classic); %#ok<LAXES>
        title(ax_cl, '$\omega(x,y,t)$', 'Interpreter', 'latex');
        xlabel(ax_cl, '$x$', 'Interpreter', 'latex');
        ylabel(ax_cl, '$y$', 'Interpreter', 'latex');
        artifacts.latex_classic_axes = strcmpi(string(ax_cl.Title.Interpreter), "latex") && ...
            strcmpi(string(ax_cl.XLabel.Interpreter), "latex") && ...
            strcmpi(string(ax_cl.YLabel.Interpreter), "latex");

        try
            h2 = animatedline(ax_cl, 'LineWidth', 1.4, 'Color', [0.95 0.4 0.1]); %#ok<NASGU>
            t2 = linspace(0, 2*pi, 60);
            for k = 1:numel(t2)
                addpoints(h2, t2(k), cos(t2(k)));
            end
            drawnow;
            artifacts.animatedline_classic_axes = true;
        catch
            artifacts.animatedline_classic_axes = false;
        end

        try
            cl_frame = getframe(ax_cl);
            cl_png = fullfile(output_dir, sprintf('ui_capability_classic_axes_%s.png', stamp));
            imwrite(cl_frame.cdata, cl_png);
            artifacts.frame_capture_classic_axes = true;
            artifacts.classic_frame_png = cl_png;
        catch
            artifacts.frame_capture_classic_axes = false;
        end
    catch
        artifacts.latex_classic_axes = false;
        artifacts.animatedline_classic_axes = false;
        artifacts.frame_capture_classic_axes = false;
    end

    if artifacts.latex_uiaxes && artifacts.animatedline_uiaxes
        artifacts.recommendation = 'Keep MATLAB UI for current scope. Use uiaxes for LaTeX + animation, and reserve architecture migration for later if custom widgets exceed uifigure constraints.';
    else
        artifacts.recommendation = 'Current MATLAB UI feature coverage is insufficient. Prototype a desktop frontend bridge next (Python/JS wrapper) with MATLAB backend retained.';
    end

    artifacts.report_json = fullfile(output_dir, sprintf('ui_capability_probe_%s.json', stamp));
    artifacts.report_md = fullfile(output_dir, sprintf('ui_capability_probe_%s.md', stamp));
    write_probe_reports(artifacts);

    %#ok<NASGU>
    clear cleanup;
    local_cleanup(fig_ui, fig_classic);
end

function write_probe_reports(artifacts)
    fid = fopen(artifacts.report_json, 'w');
    fwrite(fid, jsonencode(artifacts), 'char');
    fclose(fid);

    lines = {
        '# UI Capability Probe'
        ''
        ['Timestamp: ', artifacts.timestamp]
        ''
        '## Results'
        ['- latex_uiaxes: ', tf_text(artifacts.latex_uiaxes)]
        ['- latex_uilabel: ', tf_text(artifacts.latex_uilabel)]
        ['- animatedline_uiaxes: ', tf_text(artifacts.animatedline_uiaxes)]
        ['- frame_capture_uiaxes: ', tf_text(artifacts.frame_capture_uiaxes)]
        ['- latex_classic_axes: ', tf_text(artifacts.latex_classic_axes)]
        ['- animatedline_classic_axes: ', tf_text(artifacts.animatedline_classic_axes)]
        ['- frame_capture_classic_axes: ', tf_text(artifacts.frame_capture_classic_axes)]
        ''
        '## Artifacts'
        ['- uiaxes frame: ', artifacts.ui_frame_png]
        ['- classic axes frame: ', artifacts.classic_frame_png]
        ['- json: ', artifacts.report_json]
        ['- markdown: ', artifacts.report_md]
        ''
        '## Recommendation'
        ['- ', artifacts.recommendation]
    };

    fid = fopen(artifacts.report_md, 'w');
    fprintf(fid, '%s\n', strjoin(lines, newline));
    fclose(fid);
end

function out = tf_text(tf)
    if tf
        out = 'PASS';
    else
        out = 'FAIL';
    end
end

function local_cleanup(fig_ui, fig_classic)
    try
        if ~isempty(fig_ui) && isvalid(fig_ui)
            delete(fig_ui);
        end
    catch
    end
    try
        if ~isempty(fig_classic) && isvalid(fig_classic)
            close(fig_classic);
        end
    catch
    end
end
