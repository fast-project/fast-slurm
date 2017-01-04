#!/bin/bash

slurmctld
/etc/init.d/munge start

#make sure state of configuration is in a usable state
echo "" > /cluster/slurm-install/configs/allvminfo.txt
cat /cluster/slurm-install/scripts/macall.file.bck > /cluster/slurm-install/scripts/macall.file

#./cluster/cleanallvms.sh

echo '' > /var/log/daemon.log
echo '' > /var/log/messages
echo '' > /var/log/syslog
echo '' > /var/log/syslog.all


for s in {1..4}
do
        ssh -t fast-0$s 'sudo /etc/init.d/munge start; sudo slurmd'
done

#scontrol update NodeName=fast-0[1-3]  State=UNDRAIN
#scontrol update NodeName=fast-0[1-3]  State=RESUME
