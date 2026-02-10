function [passed, details] = test_ui_user_flow()
% test_ui_user_flow - Automated UI startup flow test (user perspective)
%
% Uses constructor startup override to emulate a user selecting UI mode.

    passed = false;
    details = '';
    app = [];

    try
        app = UIController('StartupMode', 'ui');

        assert(~isempty(app), 'UIController returned an empty app object.');
        assert(isprop(app, 'fig') && isvalid(app.fig), 'Main UI figure was not created.');
        assert(isprop(app, 'root_grid') && isvalid(app.root_grid), 'Root grid was not created.');
        assert(isprop(app, 'tab_group') && isvalid(app.tab_group), 'Tab group was not created.');

        passed = true;
        details = 'UIController startup user flow passed.';

    catch ME
        details = sprintf('%s (%s)', ME.message, ME.identifier);
    end

    try
        if ~isempty(app) && isvalid(app)
            app.cleanup();
            delete(app);
        elseif ~isempty(app) && isprop(app, 'fig') && isvalid(app.fig)
            delete(app.fig);
        end
    catch
    end
end
