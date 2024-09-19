% FREEZE_MOVE_AVERAGE_CS_ITI
% * Reads processed ezTrack output files and photometry data.
% * Plots average signal relative to average event onset, if onset = true.
%   * Freezing onset during CS.
%   * Moving onset during CS.
%   * Freezing onset during ITI.
%   * Moving onset during ITI.
% * Plots average signal relative to average event offset, if onset = false.

function [] = freeze_move_average_CS_ITI(input, signal, output_files, idx, time_range, CS_range, x_range)

    bCI_y = 6;

    if ~strcmp(input.stage, "conditioning")
        CS_first_secs = 0:90:2160;
        CS_last_secs = 30:90:2190;
        ITI_first_secs = 30:90:2190;
        ITI_last_secs = 90:90:2250;
    else
        CS_first_secs = [0 90 210];
        CS_last_secs = [30 120 240];
        ITI_first_secs = [30 120 240];
        ITI_last_secs = [90 210 300];
    end

    g1_num_freeze_CS = []; % per mouse
    g1_num_freeze_ITI = [];
    g1_num_move_CS = [];
    g1_num_move_ITI = [];

    g2_num_freeze_CS = [];
    g2_num_freeze_ITI = [];
    g2_num_move_CS = [];
    g2_num_move_ITI = [];

    for event=1:2
        % Group 1 time (-5 to 30 s) and signal, relative to freezing and moving onset
        g1_freeze_time = [];
        g1_freeze_signal = [];
        g1_freeze_signal_sem = [];
        g1_move_time = [];
        g1_move_signal = [];
        g1_move_signal_sem = [];
        
        % Group 2 time (-5 to 30 s) and signal, relative to freezing and moving onset
        if length(input.groupNames)==2
            g2_freeze_time = [];
            g2_freeze_signal = [];
            g2_freeze_signal_sem = [];
            g2_move_time = [];
            g2_move_signal = [];
            g2_move_signal_sem = [];
        end
    
        if event==1
            event_first_secs = CS_first_secs;
            event_last_secs = CS_last_secs;
        else
            event_first_secs = ITI_first_secs;
            event_last_secs = ITI_last_secs;
        end

        first_s = time_range(1);
        last_s = time_range(1) + time_range(2);
        numAnimals = numel(input.animalNames);

        for mouse=1:numAnimals
            Frames = readmatrix(output_files{idx(mouse)}, 'Range', 'A:A', 'NumHeaderLines', 1);
            Freezing = readmatrix(output_files{idx(mouse)}, 'Range', 'B:B', 'NumHeaderLines', 1);
    
            freeze_onset_times = [];
            freeze_offset_times = [];
            move_onset_times = [];
            move_offset_times = [];

            ts1_adj = signal{mouse}.ts1(signal{mouse}.ts1 >= first_s & signal{mouse}.ts1 < last_s);
            zall_adj = signal{mouse}.zall(signal{mouse}.ts1 >= first_s & signal{mouse}.ts1 < last_s);

            % Combine all freezing and moving onset or offset, ONLY in CS or ITI
            for CS=CS_range(1):CS_range(2)
                [freeze_onset_times_evt, freeze_offset_times_evt, move_onset_times_evt, move_offset_times_evt] = get_freeze_move_eps(Frames, Freezing,...
                    input.freeze_threshold, input.move_threshold, input.FPS, event_first_secs(CS), event_last_secs(CS));
                freeze_onset_times = [freeze_onset_times freeze_onset_times_evt];
                freeze_offset_times = [freeze_offset_times freeze_offset_times_evt];
                move_onset_times = [move_onset_times move_onset_times_evt];
                move_offset_times = [move_offset_times move_offset_times_evt];
            end
            
            if input.freeze_move_onset==true
                freeze_times = freeze_onset_times;
                move_times = move_onset_times;
            else
                freeze_times = freeze_offset_times;
                move_times = move_offset_times;
            end

            % Plots of individual freezing episodes (-5 to 30 s)
            curr_freeze_time = [];
            curr_freeze_signal = [];
            for eps = 1:length(freeze_times)
                freeze_time = freeze_times(eps);
                freeze_eps_ts1 = ts1_adj(ts1_adj > freeze_time+x_range(1) & ts1_adj < freeze_time+x_range(2));
                freeze_eps_zall = zall_adj(ts1_adj > freeze_time+x_range(1) & ts1_adj < freeze_time+x_range(2));
                freeze_eps_ts1_adj = freeze_eps_ts1 - freeze_time;
                if abs(time_range(1) - freeze_times(eps))>abs(x_range(1)) && abs(time_range(1)+time_range(2) - freeze_times(eps))>abs(x_range(2))
                    curr_freeze_time = add_adj_vector(curr_freeze_time, freeze_eps_ts1_adj);
                    curr_freeze_signal = add_adj_vector(curr_freeze_signal, freeze_eps_zall);
                end
            end
        
            mean_curr_freeze_time = mean(curr_freeze_time,1);
            mean_curr_freeze_signal = mean(curr_freeze_signal,1);
            sem_curr_freeze_signal = std(curr_freeze_signal,[],1) / sqrt(size(curr_freeze_signal,1));
            
            if ~isempty(mean_curr_freeze_time)
                if strcmp(input.groups(mouse),input.groupNames(1))
                    g1_freeze_time = add_adj_vector(g1_freeze_time, mean_curr_freeze_time);
                    g1_freeze_signal = add_adj_vector(g1_freeze_signal, mean_curr_freeze_signal);
                    g1_freeze_signal_sem = add_adj_vector(g1_freeze_signal_sem, sem_curr_freeze_signal);
                else
                    g2_freeze_time = add_adj_vector(g2_freeze_time, mean_curr_freeze_time);
                    g2_freeze_signal = add_adj_vector(g2_freeze_signal, mean_curr_freeze_signal);
                    g2_freeze_signal_sem = add_adj_vector(g2_freeze_signal_sem, sem_curr_freeze_signal);
                end
            end
            
            % Plots of individual moving episodes (-5 to 30 s)
            curr_move_time = [];
            curr_move_signal = [];
            for eps = 1:length(move_times)
                move_time = move_times(eps);
                move_eps_ts1 = ts1_adj(ts1_adj > move_time+x_range(1) & ts1_adj < move_time+x_range(2));
                move_eps_zall = zall_adj(ts1_adj > move_time+x_range(1) & ts1_adj < move_time+x_range(2));
                move_eps_ts1_adj = move_eps_ts1 - move_time;
                if abs(time_range(1) - move_times(eps))>abs(x_range(1)) && abs(time_range(1)+time_range(2) - move_times(eps))>abs(x_range(2))
                    curr_move_time = add_adj_vector(curr_move_time, move_eps_ts1_adj);
                    curr_move_signal = add_adj_vector(curr_move_signal, move_eps_zall);
                end
            end
            
            mean_curr_move_time = mean(curr_move_time,1);
            mean_curr_move_signal = mean(curr_move_signal,1);
            sem_curr_move_signal = std(curr_move_signal,[],1) / sqrt(size(curr_move_signal,1));
        
            if ~isempty(mean_curr_move_time)
                if strcmp(input.groups(mouse),input.groupNames(1))
                    g1_move_time = add_adj_vector(g1_move_time, mean_curr_move_time);
                    g1_move_signal = add_adj_vector(g1_move_signal, mean_curr_move_signal);
                    g1_move_signal_sem = add_adj_vector(g1_move_signal_sem, sem_curr_move_signal);
                else
                    g2_move_time = add_adj_vector(g2_move_time, mean_curr_move_time);
                    g2_move_signal = add_adj_vector(g2_move_signal, mean_curr_move_signal);
                    g2_move_signal_sem = add_adj_vector(g2_move_signal_sem, sem_curr_move_signal);
                end
            end

            if event==1
                if strcmp(input.groups(mouse),input.groupNames(1))
                    g1_num_freeze_CS = [g1_num_freeze_CS; size(curr_freeze_signal,1)];
                    g1_num_move_CS = [g1_num_move_CS; size(curr_move_signal,1)];
                else
                    g2_num_freeze_CS = [g2_num_freeze_CS; size(curr_freeze_signal,1)];
                    g2_num_move_CS = [g2_num_move_CS; size(curr_move_signal,1)];
                end
            else
                if strcmp(input.groups(mouse),input.groupNames(1))
                    g1_num_freeze_ITI = [g1_num_freeze_ITI; size(curr_freeze_signal,1)];
                    g1_num_move_ITI = [g1_num_move_ITI; size(curr_move_signal,1)];
                else
                    g2_num_freeze_ITI = [g2_num_freeze_ITI; size(curr_freeze_signal,1)];
                    g2_num_move_ITI = [g2_num_move_ITI; size(curr_move_signal,1)];
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
        mean_g1_freeze_signal = mean(g1_freeze_signal,1);
        mean_g1_move_time = mean(g1_move_time,1);
        mean_g1_move_signal = mean(g1_move_signal,1);

        if length(input.groupNames)==2
            mean_g2_freeze_time = mean(g2_freeze_time,1);
            mean_g2_freeze_signal = mean(g2_freeze_signal,1);
            mean_g2_move_time = mean(g2_move_time,1);
            mean_g2_move_signal = mean(g2_move_signal,1);
        end
       
        g1_freeze_signal_sem_prop = [];
        for col=1:size(g1_freeze_signal_sem,2)
            g1_freeze_signal_sem_prop(1,col) = propagate_error(g1_freeze_signal_sem(:,col));
        end
        
        g1_move_signal_sem_prop = [];
        for col=1:size(g1_move_signal_sem,2)
            g1_move_signal_sem_prop(1,col) = propagate_error(g1_move_signal_sem(:,col));
        end
        
        if length(input.groupNames)==2
            g2_freeze_signal_sem_prop = [];
            for col=1:size(g2_freeze_signal_sem,2)
                g2_freeze_signal_sem_prop(1,col) = propagate_error(g2_freeze_signal_sem(:,col));
            end
            
            g2_move_signal_sem_prop = [];
            for col=1:size(g2_move_signal_sem,2)
                g2_move_signal_sem_prop(1,col) = propagate_error(g2_move_signal_sem(:,col));
            end
        end
        
        % Freezing plot 
        figure; hold on;
        plot(mean_g1_freeze_time, mean_g1_freeze_signal, 'Color', [.0 .3 .0], 'LineWidth', 2.5); hold on;
        errorplot3(mean_g1_freeze_signal-g1_freeze_signal_sem_prop, mean_g1_freeze_signal+g1_freeze_signal_sem_prop, [min(mean_g1_freeze_time) max(mean_g1_freeze_time)], [.0 .3 .0],.15); hold on;
        if length(input.groupNames)==2
            plot(mean_g2_freeze_time, mean_g2_freeze_signal, 'LineWidth', 2.5, 'Color', [0.6350 0.0780 0.1840]); hold on;
            errorplot3(mean_g2_freeze_signal-g2_freeze_signal_sem_prop, mean_g2_freeze_signal+g2_freeze_signal_sem_prop, [min(mean_g2_freeze_time) max(mean_g2_freeze_time)], [0.6350 0.0780 0.1840],.15); hold on;
        end
        plot([0 0], [-3 bCI_y], 'Color', [0.6350 0.0780 0.1840], 'LineStyle', '-'); hold on;
        
        % Bootstrapping for freezing plot
        sig = .05;
        consec_thresh = 3.3;

        g1_freeze_bCIexp_sig = bootstrapping(g1_freeze_signal, sig, consec_thresh, bCI_y);
        plot(mean_g1_freeze_time,g1_freeze_bCIexp_sig,'Color','red','Marker','.');
        text(2,bCI_y+0.1,'\bf bCI','Color','red');

        if length(input.groupNames)==2
            g2_freeze_bCIexp_sig = bootstrapping(g2_freeze_signal, sig, consec_thresh, bCI_y-0.3);
            plot(mean_g2_freeze_time,g2_freeze_bCIexp_sig,'Color','red','Marker','.');
        end
    
        % Permutation test for freezing plot
        if length(input.groupNames)==2
            perm_p_sig_freeze = permutation_test(g1_freeze_signal, g2_freeze_signal, sig, consec_thresh, bCI_y-0.6);       
            plot(mean_g1_freeze_time,perm_p_sig_freeze,'Color',col_rep(1),'Marker','.', 'LineWidth', 1); hold on;
        end

        if input.freeze_move_onset==true
            if event==1
                xlabel(sprintf('Freezing onset (CS %d to %d)', CS_range(1), CS_range(2)));
            else
                xlabel(sprintf('Freezing onset (ITI %d to %d)', CS_range(1), CS_range(2)));
            end
        else
            if event==1
                xlabel(sprintf('Freezing offset (CS %d to %d)', CS_range(1), CS_range(2)));
            else
                xlabel(sprintf('Freezing offset (ITI %d to %d)', CS_range(1), CS_range(2)));
            end
        end

        % AUC for freezing plot (pre vs. post)
        g1_pre_freeze_AUCs = zeros(size(g1_freeze_signal,1),1);
        g1_post_freeze_AUCs = zeros(size(g1_freeze_signal,1),1);

        for row=1:size(g1_freeze_signal,1)
            g1_curr_time = g1_freeze_time(row,:);
            g1_pre_idx = g1_curr_time >= x_range(1) & g1_curr_time < 0;
            g1_post_idx = g1_curr_time >= 0 & g1_curr_time < x_range(2);
            g1_pre_freeze_time = g1_freeze_time(row,g1_pre_idx);
            g1_pre_freeze_signal = g1_freeze_signal(row,g1_pre_idx);
            g1_post_freeze_time = g1_freeze_time(row,g1_post_idx);
            g1_post_freeze_signal = g1_freeze_signal(row,g1_post_idx);

            g1_pre_freeze_AUC = trapz(g1_pre_freeze_time, g1_pre_freeze_signal);
            g1_post_freeze_AUC = trapz(g1_post_freeze_time, g1_post_freeze_signal);

            g1_pre_duration = 0 - x_range(1);
            g1_post_duration = x_range(2);
            g1_pre_post_ratio = max(g1_pre_duration, g1_post_duration) / min(g1_pre_duration, g1_post_duration);

            if g1_pre_duration > g1_post_duration
                g1_pre_freeze_AUC = g1_pre_freeze_AUC / g1_pre_post_ratio;
            elseif g1_post_duration > g1_pre_duration
                g1_post_freeze_AUC = g1_post_freeze_AUC / g1_pre_post_ratio;
            end

            g1_pre_freeze_AUCs(row,:) = g1_pre_freeze_AUC;
            g1_post_freeze_AUCs(row,:) = g1_post_freeze_AUC;
        end

        if event==1
            g1_pre_freeze_AUCs_CS = g1_pre_freeze_AUCs;
            g1_post_freeze_AUCs_CS = g1_post_freeze_AUCs;
        else
            g1_pre_freeze_AUCs_ITI = g1_pre_freeze_AUCs;
            g1_post_freeze_AUCs_ITI = g1_post_freeze_AUCs;
        end

        g1_pre_freeze_AUC_mean = mean(g1_pre_freeze_AUCs);
        g1_post_freeze_AUC_mean = mean(g1_post_freeze_AUCs);
        g1_pre_freeze_AUC_sem = std(g1_pre_freeze_AUCs) / sqrt(numel(g1_pre_freeze_AUCs));
        g1_post_freeze_AUC_sem = std(g1_post_freeze_AUCs) / sqrt(numel(g1_post_freeze_AUCs));

        g1_pre_post_means = [g1_pre_freeze_AUC_mean, g1_post_freeze_AUC_mean];
        g1_pre_post_sems = [g1_pre_freeze_AUC_sem, g1_post_freeze_AUC_sem];

        if length(input.groupNames)==2
            g2_pre_freeze_AUCs = zeros(size(g2_freeze_signal,1),1);
            g2_post_freeze_AUCs = zeros(size(g2_freeze_signal,1),1);
    
            for row=1:size(g2_freeze_signal,1)
                g2_curr_time = g2_freeze_time(row,:);
                g2_pre_idx = g2_curr_time >= x_range(1) & g2_curr_time < 0;
                g2_post_idx = g2_curr_time >= 0 & g2_curr_time < x_range(2);
                g2_pre_freeze_time = g2_freeze_time(row,g2_pre_idx);
                g2_pre_freeze_signal = g2_freeze_signal(row,g2_pre_idx);
                g2_post_freeze_time = g2_freeze_time(row,g2_post_idx);
                g2_post_freeze_signal = g2_freeze_signal(row,g2_post_idx);
    
                g2_pre_freeze_AUC = trapz(g2_pre_freeze_time, g2_pre_freeze_signal);
                g2_post_freeze_AUC = trapz(g2_post_freeze_time, g2_post_freeze_signal);

                g2_pre_duration = 0 - x_range(1);
                g2_post_duration = x_range(2);
                g2_pre_post_ratio = max(g2_pre_duration, g2_post_duration) / min(g2_pre_duration, g2_post_duration);
    
                if g2_pre_duration > g2_post_duration
                    g2_pre_freeze_AUC = g2_pre_freeze_AUC / g2_pre_post_ratio;
                else
                    g2_post_freeze_AUC = g2_post_freeze_AUC / g2_pre_post_ratio;
                end
    
                g2_pre_freeze_AUCs(row,:) = g2_pre_freeze_AUC;
                g2_post_freeze_AUCs(row,:) = g2_post_freeze_AUC;
            end
    
            if event==1
                g2_pre_freeze_AUCs_CS = g2_pre_freeze_AUCs;
                g2_post_freeze_AUCs_CS = g2_post_freeze_AUCs;
            else
                g2_pre_freeze_AUCs_ITI = g2_pre_freeze_AUCs;
                g2_post_freeze_AUCs_ITI = g2_post_freeze_AUCs;
            end

            g2_pre_freeze_AUC_mean = mean(g2_pre_freeze_AUCs);
            g2_post_freeze_AUC_mean = mean(g2_post_freeze_AUCs);
            g2_pre_freeze_AUC_sem = std(g2_pre_freeze_AUCs) / sqrt(numel(g2_pre_freeze_AUCs));
            g2_post_freeze_AUC_sem = std(g2_post_freeze_AUCs) / sqrt(numel(g2_post_freeze_AUCs));
    
            g2_pre_post_means = [g2_pre_freeze_AUC_mean, g2_post_freeze_AUC_mean];
            g2_pre_post_sems = [g2_pre_freeze_AUC_sem, g2_post_freeze_AUC_sem];           
        end

        labels = categorical({'Baseline', 'Freeze'});
        labels = reordercats(labels, {'Baseline', 'Freeze'});
        figure;
        scatter(labels, g1_pre_post_means, 200, 'filled', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [.0 .3 .0]); hold on;
        errorbar(labels, g1_pre_post_means, g1_pre_post_sems, g1_pre_post_sems, 'Color', 'black'); hold on;

        if length(input.groupNames)==2
            scatter(labels, g2_pre_post_means, 200, 'filled', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0.6350 0.0780 0.1840]); hold on;
            errorbar(labels, g2_pre_post_means, g2_pre_post_sems, g2_pre_post_sems, 'Color', 'black'); hold on;
        end

        % Moving plot
    
        figure; hold on;
        plot(mean_g1_move_time, mean_g1_move_signal, 'Color', [.1 .7 .1], 'LineWidth', 2.5); hold on;
        errorplot3(mean_g1_move_signal-g1_move_signal_sem_prop, mean_g1_move_signal+g1_move_signal_sem_prop, [min(mean_g1_move_time) max(mean_g1_move_time)], [.1 .7 .1],.15); hold on;
        if length(input.groupNames)==2
            plot(mean_g2_move_time, mean_g2_move_signal, 'LineWidth', 2.5, 'Color', [1 0 0]); hold on;
            errorplot3(mean_g2_move_signal-g2_move_signal_sem_prop, mean_g2_move_signal+g2_move_signal_sem_prop, [min(mean_g2_move_time) max(mean_g2_move_time)], [1 0 0],.15);
        end
        
        plot([0 0], [-3 bCI_y], 'Color', [0.4660 0.6740 0.1880], 'LineStyle', '-'); hold on;
        
        % Bootstrapping for moving plot
        sig = .05;
        consec_thresh = 3.3;

        g1_move_bCIexp_sig = bootstrapping(g1_move_signal, sig, consec_thresh, bCI_y);
        plot(mean_g1_move_time,g1_move_bCIexp_sig,'Color','red','Marker','.');
        text(2,bCI_y+0.1,'\bf bCI','Color','red');

        if length(input.groupNames)==2
            g2_move_bCIexp_sig = bootstrapping(g2_move_signal, sig, consec_thresh, bCI_y-0.3);
            plot(mean_g2_move_time,g2_move_bCIexp_sig,'Color','red','Marker','.');
        end
    
        % Permutation test for moving plot
        if length(input.groupNames)==2
            perm_p_sig_move = permutation_test(g1_move_signal, g2_move_signal, sig, consec_thresh, bCI_y-0.6);       
            plot(mean_g1_move_time,perm_p_sig_move,'Color',col_rep(1),'Marker','.', 'LineWidth', 1); hold on;
        end

        if input.freeze_move_onset==true
            if event==1
                xlabel(sprintf('Moving onset (CS %d to %d)', CS_range(1), CS_range(2)));
            else
                xlabel(sprintf('Moving onset (ITI %d to %d)', CS_range(1), CS_range(2)));
            end
        else
            if event==1
                xlabel(sprintf('Moving offset (CS %d to %d)', CS_range(1), CS_range(2)));
            else
                xlabel(sprintf('Moving offset (ITI %d to %d)', CS_range(1), CS_range(2)));
            end
        end

        % AUC for moving plot (pre vs. post)
        g1_pre_move_AUCs = zeros(size(g1_move_signal,1),1);
        g1_post_move_AUCs = zeros(size(g1_move_signal,1),1);

        for row=1:size(g1_move_signal,1)
            g1_curr_time = g1_move_time(row,:);
            g1_pre_idx = g1_curr_time >= x_range(1) & g1_curr_time < 0;
            g1_post_idx = g1_curr_time >= 0 & g1_curr_time < x_range(2);
            g1_pre_move_time = g1_move_time(row,g1_pre_idx);
            g1_pre_move_signal = g1_move_signal(row,g1_pre_idx);
            g1_post_move_time = g1_move_time(row,g1_post_idx);
            g1_post_move_signal = g1_move_signal(row,g1_post_idx);

            g1_pre_move_AUC = trapz(g1_pre_move_time, g1_pre_move_signal);
            g1_post_move_AUC = trapz(g1_post_move_time, g1_post_move_signal);

            g1_pre_duration = 0 - x_range(1);
            g1_post_duration = x_range(2);
            g1_pre_post_ratio = max(g1_pre_duration, g1_post_duration) / min(g1_pre_duration, g1_post_duration);

            if g1_pre_duration > g1_post_duration
                g1_pre_move_AUC = g1_pre_move_AUC / g1_pre_post_ratio;
            else
                g1_post_move_AUC = g1_post_move_AUC / g1_pre_post_ratio;
            end

            g1_pre_move_AUCs(row,:) = g1_pre_move_AUC;
            g1_post_move_AUCs(row,:) = g1_post_move_AUC;
        end

        if event==1
            g1_pre_move_AUCs_CS = g1_pre_move_AUCs;
            g1_post_move_AUCs_CS = g1_post_move_AUCs;
        else
            g1_pre_move_AUCs_ITI = g1_pre_move_AUCs;
            g1_post_move_AUCs_ITI = g1_post_move_AUCs;
        end

        g1_pre_move_AUC_mean = mean(g1_pre_move_AUCs);
        g1_post_move_AUC_mean = mean(g1_post_move_AUCs);
        g1_pre_move_AUC_sem = std(g1_pre_move_AUCs) / sqrt(numel(g1_pre_move_AUCs));
        g1_post_move_AUC_sem = std(g1_post_move_AUCs) / sqrt(numel(g1_post_move_AUCs));

        g1_pre_post_means = [g1_pre_move_AUC_mean, g1_post_move_AUC_mean];
        g1_pre_post_sems = [g1_pre_move_AUC_sem, g1_post_move_AUC_sem];

        if length(input.groupNames)==2
            g2_pre_move_AUCs = zeros(size(g2_move_signal,1),1);
            g2_post_move_AUCs = zeros(size(g2_move_signal,1),1);
    
            for row=1:size(g2_move_signal,1)
                g2_curr_time = g2_move_time(row,:);
                g2_pre_idx = g2_curr_time >= x_range(1) & g2_curr_time < 0;
                g2_post_idx = g2_curr_time >= 0 & g2_curr_time < x_range(2);
                g2_pre_move_time = g2_move_time(row,g2_pre_idx);
                g2_pre_move_signal = g2_move_signal(row,g2_pre_idx);
                g2_post_move_time = g2_move_time(row,g2_post_idx);
                g2_post_move_signal = g2_move_signal(row,g2_post_idx);
    
                g2_pre_move_AUC = trapz(g2_pre_move_time, g2_pre_move_signal);
                g2_post_move_AUC = trapz(g2_post_move_time, g2_post_move_signal);

                g2_pre_duration = 0 - x_range(1);
                g2_post_duration = x_range(2);
                g2_pre_post_ratio = max(g2_pre_duration, g2_post_duration) / min(g2_pre_duration, g2_post_duration);
    
                if g2_pre_duration > g2_post_duration
                    g2_pre_move_AUC = g2_pre_move_AUC / g2_pre_post_ratio;
                else
                    g2_post_move_AUC = g2_post_move_AUC / g2_pre_post_ratio;
                end
    
                g2_pre_move_AUCs(row,:) = g2_pre_move_AUC;
                g2_post_move_AUCs(row,:) = g2_post_move_AUC;
            end

            if event==1
                g2_pre_move_AUCs_CS = g2_pre_move_AUCs;
                g2_post_move_AUCs_CS = g2_post_move_AUCs;
            else
                g2_pre_move_AUCs_ITI = g2_pre_move_AUCs;
                g2_post_move_AUCs_ITI = g2_post_move_AUCs;
            end
    
            g2_pre_move_AUC_mean = mean(g2_pre_move_AUCs);
            g2_post_move_AUC_mean = mean(g2_post_move_AUCs);
            g2_pre_move_AUC_sem = std(g2_pre_move_AUCs) / sqrt(numel(g2_pre_move_AUCs));
            g2_post_move_AUC_sem = std(g2_post_move_AUCs) / sqrt(numel(g2_post_move_AUCs));
    
            g2_pre_post_means = [g2_pre_move_AUC_mean, g2_post_move_AUC_mean];
            g2_pre_post_sems = [g2_pre_move_AUC_sem, g2_post_move_AUC_sem];
        end

        labels = categorical({'Baseline', 'Move'});
        labels = reordercats(labels, {'Baseline', 'Move'});
        figure;
        scatter(labels, g1_pre_post_means, 200, 'filled', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [.1 .7 .1]); hold on;
        errorbar(labels, g1_pre_post_means, g1_pre_post_sems, g1_pre_post_sems, 'Color', 'black'); hold on;

        if length(input.groupNames)==2
            scatter(labels, g2_pre_post_means, 200, 'filled', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [1 0 0]); hold on;
            errorbar(labels, g2_pre_post_means, g2_pre_post_sems, g2_pre_post_sems, 'Color', 'black'); hold on;
        end
    end

    % AUC output
    output = 'freeze_move_average_CS_ITI_AUC.xlsx';

    cols_1 = {'Freezing (CS)', '', '', 'Moving (CS)', '', '', 'Freezing (ITI)', '', '', 'Moving (ITI)'};
    cols_2 = {'Num events', sprintf('AUC pre (%d-%d s)',x_range(1),0), sprintf('AUC post (%d-%d s)',0,x_range(2))};
    
    for group=1:length(input.groupNames)
        writematrix("Mouse",output,'Range','A2','Sheet',input.groupNames{group});
        writecell(cols_1,output,'Range','B1','Sheet',input.groupNames{group});
        writecell(repmat(cols_2,1,4),output,'Range','B2','Sheet',input.groupNames{group});

        group_mouse_names = input.animalNames(strcmp(input.groupNames{group},input.groups));
        writecell(group_mouse_names,output,'Range','A3','Sheet',input.groupNames{group});

        if group==1
            writematrix(g1_num_freeze_CS,output,'Range','B3','Sheet',input.groupNames{group});
            writematrix(g1_num_move_CS,output,'Range','E3','Sheet',input.groupNames{group});
            writematrix(g1_num_freeze_ITI,output,'Range','H3','Sheet',input.groupNames{group});
            writematrix(g1_num_move_ITI,output,'Range','K3','Sheet',input.groupNames{group});

            writematrix(g1_pre_freeze_AUCs_CS,output,'Range','C3','Sheet',input.groupNames{group});
            writematrix(g1_pre_move_AUCs_CS,output,'Range','F3','Sheet',input.groupNames{group});
            writematrix(g1_pre_freeze_AUCs_ITI,output,'Range','I3','Sheet',input.groupNames{group});
            writematrix(g1_pre_move_AUCs_ITI,output,'Range','L3','Sheet',input.groupNames{group});

            writematrix(g1_post_freeze_AUCs_CS,output,'Range','D3','Sheet',input.groupNames{group});
            writematrix(g1_post_move_AUCs_CS,output,'Range','G3','Sheet',input.groupNames{group});
            writematrix(g1_post_freeze_AUCs_ITI,output,'Range','J3','Sheet',input.groupNames{group});
            writematrix(g1_post_move_AUCs_ITI,output,'Range','M3','Sheet',input.groupNames{group});
        else
            writematrix(g2_num_freeze_CS,output,'Range','B3','Sheet',input.groupNames{group});
            writematrix(g2_num_move_CS,output,'Range','E3','Sheet',input.groupNames{group});
            writematrix(g2_num_freeze_ITI,output,'Range','H3','Sheet',input.groupNames{group});
            writematrix(g2_num_move_ITI,output,'Range','K3','Sheet',input.groupNames{group});

            writematrix(g2_pre_freeze_AUCs_CS,output,'Range','C3','Sheet',input.groupNames{group});
            writematrix(g2_pre_move_AUCs_CS,output,'Range','F3','Sheet',input.groupNames{group});
            writematrix(g2_pre_freeze_AUCs_ITI,output,'Range','I3','Sheet',input.groupNames{group});
            writematrix(g2_pre_move_AUCs_ITI,output,'Range','L3','Sheet',input.groupNames{group});

            writematrix(g2_post_freeze_AUCs_CS,output,'Range','D3','Sheet',input.groupNames{group});
            writematrix(g2_post_move_AUCs_CS,output,'Range','G3','Sheet',input.groupNames{group});
            writematrix(g2_post_freeze_AUCs_ITI,output,'Range','J3','Sheet',input.groupNames{group});
            writematrix(g2_post_move_AUCs_ITI,output,'Range','M3','Sheet',input.groupNames{group});
        end

        excel = actxserver('Excel.Application');
        workbook = excel.Workbooks.Open(fullfile(pwd, output));

        sheet = workbook.Sheets.Item(input.groupNames{group});
        sheet.Range('B1:D1').Merge;
        sheet.Range('B1:D1').HorizontalAlignment = -4108;
        sheet.Range('E1:G1').Merge;
        sheet.Range('E1:G1').HorizontalAlignment = -4108;
        sheet.Range('H1:J1').Merge;
        sheet.Range('H1:J1').HorizontalAlignment = -4108;
        sheet.Range('K1:M1').Merge;
        sheet.Range('K1:M1').HorizontalAlignment = -4108;
        sheet.Columns.AutoFit();
        
        workbook.Save;
        workbook.Close(false);
        excel.Quit;
        delete(excel);
    end
end