function [ok, msg] = test_ui_time_physics_video_triplet()
% test_ui_time_physics_video_triplet - Validate in-app MP4/AVI/GIF preview triplet behavior.

    ok = false;
    msg = '';
    app = [];

    try
        ensure_ui_test_paths();
        app = UIController('StartupMode', 'ui');

        assert(isfield(app.handles, 'time_video_axes_map') && isstruct(app.handles.time_video_axes_map), ...
            'Missing time_video_axes_map.');
        assert(isfield(app.handles.time_video_axes_map, 'mp4') && ...
            isfield(app.handles.time_video_axes_map, 'avi') && ...
            isfield(app.handles.time_video_axes_map, 'gif'), ...
            'Triplet must expose mp4/avi/gif axes.');
        assert(isfield(app.handles, 'time_video_status') && isvalid(app.handles.time_video_status), ...
            'Missing shared triplet status label.');

        figs_before = numel(findall(groot, 'Type', 'figure'));
        app.load_time_video_triplet('AutoGenerate', true);
        drawnow;

        state = app.get_time_video_state_snapshot();
        assert(isstruct(state) && isfield(state, 'streams') && ~isempty(state.streams), ...
            'Triplet state snapshot must expose loaded stream metadata.');
        available = arrayfun(@(s) isfield(s, 'available') && s.available, state.streams);
        assert(any(available), ...
            'Expected at least one playable stream after auto-generation fallback.');

        app.play_time_video_triplet();
        pause(1.2);
        app.pause_time_video_triplet();
        drawnow;

        state_after = app.get_time_video_state_snapshot();
        advanced = false;
        for idx = 1:numel(state_after.streams)
            s = state_after.streams(idx);
            if s.available && s.frame_count > 1 && s.frame_index > 1
                advanced = true;
                break;
            end
        end
        assert(advanced, 'Triplet playback did not advance any available stream.');

        app.restart_time_video_triplet();
        state_restart = app.get_time_video_state_snapshot();
        for idx = 1:numel(state_restart.streams)
            s = state_restart.streams(idx);
            if s.available
                assert(s.frame_index == 1, 'Restart must reset frame index to 1 for available streams.');
            end
        end

        figs_after = numel(findall(groot, 'Type', 'figure'));
        assert(figs_after == figs_before, ...
            'Triplet loading/playback should not create additional standalone figure windows.');

        ok = true;
        msg = 'Time/Physics triplet checks passed.';
    catch ME
        msg = sprintf('%s (%s)', ME.message, ME.identifier);
    end

    try
        if ~isempty(app) && isvalid(app)
            app.cleanup();
            delete(app);
        end
    catch
    end
end
