function [Vel_time, Vel, Pos_time_down, Pos_down] = GetVelocityData_linux(filename,Target)


% Target is the downsampled frequency you want in Hz


% For trouble shooting how rotary encoder gets "unwrapped" from 0-5V to get
% change in position over time, see RotaryEncoderTesting.m

try
    [Pos,Pos_time] = load_CSC_linux(pwd,'single',1,0,[],filename); % in microsec
catch
    disp('Load_CSC did not work!')
end


if isnan(Pos(end))
    Pos(end) = Pos(find(~isnan(Pos),1,'last'));
end
nanx = isnan(Pos);
t    = 1:numel(Pos);
Pos(nanx) = interp1(t(~nanx), Pos(~nanx), t(nanx));


% zooming into a single peak, you see that
% the peak detection with this method is a bit delayed,
% coming perhaps 0.25 msec after the rotary encoder starts to reset.
% Also, the reset process takes about 6.5 msec.
% What I recommend is that blank the encoder signal with NaNs with a
% buffer of uncertainty going back 2 msec before peak detection time and 8 msec after
% peak detection time.
% We then unwrap the signal by shifting up all rotary encoder points (blue line)
% occurring after the peak-2msec time point until the end of the session.
% We shift them up by the last recorded rotary encoder voltage at peak-2msec.
% We then interpolate over the NaNs. And then we move on to the next peak

%threshold = 300; % this is peak detection threshold for differentiated Pos (rotary encoder voltage).

DiffPos = abs(diff(Pos));

% we set thresh dynamically. start of recording can contain a amplifier reset that is very
%large, so ignore first 10% of data for getting threshold
StartIdx = floor(0.1*length(DiffPos));
threshold = 0.9*(max(DiffPos(StartIdx:end))); 

[~,LOCS] = findpeaks(abs(diff(Pos)),'MinPeakProminence',threshold);

if ~isempty(LOCS) % a few recordings had broken channel. peaks wont be found
    
    if any(Pos_time(LOCS)<0.010)
        % if early peaks, just dump that early rotary encoder to be 0V
        idx = find(Pos_time(LOCS)<0.010,1,'last');
        Pos(1:LOCS(idx)) = zeros(length(1:LOCS(idx)),1);
        LOCS(LOCS>0.010) = LOCS; % drop that early peak
    end
    
    % blank encoder signal with NaNs 2 msec before until 8 msec after each
    % peak
    for P = 1:length(LOCS)
        selPeak = Pos_time(LOCS(P));
        sIdx = find(Pos_time<selPeak-0.002,1,'last');
        eIdx = find(Pos_time<selPeak+0.008,1,'last');
        Pos(sIdx:eIdx) = nan;
    end
    
    % fill in the data before the first rotary encoder reset
    Pos2 = Pos;
    Pos2(1:LOCS(1)-1) = Pos(1:LOCS(1)-1);
    
    % Shift the position up at the breaks
    for L = 1:length(LOCS)
        if L<length(LOCS)
            % get the last value before the NaNs around the peak
            % this StartValue is where
            StartValue = Pos2(find(~isnan(Pos2(1:LOCS(L))),1,'last'));
            DataSnip = Pos2(LOCS(L):LOCS(L+1)-1);
            
            % check if this was foward movement at trans. point (5V-to-0V transition) or
            % backward movement at transition point (0V-to-5V transition)
            if L==1
                PastDataSnip = Pos(1:LOCS(L)); % look at Pos, unedited rotatary encoder trace
            else
                PastDataSnip = Pos(LOCS(L-1):LOCS(L)); % look at Pos, unedited rotatary encoder trace
            end
            CurrentDataSnip = Pos(LOCS(L):LOCS(L+1)); % look at Pos, unedited rotatary encoder trace
            if CurrentDataSnip(find(~isnan(CurrentDataSnip),1,'first'))<PastDataSnip(find(~isnan(PastDataSnip),1,'last')) % forward
                % Shift the Data Snip between rotatory encoder reset
                % points up to the prior data
                DataSnip = DataSnip + StartValue;
            elseif CurrentDataSnip(find(~isnan(CurrentDataSnip),1,'first'))>PastDataSnip(find(~isnan(PastDataSnip),1,'last')) % backward
                % Shift the Data Snip between rotatory encoder reset
                % points up to the prior data
                DataSnip = DataSnip + StartValue - CurrentDataSnip(find(~isnan(CurrentDataSnip),1,'first'));
                %DataSnip = DataSnip + StartValue - nanmean(CurrentDataSnip);
            end
            % inset the Data Snip into the new position array ('Pos2')
            Pos2(LOCS(L):LOCS(L+1)-1) = DataSnip;
        end
        if L==length(LOCS)
            % move last snip up
            StartValue = Pos2(find(~isnan(Pos2(1:LOCS(L))),1,'last'));
            DataSnip = Pos2(LOCS(L):end);
            
            % check if this was foward movement at trans. point (5V-to-0V transition) or
            % backward movement at transition point (0V-to-5V transition)
            PastDataSnip = Pos(LOCS(L-1):LOCS(L)); % look at Pos, unedited rotatary encoder trace
            CurrentDataSnip = Pos(LOCS(L):end); % look at Pos, unedited rotatary encoder trace
            if CurrentDataSnip(find(~isnan(CurrentDataSnip),1,'first'))<PastDataSnip(find(~isnan(PastDataSnip),1,'last')) % forward
                % Shift the Data Snip between rotatory encoder reset
                % points up to the prior data
                DataSnip = DataSnip + StartValue;
            elseif CurrentDataSnip(find(~isnan(CurrentDataSnip),1,'first'))>PastDataSnip(find(~isnan(PastDataSnip),1,'last')) % backward
                % Shift the Data Snip between rotatory encoder reset
                % points up to the prior data
                DataSnip = DataSnip + StartValue - CurrentDataSnip(find(~isnan(CurrentDataSnip),1,'first'));
            end
            
            Pos2(LOCS(L):end) = DataSnip;
        end
        
    end
    
    % interpolate over the NaNs
    if isnan(Pos2(end))
        Pos2(end) = Pos2(find(~isnan(Pos2),1,'last'));
    end
    nanx = isnan(Pos2);
    t    = 1:numel(Pos2);
    Pos2(nanx) = interp1(t(~nanx), Pos2(~nanx), t(nanx));
    
    clear LOCS Pos
    
    interval = Pos_time(2)-Pos_time(1); % in microsec
    interval = interval/1E6; % in sec
    
    % remove noise from rotary encoder.
    rate_orig = 1/interval;
    Pos2 = ck_filt(Pos2,rate_orig, 5,'low');
   
   % downsample
    F = rate_orig/Target;
    new_rate = rate_orig/F;
    new_interval = 1/new_rate;
    Pos_down = downsample(Pos2,F);
    Pos_time_down = downsample(Pos_time,F);
    clear Pos2
    
    Vel = diff(Pos_down)./(new_interval*1E6);
    %Vel = fastsmooth(Vel,10,3,1);
    %Vel(Vel<0) = 0; % remove backwards movement
    
    Vel_time = Pos_time_down(1:end-1); % in microsec % end-1 because of diff
    
else
    Vel = [];
    Vel_time = [];
    
    Pos_time_down = [];
    Pos_down = [];
end

end