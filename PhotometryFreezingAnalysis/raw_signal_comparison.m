% RAW_SIGNAL_COMPARISON
% * Reads processed ezTrack output files and photometry data.
% * Calculates average Y_dF_all (not z-scored) signal for these time periods:
%   * Entire time_range (total, freezing, moving)
%   * CS in time_range (total, freezing, moving)
%   * ITI in time_range (total, freezing, moving)

function [] = raw_signal_comparison(input, signal, output_files, idx, time_range, CS_range, write_output)

    num_groups = length(input.groupNames);

    mean_dF_total = cell(1,num_groups); sem_dF_total = cell(1,num_groups);
    mean_dF_total_CS = cell(1,num_groups); sem_dF_total_CS = cell(1,num_groups);
    mean_dF_total_ITI = cell(1,num_groups); sem_dF_total_ITI = cell(1,num_groups);

    mean_dF_freeze = cell(1,num_groups); sem_dF_freeze = cell(1,num_groups);
    mean_dF_freeze_CS = cell(1,num_groups); sem_dF_freeze_CS = cell(1,num_groups);
    mean_dF_freeze_ITI = cell(1,num_groups); sem_dF_freeze_ITI = cell(1,num_groups);

    mean_dF_move = cell(1,num_groups); sem_dF_move = cell(1,num_groups);
    mean_dF_move_CS = cell(1,num_groups); sem_dF_move_CS = cell(1,num_groups);
    mean_dF_move_ITI = cell(1,num_groups); sem_dF_move_ITI = cell(1,num_groups);
    
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

    numAnimals = numel(input.animalNames);
    first_s = time_range(1);
    last_s = time_range(1) + time_range(2);

    for mouse=1:numAnimals
        if strcmp(input.groups{mouse}, input.groupNames{1})
            group = 1;
        else
            group = 2;
        end

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

        % all time / all behavior
        ts1_adj = signal{mouse}.ts1(signal{mouse}.ts1 >= first_s & signal{mouse}.ts1 < last_s);
        Y_dF_all_adj = signal{mouse}.Y_dF_all(signal{mouse}.ts1 >= first_s & signal{mouse}.ts1 < last_s);
        mean_dF_total{group} = [mean_dF_total{group} mean(Y_dF_all_adj)];
        sem_dF_total{group} = [sem_dF_total{group} std(Y_dF_all_adj)/sqrt(size(Y_dF_all_adj,1))];
        
        % CS only / all behavior
        Y_dF_all_CS = [];
        for i=CS_range(1):CS_range(2)
            Y_dF_all_CS = [Y_dF_all_CS Y_dF_all_adj(ts1_adj >= CS_first_secs(i) & ts1_adj < CS_last_secs(i))];
        end
        mean_dF_total_CS{group} = [mean_dF_total_CS{group} mean(Y_dF_all_CS)];
        sem_dF_total_CS{group} = [sem_dF_total_CS{group} std(Y_dF_all_CS)/sqrt(size(Y_dF_all_CS,1))];
    
        % ITI only / all behavior
        Y_dF_all_ITI = [];
        for i=CS_range(1):CS_range(2)
            Y_dF_all_ITI = [Y_dF_all_ITI Y_dF_all_adj(ts1_adj >= ITI_first_secs(i) & ts1_adj < ITI_last_secs(i))];
        end
        mean_dF_total_ITI{group} = [mean_dF_total_ITI{group} mean(Y_dF_all_ITI)];
        sem_dF_total_ITI{group} = [sem_dF_total_ITI{group} std(Y_dF_all_ITI)/sqrt(size(Y_dF_all_ITI,1))];
    
        % all time / freezing only
        ts1_freeze = [];
        Y_dF_all_freeze = [];
        for i=1:length(freeze_onset_times)
            ts1_freeze = [ts1_freeze ts1_adj(ts1_adj >= freeze_onset_times(i) & ts1_adj < freeze_offset_times(i))];
            Y_dF_all_freeze = [Y_dF_all_freeze Y_dF_all_adj(ts1_adj >= freeze_onset_times(i) & ts1_adj < freeze_offset_times(i))];
        end
        if ~isempty(Y_dF_all_freeze)
            mean_dF_freeze{group} = [mean_dF_freeze{group} mean(Y_dF_all_freeze)];
            sem_dF_freeze{group} = [sem_dF_freeze{group} std(Y_dF_all_freeze)/sqrt(size(Y_dF_all_freeze,1))];
        end
    
        % CS only / freezing only
        Y_dF_all_freeze_CS = [];
        for i=CS_range(1):CS_range(2)
            Y_dF_all_freeze_CS = [Y_dF_all_freeze_CS Y_dF_all_freeze(ts1_freeze >= CS_first_secs(i) & ts1_freeze < CS_last_secs(i))];
        end
        if ~isempty(Y_dF_all_freeze_CS)
            mean_dF_freeze_CS{group} = [mean_dF_freeze_CS{group} mean(Y_dF_all_freeze_CS)];
            sem_dF_freeze_CS{group} = [sem_dF_freeze_CS{group} std(Y_dF_all_freeze_CS)/sqrt(size(Y_dF_all_freeze_CS,1))];
        end
    
        % ITI only / freezing only
        Y_dF_all_freeze_ITI = [];
        for i=CS_range(1):CS_range(2)
            Y_dF_all_freeze_ITI = [Y_dF_all_freeze_ITI Y_dF_all_freeze(ts1_freeze >= ITI_first_secs(i) & ts1_freeze < ITI_last_secs(i))];
        end
        if ~isempty(Y_dF_all_freeze_ITI)
            mean_dF_freeze_ITI{group} = [mean_dF_freeze_ITI{group} mean(Y_dF_all_freeze_ITI)];
            sem_dF_freeze_ITI{group} = [sem_dF_freeze_ITI{group} std(Y_dF_all_freeze_ITI)/sqrt(size(Y_dF_all_freeze_ITI,1))];
        end
    
        % all time / moving only
        ts1_move = [];
        Y_dF_all_move = [];
        for i=1:length(move_onset_times)
            ts1_move = [ts1_move ts1_adj(ts1_adj >= move_onset_times(i) & ts1_adj < move_offset_times(i))];
            Y_dF_all_move = [Y_dF_all_move Y_dF_all_adj(ts1_adj >= move_onset_times(i) & ts1_adj < move_offset_times(i))];
        end
        if ~isempty(Y_dF_all_move)
            mean_dF_move{group} = [mean_dF_move{group} mean(Y_dF_all_move)]; % mean_dF_move: avg signal in all moving episodes (each mouse)
            sem_dF_move{group} = [sem_dF_move{group} std(Y_dF_all_move)/sqrt(size(Y_dF_all_move,1))];
        end
    
        % CS only / moving only
        Y_dF_all_move_CS = [];
        for i=CS_range(1):CS_range(2)
            Y_dF_all_move_CS = [Y_dF_all_move_CS Y_dF_all_move(ts1_move >= CS_first_secs(i) & ts1_move < CS_last_secs(i))];
        end
        if ~isempty(Y_dF_all_move_CS)
            mean_dF_move_CS{group} = [mean_dF_move_CS{group} mean(Y_dF_all_move_CS)];
            sem_dF_move_CS{group} = [sem_dF_move_CS{group} std(Y_dF_all_move_CS)/sqrt(size(Y_dF_all_move_CS,1))];
        end
    
        % ITI only / moving only
        Y_dF_all_move_ITI = [];
        for i=CS_range(1):CS_range(2)
            Y_dF_all_move_ITI = [Y_dF_all_move_ITI Y_dF_all_move(ts1_move >= ITI_first_secs(i) & ts1_move < ITI_last_secs(i))];
        end
        if ~isempty(Y_dF_all_move_ITI)
            mean_dF_move_ITI{group} = [mean_dF_move_ITI{group} mean(Y_dF_all_move_ITI)];
            sem_dF_move_ITI{group} = [sem_dF_move_ITI{group} std(Y_dF_all_move_ITI)/sqrt(size(Y_dF_all_move_ITI,1))];
        end
    end

    % Means
    
    for group=1:num_groups
        mean_dF_total_combined{group} = mean(mean_dF_total{group});
        mean_dF_total_CS_combined{group} = mean(mean_dF_total_CS{group});
        mean_dF_total_ITI_combined{group} = mean(mean_dF_total_ITI{group});
        
        mean_dF_freeze_combined{group} = mean(mean_dF_freeze{group});
        mean_dF_freeze_CS_combined{group} = mean(mean_dF_freeze_CS{group});
        mean_dF_freeze_ITI_combined{group} = mean(mean_dF_freeze_ITI{group});
        
        mean_dF_move_combined{group} = mean(mean_dF_move{group});
        mean_dF_move_CS_combined{group} = mean(mean_dF_move_CS{group});
        mean_dF_move_ITI_combined{group} = mean(mean_dF_move_ITI{group});
        
        % Standard errors
    
        sem_dF_total_combined{group} = propagate_error(sem_dF_total{group});
        sem_dF_total_CS_combined{group} = propagate_error(sem_dF_total_CS{group});
        sem_dF_total_ITI_combined{group} = propagate_error(sem_dF_total_ITI{group});
        
        sem_dF_freeze_combined{group} = propagate_error(sem_dF_freeze{group});
        sem_dF_freeze_CS_combined{group} = propagate_error(sem_dF_freeze_CS{group});
        sem_dF_freeze_ITI_combined{group} = propagate_error(sem_dF_freeze_ITI{group});
        
        sem_dF_move_combined{group} = propagate_error(sem_dF_move{group});
        sem_dF_move_CS_combined{group} = propagate_error(sem_dF_move_CS{group});
        sem_dF_move_ITI_combined{group} = propagate_error(sem_dF_move_ITI{group});
    
        % Plot
        
        mean_Total = [mean_dF_total_combined{group} mean_dF_total_CS_combined{group} mean_dF_total_ITI_combined{group}];
        mean_Freeze = [mean_dF_freeze_combined{group} mean_dF_freeze_CS_combined{group} mean_dF_freeze_ITI_combined{group}];
        mean_Move = [mean_dF_move_combined{group} mean_dF_move_CS_combined{group} mean_dF_move_ITI_combined{group}];
    
        sem_Total = [sem_dF_total_combined{group} sem_dF_total_CS_combined{group} sem_dF_total_ITI_combined{group}];
        sem_Freeze = [sem_dF_freeze_combined{group} sem_dF_freeze_CS_combined{group} sem_dF_freeze_ITI_combined{group}];
        sem_Move = [sem_dF_move_combined{group} sem_dF_move_CS_combined{group} sem_dF_move_ITI_combined{group}];
        
        Total = categorical({'total','CS','ITI'});
        Total = reordercats(Total, {'total','CS','ITI'});
        figure;
        scatter(Total, mean_Total, 200, 'filled', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', 'white'); hold on;
        errorbar(Total, mean_Total, sem_Total, sem_Total, 'Color', 'black'); hold on;
        scatter(Total, mean_Freeze, 200, 'filled', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [.0 .3 .0]); hold on;
        errorbar(Total, mean_Freeze, sem_Freeze, sem_Freeze, 'Color', 'black'); hold on;
        scatter(Total, mean_Move, 200, 'filled', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [.1 .7 .1]); hold on;
        errorbar(Total, mean_Move, sem_Move, sem_Move, 'Color', 'black');
    end
    
    % Export values to Excel
    
    if write_output==true
        filename = 'raw_signal_comparison.xlsx';
        if exist(filename, 'file')==2
          delete(filename);
        end
        for group=1:num_groups
            sheetname = input.groupNames{group};
        
            Header = ["Session (Total) Mean" "Session (Total) SEM" "CS (Total) Mean" "CS (Total) SEM" "ITI (Total) Mean" "ITI (Total) SEM"...
                      "Session (Freezing) Mean" "Session (Freezing) SEM" "CS (Freezing) Mean" "CS (Freezing) SEM" "ITI (Freezing) Mean" "ITI (Freezing) SEM"...
                      "Session (Moving) Mean" "Session (Moving) SEM" "CS (Moving) Mean" "CS (Moving) SEM" "ITI (Moving) Mean" "ITI (Moving) SEM"];
        
            Average = {'Average', mean_dF_total_combined{group}, [], mean_dF_total_CS_combined{group}, [], mean_dF_total_ITI_combined{group}, [],...
                                  mean_dF_freeze_combined{group}, [], mean_dF_freeze_CS_combined{group}, [], mean_dF_freeze_ITI_combined{group}, [],...
                                  mean_dF_move_combined{group}, [], mean_dF_move_CS_combined{group}, [], mean_dF_move_ITI_combined{group}, [] };
            
            SEM = {'SEM (propagated)', sem_dF_total_combined{group}, [], sem_dF_total_CS_combined{group}, [], sem_dF_total_ITI_combined{group}, [],...
                          sem_dF_freeze_combined{group}, [], sem_dF_freeze_CS_combined{group}, [], sem_dF_freeze_ITI_combined{group}, [],...
                          sem_dF_move_combined{group}, [], sem_dF_move_CS_combined{group}, [], sem_dF_move_ITI_combined{group}, [] };
            
            writematrix(Header, filename, 'Range', 'B1', 'Sheet', sheetname);
            writecell(input.animalNames(strcmp(input.groups, input.groupNames{group})), filename, 'Range', 'A2', 'Sheet', sheetname);
            
            writematrix(mean_dF_total{group}', filename, 'Range', 'B2', 'Sheet', sheetname); writematrix(sem_dF_total{group}', filename, 'Range', 'C2', 'Sheet', sheetname);
            writematrix(mean_dF_total_CS{group}', filename, 'Range', 'D2', 'Sheet', sheetname); writematrix(sem_dF_total_CS{group}', filename, 'Range', 'E2', 'Sheet', sheetname);
            writematrix(mean_dF_total_ITI{group}', filename, 'Range', 'F2', 'Sheet', sheetname); writematrix(sem_dF_total_ITI{group}', filename, 'Range', 'G2', 'Sheet', sheetname);
            
            writematrix(mean_dF_freeze{group}', filename, 'Range', 'H2', 'Sheet', sheetname); writematrix(sem_dF_freeze{group}', filename, 'Range', 'I2', 'Sheet', sheetname);
            writematrix(mean_dF_freeze_CS{group}', filename, 'Range', 'J2', 'Sheet', sheetname); writematrix(sem_dF_freeze_CS{group}', filename, 'Range', 'K2', 'Sheet', sheetname);
            writematrix(mean_dF_freeze_ITI{group}', filename, 'Range', 'L2', 'Sheet', sheetname); writematrix(sem_dF_freeze_ITI{group}', filename, 'Range', 'M2', 'Sheet', sheetname);
            
            writematrix(mean_dF_move{group}', filename, 'Range', 'N2', 'Sheet', sheetname); writematrix(sem_dF_move{group}', filename, 'Range', 'O2', 'Sheet', sheetname);
            writematrix(mean_dF_move_CS{group}', filename, 'Range', 'P2', 'Sheet', sheetname); writematrix(sem_dF_move_CS{group}', filename, 'Range', 'Q2', 'Sheet', sheetname);
            writematrix(mean_dF_move_ITI{group}', filename, 'Range', 'R2', 'Sheet', sheetname); writematrix(sem_dF_move_ITI{group}', filename, 'Range', 'S2', 'Sheet', sheetname);
        
            writecell(Average, filename, 'Sheet', sheetname, 'WriteMode', 'append');
            writecell(SEM, filename, 'Sheet', sheetname, 'WriteMode', 'append');
        end
    end
end