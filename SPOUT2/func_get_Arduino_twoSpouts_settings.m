%% twoSpouts task get settings
% dataSession

function [output] = func_get_Arduino_twoSpouts_settings(dataSettings, folderName)

% create struct
output = struct;
% general info
output.name = [];
output.date = [];
output.folder = [];
output.arduino_code = [];
output.matlab_code = [];
output.session_end = [];
output.spout_start = [];
output.duration = [];
% settings
output.taskLLLR = [];
output.task2ABT = [];
output.taskDR = [];
output.taskPavlovian = [];
output.left_cue = [];
output.right_cue = [];
output.task_start_delay = [];
output.max_timeout = [];
output.max_omissions = [];
output.max_rewards = [];
output.max_trials = [];
output.trials_block_left = [];
output.trials_block_right = [];
output.selection_period = [];
output.consumption_period = [];
output.wrong_choice_period = [];
output.cue_duration = [];
output.cue_lick_penalty = [];
output.fails_untill_reward = [];
output.ITI_is_ENL = [];
output.enl_penalty = [];
output.ITI_period = [];
output.ITI_step = [];
output.left_reward = [];
output.left_reward_step = [];
output.right_reward = [];
output.right_reward_step = [];
output.reward_prob = [];
output.reward_delay = [];
output.block_switch_after_correct = [];
output.cue_instructed = [];
output.error_light_duration = [];
% opto
output.opto = [];
output.opto_side = [];
output.opto_epoch = [];
output.opto_duringBlockSwitch = 0;
output.opto_duringITI = 0;
output.opto_duringCue = 0;
output.opto_duringDelay = 0;
output.opto_duringStartCue = 0;
output.opto_duringOutcome = 0;
output.opto_duringConsumption = 0;
output.opto_duringError = 0;
output.opto_prob = [];
output.opto_correct_trials = [];
output.opto_delay = [];
output.opto_multiStim_ITI = [];
output.opto_multiStim_Cue = [];
output.opto_multiStim_Block = [];
output.opto_continuous = [];
output.opto_duration = [];
output.opto_pulseDuration = [];
output.opto_freq = [];
output.opto_modulation = [];
output.opto_mod_continuous = [];
output.opto_taper_off = [];
output.opto_distraction_light = [];

% twoSpouts specific
output.start_cue = [];
output.delay_duration = [];
output.delay_lick_penalty = [];
output.start_cue_duration = [];
output.start_cue_lick_penalty = [];
output.opto_multiStim_Delay = [];
output.opto_multiStim_StartCue = [];

% get session details
for k=1:size(dataSettings,1)
    if strcmp(dataSettings{k}, 'TASK STARTED AT')
        session_dur(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'Stopped by')
        output.session_end = dataSettings{k,2};
    elseif strcmp(dataSettings{k}, 'TASK ENDED AT')
        session_dur(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'AnimalName')
        output.name = dataSettings{k,2};

    elseif strcmp(dataSettings{k}, 'taskLLLR')
        if strcmp(dataSettings{k,2}, 'on')
            output.taskLLLR = 1;
        else
            output.taskLLLR = 0;
        end
    elseif strcmp(dataSettings{k}, 'task2ABT')
        if strcmp(dataSettings{k,2}, 'on')
            output.task2ABT = 1;
        else
            output.task2ABT = 0;
        end
    elseif strcmp(dataSettings{k}, 'taskDR')
        if strcmp(dataSettings{k,2}, 'on')
            output.taskDR = 1;
        else
            output.taskDR = 0;
        end
    elseif strcmp(dataSettings{k}, 'taskPavlovian')
        if strcmp(dataSettings{k,2}, 'on')
            output.taskPavlovian = 1;
        else
            output.taskPavlovian = 0;
        end

    elseif strcmp(dataSettings{k}, 'MinBlockLeft')
        output.trials_block_left(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxBlockLeft')
        output.trials_block_left(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MinBlockRight')
        output.trials_block_right(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxBlockRight')
        output.trials_block_right(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'CueTime(ms)')
        output.cue_duration = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'CuePenalty(ms)')
        output.cue_lick_penalty = str2double(dataSettings{k,2});

    elseif strcmp(dataSettings{k}, 'SelectionTime(ms)')
        output.selection_period = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'OutcomeTime(ms)') % old version
        output.consumption_period = str2double(dataSettings{k,2});
        output.wrong_choice_period = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'CorrectTime(ms)')
        output.consumption_period = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'IncorrectTime(ms)')
        output.wrong_choice_period = str2double(dataSettings{k,2});

    elseif strcmp(dataSettings{k}, 'FailsUntilReward')
        output.fails_untill_reward = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MinITI(ms)')
        output.ITI_period(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxITI(ms)')
        output.ITI_period(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'ITIStep')
        output.ITI_step = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MinENL(ms)') % old task
        output.ITI_period(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxENL(ms)') % old task
        output.ITI_period(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'ENLStep') % old task
        output.ITI_step = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'ITIisENL')
        if strcmp(dataSettings{k,2}, 'on')
            output.ITI_is_ENL = 1;
        else
            output.ITI_is_ENL = 0;
        end      

    elseif strcmp(dataSettings{k}, 'MinLeft(ms)')
        output.left_reward(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxLeft(ms)')
        output.left_reward(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'LeftStep')
        output.left_reward_step = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MinRight(ms)')
        output.right_reward(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxRight(ms)')
        output.right_reward(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'RightStep')
        output.right_reward_step = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'RewardProbability')
        output.reward_prob = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'RewardDelay(ms)')
        output.reward_delay = str2double(dataSettings{k,2});

    elseif strcmp(dataSettings{k}, 'SpoutStart')
        output.spout_start = dataSettings{k,2};
    elseif strcmp(dataSettings{k}, 'LeftCueFreq(hz)')
        output.left_cue = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'RightCueFreq(hz)')
        output.right_cue = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'ENLPenaltyDuration')
        output.enl_penalty = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'BlockSwitchAfterCorrectTrials')
        if strcmp(dataSettings{k,2}, 'on')
            output.block_switch_after_correct = 1;
        else
            output.block_switch_after_correct = 0;
        end
    elseif strcmp(dataSettings{k}, 'DurationErrorLight')
        output.error_light_duration = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'CuesInstructed')
        if strcmp(dataSettings{k,2}, 'on')
            output.cue_instructed = 1;
        else
            output.cue_instructed = 0;
        end    

    elseif strcmp(dataSettings{k}, 'OptoDuringBlockSwitch')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringBlockSwitch = 1;
        else
            output.opto_duringBlockSwitch = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoDuringITI')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringITI = 1;
        else
            output.opto_duringITI = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoDuringENL') % old version
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringITI = 1;
        else
            output.opto_duringITI = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoDuringCue')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringCue = 1;
        else
            output.opto_duringCue = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoDuringDelay')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringDelay = 1;
        else
            output.opto_duringDelay = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoDuringStartCue')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringStartCue = 1;
        else
            output.opto_duringStartCue = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoDuringOutcome') 
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringOutcome = 1;
        else
            output.opto_duringOutcome = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoDuringConsumption') 
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringConsumption = 1;
        else
            output.opto_duringConsumption = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoDuringError') 
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringError = 1;
        else
            output.opto_duringError = 0;
        end

    elseif strcmp(dataSettings{k}, 'OptoProbability')
        output.opto_prob = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'CorrectTrialsBeforeOpto')
        output.opto_correct_trials = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'OptoDelay(ms)')
        output.opto_delay = str2double(dataSettings{k,2});

    elseif strcmp(dataSettings{k}, 'AllowMultiStimITI')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_multiStim_ITI = 1;
        else
            output.opto_multiStim_ITI = 0;
        end
    elseif strcmp(dataSettings{k}, 'AllowMultiStimENL') % old task
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_multiStim_ITI = 1;
        else
            output.opto_multiStim_ITI = 0;
        end
    elseif strcmp(dataSettings{k}, 'AllowMultiStimCue')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_multiStim_Cue = 1;
        else
            output.opto_multiStim_Cue = 0;
        end
    elseif strcmp(dataSettings{k}, 'AllowMultiStimBlock')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_multiStim_Block = 1;
        else
            output.opto_multiStim_Block = 0;
        end

    elseif strcmp(dataSettings{k}, 'ContinuousOpto')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_continuous = 1;
        else
            output.opto_continuous = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoDuration(ms)')
        output.opto_duration = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'PulseDuration(ms)')
        output.opto_pulseDuration = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'OptoFrequency(Hz)')
        output.opto_freq = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'OptoModulation')
        output.opto_modulation = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'AOMModulation') % old task
        output.opto_modulation = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'OptoModContinuous')
        if strcmp(dataSettings{k,2}, 'on')
            output.opto_mod_continuous = 1;
        else
            output.opto_mod_continuous = 0;
        end
    elseif strcmp(dataSettings{k}, 'OptoTaperOff(ms)')
        output.opto_taper_off = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'AddRandomOptoLight')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_distraction_light = 1;
        else
            output.opto_distraction_light = 0;
        end
    elseif strcmp(dataSettings{k}, 'MaxOmissions')
        output.max_omissions = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'Timeout(min)')
        output.max_timeout = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxRewards')
        output.max_rewards = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxTrials')
        output.max_trials = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'TaskStartDelay')
        output.task_start_delay = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'DataSavedTo')
        output.folder = dataSettings{k,2};
    elseif strcmp(dataSettings{k}, 'Arduino Code')
        output.arduino_code = dataSettings{k,2};
    elseif strcmp(dataSettings{k}, 'MATLAB Code')
        output.matlab_code = dataSettings{k,2};

        % twoSpouts specific
    elseif strcmp(dataSettings{k}, 'StartCueDuration(ms)')
        output.start_cue_duration = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'StartCuePenalty(ms)')
        output.start_cue_lick_penalty = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'StartCueFreq(hz)')
        output.start_cue = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'DelayDuration(ms)')
        output.delay_duration = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'DelayPenalty(ms)')
        output.delay_lick_penalty = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'AllowMultiStimDelay')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_multiStim_Delay = 1;
        else
            output.opto_multiStim_Delay = 0;
        end
    elseif strcmp(dataSettings{k}, 'AllowMultiStimStartCue')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_multiStim_StartCue = 1;
        else
            output.opto_multiStim_StartCue = 0;
        end

        % notify user if we miss something
    else
        disp(['Did not find a match for: ' dataSettings{k}])
    end
end

% output.opto should only be 1 if we actually did opto (block/ITI/cue/delay/startCue/outcome/rew/error)
if output.opto_duringBlockSwitch == 1 || output.opto_duringITI == 1 || ...
        output.opto_duringCue == 1 || output.opto_duringDelay == 1 || ...
        output.opto_duringStartCue == 1 || output.opto_duringOutcome == 1 || ...
        output.opto_duringConsumption == 1 || output.opto_duringError == 1
    output.opto = 1;
else
    output.opto = 0;
end

% add duration info
try
    output.duration = session_dur(2)-session_dur(1);
catch end

% sporadically we add some extra letter to the date if we record more than once a day
tmp = strsplit(folderName, '_');
output.date = tmp{1};

% if opto, add some extra variables to struct
if output.opto == 1

    % get date
    tmp = strsplit(folderName, '_');

    % get side and epoch
    try
        output.opto_side = tmp{end-1};
        output.opto_epoch = tmp{end};
    catch
        disp(['Animal: ' output.name ' - session: ' output.date '. Please indicate in folder name which side and epoch got opto stimulation'])
        msgbox(['Animal: ' output.name ' - session: ' output.date '. Please indicate in folder name which side and epoch got opto stimulation'])
        % pause
    end

    % check if files are in correct folder
    tmp = strsplit(folderName, '_');
    if ~strcmp(output.date, tmp{1})
        disp(['Animal: ' output.name ' - folder: ' folderName ' - session: ' output.date '. Folder date does not match file date'])
        msgbox(['Animal: ' output.name ' - folder: ' folderName ' - session: ' output.date '. Folder date does not match file date'])
        % pause
    end

    % check if folder name reflects actual opto
    if      (strcmp(output.opto_epoch, 'blk') & output.opto_duringBlockSwitch == 1) | ...
            (strcmp(output.opto_epoch, 'enl') & output.opto_duringITI == 1) | ...
            (strcmp(output.opto_epoch, 'cue') & output.opto_duringCue == 1) | ...
            (strcmp(output.opto_epoch, 'dly') & output.opto_duringDelay == 1) | ...
            (strcmp(output.opto_epoch, 'scue') & output.opto_duringStartCue == 1) | ...
            (strcmp(output.opto_epoch, 'rew') & output.opto_duringConsumption == 1) | ...
            (strcmp(output.opto_epoch, 'out') & output.opto_duringOutcome == 1) | ...
            (strcmp(output.opto_epoch, 'err') & output.opto_duringError == 1) | ...
            (strcmp(output.opto_epoch, 'all'))
    else
        disp(['Opto folder name does not match actual opto experiment! Animal: ' output.name ' - session: ' output.date])
        msgbox(['Opto folder name does not match actual opto experiment! Animal: ' output.name ' - session: ' output.date])
        % pause
    end
end


% make sure user didn't add opto to folder name without doing opto
tmp = strsplit(folderName, '_');

% check if there is a side indicated
if length(tmp) > 1 & output.opto == 0 % more than 1 string
    if strcmp(tmp{end-1}, 'l') || strcmp(tmp{end-1}, 'r')
        disp(['Animal: ' output.name ' - session: ' output.date '. Folder name indicates you did opto but settings file did not'])
        msgbox(['Animal: ' output.name ' - session: ' output.date '. Folder name indicates you did opto but settings file did not'])
    end
end