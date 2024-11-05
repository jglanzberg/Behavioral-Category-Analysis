function [shifted_b] = randomShift(input_data,n)

%flip,recorder trials, circ shift each trial 
% 
% randi
%
% shuffled trials 
input_data = cellfun(@(X) flip(X,1) , input_data , 'UniformOutput' , false);

n_trials = height(input_data);
n_vectors = n;

shift_vectors = round(rand(n_trials, n_vectors) * 1100);
shifted_b = cell(n_trials,n_vectors);


numRows = size(shift_vectors, 1);
numCols = size(shift_vectors, 2);

shift_vectors = mat2cell(shift_vectors, numRows, ones(1, numCols));


for x = 1:n_vectors
    shuffle_t = randperm(n_trials,n_trials);
        s_input_data = input_data(shuffle_t);

    shifted_b(:,x) = cellfun(@(X,Y) circshift(X,Y),s_input_data,num2cell(shift_vectors{x}),'UniformOutput',false);
end

end