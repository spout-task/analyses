%% SPOUT1 preprocess data
%
% What it does: preprocesses the behavior of the one spout task (SPOUT1, for example
% Pavlovian conditioning), recorded with the Teensy and the SPOUT1 MATLAB GUI.
% Batch script: you select one cohort folder and it processes every session in it.
% Per session it reads the csv files, extracts session settings, licks, trials, blocks
% and a session summary, reads the internal and external sync pulses, saves one .mat
% file and plots one session figure.
%
% How to run: press Run, select the behavior folder of a cohort in data_raw, then
% answer y (replace) or n (skip, default) for sessions that were preprocessed before.
%
% Raw data (input), one flat folder per session named YYYYMMDD_animal:
%   ...\data_raw\<cohort>\behavior\YYYYMMDD_animal\
%       *_Settings.csv       task settings
%       *_Events.csv         all task events and licks
%       *_Blocks.csv         block information
%       *_SyncPulses.csv     internal sync pulse (Teensy)
%       *_ExtSyncPulses.csv  external sync pulse (for example from imaging)
%o 
% Preprocessed data (output): the path is copied from data_raw, with data_raw
% replaced by data_preprocessed and the behavior level dropped:
%   ...\data_preprocessed\<cohort>\<animal>\YYYYMMDD\behavior\YYYYMMDD_animal_beh_preprocess.mat
%   ...\data_preprocessed\<cohort>\<animal>\beh_YYYYMMDD_animal.jpg
% The .mat file holds one struct, session. Figures sit in the animal folder,
% so all days of one animal can be browsed with the arrow keys.
% Other steps (imaging) add their own folder next to behavior in <animal>\YYYYMMDD.
%
% Rules: the path of the selected folder must contain data_raw once, otherwise 
% the script stops. The animal name is taken only from AnimalName in *_Settings.csv,
% never from folder or file names, so <animal> in the output is AnimalName. The date
% is the first part of the session folder name (YYYYMMDD), as in SPOUT2; the rest of
% the folder name is ignored. A session without exactly one *_Settings.csv
% with an AnimalName is skipped with a warning. Animal names may not contain an
% underscore. A missing or broken sync pulse file gives a warning and that sync
% pulse is skipped.
%
% Depends on: func_get_SPOUT1_* and plot_Pavlovian_daily_session (this folder),
% func_load_SPOUT_sync_csv, func_get_SPOUT_sync_internal and func_get_SPOUT_sync_external
% (behavior\SPOUT_shared_functions), func_log_warnings (behavior\miscellaneous_functions).
%
% Warnings: problems that do not stop the script (for example a wrong number of
% behavior files) give a warning with an identifier in the command window, no popups.
% At the end of the run all warnings are listed again per session (func_log_warnings).
%
% Note: the Teensy logs correct, incorrect, reward and noreward separately, because
% with probabilistic rewards (for example in the Go NoGo, stop and ratio tasks)
% a correct choice is not always rewarded.

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
warn_ext_sync_absent = true; % external sync pulse: false = do not warn when ExtSyncPulses.csv is missing, 0 bytes or has no rows (not recorded)


% plot figs or not
Pavlovian_plot_fig_session = true;
% ask user for folder with video and framenumber
% % % raw_dir = uigetdir('', 'Select cohort directory that you need to preprocess [cohort/animal/date/behavior]');
raw_dir = uigetdir('', 'Select the behavior folder of the cohort [data_raw/cohort/behavior]');
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

% notify the user we will store the data in data_preprocessed
% as SPOUT2: copy of the data_raw path, but now data_preprocessed, and without the behavior level
[cohort_raw_dir, sel_name] = fileparts(raw_dir);                          % strip the behavior level
if ~strcmp(sel_name, 'behavior')                                          % expect data_raw\cohort\behavior
    error('spout:notBehaviorFolder', ['Select the cohort behavior folder, not: ' raw_dir])
end
if numel(strfind(cohort_raw_dir, '\data_raw\')) ~= 1                      % need exactly one data_raw level
    error('spout:noDataRaw', ['Path must contain one data_raw folder: ' raw_dir])   % never write into raw data
end
preprocessed_dir = strrep(cohort_raw_dir, '\data_raw\', '\data_preprocessed\'); % ...\data_preprocessed\cohort
disp('IMPORTANTLY, preprocessed data will be stored in:')
disp([preprocessed_dir '\animal\date\behavior'])

% find all animals
dir_animals = dir;  % get animal folders
dir_animals = dir_animals([dir_animals.isdir]); % only keep folders
tmp = {dir_animals([dir_animals.isdir]).name};  % get names
dir_animals = dir_animals(~ismember(tmp, {'.', '..'})); % remove . and ..


%% per animal, loop through folders
c=1;
dir_sessions = dir_animals;
% % % % loopje animal
% % % for c = 1:size(dir_animals,1) % per animal
% % % 
% % %     %% find sessions to preprocess
% % %     dir_sessions = dir([raw_dir '\' dir_animals(c).name]);  % get session folders
% % %     tmp = {dir_sessions([dir_sessions.isdir]).name}; % get names
% % %     dir_sessions = dir_sessions(~ismember(tmp, {'.', '..'})); % remove . and ..

    %% loopje session
    for cc = 1:size(dir_sessions,1) % per session

        %% clean workspace
        close all
        clearvars -except raw_dir user_replace preprocessed_dir dir_animals dir_sessions c cc Pavlovian_plot_fig_session warn_ext_sync_absent
        session = struct;   % make struct to store data
        func_log_warnings('session', dir_sessions(cc).name)    % warnings below belong to this session

        % date from the session folder name YYYYMMDD(_anything), the animal name is NOT taken from the folder
        sess_parts = strsplit(dir_sessions(cc).name, '_');                 % split folder name at underscores
        sess_date = sess_parts{1};                                         % YYYYMMDD, not checked, as in SPOUT2

        % are there files in the current session, i.e., is the current session folder not empty?
        % % % tmp_chk_dir_beh = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior']);
        tmp_chk_dir_beh = dir([raw_dir '\' dir_animals(cc).name '\' ]);
        tmp_chk_dir_beh([tmp_chk_dir_beh.isdir]) = [];  % delete dirs (. and ..)

        % warning to notify use of empty folder
        if isempty(tmp_chk_dir_beh)
            warning('spout:emptyFolder', ['animal: ' dir_animals(cc).name ', session: ' dir_sessions(cc).name ' is an empty folder'])   % no popup, listed again at the end
        end

        % animal name: only from AnimalName in *_Settings.csv, never from folder or file names
        animal_name = '';                                                  % empty until found
        file_dataSettings = dir([raw_dir '\' dir_animals(cc).name '\' '*Settings.csv']);   % exp settings
        if numel(file_dataSettings) == 1                                   % exactly one settings file
            opts = delimitedTextImportOptions("NumVariables", 2);          % specify columns in _Settings.csv
            dataSettings = readmatrix([raw_dir '\' dir_animals(cc).name '\' file_dataSettings.name], opts);   % settings as cell array
            idx_name = find(strcmp(dataSettings(:, 1), 'AnimalName'), 1);  % row that holds the animal name
            if ~isempty(idx_name)                                          % row found
                animal_name = strtrim(dataSettings{idx_name, 2});          % animal name as typed in the GUI
            end
        end
        if isempty(animal_name) & ~isempty(tmp_chk_dir_beh)               % files present but no usable name
            warning('spout:noAnimalName', ['Session folder: ' dir_sessions(cc).name ', not exactly one *_Settings.csv with an AnimalName, session skipped'])   % no popup, listed again at the end
        end
        sess_dir_out = [preprocessed_dir '\' animal_name '\' sess_date '\behavior'];   % output folder of this session

        % have we preprocessed this session before?
        tmp_chk_preproc = [];                                              % nothing found yet
        if ~isempty(animal_name)                                           % only with a valid animal name
            tmp_chk_preproc = dir([sess_dir_out '\' '*_preprocess.mat']);  % earlier output of this session
        end

        %% check if we need to preprocess this session
        if ( user_replace == 'y' | (user_replace == 'n' & isempty(tmp_chk_preproc)) ) & ~isempty(tmp_chk_dir_beh) & ~isempty(animal_name)  % preprocess if ('Y' or (if 'N' AND empty)) AND not empty folder AND animal name found

            % user feedback
            % % % disp(['Loading data of animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name])
            disp(['Loading data of animal: ' animal_name ' - folder: ' dir_sessions(cc).name])

            % % % % get files
            % % % file_dataSettings = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Settings.csv']);    % exp settings
            % % % file_dataEvents = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Events.csv']);        % raw events
            % % % file_dataBlocks = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Blocks.csv']);        % raw blocks
            % % % file_extSync = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*ExtSyncPulses.csv']);        % raw blocks

            % get files (settings file was found and loaded above)
            file_dataEvents = dir([raw_dir '\' dir_animals(cc).name '\' '*Events.csv']);        % raw events
            file_dataBlocks = dir([raw_dir '\' dir_animals(cc).name '\' '*Blocks.csv']);        % raw blocks
            % ExtSyncPulses.csv and SyncPulses.csv are loaded once, below (func_load_sync_csv)

            % % % % load data
            % % % opts = delimitedTextImportOptions("NumVariables", 2); % specify columns in _Settings.csv
            % % % dataSettings = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataSettings.name], opts);
            % % % opts = delimitedTextImportOptions("NumVariables", 7); % specify columns in _Events.csv
            % % % dataEvents = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataEvents.name], opts);
            % % % opts = delimitedTextImportOptions("NumVariables", 14); % specify columns in _Blocks.csv
            % % % dataBlocks = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataBlocks.name], opts);
            % % % opts = delimitedTextImportOptions("NumVariables", 3); % specify columns in ExtSyncPulses.csv
            % % % dataExtSync = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_extSync.name], opts);

            % load data (dataSettings was loaded above)
            opts = delimitedTextImportOptions("NumVariables", 7); % specify columns in _Events.csv
            dataEvents = readmatrix([raw_dir '\' dir_animals(cc).name '\' file_dataEvents.name], opts);
            opts = delimitedTextImportOptions("NumVariables", 14); % specify columns in _Blocks.csv
            dataBlocks = readmatrix([raw_dir '\' dir_animals(cc).name '\' file_dataBlocks.name], opts);

            % load sync pulses (always; missing or empty gives a warning, see func_load_sync_csv)
            sess_dir = [raw_dir '\' dir_animals(cc).name];                                                      % flat session folder
            dataSyncInt = func_load_SPOUT_sync_csv(sess_dir, '*_SyncPulses.csv', 'internal', dir_animals(cc).name);    % internal sync pulse (pattern does not match *_ExtSyncPulses.csv)
            dataSyncExt = func_load_SPOUT_sync_csv(sess_dir, '*_ExtSyncPulses.csv', 'external', dir_animals(cc).name, warn_ext_sync_absent); % external sync pulse


            %% check files
            % make sure behavioral folder has 5 files

            % find files
            % % % tmp_beh = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\']);
            tmp_beh = dir([raw_dir '\' dir_animals(cc).name '\']);
            tmp_beh([tmp_beh.isdir]) = []; % remove . and ..

            % check number beh
            if length(tmp_beh) ~= 5
                % % % disp(['animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files'])
                % % % msgbox(['animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files'])
                warning('spout:nBehFiles', ['animal: ' dir_animals(cc).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files (' num2str(length(tmp_beh)) ' instead of 5)'])   % no popup, listed again at the end
            end

            %% session info (dataSettings)

            % get data in struct
            session.info = func_get_SPOUT1_settings(dataSettings, dir_sessions(cc).name);

    
            %% lick data timestamps (dataEvents)

            % get data in struct - keep trial_info to calculate trial_data
            % licks_data aligned to cue, licks_data_abs not aligned (absolute timestamp, Teensy clock ms)
            [session.licks_data, session.licks_data_abs, trial_info, dataEvents] = func_get_SPOUT1_licks(dataEvents, session.info);


            %% trial data (dataEvents, trial_info)

            % get data
            [session.trial_data, trial_info] = func_get_SPOUT1_trials(dataEvents, trial_info);

            % update licks_data with trial_data opto
            [session.licks_data.opto] = deal(session.trial_data.opto);
            [session.licks_data_abs.opto] = deal(session.trial_data.opto);


            %% block data (dataBlocks)

            % get data
            correct_trials2switch = 1; % if 0, don't correct for first trial
            [session.block_data] = func_get_SPOUT1_blocks(dataBlocks, session.trial_data, correct_trials2switch);


            %% session data (dataTrial, dataLick)

            % get data
            [session.session_data] = func_get_SPOUT1_session(session.trial_data, session.block_data, session.licks_data);


            %% internal sync pulse
            % internal, random sync pulse starts with first HIGH (drop pre-high low)

            % preprocess internal sync pulse
            if ~isempty(dataSyncInt)                                                    % only if loaded
                try                                                                     % report, do not stop the batch
                    [session.syncInt] = func_get_SPOUT_sync_internal(dataSyncInt);            % edges of internal sync pulse
                catch err                                                               % malformed file
                    warning('spout:syncIntFailed', [dir_animals(cc).name ': internal sync pulse preprocessing failed: ' err.message])
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
                    warning('spout:syncExtFailed', [dir_animals(cc).name ': external sync pulse preprocessing failed: ' err.message])
                end
            end


            %% save data

            % make new directory in user_dir_save
            % % % save_dir = [preprocessed_dir '\' dir_animals(c).name];
            % % % mkdir([save_dir '\' dir_sessions(cc).name '\behavior'])
            % % % save_dir = [preprocessed_dir '\' dir_animals(cc).name];
            % % % mkdir([save_dir '\behavior'])
            save_dir = [preprocessed_dir '\' animal_name];                % animal folder named after AnimalName, holds the session figures
            if ~isfolder(sess_dir_out)                                    % make animal\date\behavior on the first run
                mkdir(sess_dir_out)
            end

            % save data
            % save([dir_animals(c).name '\' dir_sessions(cc).name '\' session.info.name 'c_' session.info.date '_preprocess'], 'session')
            % % % save([save_dir '\behavior\' dir_animals(cc).name '_beh_preprocess'], 'session')
            save([sess_dir_out '\' sess_date '_' animal_name '_beh_preprocess'], 'session')   % YYYYMMDD_animal_beh_preprocess.mat, animal from AnimalName
            disp('Done saving data')


            %% plot session average data

            if Pavlovian_plot_fig_session == true

                % get figure inputs
                % coolors = [106/255 153/255 78/255; 188/255 71/255 73/255; 46/255 134/255 177/255];  % blue/red/orange
                coolors = [42/255 157/255 143/255; 231/255 111/255 81/255; 233/255 196/255 106/255];  % green/red/yellow

                % plot LLLR session figure
                plot_Pavlovian_daily_session(coolors, session.info, session.trial_data, session.session_data, session.licks_data)

                % save figure - add opto if needed
                % % % saveas(gcf, [save_dir '\' 'session_' session.info.name '_' session.info.date '.jpg'])
                % % % saveas(gcf, [preprocessed_dir '\' 'session_' dir_animals(cc).name '.jpg'])
                saveas(gcf, [save_dir '\' 'beh_' sess_date '_' animal_name '.jpg'])   % beh_YYYYMMDD_animal, jpg in the animal folder
                disp('Done saving session figure')

            end


        else
            if isempty(tmp_chk_dir_beh)                                    % raw folder is empty
                disp(['Session folder: ' dir_sessions(cc).name ' is empty'])
            elseif isempty(animal_name)                                    % no AnimalName, warning given above
                disp(['Session folder: ' dir_sessions(cc).name ' skipped, no AnimalName'])
            else
                disp(['animal: ' animal_name ' session folder: ' dir_sessions(cc).name ' already done'])
            end
        end     % check if we need to run in the first place
    end     % loopje session
% end     % loopje animal

toc

% list all warnings of this run together
func_log_warnings('print')


