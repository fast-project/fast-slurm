#!/bin/bash
rm -r [0-9][0-9][0-9]
printf "" > allvminfo.txt
rm nodes/pin_fast-0[0-9]_[0-9]*


for i in {1..4}
do
	cp nodes/pin_fast-0X nodes/pin_fast-0$i
        ssh  fast-0$i 'sudo /cluster/node_setup.sh'
done

/cluster/cleanallvms.sh
