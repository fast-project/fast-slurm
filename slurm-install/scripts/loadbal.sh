#!/bin/bash

#called by slurmctld_loadbal plugin as a parent process

echo "Entering loadbalancing loop script."

prevCheksum=""
migThreashold=10000
socketMax=24000
socketUsableThreashold=20000
socketIdle=3000
sleepTimeSec=5
#requiredMinutes=1

#sourceNode
#targetNode

while [ 1 ]
do

minLoad=100000
maxLoad=0
minNode=fast-0X
maxNode=fast-0X


#scontrol update partition=vmq state=DRAIN


echo "------------------------------------------------------"

for i in {1..4}
do


	if [ $(scontrol show node fast-0$i | grep -e 'State=IDLE\|State=MIXED\|State=ALLOCATED' | wc -l) -eq 1 ]; then

	#rawq=$(scontrol show job -o | grep 'fast-0$i' |  grep "JobState=RUNNING")
	vmcount=$(scontrol show job -o | grep 'fast-0$i' |  grep "JobState=RUNNING" | wc -l)
	load=$(cat /cluster/slurm-install/configs/KPIs/KPIfast-0$i.txt | grep ' BW:' | awk '{printf $2}')
	s1load=$(cat /cluster/slurm-install/configs/KPIs/KPIfast-0$i.txt | grep s1BW | awk '{printf $2}')
	s2load=$(cat /cluster/slurm-install/configs/KPIs/KPIfast-0$i.txt | grep s2BW | awk '{printf $2}')


	#record min and max for vm migration
	if [ $vmcount -ge 2 ] && [ $(echo $load'>'$maxLoad | bc -l)  -eq 1 ]  ; then
		maxLoad=$load
		maxNode=fast-0$i
	fi

	if [ $vmcount -eq 0 ] && [ $(echo $load'<'$minLoad | bc -l)  -eq 1 ] ; then
		minLoad=-1
                minNode=fast-0$i
	else
		if [ $(echo $load'<'$minLoad | bc -l)  -eq 1 ]; then
	                minLoad=-1
	                minNode=fast-0$i
		fi
	fi

	fi
done

echo "MIN:$minNode LOAD:$minLoad MB/s     MAX:$maxNode LOAD:$maxLoad MB/s"
maxVmCount=$(scontrol show job -o | grep "JobState=RUNNING" | grep $maxNode | wc -l)
minVmCount=$(scontrol show job -o | grep "JobState=RUNNING" | grep $minNode | wc -l)
if [ "$maxNode" != "fast-0X" ] && [ "$minNode" != "fast-0X"  ]  && [ "$minNode" != "$maxNode" ] \
	&& [ $maxVmCount -ne $minVmCount  ] ; then


#extra logic for when node has a program that would overload the system


#check if the most loaded node is not the same as the least laoded node
#is7 the load diference significant?
if [ $(($maxLoad-$minLoad)) -gt $migThreashold ] ; then
	echo "Load difference of $maxLoad - $minLoad is enough"

	#helps identify if a migration has been done before
	checksum=$(squeue | grep "$minNode\|$maxNode" | awk '{ printf " "$1}' | sort | md5sum)
	#echo "checksum: $checksum"
	if [ "$checksum" != "$prevChecksum" ] ; then

	        s1load=$(cat /cluster/slurm-install/configs/KPIs/KPI$maxNode.txt | grep s1BW | awk '{printf $2}')
        	s2load=$(cat /cluster/slurm-install/configs/KPIs/KPI$maxNode.txt | grep s2BW | awk '{printf $2}')

		maxSocket=1
		if [ $s1load -lt $s2load ] ;then
		maxSocket=2
		fi

		targetMig=$(scontrol show job -o | grep "JobState=RUNNING" | grep $maxNode | grep "JobName=[0-9]*:[0-9]*:$maxSocket")

		targetVMJobID=$(echo "$targetMig" |  grep -o 'JobId=[0-9]*' | awk -F'=' '{print $2}')
		targetVM=$(echo "$targetMig" |  grep -o 'JobName=[0-9]*' | awk -F'=' '{print $2}')
		targetUserJobID=$(echo "$targetMig" |  grep -o 'JobName=[0-9]*:[0-9]*' | awk -F'[=:]' '{print $3}')

		echo "Testing Nodes: $maxNode|$minNode  Loads:$maxLoad|$minLoad  $maxNode Sockets:$s1load|$s2load   Job:$targetVMJobID, UJob:$targetUserJobID, VM:vm$targetVM Socket:$maxSocket"
		echo "User Job exists, migrating VM:$targetVM from $maxNode to $minNode"

		#obtain the cmd to resubmit the vm_job
       		subcmd=$(cat /cluster/slurm-install/configs/$targetUserJobID/subcmd.log)

		migJobID=$($subcmd --nodelist=$minNode --job-name=$targetVM":"$targetUserJobID":1"  --exclude=$maxNode --nice=-5000 \
							/cluster/slurm-install/scripts/migrate_vm.sh "vm"$targetVM $targetUserJobID | awk '{print $4}')
		COUNTER=0
		migCheck=$(ssh -q vm$targetVM  exit; echo $?) #up host
		echo "Waiting for vm$targetVM to be migrated..."
		while  [ $migCheck -eq 0  ] && [  $COUNTER -lt 30 ]; do
                        sleep 1
                        migCheck=$(ssh -q vm$targetVM  exit; echo $?)
			let COUNTER=COUNTER+1
                done

		echo "Original vm$targetVM is down..."
		migCheck=255 #down host
		jobCheck=0
		while [ $jobCheck -ne 1 ] || [ $migCheck -ne 0  ] ; do
			sleep 1
			jobCheck=$(scontrol show job=$migJobID | grep "JobState=RUNNING" | wc -l)
			migCheck=$(ssh -q vm$targetVM  exit; echo $?)
		done
		echo "vm$targetVM has been started at $minNode"


	else
		echo "This migration has already been done."
	fi
else
	echo "Load difference not big enough"

fi

else
	echo "No suitable nodes found"
fi

#scontrol update partition=vmq state=UP

sleep $sleepTimeSec

done
