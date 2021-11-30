#!/bin/bash
#
# Example Slurm batch file for running rayleigh_benard_2d.py,
# using a Recipe 1 (Python virtual environment) Dedalus installation.
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

# Activate Python & the Dedalus virtual environment
module load cray-python
export WORK=${HOME/home/work}
source $WORK/venvs/dedalus/bin/activate

# Launch Dedalus in parallel
srun --distribution=block:block --hint=nomultithread python rayleigh_benard_2d.py
