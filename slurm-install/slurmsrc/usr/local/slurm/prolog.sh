#!/bin/bash

#@compute node, by slurmd after job initiation.

echo "Running CompD Prolog"
echo $SLURM_JOB_NAME
echo $SBATCH_JOB_NAME
echo $SLURMD_NODENAME

#env | grep SLURM
echo "done"

exit 0
