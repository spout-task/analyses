%% one/twoSpouts tasks get internal sync pulse
% syncInt

function [output] = func_get_sync_internal(dataSyncInt)

% time is in ms (pulse HIGH probably 100)

% make output struct
output = struct;
output.raw = [];
output.vec_sync = [];
output.edges.rise_time = [];
output.edges.fall_time = [];
output.edges.high_dur = [];
output.edges.low_dur = [];

%% clean data

% % if we start with low pulse, remove first
% if strcmp(dataSyncInt{1,1}, 'Sync_off') || strcmp(dataSyncInt{1,1}, 'Sync off') % old task
%     dataSyncInt(1,:) = [];
% end

% if we end with 2 low pulses, remove last
if (strcmp(dataSyncInt{end,1}, 'Sync_off') || strcmp(dataSyncInt{end,1}, 'Sync off')) && ... % old task
        (strcmp(dataSyncInt{end-1,1}, 'Sync_off') || strcmp(dataSyncInt{end-1,1}, 'Sync off')) % old task
    dataSyncInt(end,:) = [];
end

% if we start with a low pulse, remove it
if (strcmp(dataSyncInt{1,1}, 'Sync_off') || strcmp(dataSyncInt{1,1}, 'Sync off')) % old task
    disp(['Remove sync off from start'])
    dataSyncInt(1,:) = [];
end

% if we start with a negative high pulse, remove it
if ((strcmp(dataSyncInt{1,1}, 'Sync_on') || strcmp(dataSyncInt{1,1}, 'Sync on'))) & ... % old task
        dataSyncInt{1,2} < 0 
    warning(['First trial starts with a negative sync on value'])
    dataSyncInt(1,:) = [];
end

%% run some checks

% if last pulse is on, throw an error
if strcmp(table2array(dataSyncInt(end,1)), 'Sync_on') || strcmp(table2array(dataSyncInt(end,1)), 'Sync on') % old task
    warning('Last pulse of session is ON')
end

% if we don't find ON - OFF - ON - OFF - etc, throw an error 
tmp = all(~strcmp(dataSyncInt(1:end-1,1), dataSyncInt(2:end,1))); 
if tmp ~= 1
    error('Sync ON and OFF do not follow each other')
end

% check if we have no dropped pulses. if so, throw an error
tmp_exp = dataSyncInt{1:end-1,2} + dataSyncInt{1:end-1,3} + 1; % find expected pulses based on current pulse + duration -> add +1 because next event start at next ms
tmp_act = dataSyncInt{2:end,2}; % find actual pulses
bad_rows = find(tmp_exp ~= tmp_act) + 1; % find differences between pulse starts
if length(bad_rows) > 1 % multiple problems
    warning(['Multiple dropped pulses found - sync pulses: ' num2str(bad_rows')])
elseif ~isempty(bad_rows) && bad_rows ~= size(dataSyncInt,1) % last pulse off can start a bit earlier
    warning(['Dropped pulse found - sync pulse: ' num2str(bad_rows)])
end

% get pulse duration -> we vary IPI, not pulse duration
if strcmp(dataSyncInt{1,1}, 'Sync_on') || strcmp(dataSyncInt{1,1}, 'Sync on') % old task
    pulse_dur = table2array(dataSyncInt(1,3));
elseif strcmp(dataSyncInt{2,1}, 'Sync_on') || strcmp(dataSyncInt{2,1}, 'Sync on') % old task
    pulse_dur = table2array(dataSyncInt(2,3));
else
    error('Cannot find Sync on pulse')
end

%% get data

% store entire sync pulse
[output.raw(1:size(dataSyncInt,1)).sync_name] = deal([]);
[output.raw(1:size(dataSyncInt,1)).sync_time] = deal([]);
[output.raw(1:size(dataSyncInt,1)).sync_dur] = deal([]);
for k=1:size(dataSyncInt,1)
    output.raw(k).sync_name = dataSyncInt{k,1};
    output.raw(k).sync_time = table2array(dataSyncInt(k,2));
    output.raw(k).sync_dur = table2array(dataSyncInt(k,3));
end

% split data in ON and OFF
cnt_on = 1;
cnt_off = 1;
for k=1:size(dataSyncInt,1) % per pulse (row)
    if strcmp(table2array(dataSyncInt(k,1)), 'Sync_on') || strcmp(table2array(dataSyncInt(k,1)), 'Sync on') % old task
        output.edges.rise_time(cnt_on) = table2array(dataSyncInt(k,2));
        output.edges.high_dur(cnt_on) = table2array(dataSyncInt(k,3));
        cnt_on = cnt_on + 1;
    else
        output.edges.fall_time(cnt_off) = table2array(dataSyncInt(k,2));
        output.edges.low_dur(cnt_off) = table2array(dataSyncInt(k,3));
        cnt_off = cnt_off + 1;
    end
end

%% vectorize

% don't normalize signal to first pulse, assume signal is low before any
% sync event! (this might screw up later analyses)
vec_len = dataSyncInt{end,2} + dataSyncInt{end,3} - 1; % last event's end time
tmp_vec = zeros(1, vec_len); % get 0's

% fill in 1's
for k = 1:size(dataSyncInt,1) % per row
    if strcmp(dataSyncInt{k,1}, 'Sync_on') || strcmp(dataSyncInt{k,1}, 'Sync on') % old task
        seg_start = dataSyncInt{k,2};
        seg_end   = seg_start + dataSyncInt{k,3};
        tmp_vec(seg_start:seg_end) = 1;
    end
end

% store vector
output.vec_sync.data = tmp_vec;

end