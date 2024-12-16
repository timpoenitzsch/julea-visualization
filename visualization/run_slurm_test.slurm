#!/bin/bash
#SBATCH --job-name=run_benchmarks
#SBATCH --output=run_benchmarks-%j.out
#SBATCH --error=run_benchmarks-%j.err
#SBATCH --time=0-0:40:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mail-type=END
#SBATCH --mail-user=tim.poenitzsch@st.ovgu.de

echo "test"