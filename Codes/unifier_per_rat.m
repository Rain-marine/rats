folder = '/scratch/work/bahriz1/Thesis/data/ratId_date';

files = dir(fullfile(folder, '*.mat'));

outFolder = '/scratch/work/bahriz1/Thesis/data/per_rat';
if ~exist(outFolder, 'dir')
    mkdir(outFolder)
end

ratIds = strings(length(files), 1);
%%

for k = 1:length(files)
    parts = split(files(k).name, '_');
    ratIds(k) = parts(1);
end
%%

ratIds = unique(ratIds);

%% For specific rats:
folder = '/scratch/work/bahriz1/Thesis/data/ratId_date';

files = dir(fullfile(folder, '*.mat'));

outFolder = '/scratch/work/bahriz1/Thesis/data/per_rat';
if ~exist(outFolder, 'dir')
    mkdir(outFolder)
end

ratIds = ["291", "293", "561", "8582"];

%%

for r = 1:length(ratIds)

    ratId = ratIds(r);

    fprintf('Processing rat %s\n', ratId)

    allT = table();

    for k = 1:length(files)

        parts = split(files(k).name, '_');

        if parts(1) ~= ratId
            continue
        end

        filePath = fullfile(folder, files(k).name);

        S = load(filePath);
        T = S.T;


        allT = [allT; T];

    end

    allT.CR_Label = nan(height(allT), 1);

    crMask = allT.Correct == 2;

    tertiles = quantile(allT.PeakVel(crMask), 2);

    allT.CR_Label(crMask & allT.PeakVel <= tertiles(1)) = 1;
    allT.CR_Label(crMask & allT.PeakVel > tertiles(1) & allT.PeakVel < tertiles(2)) = 2;
    allT.CR_Label(crMask & allT.PeakVel >= tertiles(2)) = 3;

    save(fullfile(outFolder, sprintf('%s_allT.mat', ratId)), 'allT', '-v7.3');
    writetable(allT, fullfile(outFolder, sprintf('%s_allT.csv', ratId)))

    fprintf('Saved rat %s\n', ratId)

end