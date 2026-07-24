#!/bin/bash

#SBATCH --job-name=dataAnalyst
#SBATCH --output=logs/out_%A_%a.txt
#SBATCH --error=logs/err_%A_%a.txt
#SBATCH --time=04:00:00
#SBATCH --mem=16G

START=$(( ($SLURM_ARRAY_TASK_ID - 1) * 10 + 1 ))
END=$(( $START + 9 ))

TOTAL=$(wc -l < jobs.txt)

if [ $END -gt $TOTAL ]; then
    END=$TOTAL
fi

for LINE_NUM in $(seq $START $END)
do

    LINE=$(sed -n "${LINE_NUM}p" jobs.txt)

    IFS='|' read RATID DATESTR BEHFILE NEVFILE NCSFILE <<< "$LINE"

    python Codes/download_single_session.py \
        "$RATID" \
        "$DATESTR" \
        "$BEHFILE" \
        "$NEVFILE" \
        "$NCSFILE"

done