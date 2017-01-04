#!/bin/bash

#called by ?

myvmname=$1


#delete old record for this VM
previnfo=$(cat /cluster/slurm-install/configs/allvminfo.txt | grep $myvmname)

echo "vm requested: $1, found: $previnfo"
if [[ $previnfo != "" ]]; then
	echo $previnfo
	oldnode=$(echo $previnfo | awk '{ print $2 }')
	oldvmstartjobid=$(echo $previnfo | awk '{ print $3 }')
	USER_JOBID=$(echo $previnfo | awk '{ print $4 }')

	subcmd=$(cat /cluster/slurm-install/configs/$USER_JOBID/subcmd.log)

	#update the command here when KPIs are available

	vmnumber=$(echo $myvmname | sed 's/vm//g')
	echo "moving vm number "$vmnumber" of user job id "$USER_JOBID
	echo "$subcmd /cluster/slurm-install/scripts/migrate_vm.sh $myvmname $USER_JOBID"
	$subcmd --job-name="M"$vmnumber":"$USER_JOBID  --exclude=$oldnode --nice=-5000 /cluster/slurm-install/scripts/migrate_vm.sh $myvmname $USER_JOBID

else
	echo "No such vm running at the moment."
fi
