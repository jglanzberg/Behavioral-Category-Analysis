function [profile,raw_distances] = generateProfiles(rois,tracking_data,head_pieces,body_pieces)
%generateProfiles creates the behavior profile vectors
% rois is a table with 3 columns. ("name","position","cut_off")
% * Name is the name of the relevant roi
% * position is a set of x,y positions that the roi is at in uniform space
% * cut_off is the number of pixels in uniform space away from the position that the subject can be while still being considered "near" the ROI


% The constants used are tuned for our video sampling rate of 10 frames a
% second

head_pos = tracking_data.int;

body_pos = head_pos;
avg_head_pos =cell(height(head_pos),1);
avg_body_pos =avg_head_pos;


velocity_h = cell(numel(head_pos),1);
velocity_b = cell(numel(head_pos),1);
slowing = cell(numel(head_pos),1);
active = cell(numel(head_pos),1);
rearing = cell(height(tracking_data),1);
profile = cell(13,height(tracking_data));

min_resting_len = 40;
box_gap = 15;
w = 97.5;
l = 119;
trial_length = 1100;

v_b_ths = 0.7;
num_parts = 15;

time_for_retrieval_after_delivery = 10; % in frames, in our case this was 1s
% For the various fixed parameters please check comments below for how to
% match the code to your dataset and trial structure. 



for x = 1:numel(head_pos)
	if ~isempty(head_pos{x})
		head_pos{x} = cat(3,head_pos{x}.x,head_pos{x}.y,head_pos{x}.p);
		head_pos{x} = [ head_pos{x};nan(trial_length - size( head_pos{x},1),num_parts,3)];
		head_pos{x} = head_pos{x}(:,head_pieces,1:2);



		body_pos{x} = cat(3,body_pos{x}.x,body_pos{x}.y,body_pos{x}.p);
		body_pos{x} = [ body_pos{x};nan(trial_length - size( body_pos{x},1),num_parts,3)];
		body_pos{x} = body_pos{x}(:,body_pieces,1:2);

		avg_head_pos{x} = squeeze(mean(head_pos{x},2,'omitnan'));
		avg_body_pos{x} = squeeze(mean(body_pos{x},2,'omitnan'));

		avg_head_pos{x} = complex(avg_head_pos{x}(:,1),avg_head_pos{x}(:,2));
		avg_head_pos{x} = xy_interp(avg_head_pos{x},"max_gap",inf);

		avg_head_pos{x} = convert_back(avg_head_pos{x});

		velocity_h{x} = [nan(1,1);vecnorm(median(movmean(diff(head_pos{x},1,1),11,1,'omitnan'),2,'omitnan'),2,3)];
		velocity_b{x} = [nan(1,1);vecnorm(median(movmean(diff(body_pos{x},1,1),11,1,'omitnan'),2,'omitnan'),2,3)];


		active{x} = [nan(1,1);median(movmax(vecnorm(diff(head_pos{x},1,1),2,3),21,1,'omitnan'),2,'omitnan')];



		slowing{x} = [nan(1,1);mean(movmin(vecnorm(diff(body_pos{x},1,1),2,3),7,1,'omitnan'),2,'omitnan')];



	end
	if length(tracking_data.lvr_food{x}) > 1
		tracking_data.lvr_food{x} = round(mean(tracking_data.lvr_food{x}));
	end


	head = avg_head_pos{x};
	body = avg_body_pos{x};



	outsideg = head(:,1)<= -(w+box_gap) | head(:,1) >=(w+box_gap) | head(:,2)<= -(l+box_gap) | head(:,2) >=(l+box_gap);

	insideb = body(:,1)>= -w & body(:,1) <=w & body(:,2)>= -l & body(:,2) <=l;

	rearing{x} = outsideg&insideb;

end

%  The constants used are tuned for our video sampling rate of 10 frames a
% second. 2 and 5 are relative to the moving means of the relevant parts.
ths_slowing = cellfun(@(X) X <= 2,slowing,'UniformOutput',false);
ths_active = cellfun(@(X) X >= 5,active,'UniformOutput',false);


raw_distances = cell(height(rois)+6,height(tracking_data));
distance = cell(height(rois),height(tracking_data));;

for x = 1:height(rois)

	roi = rois.position{x};

	raw_distances(x,:) = cellfun(@(X,Y) profiles.minDistance(X,roi,head_pieces,Y),head_pos(~cellfun(@isempty,head_pos)),avg_head_pos(~cellfun(@isempty,avg_head_pos)),'UniformOutput',false);
	distance(x,:) = cellfun(@(X) X<rois.cut_off(x) ,raw_distances(x,~cellfun(@isempty,head_pos)),'UniformOutput',false);


end




locomotion = cellfun(@(X) X > v_b_ths,velocity_b,'UniformOutput',false);

% When negating locomotion you must be sure to account for frames where the
% house light is off. By definition those frames won't have motion and by
% the line below would be labeled as resting. This is impossible to know
% and must be corrected for
resting = cellfun(@(X) keepConsecutiveTrue(~X,min_resting_len),locomotion,'UniformOutput',false);





near_lever = distance(1:3,:);

% Check near the lever for 2 seconds prior to lever press. 2s = 20 frames 
s2lp = registration_code.eventVector(tracking_data.lvr_food,tracking_data.timestamps,-20,trial_length,0);
%Lever press, 2 seconds before and near port
profile(1,:) = cellfun(@(X,Y) X.*Y,near_lever(1,:)',s2lp,'UniformOutput',false);

profile(2,:) = cellfun(@(X,Y) X.*Y,near_lever(2,:)',s2lp,'UniformOutput',false);




profile(4,:) = cellfun(@(X,Y,Z) X.*Y.*Z,near_lever(1,:)',ths_active,ths_slowing,'UniformOutput',false);
profile(5,:) = cellfun(@(X,Y,Z) X.*Y.*Z,near_lever(2,:)',ths_active,ths_slowing,'UniformOutput',false);
% profile(7,:) = near_lever(3,:);



% Pellet retrieval
% 1s after BB - follow proc for calculating Bb when not available
retr_1 = registration_code.eventVector(tracking_data.retrieval,tracking_data.timestamps,time_for_retrieval_after_delivery,trial_length,0);
%retrieval



% Consumption phase can only occur for at most 9s after the retrieval. 9s =
% 90 frames. It must occur at least 1 full second after it was delievered.
% 1s = 10 frames.
consump = registration_code.eventVector(tracking_data.retrieval,tracking_data.timestamps,90,trial_length,10);

profile(6,:) = cellfun(@(X,Y) X.*Y,consump,resting,'UniformOutput',false);
profile(7,:) = cellfun(@(X,Y) X.*Y,retr_1,near_lever(3,:)','UniformOutput',false);

profile(8,:) = cellfun(@(X,Y,Z) X.*Y.*Z,near_lever(3,:)',ths_active,ths_slowing,'UniformOutput',false);


% Locomotion
profile(10,:) = locomotion;



profile(3,:) = rearing;
profile(11,:) = resting;


%Hl off
HL_on = profiles.twoPointVector(tracking_data.HL_on,tracking_data.HL_off,trial_length);
profile(9,:) = cellfun(@(X) ~X,HL_on,'UniformOutput',false);


% Need to decide if missing is both missing or if only one is missing
profile(12,:) = cellfun(@(X,Y) isnan(sum(X,2)) | isnan(sum(Y,2)),avg_body_pos,avg_head_pos,'UniformOutput',false);


%Other
profile(13,:) = cellfun(@(X) ones(trial_length,1),head_pos(~cellfun(@isempty,head_pos)),'UniformOutput',false);




raw_distances(4,:) = velocity_h;%
raw_distances(5,:) = velocity_b;%
raw_distances(6,:) = active;%
raw_distances(7,:) = slowing;
raw_distances(8,:) = avg_head_pos;
raw_distances(9,:) = avg_body_pos;


% clear s2lp roi retr_1 rearing resting outsideg insideb Hl_on consump box_gap body_pos body head locomotion near_lever


end

function output = convert_back(input_complex)
output(:,1) = real(input_complex);
output(:,2) = imag(input_complex);
end

function [xy_interp] = xy_interp(xy,opts)
%%% Find jumps in tracking data by interpolation
% Required inputs:
%   #1: xy (nframes x nparts complex array)
% Optional name=value inputs:
%   isvalid (logical array, same size as "xy")
%       Logical false values in "isvalid" indicate the corresponding element of "xy" is invalid
%   max_gap
%   scale
% outputs:
%   #1: jump score (nframes x nparts array)
arguments
	xy						(:,:)	single
	opts.max_gap			(1,1)	double	= 1
	opts.interp_method		(1,1)	string	= "pchip"
	opts.isvalid			(:,:)	logical
	opts.min_valid_frames	(1,1)	double	= 0.5
end


if isfield(opts,'isvalid')
	xy(~opts.isvalid) = nan+nan*1i;
end

nparts = width(xy);
isvalid = isfinite(xy);

if isfinite(opts.max_gap)
	closable = imclose(isvalid,ones(opts.max_gap+1,1)) & ~isvalid;
else
	closable = ~isvalid;
end

xy_interp = xy;
for x = 1:nparts
	if mean(isvalid(:,x))<opts.min_valid_frames
		continue
	end
	query_idx = find(closable(:,x));
	if ~isempty(query_idx)
		xy_interp(query_idx,x) = interp1(	...
			find(isvalid(:,x)),		...
			xy(isvalid(:,x),x),		...
			query_idx,		...
			opts.interp_method,		...
			nan+nan*1i);
	end
end

end

function J = keepConsecutiveTrue(logicalVector, desiredLength)


J = imopen(logicalVector,ones(desiredLength,1));

end