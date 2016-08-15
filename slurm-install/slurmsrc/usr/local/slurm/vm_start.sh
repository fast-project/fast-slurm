#!/bin/bash
#SBATCH --output=/usr/local/slurm/logs/vmstart_log.txt

echo $@

echo "Starting VM on node "
hostname

env | grep SLURM

#MQTT start vm and store its pid
VMPID=$1
#generate XML file

#startthevm


USER_JOBID=$2
echo "$USER_JOBID"

sleep 2
#Only one instance of this script should move the  move to the proper compute queue
if [ $3 -eq 1  ]
	NODE_LIST=$4
	scontrol update jobid=$USER_JOBID partition=computeq nodes=$NODE_LIST
else
	#in this case the scrpt was callled directly for a single node job, the node list will be 1 node
	if [ $3 -eq 0  ]
        	scontrol update jobid=$USER_JOBID partition=computeq nodes=$SLURM_NODELIST
	fi
fi

#sleep or wait for USER JOB to finish
#wait for the jobid to finish and then kill the vm

UPID_PRESENT=$(squeue -j $USER_JOBID --format=%t | sed -n 2p ) 2>&1
#do while
while : ; do
if [  "$UPID_PRESENT" == "PD" || "$UPID_PRESENT" == "R" || "$UPID_PRESENT" == "CG" || "$UPID_PRESENT" == "PD" ||  "$UPID_PRESENT" == "S" ]
then
	echo "PRESENT"
	#sleep 5
else
	echo "NOT PRESENT"
	break
fi
done

#on postscript kill the vm pid
#MQTT VM STOP VMPID
