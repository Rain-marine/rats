#!/bin/bash

#SBATCH --job-name=dataAnalyst
#SBATCH --output=logs/out_%A_%a.txt
#SBATCH --error=logs/err_%A_%a.txt
#SBATCH --time=00:20:00
#SBATCH --mem=16G

START=$SLURM_ARRAY_TASK_ID
END=$SLURM_ARRAY_TASK_ID

TOTAL=$(wc -l < jobs_rerun.txt)

if [ $END -gt $TOTAL ]; then
    END=$TOTAL
fi

for LINE_NUM in $(seq $START $END)
do

    LINE=$(sed -n "${LINE_NUM}p" jobs_rerun.txt)

    IFS='|' read RATID DATESTR BEHFILE NEVFILE NCSFILE <<< "$LINE"

    python Codes/download_single_session.py \
        "$RATID" \
        "$DATESTR" \
        "$BEHFILE" \
        "$NEVFILE" \
        "$NCSFILE"

done