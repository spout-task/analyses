%% oneSpout tasks get settings
% dataSession

function [output] = func_get_Arduino_oneSpout_settings(dataSettings, folderName)

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
output.taskGoNogo = [];
output.taskStop = [];
output.taskRatio = [];
output.taskPavlovian = [];
output.A_cue = [];
output.B_cue = [];
output.task_start_delay = [];
output.max_timeout = [];
output.max_omissions = [];
output.max_rewards = [];
output.max_trials = [];
output.trials_block_A = [];
output.trials_block_B = [];
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
output.reward = [];
output.reward_step = [];
output.reward_prob = [];
output.reward_delay = [];
output.block_switch_after_correct = [];
output.cue_instructed = [];
output.error_light_duration = [];
output.SSD_staircase = [];
output.SSD_min = [];
output.SSD_max = [];
output.SSD_step = [];
% opto
output.opto = [];
output.opto_side = [];
output.opto_epoch = [];
output.opto_duringBlockSwitch = 0;
output.opto_duringITI = 0;
output.opto_duringCue = 0;
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

% oneSpout specific
output.fixed_or_progressive = []; % 1=fixed, 0=progressive
output.fixed_number_licks = [];
output.progressive_number_start_licks = [];
output.go_number_licks = [];
output.nogo_hold_duration = [];
output.stop_number_licks = [];
output.random_reward_prob = [];

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

    elseif strcmp(dataSettings{k}, 'taskGoNogo')
        if strcmp(dataSettings{k,2}, 'on')
            output.taskGoNogo = 1;
        else
            output.taskGoNogo = 0;
        end
    elseif strcmp(dataSettings{k}, 'taskStop')
        if strcmp(dataSettings{k,2}, 'on')
            output.taskStop = 1;
        else
            output.taskStop = 0;
        end
    elseif strcmp(dataSettings{k}, 'taskRatio')
        if strcmp(dataSettings{k,2}, 'on')
            output.taskRatio = 1;
        else
            output.taskRatio = 0;
        end
    elseif strcmp(dataSettings{k}, 'taskPavlovianCond')
        if strcmp(dataSettings{k,2}, 'on')
            output.taskPavlovian = 1;
        else
            output.taskPavlovian = 0;
        end

    elseif strcmp(dataSettings{k}, 'MinBlockA')
        output.trials_block_A(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxBlockA')
        output.trials_block_A(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MinBlockB')
        output.trials_block_B(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxBlockB')
        output.trials_block_B(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'CueTime(ms)')
        output.cue_duration = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'CuePenalty(ms)')
        output.cue_lick_penalty = str2double(dataSettings{k,2});

    elseif strcmp(dataSettings{k}, 'SelectionTime(ms)')
        output.selection_period = str2double(dataSettings{k,2});
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
    elseif strcmp(dataSettings{k}, 'ITIisENL')
        if strcmp(dataSettings{k,2}, 'on')
            output.ITI_is_ENL = 1;
        else
            output.ITI_is_ENL = 0;
        end      

    elseif strcmp(dataSettings{k}, 'MinReward(ms)')
        output.reward(1) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'MaxReward(ms)')
        output.reward(2) = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'RewardStep')
        output.reward_step = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'RewardProbability')
        output.reward_prob = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'RewardDelay(ms)')
        output.reward_delay = str2double(dataSettings{k,2});

    elseif strcmp(dataSettings{k}, 'SpoutStart')
        output.spout_start = dataSettings{k,2};
    elseif strcmp(dataSettings{k}, 'ACueFreq(hz)')
        output.A_cue = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'BCueFreq(hz)')
        output.B_cue = str2double(dataSettings{k,2});
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
    elseif strcmp(dataSettings{k}, 'SSDStaircase')
        if strcmp(dataSettings{k,2}, 'on')
            output.SSD_staircase = 1;
        else
            output.SSD_staircase = 0;
        end
    elseif strcmp(dataSettings{k}, 'SSDMin(ms)')
        output.SSD_min = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'SSDMax(ms)')
        output.SSD_max = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'SSDStep(ms)')
        output.SSD_step = str2double(dataSettings{k,2});

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
    elseif strcmp(dataSettings{k}, 'OptoDuringCue')
        if strcmp(dataSettings{k,2}, 'true') || strcmp(dataSettings{k,2}, 'TRUE')
            output.opto_duringCue = 1;
        else
            output.opto_duringCue = 0;
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

        % oneSpout specific
    elseif strcmp(dataSettings{k}, 'RatioFixed')
        if strcmp(dataSettings{k,2}, '0')
            output.fixed_or_progressive = 0;
        else
            output.fixed_or_progressive = 1;
        end
    elseif strcmp(dataSettings{k}, 'FRNumberLicks')
        output.fixed_number_licks = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'PRNumberStartLicks')
        output.progressive_number_start_licks = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'GoNumberLicks')
        output.go_number_licks = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'NogoHoldDuration')
        output.nogo_hold_duration = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'StopNumberLicks')
        output.stop_number_licks = str2double(dataSettings{k,2});
    elseif strcmp(dataSettings{k}, 'RandomRewardProb')
        output.random_reward_prob = str2double(dataSettings{k,2});

        % notify user if we miss something
    else
        disp(['Did not find a match for: ' dataSettings{k}])
    end
end

% output.opto should only be 1 if we actually did opto (block/ITI/cue/delay/startCue/outcome/rew/error)
if output.opto_duringBlockSwitch == 1 || output.opto_duringITI == 1 || ...
        output.opto_duringCue == 1 || output.opto_duringOutcome == 1 || ...
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