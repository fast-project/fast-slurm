#!/bin/bash

#SBATCH -p userq
#SBATCH --nodes=1-1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --time=0:02:00
#SBATCH --job-name=some_job_name
#SBATCH --mem=1000
#SBATCH --gres=mbandwidth:0

hostname

sleep 1
