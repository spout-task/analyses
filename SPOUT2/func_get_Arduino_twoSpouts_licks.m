%% twoSpouts tasks get lick data
% dataLick (output) - lick timestamps aligned to cue onset (used to be offset)
% output_raw: licks are binned in trials but not aligned (absolute timestamp!) 
%       use to map onto clock of other systems (WS through sync pulse)  

function [output, output_raw, trial_info, dataEvents] = func_get_Arduino_twoSpouts_licks(dataEvents)

% important info
% a NEW_TRIAL dataEvents{:,5} can still be followed by FREE_REWARD etc
% licks: LickLeft, LickRight

% make sure first trial (nTrial=1) has an outcome (sporadically we see no outcome, then we need to correct nTrial values)
tmp = find(str2double(dataEvents(:, 1)) == 1);
tmp = find(ismember(dataEvents(tmp, 5), 'CONSUMPTION'));
trial_del = 0;
while isempty(tmp) % no outcome
    % update user
    trial_del = trial_del+1;
    disp(['Removed trial ' num2str(trial_del)])

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

    % check if problem is gone
    tmp = find(str2double(dataEvents(:, 1)) == 1);
    tmp = find(ismember(dataEvents(tmp, 5), 'CONSUMPTION'));
end

% double check first trial
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

% make sure second row is a NEW_TRIAL (you can have a lick before)
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
[trial_info(1:n_trials).opto] = deal([]);
% timing for syncing
[trial_info(1:n_trials).trial_start_idx] = deal([]);
[trial_info(1:n_trials).trial_start_time] = deal([]);
[trial_info(1:n_trials).trial_stop_idx] = deal([]);
[trial_info(1:n_trials).trial_stop_time] = deal([]);

% get all structural trial info -> align to cue onset
for k=1:n_trials % per trial
    % general info
    trial_info(k).nTrial = k;
    trial_info(k).events = find(str2double(dataEvents(:, 1)) == k); % find all events in this trial
    trial_info(k).start_idx = trial_info(k).events(1);    % get the trial start

    % timing for syncing - find start of trial - "NEW_TRIAL" starts at end of previous trial in dataEvents matrix
    if ismember(dataEvents(trial_info(k).events(1)-1, 5), 'NEW_TRIAL') == 0 % check for start - sanity check
        error(['No start found for trial: ' num2str(k)])
    end
    % get start to align things to
    trial_info(k).trial_start_idx = trial_info(k).events(1) - 1; % find absolute row value
    trial_info(k).trial_start_time = str2double(dataEvents(trial_info(k).trial_start_idx, 6)) +1; % find timestamp - +1 ms

    % timing for syncing - find stop of trial
    if ismember(dataEvents(trial_info(k).events(end), 5), 'NEW_TRIAL') == 0 % check for stop - sanity check
        if k == n_trials % last trial can get funky
            warning(['No stop found for last trial: ' num2str(k)])
        else
            error(['No stop found for trial: ' num2str(k)])
        end
    end
    % get stop to align things to
    trial_info(k).trial_stop_idx = trial_info(k).events(end); % find absolute row value
    trial_info(k).trial_stop_time = str2double(dataEvents(trial_info(k).trial_stop_idx, 6)); % find timestamp

    % cue onset
    tmp = [find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_LEFT')) ...
        find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_RIGHT'))]; % find cue onset of left or right
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
    tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'SELECTION'));
    % there should always be an choice period
    if isempty(tmp) 
        error(['No selection period found in trial: ' num2str(k)])
    else
        trial_info(k).selection_idx = tmp + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).selection_time = str2double(dataEvents(trial_info(k).selection_idx, 6)); % find timestamp 
    end

    % get choice period
    tmp = [find(ismember(dataEvents(trial_info(k).events, 5), '#_CORRECT_LEFT')) ...
           find(ismember(dataEvents(trial_info(k).events, 5), '#_CORRECT_RIGHT')) ...
           find(ismember(dataEvents(trial_info(k).events, 5), '#_INCORRECT_LEFT')) ...
           find(ismember(dataEvents(trial_info(k).events, 5), '#_INCORRECT_RIGHT')) ...
           find(ismember(dataEvents(trial_info(k).events, 5), '#_TIMEOUT')) ...
           find(ismember(dataEvents(trial_info(k).events, 5), 'Correct LEFT')) ... % old task
           find(ismember(dataEvents(trial_info(k).events, 5), 'Correct RIGHT')) ... % old task
           find(ismember(dataEvents(trial_info(k).events, 5), '# CORRECT LEFT')) ... % old task
           find(ismember(dataEvents(trial_info(k).events, 5), '# CORRECT RIGHT')) ... % old task
           find(ismember(dataEvents(trial_info(k).events, 5), 'Incorrect LEFT')) ... % old task
           find(ismember(dataEvents(trial_info(k).events, 5), 'Incorrect RIGHT')) ... % old task
           find(ismember(dataEvents(trial_info(k).events, 5), '# Incorrect LEFT')) ... % old task
           find(ismember(dataEvents(trial_info(k).events, 5), '# Incorrect RIGHT')) ... % old task
           find(ismember(dataEvents(trial_info(k).events, 5), '# Timeout'))];   % old task
    % there should always be an choice period
    if isempty(tmp) 
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
    if isempty(tmp) % old task -> no consumption after timeout..
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), '# Timeout')); 
        if ~isempty(tmp)
            disp(['Found timeout instead of outcome in trial ' num2str(k)])
        end
    end
    % there should always be an outcome period. 2x outcome if there is a free reward
    if isempty(tmp) 
        error(['No outcome period found in trial: ' num2str(k)])
    else
        trial_info(k).outcome_idx = tmp(1) + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).outcome_time = str2double(dataEvents(trial_info(k).outcome_idx, 6)); % find timestamp 
    end

    % free reward
    tmp = find(ismember(dataEvents(trial_info(k).events, 5), 'FREE_REWARD'));
    if isempty(tmp) % no free reward
        % trial_info(k).free_reward_idx = NaN;
        % trial_info(k).free_reward_time = NaN;
    else % true free reward
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
% iTrial - iTrialType (1:left, 2:right) - outcome (1:reward, 2:error, 3:omission) - 
% t_ITI - leftITI - rightITI - leftChoice - rightChoice - leftOutcome - 
% rightOutcome - leftFree - rightFree
% cells filled with lick timestamps aligned to cue onset
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
% trial info
[output(1:n_trials).iStrategy] = deal([]);
[output(1:n_trials).opto] = deal([]);
% duration of licks
[output(1:n_trials).t_left_ITI] = deal([]);
[output(1:n_trials).t_right_ITI] = deal([]);
[output(1:n_trials).t_left_cue] = deal([]);
[output(1:n_trials).t_right_cue] = deal([]);
[output(1:n_trials).t_left_choice] = deal([]);
[output(1:n_trials).t_right_choice] = deal([]);
[output(1:n_trials).t_left_delay] = deal([]);
[output(1:n_trials).t_right_delay] = deal([]);
[output(1:n_trials).t_left_outcome] = deal([]);
[output(1:n_trials).t_right_outcome] = deal([]);
[output(1:n_trials).t_left_free] = deal([]);
[output(1:n_trials).t_right_free] = deal([]);
% timing for syncing
[output(1:n_trials).trial_start_time] = deal([]);
[output(1:n_trials).trial_stop_time] = deal([]);
% timing of licks
[output(1:n_trials).ITI_start] = deal([]);
[output(1:n_trials).cue_start] = deal([]);
[output(1:n_trials).outcome_start] = deal([]);
[output(1:n_trials).left_ITI] = deal([]);
[output(1:n_trials).right_ITI] = deal([]);
[output(1:n_trials).left_cue] = deal([]);
[output(1:n_trials).right_cue] = deal([]);
[output(1:n_trials).left_choice] = deal([]);
[output(1:n_trials).right_choice] = deal([]);
[output(1:n_trials).left_delay] = deal([]);
[output(1:n_trials).right_delay] = deal([]);
[output(1:n_trials).left_outcome] = deal([]);
[output(1:n_trials).right_outcome] = deal([]);
[output(1:n_trials).left_free] = deal([]);
[output(1:n_trials).right_free] = deal([]);
% reward reaction time and reward-lick ILIs (rewarded trials only, filled in below)
[output(1:n_trials).RT_reward] = deal(NaN);
[output(1:n_trials).ILI_reward] = deal([]);

% output_raw - data not aligned but absolute timing
output_raw = struct;
[output_raw(1:n_trials).nTrial] = deal([]);
[output_raw(1:n_trials).iBlock] = deal([]);
[output_raw(1:n_trials).iTrial] = deal([]);
[output_raw(1:n_trials).iTrialType] = deal([]);
[output_raw(1:n_trials).outcome] = deal([]);
[output_raw(1:n_trials).correct] = deal([]);
[output_raw(1:n_trials).incorrect] = deal([]);
[output_raw(1:n_trials).reward] = deal([]);
[output_raw(1:n_trials).noReward] = deal([]);
[output_raw(1:n_trials).free_reward] = deal([]);
[output_raw(1:n_trials).t_ITI] = deal([]);
% trial info
[output_raw(1:n_trials).iStrategy] = deal([]);
[output_raw(1:n_trials).opto] = deal([]);
% duration of licks
[output_raw(1:n_trials).t_left_ITI] = deal([]);
[output_raw(1:n_trials).t_right_ITI] = deal([]);
[output_raw(1:n_trials).t_left_cue] = deal([]);
[output_raw(1:n_trials).t_right_cue] = deal([]);
[output_raw(1:n_trials).t_left_choice] = deal([]);
[output_raw(1:n_trials).t_right_choice] = deal([]);
[output_raw(1:n_trials).t_left_delay] = deal([]);
[output_raw(1:n_trials).t_right_delay] = deal([]);
[output_raw(1:n_trials).t_left_outcome] = deal([]);
[output_raw(1:n_trials).t_right_outcome] = deal([]);
[output_raw(1:n_trials).t_left_free] = deal([]);
[output_raw(1:n_trials).t_right_free] = deal([]);
% timing for syncing
[output_raw(1:n_trials).trial_start_time] = deal([]);
[output_raw(1:n_trials).trial_stop_time] = deal([]);
% timing of licks
[output_raw(1:n_trials).ITI_start] = deal([]);
[output_raw(1:n_trials).cue_start] = deal([]);
[output_raw(1:n_trials).outcome_start] = deal([]);
[output_raw(1:n_trials).left_ITI] = deal([]);
[output_raw(1:n_trials).right_ITI] = deal([]);
[output_raw(1:n_trials).left_cue] = deal([]);
[output_raw(1:n_trials).right_cue] = deal([]);
[output_raw(1:n_trials).left_choice] = deal([]);
[output_raw(1:n_trials).right_choice] = deal([]);
[output_raw(1:n_trials).left_delay] = deal([]);
[output_raw(1:n_trials).right_delay] = deal([]);
[output_raw(1:n_trials).left_outcome] = deal([]);
[output_raw(1:n_trials).right_outcome] = deal([]);
[output_raw(1:n_trials).left_free] = deal([]);
[output_raw(1:n_trials).right_free] = deal([]);

% fill in trial details
for k=1:n_trials % per trial
    % trial vars
    output(k).nTrial = str2double(dataEvents(trial_info(k).start_idx, 1)); % nTrial
    output(k).iBlock = str2double(dataEvents(trial_info(k).start_idx, 2)); % iBlock
    output(k).iTrial = str2double(dataEvents(trial_info(k).start_idx, 3)); % iTrial
    output(k).free_reward = 0; % assign a 0 here, so that free reward can assign a 1 later on

    % add cue so we always know how things got aligned - multiple cues possible
    tmp = [find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_LEFT')) ...
        find(ismember(dataEvents(trial_info(k).events, 5), 'CUE_RIGHT'))]; % find cue onset of left or right
    tmp = tmp + trial_info(k).events(1) - 1; % find absolute row value
    output(k).cue_start = str2double(dataEvents(tmp, 6)) - trial_info(k).cue_time; % store cue timestamp(s)

    % add outcome (CONSUMPTION) onset so we can calculate reward reaction time
    output(k).outcome_start = trial_info(k).outcome_time - trial_info(k).cue_time;

    % timing for syncing
    output(k).trial_start_time = trial_info(k).trial_start_time;
    output(k).trial_stop_time = trial_info(k).trial_stop_time;

    % old vs new way and either with or without TrialStart_ON variable
    if (strcmp(dataEvents{trial_info(k).start_idx+1, 5}, 'ITI_LEFT') | strcmp(dataEvents{trial_info(k).start_idx+1, 5}, 'ENL_LEFT')) % iTrialType
        output(k).iTrialType = 1;
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx+1, 7)); % t_ITI
    elseif (strcmp(dataEvents{trial_info(k).start_idx, 5}, 'ITI_LEFT') | strcmp(dataEvents{trial_info(k).start_idx, 5}, 'ENL_LEFT')) % iTrialType - old task (no TrialStart_ON)
        output(k).iTrialType = 1;
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx, 7)); % t_ITI
        % right
    elseif strcmp(dataEvents{trial_info(k).start_idx+1, 5}, 'ITI_RIGHT') | strcmp(dataEvents{trial_info(k).start_idx+1, 5}, 'ENL_RIGHT') % iTrialType
        output(k).iTrialType = 2;
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx+1, 7)); % t_ITI
    elseif strcmp(dataEvents{trial_info(k).start_idx, 5}, 'ITI_RIGHT') | strcmp(dataEvents{trial_info(k).start_idx, 5}, 'ENL_RIGHT') % iTrialType - old task (no TrialStart_ON)
        output(k).iTrialType = 2;
        output(k).t_ITI = str2double(dataEvents(trial_info(k).start_idx, 7)); % t_ITI
    else
        error(['Unclear what trial this is: ' num2str(k)])
    end

    % figure out trial outcome
    if ~isempty(find([ismember(dataEvents(trial_info(k).events, 5), '#_TIMEOUT') ... % omission
                      ismember(dataEvents(trial_info(k).events, 5), '# Timeout')])) % old task
        output(k).outcome = 3;
        output(k).correct = 0;
        output(k).incorrect = 1;
        output(k).reward = 0;
        output(k).noReward = 1;
    elseif ~isempty(cell2mat([strfind(dataEvents(trial_info(k).events, 5), 'INCORRECT') ... % error
                              strfind(dataEvents(trial_info(k).events, 5), 'Incorrect')])) % old task
        output(k).outcome = 2;
        output(k).correct = 0;
        output(k).incorrect = 1;
        output(k).reward = 0;
        output(k).noReward = 1;
    elseif ~isempty(cell2mat(strfind(dataEvents(trial_info(k).events, 5), 'CORRECT'))) % correct - IMPORTANT, 'INCORRECT' would be a match substring so run elseif after 'INCORRECT'
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
    else
        disp(['could not find trial outcome for trial: ' num2str(k)])
        output(k).outcome = NaN;
    end
    
    % find free reward
    if ~isempty(find(ismember(dataEvents(trial_info(k).events, 5), 'FREE_REWARD'))) % free reward
        output(k).free_reward = 1;
    end

    % find timestamp of ITI start (first ENL) in respect to cue onset
    ITI_onset = ([ [(find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_LEFT'))) (find(ismember(dataEvents(trial_info(k).events, 5), 'ENL_LEFT')))] ...
                   [(find(ismember(dataEvents(trial_info(k).events, 5), 'ITI_RIGHT'))) (find(ismember(dataEvents(trial_info(k).events, 5), 'ENL_RIGHT')))] ] + ...
                     trial_info(k).start_idx - 1); % find ITI start and add NEW_TRIAL time (start_idx - 1) (old task included)
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
    tmp_left = find(ismember(dataEvents(trial_info(k).events, 5), 'LickLeft')) + trial_info(k).start_idx - 1; % find left licks
    tmp_right = find(ismember(dataEvents(trial_info(k).events, 5), 'LickRight')) + trial_info(k).start_idx - 1; % find right licks

    % LEFT LICKS
    for kk=tmp_left'
        % discard licks with no duration
        if str2double(dataEvents(kk, 7)) == 0
            % do nothing
            disp(['Left lick dropped: has no duration. Trial: ' num2str(k) ' - Lick: ' num2str(kk)])
            % if lick is the last event in file, it's outside task anyway so delete
        elseif kk == size(dataEvents,1)
            disp('Left Lick dropped: last event')

            % ITI lick (lick before cue onset)
        elseif str2double(dataEvents(kk, 6)) <= trial_info(k).cue_time
            output(k).left_ITI(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_left_ITI(1, end+1) = str2double(dataEvents(kk, 7));

            % cue lick (lick after cue onset but before cue onset)
        elseif str2double(dataEvents(kk, 6)) > trial_info(k).cue_time && ...
                str2double(dataEvents(kk, 6)) < trial_info(k).cue_time + str2double(dataEvents(trial_info(k).cue_idx, 7))
            output(k).left_cue(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_left_cue(1, end+1) = str2double(dataEvents(kk, 7));

            % choice lick (before delay/outcome/free)
        elseif (isempty(trial_info(k).delay_time) || str2double(dataEvents(kk, 6)) < trial_info(k).delay_time) && ...
                (isempty(trial_info(k).outcome_time) || str2double(dataEvents(kk, 6)) <= trial_info(k).outcome_time) && ... % outcome_time has to be <= as error lick aligns with CONSUMPTION
                (isempty(trial_info(k).free_reward_time) || str2double(dataEvents(kk, 6)) < trial_info(k).free_reward_time) && ...
                isempty(output(k).left_choice) % a super fast choice lick + fast outcome lick can happen before CONSUMPTION state starts
            output(k).left_choice(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_left_choice(1, end+1) = str2double(dataEvents(kk, 7));

            % delay lick (before outcome/free)
        elseif (isempty(trial_info(k).outcome_time) || str2double(dataEvents(kk, 6)) < trial_info(k).outcome_time) && ...
                (isempty(trial_info(k).free_reward_time) || str2double(dataEvents(kk, 6)) < trial_info(k).free_reward_time)
            output(k).left_delay(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_left_delay(1, end+1) = str2double(dataEvents(kk, 7));

            % outcome lick (before free)
        elseif (isempty(trial_info(k).free_reward_time) || str2double(dataEvents(kk, 6)) < trial_info(k).free_reward_time)
            output(k).left_outcome(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_left_outcome(1, end+1) = str2double(dataEvents(kk, 7));

            % free reward lick (also works for random reward trial Pavlovian task)
        elseif str2double(dataEvents(kk, 6)) >= trial_info(k).free_reward_time
            output(k).left_free(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_left_free(1, end+1) = str2double(dataEvents(kk, 7));

            % if we can't assign a lick, throw an error
        else
            error(['could not assign a left lick in trial: ' num2str(k) ', lick: ' num2str(kk)])
        end
    end

    % RIGHT LICKS
    for kk=tmp_right'
        % discard licks with no duration
        if str2double(dataEvents(kk, 7)) == 0
            % do nothing
            disp(['Right lick dropped: has no duration. Trial: ' num2str(k) ' - Lick: ' num2str(kk)])
            % if lick is the last event in file, it's outside task anyway so delete
        elseif kk == size(dataEvents,1)
            disp('Right Lick dropped: last event')

            % ITI lick (lick before cue onset)
        elseif str2double(dataEvents(kk, 6)) <= trial_info(k).cue_time
            output(k).right_ITI(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_right_ITI(1, end+1) = str2double(dataEvents(kk, 7));

            % cue lick (lick after cue onset but before cue onset)
        elseif str2double(dataEvents(kk, 6)) > trial_info(k).cue_time && ...
                str2double(dataEvents(kk, 6)) < trial_info(k).cue_time + str2double(dataEvents(trial_info(k).cue_idx, 7))
            output(k).right_cue(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_right_cue(1, end+1) = str2double(dataEvents(kk, 7));

            % choice lick (before delay/outcome/free)
        elseif (isempty(trial_info(k).delay_time) || str2double(dataEvents(kk, 6)) < trial_info(k).delay_time) && ...
                (isempty(trial_info(k).outcome_time) || str2double(dataEvents(kk, 6)) <= trial_info(k).outcome_time) && ... % outcome_time has to be <= as error lick aligns with CONSUMPTION
                (isempty(trial_info(k).free_reward_time) || str2double(dataEvents(kk, 6)) < trial_info(k).free_reward_time) && ...
                isempty(output(k).right_choice) % a super fast choice lick + fast outcome lick can happen before CONSUMPTION state starts
            output(k).right_choice(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_right_choice(1, end+1) = str2double(dataEvents(kk, 7));

            % delay lick (before outcome/free)
        elseif (isempty(trial_info(k).outcome_time) || str2double(dataEvents(kk, 6)) < trial_info(k).outcome_time) && ...
                (isempty(trial_info(k).free_reward_time) || str2double(dataEvents(kk, 6)) < trial_info(k).free_reward_time)
            output(k).right_delay(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_right_delay(1, end+1) = str2double(dataEvents(kk, 7));

            % outcome lick (before free)
        elseif (isempty(trial_info(k).free_reward_time) || str2double(dataEvents(kk, 6)) < trial_info(k).free_reward_time)
            output(k).right_outcome(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_right_outcome(1, end+1) = str2double(dataEvents(kk, 7));

            % free reward lick (also works for random reward trial Pavlovian task)
        elseif str2double(dataEvents(kk, 6)) >= trial_info(k).free_reward_time
            output(k).right_free(1, end+1) = str2double(dataEvents(kk, 6)) - trial_info(k).cue_time;
            output(k).t_right_free(1, end+1) = str2double(dataEvents(kk, 7));

            % if we can't assign a lick, throw an error
        else
            error(['could not assign a right lick in trial: ' num2str(k) ', lick: ' num2str(kk)])
        end
    end

end

% reward reaction time (RT_reward) and inter-lick intervals of reward licks (ILI_reward) - rewarded trials only
% RT_reward = first lick on the rewarded spout after outcome (CONSUMPTION) onset, ILI_reward = diff of all licks on the rewarded spout during outcome
% stored here so session data and opto plots use the exact same numbers (used to be calculated in func_get_Arduino_twoSpouts_session)
for k=1:n_trials % per trial
    if output(k).reward == 1 % rewarded trial
        if output(k).iTrialType == 1 % left
            tmp = output(k).left_outcome;
        else % right
            tmp = output(k).right_outcome;
        end
        if ~isempty(tmp) % animal licked for reward
            output(k).RT_reward = tmp(1) - output(k).outcome_start;
            output(k).ILI_reward = diff(tmp);
        end
    end
end

% remap to absolute time - output_raw
% output_raw - data not aligned but absolute timing
[output_raw(1:n_trials).nTrial] = deal(output.nTrial);
[output_raw(1:n_trials).iBlock] = deal(output.iBlock);
[output_raw(1:n_trials).iTrial] = deal(output.iTrial);
[output_raw(1:n_trials).iTrialType] = deal(output.iTrialType);
[output_raw(1:n_trials).outcome] = deal(output.outcome);
[output_raw(1:n_trials).correct] = deal(output.correct);
[output_raw(1:n_trials).incorrect] = deal(output.incorrect);
[output_raw(1:n_trials).reward] = deal(output.reward);
[output_raw(1:n_trials).noReward] = deal(output.noReward);
[output_raw(1:n_trials).free_reward] = deal(output.free_reward);
[output_raw(1:n_trials).t_ITI] = deal(output.t_ITI);
% licking duration
[output_raw(1:n_trials).t_left_ITI] = deal(output.t_left_ITI);
[output_raw(1:n_trials).t_right_ITI] = deal(output.t_right_ITI);
[output_raw(1:n_trials).t_left_cue] = deal(output.t_left_cue);
[output_raw(1:n_trials).t_right_cue] = deal(output.t_right_cue);
[output_raw(1:n_trials).t_left_choice] = deal(output.t_left_choice);
[output_raw(1:n_trials).t_right_choice] = deal(output.t_right_choice);
[output_raw(1:n_trials).t_left_delay] = deal(output.t_left_delay);
[output_raw(1:n_trials).t_right_delay] = deal(output.t_right_delay);
[output_raw(1:n_trials).t_left_outcome] = deal(output.t_left_outcome);
[output_raw(1:n_trials).t_right_outcome] = deal(output.t_right_outcome);
[output_raw(1:n_trials).t_left_free] = deal(output.t_left_free);
[output_raw(1:n_trials).t_right_free] = deal(output.t_right_free);
% timing for syncing
[output_raw(1:n_trials).trial_start_time] = deal(output.trial_start_time);
[output_raw(1:n_trials).trial_stop_time] = deal(output.trial_stop_time);

% remapping timing
for k=1:size(output_raw,2) % per trial
    output_raw(k).ITI_start = output(k).ITI_start + trial_info(k).cue_time;
    output_raw(k).cue_start = output(k).cue_start + trial_info(k).cue_time;
    output_raw(k).outcome_start = output(k).outcome_start + trial_info(k).cue_time;
    output_raw(k).left_ITI = output(k).left_ITI + trial_info(k).cue_time;
    output_raw(k).right_ITI = output(k).right_ITI + trial_info(k).cue_time;
    output_raw(k).left_cue = output(k).left_cue + trial_info(k).cue_time;
    output_raw(k).right_cue = output(k).right_cue + trial_info(k).cue_time;
    output_raw(k).left_choice = output(k).left_choice + trial_info(k).cue_time;
    output_raw(k).right_choice = output(k).right_choice + trial_info(k).cue_time;
    output_raw(k).left_delay = output(k).left_delay + trial_info(k).cue_time;
    output_raw(k).right_delay = output(k).right_delay + trial_info(k).cue_time;
    output_raw(k).left_outcome = output(k).left_outcome + trial_info(k).cue_time;
    output_raw(k).right_outcome = output(k).right_outcome + trial_info(k).cue_time;
    output_raw(k).left_free = output(k).left_free + trial_info(k).cue_time;
    output_raw(k).right_free = output(k).right_free + trial_info(k).cue_time;
end

end