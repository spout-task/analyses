%% oneSpout tasks get lick data
% dataLick (output) - lick timestamps aligned to cue onset
% output_raw: licks are binned in trials but not aligned (absolute timestamp on the Teensy clock, ms)
%       use to map onto clock of other systems (FLIPR through the external sync pulse)
% outcome (all tasks): first REWARD, NO_REWARD or CONSUMPTION row of the trial = valve opening, or the error/timeout
%       decision when there is no reward stage (checked in teensy1spout.ino, all four tasks). Pavlovian: selection and choice
%       also use REWARD or NO_REWARD, not CONSUMPTION

function [output, output_raw, trial_info, dataEvents] = func_get_Arduino_oneSpout_licks(dataEvents, sessionInfo)

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
[trial_info(1:n_trials).cue_all_idx] = deal([]);      % all go cue rows of the trial (repeats after cue penalties)
[trial_info(1:n_trials).stop_cue_idx] = deal([]);     % stop task: stop cue row (CUE_B during SELECTION)
[trial_info(1:n_trials).stop_cue_time] = deal(NaN);
[trial_info(1:n_trials).selection_idx] = deal([]);
[trial_info(1:n_trials).selection_time] = deal([]);
[trial_info(1:n_trials).choice_idx] = deal([]);
[trial_info(1:n_trials).choice_time] = deal([]);
[trial_info(1:n_trials).delay_idx] = deal([]);
[trial_info(1:n_trials).delay_time] = deal([]);
[trial_info(1:n_trials).outcome_idx] = deal([]);
[trial_info(1:n_trials).outcome_time] = deal([]);
[trial_info(1:n_trials).outcome_event] = deal([]);
[trial_info(1:n_trials).free_reward_idx] = deal([]);
[trial_info(1:n_trials).free_reward_time] = deal([]);
[trial_info(1:n_trials).events] = deal([]);
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

    % timing for syncing - find start of trial - "NEW_TRIAL" starts at end of previous trial in dataEvents matrix (as SPOUT2)
    if ismember(dataEvents(trial_info(k).events(1)-1, 5), 'NEW_TRIAL') == 0 % check for start - sanity check
        error(['No start found for trial: ' num2str(k)])
    end
    % get start to align things to - NEW_TRIAL shares its ms with the ITI onset, +1 ms as SPOUT2
    trial_info(k).trial_start_idx = trial_info(k).events(1) - 1; % find absolute row value
    trial_info(k).trial_start_time = str2double(dataEvents(trial_info(k).trial_start_idx, 6)) + 1; % find timestamp - +1 ms

    % timing for syncing - find stop of trial - last row of the trial is the next NEW_TRIAL (as SPOUT2)
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

    % cue onset - go cue = cue rows before SELECTION (teensy1spout.ino: the stop task logs its stop cue as a
    % second CUE_B row DURING SELECTION; that one is stored as stop cue, never used to align)
    tmp_cues = find(ismember(dataEvents(trial_info(k).events, 5), {'CUE_A', 'CUE_B', 'CUE_RR'})); % cue onsets of A or B or RR (random reward)
    tmp_sel = find(ismember(dataEvents(trial_info(k).events, 5), 'SELECTION'), 1); % Pavlovian has no SELECTION: all cues are go cues
    tmp_stop = [];
    if ~isempty(tmp_sel)
        tmp_stop = tmp_cues(tmp_cues > tmp_sel); % stop cue (stop task block B only)
        tmp_cues = tmp_cues(tmp_cues < tmp_sel);
    end
    % there should always be a cue
    if isempty(tmp_cues)
        error(['No cue found in trial: ' num2str(k)])
    end
    % at most one stop cue per trial (the Teensy plays it once)
    if numel(tmp_stop) > 1
        error('pavlovian:stopCue', ['Trial ' num2str(k) ' has ' num2str(numel(tmp_stop)) ' cues during SELECTION, expected 0 or 1'])
    elseif isscalar(tmp_stop)
        trial_info(k).stop_cue_idx = tmp_stop + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).stop_cue_time = str2double(dataEvents(trial_info(k).stop_cue_idx, 6)); % find timestamp
    end
    trial_info(k).cue_all_idx = tmp_cues + trial_info(k).events(1) - 1; % absolute rows of all go cues
    % only take last cue onset (can have multiple in case of cue penalties)
    tmp = tmp_cues(end);
    % get cue to align things to
    trial_info(k).cue_idx = tmp + trial_info(k).events(1) - 1; % find absolute row value
    trial_info(k).cue_time = str2double(dataEvents(trial_info(k).cue_idx, 6)); % find timestamp

    % get selection period
    if sessionInfo.taskPavlovian == 1 % pavlovian doesn't have SELECTION
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), {'REWARD', 'NO_REWARD'})); % Pavlovian task does not give a SELECTION, use the valve opening (REWARD or NO_REWARD) - exactly one per trial, verified on 16 sessions
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
        tmp_out = find(ismember(dataEvents(trial_info(k).events, 5), {'REWARD', 'NO_REWARD'})); % valve opening
        tmp_out_time = str2double(dataEvents(trial_info(k).events(tmp_out), 6)); % valve opening time
        tmp_rows = trial_info(k).events(tmp_out:end); % rows after REWARD or NO_REWARD
        % a Lick row is written when the lick ends but holds its onset time, so a lick that started before the valve
        % can be listed after REWARD: keep only licks that start at or after the valve and have a duration (as the lick assignment below)
        tmp = find(ismember(dataEvents(tmp_rows, 5), 'Lick') & ...
                   str2double(dataEvents(tmp_rows, 6)) >= tmp_out_time & ...
                   str2double(dataEvents(tmp_rows, 7)) > 0) + tmp_out-1; % find licks after REWARD or NO_REWARD
        if ~isempty(tmp) % there is at least a lick, get the first lick
            tmp = tmp(1);
        end
    else
        % decision row: Go NoGo, Ratio and stop block A use #_CORRECT, #_INCORRECT or #_TIMEOUT; stop block B uses #_STOP_SUCCESS or #_STOP_FAILURE
        tmp = find(ismember(dataEvents(trial_info(k).events, 5), {'#_CORRECT', '#_INCORRECT', '#_TIMEOUT', '#_STOP_SUCCESS', '#_STOP_FAILURE'}));
    end
    % there should always be an choice period
    if sessionInfo.taskPavlovian == 1 & isempty(tmp) % Pavlovian (so a lick is not required) AND no lick, so use max consumption time    strcmp(dataEvents(trial_info(k).cue_idx, 5), 'CUE_RR')
        trial_info(k).choice_idx = []; % find absolute row value
        trial_info(k).choice_time = str2double(dataEvents(trial_info(k).events(tmp_cons), 6)) + str2double(dataEvents(trial_info(k).events(tmp_cons), 7)); % end of CONSUMPTION, same time as before selection moved to REWARD or NO_REWARD
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

    % get outcome start - all tasks: first REWARD, NO_REWARD or CONSUMPTION row of the trial
    % teensy1spout.ino: every trial ends in CONSUMPTION. With a reward stage (REWARD_DELAY -> REWARD or NO_REWARD)
    % that row comes first (valve opening or no-reward moment); without it (Go, Stop A, Ratio error or timeout,
    % Stop B failure) the trial goes straight to CONSUMPTION, entered right after the #_INCORRECT/#_TIMEOUT decision.
    % FREE_REWARD always comes after the first CONSUMPTION, so it is never picked.
    tmp = find(ismember(dataEvents(trial_info(k).events, 5), {'REWARD', 'NO_REWARD', 'CONSUMPTION'}), 1);
    tmp_rew = find(ismember(dataEvents(trial_info(k).events, 5), {'REWARD', 'NO_REWARD'}));
    if numel(tmp_rew) > 1 % at most one reward stage per trial
        error('pavlovian:outcomeEvent', ['Trial ' num2str(k) ' has ' num2str(numel(tmp_rew)) ' REWARD or NO_REWARD rows, expected 0 or 1'])
    end
    % there should always be an outcome period
    if isempty(tmp) 
        error(['No outcome period found in trial: ' num2str(k)])
    else
        trial_info(k).outcome_idx = tmp(1) + trial_info(k).events(1) - 1; % find absolute row value
        trial_info(k).outcome_event = dataEvents{trial_info(k).outcome_idx, 5}; % REWARD, NO_REWARD or CONSUMPTION
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
% trial info
[output(1:n_trials).opto] = deal([]);
% duration of licks
[output(1:n_trials).t_lick_ITI] = deal([]);
[output(1:n_trials).t_lick_cue] = deal([]);
[output(1:n_trials).t_lick_choice] = deal([]);
[output(1:n_trials).t_lick_delay] = deal([]);
[output(1:n_trials).t_lick_outcome] = deal([]);
[output(1:n_trials).t_lick_free] = deal([]);
% timing for syncing
[output(1:n_trials).trial_start_time] = deal([]);
[output(1:n_trials).trial_stop_time] = deal([]);
% timing of licks
[output(1:n_trials).ITI_start] = deal([]);
[output(1:n_trials).cue_start] = deal([]);
[output(1:n_trials).outcome_start] = deal([]);
[output(1:n_trials).outcome_event] = deal([]);
[output(1:n_trials).stop_cue_start] = deal(NaN);   % stop task: stop cue onset relative to the go cue, NaN otherwise
[output(1:n_trials).lick_ITI] = deal([]);
[output(1:n_trials).lick_cue] = deal([]);
[output(1:n_trials).lick_choice] = deal([]);
[output(1:n_trials).lick_delay] = deal([]);
[output(1:n_trials).lick_outcome] = deal([]);
[output(1:n_trials).lick_free] = deal([]);
% reward reaction time and reward-lick ILIs (rewarded trials only, filled in below)
[output(1:n_trials).RT_reward] = deal(NaN);
[output(1:n_trials).ILI_reward] = deal([]);

% fill in trial details
for k=1:n_trials % per trial
    output(k).nTrial = str2double(dataEvents(trial_info(k).start_idx, 1)); % nTrial
    output(k).iBlock = str2double(dataEvents(trial_info(k).start_idx, 2)); % iBlock
    output(k).iTrial = str2double(dataEvents(trial_info(k).start_idx, 3)); % iTrial
    output(k).free_reward = 0; % assign a 0 here, so that both random reward and free reward can assign a 1 later on

    % add cue so we always know how things got aligned - multiple cues possible (as SPOUT2)
    output(k).cue_start = str2double(dataEvents(trial_info(k).cue_all_idx, 6))' - trial_info(k).cue_time; % store go cue timestamp(s), stop cue excluded
    output(k).stop_cue_start = trial_info(k).stop_cue_time - trial_info(k).cue_time; % NaN without a stop cue

    % add outcome onset (Pavlovian: REWARD or NO_REWARD) so we can calculate reward reaction time
    output(k).outcome_start = trial_info(k).outcome_time - trial_info(k).cue_time;
    output(k).outcome_event = trial_info(k).outcome_event; % which row outcome_start comes from

    % timing for syncing
    output(k).trial_start_time = trial_info(k).trial_start_time;
    output(k).trial_stop_time = trial_info(k).trial_stop_time;

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
    if any(ismember(dataEvents(trial_info(k).events, 5), '#_STOP_FAILURE')) % stop task block B: licked after the stop cue = error
        output(k).outcome = 2;
        output(k).correct = 0;
        output(k).incorrect = 1;
        output(k).reward = 0;
        output(k).noReward = 1;
    elseif any(ismember(dataEvents(trial_info(k).events, 5), '#_STOP_SUCCESS')) % stop task block B: withheld = correct, reward per RewardProb
        output(k).outcome = 1;
        output(k).correct = 1;
        output(k).incorrect = 0;
        output(k).reward = double(any(ismember(dataEvents(trial_info(k).events, 5), 'REWARD'))); % exact REWARD row
        output(k).noReward = 1 - output(k).reward;
    elseif ~isempty(find(ismember(dataEvents(trial_info(k).events, 5), '#_TIMEOUT'))) % omission
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

% reward reaction time (RT_reward) and inter-lick intervals of reward licks (ILI_reward) - rewarded trials only (as SPOUT2)
% rewarded = reward 1, random reward trials included. licks after outcome onset are lick_outcome (CS+) or lick_free (random reward)
% RT_reward = first of these licks minus outcome_start (Pavlovian: REWARD onset), ILI_reward = diff of these licks
for k=1:n_trials % per trial
    if output(k).reward == 1 % rewarded trial
        tmp = sort([output(k).lick_outcome output(k).lick_free]);
        if ~isempty(tmp) % animal licked for reward
            output(k).RT_reward = tmp(1) - output(k).outcome_start;
            output(k).ILI_reward = diff(tmp);
        end
    end
end

% remap to absolute time - output_raw (as SPOUT2 licks_data_abs)
% same fields as output, except RT_reward and ILI_reward (durations, not times)
% cue relative times + cue_time of the trial = Teensy clock in ms. trial_start_time and trial_stop_time are already absolute
abs_fields = {'ITI_start', 'cue_start', 'outcome_start', 'stop_cue_start', 'lick_ITI', 'lick_cue', 'lick_choice', 'lick_delay', 'lick_outcome', 'lick_free'};
output_raw = rmfield(output, {'RT_reward', 'ILI_reward'});
for k=1:n_trials % per trial
    for kk = 1:numel(abs_fields)
        output_raw(k).(abs_fields{kk}) = output(k).(abs_fields{kk}) + trial_info(k).cue_time;
    end
end

% check: last cue onset minus trial start equals t_ITI - 1 (trial start is NEW_TRIAL + 1 ms, NEW_TRIAL shares its ms with the ITI onset)
bad_trials = [];
for k=1:n_trials % per trial
    if abs((output_raw(k).cue_start(end) - output_raw(k).trial_start_time) - (output(k).t_ITI - 1)) > 1
        bad_trials(end+1) = k; %#ok<AGROW>
    end
end
if ~isempty(bad_trials)
    warning('pavlovian:absCheck', ['Cue onset minus trial start does not equal t_ITI - 1 in trials: ' num2str(bad_trials)])
end

end