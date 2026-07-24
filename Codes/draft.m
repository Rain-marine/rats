addpath('/u/16/bahriz1/unix/Desktop/Functions')
addpath(genpath('/u/16/bahriz1/unix/Desktop/totahlab-master/external/nlx_linux'))

% Om = 0, HIT = 1, CR = 2, FA = 3

baseRoot = '/u/16/bahriz1/unix/Desktop';

ratFolders = {'TN250', 'TN251', 'TN253'};   

AllT = table();

for r = 1:numel(ratFolders)

    ratID = ratFolders{r};
    baseDir = fullfile(baseRoot, ratID);

    sessions = dir(fullfile(baseDir, 'session_*'));
    sessions = sessions([sessions.isdir]);

    for i = 1:numel(sessions)
        disp(i)
        disp(numel(sessions))
        disp(class(sessions))
        disp(size(sessions))
        sessName = sessions(i).name;                  % e.g. 'session_06'
        sessDir  = fullfile(baseDir, sessName);

        sessNum = str2double(sessName(end-1:end));    % 06 -> 6
        sessStr = sprintf('%02d', sessNum);           % 6 -> '06'

        cd(sessDir);

        gngFile = sprintf('ekg_behavior_%s_%s_GNG.mat', ratID, sessStr);

        % skip session if not GNG
        if ~isfile(gngFile)
            fprintf('Skipping %s/%s (no GNG file)\n', ratID, sessName);
            continue
        end

        EventsName = sprintf('ekg_behavior_%s_%s_Events.nev', ratID, sessStr);
        Times = GetEventsData_linux(EventsName, 0, 'microsec');

        data = load(gngFile);

        data.Correct(data.Correct == 4) = [];

        % concat stimOn and trial type
        T = table(Times.StimOn(:), data.Correct(:), 'VariableNames', {'StimOn','Correct'});

    
        
        % remove types 0 and 2 because they have no instruResp
        T(T.Correct == 0 | T.Correct == 2, :) = [];

        % concat instruResp
        T.InstruResp = Times.InstruResp(:);

        % deduct offset
        offset = Times.CheetahRecordingStart;
        T.StimOn = T.StimOn - offset;
        T.InstruResp = T.InstruResp - offset;

        % convert from microsec to s
        T.StimOn = T.StimOn / 1e6;
        T.InstruResp = T.InstruResp / 1e6;

        % calculate RT
        T.ReactionTime = T.InstruResp - T.StimOn;

        % add session number
        T.Session = repmat(sessNum, height(T), 1);

        % add rat id
        T.RatID = repmat(str2double(erase(ratID, 'TN')), height(T), 1);

        % reorder columns if you want
        T = movevars(T, {'RatID','Session'}, 'Before', 'StimOn');

        % add to main dataset
        AllT = [AllT; T];

    end
end
%% PLOT

figure
histogram(AllT.ReactionTime, 50)
xlabel('Reaction Time (s)')
ylabel('Count')
title('RT distribution (all sessions)')


%%
figure
plot(AllT.ReactionTime, '.')
xlabel('Trial')
ylabel('Reaction Time (s)')
title('RT over trials')

%%
mean(AllT.ReactionTime)
median(AllT.ReactionTime)
min(AllT.ReactionTime)
max(AllT.ReactionTime)
%%


addpath('/u/16/bahriz1/unix/Desktop/Functions')
addpath(genpath('/u/16/bahriz1/unix/Desktop/totahlab-master/external/nlx_linux'))
cd('/u/16/bahriz1/unix/Desktop/TN250/session_03')


%%
EventsName = 'ekg_behavior_TN250_03_Events.nev';
Times = GetEventsData_linux(EventsName, 0, 'microsec');
data = load('ekg_behavior_TN250_03_GNG.mat');

%%
T = table(Times.StimOn(:), data.Correct(:),'VariableNames', {'StimOn','Correct'});
T(T.Correct==0 | T.Correct==2, :) = [];
T.InstruResp = Times.InstruResp(:);
T.ReactionTime = T.InstruResp - T.StimOn;
T.StimOn = T.StimOn / 1e6;
T.InstruResp = T.InstruResp / 1e6;
T.ReactionTime = T.ReactionTime / 1e6;

%%
% add load csc linux
addpath('/u/16/bahriz1/unix/Desktop/totahlab-master/nelson/Attention Project')
filename={};
filename{1} = 'ekg_behavior_TN250_03_CSC127.ncs';

[Vel_time, Vel, ~, ~] = GetVelocityData_linux(filename,200);
 Vel_time = Vel - offset;

Vel_time = Vel_time / 1e6;

%%
writetable(T, '/u/16/bahriz1/unix/Desktop/testrat.csv');

%% Find near mistakes T1 T2 T3
addpath('/u/16/bahriz1/unix/Desktop/Functions')
addpath(genpath('/u/16/bahriz1/unix/Desktop/totahlab-master/external/nlx_linux'))
addpath('/u/16/bahriz1/unix/Desktop/totahlab-master/nelson/Attention Project')
% Om = 0, HIT = 1, CR = 2, FA = 3

baseRoot = '/u/16/bahriz1/unix/Desktop';

ratFolders = {'TN250', 'TN251', 'TN253'};   
AllT = table();


%% load all velocity data

velocity_data = {};

row = 1;

for r = 1:numel(ratFolders)
    ratID = ratFolders{r};
    baseDir = fullfile(baseRoot, ratID);

    sessions = dir(fullfile(baseDir, 'session_*'));
    sessions = sessions([sessions.isdir]);

    for i = 1:numel(sessions)

        sessName = sessions(i).name;
        sessDir = fullfile(baseDir, sessName);
        sessNum = str2double(sessName(end-1:end));
        sessStr = sprintf('%02d', sessNum);

        cd(sessDir);

        EventsName = sprintf('ekg_behavior_%s_%s_Events.nev', ratID, sessStr);
        Times = GetEventsData_linux(EventsName, 0, 'microsec');
        offset = Times.CheetahRecordingStart;

        filename = {};
        filename{1} = sprintf('ekg_behavior_%s_%s_CSC127.ncs', ratID, sessStr);

        fprintf('Loading velocity rat %s session %s\n', ratID, sessStr);

        [Vel_time, Vel, ~, ~] = GetVelocityData_linux(filename, 200);
        Vel_time = (Vel_time - offset) / 1e6;

        velocity_data{row,1} = ratID;
        velocity_data{row,2} = sessNum;
        velocity_data{row,3} = Vel_time;
        velocity_data{row,4} = Vel;

        row = row + 1;
    end
end

save(fullfile(baseRoot, 'velocity_data.mat'), 'velocity_data', '-v7.3');

%%

for r = 1:numel(ratFolders)

    ratID = ratFolders{r};
    baseDir = fullfile(baseRoot, ratID);

    sessions = dir(fullfile(baseDir, 'session_*'));
    sessions = sessions([sessions.isdir]);
    disp("Doing rat" + ratID)

    for i = 1:numel(sessions)
        sessName = sessions(i).name;                  % like 'session_06'
        sessDir  = fullfile(baseDir, sessName);

        sessNum = str2double(sessName(end-1:end));    % 06 -> 6
        sessStr = sprintf('%02d', sessNum);           % 6 -> '06'

        cd(sessDir);
        disp("Session" + sessStr)

        gngFile = sprintf('ekg_behavior_%s_%s_GNG.mat', ratID, sessStr);

        % skip session if not GNG
        if ~isfile(gngFile)
            fprintf('Skipping %s/%s (no GNG file)\n', ratID, sessName);
            continue
        end

        EventsName = sprintf('ekg_behavior_%s_%s_Events.nev', ratID, sessStr);
        Times = GetEventsData_linux(EventsName, 0, 'microsec');
      
        offset = Times.CheetahRecordingStart;   
        
        data = load(gngFile);
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
        
        % Get velocity
        filename = {};
        filename{1} = sprintf('ekg_behavior_%s_%s_CSC127.ncs', ratID, sessStr);
        
        [Vel_time, Vel, ~, ~] = GetVelocityData_linux(filename, 200);
      
        Vel_time = (Vel_time - offset) / 1e6;
        
        EndTrial_Time = 1.75;
        % create empty columns for peak vel and its time
        T.PeakVel = nan(height(T), 1);
        T.PeakVelTime = nan(height(T), 1);
        
        crRows = find(T.Correct == 2);
        
        % clip the velocity vector to match the trial duration
        for k = 1:height(T)
            fprintf('Doing velocity work. Trial %d\n', T.Trial(k));
            startIdx = find(Vel_time >= T.StimOn(k), 1, 'first');
            endIdx   = find(Vel_time <= T.StimOn(k) + EndTrial_Time, 1, 'last');
        
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
        % add ses number
        T.Session = repmat(sessNum, height(T), 1);
        % add rat ID
        T.RatID = repmat(str2double(erase(ratID, 'TN')), height(T), 1);
        
        T = movevars(T, {'RatID','Session'}, 'Before', 'StimOn');
        
        AllT = [AllT; T];

    end
end

disp("AllT created")


AllT.CR_Label = nan(height(AllT), 1);

rats = unique(AllT.RatID);

for rr = 1:numel(rats)

    crMask = AllT.RatID == rats(rr) & AllT.Correct == 2;

    tertiles = quantile(AllT.PeakVel(crMask), 2);

    AllT.CR_Label(crMask & AllT.PeakVel <= tertiles(1)) = 1;
    AllT.CR_Label(crMask & ...
                  AllT.PeakVel > tertiles(1) & ...
                  AllT.PeakVel < tertiles(2)) = 2;
    AllT.CR_Label(crMask & AllT.PeakVel >= tertiles(2)) = 3;

end

%% Save
S = table2struct(AllT);
save('AllT_struct.mat', 'S', '-v7.3');

%%
rows = find(AllT.Correct ~= 2);

for k = rows'

    clip = AllT.VelTrace{k};
    tclip = AllT.VelTime{k};

    if isempty(clip)
        continue
    end

    [peakVal, localIdx] = max(clip);

    AllT.PeakVel(k) = peakVal;
    AllT.PeakVelTime(k) = AllT.StimOn(k) + tclip(localIdx);

end

%%
load('~/Desktop/beh_list.mat');
load('~/Desktop/nev_list.mat');
load('~/Desktop/ncs_list.mat');

