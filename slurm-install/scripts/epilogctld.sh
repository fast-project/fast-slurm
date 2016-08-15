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
else
	echo "folder for user job id $USER_JOBID is NOT present" >> $log

fi

#check if it is a user job id

        #terminate virtual machines belonging to juser job id
        #get the vms of this host that belong to the user job
        while IFS= read -r p; do


                VM_SLURM_ID=$(echo $p | awk '{ print $1 }')
                VM_HOST_NAME=$(echo $p | awk '{ print $2 }')
                VM_NAME=$(echo $p | awk '{ print $3 }')



		echo "Terminating vm "$VM_SLURM_ID" "$VM_HOST_NAME" "$VM_NAME >> $log


		#fast-mqtt --stopvm $VM_HOST_NAME $VM_NAME
		#flock -x stop.lock setsid /sbin/fast-mqtt --stopvm 2 $VM_HOST_NAME $VM_NAME > /dev/null  2>&1 < /dev/null &
		flock -x stop.lock timeout --kill-after=1 60 /sbin/fast-mqtt --stopvm $VM_HOST_NAME $VM_NAME > /dev/null  2>&1
		pstree -ph > $log.tree
		scontrol update node=$VM_NAME state=down reason=vmunused
		#scancel $VM_SLURM_ID

		sed -i "/$VM_NAME/d" /cluster/slurm-install/scripts/macall.file
		sed -i "/$VM_NAME/d" /cluster/slurm-install/configs/allvminfo.txt

		echo -e "\tDone" >> $log

        done </cluster/slurm-install/configs/$USER_JOBID/vmjobids.txt
	echo "deleting /cluster/slurm-install/configs/$USER_JOBID/" >> $log
	#make sure this happens!

	if [ -z != $USER_JOBID ] ; then
		rm -r /cluster/slurm-install/configs/$USER_JOBID/
	fi


echo "Done" >> $log

exit 0
