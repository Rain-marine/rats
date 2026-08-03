You'll need to clone this repository and put the folder "totahlab" next to the Codes folder.
https://github.com/ntotah/totahlab.git



We need a dataset (table) that looks like this:

<img width="1690" height="262" alt="image" src="https://github.com/user-attachments/assets/5dd15477-515b-4df3-a989-a781787ff457" />
<img width="1751" height="272" alt="image" src="https://github.com/user-attachments/assets/1476b141-be4e-42ee-ba83-88983eaf4eab" />



Each session has these 3 files: behavior file (.mat), velocity file (.ncs) and events file (.nev). To create the full dataset, all 3 files for each session must be downloaded, loaded into Matlab and processed according to desire. The Matlab function Codes/rawdrec2dataset.m does the processing. It takes (all as strings) the ratID, session's data in ddmmyy format, the path where the 3 files are stored and the behavior, event and velocity file names respectively. Example: 
```
rawrec2dataset('8122', '190718', '/scratch/work/bahriz1/Thesis/rerun_downloads/8122_190718','Rat 8122 Lev5_GNG2Stim 19-Jul-2018.mat', 'Events_8122_190718.nev', 'CSC63_8122_190718.ncs')
```
It outputs in the directory data/ratId_date/ one .mat file for the whole session. This .mat file contains a table that looks like this:
<img width="1472" height="511" alt="image" src="https://github.com/user-attachments/assets/09bfe1c8-4312-4405-823a-ae2f495da8be" />

---- IN CASE FUNCTIONS ARE CLONED FROM TOTAHLAB REPO ----
NOTE: To avoid some files from timing out, go to nelson/Attention Project/GetVelocityData_linux.m, and change line 64 (shown in the picture) to threshold = 0.9*maxVal.
This won't have any impact on the results we'll get later but it will noticeably make it faster.

UPDATE: : in totahlab/nelson/Attention Project/GetVelocityData.m line 15 from
```
[Pos,Pos_time] = load_CSC_linux(pwd,'single',1,0,[],filename);
```
to
```
[Pos,Pos_time] = load_CSC_linux_new2026(pwd,filename);
```

<img width="852" height="401" alt="image" src="https://github.com/user-attachments/assets/004a2318-a7ce-4ce5-b47f-61ebdd55c3b4" />
------------------------------------------------------------

1. Submit the jobs to Triton:
```
sbatch --array=1-142%10 download_raw2dataset_batch.sh
```
Explanation: Behavior, Events and Velocity file names are respectively stored in data/beh_list.mat, data/nev_list.mat and data/ncs_list.mat.
I wrote Codes/download_list_creator.ipynb to create the jobs.txt file. Each line in jobs.txt is the required data and file names for one session. Codes/download_single_session.py gets this data as inputs, downloads them from datacloud and runs Codes/rawrec2dataset.m on them. thus in summary, Codes/download_single_session.py downloads ONE sessions data and outputs data/ratId_data/Rat's ID_Session's Date.mat.
The batch job download_raw2dataset_batch.sh simply automatizes this process by submitting 142 jobs on Triton, where each "job" is doing this process for 10 sessions (e.g. 10 lins in jobs.txt). The reason for 142 jobs is because jobs.txt had 1420 lines. CAUTION: it is super importatnt that the last meaningful line in jobs.txt ends with a \n AKA has an empty line after it. (Look at how download_raw2dataset_batch.sh reads lines from jobs.txt)


