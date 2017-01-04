#!/bin/bash


scp fast:{/cluster/*.sh,/etc/hosts,/etc/dhcp/dhcpd.conf} ./testcluster/
scp fast:/cluster/slurm-install/etc/*.conf ./slurm-install/etc

instal=/cluster/slurm-install/scripts
scp fast:{$instal/*.sh,$instal/macall.file.bck} ./slurm-install/scripts/

conf=/cluster/slurm-install/configs
scp fast:{$conf/clean.sh,$conf/parastation.conf,$conf/vm.xml,$conf/nodes/pin_fast-0X} ./slurm-install/configs

scp -r fast:/cluster/slurm-install/slurmsrc/src ./slurm-install/slurmsrc/
