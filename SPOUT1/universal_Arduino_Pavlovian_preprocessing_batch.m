%% Pavlovian task preprocessing Arduino output
% oneSpout task

% script preprocesses Arduino/Matlab GUI output
% data directories should be: main_dir/session_animal/ -> raw data

% batch script processes all animals all sessions

% TO DO:
% - add ExtSyncPulse

%% find dir

% clear matlab
clearvars
close all force
tic

% plot figs or not
plot_fig_session = true;

% ask user for folder with video and framenumber
% % % raw_dir = uigetdir('', 'Select cohort directory that you need to preprocess [cohort/animal/date/behavior]');
raw_dir = uigetdir('', 'Select cohort directory that you need to preprocess [cohort/session_animal]');
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
% % % preprocessed_dir = '\\research.files.med.harvard.edu\Neurobio\MICROSCOPE\Bastijn\data_preprocessed\behavior\Pavlovian';
preprocessed_dir = [raw_dir '\_preprocessed'];
% % % tmp = strsplit(raw_dir, '\');
% % % preprocessed_dir = [preprocessed_dir '\' tmp{end}];
disp('IMPORTANTLY, preprocessed data will be stored in:')
disp([preprocessed_dir])

% find all animals
dir_animals = dir;  % get animal folders
dir_animals = dir_animals([dir_animals.isdir]); % only keep folders
tmp = {dir_animals([dir_animals.isdir]).name};  % get names
dir_animals = dir_animals(~ismember(tmp, {'.', '..'})); % remove . and ..

% remove _preprocessed
for k=size(dir_animals,1):-1:1
    if strcmp(dir_animals(k).name, '_preprocessed')
        dir_animals(k) = [];
    end
end


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
        % close all
        clearvars -except raw_dir user_replace preprocessed_dir dir_animals dir_sessions c cc plot_fig_session
        session = struct;   % make struct to store data

        % have we preprocessed this session before?
        try % check if we can find the folder
            % % % tmp_chk_preproc = dir([preprocessed_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*_preprocess.mat']);
            tmp_chk_preproc = dir([preprocessed_dir '\' dir_animals(cc).name '\behavior\' '*_preprocess.mat']);
        catch
            tmp_chk_preproc = [];
        end

        % are there files in the current session, i.e., is the current session folder not empty?
        % % % tmp_chk_dir_beh = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior']);
        tmp_chk_dir_beh = dir([raw_dir '\' dir_animals(cc).name '\' ]);
        tmp_chk_dir_beh([tmp_chk_dir_beh.isdir]) = [];  % delete dirs (. and ..)

        % message box to notify use of empty folder
        if isempty(tmp_chk_dir_beh)
            msgbox(['Animal: ' dir_animals(cc).name ', session: ' dir_sessions(cc).name ' is an empty folder'], 'Empty folder detected')
        end

        %% check if we need to preprocess this session
        if ( user_replace == 'y' | (user_replace == 'n' & isempty(tmp_chk_preproc)) ) & ~isempty(tmp_chk_dir_beh)  % preprocess if ('Y' or (if 'N' AND empty)) AND not empty folder

            % user feedback
            % % % disp(['Loading data of animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name])
            disp(['Loading data of animal: ' dir_animals(cc).name])

            % % % % get files
            % % % file_dataSettings = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Settings.csv']);    % exp settings
            % % % file_dataEvents = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Events.csv']);        % raw events
            % % % file_dataBlocks = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*Blocks.csv']);        % raw blocks
            % % % file_extSync = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' '*ExtSyncPulses.csv']);        % raw blocks

            % get files
            file_dataSettings = dir([raw_dir '\' dir_animals(cc).name '\' '*Settings.csv']);    % exp settings
            file_dataEvents = dir([raw_dir '\' dir_animals(cc).name '\' '*Events.csv']);        % raw events
            file_dataBlocks = dir([raw_dir '\' dir_animals(cc).name '\' '*Blocks.csv']);        % raw blocks
            file_extSync = dir([raw_dir '\' dir_animals(cc).name '\' '*ExtSyncPulses.csv']);        % raw blocks

            % % % % load data
            % % % opts = delimitedTextImportOptions("NumVariables", 2); % specify columns in _Settings.csv
            % % % dataSettings = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataSettings.name], opts);
            % % % opts = delimitedTextImportOptions("NumVariables", 7); % specify columns in _Events.csv
            % % % dataEvents = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataEvents.name], opts);
            % % % opts = delimitedTextImportOptions("NumVariables", 14); % specify columns in _Blocks.csv
            % % % dataBlocks = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_dataBlocks.name], opts);
            % % % opts = delimitedTextImportOptions("NumVariables", 3); % specify columns in ExtSyncPulses.csv
            % % % dataExtSync = readmatrix([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\' file_extSync.name], opts);

            % load data
            opts = delimitedTextImportOptions("NumVariables", 2); % specify columns in _Settings.csv
            dataSettings = readmatrix([raw_dir '\' dir_animals(cc).name '\' file_dataSettings.name], opts);
            opts = delimitedTextImportOptions("NumVariables", 7); % specify columns in _Events.csv
            dataEvents = readmatrix([raw_dir '\' dir_animals(cc).name '\' file_dataEvents.name], opts);
            opts = delimitedTextImportOptions("NumVariables", 14); % specify columns in _Blocks.csv
            dataBlocks = readmatrix([raw_dir '\' dir_animals(cc).name '\' file_dataBlocks.name], opts);
            opts = delimitedTextImportOptions("NumVariables", 3); % specify columns in ExtSyncPulses.csv
            dataExtSync = readmatrix([raw_dir '\' dir_animals(cc).name '\' file_extSync.name], opts);


            %% check files
            % make sure behavioral folder has 5 files

            % find files
            % % % tmp_beh = dir([raw_dir '\' dir_animals(c).name '\' dir_sessions(cc).name '\behavior\']);
            tmp_beh = dir([raw_dir '\' dir_animals(cc).name '\']);
            tmp_beh([tmp_beh.isdir]) = []; % remove . and ..

            % check number beh
            if length(tmp_beh) ~= 5
                % % % disp(['Animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files'])
                % % % msgbox(['Animal: ' dir_animals(c).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files'])
                disp(['Animal: ' dir_animals(cc).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files'])
                msgbox(['Animal: ' dir_animals(cc).name ' - session: ' dir_sessions(cc).name ', incorrect number of behavioral files'])
            end

            %% session info (dataSettings)

            % get data in struct
            session.info = func_get_Arduino_oneSpout_settings(dataSettings, dir_sessions(cc).name);

    
            %% lick data timestamps (dataEvents)

            % get data in struct - keep trial_info to calculate trial_data
            [session.licks_data, trial_info, dataEvents] = func_get_Arduino_oneSpout_licks(dataEvents, session.info);


            %% trial data (dataEvents, trial_info)

            % get data
            [session.trial_data, trial_info] = func_get_Arduino_oneSpout_trials(dataEvents, trial_info);

            % update licks_data with trial_data opto
            [session.licks_data.opto] = deal(session.trial_data.opto);


            %% block data (dataBlocks)

            % get data
            correct_trials2switch = 1; % if 0, don't correct for first trial
            [session.block_data] = func_get_Arduino_oneSpout_blocks(dataBlocks, session.trial_data, correct_trials2switch);


            %% session data (dataTrial, dataLick)

            % get data
            [session.session_data] = func_get_Arduino_oneSpout_session(session.trial_data, session.block_data);


            %% save data

            % make new directory in user_dir_save
            % % % save_dir = [preprocessed_dir '\' dir_animals(c).name];
            % % % mkdir([save_dir '\' dir_sessions(cc).name '\behavior'])
            save_dir = [preprocessed_dir '\' dir_animals(cc).name];
            mkdir([save_dir '\behavior'])

            % save data
            % save([dir_animals(c).name '\' dir_sessions(cc).name '\' session.info.name 'c_' session.info.date '_preprocess'], 'session')
            save([save_dir '\behavior\' dir_animals(cc).name '_beh_preprocess'], 'session')
            disp('Done saving data')


            %% plot session average data

            if plot_fig_session == true

                % get figure inputs
                % coolors = [106/255 153/255 78/255; 188/255 71/255 73/255; 46/255 134/255 177/255];  % blue/red/orange
                coolors = [42/255 157/255 143/255; 231/255 111/255 81/255; 233/255 196/255 106/255];  % green/red/yellow

                % plot LLLR session figure
                plot_Pavlovian_daily_session(coolors, session.info, session.trial_data, session.session_data, session.licks_data)

                % save figure - add opto if needed
                % % % saveas(gcf, [save_dir '\' 'session_' session.info.name '_' session.info.date '.jpg'])
                saveas(gcf, [preprocessed_dir '\' 'session_' dir_animals(cc).name '.jpg'])
                disp('Done saving session figure')

            end


        else
            if isempty(tmp_chk_preproc) & isempty(tmp_chk_dir_beh)  % check if folder is empty
                % % % disp(['Animal: ' dir_animals(c).name ' session: ' dir_sessions(cc).name ' is empty'])
                disp(['Animal: ' dir_animals(cc).name ' session: ' dir_sessions(cc).name ' is empty'])
            else
                % % % disp(['Animal: ' dir_animals(c).name ' session: ' dir_sessions(cc).name ' already done'])
                disp(['Animal: ' dir_animals(cc).name ' session: ' dir_sessions(cc).name ' already done'])
            end
        end     % check if we need to run in the first place
    end     % loopje session
% end     % loopje animal


toc






