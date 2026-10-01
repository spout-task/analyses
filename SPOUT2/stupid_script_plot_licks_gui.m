% stupid script to plot licks of GUI

clc; clearvars; close all

% load [date]_[animal]_Data.csv file
[file, location] = uigetfile('*.csv');
cd(location)
RawData = readtable(file);

% % get trials
% cnt=1;
% for k=1:size(RawData,1) % data rows
%     if strcmp(string(table2cell(RawData(k,5))), 'NEW_TRIAL')
%         trials(cnt) = table2array(RawData(k,6));
%         cnt=cnt+1;
%     end
% end
% trials(end+1) = table2array(RawData(end,6));

% assign events to trials
% % cnt=1;
% % for k=1:size(trials,2)-1    % trials
% %     for kk=1:size(RawData,1) % data rows
% %         if table2array(RawData(kk,6)) >= trials(k) && table2array(RawData(kk,6)) < trials(k+1)
% %             RawData(kk,8) = {cnt};
% %         end
% %     end
% %     cnt=cnt+1;
% % end
% PROBLEM here is that a lick can happen at the end of OUTCOME, continue
% during start of ENL, thereby triggering a ENL_PENALTY

% assign trial number to rows
cnt=1;
new_trial = find(strcmp(table2array(RawData(:,5)), 'NEW_TRIAL') == 1);
new_trial(end+1) = size(RawData,1);
for k=1:size(new_trial,1)-1    % trials
    RawData(new_trial(k):new_trial(k+1)-1, 8) = {cnt};
    cnt=cnt+1;    
end


% get licks
cnt=1;
for k=1:size(RawData,1) % data rows
    if strcmp(string(table2cell(RawData(k,5))), 'LickLeft')
        %         tmp(cnt,1) = 1; % store direction
        %         tmp(cnt,2) = table2array(RawData(k,6));
        %         cnt=cnt+1;
        rev_cnt=k-1;    % reversed counter
        while ~strcmp(string(table2cell(RawData(rev_cnt,5))), 'SELECTION')  % find selection
            rev_cnt=rev_cnt-1;
        end
        tmp(cnt,1) = table2array(RawData(k,8));  % store trial
        tmp(cnt,2) = 1; % store direction
        tmp(cnt,3) = table2array(RawData(k,6)) - table2array(RawData(rev_cnt,6));
        cnt=cnt+1;
    elseif strcmp(string(table2cell(RawData(k,5))), 'LickRight')
        %         tmp(cnt,1) = 2; % store direction
        %         tmp(cnt,2) = table2array(RawData(k,6));
        %         cnt=cnt+1;
        rev_cnt=k-1;    % reversed counter
        while ~strcmp(string(table2cell(RawData(rev_cnt,5))), 'SELECTION')  % find selection
            rev_cnt=rev_cnt-1;
        end
        tmp(cnt,1) = table2array(RawData(k,8));  % store trial
        tmp(cnt,2) = 2; % store direction
        tmp(cnt,3) = table2array(RawData(k,6)) - table2array(RawData(rev_cnt,6));
        cnt=cnt+1;
    end
end



%% plot licks

figure
hold on
cnt=1;
for k=min(tmp(:,1)):max(tmp(:,1))
    idx = find(tmp(:,1)==k);
    for kk=1:length(idx)
        if tmp(cnt,2) == 1;
            scatter(tmp(idx(kk),3), [k], 'filled', 'm')
        else
            scatter(tmp(idx(kk),3), [k], 'filled', 'c')
        end
        cnt=cnt+1;
    end
end
ylim([0 max(tmp(:,1))+1])


%% get session trials

% struct trials
trialData = struct;
trialData.leftRight = [];           % 1 2
trialData.correctWrongOmis = [];    % 1 2 3
trialData.duration = [];            % duration in ms

% loop through trials
maxTrials = table2array(RawData(end,1));
for k=1:maxTrials
    % idx trial rows
    idx = find(table2array(RawData(:,1)) == k);

    % check if animal made choice lick
    for kk=idx(1):idx(end)
        event = table2array(RawData(kk,5));
        if strcmp(event, '# CORRECT LEFT')
            % check if correct left or right
            trialData(k).leftRight = 1;
            trialData(k).correctWrongOmis = 1;
            trialData(k).duration = table2array(RawData(kk,6)) - table2array(RawData(kk-1,6));
        elseif strcmp(event, '# CORRECT RIGHT')
            % check if correct left or right
            trialData(k).leftRight = 2;
            trialData(k).correctWrongOmis = 1;
            trialData(k).duration = table2array(RawData(kk,6)) - table2array(RawData(kk-1,6));
        elseif strcmp(event, '# Incorrect LEFT')
            % check if correct left or right
            trialData(k).leftRight = 2;
            trialData(k).correctWrongOmis = 2;
            trialData(k).duration = table2array(RawData(kk,6)) - table2array(RawData(kk-1,6));
        elseif strcmp(event, '# Incorrect RIGHT')
            % check if correct left or right
            trialData(k).leftRight = 1;
            trialData(k).correctWrongOmis = 2;
            trialData(k).duration = table2array(RawData(kk,6)) - table2array(RawData(kk-1,6));
        elseif strcmp(event, '# Timeout')
            % check if correct left or right
            if strcmp(table2array(RawData(idx(1),5)), 'ENL_LEFT')
                trialData(k).leftRight = 1;
            elseif strcmp(table2array(RawData(idx(1),5)), 'ENL_RIGHT')
                trialData(k).leftRight = 2;
            end
            trialData(k).correctWrongOmis = 3;
            trialData(k).duration = table2array(RawData(kk,6)) - table2array(RawData(kk-1,6));
        end
    end
end

%% plot session trials

% colors
coolors = [106/255 153/255 78/255; 188/255 71/255 73/255; 46/255 134/255 177/255];  % green/red/blue outcome
x_data = [1: length(trialData)];
% y_min = 1;
% y_max = 500;
% min_size = 2;
% scale_factor = 15;
reduct = 2;

figure('Position', [10 300 800 150])
hold on
for k=1:length(trialData)   % per trial
    % get size of dot
    if trialData(k).duration <= 500 % lick is 0.5 seconds or less (very fast)
        size_dot = 20/reduct;
    elseif trialData(k).duration <= 1000 % lick is between 0.5 and 1 seconds (fast)
        size_dot = 35/reduct;
    elseif trialData(k).duration <= 3000 % lick is between 1 and 3 seconds (fine)
        size_dot = 50/reduct;
    elseif trialData(k).duration > 3000 % lick is slower than 3 seconds (bad)
        size_dot = 65/reduct;
    end

    plot(x_data(k), trialData(k).leftRight, '.', ...
        'MarkerSize', size_dot, ...    % marker size 
        'MarkerEdgeColor', coolors(trialData(k).correctWrongOmis,:))                % color represents outcome
end
hold off
% xlim([75 175])
xlim([x_data(1) x_data(end)])
ylim([0.5 2.5])    % y limit
yticks([0 1])
yticklabels({'L', 'R'})
ylabel('Licks')
title('')






