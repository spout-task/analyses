%% oneSpout tasks get trial data
% dataTrial - trial info

function [output, trial_info] = func_get_Arduino_oneSpout_trials(dataEvents, trial_info)

% flex vars
n_trials = size(trial_info,2);

% create struct; rows = trials
% iTrialType (1:A, 2:B, 3:RR) - outcome (1:reward, 2:error, 3:omission, 4:random reward)

output = struct;
[output(1:n_trials).nTrial] = deal(trial_info.nTrial);
[output(1:n_trials).iBlock] = deal(trial_info.iBlock);
[output(1:n_trials).iTrial] = deal(trial_info.iTrial);
[output(1:n_trials).iTrialType] = deal(trial_info.iTrialType);
[output(1:n_trials).iTrial_post] = deal([]);
[output(1:n_trials).outcome] = deal(trial_info.outcome);
[output(1:n_trials).iCorrect] = deal([]);
[output(1:n_trials).iInCorrect] = deal([]);
[output(1:n_trials).iReward] = deal([]);
[output(1:n_trials).iNoReward] = deal([]);
[output(1:n_trials).free_reward] = deal(trial_info.free_reward);
[output(1:n_trials).t_selection] = deal([]);
[output(1:n_trials).t_cue] = deal([]);
[output(1:n_trials).n_cue] = deal([]);
[output(1:n_trials).trials_cue] = deal([]);
[output(1:n_trials).t_ITI] = deal([]);
[output(1:n_trials).n_ENL] = deal([]);
[output(1:n_trials).trials_ENL] = deal([]);
[output(1:n_trials).licks] = deal([]);
[output(1:n_trials).blockSwitch] = deal([]);
[output(1:n_trials).opto] = deal([]);
[output(1:n_trials).opto_blk] = deal([]);
[output(1:n_trials).opto_ITI] = deal([]);
[output(1:n_trials).opto_cue] = deal([]);
[output(1:n_trials).opto_out] = deal([]);
[output(1:n_trials).opto_rew] = deal([]);
[output(1:n_trials).opto_err] = deal([]);
% timing for syncing
[output(1:n_trials).timing_start_time] = deal(trial_info.timing_start_time);
[output(1:n_trials).timing_stop_time] = deal(trial_info.timing_stop_time);

% find info per trial
for k=1:n_trials % per trial

    % reset tmp vars after block transition - val(1) = to store, val(2) = to keep track
    if k==1 || (str2double(dataEvents(trial_info(k).start_idx, 2)) - str2double(dataEvents(trial_info(k-1).start_idx, 2))) > 0
        tmp_correct = [0 0];
        tmp_incorrect = [0 0];
        tmp_reward = [0 0];
        tmp_noreward = [0 0];
    end

    % easy vars
    output(k).iTrial_post = str2double(dataEvents(trial_info(k).events(end), 4));

    % vars that might change
    % cue and ITI
    if output(k).iTrialType == 1 % A trial
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_A')); % find CUE A onset
        output(k).t_cue = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7)); % store duration
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_A')); % find ITI A onset
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7)); % store duration
    elseif output(k).iTrialType == 2 % B trial
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_B')); % find CUE B onset
        output(k).t_cue = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7));
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_B')); % find ITI B onset
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7));
    elseif output(k).iTrialType == 3 % RR trial Pavlovian
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_RR')); % find CUE RR onset
        output(k).t_cue = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7));
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_RR')); % find ITI RR onset
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7));
    else
        error(['Unclear what iTrialType trial ' num2str(k) ' is'])
    end

    % get outcome vars
    % ERROR OUTCOME
    if output(k).outcome == 2 
        % update correct/incorrect
        tmp_incorrect(2) = tmp_incorrect(2) + 1; 
        tmp_incorrect(1) = tmp_incorrect(2);
        tmp_correct(1) = 0;
        % update reward/noreward
        if ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'REWARD'))) % animal got reward
            tmp_reward(2) = tmp_reward(2) + 1; 
            tmp_reward(1) = tmp_reward(2);
            tmp_noreward(1) = 0;
        else % no reward
            tmp_noreward(2) = tmp_noreward(2) + 1; 
            tmp_noreward(1) = tmp_noreward(2);
            tmp_reward(1) = 0;
        end
        % find eventTime choice
        % tmp_choice = trial_info(k).choice_time;

    % CORRECT OUTCOME
    elseif output(k).outcome == 1 
        % update correct/incorrect
        tmp_correct(2) = tmp_correct(2) + 1; 
        tmp_correct(1) = tmp_correct(2);
        tmp_incorrect(1) = 0;
        % update reward/noreward
        if ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'NO_REWARD'))) % animal got no reward
            tmp_noreward(2) = tmp_noreward(2) + 1; 
            tmp_noreward(1) = tmp_noreward(2);
            tmp_reward(1) = 0;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'REWARD'))) % animal got reward -> "REWARD" overlaps with "NO_REWARD" so start with NO_REWARD
            tmp_reward(2) = tmp_reward(2) + 1; 
            tmp_reward(1) = tmp_reward(2);
            tmp_noreward(1) = 0;
        else
            error(['Unclear outcome of trial: ' num2str(k)])
        end
        % find eventTime choice
        % tmp_choice = trial_info(k).choice_time;
        
    % OMISSION
    elseif output(k).outcome == 3 
        % update correct/incorrect
        tmp_incorrect(2) = tmp_incorrect(2) + 1; 
        tmp_incorrect(1) = tmp_incorrect(2);
        tmp_correct(1) = 0;
        % update reward/noreward
        tmp_noreward(2) = tmp_noreward(2) + 1; 
        tmp_noreward(1) = tmp_noreward(2);
        tmp_reward(1) = 0;
        % find eventTime choice
        % tmp_choice = str2double(dataEvents(trial_info(k).choice_idx, 7)) + trial_info(k).choice_time;

    % RANDOM REWARD - Pavlovian conditioning
    elseif output(k).outcome == 4
        % update correct/incorrect
        tmp_incorrect(1) = 0;
        tmp_correct(1) = 0;
        % update reward/noreward
        tmp_noreward(1) = 0;
        tmp_reward(2) = tmp_reward(2) + 1;
        tmp_reward(1) = tmp_reward(2);
        % find eventTime choice
        % tmp_choice = str2double(dataEvents(trial_info(k).choice_idx, 7)) + trial_info(k).choice_time;

    end

    % store outcome
    output(k).iCorrect = tmp_correct(1);
    output(k).iInCorrect = tmp_incorrect(1);
    output(k).iReward = tmp_reward(1);
    output(k).iNoReward = tmp_noreward(1);

    % store choice latency (t_selection)
    output(k).t_selection = trial_info(k).choice_time - trial_info(k).selection_time;

    % penalties related vars
    output(k).n_cue = [size(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'CUE_A')), 1) + ...
                       size(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'CUE_B')), 1)+ ...
                       size(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'CUE_RR')), 1)];   % number of Cue presentations
    if output(k).n_cue > 1 % binarize cue penalties
        output(k).trials_cue = 1;
        trial_info(k).trials_cue = 1;
    else
        output(k).trials_cue = 0;
        trial_info(k).trials_cue = 0;
    end
    output(k).n_ENL = size(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'ENL_PENALTY')), 1) + 1;   % number of ENL periods (= penalties + 1)
    if output(k).n_ENL > 1 % binarize ENL's
        output(k).trials_ENL = 1;
        trial_info(k).trials_ENL = 1;
    else
        output(k).trials_ENL = 0;
        trial_info(k).trials_ENL = 0;
    end

    % lick vars
    output(k).licks = size(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Lick')), 1); % all licks

    % opto vars - assign 0 then fill in
    output(k).opto = 0;
    output(k).opto_blk = 0;
    output(k).opto_ITI = 0;
    output(k).opto_cue = 0;
    output(k).opto_out = 0;
    output(k).opto_rew = 0;
    output(k).opto_err = 0;
    % find opto
    if ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_ON'))) % opto stim
        output(k).opto = 1;
        % find which stim
        if ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_ITI'))) % ITI
            output(k).opto_ITI = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_cue'))) % cue
            output(k).opto_cue = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_anyOutcome'))) % anyOutcome
            output(k).opto_out = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_consumption')))
            output(k).opto_rew = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_error'))) % error
            output(k).opto_err = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_blockSwitch')))
            output(k).opto_blk = 1;
        end
    end
end


% add block switches
for k=1:n_trials  % per trial

    % BLOCK SWITCH
    if k == 1 % first block is a transition
        output(k).blockSwitch = 1;
    elseif output(k).iBlock ~= output(k-1).iBlock % transition
        output(k).blockSwitch = 1;
    else
        output(k).blockSwitch = 0;
    end

end
