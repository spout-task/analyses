    %% twoSpouts tasks get trial data
% dataTrial - trial info

function [output, trial_info] = func_get_Arduino_twoSpouts_trials(dataEvents, trial_info)

% flex vars
n_trials = size(trial_info,2);

% create struct; rows = trials
% iTrialType (1:left, 2:right) - outcome (1:reward, 2:error, 3:omission) -
% iStrategy (0=trial 1 or omission, 1=win-repeat, 2=lose-switch, 3=win-switch, 4=lose-repeat)
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
[output(1:n_trials).leftLicks] = deal([]);
[output(1:n_trials).rightLicks] = deal([]);
[output(1:n_trials).iStrategy] = deal([]);
[output(1:n_trials).blockSwitch] = deal([]);
[output(1:n_trials).rewSpout] = deal([]);
[output(1:n_trials).animalSwitch] = deal([]);
[output(1:n_trials).opto] = deal([]);
[output(1:n_trials).opto_blk] = deal([]);
[output(1:n_trials).opto_ITI] = deal([]);
[output(1:n_trials).opto_cue] = deal([]);
[output(1:n_trials).opto_delay] = deal([]);
[output(1:n_trials).opto_startCue] = deal([]);
[output(1:n_trials).opto_out] = deal([]);
[output(1:n_trials).opto_rew] = deal([]);
[output(1:n_trials).opto_err] = deal([]);
% timing for syncing
[output(1:n_trials).trial_start_time] = deal(trial_info.trial_start_time);
[output(1:n_trials).trial_stop_time] = deal(trial_info.trial_stop_time);

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
    if output(k).iTrialType == 1 % left trial
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_LEFT')); % find CUE onset
        output(k).t_cue = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7)); % store duration
        tmp1 = find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_LEFT')); % find ITI onset
        tmp2 = find(ismember(dataEvents(trial_info(k).events, 5), 'ENL_LEFT')); % old task
        tmp = [tmp1 tmp2]; % find ITI onset (old or new)
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7)); % store duration
    elseif output(k).iTrialType == 2 % right trial
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_RIGHT')); % find CUE onset
        output(k).t_cue = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7));
        tmp1 = find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_RIGHT')); % find ITI onset
        tmp2 = find(ismember(dataEvents(trial_info(k).events, 5), 'ENL_RIGHT')); % old task
        tmp = [tmp1 tmp2]; % find ITI onset (old or new)
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx + tmp(1) - 1, 7));
    else
        error(['Unclear what iTrialType trial ' num2str(k) ' is'])
    end

    % outcome vars
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
    end

    % store outcome
    output(k).iCorrect = tmp_correct(1);
    output(k).iInCorrect = tmp_incorrect(1);
    output(k).iReward = tmp_reward(1);
    output(k).iNoReward = tmp_noreward(1);

    % store choice latency (t_selection) -> selection till actual choice 
    output(k).t_selection = trial_info(k).choice_time - trial_info(k).selection_time;

    % penalties related vars
    output(k).n_cue = [size(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'CUE_LEFT')), 1) + ...
                       size(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'CUE_RIGHT')), 1)];   % number of Cue presentations
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
    output(k).leftLicks = size(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'LickLeft')), 1); % left licks
    output(k).rightLicks = size(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'LickRight')), 1); % right licks

    % opto vars - assign 0 then fill in
    output(k).opto = 0;
    output(k).opto_blk = 0;
    output(k).opto_ITI = 0;
    output(k).opto_cue = 0;
    output(k).opto_delay = 0;
    output(k).opto_startCue = 0;
    output(k).opto_out = 0;
    output(k).opto_rew = 0;
    output(k).opto_err = 0;
    % find opto
    if ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_ON'))) || ... % opto stim
            ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Laser ON'))) || ... % old task
            ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto ON'))) % old task
        output(k).opto = 1;
        % find which stim
        if ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_ITI'))) || ... % ITI
           ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto ENL'))) % old task
            output(k).opto_ITI = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_cue'))) || ... % cue
               ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto Cue'))) % old task
            output(k).opto_cue = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_delay'))) % delay
            output(k).opto_delay = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_startCue'))) % startCue
            output(k).opto_startCue = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_anyOutcome'))) % anyOutcome
            output(k).opto_out = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_consumption'))) || ... % consumption
               ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_outcome'))) || ... % old task
               ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto Outcome'))) % old task
            output(k).opto_rew = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_error'))) % error
            output(k).opto_err = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto_blockSwitch'))) || ... % blockSwitch
               ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'Opto BlockSwitch'))) % old task
            output(k).opto_blk = 1;
        end
    end
end

% classify trial strategy -> iStrategy
% 0=trial 1 or omission, 1=win-repeat, 2=lose-switch, 3=win-switch, 4=lose-repeat
% (1&2 are correct strategies, 3&4 incorrect)
output(1).iStrategy = 0;
for k=2:n_trials % per trial
    % make sure animal did not make an omission at previous or current trial
    if output(k).outcome == 3
        output(k).iStrategy = 0;
    else
        % if previous trial(s) is an omission, find last successful trail
        if output(k-1).outcome == 3
            try % go through all the previous trials and find the last trial that was not an omission
                tmp = find([output(1:k-1).outcome] < 3);
                q = k - tmp(end);
            catch % if the first trial was an omission, you can't find a previous non-omission trial
                q = 1;
            end
        else % compare against last trial
            q = 1;
        end

        % win-repeat (1)
        if output(k-q).iTrialType == output(k).iTrialType   % within block
            if output(k-q).iCorrect > 0 && output(k).iCorrect > 0
                output(k).iStrategy = 1;
            end
        else    % between blocks (=switch)
            if output(k-q).iCorrect > 0 && output(k).iCorrect == 0
                output(k).iStrategy = 1;
            end
        end

        % lose-switch (2)
        if output(k-q).iTrialType == output(k).iTrialType   % within block
            if output(k-q).iCorrect == 0 && output(k).iCorrect > 0
                output(k).iStrategy = 2;
            end
        else    % between blocks (=switch)
            if output(k-q).iCorrect == 0 && output(k).iCorrect == 0
                output(k).iStrategy = 2;
            end
        end

        % win-switch (3)
        if output(k-q).iTrialType == output(k).iTrialType  % within block
            if output(k-q).iCorrect > 0 && output(k).iCorrect == 0
                output(k).iStrategy = 3;
            end
        else    % between blocks (=switch)
            if output(k-q).iCorrect > 0 && output(k).iCorrect > 0
                output(k).iStrategy = 3;
            end
        end

        % lose-repeat (4)
        if output(k-q).iTrialType == output(k).iTrialType   % within block
            if output(k-q).iCorrect == 0 && output(k).iCorrect == 0
                output(k).iStrategy = 4;
            end
        else    % between blocks (=switch)
            if output(k-q).iCorrect == 0 && output(k).iCorrect > 0
                output(k).iStrategy = 4;
            end
        end
    end
end

% add block switches, whether animal choose high reward port, and whether the animal switched
for k=1:n_trials  % per trial

    % BLOCK SWITCH
    if k == 1 % first block is a transition
        output(k).blockSwitch = 1;
    elseif output(k).iBlock ~= output(k-1).iBlock % transition
        output(k).blockSwitch = 1;
    else
        output(k).blockSwitch = 0;
    end

    % HIGH REWARD CHOICE
    if output(k).outcome == 1
        output(k).rewSpout = 1;
    elseif output(k).outcome == 2
        output(k).rewSpout = 0;
    elseif output(k).outcome == 3
        output(k).rewSpout = nan;
    end

    % ANIMAL SWITCH
    if k == 1 % first trial is not a switch
        output(k).animalSwitch = 0;
    elseif output(k).iStrategy == 1 % wr
        output(k).animalSwitch = 0;
    elseif output(k).iStrategy == 2 % ls
        output(k).animalSwitch = 1;
    elseif output(k).iStrategy == 3 % ws
        output(k).animalSwitch = 1;
    elseif output(k).iStrategy == 4 % lr
        output(k).animalSwitch = 0;
    else
        output(k).animalSwitch = nan; % omission
    end

end
