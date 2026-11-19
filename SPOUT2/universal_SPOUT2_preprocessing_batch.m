%% SPOUT2 preprocess data
%
% What it does: preprocesses the behavior of the two spout task (SPOUT2, for example
% LLLR), recorded with the Teensy and the SPOUT2 MATLAB GUI.
% Batch script: you select one cohort folder and it processes every session of
% every animal in it. Per session it reads the csv files, extracts session settings,
% licks, trials, blocks and a session summary, reads the internal and external sync
% pulses, saves one .mat file and plots the session figures. At the end it can run
% universal_LLLR_plot_across_sessions for the whole cohort.
%
% How to run: press Run, select a cohort folder in data_raw, then answer y (replace)
% or n (skip, default) for sessions that were preprocessed before.
%
% Raw data (input), one folder per animal and session:
%   ...\data_raw\<cohort>\<animal>\<session>\behavior\
%       *_Settings.csv       task settings
%       *_Events.csv         all task events and licks
%       *_Blocks.csv         block information
%       *_SyncPulses.csv     internal sync pulse (Teensy)
%       *_ExtSyncPulses.csv  external sync pulse (for example from imaging)
%   ...\data_raw\<cohort>\<animal>\<session>\camera\   (only checked, not processed)
%
% Preprocessed data (output): the path is copied from data_raw, with data_raw
% replaced by data_preprocessed:
%   ...\data_preprocessed\<cohort>\<animal>\<session>\behavior\animal_date_beh_preprocess.mat
%   ...\data_preprocessed\<cohort>\<animal>\beh_date_animal.jpg   (and beh_date_animal_lick_histogram.jpg)
% The .mat file holds one struct, session. Figures sit in the animal folder,
% so all sessions of one animal can be browsed with the arrow keys.
%
% Rules: the path of the selected folder must contain data_raw once, otherwise 
% the script stops. The animal name is taken only from AnimalName in *_Settings.csv,
% never from folder or file names, so <animal> in the output is AnimalName. The raw
% <animal> folder is only used to find the files. A session without exactly one
% *_Settings.csv with an AnimalName is skipped with a warning. Animal names may not
% contain an underscore. A missing or broken sync pulse file gives a warning and
% that sync pulse is skipped.
%
% Depends on: func_get_SPOUT2_*, plot_LLLR_daily_session and plot_LLLR_daily_licks
% (this folder), func_load_SPOUT_sync_csv, func_get_SPOUT_sync_internal and
% func_get_SPOUT_sync_external (behavior\SPOUT_shared_functions),
% universal_LLLR_plot_across_sessions (behavior\SPOUT2\2_LLLR_plot_data),
% func_log_warnings (behavior\miscellaneous_functions).
%
% Warnings: problems that do not stop the script (for example a wrong number of
% behavior files) give a warning with an identifier in the command window, no popups.
% At the end of the run all warnings are listed again per session (func_log_warnings).
%
% Note: the Teensy logs correct, incorrect, reward and noreward separately, because
% with probabilistic rewards a correct choice is not always rewarded.

%% find dir

% clear matlab
clearvars
close all force

% housekeeping
func_log_warnings('start')    % collect all warnings of this run, printed again at the end
tic

% sync pulses are always loaded; a missing, empty or malformed file gives a warning and that sync pulse is skipped
% internal sync pulse - duration column is for the SAME row sync pulse (off/on), as we decide how long each pulse takes
% external sync pulse - duration column is for the NEXT row sync pulse (off/on), as we can't predict how long the first pulse will take
warn_ext_sync_absent = false; % external sync pulse: false = do not warn when ExtSyncPulses.csv is missing, 0 bytes or has no rows (not recorded)

% plot figs or not
LLLR_plot_fig_session = true;
LLLR_plot_fig_lick_raster = false;

% after preprocessing, plot the across sessions figures of this cohort
LLLR_plot_across_session_after_preprocessing = true;

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
if numel(strfind(raw_dir, '\data_raw\')) ~= 1                              % need exactly one data_raw level
    error('spout:noDataRaw', ['Path must contain one data_raw folder: ' raw_dir])   % never write into raw data
end
% % % preprocessed_dir = strrep(raw_dir, 'data_raw', 'data_preprocessed');
preprocessed_dir = strrep(raw_dir, '\data_raw\', '\data_preprocessed\');      % whole folder name only

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
        clearvars -except raw_dir user_replace preprocessed_dir dir_animals dir_sessions c cc LLLR_plot_fig_session LLLR_plot_fig_lick_raster plot_after_preprocessing LLLR_plot_across_session_after_preprocessing warn_ext_sync_absent
        session = struct;   % make struct to store data
        func_log_warnings('session', [dir_animals(c).name ' ' dir_sessions(cc).name])    % warnings below belong to this session

        % are there files in the current session, i.e., is the current session folder not empty?
        tmp_chk_dir_beh = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior']);
        tmp_chk_dir_beh([tmp_chk_dir_beh.isdir]) = [];  % delete dirs (. and ..)

        % warning to notify use of empty folder
        if isempty(tmp_chk_dir_beh)
            warning('spout:emptyFolder', ['animal: ' dir_animals(c).name ', session: ' dir_sessions(cc).name ' is an empty folder'])   % no popup, listed again at the end
        end

        % animal name: only from AnimalName in *_Settings.csv, never from folder or file names
        animal_name = '';                                                  % empty until found
        file_dataSettings = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Settings.csv']);    % exp settings
        if numel(file_dataSettings) == 1                                   % exactly one settings file
            opts = delimitedTextImportOptions("NumVariables", 2);          % specify columns in _Settings.csv
            dataSettings = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataSettings.name], opts);   % settings as cell array
            idx_name = find(strcmp(dataSettings(:, 1), 'AnimalName'), 1);  % row that holds the animal name
            if ~isempty(idx_name)                                          % row found
                animal_name = strtrim(dataSettings{idx_name, 2});          % animal name as typed in the GUI
            end
        end
        if isempty(animal_name) & ~isempty(tmp_chk_dir_beh)               % files present but no usable name
            warning('spout:noAnimalName', ['Animal folder: ' dir_animals(c).name ', session: ' dir_sessions(cc).name ', not exactly one *_Settings.csv with an AnimalName, session skipped'])   % no popup, listed again at the end
        end

        % have we preprocessed this session before?
        tmp_chk_preproc = [];                                              % nothing found yet
        if ~isempty(animal_name)                                           % only with a valid animal name
            tmp_chk_preproc = dir([preprocessed_dir '\' animal_name '\' dir_sessions(cc).name '\behavior\' '*_preprocess.mat']);   % earlier output of this session
        end

        %% check if we need to preprocess this session
        if ( user_replace == 'y' | (user_replace == 'n' & isempty(tmp_chk_preproc)) ) & ~isempty(tmp_chk_dir_beh) & ~isempty(animal_name)  % preprocess if ('Y' or (if 'N' AND empty)) AND not empty folder AND animal name found

            % user feedback
            disp(['Loading data of animal: ' animal_name ' - session: ' dir_sessions(cc).name])

            % get files (settings file was found and loaded above)
            file_dataEvents = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Events.csv']);        % raw events
            file_dataBlocks = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Blocks.csv']);        % raw blocks

            % load data (dataSettings was loaded above)
            opts = delimitedTextImportOptions("NumVariables", 7); % specify collumns in _Events.csv
            dataEvents = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataEvents.name], opts);
            opts = delimitedTextImportOptions("NumVariables", 19); % specify collumns in _Blocks.csv
            dataBlocks = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataBlocks.name], opts);

            % load sync pulses (always; missing or empty gives a warning, see func_load_sync_csv)
            sess_dir = [raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior'];               % behavior folder
            sess_name = [animal_name ' ' dir_sessions(cc).name];                                              % for messages
            dataSyncInt = func_load_SPOUT_sync_csv(sess_dir, '*_SyncPulses.csv', 'internal', sess_name);           % internal sync pulse
            dataSyncExt = func_load_SPOUT_sync_csv(sess_dir, '*_ExtSyncPulses.csv', 'external', sess_name, warn_ext_sync_absent);   % external sync pulse

            %% check files
            % make sure behavioral folder has 4 files, camera folder has 2
            % files, and those files are made around the same time

            % find files
            tmp_beh = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\']);
            tmp_beh([tmp_beh.isdir]) = []; % remove . and ..
            tmp_cam = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\camera\']);
            tmp_cam([tmp_cam.isdir]) = []; % remove . and ..

            % check number beh
            if length(tmp_beh) ~= 5
                warning('spout:nBehFiles', ['animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files (' num2str(length(tmp_beh)) ' instead of 5)'])   % no popup, listed again at the end
            end

            % check number cam
            if length(tmp_cam) ~= 2
                warning('spout:nCamFiles', ['animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of camera files (' num2str(length(tmp_cam)) ' instead of 2)'])   % no popup, listed again at the end
            end

            % compare when files were made, difference should be less than 10 min
            try
                t1 = datetime(tmp_beh(1).datenum, 'ConvertFrom', 'datenum');
                t2 = datetime(tmp_cam(1).datenum, 'ConvertFrom', 'datenum');
                if abs(t1 - t2) > minutes(10)
                    warning('spout:camTimeMismatch', ['animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', behavioral and camera files appear to have different timestamps'])   % no popup, listed again at the end
                end
            catch; end

            %% session info (dataSettings)

            % get data in struct
            session.info = func_get_SPOUT2_settings(dataSettings, dir_sessions(cc).name);


            %% lick data timestamps (dataEvents)

            % get data in struct - keep trial_info to calculate trial_data
            % licks_data aligned to cue, licks_data_abs not aligned (absolute timestamp)
            [session.licks_data, session.licks_data_abs, trial_info, dataEvents] = func_get_SPOUT2_licks(dataEvents);


            %% trial data (dataEvents, trial_info)

            % get data
            [session.trial_data, trial_info] = func_get_SPOUT2_trials(dataEvents, trial_info);

            % update licks_data with trial_data strategy and opto
            [session.licks_data.iStrategy] = deal(session.trial_data.iStrategy);
            [session.licks_data.opto] = deal(session.trial_data.opto);
            [session.licks_data_abs.iStrategy] = deal(session.trial_data.iStrategy);
            [session.licks_data_abs.opto] = deal(session.trial_data.opto);


            %% block data (dataBlocks)

            % get data
            correct_trials2switch = 1; % if 0, don't correct for first trial
            [session.block_data] = func_get_SPOUT2_blocks(dataBlocks, session.trial_data, correct_trials2switch);


            %% ITI lick data (dataLick, dataTrial)

            % get data - ITI licks aligned to previous and future choice
            [session.ITI_licks] = func_get_SPOUT2_ITI_licks(session.licks_data, session.trial_data);


            %% session data (dataTrial, dataLick)

            % get data
            [session.session_data] = func_get_SPOUT2_session(session.trial_data, session.block_data, session.licks_data, session.ITI_licks);


            %% block switch probability data(dataTrial, number of trial pre/post)

            % fixed vars
            n_trials_pre = 4;   % trials before block transition
            n_trials_post = 8;  % trials after block transition (including the first switch trial)

            % find reward spout probability and switch probability
            [session.block_switch_prob.prob_spout, session.block_switch_prob.prob_switch] = func_get_SPOUT2_probability_spout_and_switch(session.trial_data, n_trials_pre, n_trials_post);


            %% internal and external sync pulses
            % internal, random sync pulse starts with first HIGH (drop pre-high low)

            % preprocess internal sync pulse
            if ~isempty(dataSyncInt)                                                    % only if loaded
                try                                                                     % report, do not stop the batch
                    [session.syncInt] = func_get_SPOUT_sync_internal(dataSyncInt);            % edges of internal sync pulse
                catch err                                                               % malformed file
                    warning('spout:syncIntFailed', [sess_name ': internal sync pulse preprocessing failed: ' err.message])
                end
            end


            %% external sync pulse
            % external sync pulse as received by the Teensy - duration column is the PREVIOUS state
            % a starting ExtSync_off (line idle high before the external sync pulse started) is dropped

            % preprocess external sync pulse
            if ~isempty(dataSyncExt)                                                    % only if loaded
                try                                                                     % report, do not stop the batch
                    [session.syncExt] = func_get_SPOUT_sync_external(dataSyncExt);            % edges of external sync pulse
                    disp(['External sync pulse: ' num2str(session.syncExt.n_pulses) ' pulses, first to last ' num2str(session.syncExt.first_to_last_s) ' s'])  % feedback
                catch err                                                               % malformed file
                    warning('spout:syncExtFailed', [sess_name ': external sync pulse preprocessing failed: ' err.message])
                end
            end


            %% save data

            % make new directory in user_dir_save
            save_dir = [preprocessed_dir '\' animal_name];                % animal folder, named after AnimalName in *_Settings.csv
            mkdir([save_dir '\' dir_sessions(cc).name '\behavior'])

            % save data
            % save([dir_animals(c).name '\' dir_sessions(cc).name '\' session.info.name 'c_' session.info.date '_preprocess'], 'session')
            save([save_dir '\' dir_sessions(cc).name '\behavior\' animal_name '_' session.info.date '_beh_preprocess'], 'session')   % animal_date_beh_preprocess.mat
            disp('Done saving data')


            %% plot session average data

            if LLLR_plot_fig_session == true

                % get figure inputs
                coolors = [106/255 153/255 78/255; 188/255 71/255 73/255; 46/255 134/255 177/255];  % green/red/blue

                % plot LLLR session figure
                plot_LLLR_daily_session(coolors, session.info, session.trial_data, session.session_data)

                % save figure - add opto if needed
                if session.info.opto == 1
                    % % % saveas(gcf, [save_dir '\' 'session_' session.info.name '_' session.info.date '_opto_' session.info.opto_side '_' session.info.opto_epoch '.jpg'])
                    saveas(gcf, [save_dir '\' 'beh_' session.info.date '_' animal_name '_opto_' session.info.opto_side '_' session.info.opto_epoch '.jpg'])   % beh_date_animal_opto
                else
                    % % % saveas(gcf, [save_dir '\' 'session_' session.info.name '_' session.info.date '.jpg'])
                    saveas(gcf, [save_dir '\' 'beh_' session.info.date '_' animal_name '.jpg'])   % beh_date_animal
                end
                disp('Done saving session figure')
            end


            %% plot histogram licks

            if LLLR_plot_fig_lick_raster == true

                % fixed vars
                dot_size = 10;
                x_min = -2000;
                x_max = session.info.selection_period/2;

                % plot LLLR licks figure
                plot_LLLR_daily_licks(dot_size, x_min, x_max, session.licks_data)

                % save figure
                % % % saveas(gcf, [save_dir '\' 'lick_histogram_' session.info.name '_' session.info.date '.jpg'])
                saveas(gcf, [save_dir '\' 'beh_' session.info.date '_' animal_name '_lick_histogram.jpg'])   % beh_date_animal_lick_histogram
                disp('Done saving licks histogram')
            end

        else
            if isempty(tmp_chk_dir_beh)                                    % raw folder is empty
                disp(['animal: ' dir_animals(c).name ' session: ' dir_sessions(cc).name ' is empty'])
            elseif isempty(animal_name)                                    % no AnimalName, warning given above
                disp(['animal: ' dir_animals(c).name ' session: ' dir_sessions(cc).name ' skipped, no AnimalName'])
            else
                disp(['animal: ' animal_name ' session: ' dir_sessions(cc).name ' already done'])
            end
        end     % check if we need to run in the first place
        
    end     % loopje session

end     % loopje animal

toc

%% plot across sessions

if LLLR_plot_across_session_after_preprocessing == true

    % answers to the questions of universal_LLLR_plot_across_sessions
    plot_args = struct;
    plot_args.cohort_dir = preprocessed_dir;    % cohort folder with preprocessed data
    plot_args.session_mode = 'all';             % 'all' or 'fixed'
    plot_args.skip_first = [];                  % only used for 'fixed'
    plot_args.skip_last = [];                   % only used for 'fixed'
    plot_args.excl_blocks_start = 2;            % blocks to exclude from start of session
    plot_args.excl_blocks_end = 2;              % blocks to exclude from end of session
    plot_args.delete_old_figures_folders = true; % remove previous across session folders

    % run plotting script (clears workspace, so keep this as the last step)
    func_log_warnings('session', 'across sessions plot')    % warnings below belong to the across sessions figures
    universal_LLLR_plot_across_sessions
end

% list all warnings of this run together (func_log_warnings keeps no variables, so the cleared workspace does not matter)
func_log_warnings('print')


