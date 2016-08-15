#!/bin/bash

#SBATCH -p userq
#SBATCH --ntasks-per-node=1
#SBATCH --nodes=2
#SBATCH --cpus-per-task=18
#SBATCH --ntasks=2
#SBATCH --time=2:00:00
#SBATCH --job-name=userjob
#SBATCH --mem=1000
#SBATCH --gres=mbandwidth:1

hostname

sleep 20
