#!/bin/bash

#called by ?



#SBATCH --output=/cluster/slurm-install/scripts/logs/migratevm.log


echo $@

echo "Migrating VM to another node "
hostname
thisnode=$(hostname)

#env | grep SLURM

#MQTT start vm and store its pid


USER_JOBID=$1
myvmname=$2

echo "All params: "$@

vmupath=/cluster/slurm-install/configs/$USER_JOBID


echo $myvmname

#record vmjobid for later destruction

#delete old record for this VM
previnfo=$(cat /cluster/slurm-install/configs/allvminfo.txt | grep $myvmname)
oldnode=$(cat $previnfo | awk 'print $2')
oldvmstartjobid=$(cat $previnfo | awk 'print $3')

sed -i "/$myvmname/d"  /cluster/slurm-install/configs/allvminfo.txt
echo $myvmname" "$thisnode" "$SLURM_JOB_ID >> /cluster/slurm-install/configs/allvminfo.txt


sed -i "/$myvmname/d" $vmupath/vmjobids.txt
echo $SLURM_JOB_ID" "$thisnode" "$myvmname >> $vmupath/vmjobids.txt

#send the mqtt mesage
timeout 60 sh -c 'fast-mqtt --migratevm $myvmname $thisnode $oldnode' &> /dev/null

sleep 2

scancel $oldvmstartjobid


#do while
while : ; do

UPID_PRESENT=$(squeue -j $USER_JOBID --format=%t | sed -n 2p ) 2>&1


if [[  "$UPID_PRESENT" == "PD" || "$UPID_PRESENT" == "R" || "$UPID_PRESENT" == "CG" || "$UPID_PRESENT" == "PD" ||  "$UPID_PRESENT" == "S" ]]; then
	#echo "PRESENT"
	sleep 1
else
	echo "NOT PRESENT"
	break
fi

done

