#!/bin/bash

#called by slurm on each compute node as submited by  vm_wrapper

#job_id=$1
#node_idx=$2 #is this the first or any other call to the script
#NUM_NODES=$3
#nodelist=$4


#SBATCH --output=/cluster/slurm-install/scripts/logs/vmstart_%j.log

#echo $@

echo "Starting VM on node "
hostname
thisnode=$(hostname)

#env | grep SLURM

#MQTT start vm and store its pid


cpulist=""
restcpulist=""

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

while [ ! -f $vmupath/vm.xml ]; do sleep 1; done

#create XML
thisxmlpath=$vmupath/$myvmname.xml
cp $vmupath/vm.xml $thisxmlpath

vmimage=$vmupath/$myvmname.qcow2
qemu-img create -f qcow2 -b /cluster/vm-images/ubuntu15010/fast-vm-base.qcow2  $vmimage


sed -i 's/FLAG_MAC/'$mymac'/g' $thisxmlpath
sed -i 's/FLAG_UUID/'$macid'/g' $thisxmlpath
sed -i 's/FLAG_VMNAME/'$myvmname'/g' $thisxmlpath

sed -i 's@FLAG_VMIMAGE@'$vmimage'@g' $thisxmlpath

#sed -i 's/#FLAG_VMNAME/$myvmname $2 process any\n\t#FLAG_VMNAME/g' $pconfig

#record vmjobid for later destruction
echo $SLURM_JOB_ID" "$thisnode" "$myvmname >> $vmupath/vmjobids.txt
echo $myvmname" "$thisnode" "$SLURM_JOB_ID" "$USER_JOBID >> /cluster/slurm-install/configs/allvminfo.txt


#exec 200>/cluster/slurm-install/configs/nodes/pin_$thisnode.lock
#get cpu pins
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

#flock -u 200
) 200>/cluster/slurm-install/configs/nodes/pin_$thisnode.lock


#send the mqtt mesage
#fast-mqtt --startvm $thisnode $myvmname $thisxmlpath &> /dev/null &
flock -x stop.lock timeout --kill-after=1 30 fast-mqtt --startvm $thisnode $myvmname $thisxmlpath &> /dev/null


#sleep 2
if [ $2 -eq 1  ]
then #Only one instance of this script should move the  move to the proper compute queue

	NUM_NODES=$3
	#VMNODE_LIST=$4

	echo "waiting to move multiple_node_job to computeq"


	n=$(wc -l < $vmupath/vmjobids.txt)
	while [ $n -lt 	$NUM_NODES ]
	do
		sleep 1
		n=$(wc -l < $vmupath/vmjobids.txt)
	done

	echo "moving multiple_node_job to computeq"

	VMNODE_LIST=$(cat $vmupath/vmjobids.txt | awk '{ print $3 }' | sed ':a;N;$!ba;s/\n/,/g')
	echo "vm node list: "$VMNODE_LIST

	vmlist_array=($(cat $vmupath/vmjobids.txt | awk '{ print $3 }' |  sed ':a;N;$!ba;s/\n/ /g'))


	echo ${vmlist_array[@]}

        cp /cluster/slurm-install/configs/parastation.conf $vmupath
        sed -i "s/FLAG_1/${vmlist_array[0]}/g" $vmupath/parastation.conf



	for (( i=1; i<$n; i++ ));
	do
	        sed -i "s/#FLAG_2/${vmlist_array[$i]} $i processes any\n\t#FLAG_2/g" $vmupath/parastation.conf
	done


	#the list of nodes is in the file but was also passed by the vm_wrapper to all vm_starts
	scontrol update jobid=$USER_JOBID partition=computeq nodelist=$VMNODE_LIST
else

	#in this case the scrpt was callled directly for a single node job, the node list will be 1 node
	if [ $2 -eq 0  ]
	then
		echo "moving single node job to computeq"
		cp /cluster/slurm-install/configs/parastation.conf $vmupath
		sed -i 's/FLAG_1/'$myvmname'/g' $vmupath/parastation.conf

        	scontrol update jobid=$USER_JOBID partition=computeq nodelist=$myvmname

	fi
fi

scontrol update node=$myvmname state=idle
scontrol update node=$myvmname state=undrain
#scontrol update NodeName=$myvmname State=down Reason=hung_proc;
#scontrol update NodeName=$myvmname State=resume


#do while
while : ; do

UPID_PRESENT=$(squeue -j $USER_JOBID --format=%t | sed -n 2p ) 2>&1

if [  "$UPID_PRESENT" == "PD"  ]; then

        #echo "PRESENT"
        sleep 2
else
        echo "Reppining, State:"$UPID_PRESENT" "
        break 2
fi

done


formattedCPULIST=$(echo $cpulist | sed 's/ /,/g')
#echo $cpulist | sed 's/ /,/g'
#echo $formattedCPULIST

#flock -x stop.lock timeout --kill-after=1 30 fast-mqtt --repinvm $thisnode $myvmname [$formattedCPULIST]
#printf "\n---\ntask: repin vm\nvm-name: $myvmname\nvcpu-map: [$formattedCPULIST]\n---" | mosquitto_pub -h fast-login -t fast/migfra/$thisnode/task -s

#sleep or wait for USER JOB to finish
#wait for the jobid to finish and then kill the vm

#do while
while : ; do

UPID_PRESENT=$(squeue -j $USER_JOBID --format=%t | sed -n 2p ) 2>&1
#squeue -j $USER_JOBID --format=%t | sed -n 2p

if [[  "$UPID_PRESENT" == "PD" || "$UPID_PRESENT" == "R" || "$UPID_PRESENT" == "CG" || "$UPID_PRESENT" == "PD" ||  "$UPID_PRESENT" == "S" ]]; then

	#echo "PRESENT"
	sleep 2
else
	echo "NOT PRESENT"
	break 2
fi

done
