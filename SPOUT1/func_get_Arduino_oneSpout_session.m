%% oneSpout tasks get session data
% dataTrial - data session
% dataLicks - lick data (optional), used for reward RT and lick frequency (as SPOUT2)

function [output] = func_get_Arduino_oneSpout_session(dataTrial, dataBlock, dataLicks)

% fixed vars
ILI_threshold = 250;    % ILI threshold in ms (within bout licks), as SPOUT2

% optional inputs - older scripts only use dataTrial and dataBlock
if nargin < 3 % no lick data
    dataLicks = [];
end

% make output struct
output = struct;

% A/B/RR trials
A_trials = find([dataTrial(:).iTrialType] == 1);
B_trials = find([dataTrial(:).iTrialType] == 2);
RR_trials = find([dataTrial(:).iTrialType] == 3); % random reward
block_A_trials = find([dataBlock(:).iTrialType] == 1);
block_B_trials = find([dataBlock(:).iTrialType] == 2);

% session average data
output.trials = size(dataTrial,2);
output.trials_A = length(A_trials); % by trial type: block totals would include the random reward trials inside a block
output.trials_B = length(B_trials);
output.trials_RR = length(RR_trials);
output.number_blocks = size(dataBlock,2);
output.trials_per_block = mean([dataBlock.total_trials]);
    % licks
output.total_licks = sum([dataTrial(:).licks]);
output.total_licks_A = sum([dataTrial(A_trials).licks]);
output.total_licks_B = sum([dataTrial(B_trials).licks]);
output.total_licks_RR = sum([dataTrial(RR_trials).licks]);
    % correct
output.correct = length(find([dataTrial(:).iCorrect] > 0));
output.correct_A = length(find([dataTrial(A_trials).iCorrect] > 0));
output.correct_B = length(find([dataTrial(B_trials).iCorrect] > 0));
    % inCorrect
output.inCorrect = length(find([dataTrial(:).iInCorrect] > 0));
output.inCorrect_A = length(find([dataTrial(A_trials).iInCorrect] > 0));
output.inCorrect_B = length(find([dataTrial(B_trials).iInCorrect] > 0));
    % reward
output.reward = length(find([dataTrial(:).iReward] > 0));
output.reward_A = length(find([dataTrial(A_trials).iReward] > 0));
output.reward_B = length(find([dataTrial(B_trials).iReward] > 0));
output.reward_RR = length(find([dataTrial(RR_trials).iReward] > 0));
    % noReward
output.noReward = length(find([dataTrial(:).iNoReward] > 0));
output.noReward_A = length(find([dataTrial(A_trials).iNoReward] > 0));
output.noReward_B = length(find([dataTrial(B_trials).iNoReward] > 0));
    % omissions
output.omissions = length(find([dataTrial(:).outcome] == 3));
output.omissions_A = length(find([dataTrial(A_trials).outcome] == 3));
output.omissions_B = length(find([dataTrial(B_trials).outcome] == 3));
    % trials with cue penalties
output.trials_cue = sum([dataBlock(:).trials_cue]);
output.trials_cue_A = sum([dataBlock(block_A_trials).trials_cue]);
output.trials_cue_B = sum([dataBlock(block_B_trials).trials_cue]);
    % Cue penalties
tmp = find([dataTrial(:).n_cue] ~= 1);  % find all trials with cue penalties 
if isempty(tmp) % no penalties
    output.cue_penalties_mean = 0;
else
    output.cue_penalties_mean = mean([dataTrial(tmp).n_cue]);
end
tmp = find(([dataTrial(:).iTrialType] == 1 & [dataTrial(:).n_cue] ~= 1) == 1); % find all A trials with cue penalties
if isempty(tmp) % no penalties
    output.cue_penalties_mean_A = 0;
else
    output.cue_penalties_mean_A = mean([dataTrial(tmp).n_cue]);
end
tmp = find(([dataTrial(:).iTrialType] == 2 & [dataTrial(:).n_cue] ~= 1) == 1); % find all B trials with cue penalties
if isempty(tmp) % no penalties
    output.cue_penalties_mean_B = 0;
else
    output.cue_penalties_mean_B = mean([dataTrial(tmp).n_cue]);
end
    % trials with ENL penalties
output.trials_ENL = sum([dataBlock(:).trials_ENL]);
output.trials_ENL_A = sum([dataBlock(block_A_trials).trials_ENL]);
output.trials_ENL_B = sum([dataBlock(block_B_trials).trials_ENL]);
    % ENL penalties
tmp = find([dataTrial(:).n_ENL] ~= 1);  % find all trials with ENL penalties 
if isempty(tmp) % no penalties
    output.ENL_penalties_mean = 0;
else
    output.ENL_penalties_mean = mean([dataTrial(tmp).n_ENL]);
end
tmp = find(([dataTrial(:).iTrialType] == 1 & [dataTrial(:).n_ENL] ~= 1) == 1); % find all A trials with ENL penalties
if isempty(tmp) % no penalties
    output.ENL_penalties_mean_A = 0;
else
    output.ENL_penalties_mean_A = mean([dataTrial(tmp).n_ENL]);
end
tmp = find(([dataTrial(:).iTrialType] == 2 & [dataTrial(:).n_ENL] ~= 1) == 1); % find all B trials with ENL penalties
if isempty(tmp) % no penalties
    output.ENL_penalties_mean_B = 0;
else
    output.ENL_penalties_mean_B = mean([dataTrial(tmp).n_ENL]);
end
    % trials2switch
output.trials2switch_mean = mean([dataBlock(:).trials2switch]);
output.trials2switch_mean_A = mean([dataBlock(block_A_trials).trials2switch]);
output.trials2switch_mean_B = mean([dataBlock(block_B_trials).trials2switch]);
    % trials per block
output.trials_block_mean = mean([dataBlock(:).total_trials]);
output.trials_block_mean_A = mean([dataBlock(block_A_trials).total_trials]);
output.trials_block_mean_B = mean([dataBlock(block_B_trials).total_trials]);

    % free rewards
output.free_reward = sum([dataBlock(:).free_reward]);

    % reward reaction time (outcome onset -> first reward lick) and ILI of reward licks - rewarded trials only (as SPOUT2)
    % values per trial come from func_get_Arduino_oneSpout_licks (RT_reward, ILI_reward)
tmp_RT = nan(1, size(dataTrial,2));   % reward RT per trial
tmp_ILI_A = [];                       % within bout ILIs CS+ trials
tmp_ILI_RR = [];                      % within bout ILIs random reward trials
if ~isempty(dataLicks) && isfield(dataLicks, 'RT_reward')
    tmp_RT = [dataLicks(:).RT_reward];
    for k=1:size(dataTrial,2) % per trial
        tmp = dataLicks(k).ILI_reward; % ILIs between reward licks
        if ~isempty(tmp)
            if dataTrial(k).iTrialType == 1 % CS+
                tmp_ILI_A = [tmp_ILI_A tmp(tmp < ILI_threshold)];
            elseif dataTrial(k).iTrialType == 3 % random reward
                tmp_ILI_RR = [tmp_ILI_RR tmp(tmp < ILI_threshold)];
            end
        end
    end
end
output.RT_reward_median = median(tmp_RT, 'omitnan');
output.RT_reward_median_A = median(tmp_RT(A_trials), 'omitnan');
output.RT_reward_median_RR = median(tmp_RT(RR_trials), 'omitnan');

    % reward lick frequency (within bout ILIs)
output.lick_freq_ILI_threshold = ILI_threshold;
output.lick_freq = 1 / (median([tmp_ILI_A tmp_ILI_RR]) / 1000); % convert ms to seconds
output.lick_freq_A = 1 / (median(tmp_ILI_A) / 1000);
output.lick_freq_RR = 1 / (median(tmp_ILI_RR) / 1000);
