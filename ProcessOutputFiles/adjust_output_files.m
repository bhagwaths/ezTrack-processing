function [frames_adj, freezing_adj] = adjust_output_files(input)

    numAnimals=numel(input.animalNames);
    
    for i=1:length(input.stages)
        if contains(input.stages{i}, "CNO") && contains(input.stages{i}, "shock")
            last_sec = 300;
        elseif contains(input.stages{i}, "discrimination")
            last_sec = 1315;
        elseif contains(input.stages{i}, "conditioning")
            last_sec = 300;
        elseif contains(input.stages{i}, "extinction") && ~contains(input.stages{i}, "retrieval")
            if input.ITI_s == 5 || input.ITI_s == 30
                last_sec = (input.ITI_s + input.CS_s) * 50;
            else
                last_sec = (input.ITI_s + input.CS_s) * 25;
            end
        elseif contains(input.stages{i}, "retrieval") || contains(input.stages{i}, "renewal") || ...
            contains(input.stages{i}, "habituation")
            last_sec = (input.ITI_s + input.CS_s) * 5;
        end
    
        output_file_folder = strcat(input.group_folder, '\', convertStringsToChars(input.stages{i}), '\FreezingOutput');
        [idx, output_files] = read_output_files(input.animalNames, numAnimals, output_file_folder, '_FreezingOutput.csv');
    
        if input.constant_frames==false
            FPSs = [];
            lastTSs = [];
            firstTTLs = [];
    
            for j=1:numAnimals
                animalName=input.animalNames{j};
                blockpath=input.blockpaths{i}{j};
                onOff=input.TTLonOff{i}(j);
                [~, lastTS, firstTTL_raw] = read_photometry_data_old(blockpath,onOff);
                
                % import Frames and Freezing from Eztrack output file
                frames{j} = readmatrix(output_files{idx(j)}, 'Range', 'E:E', 'NumHeaderLines', 1);
                freezing{j} = readmatrix(output_files{idx(j)}, 'Range', 'G:G', 'NumHeaderLines', 1);
        
                % FPS = (frames in video from light to end) / (seconds in photometry data from TTL to end)
                output_frames = numel(frames{j})-input.baseline_frames;
                lastTSs = [lastTSs lastTS];
                firstTTLs = [firstTTLs firstTTL_raw];
                FPS = output_frames / (lastTS-firstTTL_raw);
                FPSs = [FPSs FPS];
            end

            % first TTL in output file occurs at end of baseline (baseline_frames)
            firstTTL = input.baseline_frames;
        
            for j=1:numAnimals
                % cut frames and freezing values... 180 s baseline, up to 'last_sec' s after first TTL
                cut_frames{j} = frames{j}(frames{j} >= (firstTTL - 180*FPSs(j)) & frames{j} <= (firstTTL + last_sec*FPSs(j)));
                cut_freezing{i}{j} = freezing{j}(frames{j} >= (firstTTL - 180*FPSs(j)) & frames{j} <= (firstTTL + last_sec*FPSs(j)));
                
                % make frames relative to first TTL
                adj_cut_frames{j} = cut_frames{j} - firstTTL;
            
                % convert frames to seconds... same time range for all mice
                adj_cut_s{j} = adj_cut_frames{j} / FPSs(j);
            end
            
            % find mouse with fewest # of rows in output file, after cutting... lowest FPS
            [~, minidx] = min(cellfun('size', adj_cut_s, 1));
    
            % downsample cut time and freezing values to the size of smallest output file
            for j=1:numAnimals
               size_cut = size(adj_cut_s{j}, 1);
               size_freeze = size(cut_freezing{i}{j},1);
               time_ds{j} = interp1(1:size_cut, adj_cut_s{j}, linspace(1,size_cut,length(adj_cut_s{minidx})))';
               freezing_ds{i}{j} = interp1(1:size_freeze, cut_freezing{i}{j}, linspace(1,size_freeze,length(cut_freezing{i}{minidx})))';
            end
    
            for j=1:numAnimals
                for k=1:length(freezing_ds{i}{j})
                    if freezing_ds{i}{j}(k) ~= 0 && freezing_ds{i}{j}(k) ~= 100
                        if freezing_ds{i}{j}(k) < 50
                            freezing_ds{i}{j}(k) = 0;
                        else
                            freezing_ds{i}{j}(k) = 100;
                        end
                    end
                end
            end
    
            % convert seconds back to frames... now has same FPS for all mice (lowest FPS used)
            for j=1:numAnimals
                frames_ds{i}{j} = time_ds{j} * input.adjusted_FPS;
            end

            frames_adj = frames_ds;
            freezing_adj = freezing_ds;

        elseif input.constant_frames == true

            firstTTL = 180 * input.constant_FPS;
            % import Frames and Freezing from Eztrack output file
            for j=1:numAnimals
                frames{j} = readmatrix(output_files{idx(j)}, 'Range', 'E:E', 'NumHeaderLines', 1);
                freezing{j} = readmatrix(output_files{idx(j)}, 'Range', 'G:G', 'NumHeaderLines', 1);
        
                % cut frames and freezing values... 180 s baseline, up to 'last_sec' s after first TTL
                cut_frames{j} = frames{j}(frames{j} >= 0 & frames{j} <= (firstTTL + last_sec*input.constant_FPS));
                cut_freezing{i}{j} = freezing{j}(frames{j} >= 0 & frames{j} <= (firstTTL + last_sec*input.constant_FPS));
                
                % make frames relative to first TTL
                adj_cut_frames{i}{j} = cut_frames{j} - firstTTL;
            
                % convert frames to seconds... same time range for all mice
                adj_cut_s{i}{j} = adj_cut_frames{i}{j} / input.constant_FPS;
            end 
    
            frames_adj = adj_cut_frames;
            freezing_adj = cut_freezing;
        end
    end
end