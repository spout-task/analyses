%% first attempt to plot align sync pulses between teensy and camera

%% TO DO
% xxx 0) check last pulse and delete from teensy/cam if teensy didn't finish it
% xxx 1) calculate IPI duration per data stream (don't downsample!)
% xxx 2) use frameID to see if we have missing frames
% xxx 3) use frameTimestamp to see if we have missing frames
% 4) find number of peaks and compare between 2 streams (pulses_cam -
% pulses_teensy -> should be 0!)
% OR get timestamp of rising edge and subtract those (pulses_cam(i) -
% pulses_teensy(i) -> should be a flat line! sloped line = linear drift,
% wiggly or diverging = nonlinear drift or dropped frames)
% !!!!!!!!!!!!!!!!!!
% xxx 5) think about how to deal with missing frames -> you can find missing
% xxx frames by diff(syncDataCam(:,1)) (a value >1 means # of missing frames).
% but now what? you want to add "empty" frames for alignment to the sync
% pulse? 

close all
clearvars

%% user settings
snippet_s = 5; % length of snippet plot in seconds

%% load data

% load [date]_[animal]_SyncPulses.csv file
[fileTeensy, location] = uigetfile('*.csv', 'Select teensy *_SyncPulses.csv file');
cd(location)
syncDataTeensy = readtable(fileTeensy);

% load camera file
[fileCam, location] = uigetfile('*.csv', 'Select camera timestamp_*.csv file');
syncDataCam = load([location fileCam]);

% get file name based on teensy code
tmp = strsplit(fileTeensy, '.');
tmp = strsplit(tmp{1}, '_');
save_name = [tmp{2} '_' tmp{1}];


%% get pulses syncDataTeensy
% time is ms (pulse HIGH should be 100)

% get pulse duration -> we vary IPI, not pulse duration
if strcmp(syncDataTeensy{1,1}, 'Sync on')
    pulse_dur = table2array(syncDataTeensy(1,3));
elseif strcmp(syncDataTeensy{2,1}, 'Sync on')
    pulse_dur = table2array(syncDataTeensy(2,3));
else
    error('Cannot find Sync on pulse')
end

% get data
pulses = table2array(syncDataTeensy(:,[2 3]));

% % sanity check
% if ~strcmp(table2array(syncDataTeensy(end,1)), 'Sync off')
%     error('Something wrong with sync pulse start and stop of session')
% end

% split ON and OFF
cnt=1;
if strcmp(table2array(syncDataTeensy(1,1)), 'Sync on')
    startFrame = 1;
elseif strcmp(table2array(syncDataTeensy(1,1)), 'Sync off')
    startFrame = 2;
end
for k=startFrame:2:size(pulses,1)-1
    pOn(cnt) = pulses(k);
    pOff(cnt) = pulses(k+1);
    cnt=cnt+1;
end

% subtract first frame timestamp
valNorm = pOn(1)-1;
pOn = pOn - valNorm;
pOff = pOff - valNorm;

% make binary vector
binTeensy = zeros(1,pOff(end));

% fill with 1's
for k=1:size(pOn,2)
    tmp = find(pOff > pOn(k));
    binTeensy(pOn(k):pOff(tmp(1))) = 1;
end

% get all rises and falls to calculate IPI duration
idxFallTeensy = strfind(logical(binTeensy), [1, 0]) + 1;
idxRiseTeensy = strfind(logical(binTeensy), [0, 1]) + 1;

% get fps of teensy -> use all the high pulses
% -1 corrects for inclusive fill in binTeensy (pOn:pOff spans 1 extra sample)
% actual_pulse_dur_teensy accounts for firmware rounding (pOff = pOn + pulse_dur + 1)
teensy_pulses = idxFallTeensy(2:end) - idxRiseTeensy(1:end-1) - 1;
actual_pulse_dur_teensy = mean(table2array(syncDataTeensy(2:2:end,2)) - table2array(syncDataTeensy(1:2:end-1,2)));
fps_teensy = 1000 / (actual_pulse_dur_teensy / mean(teensy_pulses));

% figure out if last pulse was interrupted because of terminating the task
if length(idxFallTeensy) > length(idxRiseTeensy) % check if there are more falls than rises
    last_pulse_interrupted = false;
elseif length(idxFallTeensy) == length(idxRiseTeensy) % same amount
    last_pulse_interrupted = true;
end

% get IPI
for k=1:length(idxFallTeensy)-1 % skip last IPI
    ipiTeensy(k) = (length(idxFallTeensy(k) : idxRiseTeensy(k)) -1) / fps_teensy; % -1 to avoid counting rise again
end


%% get pulses syncDataCam
% timestamp vals in ns

% blackflys low/high is generally 4/12, but we can jsut check that
camHigh = max(syncDataCam(:,3));

% find onset and offset
onsetCam = find(syncDataCam(:,3) == camHigh);
offsetCam = onsetCam(end)+1;
onsetCam = onsetCam(1);

% cut cam sync data - remove last pulse if needed
if last_pulse_interrupted == true
    binCam = syncDataCam(onsetCam:offsetCam-1, 3);
else
    binCam = syncDataCam(onsetCam:offsetCam, 3);
end

% scale/normalize values to [0 1]
minVal = min(binCam);
maxVal = max(binCam);
binCam = (binCam - minVal) / (maxVal - minVal);
binCam = binCam';

% get all rises and falls to calculate IPI duration
idxFallCam = strfind(logical(binCam), [1, 0]) + 1;
idxRiseCam = strfind(logical(binCam), [0, 1]) + 1;

% get fps of beh camera -> use all the high pulses
cam_pulses = idxFallCam(2:end) - idxRiseCam(1:end-1); % skip first pulse
fps_cam = 1000 / (pulse_dur / mean(cam_pulses)); % # 1000 / (100 / mean #frames high) - sampling rate cam (Hz)

% get IPI
for k=1:length(idxFallCam)-1 % skip last IPI
    ipiCam(k) = (length(idxFallCam(k) : idxRiseCam(k)) -1) / fps_cam; % -1 to avoid counting rise again
end


%% plot 1: full sync pulse signals

% time axes
tTeensy = (0:length(binTeensy)-1) / fps_teensy; % seconds
tCam    = (0:length(binCam)-1)    / fps_cam;    % seconds

% figure
figure('Name', 'Full sync pulse');
subplot(2,1,1)
plot(tTeensy, binTeensy)
ylim([-0.5 1.5])
xlabel('Time (s)')
title(sprintf('Sync pulse Teensy  [fps = %.1f Hz, n pulses = %d]', fps_teensy, length(pOn)))

subplot(2,1,2)
plot(tCam, binCam)
ylim([-0.5 1.5])
xlabel('Time (s)')
title(sprintf('Sync pulse Camera  [fps = %.1f Hz, n pulses = %d]', fps_cam, length(idxFallCam)))

% save fig
saveas(gcf, [save_name '_entire_trace.jpg'])
disp('Done saving figure')


%% plot 2: snippet (user-defined length)

% get snippet data
snippet_samplesTeensy = round(snippet_s * fps_teensy);
snippet_samplesCam    = round(snippet_s * fps_cam);

% plot fig
figure('Position', [100 100 200 200])
subplot(2,1,1)
plot(tTeensy(1:min(snippet_samplesTeensy, end)), binTeensy(1:min(snippet_samplesTeensy, end)))
ylim([-0.1 1.1])
xlim([0 snippet_s])
xlabel('Time (s)')
title(sprintf('Teensy  (first %.0f s)', snippet_s))

subplot(2,1,2)
plot(tCam(1:min(snippet_samplesCam, end)), binCam(1:min(snippet_samplesCam, end)))
ylim([-0.1 1.1])
xlim([0 snippet_s])
xlabel('Time (s)')
title(sprintf('Camera  (first %.0f s)', snippet_s))

% save fig
saveas(gcf, [save_name '_snippet_trace.jpg'])
saveas(gcf, [save_name '_snippet_trace.svg'])
disp('Done saving figure')


%% cross correlation
% importantly: the ipilag value indicates how many ipi's you should move up
% or down, not number of frames
% note: lag=0 is expected because IPI sequences are anchored to the first
% detected pulse in each stream - the pre-recording offset is discarded
% when pulse edges are extracted.

[rIPI, lagIPI] = xcorr(ipiTeensy, ipiCam, 'normalized');

% plot fig
figure('Position', [100 100 200 100])
plot(lagIPI, rIPI)
xlabel('Lag (pulses)')
ylabel('Correlation')
title('XCorr IPI  (lag=0 expected)')

% save fig
saveas(gcf, [save_name '_cross-corr_ipi.jpg'])
saveas(gcf, [save_name '_cross-corr_ipi.svg'])
disp('Done saving figure')


%% cross correlation - entire binary trace
% same comparison as above, but on the full binary sync-pulse traces rather
% than the IPI sequence. Teensy and camera are sampled at different native
% rates, so both traces are first resampled onto a common uniform grid at
% the higher of the two rates before cross-correlating.
fs_common    = max(fps_teensy, fps_cam);                 % higher native rate (Hz)
dt_common    = 1 / fs_common;                            % s
t_common     = 0 : dt_common : min(tTeensy(end), tCam(end));
binTeensy_rs = interp1(tTeensy, double(binTeensy), t_common, 'previous', 0); % zero-order hold
binCam_rs    = interp1(tCam,    double(binCam),    t_common, 'previous', 0);
binTeensy_rs = double(binTeensy_rs > 0.5);               % keep strictly binary
binCam_rs    = double(binCam_rs   > 0.5);

maxlag_trace = round(2 * fs_common);                     % +/- 2 s, avoid millions of lags
[rTrace, lagTrace] = xcorr(binTeensy_rs, binCam_rs, maxlag_trace, 'normalized');

% plot fig
figure('Position', [100 100 200 100])
plot(lagTrace, rTrace)
xlabel(sprintf('Lag (samples @ %.0f Hz)', fs_common))
ylabel('Correlation')
title('XCorr full trace  (lag=0 expected)')

% save fig
saveas(gcf, [save_name '_cross-corr_trace.jpg'])
saveas(gcf, [save_name '_cross-corr_trace.svg'])
disp('Done saving figure')


%% run a bunch of controls

% compare number of pulses
if length(ipiTeensy) ~= length(ipiCam)
    error('different number of peaks')
end

% check if lag is 0
[~, idx] = max(rIPI); % find lag value
if lagIPI(idx) ~= 0
    error('shifted signal')
end

% check if frameID is linear
frameID_diff = diff(syncDataCam(:,1)) == 1; % find all pairs that are consecutive: idx=1, else idx=0
if ~isempty(find(frameID_diff == 0, 1))    % check if there are missing frames
    
    % find frame IDs
    frameID_drop = find(frameID_diff == 0);

    % find how many frames were dropped
    for k=1:length(frameID_drop) % per missing frame point
        frameID_number(k,1) = syncDataCam(frameID_drop(k)+1,1) - syncDataCam(frameID_drop(k),1);
    end

    % correct syncDataCam
    for k=length(frameID_drop):-1:1 % per missing frame point -> reverse order so we can add NaN's
        for kk=frameID_number(k)-1:-1:1 % per missing frame -> reverse order so we can add NaN's. first -1 is because we subtracted k+1 - k
            % notify user
            disp(['Location framedrop: ' num2str(frameID_drop(k)) ', number of frames: ' num2str(frameID_number(k))])

            % make updated row
            new_row = [syncDataCam(frameID_drop(k),1)+kk NaN NaN];  % row to be added
            syncDataCam = [syncDataCam(1:frameID_drop(k), :); new_row; syncDataCam(frameID_drop(k)+1:end, :)]; % add row
        end
    end
end


%% pulse frequency
pOn_raw        = table2array(syncDataTeensy(1:2:end-1, 2)); % all Sync on timestamps in ms
period_ms      = diff(pOn_raw);                             % onset-to-onset interval per pulse
pulse_freq_hz  = 1000 ./ period_ms;                        % instantaneous pulse frequency (Hz)
unique_periods = unique(period_ms);

fprintf('\n=== Pulse frequency ===\n')
fprintf('  mean:   %.4f Hz\n', mean(pulse_freq_hz))
fprintf('  median: %.4f Hz\n', median(pulse_freq_hz))
fprintf('  min:    %.4f Hz\n', min(pulse_freq_hz))
fprintf('  max:    %.4f Hz\n', max(pulse_freq_hz))
fprintf('  std:    %.4f Hz\n', std(pulse_freq_hz))
fprintf('  %-12s  %-10s  %-10s  %s\n', 'Period (ms)', 'Freq (Hz)', 'N pulses', 'Fraction')
for k = 1:length(unique_periods)
    n = sum(period_ms == unique_periods(k));
    fprintf('  %-12d  %-10.4f  %-10d  %.1f%%\n', unique_periods(k), 1000/unique_periods(k), n, 100*n/length(period_ms))
end


%% plot 3: drift between streams
% get timestamps rising edge Teensy
timestampRiseTeensy = idxRiseTeensy / fps_teensy; % in seconds
timestampRiseTeensy = timestampRiseTeensy - timestampRiseTeensy(1);

% get timestamps rising edge Cam
timestampRiseCam = idxRiseCam / fps_cam; % in seconds
timestampRiseCam = timestampRiseCam - timestampRiseCam(1);

% use min length in case pulse counts differ by 1
nRises = min(length(timestampRiseTeensy), length(timestampRiseCam));

figure('Name', 'Clock drift');
plot(timestampRiseTeensy(1:nRises) - timestampRiseCam(1:nRises))
xlabel('Pulse #')
ylabel('Mismatch (s)  [+ = Teensy faster, - = Cam faster]')
title('Clock drift: Teensy vs Camera rising edges')

% save fig
saveas(gcf, [save_name '_clock-drift.jpg'])
disp('Done saving figure')
