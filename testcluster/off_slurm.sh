#!/bin/bash

pkill slurmctld

for s in {1..3}
do
	ssh -t fast-0$s 'sudo pkill slurmd'
done
