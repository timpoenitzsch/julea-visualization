#!/bin/bash
#SBATCH --job-name=run_benchmarks
#SBATCH --output=run_benchmarks-%j.out
#SBATCH --error=run_benchmarks-%j.err
#SBATCH --time=0-24:00:00
#SBATCH --ntasks=1
#SBATCH --nodelist=ant13
#SBATCH --cpus-per-task=24
#SBATCH --mail-type=END
#SBATCH --mail-user=tim.poenitzsch@st.ovgu.de

echo "starting benchmarks"
echo ""
cd /scratch/hdd/visualization-tests-poenitzsch/julea-visualization

RUNS=20

for ((i=1; i<=$RUNS; i++)); do
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
    ./do_x_benchmarks.sh
    echo "cd .."
    cd ..

    echo "./scripts/setup.sh stop-local"
    ./scripts/setup.sh stop-local

    
    echo "./scripts/setup.sh clean-local"
    ./scripts/setup.sh clean-local
    
    if [ $i -lt $RUNS ]; then
        sleep 3600
    fi
done
echo "end of benchmarks"
