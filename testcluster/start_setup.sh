#!/bin/bash

#make sure ipforwarding is working on login node
#for login node
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i net0 -o internet0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE




mqtt=/cluster/MQTT/dummy-scheduler/fast-mqtt

#ifloginnode do later
#start mosquitto
mosquitto -c /etc/mosquitto/mosquitto.conf

#start mqtt slurm service
#$mqtt --listen &> /dev/null &



#IB
mst start
/etc/init.d/opensmd start



#start slurm
./off_slurm.sh
./on_slurm.sh


#Node setup, contains migfra, MST, IB, etc
for s in {1..4}
do
        ssh  fast-0$s 'sudo /cluster/node_setup.sh &'

done


#/cluster/fast/migration-framework/migfra  --config /cluster/fast/migration-framework/migfra.conf
#libvirt
#/cluster/libvirt-1.3.3/bin/set_environment.sh -d
