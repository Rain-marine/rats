#!/bin/bash

#SBATCH --job-name=hssm
#SBATCH --output=logs/hssm_smapler/hssm_%x_%j.out
#SBATCH --error=logs/hssm_sampler/hssm_%x_%j.err
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4

source ~/.bashrc

conda activate /scratch/work/bahriz1/.conda_envs/hssm
conda activate hssm

python run_HSSM.py "$1"