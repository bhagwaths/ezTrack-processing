function [zall, zerror, ts1, Y_dF_all] = process_signal(streams, STREAM_STORES, TRANGE, BASELINE, N)
    % Applying a time filter to a uniformly sampled signal means that the
    % length of each segment could vary by one sample.  Let's find the minimum
    % length so we can trim the excess off before calculating the mean.
    minLength1 = min(cellfun('prodofsize', streams.(STREAM_STORES{1}).filtered));
    minLength2 = min(cellfun('prodofsize', streams.(STREAM_STORES{2}).filtered));
    minLength3 = min(cellfun('prodofsize', streams.(STREAM_STORES{3}).filtered));
    streams.(STREAM_STORES{1}).filtered = cellfun(@(x) x(1:minLength1), streams.(STREAM_STORES{1}).filtered, 'UniformOutput',false);
    streams.(STREAM_STORES{2}).filtered = cellfun(@(x) x(1:minLength2), streams.(STREAM_STORES{2}).filtered, 'UniformOutput',false);
    streams.(STREAM_STORES{3}).filtered = cellfun(@(x) x(1:minLength3), streams.(STREAM_STORES{3}).filtered, 'UniformOutput',false);
    
    allSignals = cell2mat(streams.(STREAM_STORES{1}).filtered');
    
    % downsample 10x and average 405 signal
    F405 = zeros(size(allSignals(:,1:N:end-N+1)));
    for ii = 1:size(allSignals,1)
        F405(ii,:) = arrayfun(@(i) mean(allSignals(ii,i:i+N-1)),1:N:length(allSignals)-N+1);
    end
    minLength1 = size(F405,2);
    
    % Create mean signal, standard error of signal, and DC offset of 405 signal
    meanSignal1 = mean(F405,1);
    stdSignal1 = std(double(F405))/sqrt(size(F405,1));
    dcSignal1 = mean(meanSignal1);
    
    % downsample 10x and average 465 signal
    allSignals = cell2mat(streams.(STREAM_STORES{2}).filtered');
    F465 = zeros(size(allSignals(:,1:N:end-N+1)));
    for ii = 1:size(allSignals,1)
        F465(ii,:) = arrayfun(@(i) mean(allSignals(ii,i:i+N-1)),1:N:length(allSignals)-N+1);
    end
    minLength2 = size(F465,2);
    
    % Create mean signal, standard error of signal, and DC offset of 465 signal
    meanSignal2 = mean(F465,1);
    stdSignal2 = std(double(F465))/sqrt(size(F465,1));
    dcSignal2 = mean(meanSignal2);
    
    % downsample 10x and average 465 signal
    allSignals = cell2mat(streams.(STREAM_STORES{3}).filtered');
    Fraw = zeros(size(allSignals(:,1:N:end-N+1)));
    for ii = 1:size(allSignals,1)
        Fraw(ii,:) = arrayfun(@(i) mean(allSignals(ii,i:i+N-1)),1:N:length(allSignals)-N+1);
    end
    minLength3 = size(Fraw,2);
    
    % Create the time vector for each stream store
    ts1 = TRANGE(1) + (1:minLength1) / streams.(STREAM_STORES{1}).fs*N;
    ts2 = TRANGE(1) + (1:minLength2) / streams.(STREAM_STORES{2}).fs*N;
    ts3=TRANGE(1)+(1:minLength3) / streams.(STREAM_STORES{3}).fs*N;
    
    % Subtract DC offset to get signals on top of one another
    meanSignal1 = meanSignal1 - dcSignal1;
    meanSignal2 = meanSignal2 - dcSignal2;
    
    % Fitting 405 channel onto 465 channel to detrend signal bleaching
    % Scale and fit data
    % Algorithm sourced from Tom Davidson's Github:
    % https://github.com/tjd2002/tjd-shared-code/blob/master/matlab/photometry/FP_normalize.m
    
    bls = polyfit( F405(1:end),F465(1:end), 1);
    Y_fit_all = bls(1) .* F405 + bls(2);
    Y_dF_all = F465 - Y_fit_all;
    
    zall = zeros(size(Y_dF_all));
    tmp = 0;
    for i = 1:size(Y_dF_all,1)
        ind = ts2(1,:) < BASELINE(2) & ts2(1,:) > BASELINE(1);
        zb = mean(Y_dF_all(i,ind)); % baseline period mean (-6 to -1 seconds)
        zsd = std(Y_dF_all(i,ind)); % baseline period stdev
        for j = 1:size(Y_dF_all,2) % Z score per bin
            tmp = tmp + 1;
            zall(i,tmp)=(Y_dF_all(i,j) - zb)/zsd;
        end
        tmp=0;
    end
    
    % Standard error of the z-score
    zerror = std(zall)/sqrt(size(zall,1));
end

