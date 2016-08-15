#!/bin/bash

echo $@ > /usr/local/slurm/logs/submitprolog.txt
#echo $@

if [ "$3" -eq "1" ] ; then
	sbatch --partition=vmq --nodes=$3 --time=$4 --mem=$5 -n $6 /usr/local/slurm/vm_start.sh $1 $2 0 >> /usr/local/slurm/logs/submitprolog.txt 2>&1
	echo "done submitting vm_start" >>  /usr/local/slurm/logs/submitprolog.txt
else
	sbatch --partition=vmq --nodes=$3 --time=$4 --mem=$5 -n $6 /usr/local/slurm/vm_wrapper.sh $1 $2 >> /usr/local/slurm/logs/submitprolog.txt 2>&1
	echo "done submitting vm_wrapper" >>  /usr/local/slurm/logs/submitprolog.txt
fi


exit 0
