% LLLR task Arduino output
% plot session

function plot_Pavlovian_daily_session(coolors, dataInfo, dataTrial, dataSession, dataLick)

% fixed vars
mrk_size = 25;
sem_alpha = .3;
bin_min = -1000;  % min bin in ms
bin_width = 100; % min bin in ms
bin_max = dataInfo.cue_duration + dataInfo.consumption_period;  % min bin in ms
coolors_epochs = [233/255 236/255 239/255; 222/255 226/255 230/255; 52/255 58/255 64/255]; % cue, delay, outcome


% let's get licking data for CS+, CS-, and free trials
% - distribution across trials (average)
% - bars per epoch (cue, delay, out)

% define min:bin width:max
edges = bin_min:bin_width:bin_max;            % ms; pick bin width to taste
bin_counts = edges(1:end-1) + diff(edges)/2;  % get bin counts

% find licks per bin per trial
nTrials = size(dataTrial,2);
counts = zeros(nTrials, numel(edges)-1); % matrix trials x bins
for k = 1:nTrials
    % trial_idx = RR_trials(k);
    current_trial = [dataLick(k).lick_ITI   dataLick(k).lick_cue ...
        dataLick(k).lick_choice dataLick(k).lick_delay ...
        dataLick(k).lick_outcome dataLick(k).lick_free];
    counts(k,:) = histcounts(current_trial, edges);
end

% convert to licks/s (as timestamps are in ms)
counts =  counts / (bin_width/1000);

% find A/B trials
A_trials = find([dataLick(:).iTrialType] == 1);
B_trials = find([dataLick(:).iTrialType] == 2);
RR_trials = find([dataLick(:).iTrialType] == 3);

% get bin_counts to plot average lick frequency
cue_bins = bin_counts >= 0 & bin_counts < dataInfo.cue_duration;
delay_bins = bin_counts >= dataInfo.cue_duration & bin_counts < dataInfo.cue_duration + dataInfo.reward_delay;
out_bins = bin_counts >= dataInfo.cue_duration + dataInfo.reward_delay;

% get bin count for plotting
licks.A.cue = mean(mean(counts(A_trials, cue_bins)));
licks.A.delay = mean(mean(counts(A_trials, delay_bins)));
licks.A.out = mean(mean(counts(A_trials, out_bins)));
licks.B.cue = mean(mean(counts(B_trials, cue_bins)));
licks.B.delay = mean(mean(counts(B_trials, delay_bins)));
licks.B.out = mean(mean(counts(B_trials, out_bins)));
licks.RR.cue = mean(mean(counts(RR_trials, cue_bins)));
licks.RR.delay = mean(mean(counts(RR_trials, delay_bins)));
licks.RR.out = mean(mean(counts(RR_trials, out_bins)));
y_lim_bar = round(max([licks.A.cue licks.A.delay licks.A.out licks.B.cue licks.B.delay licks.B.out licks.RR.cue licks.RR.delay licks.RR.out])*1.1, 1);
if y_lim_bar == 0 % no licks were made
    y_lim_bar = 1;
end

% get mean + sem per trial-type
mean_A = mean(counts(A_trials,:));
mean_B = mean(counts(B_trials,:));
mean_RR = mean(counts(RR_trials,:));
sem_A = std(counts(A_trials,:)) ./ sqrt(length(A_trials));
sem_B = std(counts(B_trials,:)) ./ sqrt(length(B_trials));
sem_RR = std(counts(RR_trials,:)) ./ sqrt(length(RR_trials));



% plotje here we gooo
figure('Position', [10 300 1400 500])

% subplot
subplot(1,8,1)
data1 = dataSession.trials_A;
data2 = dataSession.trials_B;
data3 = dataSession.free_reward;
hold on
plot(1, data1, '.', 'MarkerSize', mrk_size, 'Color', coolors(1,:))
plot(2, data2, '.', 'MarkerSize', mrk_size, 'Color', coolors(2,:))
plot(3, data3, '.', 'MarkerSize', mrk_size, 'Color', coolors(3,:))
ylim([0 max([data1 data2 data3])*1.1])
xlim([0.5 3.5])
ylabel('# trials')
xticklabels({'CS+', 'CS-', 'Free'})
title('Trials')
y_lim_rew = ylim; % y_lim for reward plot

% subplot
subplot(1,8,2)
data2 = dataSession.reward_A;
data3 = dataSession.free_reward;
hold on
plot(1, data2, '.', 'MarkerSize', mrk_size, 'Color', coolors(1,:))
plot(2, data3, '.', 'MarkerSize', mrk_size, 'Color', coolors(3,:))
ylim([0 max([data2 data3])*1.1])
xlim([0.5 2.5])
ylim([y_lim_rew(1) y_lim_rew(2)])
ylabel('# rewards')
xticklabels({'CS+', 'Free'})
title('Rewards')

% subplot
subplot(1,8,3)
data1 = dataSession.total_licks_A;
data2 = dataSession.total_licks_B;
data3 = dataSession.total_licks - data1 - data2;
hold on
plot(1, data1, '.', 'MarkerSize', mrk_size, 'Color', coolors(1,:))
plot(2, data2, '.', 'MarkerSize', mrk_size, 'Color', coolors(2,:))
plot(3, data3, '.', 'MarkerSize', mrk_size, 'Color', coolors(3,:))
try
ylim([0 max([data1 data2 data3])*1.1])
catch; ylim([0 1]); end % no licks were made
xlim([0.5 3.5])
ylabel('# licks')
xticklabels({'CS+', 'CS-', 'Free'})
title('Licks')

% subplot
subplot(1,8,6)
data1 = licks.A.cue;
data2 = licks.B.cue;
data3 = licks.RR.cue;
% check if licks are not absent
if isnan(data1)
    data1 = 0;
end
if isnan(data2)
    data2 = 0;
end
if isnan(data3)
    data3 = 0;
end
hold on
plot(1, data1, '.', 'MarkerSize', mrk_size, 'Color', coolors(1,:))
plot(2, data2, '.', 'MarkerSize', mrk_size, 'Color', coolors(2,:))
plot(3, data3, '.', 'MarkerSize', mrk_size, 'Color', coolors(3,:))
ylim([0 y_lim_bar])
xlim([0.5 3.5])
ylabel('Lick rate (Hz)')
xticklabels({'CS+', 'CS-', 'Free'})
title('Cue licks')

% subplot
subplot(1,8,7)
data1 = licks.A.delay;
data2 = licks.B.delay;
data3 = licks.RR.delay;
% check if licks are not absent
if isnan(data1)
    data1 = 0;
end
if isnan(data2)
    data2 = 0;
end
if isnan(data3)
    data3 = 0;
end
hold on
plot(1, data1, '.', 'MarkerSize', mrk_size, 'Color', coolors(1,:))
plot(2, data2, '.', 'MarkerSize', mrk_size, 'Color', coolors(2,:))
plot(3, data3, '.', 'MarkerSize', mrk_size, 'Color', coolors(3,:))
ylim([0 y_lim_bar])
xlim([0.5 3.5])
ylabel('Lick rate (Hz)')
xticklabels({'CS+', 'CS-', 'Free'})
title('Delay licks')

% subplot
subplot(1,8,8)
data1 = licks.A.out;
data2 = licks.B.out;
data3 = licks.RR.out;
% check if licks are not absent
if isnan(data1)
    data1 = 0;
end
if isnan(data2)
    data2 = 0;
end
if isnan(data3)
    data3 = 0;
end
hold on
plot(1, data1, '.', 'MarkerSize', mrk_size, 'Color', coolors(1,:))
plot(2, data2, '.', 'MarkerSize', mrk_size, 'Color', coolors(2,:))
plot(3, data3, '.', 'MarkerSize', mrk_size, 'Color', coolors(3,:))
ylim([0 y_lim_bar])
xlim([0.5 3.5])
ylabel('Lick rate (Hz)')
xticklabels({'CS+', 'CS-', 'Free'})
title('Outcome licks')

% subplot - lick raster
subplot(1,8,[4 5])
hold on
% add epoch data - cue, delay, outcome
% y_lim = [round(min([mean_RR-sem_RR mean_B-sem_B mean_A-sem_A])-0.5)+0.1 round(max([mean_RR+sem_RR mean_B+sem_B mean_A+sem_A])*1.1)];
y_lim = [0 round(max([mean_RR+sem_RR mean_B+sem_B mean_A+sem_A])*1.1)];
rectangle('Position', [0 y_lim(1) dataInfo.cue_duration abs(y_lim(1))+y_lim(2)], 'FaceColor', coolors_epochs(1,:), 'EdgeColor', 'none') % cue
rectangle('Position', [dataInfo.cue_duration y_lim(1) dataInfo.reward_delay abs(y_lim(1))+y_lim(2)], 'FaceColor', coolors_epochs(2,:), 'EdgeColor', 'none') % delay
xline(dataInfo.cue_duration + dataInfo.reward_delay, '--', 'Color', coolors_epochs(3,:)) % outcome
text(0, y_lim(2)*.95, 'Cue')
if dataInfo.reward_delay ~= 0
    text(dataInfo.cue_duration, y_lim(2)*.95, 'Delay')
end
% RR
fill([bin_counts fliplr(bin_counts)], [mean_RR+sem_RR fliplr(mean_RR-sem_RR)], ...
    coolors(3,:), 'EdgeColor','none', 'FaceAlpha', sem_alpha);
plot(bin_counts, mean_RR, 'k', 'LineWidth', 1.5, 'Color', coolors(3,:));
% B
fill([bin_counts fliplr(bin_counts)], [mean_B+sem_B fliplr(mean_B-sem_B)], ...
    coolors(2,:), 'EdgeColor','none', 'FaceAlpha', sem_alpha);
plot(bin_counts, mean_B, 'k', 'LineWidth', 1.5, 'Color', coolors(2,:));
% A
fill([bin_counts fliplr(bin_counts)], [mean_A+sem_A fliplr(mean_A-sem_A)], ...
    coolors(1,:), 'EdgeColor','none', 'FaceAlpha', sem_alpha);
plot(bin_counts, mean_A, 'k', 'LineWidth', 1.5, 'Color', coolors(1,:));
xlim([bin_min bin_max])
ylim([y_lim(1)-0.1 y_lim(2)])
xlabel('Time (ms)'); ylabel('Lick rate (Hz)');
title('Lick rate across trials')

