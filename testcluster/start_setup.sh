#!/bin/bash

#make sure ipforwarding is working on login node
#for login node
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i net0 -o internet0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE




mqtt=/cluster/MQTT/dummy-scheduler/fast-mqtt


#ifloginnode do later
#start mosquitto
#/usr/sbin/mosquitto -c /etc/mosquitto/mosquitto.conf
usr/local/sbin/mosquitto -c /etc/mosquitto/mosquitto.conf

#start mqtt slurm service
$mqtt --listen &> /dev/null &


#start agents
$mqtt --initAgents

#libvirt
/cluster/libvirt-1.3.3/bin/set_environment.sh -d

sudo service libvirt-bin start
sudo -i
sudo  /cluster/libvirt-1.3.3/bin/set_environment.sh -d
sudo /cluster/libvirt-1.3.3/sbin/virtlogd -v -f /cluster/libvirt-1.3.3/etc/libvirt/virtlogconf
sudo /cluster/libvirt-1.3.3/sbin/libvirtd -l -f /cluster/libvirt-1.3.3/etc/libvirt/libvirtd.conf


#IB
mst start
/etc/init.d/opensmd start


#start slurm
./on_slurm.sh


#mig framework
/cluster/fast/migration-framework/migfra  --config /cluster/fast/migration-framework/migfra.conf
