function [bCIexp_sig] = bootstrapping(data, sig, consec_thresh, y)

[n,ev_win] = size(data);
bCI = boot_CI(data,1000,sig);
[adjLCI,adjUCI] = CIadjust(bCI(1,:),bCI(2,:),[],n,2);
bCIexp = [adjLCI;adjUCI];

bCIexp_sig = NaN(1,ev_win);
sig_idx = find((bCIexp(1,:) > 0) | (bCIexp(2,:) < 0));
consec = consec_idx(sig_idx,consec_thresh);
bCIexp_sig(sig_idx(consec)) = y;

end

