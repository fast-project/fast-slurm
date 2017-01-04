#!/bin/bash


for s in {1..4}
do
	ssh -t fast-0$s 'sudo pkill migfra'
	ssh -t fast-0$s 'sudo /cluster/node_setup.sh'

done

