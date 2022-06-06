#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

WORKLOAD=$1

if [[ $WORKLOAD == empty-tag ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=100,0
    export SEQNUM_READ_PERCENTAGES=100,0,0,0,0
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
elif [[ $WORKLOAD == new-tags-always ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=100,0,0,0,0
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
else 
    exit 1
fi

export WORKLOAD=$WORKLOAD

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

RESULT_DIR=$BASE_DIR/results/$WORKLOAD
rm -rf $RESULT_DIR
mkdir -p $RESULT_DIR

#Boki-local
cp $MACHINE_SPEC_DIR/boki/machines_eng1-st1-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-plot-time-vs-memory \
    --directory=$RESULT_DIR \
    --workload=$WORKLOAD \
    --result-file=$RESULT_DIR/time-vs-memory.png
