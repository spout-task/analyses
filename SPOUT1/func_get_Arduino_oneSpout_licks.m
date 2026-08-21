%% oneSpout tasks get lick data
% dataLick - lick timestamps aligned to cue onset

function [output, trial_info, dataEvents] = func_get_Arduino_oneSpout_licks(dataEvents, sessionInfo)

% important info
% a NEW_TRIAL dataEvents{:,5} can still be followed by FREE_REWARD etc


% make sure first trial (nTrial=1) has an outcome (sporadically we see no outcome, then we need to correct nTrial values)
tmp = find(str2double(dataEvents(:, 1)) == 1);
tmp = find(ismember(dataEvents(tmp, 5), 'CONSUMPTION'));
if isempty(tmp) % no outcome
    % delete trial 0 rows
    tmp = find(str2double(dataEvents(:, 1)) == 0);
    dataEvents(tmp, :) = [];

    % find last iTrial to change
    tmp = find(diff(str2double(dataEvents(:, 3))) < 0);
    last_iTrial_change = tmp(1) + 1;
    % adjust nTrial and iTrial if needed
    for k=2:size(dataEvents,1) % first value = "nTrial"
        % change ntrial
        dataEvents{k,1} = num2str(str2double(dataEvents{k,1}) - 1);
        % change iTrial
        if k < last_iTrial_change
            dataEvents{k,3} = num2str(str2double(dataEvents(k,3)) - 1);
        end
    end
end

% make sure second row is a NEW_TRIAL (you can have a lick before trial starts)
while isempty(cell2mat(strfind(dataEvents(2, 5), 'NEW_TRIAL')))
    dataEvents(2,:) = [];
end

% if last trial has only 0's (emergency stop), delete it
if str2double(dataEvents(end,1)) == 0
    tmp = find(str2double(dataEvents(:,1)) == 0);
    if tmp(1) == 2 % don't remove starting block
        tmp(1) = [];
    end
    dataEvents(tmp,:) = [];
end

% delete last trial (either IDLE or half a trial if you hit emergency stop)
tmp = find(str2double(dataEvents(:,1)) == str2double(dataEvents{end, 1}));
dataEvents(tmp,:) = [];
n_trials = str2double(dataEvents{end, 1});

% store some vars
trial_info = struct;
[trial_info(1:n_trials).nTrial] = deal([]);
[trial_info(1:n_trials).iBlock] = deal([]);
[trial_info(1:n_trials).iTrial] = deal([]);
[trial_info(1:n_trials).iTrialType] = deal([]);
[trial_info(1:n_trials).t_ITI] = deal([]);
[trial_info(1:n_trials).outcome] = deal([]);
[trial_info(1:n_trials).free_reward] = deal([]);
[trial_info(1:n_trials).start_idx] = deal([]);
[trial_info(1:n_trials).cue_idx] = deal([]);
[trial_info(1:n_trials).cue_time] = deal([]);
[trial_info(1:n_trials).selection_idx] = deal([]);
[trial_info(1:n_trials).selection_time] = deal([]);
[trial_info(1:n_trials).choice_idx] = deal([]);
[trial_info(1:n_trials).choice_time] = deal([]);
[trial_info(1:n_trials).delay_idx] = deal([]);
[trial_info(1:n_trials).delay_time] = deal([]);
[trial_info(1:n_trials).outcome_idx] = deal([]);
[trial_info(1:n_trials).outcome_time] = deal([]);
[trial_info(1:n_trials).free_reward_idx] = deal([]);
[trial_info(1:n_trials).free_reward_time] = deal([]);
[trial_info(1:n_trials).events] = deal([]);
% timing for syncing
[trial_info(1:n_trials).timing_start_idx] = deal([]);
[trial_info(1:n_trials).timing_start_time] = deal([]);
[trial_info(1:n_trials).timing_stop_idx] = deal([]);
[trial_info(1:n_trials).timing_stop_time] = deal([]);

% get all structural trial info -> align to cue onset
for k=1:n_trials % per trial
    % general info
    trial_info(k).nTrial = k;
    trial_info(k).events = find(str2double(dataEvents(:, 1)) == k); % find all events in this trial
    trial_info(k).start_idx = trial_info(k).events(1);    % get the trial start

    % timing for syncing - find start of trial - "NEW_TRIAL" starts at end of previous trial in dataEvents matrix
    tmp = find(ismember(dataEvents(trial_info(k).events(1)-1, 5), 'NEW_TRIAL')); % find start
    % there should always be a start
    if isempty(tmp)
        error(['No start found for trial: ' num2str(k)])
    end
    % get stop to align things to
    trial_info(k).timing_start_idx = tmp + trial_info(k).events(1) - 1; % find absolute row value
    trial_info(k).timing_start_time = str2double(dataEvents(trial_info(k).timing_start_idx, 6)); % find timestamp

    % timing for syncing - find stop of trial
    tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'NEW_TRIAL')); % find stop
    % there should always be a start
    if isempty(tmp)
        error(['No stop found for trial: ' num2str(k)])
    end
    % get stop to align things to
    trial_info(k).timing_stop_idx = tmp + trial_info(k).events(1) - 1; % find absolute row value
    trial_info(k).timing_stop_time = str2double(dataEvents(trial_info(k).timing_stop_idx, 6)); % find timestamp

    % cue onset
    tmp = [find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_A')) ...
           find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_B')) ...
           find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_RR'))]; % find cue onset of A or B or RR (random reward)
    % there should always be a cue
    if isempty(tmp)
        error(['No cue found in trial: ' num2str(k)])
    end
    % only take last cue onset (can have multiple in case of cue penalties)
    tmp = tmp(end);
    % get cue to align things to
    trial_info(k).cue_idx = tmp + trial_info(k).events(1) - 1; % find absolute row value
    trial_info(k).cue_time = str2double(dataEvents(trial_info(k).cue_idx, 6)); % find timestamp

    % get selection period
    if sessionInfo.taskPavlovian == 1 % pavlovian doesn't have SELECTION
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'CONSUMPTION')); % Pavlovian task does not give a SELECTION, but immediately goes to CONSUMPTION
    else
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'SELECTION'));
    end
    % there should always be an choice period
    if isempty(tmp) 
        error(['No selection period found in trial: ' num2str(k)])
    else
        trial_info(k).selection_idx = tmp + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).selection_time = str2double(dataEvents(trial_info(k).selection_idx, 6)); % find timestamp 
    end

    % get choice period
    if sessionInfo.taskPavlovian == 1 % pavlovian does not have a choice lick, so take the first lick
        tmp_cons = find(ismember(dataEvents(trial_info(k).events, 5), 'CONSUMPTION'));
        tmp = find(ismember(dataEvents(trial_info(k).events(tmp_cons:end), 5), 'Lick')) + tmp_cons-1; % find licks after consumption
        if ~isempty(tmp) % there is at least a lick, get the first lick
            tmp = tmp(1);
        end
    else
        tmp = [find(ismember(dataEvents(trial_info(k).events, 5), '#_CORRECT')) ...
            find(ismember(dataEvents(trial_info(k).events, 5), '#_INCORRECT')) ...
            find(ismember(dataEvents(trial_info(k).events, 5), '#_TIMEOUT'))];
    end
    % there should always be an choice period
    if sessionInfo.taskPavlovian == 1 & isempty(tmp) % Pavlovian (so a lick is not required) AND no lick, so use max consumption time    strcmp(dataEvents(trial_info(k).cue_idx, 5), 'CUE_RR')
        trial_info(k).choice_idx = []; % find absolute row value
        trial_info(k).choice_time = trial_info(k).selection_time + str2double(dataEvents(trial_info(k).events(tmp_cons), 7)); % find timestamp
    elseif isempty(tmp)
        error(['No choice period found in trial: ' num2str(k)])
    else
        trial_info(k).choice_idx = tmp + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).choice_time = str2double(dataEvents(trial_info(k).choice_idx, 6)); % find timestamp
    end

    % get delay period
    tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'REWARD_DELAY'));
    if isempty(tmp)
    else
        trial_info(k).delay_idx = tmp + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).delay_time = str2double(dataEvents(trial_info(k).delay_idx, 6)); % find timestamp 
    end

    % get outcome start
    tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'CONSUMPTION'));
    % there should always be an outcome period. 2x outcome if there is a free reward
    if isempty(tmp) 
        error(['No outcome period found in trial: ' num2str(k)])
    else
        trial_info(k).outcome_idx = tmp(1) + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).outcome_time = str2double(dataEvents(trial_info(k).outcome_idx, 6)); % find timestamp 
    end

    % free reward - true free reward if animal is bad or random reward (Pavlovian task)
    tmp1 = find(ismember(dataEvents(trial_info(k).events, 5), 'FREE_REWARD'));
    tmp2 = find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_RR'));
    if isempty(tmp1) && isempty(tmp2) % no free reward
        % trial_info(k).free_reward_idx = NaN;
        % trial_info(k).free_reward_time = NaN;
    elseif isempty(tmp2) % true free reward
        trial_info(k).free_reward_idx = tmp1 + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).free_reward_time = str2double(dataEvents(trial_info(k).free_reward_idx, 6)); % find timestamp 
    elseif isempty(tmp1) % random reward
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'REWARD')); % find reward delivery
        trial_info(k).free_reward_idx = tmp + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).free_reward_time = str2double(dataEvents(trial_info(k).free_reward_idx, 6)); % find timestamp 
    end
end

% make sure n_trials equals cue onsets
if n_trials ~= length([trial_info(:).cue_idx])
    % if not, remove the second to last trial from dataEvents (can be an empty trial in some cases)
    if (n_trials -1) == length([trial_info(:).cue_idx])
        trial_info(:,n_trials) = [];
        n_trials = n_trials - 1;
    else
        error('n_trials does not match number of cues')
    end
end

% make struct with rows = trials (nTrials), columns = nTrial - iBlock -
% iTrial - iTrialType (1:A, 2:B, 3:RR) - outcome (1:reward, 2:error, 3:omission) -
% correct (0:no, 1:yes) - licks
% cells filled with lick timestamps aligned to cue onset and lick duration
output = struct;
[output(1:n_trials).nTrial] = deal([]);
[output(1:n_trials).iBlock] = deal([]);
[output(1:n_trials).iTrial] = deal([]);
[output(1:n_trials).iTrialType] = deal([]);
[output(1:n_trials).outcome] = deal([]);
[output(1:n_trials).correct] = deal([]);
[output(1:n_trials).incorrect] = deal([]);
[output(1:n_trials).reward] = deal([]);
[output(1:n_trials).noReward] = deal([]);
[output(1:n_trials).free_reward] = deal([]);
[output(1:n_trials).t_ITI] = deal([]);
[output(1:n_trials).ITI_start] = deal([]);
[output(1:n_trials).lick_ITI] = deal([]);
[output(1:n_trials).lick_cue] = deal([]);
[output(1:n_trials).lick_choice] = deal([]);
[output(1:n_trials).lick_delay] = deal([]);
[output(1:n_trials).lick_outcome] = deal([]);
[output(1:n_trials).lick_free] = deal([]);
[output(1:n_trials).t_lick_ITI] = deal([]);
[output(1:n_trials).t_lick_cue] = deal([]);
[output(1:n_trials).t_lick_choice] = deal([]);
[output(1:n_trials).t_lick_delay] = deal([]);
[output(1:n_trials).t_lick_outcome] = deal([]);
[output(1:n_trials).t_lick_free] = deal([]);
% timing for syncing
[output(1:n_trials).timing_start_time] = deal([]);
[output(1:n_trials).timing_stop_time] = deal([]);

% fill in trial details
for k=1:n_trials % per trial
    output(k).nTrial = str2double(dataEvents(trial_info(k).start_idx, 1)); % nTrial
    output(k).iBlock = str2double(dataEvents(trial_info(k).start_idx, 2)); % iBlock
    output(k).iTrial = str2double(dataEvents(trial_info(k).start_idx, 3)); % iTrial
    output(k).free_reward = 0; % assign a 0 here, so that both random reward and free reward can assign a 1 later on

    % timing for syncing
    output(k).timing_start_time = trial_info(k).timing_start_time;
    output(k).timing_stop_time = trial_info(k).timing_stop_time;

    % start_idx is TrialStart_ON, +1 is ITI_A or B
    if strcmp(dataEvents{trial_info(k).start_idx+1, 5}, 'ITI_A') % iTrialType
        output(k).iTrialType = 1;
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx+1, 7)); % t_ITI
    elseif strcmp(dataEvents{trial_info(k).start_idx+1, 5}, 'ITI_B') % iTrialType
        output(k).iTrialType = 2;
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx+1, 7)); % t_ITI
    elseif strcmp(dataEvents{trial_info(k).start_idx+1, 5}, 'ITI_RR') % iTrialType
        output(k).iTrialType = 3;
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx+1, 7)); % t_ITI
    else
        error(['Unclear what trial this is: ' num2str(k)])
    end

    % figure out trial outcome
    if ~isempty(find(ismember(dataEvents(trial_info(k).events, 5), '#_TIMEOUT'))) % omission
        output(k).outcome = 3;
        output(k).correct = 0;
        output(k).incorrect = 1;
        output(k).reward = 0;
        output(k).noReward = 1;
    elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), '#_INCORRECT'))) % error
        output(k).outcome = 2;
        output(k).correct = 0;
        output(k).incorrect = 1;
        output(k).reward = 0;
        output(k).noReward = 1;
    elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), '#_CORRECT'))) % correct
        output(k).outcome = 1;
        output(k).correct = 1;
        output(k).incorrect = 0;
        % check if animal actually got reward or not
        if ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'NO_REWARD'))) % not rewarded
            output(k).reward = 0;
            output(k).noReward = 1;
        elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'REWARD'))) % rewarded
            output(k).reward = 1;
            output(k).noReward = 0;
        end
    elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), '#_RANDOM_REWARD'))) % Pavlovian conditioning
        output(k).outcome = 4;
        output(k).correct = 0;
        output(k).incorrect = 0;
        output(k).reward = 1;
        output(k).noReward = 0;
        output(k).free_reward = 1;
    else
        disp(['could not find trial outcome for trial: ' num2str(k)])
        output(k).outcome = NaN;
    end

    % find free reward
    if ~isempty(find(ismember(dataEvents(trial_info(k).events, 5), 'FREE_REWARD'))) % free reward
        output(k).free_reward = 1;
    end

    % find timestamp of ITI start (first ENL) in respect to cue onset
    ITI_onset = ([(find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_A'))) ...
                  (find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_B'))) ...
                  (find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_RR')))] + ...
                   trial_info(k).start_idx - 1); % find ITI start and add NEW_TRIAL time (start_idx - 1)
    output(k).ITI_start = str2double(dataEvents(ITI_onset, 6)) - trial_info(k).cue_time;

    % add to trial_info so we can carry over to next function
    trial_info(k).iBlock = output(k).iBlock;
    trial_info(k).iTrial = output(k).iTrial;
    trial_info(k).iTrialType = output(k).iTrialType;
    trial_info(k).t_ITI = output(k).t_ITI;
    trial_info(k).outcome = output(k).outcome;
    trial_info(k).free_reward = output(k).free_reward;
end

% find and assign all licks, relative to cue onset
for k=1:n_trials % per trial
    % now find all licks
    tmp_lick = find(ismember(dataEvents(trial_info(k).events, 5), 'Lick')) + trial_info(k).start_idx - 1; % find all licks

    % assign each lick
    for kk=tmp_lick'
        % discard licks with no duration
        if str2double(dataEvents(kk, 7)) == 0
            % do nothing
            disp(['Lick dropped: has no duration. Trial: ' num2str(k) ' - Lick: ' num2str(kk)])
        % if lick is the last event in file, it's outside task anyway so delete
        elseif kk == size(dataEvents,1)
            disp('Lick dropped: last event')

        % ITI lick (lick before cue onset)
        elseif str2double(dataEvents(kk, 6)) <= trial_info(k).cue_time
            output(k).lick_ITI(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_lick_ITI(1, end+1) = str2double(dataEvents(kk, 7));

        % cue lick (lick after cue onset but before cue onset)
        elseif str2double(dataEvents(kk, 6)) > trial_info(k).cue_time && ...
               str2double(dataEvents(kk, 6)) < trial_info(k).cue_time + str2double(dataEvents(trial_info(k).cue_idx, 7))
            output(k).lick_cue(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_lick_cue(1, end+1) = str2double(dataEvents(kk, 7));        
        
        % choice lick (before delay/outcome/free)
        elseif (isempty(trial_info(k).delay_time) || str2double(dataEvents(kk, 6)) < trial_info(k).delay_time) && ...
               (isempty(trial_info(k).outcome_time) || str2double(dataEvents(kk, 6)) < trial_info(k).outcome_time) && ...
               (isempty(trial_info(k).free_reward_time) || str2double(dataEvents(kk, 6)) < trial_info(k).free_reward_time)
            output(k).lick_choice(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_lick_choice(1, end+1) = str2double(dataEvents(kk, 7));

        % delay lick (before outcome/free)
        elseif (isempty(trial_info(k).outcome_time) || str2double(dataEvents(kk, 6)) < trial_info(k).outcome_time) && ...
               (isempty(trial_info(k).free_reward_time) || str2double(dataEvents(kk, 6)) < trial_info(k).free_reward_time)
            output(k).lick_delay(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_lick_delay(1, end+1) = str2double(dataEvents(kk, 7));

        % outcome lick (before free)
        elseif (isempty(trial_info(k).free_reward_time) || str2double(dataEvents(kk, 6)) < trial_info(k).free_reward_time)
            output(k).lick_outcome(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_lick_outcome(1, end+1) = str2double(dataEvents(kk, 7));

        % free reward lick (also works for random reward trial Pavlovian task)
        elseif str2double(dataEvents(kk, 6)) >= trial_info(k).free_reward_time
            output(k).lick_free(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_lick_free(1, end+1) = str2double(dataEvents(kk, 7));

        % if we can't assign a lick, throw an error
        else
            error(['could not assign a lick in trial: ' num2str(k) ', lick: ' num2str(kk)])
        end
    end
end

end