% LLLR task Arduino output
% plot session

function plot_LLLR_daily_session(coolors, dataInfo, dataTrial, dataSession)

% get figure inputs
x_data = [1: size(dataTrial,2)];         % x axis (trials)
y_min = 1;                                   % used to scale lick latency and plot as size dot
y_max = dataInfo.selection_period;           % used to scale lick latency and plot as size dot
% coolors_blr = [168/255 213/255 226/255; 249/255 166/255 32/255; 255/255 212/255 73/255];    % colors of bars
coolors_blr = [0/255 180/255 216/255; 255/255 145/255 0/255; 123/255 44/255 191/255];         % colors of bars
bar_xmin = 0.5;                              % min value for bar graphs
bar_xmax = 3.5;                              % max value for bar graphs
min_size = 2;                                % min size of fastest datapoint
scale_factor = 15;                           % scale size of dots

% plot some session averages
figure('Position', [10 300 1000 400])

% plot raw licks left/right correct/error
subplot(2,13,[1:13])
hold on
for k=1:size(dataTrial,2)  % per trial

    % plot placeholders for free reward, cue penalty, enl penalty, opto
    scatter([ones(1,4) * k], [1 2 3 4], 'Marker', '.', 'MarkerEdgeColor', [0.85 0.85 0.85], 'MarkerFaceColor', [0.85 0.85 0.85]);

    % plot trial outcome
    tmp = getDotSize(dataTrial(k).t_selection, dataInfo.selection_period);
    plot(x_data(k), dataTrial(k).iTrialType+4, '.', ...
        'MarkerSize', tmp, ...    % marker size scaled latency (invert by: ((ymin + ymax) - value /2) /100) ((y_min+y_max) - dataTrial_new.t_selection(k)/2) /100
        'MarkerEdgeColor', coolors(dataTrial(k).outcome,:))                % color represents outcome

    % plot(x_data(k), dataTrial(k).iTrialType, '.', ...
    %     'MarkerSize', (((dataTrial(k).t_selection+1 - y_min) / (y_max - y_min))+min_size)*scale_factor, ...    % marker size scaled latency (invert by: ((ymin + ymax) - value /2) /100) ((y_min+y_max) - dataTrial_new.t_selection(k)/2) /100
    %     'MarkerEdgeColor', coolors(dataTrial(k).outcome,:))                % color represents outcome

    % add free reward, cue penalty, enl penalty, opto
    if dataTrial(k).free_reward > 0 % free reward
        scatter(k, 1, 25, 'o', 'filled', 'MarkerFaceColor', '#edb120')
    end
    if dataTrial(k).n_cue > 1 % cue penalty
        scatter(k, 2, 25, 'o', 'filled', 'MarkerFaceColor', '#edb120')
    end
    if dataTrial(k).n_ENL > 1 % enl penalty
        scatter(k, 3, 25, 'o', 'filled', 'MarkerFaceColor', '#edb120')
    end
    if dataTrial(k).opto == 1 % opto
        if dataTrial(k).opto_ITI == 1 % ITI
            scatter(k, 4, 25, 'v', 'filled', 'MarkerFaceColor', '#edb120')
        elseif dataTrial(k).opto_cue == 1 % cue
            scatter(k, 4, 25, '^', 'filled', 'MarkerFaceColor', '#edb120')
        elseif dataTrial(k).opto_rew == 1 % rew
            scatter(k, 4, 25, 'square', 'filled', 'MarkerFaceColor', '#edb120')
        elseif dataTrial(k).opto_blk == 1 % blockswitch
            scatter(k, 4, 25, 'diamond', 'filled', 'MarkerFaceColor', '#edb120')
        end
    end

    % % add opto trial if needed
    % if dataTrial(k).opto == 1 % make sure it's an opto trial
    %     if dataTrial(k).opto_ITI == 1 % ITI
    %         scatter(x_data(k), 0.5, 35, 'o', 'filled', 'MarkerFaceColor', '#edb120');
    %     elseif dataTrial(k).opto_cue == 1 % cue
    %         scatter(x_data(k), 0.5, 35, '^', 'filled', 'MarkerFaceColor', '#edb120');
    %     elseif dataTrial(k).opto_rew == 1 % outcome
    %         scatter(x_data(k), 0.5, 35, 'square', 'filled', 'MarkerFaceColor', '#edb120');
    %     elseif dataTrial(k).opto_blk == 1 % block
    %         scatter(x_data(k), 0.5, 35, 'diamond', 'filled', 'MarkerFaceColor', '#edb120');
    %     end
    % end

end
hold off
xlim([0 length(x_data)])
ylim([0.5 6.5])    % y limit
yticks([1:6])
yticklabels({'Free_r', 'Cue_p', 'ENL_p', 'Opto', 'Left', 'Right'})
% ylim([-0.5 1.5])    % y limit
% yticks([0 1])
% yticklabels({'L', 'R'})
% ylabel('Spout direction')
title('')

% % plot number of trials
% subplot(2,13,[14])
% bar(1, dataSession.trials, 'FaceColor', coolors_blr(1,:))
% % ylim([bar_min bar_max])
% xlim([bar_xmin bar_xmax-2])
% xticks([1])
% xticklabels({'B'})
% title('Trials')
% 
% % plot number of blocks
% subplot(2,13,[15])
% bar(1, dataSession.number_blocks, 'FaceColor', coolors_blr(1,:))
% % ylim([bar_min bar_max])
% xlim([bar_xmin bar_xmax-2])
% xticks([1])
% xticklabels({'B'})
% title('Blocks')

% plot number of trials and blocks
subplot(2,13,[14])
hold on
plot(1, dataSession.trials, '.', 'MarkerSize', 20, 'MarkerEdgeColor', coolors_blr(1,:))
plot(1, dataSession.number_blocks, '.', 'MarkerSize', 20, 'MarkerEdgeColor', coolors_blr(1,:) * .8)
ylim([0 dataSession.trials * 1.1])
xlim([bar_xmin bar_xmax-2])
xticks([1])
xticklabels({'T/B'})
title('Session')

% plot total number of left/right licks
subplot(2,13,[15])
hold on
plot(0.75, dataSession.total_licks_left, '.', 'MarkerSize', 20, 'MarkerEdgeColor', coolors_blr(2,:))
plot(1.25, dataSession.total_licks_right, '.', 'MarkerSize', 20, 'MarkerEdgeColor', coolors_blr(3,:))
xlim([bar_xmin bar_xmax-2])
ylim([0 max([dataSession.total_licks_left, dataSession.total_licks_right])*1.1])
xticks([1])
xticklabels({'L/R'})
title('Licks')

% plot reward rate - transparant = correct/rew+error, full bar = rew/trials
subplot(2,13,[16])
hold on
h = bar(1, dataSession.correct/(dataSession.correct+dataSession.inCorrect-dataSession.omissions), 'FaceColor', coolors_blr(1,:), 'LineStyle', 'none');
h.FaceAlpha = 0.4;
bar(1, dataSession.correct/dataSession.trials, 'FaceColor', coolors_blr(1,:)) 
% ylim([bar_min bar_max])
xlim([bar_xmin bar_xmax-2])
xticks([1])
xticklabels({'C'})
ylim([0 1])
title('Reward rate')

% plot ENL penalties
subplot(2,13,[17,18])
hold on
bar(1, dataSession.trials_ENL/dataSession.trials, 'FaceColor', coolors_blr(1,:))
bar(2, dataSession.trials_ENL_left/dataSession.trials_left, 'FaceColor', coolors_blr(2,:))
bar(3, dataSession.trials_ENL_right/dataSession.trials_right, 'FaceColor', coolors_blr(3,:))
ylim([0 1])
xlim([bar_xmin bar_xmax])
xticks([1 2 3])
xticklabels({'C', 'L', 'R'})
title('ENL rate')

% plot error and omisson for both/left/right
subplot(2,13,[19,20])
hold on
bar(1, dataSession.inCorrect/dataSession.trials, 'FaceColor', coolors_blr(1,:))
bar(2, dataSession.inCorrect_left/dataSession.trials_left, 'FaceColor', coolors_blr(2,:))
bar(3, dataSession.inCorrect_right/dataSession.trials_right, 'FaceColor', coolors_blr(3,:))
ylim([0 1])
xlim([bar_xmin bar_xmax])
xticks([1 2 3])
xticklabels({'C', 'L', 'R'})
title('Error rate')

subplot(2,13,[21,22])
hold on
bar(1, dataSession.omissions/dataSession.trials, 'FaceColor', coolors_blr(1,:))
bar(2, dataSession.omissions_left/dataSession.trials_left, 'FaceColor', coolors_blr(2,:))
bar(3, dataSession.omissions_right/dataSession.trials_right, 'FaceColor', coolors_blr(3,:))
ylim([0 1])
xlim([bar_xmin bar_xmax])
xticks([1 2 3])
xticklabels({'C', 'L', 'R'})
title('Omission rate')

subplot(2,13,[23,24])
hold on
bar(1, dataSession.correct_strategy_mean, 'FaceColor', coolors_blr(1,:))
bar(2, dataSession.correct_strategy_mean_left, 'FaceColor', coolors_blr(2,:))
bar(3, dataSession.correct_strategy_mean_right, 'FaceColor', coolors_blr(3,:))
% ylim([bar_min bar_max])
xlim([bar_xmin bar_xmax])
xticks([1 2 3])
xticklabels({'C', 'L', 'R'})
title('Strategy rate')

% plot trials2switch and strategy
subplot(2,13,[25,26])
hold on
bar(1, dataSession.trials2switch_mean, 'FaceColor', coolors_blr(1,:))
bar(2, dataSession.trials2switch_mean_left, 'FaceColor', coolors_blr(2,:))
bar(3, dataSession.trials2switch_mean_right, 'FaceColor', coolors_blr(3,:))
% ylim([bar_min bar_max])
xlim([bar_xmin bar_xmax])
xticks([1 2 3])
xticklabels({'C', 'L', 'R'})
title('Trials2Switch')

end


% find difference in time between choice lick time and cue onset (in ms) to determine marker size
    function dotSize = getDotSize(lickTimeDiff, selectionTime)

        % plot dot size as ratio between reaction time and selection threshold
        if lickTimeDiff <= selectionTime * .15 % lick is fast
            dotSize = 10; % 20
        elseif lickTimeDiff <= selectionTime * .3 % lick is fine
            dotSize = 20; % 40
        elseif lickTimeDiff <= selectionTime * .6 % lick is slow
            dotSize = 30; % 60
        else % lick is bad or omission
            dotSize = 40; % 80
        end
    end