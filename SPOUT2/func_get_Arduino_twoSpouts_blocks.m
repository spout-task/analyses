%% twoSpouts tasks get block data
% dataBlocks - block info

function [output] = func_get_Arduino_twoSpouts_blocks(dataBlocks, trial_data, correct_trials2switch)

% flex vars
n_blocks = size(dataBlocks, 1) - 1; % first "block" is text

% create struct
output = struct;
[output(1:n_blocks).iBlock] = deal([]);
[output(1:n_blocks).iTrialType] = deal([]);
[output(1:n_blocks).trials2switch] = deal([]);
[output(1:n_blocks).total_trials] = deal([]);
[output(1:n_blocks).correct] = deal([]);
[output(1:n_blocks).incorrect] = deal([]);
[output(1:n_blocks).reward] = deal([]);
[output(1:n_blocks).noReward] = deal([]);
[output(1:n_blocks).omissions] = deal([]);
[output(1:n_blocks).cue_penalties] = deal([]);
[output(1:n_blocks).trials_cue] = deal([]);
[output(1:n_blocks).ENL_penalties] = deal([]);
[output(1:n_blocks).trials_ENL] = deal([]);
[output(1:n_blocks).blockLength] = deal([]);
[output(1:n_blocks).free_reward] = deal([]);
[output(1:n_blocks).leftLicks] = deal([]);
[output(1:n_blocks).rightLicks] = deal([]);

[output(1:n_blocks).iStrategy_wr] = deal([]);
[output(1:n_blocks).iStrategy_ls] = deal([]);
[output(1:n_blocks).iStrategy_ws] = deal([]);
[output(1:n_blocks).iStrategy_lr] = deal([]);
[output(1:n_blocks).iStrategy_correct] = deal([]);

% fill in data
for k=1:n_blocks % per block

    % get simple data
    tmp = [trial_data([trial_data(:).iBlock] == k).iBlock];
    output(k).iBlock = tmp(1);
    tmp = [trial_data([trial_data(:).iBlock] == k).iTrialType];
    if ~isempty(find(tmp == 1)) % block left
        output(k).iTrialType = 1;
    elseif ~isempty(find(tmp == 2)) % block right 
        output(k).iTrialType = 2;
    else
        error(['Unclear what block this is. Block: ' num2str(k)])
    end

    % get average data
    output(k).total_trials = size(trial_data([trial_data(:).iBlock] == k),2);
    output(k).correct = max([trial_data([trial_data(:).iBlock] == k).iCorrect]);
    output(k).incorrect = max([trial_data([trial_data(:).iBlock] == k).iInCorrect]);
    output(k).reward = max([trial_data([trial_data(:).iBlock] == k).iReward]);
    output(k).noReward = max([trial_data([trial_data(:).iBlock] == k).iNoReward]);
    output(k).omissions = sum([trial_data([trial_data(:).iBlock] == k).outcome] == 3);
    output(k).ENL_penalties = sum([trial_data([trial_data(:).iBlock] == k).n_ENL]) - output(k).total_trials;
    output(k).trials_ENL = sum([trial_data([trial_data(:).iBlock] == k).trials_ENL]);
    output(k).cue_penalties = sum([trial_data([trial_data(:).iBlock] == k).n_cue]) - output(k).total_trials;
    output(k).trials_cue = sum([trial_data([trial_data(:).iBlock] == k).trials_cue]);
    output(k).free_reward = sum([trial_data([trial_data(:).iBlock] == k).free_reward]);
    output(k).leftLicks = sum([trial_data([trial_data(:).iBlock] == k).leftLicks]);
    output(k).rightLicks = sum([trial_data([trial_data(:).iBlock] == k).rightLicks]);
    
    % get strategy rate
    output(k).iStrategy_wr = sum([trial_data([trial_data(:).iBlock] == k).iStrategy] == 1);
    output(k).iStrategy_ls = sum([trial_data([trial_data(:).iBlock] == k).iStrategy] == 2);
    output(k).iStrategy_ws = sum([trial_data([trial_data(:).iBlock] == k).iStrategy] == 3);
    output(k).iStrategy_lr = sum([trial_data([trial_data(:).iBlock] == k).iStrategy] == 4);
    output(k).iStrategy_correct = (output(k).iStrategy_wr + output(k).iStrategy_ls) / (output(k).iStrategy_wr + output(k).iStrategy_ls + output(k).iStrategy_ws + output(k).iStrategy_lr);

    % get data from dataBlocks file
    output(k).blockLength = str2double(dataBlocks(k+1, 3));

    % find trials2switch and correct for first trial is needed
    tmp = find([trial_data([trial_data(:).iBlock] == k).iTrial_post]);
    if isempty(tmp) % animal did not switch
        output(k).trials2switch = 0 - correct_trials2switch;
    else
        output(k).trials2switch = tmp(1) - correct_trials2switch;
    end

end
