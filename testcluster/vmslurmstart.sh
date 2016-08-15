#!/bin/bash
/etc/init.d/munge start
slurmd -vv
vmname=$(hostname)
scontrol update NodeName=$vmname  State=RESUME
