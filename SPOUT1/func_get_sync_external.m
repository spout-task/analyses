%% one/twoSpouts tasks get external sync pulse
% syncExt

function [output] = func_get_sync_external(dataSyncExt)
%FUNC_GET_SYNC_EXTERNAL  Edges of the external (FLIPR1) sync pulse from ExtSyncPulses.csv.
%
%   output = func_get_sync_external(dataSyncExt)
%
%   Modelled on func_get_sync_internal. Same field names as syncInt, plus
%   the summary fields of imaging.sync (n_pulses, first_to_last_s, lead_high,
%   lead_s, trunc_last). All times in ms on the Teensy clock.
%
%   Input
%     dataSyncExt  table from readtable(*_ExtSyncPulses.csv), columns
%                  status (ExtSync_on or ExtSync_off), time, duration
%
%   Output (struct)
%     raw              struct array per row after cleaning: sync_name, sync_time, sync_dur
%     vec_sync.data    logical row vector, index is the ms, true while the line is high
%     edges.rise_time  rising edges in ms
%     edges.fall_time  falling edges in ms
%     edges.high_dur   fall minus rise per pulse in ms, NaN for a truncated last pulse
%     edges.low_dur    next rise minus fall per pulse in ms, last value NaN
%     n_pulses         number of rising edges
%     first_to_last_s  last minus first rising edge in s
%     lead_high        true if the first row was ExtSync_off and was dropped
%     lead_s           time of that dropped falling edge in s, NaN otherwise
%     trunc_last       true if the last row is ExtSync_on
%     checks.duration_bad_rows  rows (of the cleaned table) where the duration rule fails
%
%   Duration column: unlike the internal sync, the duration on row k is the
%   length of the PREVIOUS state, so time(k) minus time(k minus 1) equals
%   duration(k). The first row has duration equal to its time (time since 0).
%   Verified on all ten Pavlovian sessions of 260601 and 260602.
%
%   Errors and warnings
%     pavlovian:emptySyncExt (error), pavlovian:syncExtName (error),
%     pavlovian:syncExtOrder (error), pavlovian:syncExtTime (error),
%     pavlovian:syncExtDuration (warning), pavlovian:syncExtTruncated (warning)
%
%   Usage
%     [session.syncExt] = func_get_sync_external(dataSyncExt);

% fixed vars
name_on = 'ExtSync_on';     % rising edge
name_off = 'ExtSync_off';   % falling edge
dur_tol_ms = 1;             % tolerance of the duration check (Teensy has 1 ms resolution)

% make output struct
output = struct;
output.raw = [];
output.vec_sync = [];
output.edges.rise_time = [];
output.edges.fall_time = [];
output.edges.high_dur = [];
output.edges.low_dur = [];
output.n_pulses = 0;
output.first_to_last_s = NaN;
output.lead_high = false;
output.lead_s = NaN;
output.trunc_last = false;
output.checks.duration_bad_rows = [];

%% get columns

% empty file -> stop, nothing to sync with
if isempty(dataSyncExt) || height(dataSyncExt) == 0
    error('pavlovian:emptySyncExt', 'ExtSyncPulses has no rows')
end
sync_name = dataSyncExt{:,1};   % status
sync_time = dataSyncExt{:,2};   % time in ms
sync_dur = dataSyncExt{:,3};    % duration of the previous state in ms

% only ExtSync_on and ExtSync_off are expected
if any(~ismember(sync_name, {name_on, name_off}))
    error('pavlovian:syncExtName', 'ExtSyncPulses has unknown status names')
end

%% clean data

% if we start with a low pulse, remove it
% the line was idle high when the Teensy started and dropped at FLIPR1 acquisition start
% verified: 20260601_tomahawk, ExtSync_off at 55522 ms, 1000 ms before the first pulse
if strcmp(sync_name{1}, name_off)
    output.lead_high = true;
    output.lead_s = sync_time(1) / 1000;
    disp(['Remove ExtSync_off from start at ' num2str(sync_time(1)) ' ms (line idle high before FLIPR1 started)'])
    sync_name(1) = [];
    sync_time(1) = [];
    sync_dur(1) = [];
end

% nothing left
if isempty(sync_name)
    error('pavlovian:emptySyncExt', 'ExtSyncPulses has no rising edge')
end

% times are used as ms index of vec_sync, so they must be at least 1
if any(sync_time < 1)
    error('pavlovian:syncExtTime', 'ExtSyncPulses has times below 1 ms')
end

%% run some checks

% if we don't find ON - OFF - ON - OFF - etc, throw an error
if any(strcmp(sync_name(1:end-1), sync_name(2:end)))
    error('pavlovian:syncExtOrder', 'ExtSync ON and OFF do not follow each other')
end

% duration on row k is the length of the previous state -> time(k) - time(k-1) == duration(k)
bad_rows = find(abs(diff(sync_time) - sync_dur(2:end)) > dur_tol_ms) + 1;
output.checks.duration_bad_rows = bad_rows(:)';
if ~isempty(bad_rows)
    warning('pavlovian:syncExtDuration', ['ExtSync time and duration do not match, rows: ' num2str(bad_rows(:)')])
end

% if last pulse is on, the last pulse is truncated
if strcmp(sync_name{end}, name_on)
    output.trunc_last = true;
    warning('pavlovian:syncExtTruncated', 'Last ExtSync pulse of session is ON')
end

%% get data

% store entire sync pulse (after cleaning), same fields as syncInt
output.raw = struct('sync_name', sync_name(:)', 'sync_time', num2cell(sync_time(:)'), 'sync_dur', num2cell(sync_dur(:)'));

% split data in ON and OFF
is_on = strcmp(sync_name, name_on);
rise_time = sync_time(is_on)';
fall_time = sync_time(~is_on)';
n_pulses = numel(rise_time);
n_fall = numel(fall_time); % n_pulses, or n_pulses - 1 if the last pulse is truncated

% durations from the times, not from the duration column
high_dur = nan(1, n_pulses);
low_dur = nan(1, n_pulses);
high_dur(1:n_fall) = fall_time - rise_time(1:n_fall);
low_dur(1:n_pulses-1) = rise_time(2:n_pulses) - fall_time(1:n_pulses-1);

% store
output.edges.rise_time = rise_time;
output.edges.fall_time = fall_time;
output.edges.high_dur = high_dur;
output.edges.low_dur = low_dur;
output.n_pulses = n_pulses;
output.first_to_last_s = (rise_time(end) - rise_time(1)) / 1000;

%% vectorize

% same definition as syncInt: index is the ms, high from rise up to the ms before the fall
% logical instead of double (about 3 MB for one hour)
vec_len = max([rise_time fall_time]);
tmp_vec = false(1, vec_len);
for k = 1:n_pulses % per pulse
    if k <= n_fall
        tmp_vec(rise_time(k):fall_time(k)-1) = true;
    else % truncated last pulse, only its rising edge is known
        tmp_vec(rise_time(k)) = true;
    end
end
output.vec_sync.data = tmp_vec;

end
