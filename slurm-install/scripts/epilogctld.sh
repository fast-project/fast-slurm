#!/bin/bash
log=/cluster/slurm-install/scripts/logs/ctldepilog.out
echo "Running CtlD Epilog" >> $log
cd /cluster/slurm-install/scripts/
pwd >> $log

#env | grep SLURM
#env >> $log

USER_JOBID=$SLURM_JOB_ID

echo "user job id: "$USER_JOBID >> $log

if [[ -d /cluster/slurm-install/configs/$USER_JOBID/ ]] ; then
	echo "folder for user job id $USER_JOBID is present" >> $log

#check if it is a user job id

        #terminate virtual machines belonging to juser job id
        #get the vms of this host that belong to the user job
        while IFS= read -r p; do


                VM_SLURM_ID=$(echo $p | awk '{ print $1 }')
                VM_HOST_NAME=$(echo $p | awk '{ print $2 }')
                VM_NAME=$(echo $p | awk '{ print $3 }')

		scontrol update node=$VM_NAME state=down reason=vmunused


		echo "Terminating vm "$VM_SLURM_ID" "$VM_HOST_NAME" "$VM_NAME >> $log


		#fast-mqtt --stopvm $VM_HOST_NAME $VM_NAME
		#flock -x stop.lock setsid /sbin/fast-mqtt --stopvm 2 $VM_HOST_NAME $VM_NAME > /dev/null  2>&1 < /dev/null &
		flock -x stop.lock timeout --kill-after=1 60 /sbin/fast-mqtt --stopvm $VM_HOST_NAME $VM_NAME > /dev/null  2>&1
		#pstree -ph > $log.tree

		echo -e "\tDone" >> $log




        done </cluster/slurm-install/configs/$USER_JOBID/vmjobids.txt


	#echo "deleting /cluster/slurm-install/configs/$USER_JOBID/" >> $log
	#make sure this happens!

	#if [ -z != $USER_JOBID ] ; then
	#	rm -r /cluster/slurm-install/configs/$USER_JOBID/ >> $log
	#fi
	#scontrol update node=$thisnode Gres=mbandwidth:10,dbandwidth:10

else
	echo "VM JOB detected, folder for user job id $USER_JOBID is NOT present" >> $log
	VM_SLURM_ID=$SLURM_JOB_ID


	sed -i "/ $VM_SLURM_ID /d" /cluster/slurm-install/scripts/macall.file >> $log
	sed -i "/ $VM_SLURM_ID /d" /cluster/slurm-install/configs/allvminfo.txt >> $log


	echo "Restoring pinning ids of this VM" >> $log
	thisnode=$SLURM_JOB_NODELIST
	echo "VM node:"$thisnode >> $log

	#restore the pinning settings
	#get cpu pins
	(
	# Wait for lock on file (fd 200) for 100 seconds
	flock -x -w 100 200
	cpulist=$(cat /cluster/slurm-install/configs/nodes/pin_"$thisnode"_$VM_SLURM_ID)
	if [ $(echo $cpulist | awk '{ printf $1 }')=="[0]" ]; then
		bcklist=$(cat /cluster/slurm-install/configs/nodes/pin_$thisnode)
		echo "$cpulist $bcklist"  > /cluster/slurm-install/configs/nodes/pin_$thisnode
	else
		printf $cpulist >> /cluster/slurm-install/configs/nodes/pin_$thisnode
	fi

	rm /cluster/slurm-install/configs/nodes/pin_$thisnode"_"$VM_SLURM_ID

	)200>/cluster/slurm-install/configs/nodes/pin_$thisnode.lock

fi


echo "Done" >> $log

exit 0
