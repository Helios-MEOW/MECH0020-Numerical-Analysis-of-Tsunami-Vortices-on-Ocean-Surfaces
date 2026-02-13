function test_ui_layout_sandbox()
% test_ui_layout_sandbox - Contract checks for layout-manifest sandbox UI.

    ensure_ui_test_paths();
    cfg = UI_Layout_Config();

    assert(isfield(cfg, 'layout_manifest') && isstruct(cfg.layout_manifest) && ~isempty(cfg.layout_manifest), ...
        'UI_Layout_Config must expose non-empty layout_manifest.');
    assert(isfield(cfg, 'tab_layout') && isstruct(cfg.tab_layout) && ...
        isfield(cfg.tab_layout, 'config') && isfield(cfg.tab_layout.config, 'grid') && ...
        isfield(cfg.tab_layout.config, 'sections'), ...
        'UI_Layout_Config must expose grouped per-tab layout settings.');
    assert(isfield(cfg, 'tab_group') && isfield(cfg.tab_group, 'order') && numel(cfg.tab_group.order) >= 3, ...
        'UI_Layout_Config must expose configurable tab order.');
    assert(isfield(cfg, 'text') && isfield(cfg.text, 'tabs') && isfield(cfg.text, 'monitor_panels'), ...
        'UI_Layout_Config must expose centralized text manifest.');
    assert(isfield(cfg, 'defaults_source') && isfield(cfg.defaults_source, 'loader') && ...
        contains(lower(string(cfg.defaults_source.loader)), 'create_default_parameters'), ...
        'UI_Layout_Config must expose defaults provenance.');

    sandbox = UI_Layout_Sandbox('Visible', 'off');
    cleanup_obj = onCleanup(@() close_sandbox(sandbox));

    assert(isfield(sandbox, 'fig') && isvalid(sandbox.fig), 'Sandbox must return a valid uifigure handle.');

    tabs = findall(sandbox.fig, 'Type', 'uitab');
    tab_titles = lower(string({tabs.Title}));
    assert(any(tab_titles == lower(string(cfg.text.tabs.config))), 'Sandbox missing Configuration tab.');
    assert(any(tab_titles == lower(string(cfg.text.tabs.monitoring))), 'Sandbox missing Live Monitor tab.');
    assert(any(tab_titles == lower(string(cfg.text.tabs.results))), 'Sandbox missing Results tab.');

    monitor_panels = findall(sandbox.fig, 'Type', 'uipanel', 'Title', cfg.text.monitor_panels.dashboard);
    assert(~isempty(monitor_panels), 'Sandbox missing monitor dashboard panel title from config.');
    monitor_tables = findall(sandbox.fig, 'Type', 'uitable');
    assert(~isempty(monitor_tables) && all(arrayfun(@(t) numel(t.ColumnName) >= 1, monitor_tables)), ...
        'Sandbox should provide placeholder monitor numeric table(s).');

    %#ok<NASGU>
    clear cleanup_obj;
end

function close_sandbox(sandbox)
    if isstruct(sandbox) && isfield(sandbox, 'fig')
        try
            if isvalid(sandbox.fig)
                delete(sandbox.fig);
            end
        catch
        end
    end
end
