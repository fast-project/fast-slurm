#!/bin/bash

#called by loadbal.sh when a migration has to be trigger for load balancing



#SBATCH --output=/cluster/slurm-install/scripts/logs/migratevm.log


echo $@

echo "Migrating VM to another node "
hostname
thisnode=$(hostname)

#env | grep SLURM

#MQTT start vm and store its pid


USER_JOBID=$2
myvmname=$1

rawvmname=${myvmname:2:10}

echo "All params: "$@

vmupath=/cluster/slurm-install/configs/$USER_JOBID
newvmupath=/cluster/slurm-install/configs/$SLURM_JOB_ID

echo $myvmname

#check the user job is still running
checkUserJob=$(scontrol show job $USER_JOBID | grep "JobState=RUNNING" | wc -l)
if [ $checkUserJob -eq 1 ]; then


#delete old record for this VM
previnfo=$(cat /cluster/slurm-install/configs/allvminfo.txt | grep $myvmname)
oldnode=$(echo $previnfo | awk '{print $2}')
oldvmstartjobid=$(echo $previnfo | awk '{print $3}')


echo "previnfo: "$previnfo

sed -i "/$myvmname/d"  /cluster/slurm-install/configs/allvminfo.txt
echo $myvmname" "$thisnode" "$SLURM_JOB_ID" "$USER_JOBID >> /cluster/slurm-install/configs/allvminfo.txt


sed -i "/$myvmname/d" $vmupath/vmjobids.txt
echo $SLURM_JOB_ID" "$thisnode" "$myvmname >> $vmupath/vmjobids.txt

#get the new pinning details to submit through migration mqtt msg

#cpulist
(
#START ATOMIC ACCESS
# Wait for lock on file (fd 200) for 100 seconds
flock -x -w 100 200

if [ $(squeue | grep $thisnode | wc -l) -eq 1 ]; then
cp /cluster/slurm-install/configs/nodes/pin_fast-0X /cluster/slurm-install/configs/nodes/pin_$thisnode
rm /cluster/slurm-install/configs/nodes/pin_$thisnode"_*"
fi

cpulist=$(cut -d " " -f 1-$SLURM_JOB_CPUS_PER_NODE "/cluster/slurm-install/configs/nodes/pin_$thisnode")
restlist=$(cut -d " " -f $(($SLURM_JOB_CPUS_PER_NODE+1))-100 "/cluster/slurm-install/configs/nodes/pin_$thisnode")
#cut -d " " -f $(($SLURM_JOB_CPUS_PER_NODE+1))-100 "/cluster/slurm-install/configs/nodes/pin_$thisnode"
echo $restlist > /cluster/slurm-install/configs/nodes/pin_$thisnode
echo $cpulist > /cluster/slurm-install/configs/nodes/pin_"$thisnode"_$SLURM_JOB_ID

cpupinlist=0-31
echo "${cpulist:0:3}"
if [ "${cpulist:0:3}" == "[0]"  ] ; then
        socketID=1
        cpupinlist=0-7,16-23
else
        cpupinlist=8-15,24-31
        socketID=2
fi

sed -i 's/FLAG_SOCKET/'$(($socketID-1))'/g' $thisxmlpath
sed -i 's/FLAG_PIN/'$cpupinlist'/g' $thisxmlpath

echo "$socketID $cpupinlist"

scontrol update jobid=$SLURM_JOB_ID JobName=$rawvmname":"$USER_JOBID":"$socketID

echo $cpulist
echo $restlist

#send the mqtt mesage
fast-mqtt --migratevm $myvmname $oldnode $thisnode [$cpulist]


#flock -u 200
) 200>/cluster/slurm-install/configs/nodes/pin_$thisnode.lock



while  [ $migCheck -eq 0  ] ; do
	sleep 1
	migCheck=$(ssh -q $myvmname  exit; echo $?)
done

scancel $oldvmstartjobid


#do while
while : ; do

UPID_PRESENT=$(squeue -j $USER_JOBID --format=%t | sed -n 2p ) 2>&1


if [[  "$UPID_PRESENT" == "PD" || "$UPID_PRESENT" == "R" || "$UPID_PRESENT" == "CG" || "$UPID_PRESENT" == "PD" ||  "$UPID_PRESENT" == "S" ]]; then
	#echo "PRESENT"
	sleep 1
else
	date
	echo "NOT PRESENT"
	break
fi

done

echo "done migrating"

else

echo "User Job $USER_JOBID already finished!"

fi



