function [freeze_onset_times, freeze_offset_times, move_onset_times, move_offset_times] = get_freeze_move_eps(Frames, Freezing, freeze_threshold, move_threshold, FPS, first_s, last_s)
%GET_FREEZE_MOVE_EPS
    time_values = Frames / FPS;
    [~,start_idx] = min(abs(first_s-time_values)); % finds idx in time_values (from Frames) corresponding to first_s
    [~,last_idx] = min(abs(last_s-time_values)); % finds idx in time_values (from Frames) corresponding to last_s

    % For each output file: add frames that mark freezing onset into freeze_onset_frames
                          % add frames that mark freezing offset into freeze_offset_frames
    cons_freeze = 0;
    freeze_onset_frames = [];
    freeze_offset_frames = [];
    threshold_reached = false;

    % Freezing onset/offset
    for i = start_idx:last_idx
        if Freezing(i) == 100
            cons_freeze = cons_freeze + 1;
            if cons_freeze == freeze_threshold
                freeze_onset_frames = [freeze_onset_frames Frames(i-freeze_threshold+1)];
                threshold_reached = true;
            end
        else
            cons_freeze = 0;
            if threshold_reached == true
                freeze_offset_frames = [freeze_offset_frames Frames(i-1)];
                threshold_reached = false;
            end
        end
    end
    freeze_onset_times = (freeze_onset_frames / FPS);
    freeze_offset_times = (freeze_offset_frames / FPS);

    % For each output file: add frames that mark moving onset into move_onset_frames
                          % add frames that mark moving offset into move_offset_frames
    cons_move = 0;
    move_onset_frames = [];
    move_offset_frames = [];
    threshold_reached = false;
    for m = start_idx:last_idx
        if Freezing(m) == 0
            cons_move = cons_move + 1;
            if cons_move == move_threshold
                move_onset_frames = [move_onset_frames Frames(m-move_threshold+1)];
                threshold_reached = true;
            end
        else
            cons_move = 0;
            if threshold_reached == true
                move_offset_frames = [move_offset_frames Frames(m-1)];
                threshold_reached = false;
            end
        end
    end
    move_onset_times = (move_onset_frames / FPS);
    move_offset_times = (move_offset_frames / FPS);
end

