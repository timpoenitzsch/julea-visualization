#!/bin/bash
#SBATCH --job-name=run_benchmark
#SBATCH --output=run_benchmark-%j.out
#SBATCH --error=run_benchmark-%j.err
#SBATCH --nodelist=ant13
#SBATCH --time=0-0:40:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mail-type=END
#SBATCH --mail-user=tim.poenitzsch@st.ovgu.de

echo "starting benchmark"
echo "cd /scratch/hdd/visualization-tests-poenitzsch/julea-visualization"
cd /scratch/hdd/visualization-tests-poenitzsch/julea-visualization
echo "starting benchmark $i"
echo ". scripts/environment.sh"
. scripts/environment.sh

echo "./scripts/setup.sh clean-local"
./scripts/setup.sh clean-local

echo "./scripts/setup.sh start-local"
./scripts/setup.sh start-local

echo "cd visualization"
cd visualization
echo "./do_x_benchmarks.sh"
./do_x_benchmarks.sh 1 0
echo "cd .."
cd ..

echo "./scripts/setup.sh stop-local"
./scripts/setup.sh stop-local

echo "./scripts/setup.sh clean-local"
./scripts/setup.sh clean-local

echo "end of benchmark"
