% Om = 0, HIT = 1, CR = 2, FA = 3
    addpath('/scratch/work/bahriz1/Thesis/Functions')
    addpath(genpath('/scratch/work/bahriz1/Thesis/totahlab-master/external/nlx_linux'))
    addpath('/scratch/work/bahriz1/Thesis/totahlab-master/nelson/Attention Project')
  %% go to where the data is and fill in the file names manually
  gngFile = '';
  ncsFile = '';
  EventsName = '';
  %%

    Times = GetEventsData_linux(EventsName, 0, 'microsec');
    data = load(gngFile);
    offset = Times.CheetahRecordingStart;   
    correct = data.Correct(:);
    % get rid of weird trials
    validMask = correct ~= 4;
    correct = correct(validMask);
    stimOn = Times.StimOn(:);
    stimOn = stimOn(validMask);
    %keep orig trial # in case needed
    origTrial = (1:numel(correct))'; 
    T = table(origTrial, stimOn, correct, 'VariableNames', {'Trial','StimOn','Correct'});
    respMask = T.Correct == 1 | T.Correct == 3;
    T.InstruResp = nan(height(T),1);
    T.InstruResp(respMask) = Times.InstruResp(:);
    T.StimOn = (T.StimOn - offset) / 1e6;
    T.InstruResp = (T.InstruResp - offset) / 1e6;
    T.ReactionTime = T.InstruResp - T.StimOn;
    %%
    % Get velocity
    filename = {};
    filename{1} = ncsFile;
    %%
    [Vel_time, Vel, ~, ~] = GetVelocityData_linux(filename, 200);
    %%
    Vel_time = (Vel_time - offset) / 1e6;
    EndTrial_Time = 1.75;
    % create empty columns for peak vel and its time
    T.PeakVel = nan(height(T), 1);
    T.PeakVelTime = nan(height(T), 1);
    % clip the velocity vector to match the trial duration
    for k = 1:height(T)
        %fprintf('Doing velocity work. Trial %d\n', T.Trial(k));
        startIdx = find(Vel_time >= T.StimOn(k), 1, 'first');
        endIdx = find(Vel_time <= T.StimOn(k) + EndTrial_Time, 1, 'last');
        if isempty(startIdx) || isempty(endIdx) || endIdx < startIdx
            continue
        end
        T.VelTime{k} = Vel_time(startIdx:endIdx) - T.StimOn(k);
        T.VelTrace{k} = Vel(startIdx:endIdx);
        % get max vel for CR
        if T.Correct(k) == 2
            [peakVal, localIdx] = max(T.VelTrace{k});
            T.PeakVel(k) = peakVal;
            T.PeakVelTime(k) = T.StimOn(k) + T.VelTime{k}(localIdx);
        end
    end
    % add date
    T.Date = repmat(date, height(T), 1);
    % add rat ID
    T.RatID = repmat(str2double(ratId), height(T), 1); 
    T = movevars(T, {'RatID','Date'}, 'Before', 'StimOn');
    fileName = sprintf('%s_%s.mat', ratId, date);
    savePath = fullfile('/scratch/work/bahriz1/Thesis/data', fileName);
    save(savePath, 'T');