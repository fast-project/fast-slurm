#!/bin/bash

FILE="/cluster/slurm-install/logs/ctldprolog.out"

echo "Running CtlD Prolog" > $FILE
echo $SLURM_JOB_NAME >> $FILE
echo $SBATCH_JOB_NAME >> $FILE
echo $SLURMD_NODENAME >> $FILE


pwd

exit 0
