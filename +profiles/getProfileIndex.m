function [outputArg1] = getProfileIndex(inputArg1,inputArg2)
%GETPROFILEINDEX Summary of this function goes here
%   Detailed explanation goes here
valid = size(inputArg1,2);
valid = 1:valid;
valid = ismember(valid,inputArg2);
vals = zeros(1,size(inputArg1,2));
vals(valid) = inputArg2;
% inputArg1 = inputArg1(:,valid);
[~,labled_idx] = max(inputArg1.* vals,[],2);
outputArg1 = labled_idx;
end

