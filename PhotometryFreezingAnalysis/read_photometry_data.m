% Returns lastTS (end time of recording in s) and firstTTL (end time of baseline in s) from photometry file path

function [signal] = read_photometry_data(input)

    if contains(input.stage, "CNO") && contains(input.stage, "shock")
        TRANGE = [-180 450];
    elseif strcmp(input.stage, "conditioning")
        TRANGE = [-180 480];
    elseif strcmp(input.stage, "extinction_1") || strcmp(input.stage, "extinction_2")
        TRANGE = [-180 2430];
    else
        TRANGE = [-180 630];
    end

    BASELINE_PER = [-180 -1];

    for i=1:numel(input.blockpaths)
        [data{i}, signal{i}.lastTS] = TDTbin2mat(input.blockpaths{i});
        
        %create epoc for trials
        data{i}.epocs.Session.name = 'Session';
        
        if input.TTLonOff(i)==1
            if data{i}.epocs.TTL_.onset(1) ~= 0
                if contains(input.stage, "CNO") && contains(input.stage, "shock") && input.FPS == 10
                    data{i}.epocs.Session.onset = data{i}.epocs.TTL_.onset(2);
                    data{i}.epocs.Session.offset = data{i}.epocs.TTL_.onset(2)+ [20];
                else
                    data{i}.epocs.Session.onset = data{i}.epocs.TTL_.onset(1);
                    data{i}.epocs.Session.offset = data{i}.epocs.TTL_.onset(1)+ [20];
                end
            else
                data{i}.epocs.Session.onset = data{i}.epocs.TTL_.onset(2);
                data{i}.epocs.Session.offset = data{i}.epocs.TTL_.onset(2)+ [20];
            end
        else
            if data{i}.epocs.TTL_.offset(1) ~= 0
                data{i}.epocs.Session.onset = data{i}.epocs.TTL_.offset(1);
                data{i}.epocs.Session.offset = data{i}.epocs.TTL_.offset(1)+ [20];
            else
                data{i}.epocs.Session.onset = data{i}.epocs.TTL_.offset(2);
                data{i}.epocs.Session.offset = data{i}.epocs.TTL_.offset(2)+ [20];
            end
        end
        
        data{i}.epocs.Session.data = [1];
        
        if input.TTLonOff(i)==1
            if data{i}.epocs.TTL_.onset(1) ~= 0
                if contains(input.stage, "CNO") && contains(input.stage, "shock") && input.FPS == 10
                    signal{i}.firstTTL = data{i}.epocs.TTL_.onset(2);
                else
                    signal{i}.firstTTL = data{i}.epocs.TTL_.onset(1);
                end
            else
                signal{i}.firstTTL = data{i}.epocs.TTL_.onset(2);
            end
        
        else
            if data{i}.epocs.TTL_.offset(1) ~= 0
                signal{i}.firstTTL = data{i}.epocs.TTL_.offset(1);
            else
                signal{i}.firstTTL = data{i}.epocs.TTL_.offset(2);
            end
        end

        if input.streams(i)==12
            STREAM_STORE1 = input.streams_12{1}; % 405 channel
            STREAM_STORE2 = input.streams_12{2}; % 465 channel
        else
            STREAM_STORE1 = input.streams_34{1}; % 405 channel
            STREAM_STORE2 = input.streams_34{2}; % 465 channel
        end
        STREAM_STORE3 = 'aFi1r';
        EPOC = 'Session';
        STREAM_STORES = {STREAM_STORE1, STREAM_STORE2, STREAM_STORE3};

        data{i} = TDTfilter(data{i},EPOC,'TIME',TRANGE);
        remove_artifacts(data{i}.streams, input.ARTIFACT, STREAM_STORES);
        [signal{i}.zall, signal{i}.zerror, signal{i}.ts1, signal{i}.Y_dF_all] = process_signal(data{i}.streams, STREAM_STORES, TRANGE, BASELINE_PER, input.N);
    end
end