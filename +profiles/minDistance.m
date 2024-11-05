function [distances_matrix] = minDistance(temp,roi,head_pieces,avg)


reshaped_body_parts = reshape(temp, [], 2);
reshaped_body_parts = cat(1,reshaped_body_parts,avg);

replicated_roi = repmat(roi, size(reshaped_body_parts, 1), 1);

distances = sqrt(sum((reshaped_body_parts - replicated_roi).^2, 2));

distances_matrix = min(reshape(distances,[], size(head_pieces, 2)+1, size(head_pieces, 1)),[],2);
end