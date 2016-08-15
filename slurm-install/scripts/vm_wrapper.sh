#!/bin/bash
#SBATCH --output=/cluster/slurm-install/scripts/logs/wrapper.log

#submits vmstart scripts to all copmpute nodes

user_job_id=$1
min_nodes=$2
time_limit=$3
pn_min_mem=$4
cpus_per_vm=$5
gres=$6
echo "Starting Multiple VMs on $SLURM_NODELIST"


export IFS=";"

#send the individual vm scripts to a HIGH priority vmq called vmqp
for (( i=1; i<=$min_nodes; i++ ))
do
	#--nodelist=$SLURM_NODELIST
	echo "submitting vm_start.sh: $SLURM_NODELIST $min_cpus"
	sbatch --partition=vmq --nodes=1-1 --ntasks=1 --ntasks-per-node=1 --time=$time_limit --mem=$pn_min_mem --cpus-per-task=$cpus_per_vm --gres=$gres  \
			/cluster/slurm-install/scripts/vm_start.sh  $user_job_id $i $SLURM_JOB_NUM_NODES $SLURM_NODELIST
done

echo "done submitting vm_start for all requested nodes"

#tune this so that the system obtains moves the newly submitted jobs ahead
sleep 2

#verify that the jobs have taken their place?

hostname

#env | grep SLURM

