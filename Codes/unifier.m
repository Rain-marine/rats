folder = '/scratch/work/bahriz1/Thesis/data/ratId_date'; 
files = dir(fullfile(folder,'*.mat')); 
allT = table(); 
for k = 1:length(files) 
    filePath = fullfile(folder, files(k).name); 
    S = load(filePath); 
    T = S.T; 
    allT = [allT; T]; 
end 
%% Tertiles and labeling near mistakes 
allT.CR_Label = nan(height(allT), 1);
rats = unique(allT.RatID); 
for rr = 1:numel(rats) 
    crMask = allT.RatID == rats(rr) & allT.Correct == 2; 
    tertiles = quantile(allT.PeakVel(crMask), 2); 
    allT.CR_Label(crMask & allT.PeakVel <= tertiles(1)) = 1; 
    allT.CR_Label(crMask & allT.PeakVel > tertiles(1) & allT.PeakVel < tertiles(2)) = 2; 
    allT.CR_Label(crMask & allT.PeakVel >= tertiles(2)) = 3; 
end 
%% Save 
writetable(allT,'allT.csv') 
%% 
S = table2struct(allT); 
%% 
save('allT_struct.mat', 'S', '-v7.3');