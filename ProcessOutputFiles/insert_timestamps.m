function [] = insert_timestamps(input, frames, freezing)

    numAnimals=numel(input.animalNames);
    
    filenames = [];
    for i=1:length(input.stages)
        for j=1:numAnimals
            filename = strcat(convertCharsToStrings(input.group_folder),'\',convertCharsToStrings(input.stages{i}),...
                '\FreezingOutput_processed\',convertCharsToStrings(input.animalNames{j}), '_FreezingOutput_processed.csv');
            filenames{i}{j} = filename;
        end
    end

    if input.constant_frames==true
        new_FPS = input.constant_FPS;
    else
        new_FPS = input.adjusted_FPS;
    end

    timestamps = cell(1,length(input.stages));
    for i=1:length(input.stages)
        % Pre-allocate timestamps vector
        for j=1:numAnimals
            timestamps{i}{j} = zeros(length(frames{i}{j}),1);
        end

        % Assign CS_first_secs based on stage
        if contains(input.stages{i}, "CNO") && contains(input.stages{i}, "shock")
            CS_first_secs = [];
        elseif contains(input.stages{i}, "discrimination")
            CS_first_secs = [0 90 210 360 480 570 720 870 990 1140];
        elseif contains(input.stages{i}, "conditioning")
            CS_first_secs = [0 90 210];
        else
            trial_s = input.CS_s + input.ITI_s;
            if contains(input.stages{i}, "extinction") && ~contains(input.stages{i}, "retrieval")
                if input.ITI_s == 5 || input.ITI_s == 30
                    num_trials = 50;
                else
                    num_trials = 25;
                end
                CS_first_secs = 0:trial_s:(num_trials*trial_s - 1);
            elseif contains(input.stages{i}, "retrieval") || contains(input.stages{i}, "renewal") ||...
                    contains(input.stages{i}, "habituation")
                num_trials = 5;
                CS_first_secs = 0:trial_s:(num_trials*trial_s - 1);
            end
        end

        % Mark CS onset in timestamps vector
        for j=1:numAnimals
            if contains(input.stages{i}, "discrimination")
                for k=1:length(CS_first_secs)
                    [~,idx] = min(abs(frames{i}{j}-CS_first_secs(k)*new_FPS));
                    if mod(k,2)==1
                        timestamps{i}{j}(idx,1) = 1; % CS+
                    else
                        timestamps{i}{j}(idx,1) = 2; % CS-
                    end
                end
            else
                for k=1:length(CS_first_secs)
                    [~,idx] = min(abs(frames{i}{j}-CS_first_secs(k)*new_FPS));
                    timestamps{i}{j}(idx,1) = 1;
                end
            end
        end
    end

    for i=1:length(input.stages)
        for j=1:numAnimals
            output_cols{i}{j} = array2table([frames{i}{j} freezing{i}{j} timestamps{i}{j}],'VariableNames',{'Frames', 'Freezing', 'Timestamps'});
        end
        
        for j=1:numAnimals
            writetable(output_cols{i}{j},filenames{i}{j});
        end
    end
end