%% one/twoSpouts tasks load one sync pulse csv
% used for the internal (SyncPulses.csv) and external (ExtSyncPulses.csv) sync pulse

function data_sync = func_load_SPOUT_sync_csv(sync_dir, sync_pattern, sync_label, session_name, warn_if_absent)
%FUNC_LOAD_SYNC_CSV  Load one sync pulse csv; warn and return [] if missing, duplicate, empty or unreadable.
%
%   data_sync = func_load_SPOUT_sync_csv(sync_dir, sync_pattern, sync_label, session_name)
%   data_sync = func_load_SPOUT_sync_csv(sync_dir, sync_pattern, sync_label, session_name, warn_if_absent)
%   warn_if_absent (optional, default true): false skips the warning for a missing, 0 byte or header only file
%   (sync pulse not recorded). More than one matching file or an unreadable file always gives a warning.
%   example: dataSyncExt = func_load_SPOUT_sync_csv(sess_dir, '*_ExtSyncPulses.csv', 'external', 'b-2', false)

% report if sync file is absent or empty
if nargin < 5                                                               % input not given
    warn_if_absent = true;                                                  % old behaviour, warn
end

% find data and report if needed
data_sync = [];                                                             % default: nothing loaded
file_sync = dir(fullfile(sync_dir, sync_pattern));                          % find sync file(s)
if isempty(file_sync)                                                       % no file found
    if warn_if_absent                                                       % report only if asked
        warning('spout:syncMissing', [session_name ': no ' sync_pattern ' found, ' sync_label ' sync pulse skipped'])
    end
    return                                                                  % leave empty
elseif numel(file_sync) > 1                                                 % ambiguous, do not guess
    warning('spout:syncMultiple', [session_name ': ' num2str(numel(file_sync)) ' files match ' sync_pattern ', ' sync_label ' sync pulse skipped'])
    return                                                                  % leave empty
elseif file_sync.bytes == 0                                                 % 0 byte file
    if warn_if_absent                                                       % report only if asked
        warning('spout:syncEmptyFile', [session_name ': ' file_sync.name ' is 0 bytes, ' sync_label ' sync pulse skipped'])
    end
    return                                                                  % leave empty
end
try                                                                         % read file
    data_sync = readtable(fullfile(sync_dir, file_sync.name));              % load as table
catch err                                                                   % unreadable file
    warning('spout:syncRead', [session_name ': could not read ' file_sync.name ' (' err.message '), ' sync_label ' sync pulse skipped'])
    data_sync = [];                                                         % leave empty
    return
end
if height(data_sync) == 0                                                   % header only, no rows
    if warn_if_absent                                                       % report only if asked
        warning('spout:syncNoRows', [session_name ': ' file_sync.name ' has no rows, ' sync_label ' sync pulse skipped'])
    end
    data_sync = [];                                                         % leave empty
    return
end
disp([upper(sync_label(1)) sync_label(2:end) ' sync pulse loaded: ' file_sync.name ' (' num2str(height(data_sync)) ' rows)'])  % feedback
end
