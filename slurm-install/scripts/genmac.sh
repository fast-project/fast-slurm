#!/bin/bash

#ATOMIC ACCESS

#(
  # Wait for lock on file (fd 200) for 100 seconds
#flock -x -w 100 200
#START ATOMIC ACCESS


A=$(sed '1q;d' /cluster/slurm-install/scripts/maccurrent.file)
#echo $A
Aa=$(echo "obase=16; $((0xF$A + 0x01))" | bc | tail -c 3)
#echo $Aa


while [ $(grep " $Aa" /cluster/slurm-install/scripts/macall.file  | wc -l) -ne 0 ]
do
	Aa=$(echo "obase=16; $((0xF$Aa + 0x01))" | bc | tail -c 3)
	#echo $Aa
done


echo $Aa > /cluster/slurm-install/scripts/maccurrent.file

macid=$(echo $Aa | tail -c 3)
myvmname="vm"$(echo "obase=10; $((0x$macid))" | bc)
echo $myvmname" "$Aa >> /cluster/slurm-install/scripts/macall.file



addrss="52:54:00:86:f1:"$(echo $Aa | fold -w2   | sed ':a;N;$!ba;s/\n/:/g')


echo $addrss

#) 200>/var/lock/maccurrentfile


