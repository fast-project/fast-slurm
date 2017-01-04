#!/bin/bash
#Executed when a user job is submited.
#Triggered by the prolog plugin.
#Distinction between vm jobs and user jobs are done at the prolog plugin.

cd /cluster/slurm-install/scripts/
log=/cluster/slurm-install/scripts/logs/submitprolog.txt

echo "Starting prolog_submit.sh" >> $log

vm_id=$1
user_job_id=$2
min_nodes=$3
time_limit=$4
pn_min_mem=$5
min_cpus=$6
cpu_p_tsk=$7
gres=$8

pwd >> $log

echo "$@" >> $log

xmlpath=/cluster/slurm-install/configs/$user_job_id
mkdir $xmlpath >> $log #clean it out later

while [ ! -d $xmlpath ]
do
  sleep 1
done

cp /cluster/slurm-install/configs/vm.xml $xmlpath >> $log

#add memory required for the OS on the node in megabytes
vm_total_mem=$(echo $pn_min_mem' + 1300' | bc)

sed -i "s/FLAG_MEMORY/$vm_total_mem/g" $xmlpath/vm.xml >> $log


if [ "$3" -eq "1" ] ; then
	sed -i "s/FLAG_CORES/$min_cpus/g" $xmlpath/vm.xml >> $log #cpus per task perhaps?

	#if only one node is required, a single vm_Start script is required in the ndoe that slurm chooses
	sbatch --job-name="vm_j"$user_job_id --partition=vmq --nodes=1-1 --mem=$vm_total_mem --ntasks=1 --cpus-per-task=$min_cpus --mincpus=$min_cpus --ntasks-per-node=1 --gres=$gres  \
		 /cluster/slurm-install/scripts/vm_start.sh  $user_job_id 0 &>> $log
	echo "sbatch --partition=vmq --nodes=1-1 --mem=$vm_total_mem --ntasks=1 \
	--cpus-per-task=$min_cpus --mincpus=$min_cpus --ntasks-per-node=1 --gres=$gres" > $xmlpath/subcmd.log

	echo "done submitting vm_start" >>  $log
else

	cpus_per_node=$(echo "$min_cpus/$min_nodes" | bc)
	echo $cpus_per_node"= "$min_nodes"*"$min_cpus >> $log

	sed -i "s/FLAG_CORES/$cpus_per_node/g" $xmlpath/vm.xml >> $log #cpus per task perhaps?

	#all vms need to start at the same time, so the submission needs to be done as a whole
	#sbatch --partition=vmq --nodes=$min_nodes --time=$time_limit --mem=$pn_min_mem -n $min_cpus --gres=$gres \
	sbatch --partition=vmq --mem=$pn_min_mem --nodes=1-$min_nodes --ntasks=$min_nodes --cpus-per-task=$cpus_per_node --gres=$gres \
		/cluster/slurm-install/scripts/vm_wrapper.sh $user_job_id $min_nodes $time_limit $pn_min_mem $cpus_per_node $gres &>> $log
	echo "sbatch --partition=vmq --mem=$pn_min_mem --nodes=1-1 --ntasks=1 --cpus-per-task=$cpus_per_node --gres=$gres" > $xmlpath/subcmd.log
	echo "done submitting vm_wrapper" >>  $log
fi


exit 0
