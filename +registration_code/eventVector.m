function [output] = eventVector(target_data,ts,t_diff,t_length,shifting)
%EVENTVECTOR Summary of this function goes here
%   Detailed explanation goes here
% [s,t] = size(input_time);
% input: target_data = reference time, ts = timestamps for each trial,
% t_diff = seconds relative to reference, t_length = max length of trials

lever_press_start = cell2mat(target_data);
lever_press_end = lever_press_start + t_diff;
lever_press_end(lever_press_end>t_length) = t_length;

emptyVecs = cell(height(lever_press_start),1);
output = cell(height(target_data),1);
if t_diff > 1
for x = 1:height(lever_press_start)
    temp = zeros(t_length,1);
    temp(lever_press_start(x)+shifting:lever_press_end(x)+shifting) = 1;
    
    if length(temp) > t_length
    temp = temp(1:t_length);
    end
    emptyVecs{x} = temp;
    
end
else
    % Don't need to worry about the differential going below 0 since Lp is
    % only possible after 200 when LO
    for x = 1:height(lever_press_start)
    temp = zeros(t_length,1);
    temp(lever_press_end(x)+shifting:lever_press_start(x)+shifting) = 1;
    emptyVecs{x} = temp;
    end

end
output(find(~cellfun(@isempty,target_data))) = emptyVecs;
for x = 1:height(output)
    if isempty(output{x})
   
        output{x} = zeros(t_length,1);
    end
end
end

