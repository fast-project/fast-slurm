#!/bin/bash
#SBATCH --output=/usr/local/slurm/logs/vmwrapper_log.txt
echo "Starting Multiple VMs on"

#get the nodes where each single vmstart script should go
@node_arr = split(/;/, $SLURM_NODELIST);

#send the individual vm scripts
for i in {1..$SLURM_JOB_NUM_NODES}
do
	sbatch --partition=vmqp --nodelist=$node_arr[$i] --nodes=1 --time=$4 --mem=$5 -n $6 /usr/local/slurm/vm_start.sh $1 $2 $i $SLURM_NODELIST
done

echo "done submitting vm_start for all requested nodes"

hostname

env | grep SLURM

