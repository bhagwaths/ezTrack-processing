function [] = freeze_move_entire_session(input, signal, output_files, idx, time_range, CS_range, bin_size, plot_num, write_output)

    % CS time range, relative to CS onset
    % only affects double line graph (3c) and heat maps (4)
    CS_time_range = [-5 30];

    % CNO shock time range, relative to shock onset
    % only affects double line graph (3c) and heat maps (4)
    CNO_shock_time_range = [-5 29];
   
    % Define CS or shock intervals
    if contains(input.stage, "CNO") && contains(input.stage, "shock")
        CS_first_secs = [];
        if input.FPS == 10
            shock_first_secs = 0:62:248;
        else
            shock_first_secs = 0:60:240;
        end
    elseif ~strcmp(input.stage, "conditioning")
        CS_first_secs = 0:90:2160;
    else
        CS_first_secs = [0 90 210];
    end

    % Number of CS in range
    if ~isempty(CS_range)
        num_CS = (CS_range(2) - CS_range(1) + 1);
    end

    % Assign filename where we want to write output
    if write_output==true
        if plot_num==1
            filename = 'zall_ind_freeze_move.xlsx';
            if exist(filename, 'file')==2
                delete(filename);
            end
        elseif plot_num==2
            filename = 'zall_mean_freeze_move_heat.xlsx';
            if exist(filename, 'file')==2
                delete(filename);
            end
        elseif plot_num==3
            filename = 'zall_mean_freeze_move_line.xlsx';
            if exist(filename, 'file')==2
                delete(filename);
            end
        elseif plot_num==5
            filename = 'freeze_pct_heat_map.xlsx';
            if exist(filename, 'file')==2
                delete(filename);
            end
        end
    end

    % Finds # of animals, total and per group
    numAnimals_total = numel(input.animalNames);
    num_groups = length(input.groupNames);
    for group=1:num_groups
        numAnimals{group} = nnz(strcmp(input.groups, input.groupNames{group}));
        % Changes ":" in group name to "-", because ":" is not allowed as Excel sheet name
        if contains(input.groupNames{group}, ":")
            input.groupNames{group} = replace(input.groupNames{group}, ":", "-");
        end
    end

    zall_combined = cell(1,num_groups);
    ts1_combined = cell(1,num_groups);
    freeze_eps_combined = cell(1,num_groups);
    move_eps_combined = cell(1,num_groups);
    freeze_time_lengths = cell(1,num_groups);
    move_time_lengths = cell(1,num_groups);

    for mouse=1:numAnimals_total
        if strcmp(input.groups{mouse}, input.groupNames{1})
            group = 1;
        else
            group = 2;
        end

        % Find freezing/moving onset/offset from output file for 'mouse'
        Frames = readmatrix(output_files{idx(mouse)}, 'Range', 'A:A', 'NumHeaderLines', 1);
        Freezing = readmatrix(output_files{idx(mouse)}, 'Range', 'B:B', 'NumHeaderLines', 1);
    
        first_s = time_range(1);
        last_s = time_range(1) + time_range(2);
    
        [freeze_onset_times, freeze_offset_times, move_onset_times, move_offset_times] = get_freeze_move_eps(Frames,...
                                             Freezing, input.freeze_threshold, input.move_threshold, input.FPS, first_s, last_s);
        
        if length(freeze_onset_times) ~= length(freeze_offset_times)
            freeze_offset_times = [freeze_offset_times last_s];
        end
        
        if length(move_onset_times) ~= length(move_offset_times)
            move_offset_times = [move_offset_times last_s];
        end

        % Cut time and zall for 'mouse' based on range of interest in FreezeMoveMaster
        ts1_adj = signal{mouse}.ts1(signal{mouse}.ts1 >= first_s & signal{mouse}.ts1 < last_s);
        zall_adj = signal{mouse}.zall(signal{mouse}.ts1 >= first_s & signal{mouse}.ts1 < last_s);

        % 1. Individual z-scored ΔF/F for entire session, with freezing and moving labels.
        if plot_num==1
            if write_output==true
                freeze_move_col = repmat('N', [1, length(ts1_adj)]);
            end
            figure;
            if contains(input.stage, "CNO") && contains(input.stage, "shock")
                a=0;
                for i=1:5
                    patch([a a+2 a+2 a], [-10 -10 50 50], [1 .8 .8], 'EdgeColor','none');
                    if input.FPS == 10
                        a=a+62;
                    else
                        a=a+60;
                    end
                end
            elseif ~strcmp(input.stage, "conditioning")
                a=(CS_range(1) - 1) * 90;
                for ii=1:num_CS
                    patch([a a+30 a+30 a], [- 5 -5 15 15], [.8 1 1], 'EdgeColor','none');
                    a=a+90;
                end
            else
                ITI = [0 90 120];
                if CS_range(1) == 1
                    a = 0;
                elseif CS_range(1) == 2
                    a = 90;
                else
                    a = 210;
                end
                for ii=1:num_CS
                    a=a+ITI(ii);
                    patch([a a+28 a+28 a], [-10 -10 50 50], [.8 1 1], 'EdgeColor','none');
                    patch([a+28 a+30 a+30 a+28], [-10 -10 50 50], [1 .8 .8], 'EdgeColor','none');
                end
            end
            hold on;
            plot(ts1_adj, zall_adj); hold on;
        end
    
        % Create freezing vector
        freeze_eps = NaN(1, length(ts1_adj));
        for i=1:length(freeze_onset_times)
            freeze_start = freeze_onset_times(i);
            freeze_end = freeze_offset_times(i);
            freeze_ep = find(ts1_adj > freeze_start & ts1_adj < freeze_end);
            freeze_eps(freeze_ep) = 3;
            if write_output==true
                freeze_move_col(freeze_ep) = 'F';
            end
        end
    
        % Plot freezing vector
        if plot_num==1
            plot(ts1_adj, freeze_eps, 'LineWidth', 2, 'Color', [0.6350 0.0780 0.1840]); hold on;
        end

        % Create moving vector    
        move_eps = NaN(1, length(ts1_adj));
        for i=1:length(move_onset_times)
            move_start = move_onset_times(i);
            move_end = move_offset_times(i);
            move_ep = find(ts1_adj > move_start & ts1_adj < move_end);
            move_eps(move_ep) = 3;
            if write_output==true
                freeze_move_col(move_ep) = 'M';
            end
        end
        
        % Plot moving vector
        if plot_num==1
            plot(ts1_adj, move_eps, 'LineWidth', 2, 'Color', [0.4660 0.6740 0.1880]);

            if write_output==true
                Header = ["Time (s)" "Z-scored Signal" "Behavior"];
                writematrix(Header, filename, 'Range', 'A1', 'Sheet', input.animalNames{mouse});
                writematrix(ts1_adj', filename, 'Range', 'A2', 'Sheet', input.animalNames{mouse});
                writematrix(zall_adj', filename, 'Range', 'B2', 'Sheet', input.animalNames{mouse});
                writematrix(freeze_move_col', filename, 'Range', 'C2', 'Sheet', input.animalNames{mouse});
            end
        end
    
        % Add individual 'mouse' data as new row in array with combined data
        zall_combined{group} = [zall_combined{group}; zall_adj];
        ts1_combined{group} = [ts1_combined{group}; ts1_adj];
        freeze_eps_combined{group} = [freeze_eps_combined{group}; freeze_eps];
        move_eps_combined{group} = [move_eps_combined{group}; move_eps];
    
        freeze_time_lengths{group} = [freeze_time_lengths{group} (freeze_offset_times - freeze_onset_times)];
        move_time_lengths{group} = [move_time_lengths{group} (move_offset_times - move_onset_times)];
    end

    % We are done going through each 'mouse' ... average time and zall vectors
    for group=1:num_groups
        zall_mean{group} = mean(zall_combined{group},1);
        zall_sem{group} = std(zall_combined{group},[],1) / sqrt(size(zall_combined{group},1));
        ts1_mean{group} = mean(ts1_combined{group},1);
        
        % Calculate freeze_move_score (# of mice freezing - # of mice moving, at each time point)
        freeze_eps_count{group} = [];
        for col=1:size(freeze_eps_combined{group},2)
            freeze_marked_1 = ~isnan(freeze_eps_combined{group}(:,col)); % traverses every time pt... how many mice freezing?
            freeze_eps_count{group} = [freeze_eps_count{group} (nnz(freeze_marked_1))];
        end
        move_eps_count{group} = [];
        for col=1:size(move_eps_combined{group},2)
            move_marked_1 = ~isnan(move_eps_combined{group}(:,col)); % traverses every time pt... how many mice moving?
            move_eps_count{group} = [move_eps_count{group} (nnz(move_marked_1))];
        end
        freeze_move_score{group} = freeze_eps_count{group} - move_eps_count{group};
    end

    % 2. Mean z-scored ΔF/F for entire session, with number of mice freezing and moving.
    % Heat map line represents mice freezing or moving at a given time point, based on freeze_move_score.
    if plot_num==2
        for group=1:num_groups
            figure;
            if contains(input.stage, "CNO") && contains(input.stage, "shock")
                a=0;
                for i=1:5
                    patch([a a+2 a+2 a], [-10 -10 50 50], [1 .8 .8], 'EdgeColor','none');
                    if input.FPS == 10
                        a=a+62;
                    else
                        a=a+60;
                    end
                end
            elseif ~strcmp(input.stage, "conditioning")
                a=(CS_range(1) - 1) * 90;
                for ii=1:num_CS
                    patch([a a+30 a+30 a], [- 5 -5 15 15], [.8 1 1], 'EdgeColor','none');
                    a=a+90;
                end
            else
                ITI = [0 90 120];
                if CS_range(1) == 1
                    a = 0;
                elseif CS_range(1) == 2
                    a = 90;
                else
                    a = 210;
                end
                for ii=1:num_CS
                    a=a+ITI(ii);
                    patch([a a+28 a+28 a], [-10 -10 50 50], [.8 1 1], 'EdgeColor','none');
                    patch([a+28 a+30 a+30 a+28], [-10 -10 50 50], [1 .8 .8], 'EdgeColor','none');
                end
            end
            hold on;
            
            plot(ts1_mean{group}, zall_mean{group}, 'Color', [.0 .4 .0], 'LineWidth', 1); hold on;
            errorplot3(zall_mean{group}-zall_sem{group},zall_mean{group}+zall_sem{group},[first_s last_s],[.0 .4 .0],0.3); hold on;
            
            num_scores = 2*numAnimals{group} + 1;
            possible_scores = -numAnimals{group}:numAnimals{group};
            cmap = colormap(jet(num_scores));
            for i=1:num_scores
                color = NaN(1,length(ts1_adj));
                color_idx = freeze_move_score{group} == possible_scores(i);
                color(color_idx) = 3;
                plot(ts1_mean{group}, color, 'LineWidth', 3, 'Color', cmap(possible_scores(i)+numAnimals{group}+1,:)); hold on;
            end
            
            colorbar;
            clim([-numAnimals{group} numAnimals{group}]);
    
            if write_output==true
                Header = ["Time (s)" "Mean Z-scored Signal" "SEM" "Freezing Score"];
                writematrix(Header, filename, 'Range', 'A1', 'Sheet', input.groupNames{group});
                writematrix(ts1_mean{group}', filename, 'Range', 'A2', 'Sheet', input.groupNames{group});
                writematrix(zall_mean{group}', filename, 'Range', 'B2', 'Sheet', input.groupNames{group});
                writematrix(zall_sem{group}', filename, 'Range', 'C2', 'Sheet', input.groupNames{group});
                writematrix(freeze_move_score{group}', filename, 'Range', 'D2', 'Sheet', input.groupNames{group});
            end
        end
    end

    for group=1:num_groups
        freeze_pct{group} = freeze_eps_count{group} / numAnimals{group};
    end

    % 3. Double line graph, with % mice freezing as a line. 
    % Mean z-scored ΔF/F for entire session, with number of mice freezing and moving.
    if plot_num==3
        zall_peaktimes = cell(1,num_groups);
        freeze_peaktimes = cell(1,num_groups);
        
        for group=1:num_groups
            figure;
            if contains(input.stage, "CNO") && contains(input.stage, "shock")
                a=0;
                for i=1:5
                    patch([a a+2 a+2 a], [-10 -10 50 50], [1 .8 .8], 'EdgeColor','none');
                    if input.FPS == 10
                        a=a+62;
                    else
                        a=a+60;
                    end
                end
            elseif ~strcmp(input.stage, "conditioning")
                a=(CS_range(1) - 1) * 90;
                for ii=1:num_CS
                    patch([a a+30 a+30 a], [- 5 -5 15 15], [.8 1 1], 'EdgeColor','none');
                    a=a+90;
                end
            else
                ITI = [0 90 120];
                if CS_range(1) == 1
                    a = 0;
                elseif CS_range(1) == 2
                    a = 90;
                else
                    a = 210;
                end
                for ii=1:num_CS
                    a=a+ITI(ii);
                    patch([a a+28 a+28 a], [-10 -10 50 50], [.8 1 1], 'EdgeColor','none');
                    patch([a+28 a+30 a+30 a+28], [-10 -10 50 50], [1 .8 .8], 'EdgeColor','none');
                end
            end
            hold on;
            
            yyaxis left;
            plot(ts1_mean{group}, zall_mean{group}, 'Color', [.0 .4 .0], 'LineWidth', 2.5); hold on;
            errorplot3(zall_mean{group}-zall_sem{group},zall_mean{group}+zall_sem{group},[first_s last_s],[.0 .4 .0],0.3); hold on;
            
            yyaxis right;
            plot(ts1_mean{group}, freeze_pct{group}, 'Color', [.5 .65 .5], 'LineWidth', 2.5);
    
            % Peak difference
            if ~isempty(CS_range)
                for i=CS_range(1):CS_range(2)
                    CS_timerange = ts1_mean{group}(ts1_mean{group} > CS_first_secs(i) & ...
                        ts1_mean{group} < CS_first_secs(i)+CS_time_range(2));
                    CS_zall = zall_mean{group}(ts1_mean{group} > CS_first_secs(i) & ...
                        ts1_mean{group} < CS_first_secs(i)+CS_time_range(2));
                    [~,CS_zall_max_idx] = max(CS_zall);
                    zall_peaktime = CS_timerange(CS_zall_max_idx);
                    CS_freeze = freeze_pct{group}(ts1_mean{group} > CS_first_secs(i) & ...
                        ts1_mean{group} < CS_first_secs(i)+CS_time_range(2));
                    [~,CS_freeze_max_idx] = max(CS_freeze);
                    freeze_peaktime = CS_timerange(CS_freeze_max_idx);
                    
                    zall_peaktimes{group} = [zall_peaktimes{group}; zall_peaktime];
                    freeze_peaktimes{group} = [freeze_peaktimes{group}; freeze_peaktime];
                    peak_differences{group} = freeze_peaktimes{group} - zall_peaktimes{group};
                end
            end
    
            if write_output==true
                Header = ["Time (s)" "Mean Z-scored Signal" "SEM" "% Mice Freezing"];
                writematrix(Header, filename, 'Range', 'A1', 'Sheet', sprintf('%s - Mean Signal', input.groupNames{group}));
                writematrix(ts1_mean{group}', filename, 'Range', 'A2', 'Sheet', sprintf('%s - Mean Signal', input.groupNames{group}));
                writematrix(zall_mean{group}', filename, 'Range', 'B2', 'Sheet', sprintf('%s - Mean Signal', input.groupNames{group}));
                writematrix(zall_sem{group}', filename, 'Range', 'C2', 'Sheet', sprintf('%s - Mean Signal', input.groupNames{group}));
                writematrix((freeze_pct{group}*100)', filename, 'Range', 'D2', 'Sheet', sprintf('%s - Mean Signal', input.groupNames{group}));
                if ~isempty(CS_range)
                    Header_2 = ["CS" "Mean Z-scored Signal Peak (s)" "% Mice Freezing Peak (s)" "Time Difference (s)"];
                    writematrix(Header_2, filename, 'Range', 'A1', 'Sheet', sprintf('%s - Peak Differences', input.groupNames{group}));
                    writematrix((CS_range(1):CS_range(2))', filename, 'Range', 'A2', 'Sheet', sprintf('%s - Peak Differences', input.groupNames{group}));
                    writematrix(zall_peaktimes{group}, filename, 'Range', 'B2', 'Sheet', sprintf('%s - Peak Differences', input.groupNames{group}));
                    writematrix(freeze_peaktimes{group}, filename, 'Range', 'C2', 'Sheet', sprintf('%s - Peak Differences', input.groupNames{group}));
                    writematrix(peak_differences{group}, filename, 'Range', 'D2', 'Sheet', sprintf('%s - Peak Differences', input.groupNames{group}));
                end
            end
        end
    end

    if plot_num == 4 || plot_num == 5 || plot_num == 6
        % Find freeze % for each CS in CS_time_range
        if ~isempty(CS_range)
            CS_freeze_pcts = cell(1,num_groups);
            CS_bin_freeze_pcts = cell(1,num_groups);
            CS_bin_freeze_pcts_sem = cell(1,num_groups);
            for group=1:num_groups
                for i=CS_range(1):CS_range(2)
                    curr_CS = freeze_pct{group}(ts1_mean{group} > CS_first_secs(i)+CS_time_range(1) & ts1_mean{group} < CS_first_secs(i)+CS_time_range(2));
                    CS_freeze_pcts{group} = add_adj_vector(CS_freeze_pcts{group},curr_CS);
                end
                % Find freeze % for each CS bin of bin_size
                if plot_num == 4 || plot_num == 6
                    num_bins = floor(num_CS / bin_size);
                    st = 1;
                    for i=1:num_bins
                        lst = st+bin_size-1;
                        CS_bin_freeze_pcts{group}(i,:) = mean(CS_freeze_pcts{group}(st:lst,:),1);
                        CS_bin_freeze_pcts_sem{group}(i,:) = std(CS_freeze_pcts{group}(st:lst,:),[],1) / sqrt(size(CS_freeze_pcts{group}(st:lst,:),1));
                        st = st + bin_size;
                    end
                end
            end
        % Find freeze % for each shock in CNO_shock_time_range
        else
            shock_freeze_pcts = cell(1,num_groups);
            shock_bin_freeze_pcts = cell(1,num_groups);
            shock_bin_freeze_pcts_sem = cell(1,num_groups);
            for group=1:num_groups
                for i=1:numel(shock_first_secs)
                    if shock_first_secs(i)+CNO_shock_time_range(2) > ts1_mean{group}(end)
                        error('Value in CNO_shock_time_range (%d) must be less than or equal to %d.', ...
                            CNO_shock_time_range(2), floor(ts1_mean{group}(end)-shock_first_secs(i)));
                        return;
                    end
                    curr_shock = freeze_pct{group}(ts1_mean{group} > shock_first_secs(i)+CNO_shock_time_range(1) & ...
                        ts1_mean{group} < shock_first_secs(i)+CNO_shock_time_range(2));
                    shock_freeze_pcts{group} = add_adj_vector(shock_freeze_pcts{group},curr_shock);
                end
                % Find freeze % for each shock bin of bin_size
                if plot_num == 4 || plot_num == 6
                    num_bins = floor(numel(shock_first_secs) / bin_size);
                    st = 1;
                    for i=1:num_bins
                        lst = st+bin_size-1;
                        shock_bin_freeze_pcts{group}(i,:) = mean(shock_freeze_pcts{group}(st:lst,:),1);
                        shock_bin_freeze_pcts_sem{group}(i,:) = std(shock_freeze_pcts{group}(st:lst,:),[],1) / sqrt(size(shock_freeze_pcts{group}(st:lst,:),1));
                        st = st + bin_size;
                    end
                end
            end
        end
    end
    
    % 4. Mean z-scored ΔF/F for entire session, with number of mice freezing and moving (double line graph)
    if plot_num==4
        % Find mean signal for each CS in CS_time_range
        if ~isempty(CS_range)
            CS_zall = cell(1,num_groups);
            CS_zall_sem = cell(1,num_groups);
            CS_zall_bins = cell(1,num_groups);
            CS_zall_bins_sem = cell(1,num_groups);
    
            for group=1:num_groups
                for i=CS_range(1):CS_range(2)
                    curr_CS_zall = zall_mean{group}(ts1_mean{group} >= CS_first_secs(i)+CS_time_range(1) & ts1_mean{group} < CS_first_secs(i)+CS_time_range(2));
                    CS_zall{group} = add_adj_vector(CS_zall{group},curr_CS_zall);
                    curr_CS_sem = zall_sem{group}(ts1_mean{group} >= CS_first_secs(i)+CS_time_range(1) & ts1_mean{group} < CS_first_secs(i)+CS_time_range(2));
                    CS_zall_sem{group} = add_adj_vector(CS_zall_sem{group},curr_CS_sem);
                end
    
                % Find mean signal for each CS bin of bin_size. Plot signal and freeze %.
                st = 1;
                time_axis = linspace(CS_time_range(1),CS_time_range(2),length(CS_zall{group}));
                for i=1:num_bins
                    lst = st+bin_size-1;
                    CS_zall_bins{group}(i,:) = mean(CS_zall{group}(st:lst,:),1);
                    for j=1:size(CS_zall{group},2)
                        CS_zall_bins_sem{group}(i,j) = propagate_error(CS_zall_sem{group}(st:lst,j));
                    end
                    figure;
                    yyaxis left;
                    plot(time_axis,CS_zall_bins{group}(i,:), 'Color', [.0 .4 .0], 'LineWidth', 2.5); hold on;
                    errorplot3(CS_zall_bins{group}(i,:) - CS_zall_bins_sem{group}(i,:),...
                        CS_zall_bins{group}(i,:) + CS_zall_bins_sem{group}(i,:),CS_time_range,[.0 .4 .0],0.3);
                    yyaxis right;
                    plot(time_axis,CS_bin_freeze_pcts{group}(i,:), 'Color', [.5 .65 .5], 'LineWidth', 2.5); hold on;
                    errorplot3(CS_bin_freeze_pcts{group}(i,:) - CS_bin_freeze_pcts_sem{group}(i,:),...
                        CS_bin_freeze_pcts{group}(i,:) + CS_bin_freeze_pcts_sem{group}(i,:),CS_time_range,[.5 .65 .5],0.3);
                    title(sprintf("CS %d to CS %d (%s)", st+CS_range(1)-1, lst+CS_range(1)-1, input.groupNames{group}));
                    st = st + bin_size;
                end
            end
        else
        % Find mean signal for each shock in CNO_shock_time_range
            shock_zall = cell(1,num_groups);
            shock_zall_sem = cell(1,num_groups);
            shock_zall_bins = cell(1,num_groups);
            shock_zall_bins_sem = cell(1,num_groups);
    
            for group=1:num_groups
                for i=1:numel(shock_first_secs)
                    if shock_first_secs(i)+CNO_shock_time_range(2) > ts1_mean{group}(end)
                        error('Value in CNO_shock_time_range (%d) must be less than or equal to %d.', ...
                            CNO_shock_time_range(2), floor(ts1_mean{group}(end)-shock_first_secs(i)));
                        return;
                    end
                    curr_shock_zall = zall_mean{group}(ts1_mean{group} >= shock_first_secs(i)+CNO_shock_time_range(1) & ...
                        ts1_mean{group} < shock_first_secs(i)+CNO_shock_time_range(2));
                    shock_zall{group} = add_adj_vector(shock_zall{group},curr_shock_zall);
                    curr_shock_sem = zall_sem{group}(ts1_mean{group} >= shock_first_secs(i)+CNO_shock_time_range(1) & ...
                        ts1_mean{group} < shock_first_secs(i)+CNO_shock_time_range(2));
                    shock_zall_sem{group} = add_adj_vector(shock_zall_sem{group},curr_shock_sem);
                end
    
                % Find mean signal for each shock bin of bin_size. Plot signal and freeze %.
                st = 1;
                time_axis = linspace(CNO_shock_time_range(1),CNO_shock_time_range(2),length(shock_zall{group}));
                for i=1:num_bins
                    lst = st+bin_size-1;
                    shock_zall_bins{group}(i,:) = mean(shock_zall{group}(st:lst,:),1);
                    for j=1:size(shock_zall{group},2)
                        shock_zall_bins_sem{group}(i,j) = propagate_error(shock_zall_sem{group}(st:lst,j));
                    end
                    figure;
                    yyaxis left;
                    plot(time_axis,shock_zall_bins{group}(i,:), 'Color', [.0 .4 .0], 'LineWidth', 2.5); hold on;
                    errorplot3(shock_zall_bins{group}(i,:) - shock_zall_bins_sem{group}(i,:),...
                        shock_zall_bins{group}(i,:) + shock_zall_bins_sem{group}(i,:),CNO_shock_time_range,[.0 .4 .0],0.3);
                    yyaxis right;
                    plot(time_axis,shock_bin_freeze_pcts{group}(i,:), 'Color', [.5 .65 .5], 'LineWidth', 2.5); hold on;
                    errorplot3(shock_bin_freeze_pcts{group}(i,:) - shock_bin_freeze_pcts_sem{group}(i,:),...
                        shock_bin_freeze_pcts{group}(i,:) + shock_bin_freeze_pcts_sem{group}(i,:),CNO_shock_time_range,[.5 .65 .5],0.3);
                    title(sprintf("shock %d to shock %d (%s)", st, lst, input.groupNames{group}));
                    st = st + bin_size;
                end
            end
        end
    end

    % 5. Heat map of freezing for entire session. Each row represents individual CS or shock.
    if plot_num==5
        if ~isempty(CS_range)
            for group=1:num_groups
                figure;
                imagesc(linspace(CS_time_range(1),CS_time_range(2),length(CS_freeze_pcts{group})), 1, CS_freeze_pcts{group});
                colormap('jet');
                colorbar;
                if write_output==true
                    writematrix(CS_freeze_pcts{group}, filename, 'Range', 'A1', 'Sheet', input.groupNames{group});
                end
            end
        else
            for group=1:num_groups
                figure;
                imagesc(linspace(CNO_shock_time_range(1),CNO_shock_time_range(2),length(shock_freeze_pcts{group})), 1, shock_freeze_pcts{group});
                colormap('jet');
                colorbar;
                if write_output==true
                    writematrix(shock_freeze_pcts{group}, filename, 'Range', 'A1', 'Sheet', input.groupNames{group});
                end
            end
        end
    end

    % 6. Heat map of freezing for entire session. Each row represents CS or shock bin of bin_size.
    if plot_num==6
        if ~isempty(CS_range)
            for group=1:num_groups
                figure;
                imagesc(linspace(CS_time_range(1),CS_time_range(2),length(CS_freeze_pcts{group})), 1, CS_bin_freeze_pcts{group});
                colormap('jet');
                colorbar;
            end
        else
            for group=1:num_groups
                figure;
                imagesc(linspace(CNO_shock_time_range(1),CNO_shock_time_range(2),length(shock_freeze_pcts{group})), 1, shock_bin_freeze_pcts{group});
                colormap('jet');
                colorbar;
            end
        end
    end

    % 7. Histograms of length of freezing and moving episodes. Freezing episode lengths (in seconds).
    if plot_num==7
        for group=1:num_groups
            [counts_freeze, edges] = histcounts(freeze_time_lengths{group}, 'BinEdges', 0:40);
            adj_counts_freeze = counts_freeze / numAnimals{group};
            
            figure;
            h = bar(edges(1:end-1), adj_counts_freeze, 'hist');
            h.FaceColor = [.0 .3 .0];
        end
    end

    % 8. Histograms of length of freezing and moving episodes. Moving episode lengths (in seconds).
    if plot_num==8
        for group=1:num_groups
            [counts_move, edges] = histcounts(move_time_lengths{group}, 'BinEdges', 0:40);
            adj_counts_move = counts_move / numAnimals{group};
            
            figure;
            h = bar(edges(1:end-1), adj_counts_move, 'hist');
            h.FaceColor = [.1 .7 .1];
        end
    end
end