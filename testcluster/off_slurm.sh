#!/bin/bash

pkill slurmctld

for s in {1..4}
do
	ssh -t fast-0$s 'sudo pkill slurmd'
done
