#!/bin/bash



for s in {1..3}
do
	ssh fast-0${s} 'sudo pkill migfra; sudo /cluster/fast/migration-framework/migfra --config /cluster/fast/migration-framework/migfra.conf &'
done
ls
#scontrol update NodeName=fast-0[1-3]  State=UNDRAIN
#scontrol update NodeName=fast-0[1-3]  State=RESUME
