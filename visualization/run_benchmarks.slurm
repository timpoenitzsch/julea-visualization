#!/bin/bash
#SBATCH --job-name=run_benchmarks
#SBATCH --output=run_benchmarks-%j.out
#SBATCH --error=run_benchmarks-%j.err
#SBATCH --time=0-24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=47
#SBATCH --mail-type=END
#SBATCH --mail-user=tim.poenitzsch@st.ovgu.de

cd /scratch/hdd/visualization-tests-poenitzsch/julea-visualization

RUNS=20

for ((i=1; i<=$RUNS; i++)); do
    . scripts/environment.sh
    
    ./scripts/setup.sh start

    cd visualization
    ./do_x_benchmarks.sh
    cd ..

    ./scripts/setup.sh stop
    
    # Nach jedem Durchlauf eine Stunde warten, außer nach dem letzten Durchlauf
    if [ $i -lt $RUNS ]; then
        sleep 3600
    fi
done
