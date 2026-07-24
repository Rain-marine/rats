function [Times] = GetEventsData_linux(EventsName,ZeroAligned,TimeUnit)



% ZeroAligned - can be 1 (starts at 0) or 0 (starts at recording time)
% TimeUnit - 'microsec' or 'sec'

% this next line is a function provided by Neuralynx that collects the
% times and names of events. For the upstairs set-up, we can use names to
% look things up. For downstairs set-up #1, we have an issue that that old
% version of the recording system won't let you name things (downstairs
% set-up #2 will allow it). This script has to "decode" the values of
% different bits on various channels to pull out events. Do not worry about
% understanding this part. Just use the structure variable produced (Times)
% to do your analyses. It will have times in seconds. So, just run this
% section and ignore how it works and use Times for your analyses.

[Timestamps_tmp,TTLs_tmp,Eventstrings_tmp] = Nlx2MatEV_v3([pwd '/' EventsName],[1 0 1 0 1],0,1,0);
% timestampes in microsec; start time as curent time on cheetah when
% recording started

% remove times with extra start (rare case)
StartIdx = find(~cellfun('isempty',strfind(Eventstrings_tmp,'Starting Recording')));
EndIdx = find(~cellfun('isempty',strfind(Eventstrings_tmp,'Stopping Recording')));
if length(StartIdx)>1
    [~,MaxIdx] = max(EndIdx-StartIdx);
    RecordingEndIdx = EndIdx(MaxIdx);
    RecordingStartIdx = StartIdx(MaxIdx);
    % remove extra data that was mistake (cheetah run again
    % afte rat off the ball, but before cheetah was saved
    Eventstrings_tmp = Eventstrings_tmp(RecordingStartIdx:RecordingEndIdx);
    Timestamps_tmp = Timestamps_tmp(RecordingStartIdx:RecordingEndIdx);
    TTLs_tmp = TTLs_tmp(RecordingStartIdx:RecordingEndIdx);
end

if ZeroAligned == 1
    Timestamps_tmp = Timestamps_tmp-Timestamps_tmp(1); % make times start at 0
end

if strcmp(TimeUnit,'sec')
    Timestamps_tmp = Timestamps_tmp/1E6; % change to seconds
end

% check if downstairs set-up (no event names)
if length(TTLs_tmp)>2 && any(TTLs_tmp(1:4)>64) % downstairs set-up has problems with an initial pulse on all ports
    TTLs_tmp(1:4) = 0;
end

% TTLs represent 0 if off and 2^n if on, where n is the bit (starting at 0
% on the right). So, if bit 2 (3rd number from right in cheetah) is on,
% then 2^2 = 4 and the TTL is 4. however, if two bits are one at once, the
% TTLs are added together, then if one of them turns off, that one is
% subtracted.

TTLnew = bitand(TTLs_tmp,4); 
TTLtest = TTLnew(2:end) - TTLnew(1:end-1); % add the first value up to your 'likes':
TTLtest = [TTLnew(1) TTLtest];
tmp = find(TTLtest>0);
Times.FrameOnsets = Timestamps_tmp(tmp);
    
TTLnew = bitand(TTLs_tmp,2);
TTLtest = TTLnew(2:end) - TTLnew(1:end-1); % add the first value up to your 'likes':
TTLtest = [TTLnew(1) TTLtest];
tmp = find(TTLtest>0);
Times.BodyFrameOnsets = Timestamps_tmp(tmp);
    
tmp = Timestamps_tmp(find(~cellfun('isempty',strfind(Eventstrings_tmp,'InstrResp'))));
if isempty(tmp) % Event names not available
    TTLnew = bitand(TTLs_tmp,16); % (0x0010 Hex is 16 decimal)
    TTLtest = TTLnew(2:end) - TTLnew(1:end-1); % add the first value up to your 'likes':
    TTLtest = [TTLnew(1) TTLtest];
    tmp = find(TTLtest>0);
    Times.InstruResp = Timestamps_tmp(tmp);
else
    Times.InstruResp = tmp;
end

tmp = Timestamps_tmp(find(~cellfun('isempty',strfind(Eventstrings_tmp,'Lamp'))));
if isempty(tmp) % Event names not available
    TTLnew = bitand(TTLs_tmp,128); % (0x0080 hex is 128 decimal)
    TTLtest = TTLnew(2:end) - TTLnew(1:end-1); % add the first value up to your 'likes':
    TTLtest = [TTLnew(1) TTLtest];
    tmp = find(TTLtest>0);
    Times.LampOn = Timestamps_tmp(tmp);
else
    Times.LampOn = tmp;
end

tmp = Timestamps_tmp(find(~cellfun('isempty',strfind(Eventstrings_tmp,'PremResp'))));
% ignore if no event name
Times.PremRespTrigger = tmp;

tmp = Timestamps_tmp(find(~cellfun('isempty',strfind(Eventstrings_tmp,'Reward'))));
if isempty(tmp) % Event names not available
    TTLnew = bitand(TTLs_tmp,8); % 0x008 hex is 8 decimal
    TTLtest = TTLnew(2:end) - TTLnew(1:end-1); % add the first value up to your 'likes':
    TTLtest = [TTLnew(1) TTLtest];
    tmp = find(TTLtest>0);
    Times.RewardPulse = Timestamps_tmp(tmp);
else
    Times.RewardPulse = tmp;
end

tmp = Timestamps_tmp(find(~cellfun('isempty',strfind(Eventstrings_tmp,'StimOn'))));
if isempty(tmp) % Event names not available
    TTLnew = bitand(TTLs_tmp,32); % 0x0020 is 32 demimal
    TTLtest = TTLnew(2:end) - TTLnew(1:end-1); % add the first value up to your 'likes':
    TTLtest = [TTLnew(1) TTLtest];
    tmp = find(TTLtest>0);
    Times.StimOn = Timestamps_tmp(tmp);
else
    Times.StimOn = tmp;
end

tmp = Timestamps_tmp(find(~cellfun('isempty',strfind(Eventstrings_tmp,'Feedback_Incorrect_BrownNoise'))));
if ~isempty(tmp)
    Times.Feedback = tmp;
else
    Times.Feedback = [];
end

tmp = Timestamps_tmp(find(~cellfun('isempty',strfind(Eventstrings_tmp,'Feedback_Correct_BlueNoise'))));
if ~isempty(tmp)
    Times.FeedbackCorrect = tmp;
else
    Times.FeedbackCorrect = [];
end


Times.CheetahRecordingStart = Timestamps_tmp(find(~cellfun('isempty',strfind(Eventstrings_tmp,'Starting Recording'))));
Times.CheetahRecordingEnd = Timestamps_tmp(find(~cellfun('isempty',strfind(Eventstrings_tmp,'Stopping Recording'))));
clear *_tmp


