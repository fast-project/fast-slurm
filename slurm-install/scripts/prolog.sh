#!/bin/bash          
echo "Running CompD Prolog"
echo $SLURM_JOB_NAME
echo $SBATCH_JOB_NAME
echo $SLURMD_NODENAME

pwd

#env | grep SLURM
echo "done"

exit 0
