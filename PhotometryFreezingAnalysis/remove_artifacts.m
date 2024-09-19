function [] = remove_artifacts(streams, ARTIFACT, STREAM_STORES)
    art1 = ~cellfun('isempty', cellfun(@(x) x(x>ARTIFACT), streams.(STREAM_STORES{1}).filtered, 'UniformOutput',false));
    art2 = ~cellfun('isempty', cellfun(@(x) x(x<-ARTIFACT), streams.(STREAM_STORES{1}).filtered, 'UniformOutput',false));
    good = ~art1 & ~art2;
    streams.(STREAM_STORES{1}).filtered = streams.(STREAM_STORES{1}).filtered(good);
    
    art1 = ~cellfun('isempty', cellfun(@(x) x(x>ARTIFACT), streams.(STREAM_STORES{2}).filtered, 'UniformOutput',false));
    art2 = ~cellfun('isempty', cellfun(@(x) x(x<-ARTIFACT), streams.(STREAM_STORES{2}).filtered, 'UniformOutput',false));
    good2 = ~art1 & ~art2;
    streams.(STREAM_STORES{2}).filtered = streams.(STREAM_STORES{2}).filtered(good2);
    
    numArtifacts = sum(~good) + sum(~good2);
end

