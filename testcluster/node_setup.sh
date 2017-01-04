#!/bin/bash

nodename=$(hostname)

slurmd

pkill virtlogd
pkill libvirtd
killall -9 libvirtd
rm -f /var/run/libvirtd.pid

sleep 2

#libvirt
/cluster/libvirt-1.3.3/bin/set_environment.sh -d

#IB
mst start

#migfra
/cluster/fast/migration-framework/migfra -d --config /cluster/fast/migration-framework/migfra.conf


#agents
echo "Starting agent"
#pkill mmbwmon
#cd /cluster/fast/mmbwmon
#rm $nodename-mmbwmon.out
#nohup ./mmbwmon --server fast-login --numa 2 --threads 16 --smt 1 > $nodename-mmbwmon.out 2>&1 &

#use intel PCM style Agents instead
#rm /cluster/slurm-install/configs/KPIs/logs/log*
pkill profiler.sh
sleep 2
nohup /cluster/slurm-install/scripts/profiler.sh  > /cluster/slurm-install/configs/KPIs/logs/log_$nodename.out 2>&1 &
