%% twoSpouts tasks get session data
% dataTrial - data session
% dataLicks - lick data (optional), used for reward RT and lick frequency
% dataITI - ITI lick data (optional), used for ITI lick alignment

function [output] = func_get_Arduino_twoSpouts_session(dataTrial, dataBlock, dataLicks, dataITI)

% fixed vars
ILI_threshold = 250;    % ILI threshold in ms (within bout licks)

% optional inputs - older scripts only use dataTrial and dataBlock
if nargin < 3 % no lick data
    dataLicks = [];
end
if nargin < 4 % no ITI data -> dummy struct, ITI values become NaN
    dataITI = struct('repeat', NaN, 'n_licks', 0, 'prev_all', NaN, 'prev_first', NaN, 'prev_last', NaN, ...
        'future_all', NaN, 'future_first', NaN, 'future_last', NaN);
end

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

    % strategy fraction wr & ls & ws & lr (fraction of all non-omission trials, excl. first trial)
tmp = find([dataTrial(:).iStrategy] > 0);  % find all non-omission trials
output.strategy_frac_wr = length(find([dataTrial(tmp).iStrategy] == 1)) / length(tmp);
output.strategy_frac_ls = length(find([dataTrial(tmp).iStrategy] == 2)) / length(tmp);
output.strategy_frac_ws = length(find([dataTrial(tmp).iStrategy] == 3)) / length(tmp);
output.strategy_frac_lr = length(find([dataTrial(tmp).iStrategy] == 4)) / length(tmp);

    % choice reaction time (selection onset -> choice)
tmp = find([dataTrial(:).outcome] < 3);  % find all non-omission trials
output.RT_choice_median = median([dataTrial(tmp).t_selection], 'omitnan');
tmp = find(([dataTrial(:).iTrialType] == 1 & [dataTrial(:).outcome] < 3) == 1); % find all left non-omission trials
output.RT_choice_median_left = median([dataTrial(tmp).t_selection], 'omitnan');
tmp = find(([dataTrial(:).iTrialType] == 2 & [dataTrial(:).outcome] < 3) == 1); % find all right non-omission trials
output.RT_choice_median_right = median([dataTrial(tmp).t_selection], 'omitnan');

    % reward reaction time (consumption onset -> first reward lick) and ILI of reward licks - rewarded trials only
tmp_RT = nan(1, size(dataTrial,2));  % reward RT per trial
tmp_ILI_left = [];                   % within bout ILIs left
tmp_ILI_right = [];                  % within bout ILIs right
if ~isempty(dataLicks) && isfield(dataLicks, 'RT_reward') % per-trial values stored during preprocessing (func_get_Arduino_twoSpouts_licks)
    tmp_RT = [dataLicks(:).RT_reward];
    for k=1:size(dataTrial,2) % per trial
        tmp = dataLicks(k).ILI_reward; % ILIs between reward licks
        if ~isempty(tmp)
            if dataTrial(k).iTrialType == 1 % left
                tmp_ILI_left = [tmp_ILI_left tmp(tmp < ILI_threshold)];
            elseif dataTrial(k).iTrialType == 2 % right
                tmp_ILI_right = [tmp_ILI_right tmp(tmp < ILI_threshold)];
            end
        end
    end
elseif ~isempty(dataLicks) % older preprocessed files without RT_reward/ILI_reward: calculate here
    for k=1:size(dataTrial,2) % per trial
        if dataLicks(k).reward == 1 % rewarded trial
            % get outcome licks of rewarded spout
            if dataTrial(k).iTrialType == 1 % left
                tmp = dataLicks(k).left_outcome;
            elseif dataTrial(k).iTrialType == 2 % right
                tmp = dataLicks(k).right_outcome;
            end
            % get RT and ILIs
            if ~isempty(tmp) % animal licked for reward
                tmp_RT(k) = tmp(1) - dataLicks(k).outcome_start;
                tmp = diff(tmp); % ILIs
                if dataTrial(k).iTrialType == 1 % left
                    tmp_ILI_left = [tmp_ILI_left tmp(tmp < ILI_threshold)];
                elseif dataTrial(k).iTrialType == 2 % right
                    tmp_ILI_right = [tmp_ILI_right tmp(tmp < ILI_threshold)];
                end
            end
        end
    end
end
output.RT_reward_median = median(tmp_RT, 'omitnan');
output.RT_reward_median_left = median(tmp_RT(left_trials), 'omitnan');
output.RT_reward_median_right = median(tmp_RT(right_trials), 'omitnan');

    % reward lick frequency (within bout ILIs)
output.lick_freq_ILI_threshold = ILI_threshold;
output.lick_freq = 1 / (median([tmp_ILI_left tmp_ILI_right]) / 1000); % convert ms to seconds
output.lick_freq_left = 1 / (median(tmp_ILI_left) / 1000);
output.lick_freq_right = 1 / (median(tmp_ILI_right) / 1000);

    % ITI lick alignment with previous and future choice - repeat trials (previous choice == future choice)
tmp = find(([dataITI(:).repeat] == 1 & [dataITI(:).n_licks] > 0) == 1); % find all repeat trials with ITI licks
output.ITI_trials_repeat = length(tmp);
output.ITI_align_prev_all_repeat = mean([dataITI(tmp).prev_all], 'omitnan');
output.ITI_align_prev_first_repeat = mean([dataITI(tmp).prev_first], 'omitnan');
output.ITI_align_prev_last_repeat = mean([dataITI(tmp).prev_last], 'omitnan');
output.ITI_align_future_all_repeat = mean([dataITI(tmp).future_all], 'omitnan');
output.ITI_align_future_first_repeat = mean([dataITI(tmp).future_first], 'omitnan');
output.ITI_align_future_last_repeat = mean([dataITI(tmp).future_last], 'omitnan');

    % ITI lick alignment with previous and future choice - switch trials (previous choice ~= future choice)
tmp = find(([dataITI(:).repeat] == 0 & [dataITI(:).n_licks] > 0) == 1); % find all switch trials with ITI licks
output.ITI_trials_switch = length(tmp);
output.ITI_align_prev_all_switch = mean([dataITI(tmp).prev_all], 'omitnan');
output.ITI_align_prev_first_switch = mean([dataITI(tmp).prev_first], 'omitnan');
output.ITI_align_prev_last_switch = mean([dataITI(tmp).prev_last], 'omitnan');
output.ITI_align_future_all_switch = mean([dataITI(tmp).future_all], 'omitnan');
output.ITI_align_future_first_switch = mean([dataITI(tmp).future_first], 'omitnan');
output.ITI_align_future_last_switch = mean([dataITI(tmp).future_last], 'omitnan');
