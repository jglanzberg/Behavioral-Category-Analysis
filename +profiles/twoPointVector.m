function [output] = twoPointVector(target_data,target_data_2,t_length)
%EVENTVECTOR Summary of this function goes here
%   Detailed explanation goes here
% [s,t] = size(input_time);
% For cocaine sessions, expand time window after lp 

lever_press_start = cell2mat(target_data);
lever_press_end = cell2mat(target_data_2);
lever_press_end(lever_press_end>t_length) = t_length;

emptyVecs = cell(height(lever_press_start),1);
output = cell(height(target_data),1);
% if t_diff > 1
for x = 1:height(lever_press_start)
    temp = zeros(t_length,1);
    temp(lever_press_start(x):lever_press_end(x)) = 1;
    emptyVecs{x} = temp;
end
% else
%     % Don't need to worry about the differential going below 0 since Lp is
%     % only possible after 200 when LO
%     for x = 1:height(lever_press_start)
%     temp = zeros(t_length,1);
%     temp(lever_press_end(x):lever_press_start(x)) = 1;
%     emptyVecs{x} = temp;
%     end
% 
% end
output(find(~cellfun(@isempty,target_data))) = emptyVecs;
for x = 1:height(output)
    if isempty(output{x})
   
        output{x} = zeros(t_length,1);
    end
end
end

