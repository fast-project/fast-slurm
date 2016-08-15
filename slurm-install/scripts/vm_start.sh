#!/bin/bash

#called by slurm on each compute node as submited by  vm_wrapper

#job_id=$1
#node_idx=$2 #is this the first or any other call to the script
#NUM_NODES=$3
#nodelist=$4


#SBATCH --output=/cluster/slurm-install/scripts/logs/vmstart.log

echo $@

echo "Starting VM on node "
hostname
thisnode=$(hostname)

env | grep SLURM

#MQTT start vm and store its pid


USER_JOBID=$1
echo $USER_JOBID

vmupath=/cluster/slurm-install/configs/$USER_JOBID

#pconfig=$vmupath/parastation.config


echo "All params: "$@

mymac=$(flock -x macall.file /cluster/slurm-install/scripts/genmac.sh)
macid=$(echo $mymac | tail -c 3)
rawvmname=$(echo "obase=10; $((0x$macid))" | bc)
myvmname="vm"$(echo "obase=10; $((0x$macid))" | bc)
echo $myvmname

#create XML
thisxmlpath=$vmupath/$myvmname.xml
mv $vmupath/vm.xml $thisxmlpath

vmimage=$vmupath/$myvmname.qcow2
qemu-img create -f qcow2 -b /cluster/vm-images/ubuntu15010/fast-vm-base.qcow2  $vmimage


sed -i 's/FLAG_MAC/'$mymac'/g' $thisxmlpath
sed -i 's/FLAG_UUID/'$macid'/g' $thisxmlpath
sed -i 's/FLAG_VMNAME/'$myvmname'/g' $thisxmlpath

sed -i 's@FLAG_VMIMAGE@'$vmimage'@g' $thisxmlpath

#sed -i 's/#FLAG_VMNAME/$myvmname $2 process any\n\t#FLAG_VMNAME/g' $pconfig

#record vmjobid for later destruction
echo $SLURM_JOB_ID" "$thisnode" "$myvmname >> $vmupath/vmjobids.txt
echo $myvmname" "$thisnode" "$SLURM_JOB_ID >> /cluster/slurm-install/configs/allvminfo.txt

#send the mqtt mesage
#fast-mqtt --startvm $thisnode $myvmname $thisxmlpath &> /dev/null &
flock -x stop.lock timeout --kill-after=1 30 fast-mqtt --startvm $thisnode $myvmname $thisxmlpath &> /dev/null
#flock -x stop.lock fast-mqtt --startvm $thisnode $myvmname $thisxmlpath &> /dev/null
#fast-mqtt --statusStartvm $myvmname ?

#sleep 2
if [ $2 -eq 1  ]
then #Only one instance of this script should move the  move to the proper compute queue

	NUM_NODES=$3
	VMNODE_LIST=$4

	n=$(wc -l < $vmupath/vmjobids.txt)
	while [ $n -lt 	$NUM_NODES ]
	do
		sleep 1
		n=$(wc -l < $vmupath/vmjobids.txt)
	done


	#the list of nodes is in the file but was also passed by the vm_wrapper to all vm_starts

	echo "moving multiple node job to computeq"
	scontrol update jobid=$USER_JOBID partition=computeq nodelist=$VMNODE_LIST
	scontrol update jobid=$SLURM_JOB_ID JobName=$rawvmname":"$USER_JOBID
else

	#in this case the scrpt was callled directly for a single node job, the node list will be 1 node
	if [ $2 -eq 0  ]
	then
		echo "moving single node job to computeq"

        	scontrol update jobid=$USER_JOBID partition=computeq nodelist=$myvmname
		scontrol update jobid=$SLURM_JOB_ID JobName=$rawvmname":"$USER_JOBID

	fi
fi

scontrol update node=$myvmname state=idle
scontrol update node=$myvmname state=undrain
#scontrol update NodeName=$myvmname State=down Reason=hung_proc;
#scontrol update NodeName=$myvmname State=resume

#sleep or wait for USER JOB to finish
#wait for the jobid to finish and then kill the vm

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

#if [ $2 -eq 1  ]; then
#	echo "Killing vm"
#	#kill vm in this script
#	fast-mqtt stopvm $thisnode $myvmname &
#	#rm -rf $vmupath
#fi

#on postscript kill the vm pid?
#MQTT VM STOP VMPID
