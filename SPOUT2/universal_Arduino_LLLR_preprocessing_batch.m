%% Lick Left / Lick Right task preprocessing Arduino output
% twoSpouts task

% script preprocesses Arduino/Matlab GUI output
% data directories should be: Cohort/animal/session/behavior -> raw data

% batch script processes all animals all sessions

% differences between LV and Arduino preprocessing
% Arduino has correct/incorrect/reward/noreward (vs rewards/errors which does not take into account probabilistic)

% clear matlab
clearvars
close all force
tic

% include sync pulse
sync_int = true;        % internal sync pulse - duration column is for the SAME row sync pulse (off/on), as we decide how long each pulse takes
sync_ext = false;       % external sync pulse - duration column is for the NEXT row sync pulse (off/on), as we can't predict how long the first pulse will take

% plot figs or not
plot_fig_session = true;
plot_fig_lick_raster = false;

% ask user for folder with video and framenumber
raw_dir = uigetdir('', 'Select cohort directory that you need to preprocess [cohort/animal/date/behavior]');
cd(raw_dir)

% ask user if they want to replace excisting preprocessing files
user_replace = input('Do you want to replace (y) or skip preprocessed files (n, default)*?: ', "s");
if isempty(user_replace)
    user_replace = 'n';
elseif user_replace == 'y' | user_replace == 'n'
else
    error(['please answer with y or n'])
end

% ask user where to store preprocessed data
% user_dir_save = uigetdir('', 'Select cohort directory where you want to store data. Matlab will make animal/date folders');

% notify the user we will store the data in Bastijn\data_preprocessed
% it's a copy of the data_raw path, but now it's data_preprocessed which
% allows for easy backup and finding of data
preprocessed_dir = strrep(raw_dir, 'data_raw', 'data_preprocessed');

disp('IMPORTANTLY, preprocessed data will be stored in:')
disp([preprocessed_dir '\animal\session\behavior'])

% find all animals
dir_animals = dir;  % get animal folders
dir_animals = dir_animals([dir_animals.isdir]); % only keep folders
tmp = {dir_animals([dir_animals.isdir]).name};  % get names
dir_animals = dir_animals(~ismember(tmp, {'.', '..'})); % remove . and ..


%% per animal, loop through folders

% loopje animal
for c = 1:size(dir_animals,1) % per animal

    %% find sessions to preprocess
    dir_sessions = dir([raw_dir '\' dir_animals(c).name]);  % get session folders
    tmp = {dir_sessions([dir_sessions.isdir]).name}; % get names
    dir_sessions = dir_sessions(~ismember(tmp, {'.', '..'})); % remove . and ..

    %% loopje session
    for cc = 1:size(dir_sessions,1) % per session

        %% clean workspace
        close all
        clearvars -except raw_dir user_replace preprocessed_dir dir_animals dir_sessions c cc plot_fig_session plot_fig_lick_raster sync_int sync_ext
        session = struct;   % make struct to store data

        % have we preprocessed this session before?
        try % check if we can find the folder
            tmp_chk_preproc = dir([preprocessed_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*_preprocess.mat']);
        catch
            tmp_chk_preproc = [];
        end

        % are there files in the current session, i.e., is the current session folder not empty?
        tmp_chk_dir_beh = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior']);
        tmp_chk_dir_beh([tmp_chk_dir_beh.isdir]) = [];  % delete dirs (. and ..)

        % message box to notify use of empty folder
        if isempty(tmp_chk_dir_beh)
            msgbox(['Animal: ' dir_animals(c).name ', session: ' dir_sessions(cc).name ' is an empty folder'], 'Empty folder detected')
        end

        %% check if we need to preprocess this session
        if ( user_replace == 'y' | (user_replace == 'n' & isempty(tmp_chk_preproc)) ) & ~isempty(tmp_chk_dir_beh)  % preprocess if ('Y' or (if 'N' AND empty)) AND not empty folder

            % user feedback
            disp(['Loading data of animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name])

            % get files
            file_dataSettings = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Settings.csv']);    % exp settings
            file_dataEvents = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Events.csv']);        % raw events
            file_dataBlocks = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Blocks.csv']);        % raw blocks

            % load data
            opts = delimitedTextImportOptions("NumVariables", 2); % specify columns in _Settings.csv
            dataSettings = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataSettings.name], opts);
            opts = delimitedTextImportOptions("NumVariables", 7); % specify collumns in _Events.csv
            dataEvents = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataEvents.name], opts);
            opts = delimitedTextImportOptions("NumVariables", 19); % specify collumns in _Blocks.csv
            dataBlocks = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataBlocks.name], opts);

            % load int sync pulses
            if sync_int == true
                file_syncInt = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*_SyncPulses.csv']);        % internal sync pulse
                dataSyncInt = readtable([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_syncInt.name]);
                disp('Internal sync pulse loaded')
            end

            % load ext sync pulses
            if sync_ext == true
                file_syncExt = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*_ExtSyncPulses.csv']);        % external sync pulse
                dataSyncInt = readtable([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_syncExt.name]);
                disp('External sync pulse loaded')
            end

            %% check files
            % make sure behavioral folder has 4 files, camera folder has 2
            % files, and those files are made around the same time

            % find files
            tmp_beh = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\']);
            tmp_beh([tmp_beh.isdir]) = []; % remove . and ..
            tmp_cam = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\camera\']);
            tmp_cam([tmp_cam.isdir]) = []; % remove . and ..

            % check number beh
            if length(tmp_beh) ~= 4
                disp(['Animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files'])
                msgbox(['Animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files'])
            end

            % check number cam
            if length(tmp_cam) ~= 2
                disp(['Animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of camera files'])
                msgbox(['Animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of camera files'])
            end

            % compare when files were made, difference should be less than 10 min
            try
                t1 = datetime(tmp_beh(1).datenum, 'ConvertFrom', 'datenum');
                t2 = datetime(tmp_cam(1).datenum, 'ConvertFrom', 'datenum');
                if abs(t1 - t2) > minutes(10)
                    disp(['Animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', behavioral and camera files appear to have different timestamps'])
                    msgbox(['Animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', behavioral and camera files appear to have different timestamps'])
                end
            catch; end

            %% session info (dataSettings)

            % get data in struct
            session.info = func_get_Arduino_twoSpouts_settings(dataSettings, dir_sessions(cc).name);


            %% lick data timestamps (dataEvents)

            % get data in struct - keep trial_info to calculate trial_data
            % licks_data aligned to cue, licks_data_abs not aligned (absolute timestamp)
            [session.licks_data, session.licks_data_abs, trial_info, dataEvents] = func_get_Arduino_twoSpouts_licks(dataEvents);


            %% trial data (dataEvents, trial_info)

            % get data
            [session.trial_data, trial_info] = func_get_Arduino_twoSpouts_trials(dataEvents, trial_info);

            % update licks_data with trial_data strategy and opto
            [session.licks_data.iStrategy] = deal(session.trial_data.iStrategy);
            [session.licks_data.opto] = deal(session.trial_data.opto);
            [session.licks_data_abs.iStrategy] = deal(session.trial_data.iStrategy);
            [session.licks_data_abs.opto] = deal(session.trial_data.opto);


            %% block data (dataBlocks)

            % get data
            correct_trials2switch = 1; % if 0, don't correct for first trial
            [session.block_data] = func_get_Arduino_twoSpouts_blocks(dataBlocks, session.trial_data, correct_trials2switch);


            %% ITI lick data (dataLick, dataTrial)

            % get data - ITI licks aligned to previous and future choice
            [session.ITI_licks] = func_get_Arduino_twoSpouts_ITI_licks(session.licks_data, session.trial_data);


            %% session data (dataTrial, dataLick)

            % get data
            [session.session_data] = func_get_Arduino_twoSpouts_session(session.trial_data, session.block_data, session.licks_data, session.ITI_licks);


            %% block switch probability data(dataTrial, number of trial pre/post)

            % fixed vars
            n_trials_pre = 4;   % trials before block transition
            n_trials_post = 8;  % trials after block transition (including the first switch trial)

            % find reward spout probability and switch probability
            [session.block_switch_prob.prob_spout, session.block_switch_prob.prob_switch] = func_get_probability_spout_and_switch(session.trial_data, n_trials_pre, n_trials_post);


            %% internal sync pulse
            % internal, random sync pulse starts with first HIGH (drop pre-high low)

            % preprocess sync pulse
            if sync_int == true
                [session.syncInt] = func_get_sync_internal(dataSyncInt);
            end


            %% save data

            % make new directory in user_dir_save
            save_dir = [preprocessed_dir '\' dir_animals(c).name];
            mkdir([save_dir '\' dir_sessions(cc).name '\behavior'])

            % save data
            % save([dir_animals(c).name '\' dir_sessions(cc).name '\' session.info.name 'c_' session.info.date '_preprocess'], 'session')
            save([save_dir '\' dir_sessions(cc).name '\behavior\' session.info.name '_' session.info.date '_beh_preprocess'], 'session')
            disp('Done saving data')


            %% plot session average data

            if plot_fig_session == true

                % get figure inputs
                coolors = [106/255 153/255 78/255; 188/255 71/255 73/255; 46/255 134/255 177/255];  % green/red/blue

                % plot LLLR session figure
                plot_LLLR_daily_session(coolors, session.info, session.trial_data, session.session_data)

                % save figure - add opto if needed
                if session.info.opto == 1
                    saveas(gcf, [save_dir '\' 'session_' session.info.name '_' session.info.date '_opto_' session.info.opto_side '_' session.info.opto_epoch '.jpg'])
                else
                    saveas(gcf, [save_dir '\' 'session_' session.info.name '_' session.info.date '.jpg'])
                end
                disp('Done saving session figure')
            end


            %% plot histogram licks

            if plot_fig_lick_raster == true

                % fixed vars
                dot_size = 10;
                x_min = -2000;
                x_max = session.info.selection_period/2;

                % plot LLLR licks figure
                plot_LLLR_daily_licks(dot_size, x_min, x_max, session.licks_data)

                % save figure
                saveas(gcf, [save_dir '\' 'lick_histogram_' session.info.name '_' session.info.date '.jpg'])
                disp('Done saving licks histogram')
            end

        else
            if isempty(tmp_chk_preproc) & isempty(tmp_chk_dir_beh)  % check if folder is empty
                disp(['Animal: ' dir_animals(c).name ' session: ' dir_sessions(cc).name ' is empty'])
            else
                disp(['Animal: ' dir_animals(c).name ' session: ' dir_sessions(cc).name ' already done'])
            end
        end     % check if we need to run in the first place
        
    end     % loopje session

end     % loopje animal


toc






