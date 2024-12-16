#!/bin/bash
#SBATCH --job-name=run_slurm_test
#SBATCH --output=run_slurm_test-%j.out
#SBATCH --error=run_slurm_test-%j.err
#SBATCH --nodelist=ant13
#SBATCH --time=0-0:40:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mail-type=END
#SBATCH --mail-user=tim.poenitzsch@st.ovgu.de

echo "test"