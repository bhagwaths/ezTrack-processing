function [prop_error] = propagate_error(sem_array)
%PROPAGATE_ERROR when finding the mean of a set of values, each with their
%own SEM
    squared_sum = 0;
    for i=1:numel(sem_array)
        squared_sum = squared_sum + (sem_array(i)^2);
    end
    sqrt_sum = sqrt(squared_sum);
    prop_error = sqrt_sum / numel(sem_array);
end

