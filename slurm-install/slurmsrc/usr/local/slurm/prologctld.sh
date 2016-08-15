#!/bin/bash
#@head node, by slurmctld  after job initiation.


FILE="/usr/local/slurm/ctldprolog.out"
echo "Running CtlD Prolog" > $FILE
echo $SLURM_JOB_NAME >> $FILE
echo $SBATCH_JOB_NAME >> $FILE
echo $SLURMD_NODENAME >> $FILE
exit 0
