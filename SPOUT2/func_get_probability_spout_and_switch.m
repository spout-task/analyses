%% twoSpouts tasks get probability high reward and switch
% function to calculate probability of selecting high reward spout and switch to the other spout around a block switch
% input trial data, how many trials to analyze pre and post

function [prob_spout, prob_switch] = func_get_probability_spout_and_switch(trials, n_trials_pre, n_trials_post)

% get all the block switches
trials_blockSwitch = find([trials.blockSwitch] == 1);

% get rid of the first one
if trials_blockSwitch(1) == 1
    trials_blockSwitch(1) = [];
end

% make matrix
prob_spout = nan(size(trials_blockSwitch,2), n_trials_pre+n_trials_post);
prob_switch = nan(size(trials_blockSwitch,2), n_trials_pre+n_trials_post);

% calculate high spout probability and switch probablity around block transitions
for k = 1:size(trials_blockSwitch,2) % per blockSwitch
    % find current blockswith trial
    current_blockSwitch = trials_blockSwitch(k);

    % reward spout probability
    try % if it's last block, we might not be able to get enough trials
        prob_spout(k,1:n_trials_pre+n_trials_post) = [trials(current_blockSwitch-n_trials_pre:current_blockSwitch+n_trials_post-1).rewSpout];
    catch
        max_trials = size(trials,2);
        prob_spout(k,1:length(current_blockSwitch-n_trials_pre:max_trials)) = [trials(current_blockSwitch-n_trials_pre:max_trials).rewSpout];
    end

    % switch probability
    try % if it's last block, we might not be able to get enough trials
        prob_switch(k,1:n_trials_pre+n_trials_post) = [trials(current_blockSwitch-n_trials_pre:current_blockSwitch+n_trials_post-1).animalSwitch];
    catch
        max_trials = size(trials,2);
        prob_switch(k,1:length(current_blockSwitch-n_trials_pre:max_trials)) = [trials(current_blockSwitch-n_trials_pre:max_trials).animalSwitch];
    end
end

end