const = BEC;
sids = fetch(const.conn,"SELECT DISTINCT sid FROM cells").sid;
profiles = [1:8,10,11,13];

conf_table = table('Size',[length(sids) 3],'VariableTypes',["cell","cell","cell"],'VariableNames',["cc","bb","scores"]);
bout_table = table();

%%
all_b_n = cellfun (@(X) size(X,1),bout_table.bouts);

%%
shift_vects = table();
r_table = table();


%%
for target_s = 1:numel(sids)
	tic
	disp(target_s);
	target_sid = sids(target_s);
	% target_cells = fetch(const.conn,"SELECT sid,extract_id FROM filtered_data t1 WHERE t1.sid = "+target_sid);
	target_cells = fetch(const.conn,"SELECT sid,extract_id FROM cell_stats WHERE sid = " + target_sid);
	neural_data = load_functions.load_neural_data(target_cells,2,'use_db',false);
	behavior_data = const.get_behavior_data(target_sid);

	if ~isequal(neural_data.rec_ids{1},behavior_data.rec_ids)
		t2 = ~ismember(neural_data.rec_ids{1},behavior_data.rec_ids);
		t3 = ~ismember(behavior_data.rec_ids,neural_data.rec_ids{1});
		if sum(t2 ~=0)
			t2 = find(t2);
			all_neural_frames = 1:size(neural_data.normal_trace{1},1);
			remove_frames_t2 = [];
			for missing_t2 = 1:numel(t2)
				remove_frames_t2 = [remove_frames_t2,(((t2(missing_t2)-1)*1100)+1):((t2(missing_t2))*1100)];
			end
			% neural data has rec_ids not found in behavior
			all_neural_frames = setdiff(all_neural_frames,remove_frames_t2);

			neural_data.normal_trace{1} = neural_data.normal_trace{1}(all_neural_frames,:);

		end

		if sum(t3 ~=0)
			% behavior has rec_ids not found in the neural
			error("Unexpected");

		end
	end


	deconv = neural_data.normal_trace{1};

	session_profiles = cat(1,behavior_data.profiles{:});

	assert(isequal(size(deconv,1),size(session_profiles,1)))
	avg_bout = cell(11,1);

	for p_0 = 1:11
		p = profiles(p_0);
		[interval,~,~] = lp.util.find_intervals(session_profiles,1,'min_length',2,'cell_output',false,'vals',p);
		if ~isempty(interval)

			neural_bouts = cell(size(interval,1),1);
			for bout = 1:size(interval,1)
				neural_bouts{bout} = mean(deconv(interval(bout,1):interval(bout,2),:),1,"omitnan");
			end


			place_hold = cat(1,neural_bouts{:});
	

			avg_bout{p_0} = mean(place_hold,1,'omitnan');
		end
	end

	missing_p = cellfun(@isempty,avg_bout);
	not_missing = ~missing_p;
	not_missing = find(not_missing,1);
	avg_bout(missing_p) = {ones(1,size(avg_bout{not_missing},2))*-1};
	clear missing_p not_missing;

	final_coeff = cat(1,avg_bout{:});

	fix_nan = isnan(final_coeff);
	final_coeff(fix_nan) = -1;

	conf_table.scores{target_s} = final_coeff;
	% conf_table.cc{target_s} = ci;
	% conf_table.bb{target_s} = bootstat;

	beep
	tuning_table = table;
	sid_col = repmat(target_sid,height(target_cells),1);
	commaSeparatedString = cell(height(target_cells),1);
	for n = 1:size(final_coeff,2)

		commaSeparatedString{n} = join(string(final_coeff(:,n)'), ',');

		% updateQuery = "UPDATE tuning_profiles SET scores = '" + commaSeparatedString +"' WHERE sid = "+ num2str(target_sid) +" AND extract_id = " +num2str(target_cells.extract_id(n))+ ";";
		% execute(const.conn,updateQuery);
	end
	tuning_table.sid = sid_col;
	tuning_table.extract_id = (1:height(target_cells))';
	tuning_table.scores= string(commaSeparatedString);
	sqlwrite(const.conn,"tuning_profiles",tuning_table);

	clear avg_bout tuning_table t2 sid_col place_hold ci bootstat invalid_idx behavior_data fix_nan bout commaSeparatedString deconv final_coeff interval len n neural_bouts neural_data p p_0 session_profiles target_cells target_sid type updateQuery;
	toc
end