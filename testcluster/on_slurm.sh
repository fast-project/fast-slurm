#!/bin/bash

slurmctld -vvv
/etc/init.d/munge start


for s in {1..3}
do
        ssh -t fast-0$s 'sudo /etc/init.d/munge start; sudo slurmd -vvv'
done

#scontrol update NodeName=fast-0[1-3]  State=UNDRAIN
#scontrol update NodeName=fast-0[1-3]  State=RESUME
