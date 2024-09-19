% FREEZE_MOVE_AVERAGE
% * Reads processed ezTrack output files and photometry data.
% * Plots average signal relative to average event onset, if onset = true.
%   * Freezing onset across session.
%   * Moving onset across session.
% * Plots average signal relative to average event offset, if onset =
% false.

function [] = freeze_move_average(input, signal, output_files, idx, time_range, x_range)

    bCI_y = 4;

    % Group 1 time (-5 to 30 s) and signal, relative to freezing and moving onset
    g1_freeze_time = [];
    g1_freeze_signal = [];
    g1_freeze_signal_sem = [];
    g1_move_time = [];
    g1_move_signal = [];
    g1_move_signal_sem = [];
    
    % Group 2 time (-5 to 30 s) and signal, relative to freezing and moving onset
    g2_freeze_time = [];
    g2_freeze_signal = [];
    g2_freeze_signal_sem = [];
    g2_move_time = [];
    g2_move_signal = [];
    g2_move_signal_sem = [];

    first_s = time_range(1);
    last_s = time_range(1) + time_range(2);
    
    numAnimals = numel(input.animalNames);
    for mouse=1:numAnimals   
        Frames = readmatrix(output_files{idx(mouse)}, 'Range', 'A:A', 'NumHeaderLines', 1);
        Freezing = readmatrix(output_files{idx(mouse)}, 'Range', 'B:B', 'NumHeaderLines', 1);
        
        [freeze_onset_times, freeze_offset_times, move_onset_times, move_offset_times] = get_freeze_move_eps(Frames, Freezing,...
                                                        input.freeze_threshold, input.move_threshold, input.FPS, first_s, last_s);

        if length(freeze_onset_times) ~= length(freeze_offset_times)
            freeze_offset_times = [freeze_offset_times last_s];
        end
        
        if length(move_onset_times) ~= length(move_offset_times)
            move_offset_times = [move_offset_times last_s];
        end

        if input.freeze_move_onset==true
            freeze_times = freeze_onset_times;
            move_times = move_onset_times;
        else
            freeze_times = freeze_offset_times;
            move_times = move_offset_times;
        end

        ts1_adj = signal{mouse}.ts1(signal{mouse}.ts1 >= first_s & signal{mouse}.ts1 < last_s);
        zall_adj = signal{mouse}.zall(signal{mouse}.ts1 >= first_s & signal{mouse}.ts1 < last_s);

        % Plots of individual freezing episodes (-5 to 30 s)
        curr_freeze_time = [];
        curr_freeze_signal = [];
        for eps = 1:length(freeze_times)
            freeze_time = freeze_times(eps); 
            freeze_eps_ts1 = ts1_adj(ts1_adj > freeze_time+(x_range(1)) & ts1_adj < freeze_time+(x_range(2)));
            freeze_eps_zall = zall_adj(ts1_adj > freeze_time+(x_range(1)) & ts1_adj < freeze_time+(x_range(2)));
            freeze_eps_ts1_adj = freeze_eps_ts1 - freeze_time;
            if (first_s - freeze_time) < x_range(1) && (last_s - freeze_time) > x_range(2)
                if isempty(curr_freeze_time) || (length(freeze_eps_ts1_adj)==size(curr_freeze_time,2))
                    curr_freeze_time = [curr_freeze_time; freeze_eps_ts1_adj];
                    curr_freeze_signal = [curr_freeze_signal; freeze_eps_zall];
                else
                    oL = length(freeze_eps_ts1_adj);
                    curr_freeze_time = [curr_freeze_time; interp1(1:oL, freeze_eps_ts1_adj, linspace(1,oL,size(curr_freeze_time,2)))];
                    curr_freeze_signal = [curr_freeze_signal; interp1(1:oL, freeze_eps_zall, linspace(1,oL,size(curr_freeze_signal,2)))];
                end
            end
        end
    
        mean_curr_freeze_time = mean(curr_freeze_time,1);
        mean_curr_freeze_signal = mean(curr_freeze_signal,1);

        sem_curr_freeze_time = std(curr_freeze_time,[],1) / sqrt(size(curr_freeze_time,1));
        sem_curr_freeze_signal = std(curr_freeze_signal,[],1) / sqrt(size(curr_freeze_signal,1));
        
        if ~isempty(mean_curr_freeze_time)
            if strcmp(input.groups(mouse),input.groupNames(1))
                if isempty(g1_freeze_time) || (size(mean_curr_freeze_time,2)==size(g1_freeze_time,2))
                    g1_freeze_time = [g1_freeze_time; mean_curr_freeze_time];
                    g1_freeze_signal = [g1_freeze_signal; mean_curr_freeze_signal];
                    g1_freeze_signal_sem = [g1_freeze_signal_sem; sem_curr_freeze_signal];
                else
                    oL = size(mean_curr_freeze_time,2);
                    mean_curr_freeze_time = interp1(1:oL, mean_curr_freeze_time, linspace(1,oL,size(g1_freeze_time,2)));
                    mean_curr_freeze_signal = interp1(1:oL, mean_curr_freeze_signal, linspace(1,oL,size(g1_freeze_signal,2)));
                    g1_freeze_time = [g1_freeze_time; mean_curr_freeze_time];
                    g1_freeze_signal = [g1_freeze_signal; mean_curr_freeze_signal];

                    sem_curr_freeze_signal = interp1(1:oL, sem_curr_freeze_signal, linspace(1,oL,size(g1_freeze_signal_sem,2)));
                    g1_freeze_signal_sem = [g1_freeze_signal_sem; sem_curr_freeze_signal];
                end
            else
                if isempty(g2_freeze_time) || (size(mean_curr_freeze_time,2)==size(g2_freeze_time,2))
                    g2_freeze_time = [g2_freeze_time; mean_curr_freeze_time];
                    g2_freeze_signal = [g2_freeze_signal; mean_curr_freeze_signal];
                    g2_freeze_signal_sem = [g2_freeze_signal_sem; sem_curr_freeze_signal];
                else
                    oL = size(mean_curr_freeze_time,2);
                    mean_curr_freeze_time = interp1(1:oL, mean_curr_freeze_time, linspace(1,oL,size(g2_freeze_time,2)));
                    mean_curr_freeze_signal = interp1(1:oL, mean_curr_freeze_signal, linspace(1,oL,size(g2_freeze_signal,2)));
                    g2_freeze_time = [g2_freeze_time; mean_curr_freeze_time];
                    g2_freeze_signal = [g2_freeze_signal; mean_curr_freeze_signal];

                    sem_curr_freeze_signal = interp1(1:oL, sem_curr_freeze_signal, linspace(1,oL,size(g2_freeze_signal_sem,2)));
                    g2_freeze_signal_sem = [g2_freeze_signal_sem; sem_curr_freeze_signal];
                end
            end
        end
        
        % Plots of individual moving episodes (-5 to 30 s)
        curr_move_time = [];
        curr_move_signal = [];
        for eps = 1:length(move_times)
            move_time = move_times(eps);
            move_eps_ts1 = ts1_adj(ts1_adj > move_time+(x_range(1)) & ts1_adj < move_time+(x_range(2)));
            move_eps_zall = zall_adj(ts1_adj > move_time+(x_range(1)) & ts1_adj < move_time+(x_range(2)));
            move_eps_ts1_adj = move_eps_ts1 - move_time;
            if (first_s - move_time) < x_range(1) && (last_s - move_time) > x_range(2)
                if isempty(curr_move_time) || length(move_eps_ts1_adj)==length(curr_move_time)
                    curr_move_time = [curr_move_time; move_eps_ts1_adj];
                    curr_move_signal = [curr_move_signal; move_eps_zall];
                else
                    oL = length(move_eps_ts1_adj);
                    curr_move_time = [curr_move_time; interp1(1:oL, move_eps_ts1_adj, linspace(1,oL,length(curr_move_time)))];
                    curr_move_signal = [curr_move_signal; interp1(1:oL, move_eps_zall, linspace(1,oL,length(curr_move_signal)))];
                end
            end
        end
        
        mean_curr_move_time = mean(curr_move_time,1);
        mean_curr_move_signal = mean(curr_move_signal,1);
        
        sem_curr_move_time = std(curr_move_time,[],1) / sqrt(size(curr_move_time,1));
        sem_curr_move_signal = std(curr_move_signal,[],1) / sqrt(size(curr_move_signal,1));
    
        if ~isempty(mean_curr_move_time)
            if strcmp(input.groups(mouse),input.groupNames(1))
                if isempty(g1_move_time) || (size(mean_curr_move_time,2)==size(g1_move_time,2))
                    g1_move_time = [g1_move_time; mean_curr_move_time];
                    g1_move_signal = [g1_move_signal; mean_curr_move_signal];
                    g1_move_signal_sem = [g1_move_signal_sem; sem_curr_move_signal];
                else
                    oL = size(mean_curr_move_time,2);
                    mean_curr_move_time = interp1(1:oL, mean_curr_move_time, linspace(1,oL,size(g1_move_time,2)));
                    mean_curr_move_signal = interp1(1:oL, mean_curr_move_signal, linspace(1,oL,size(g1_move_signal,2)));
                    g1_move_time = [g1_move_time; mean_curr_move_time];
                    g1_move_signal = [g1_move_signal; mean_curr_move_signal];

                    sem_curr_move_signal = interp1(1:oL, sem_curr_move_signal, linspace(1,oL,size(g1_move_signal_sem,2)));
                    g1_move_signal_sem = [g1_move_signal_sem; sem_curr_move_signal];
                end
            else
                if isempty(g2_move_time) || (size(mean_curr_move_time,2)==size(g2_move_time,2))
                    g2_move_time = [g2_move_time; mean_curr_move_time];
                    g2_move_signal = [g2_move_signal; mean_curr_move_signal];
                    g2_move_signal_sem = [g2_move_signal_sem; sem_curr_move_signal];
                else
                    oL = size(mean_curr_move_time,2);
                    mean_curr_move_time = interp1(1:oL, mean_curr_move_time, linspace(1,oL,size(g2_move_time,2)));
                    mean_curr_move_signal = interp1(1:oL, mean_curr_move_signal, linspace(1,oL,size(g2_move_signal,2)));
                    g2_move_time = [g2_move_time; mean_curr_move_time];
                    g2_move_signal = [g2_move_signal; mean_curr_move_signal];

                    sem_curr_move_signal = interp1(1:oL, sem_curr_move_signal, linspace(1,oL,size(g2_move_signal_sem,2)));
                    g2_move_signal_sem = [g2_move_signal_sem; sem_curr_move_signal];
                end
            end
        end
    end

    if length(input.groupNames)==2
        if size(g1_freeze_signal,2) ~= size(g2_freeze_signal,2)
            size_diff = size(g2_freeze_signal,2) - size(g1_freeze_signal,2);
            if size_diff < 0 % g1 is longer by abs(size_diff)
                orig_length = size(g1_freeze_signal,2);
                g1_freeze_time = g1_freeze_time(:,1:orig_length-abs(size_diff));
                g1_freeze_signal = g1_freeze_signal(:,1:orig_length-abs(size_diff));
                g1_freeze_signal_sem = g1_freeze_signal_sem(:,1:orig_length-abs(size_diff));
            elseif size_diff > 0 % g2 is longer by abs(size_diff)
                orig_length = size(g2_freeze_signal,2);
                g2_freeze_time = g2_freeze_time(:,1:orig_length-abs(size_diff));
                g2_freeze_signal = g2_freeze_signal(:,1:orig_length-abs(size_diff));
                g2_freeze_signal_sem = g2_freeze_signal_sem(:,1:orig_length-abs(size_diff));
            end
        end
        if size(g1_move_signal,2) ~= size(g2_move_signal,2)
            size_diff = size(g2_move_signal,2) - size(g1_move_signal,2);
            if size_diff < 0 % g1 is longer by abs(size_diff)
                orig_length = size(g1_move_signal,2);
                g1_move_time = g1_move_time(:,1:orig_length-abs(size_diff));
                g1_move_signal = g1_move_signal(:,1:orig_length-abs(size_diff));
                g1_move_signal_sem = g1_move_signal_sem(:,1:orig_length-abs(size_diff));
            elseif size_diff > 0 % g2 is longer by abs(size_diff)
                orig_length = size(g2_move_signal,2);
                g2_move_time = g2_move_time(:,1:orig_length-abs(size_diff));
                g2_move_signal = g2_move_signal(:,1:orig_length-abs(size_diff));
                g2_move_signal_sem = g2_move_signal_sem(:,1:orig_length-abs(size_diff));
            end
        end
    end

    mean_g1_freeze_time = mean(g1_freeze_time,1);
    mean_g2_freeze_time = mean(g2_freeze_time,1);
    mean_g1_freeze_signal = mean(g1_freeze_signal,1);
    mean_g2_freeze_signal = mean(g2_freeze_signal,1);
    
    mean_g1_move_time = mean(g1_move_time,1);
    mean_g2_move_time = mean(g2_move_time,1);
    mean_g1_move_signal = mean(g1_move_signal,1);
    mean_g2_move_signal = mean(g2_move_signal,1);

    g1_freeze_signal_sem_prop = [];
    for col=1:size(g1_freeze_signal_sem,2)
        g1_freeze_signal_sem_prop(1,col) = propagate_error(g1_freeze_signal_sem(:,col));
    end

    g1_move_signal_sem_prop = [];
    for col=1:size(g1_move_signal_sem,2)
        g1_move_signal_sem_prop(1,col) = propagate_error(g1_move_signal_sem(:,col));
    end

    g2_freeze_signal_sem_prop = [];
    for col=1:size(g2_freeze_signal_sem,2)
        g2_freeze_signal_sem_prop(1,col) = propagate_error(g2_freeze_signal_sem(:,col));
    end

    g2_move_signal_sem_prop = [];
    for col=1:size(g2_move_signal_sem,2)
        g2_move_signal_sem_prop(1,col) = propagate_error(g2_move_signal_sem(:,col));
    end
    
    % Mean signal relative to mean freezing onset
    
    figure; hold on;
    plot(mean_g1_freeze_time, mean_g1_freeze_signal, 'Color', [.0 .3 .0], 'LineWidth', 2.5); hold on;        
    errorplot3(mean_g1_freeze_signal-g1_freeze_signal_sem_prop, mean_g1_freeze_signal+g1_freeze_signal_sem_prop, [min(mean_g1_freeze_time) max(mean_g1_freeze_time)], [.0 .3 .0],.15); hold on;
    
    if numel(input.groupNames)==2
        plot(mean_g2_freeze_time, mean_g2_freeze_signal, 'LineWidth', 2.5, 'Color', [0.6350 0.0780 0.1840]); hold on;
        errorplot3(mean_g2_freeze_signal-g2_freeze_signal_sem_prop, mean_g2_freeze_signal+g2_freeze_signal_sem_prop, [min(mean_g2_freeze_time) max(mean_g2_freeze_time)], [0.6350 0.0780 0.1840],.15); hold on;
    end
    
    plot([0 0], [-3 4], 'Color', [0.6350 0.0780 0.1840], 'LineStyle', '-'); hold on;
    
    % Bootstrapping - freezing plot
    sig = .05;
    consec_thresh = 3.3;
    
    % run bCI
    ERT_test.g1_freeze = g1_freeze_signal;
    ERT_test.g2_freeze = g2_freeze_signal;
    
    [n_g1_freeze,ev_win_freeze] = size(ERT_test.g1_freeze);
    [n_g2_freeze,~] = size(ERT_test.g2_freeze);
    timeline = linspace(+(x_range(1)),+(x_range(2)),ev_win_freeze);
    
    %g1_freeze bCI
    mean_g1_freeze = mean(ERT_test.g1_freeze,1);
    sem_g1_freeze = std(ERT_test.g1_freeze) / sqrt(size(ERT_test.g1_freeze,1));
    g1_freeze_bCI = boot_CI(ERT_test.g1_freeze,1000,sig);
    [adjLCI,adjUCI] = CIadjust(g1_freeze_bCI(1,:),g1_freeze_bCI(2,:),[],n_g1_freeze,2);
    g1_freeze_bCIexp = [adjLCI;adjUCI];
    
    g1_freeze_bCIexp_sig = NaN(1,ev_win_freeze);
    sig_idx = find((g1_freeze_bCIexp(1,:) > 0) | (g1_freeze_bCIexp(2,:) < 0));
    consec = consec_idx(sig_idx,consec_thresh);
    g1_freeze_bCIexp_sig(sig_idx(consec)) = bCI_y;
    
    %Plot bCI
    plot(timeline,g1_freeze_bCIexp_sig,'Color','red','Marker','.'); hold on;
    text(2,bCI_y+0.1,'\bf bCI','Color','red');
    
    % Permutation test - freezing plot
    
    if length(input.groupNames)==2
        sig = .05;
        consec_thresh = 3.3;
        
        ERT_test.g1_freeze = g1_freeze_signal; % group 1 (Cm)
        ERT_test.g2_freeze = g2_freeze_signal; % group 2 (Cp)
        [n_g2_freeze,ev_win_freeze] = size(ERT_test.g2_freeze);
        [n_g1_freeze,~] = size(ERT_test.g1_freeze);
        
        mean_g2_freeze = mean(ERT_test.g2_freeze,1);
        sem_g2_freeze = std(ERT_test.g2_freeze) / sqrt(size(ERT_test.g2_freeze,1));
        mean_g1_freeze = mean(ERT_test.g1_freeze,1);
        sem_g1_freeze = std(ERT_test.g1_freeze) / sqrt(size(ERT_test.g1_freeze,1));
        
        perm_p_freeze = permTest_array(ERT_test.g2_freeze,ERT_test.g1_freeze,1000);
        perm_p_sig_freeze = NaN(1,ev_win_freeze);
        sig_idx_freeze = find(perm_p_freeze < sig);
        consec_freeze = consec_idx(sig_idx_freeze,consec_thresh);
        perm_p_sig_freeze(sig_idx_freeze(consec_freeze)) = max(max(mean_g1_freeze), max(mean_g2_freeze)) * 1.1;
        
        plot(mean_g1_freeze_time,perm_p_sig_freeze,'Color',col_rep(1),'Marker','.', 'LineWidth', 1); hold on;
    end

    if input.freeze_move_onset==true
        xlabel("Freezing onset");
    else
        xlabel("Freezing offset");
    end
    
    % Mean signal relative to mean moving onset
    
    figure; hold on;
    plot(mean_g1_move_time, mean_g1_move_signal, 'Color', [.1 .7 .1], 'LineWidth', 2.5); hold on;
    errorplot3(mean_g1_move_signal-g1_move_signal_sem_prop, mean_g1_move_signal+g1_move_signal_sem_prop, [min(mean_g1_move_time) max(mean_g1_move_time)], [.1 .7 .1],.15); hold on;

    if numel(input.groupNames)==2
        plot(mean_g2_move_time, mean_g2_move_signal, 'LineWidth', 2.5, 'Color', [1 0 0]); hold on;
        errorplot3(mean_g2_move_signal-g2_move_signal_sem_prop, mean_g2_move_signal+g2_move_signal_sem_prop, [min(mean_g2_move_time) max(mean_g2_move_time)], [1 0 0],.15); hold on;
    end

    plot([0 0], [-3 4], 'Color', [0.4660 0.6740 0.1880], 'LineStyle', '-'); hold on;
    
    % Bootstrapping - moving plot
    sig = .05;
    consec_thresh = 3.3;
    
    % run bCI
    ERT_test.g1_move = g1_move_signal;
    ERT_test.g2_move = g2_move_signal;
    
    [n_g1_move,ev_win_move] = size(ERT_test.g1_move);
    [n_g2_move,~] = size(ERT_test.g2_move);
    timeline = linspace(x_range(1),x_range(2),ev_win_move);
    
    %g1_freeze bCI
    mean_g1_move = mean(ERT_test.g1_move,1);
    sem_g1_move = std(ERT_test.g1_move) / sqrt(size(ERT_test.g1_move,1));
    g1_move_bCI = boot_CI(ERT_test.g1_move,1000,sig);
    [adjLCI,adjUCI] = CIadjust(g1_move_bCI(1,:),g1_move_bCI(2,:),[],n_g1_move,2);
    g1_move_bCIexp = [adjLCI;adjUCI];
    
    g1_move_bCIexp_sig = NaN(1,ev_win_move);
    sig_idx = find((g1_move_bCIexp(1,:) > 0) | (g1_move_bCIexp(2,:) < 0));
    consec = consec_idx(sig_idx,consec_thresh);
    g1_move_bCIexp_sig(sig_idx(consec)) = bCI_y;
    
    %Plot bCI
    plot(timeline,g1_move_bCIexp_sig,'Color','red','Marker','.'); hold on;
    text(2,bCI_y+0.1,'\bf bCI','Color','red');
    
    % Permutation test - moving plot
    
    if length(input.groupNames)==2
        ERT_test.g1_move = g1_move_signal; % group 1 (Cm)
        ERT_test.g2_move = g2_move_signal; % group 2 (Cp)
        
        [n_g2_move,ev_win_move] = size(ERT_test.g2_move);
        [n_g1_move,~] = size(ERT_test.g1_move);
        
        mean_g2_move = mean(ERT_test.g2_move,1);
        sem_g2_move = std(ERT_test.g2_move) / sqrt(size(ERT_test.g2_move,1));
        
        mean_g1_move = mean(ERT_test.g1_move,1);
        sem_g1_move = std(ERT_test.g1_move) / sqrt(size(ERT_test.g1_move,1));
        
        perm_p_move = permTest_array(ERT_test.g2_move,ERT_test.g1_move,1000);
        
        perm_p_sig_move = NaN(1,ev_win_move);
        sig_idx_move = find(perm_p_move < sig);
        consec_move = consec_idx(sig_idx_move,consec_thresh);
        perm_p_sig_move(sig_idx_move(consec_move)) = max(max(mean_g1_move), max(mean_g2_move)) * 1.1;
        
        plot(mean_g1_move_time,perm_p_sig_move,'Color',col_rep(1),'Marker','.', 'LineWidth', 1); hold on;
    end

    if input.freeze_move_onset==true
        xlabel("Moving onset");
    else
        xlabel("Moving offset");
    end

end