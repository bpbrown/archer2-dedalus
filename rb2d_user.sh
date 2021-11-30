#!/bin/bash
#
# Example Slurm batch file for running rayleigh_benard_2d.py,
# using a Recipe 2 (i.e. user-level) Dedalus installation.
#
#SBATCH --job-name=rb2d
#SBATCH --nodes=1
#SBATCH --tasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=0:05:00
#
#SBATCH --account=[FILL THIS IN]
#SBATCH --partition=standard
#SBATCH --qos=standard

# Activate Python and tell it where to find local packages
module load cray-python
export WORK=${HOME/home/work}
export PYTHONUSERBASE=$WORK/.local

# Launch Dedalus in parallel
srun --distribution=block:block --hint=nomultithread python rayleigh_benard_2d.py
