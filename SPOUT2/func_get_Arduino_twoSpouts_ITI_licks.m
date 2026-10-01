%% twoSpouts tasks get ITI lick data
% dataITI - ITI licks aligned to previous and future choice
% ITI licks: licks before first cue onset (excludes cue penalty licks)
% previous choice = spout licked in trial k-1, future choice = spout licked in trial k
% align: 1 = lick on same spout as choice, 0 = lick on other spout

function [output] = func_get_Arduino_twoSpouts_ITI_licks(dataLicks, dataTrial)

% fixed vars
perc_licks = 0.25;      % fraction of first/last ITI licks (min 1 lick)
n_trials = size(dataTrial,2);

% find chosen spout (1:left, 2:right, NaN:omission)
choice = nan(1, n_trials);
for k=1:n_trials % per trial
    if dataTrial(k).outcome == 1 % correct -> licked trial type spout
        choice(k) = dataTrial(k).iTrialType;
    elseif dataTrial(k).outcome == 2 % error -> licked other spout
        choice(k) = 3 - dataTrial(k).iTrialType;
    end
end

% create struct; rows = trials
% repeat (1:previous choice == future choice, 0:switch, NaN:first trial or omission)
output = struct;
[output(1:n_trials).nTrial] = deal([]);
[output(1:n_trials).choice_prev] = deal(NaN);
[output(1:n_trials).choice_future] = deal(NaN);
[output(1:n_trials).repeat] = deal(NaN);
[output(1:n_trials).lick_times] = deal([]);
[output(1:n_trials).lick_side] = deal([]);
[output(1:n_trials).n_licks] = deal(0);
[output(1:n_trials).n_licks_perc] = deal(0);
[output(1:n_trials).prev_align] = deal([]);
[output(1:n_trials).future_align] = deal([]);
[output(1:n_trials).prev_all] = deal(NaN);
[output(1:n_trials).prev_first] = deal(NaN);
[output(1:n_trials).prev_last] = deal(NaN);
[output(1:n_trials).future_all] = deal(NaN);
[output(1:n_trials).future_first] = deal(NaN);
[output(1:n_trials).future_last] = deal(NaN);

% find info per trial
for k=1:n_trials % per trial

    % trial vars
    output(k).nTrial = k;

    % previous and future choice
    if k > 1 % first trial has no previous choice
        output(k).choice_prev = choice(k-1);
    end
    output(k).choice_future = choice(k);

    % find ITI licks - licks before first cue onset
    tmp = min(dataLicks(k).cue_start); % first cue onset
    tmp_left = dataLicks(k).left_ITI(dataLicks(k).left_ITI < tmp);
    tmp_right = dataLicks(k).right_ITI(dataLicks(k).right_ITI < tmp);

    % combine left/right licks and sort in time
    tmp_side = [ones(1, length(tmp_left)) ones(1, length(tmp_right))*2]; % 1:left, 2:right
    [output(k).lick_times, tmp] = sort([tmp_left tmp_right]);
    output(k).lick_side = tmp_side(tmp);
    output(k).n_licks = size(output(k).lick_times,2);
    output(k).n_licks_perc = ceil(output(k).n_licks * perc_licks);

    % align licks with previous/future choice - skip first trial and omissions
    if ~isnan(output(k).choice_prev) && ~isnan(output(k).choice_future)
        output(k).repeat = double(output(k).choice_prev == output(k).choice_future);

        % only trials with ITI licks
        if output(k).n_licks > 0
            % previous choice
            output(k).prev_align = double(output(k).lick_side == output(k).choice_prev);
            output(k).prev_all = mean(output(k).prev_align);
            output(k).prev_first = mean(output(k).prev_align(1:output(k).n_licks_perc));
            output(k).prev_last = mean(output(k).prev_align(end-output(k).n_licks_perc+1:end));

            % future choice
            output(k).future_align = double(output(k).lick_side == output(k).choice_future);
            output(k).future_all = mean(output(k).future_align);
            output(k).future_first = mean(output(k).future_align(1:output(k).n_licks_perc));
            output(k).future_last = mean(output(k).future_align(end-output(k).n_licks_perc+1:end));
        end
    end
end
