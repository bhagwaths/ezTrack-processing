function [new_array] = add_adj_vector(orig_array,new_row)
%ADJUST_VECTOR_LENGTH
%   When storing freeze % or signal for each CS or shock in an array, ensures that
%   the vector length (added as new row to the array) matches the array length, 
%   using downsampling. Then adds the row to the array.
    if isempty(orig_array)
        new_array = [orig_array; new_row];
    elseif length(new_row) == length(orig_array)
        new_array = [orig_array; new_row];
    elseif length(new_row) > length(orig_array)
        oL = length(new_row);
        downsampled = interp1(1:oL, new_row, linspace(1,oL,length(orig_array)));
        new_array = [orig_array; downsampled];
    else % length(new_row) < length(orig_array)
        oL = size(orig_array,2);
        for row=1:size(orig_array,1)
            new_array(row,:) = interp1(1:oL, orig_array(row,:), linspace(1,oL,length(new_row)));
        end
        new_array = [new_array; new_row];
    end
end

