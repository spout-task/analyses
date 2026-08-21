% LLLR task Arduino output
% plot licks

function plot_LLLR_daily_licks(dot_size, x_min, x_max, licks_data)

% coolors
coolors = [255/255 145/255 0/255; 123/255 44/255 191/255]; % left/right orange/violet (princeton orange/french violet) licks

% figure
figure
hold on
for q=1:size(licks_data,2)
    try; scatter(licks_data(q).left_choice, q, dot_size, 'filled', 'MarkerFaceColor', coolors(1,:)); catch; end
    try; scatter(licks_data(q).right_choice, q, dot_size, 'filled', 'MarkerFaceColor', coolors(2,:)); catch; end
    try; scatter(licks_data(q).left_outcome, q, dot_size, 'filled', 'MarkerFaceColor', coolors(1,:)); catch; end
    try; scatter(licks_data(q).right_outcome, q, dot_size, 'filled', 'MarkerFaceColor', coolors(2,:)); catch; end
    try; scatter(licks_data(q).left_ITI, q, dot_size, 'filled', 'MarkerFaceColor', coolors(1,:)); catch; end
    try; scatter(licks_data(q).right_ITI, q, dot_size, 'filled', 'MarkerFaceColor', coolors(2,:)); catch; end
end
xlim([x_min x_max])
ylim([0 size(licks_data,2)])
xlabel('Time from cue (ms)')
ylabel('Trial')

% plot choice line
line([0 0], [0 size(licks_data,2)],'Color','black','LineStyle','--')

end