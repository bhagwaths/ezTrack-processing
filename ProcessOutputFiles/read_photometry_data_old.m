% Returns lastTS (end time of recording in s) and firstTTL (end time of baseline in s) from photometry file path

function [data, lastTS, firstTTL] = read_photometry_data_old(blockpath,onOff)

[data, lastTS] = TDTbin2mat(blockpath);

%create epoc for trials
data.epocs.Session.name = 'Session';

if onOff==1
    if data.epocs.TTL_.onset(1) ~= 0
        data.epocs.Session.onset = data.epocs.TTL_.onset(1);
        data.epocs.Session.offset = data.epocs.TTL_.onset(1)+ [20];
    else
        data.epocs.Session.onset = data.epocs.TTL_.onset(2);
        data.epocs.Session.offset = data.epocs.TTL_.onset(2)+ [20];
    end
else
    if data.epocs.TTL_.offset(1) ~= 0
        data.epocs.Session.onset = data.epocs.TTL_.offset(1);
        data.epocs.Session.offset = data.epocs.TTL_.offset(1)+ [20];
    else
        data.epocs.Session.onset = data.epocs.TTL_.offset(2);
        data.epocs.Session.offset = data.epocs.TTL_.offset(2)+ [20];
    end
end

data.epocs.Session.data = [1];

if onOff==1
    if data.epocs.TTL_.onset(1) ~= 0
        firstTTL = data.epocs.TTL_.onset(1);
    else
        firstTTL = data.epocs.TTL_.onset(2);
    end

else
    if data.epocs.TTL_.offset(1) ~= 0
        firstTTL = data.epocs.TTL_.offset(1);
    else
        firstTTL = data.epocs.TTL_.offset(2);
    end
end

end