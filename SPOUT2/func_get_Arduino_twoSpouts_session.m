%% twoSpouts tasks get session data
% dataTrial - data session

function [output] = func_get_Arduino_twoSpouts_session(dataTrial, dataBlock)

% make output struct
output = struct;

% left/right trials
left_trials = find([dataTrial(:).iTrialType] == 1);
right_trials = find([dataTrial(:).iTrialType] == 2);
block_left_trials = find([dataBlock(:).iTrialType] == 1);
block_right_trials = find([dataBlock(:).iTrialType] == 2);

% session average data
output.trials = size(dataTrial,2);
output.trials_left = sum([dataBlock(block_left_trials).total_trials]);
output.trials_right = sum([dataBlock(block_right_trials).total_trials]);
output.number_blocks = size(dataBlock,2);
output.trials_per_block = mean([dataBlock.total_trials]);
    % licks
output.total_licks = sum([dataTrial(:).leftLicks]) + sum([dataTrial(:).rightLicks]);
output.total_licks_left = sum([dataTrial(:).leftLicks]);
output.total_licks_right = sum([dataTrial(:).rightLicks]);
    % correct
output.correct = length(find([dataTrial(:).iCorrect] > 0));
output.correct_left = length(find([dataTrial(left_trials).iCorrect] > 0));
output.correct_right = length(find([dataTrial(right_trials).iCorrect] > 0));
    % inCorrect
output.inCorrect = length(find([dataTrial(:).iInCorrect] > 0));
output.inCorrect_left = length(find([dataTrial(left_trials).iInCorrect] > 0));
output.inCorrect_right = length(find([dataTrial(right_trials).iInCorrect] > 0));
    % reward
output.reward = length(find([dataTrial(:).iReward] > 0));
output.reward_left = length(find([dataTrial(left_trials).iReward] > 0));
output.reward_right = length(find([dataTrial(right_trials).iReward] > 0));
    % noReward
output.noReward = length(find([dataTrial(:).iNoReward] > 0));
output.noReward_left = length(find([dataTrial(left_trials).iNoReward] > 0));
output.noReward_right = length(find([dataTrial(right_trials).iNoReward] > 0));
    % omissions
output.omissions = length(find([dataTrial(:).outcome] == 3));
output.omissions_left = length(find([dataTrial(left_trials).outcome] == 3));
output.omissions_right = length(find([dataTrial(right_trials).outcome] == 3));

    % trials with cue penalties
output.trials_cue = sum([dataBlock(:).trials_cue]);
output.trials_cue_left = sum([dataBlock(block_left_trials).trials_cue]);
output.trials_cue_right = sum([dataBlock(block_right_trials).trials_cue]);
    % Cue penalties
tmp = find([dataTrial(:).n_cue] ~= 1);  % find all trials with cue penalties 
if isempty(tmp) % no penalties
    output.cue_penalties_mean = 0;
else
    output.cue_penalties_mean = mean([dataTrial(tmp).n_cue]);
end
tmp = find(([dataTrial(:).iTrialType] == 1 & [dataTrial(:).n_cue] ~= 1) == 1); % find all left trials with cue penalties
if isempty(tmp) % no penalties
    output.cue_penalties_mean_left = 0;
else
    output.cue_penalties_mean_left = mean([dataTrial(tmp).n_cue]);
end
tmp = find(([dataTrial(:).iTrialType] == 2 & [dataTrial(:).n_cue] ~= 1) == 1); % find all right trials with cue penalties
if isempty(tmp) % no penalties
    output.cue_penalties_mean_right = 0;
else
    output.cue_penalties_mean_right = mean([dataTrial(tmp).n_cue]);
end

    % trials with ENL penalties
output.trials_ENL = sum([dataBlock(:).trials_ENL]);
output.trials_ENL_left = sum([dataBlock(block_left_trials).trials_ENL]);
output.trials_ENL_right = sum([dataBlock(block_right_trials).trials_ENL]);
    % ENL penalties
tmp = find([dataTrial(:).n_ENL] ~= 1);  % find all trials with ENL penalties 
if isempty(tmp) % no penalties
    output.ENL_penalties_mean = 0;
else
    output.ENL_penalties_mean = mean([dataTrial(tmp).n_ENL]);
end
tmp = find(([dataTrial(:).iTrialType] == 1 & [dataTrial(:).n_ENL] ~= 1) == 1); % find all left trials with ENL penalties
if isempty(tmp) % no penalties
    output.ENL_penalties_mean_left = 0;
else
    output.ENL_penalties_mean_left = mean([dataTrial(tmp).n_ENL]);
end
tmp = find(([dataTrial(:).iTrialType] == 2 & [dataTrial(:).n_ENL] ~= 1) == 1); % find all right trials with ENL penalties
if isempty(tmp) % no penalties
    output.ENL_penalties_mean_right = 0;
else
    output.ENL_penalties_mean_right = mean([dataTrial(tmp).n_ENL]);
end

    % correct strategy
output.correct_strategy_mean = mean([dataBlock(:).iStrategy_correct], 'omitnan');
output.correct_strategy_mean_left = mean([dataBlock(block_left_trials).iStrategy_correct], 'omitnan');
output.correct_strategy_mean_right = mean([dataBlock(block_right_trials).iStrategy_correct], 'omitnan');
    % trials2switch
output.trials2switch_mean = mean([dataBlock(:).trials2switch]);
output.trials2switch_mean_left = mean([dataBlock(block_left_trials).trials2switch]);
output.trials2switch_mean_right = mean([dataBlock(block_right_trials).trials2switch]);
    % trials per block
output.trials_block_mean = mean([dataBlock(:).total_trials]);
output.trials_block_mean_left = mean([dataBlock(block_left_trials).total_trials]);
output.trials_block_mean_right = mean([dataBlock(block_right_trials).total_trials]);
    % strategy wr & ls & ws & lr
output.strategy_wr_mean = mean([dataBlock(:).iStrategy_wr]);
output.strategy_ls_mean = mean([dataBlock(:).iStrategy_ls]);
output.strategy_ws_mean = mean([dataBlock(:).iStrategy_ws]);
output.strategy_lr_mean = mean([dataBlock(:).iStrategy_lr]);

% free rewards
output.free_reward = sum([dataBlock(:).free_reward]);
