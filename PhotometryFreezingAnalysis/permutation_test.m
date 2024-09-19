function [perm_p_sig] = permutation_test(g1_data, g2_data, sig, consec_thresh, y)

[~,ev_win] = size(g1_data);
perm_p = permTest_array(g1_data,g2_data,1000);
perm_p_sig = NaN(1,ev_win);
sig_idx = find(perm_p < sig);
consec = consec_idx(sig_idx,consec_thresh);
perm_p_sig(sig_idx(consec)) = y;

end

