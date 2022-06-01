#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

WORKLOAD=$1

if [[ $WORKLOAD == empty-tag ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=100,0
    export SEQNUM_READ_PERCENTAGES=0,0,0,0,100
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,0,0,0,0,100
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == one-tag-only ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=0,0,0,0,100
    export TAG_APPEND_PERCENTAGES=0,0,100
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
    export SHARED_TAGS_CAPACITY=1
elif [[ $WORKLOAD == new-tags-always ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=0,0,0,0,100
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,0,0,0,0,100
    export SHARED_TAGS_CAPACITY=20
else 
    exit 1
fi

export WORKLOAD=$WORKLOAD

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

RESULT_DIR=$BASE_DIR/results/$WORKLOAD
mkdir -p $RESULT_DIR

# Boki-local
cp $MACHINE_SPEC_DIR/boki/machines_eng2-st2-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# # Boki-remote
# cp $MACHINE_SPEC_DIR/boki/machines_eng2-ei2-st2-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# Boki-full
# cp $MACHINE_SPEC_DIR/boki/machines_eng1-ef1-st1-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-full $CONTROLLER_SPEC_DIR/boki/eng3-ei1-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# Indilog-local
cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog-local $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json 

# # Indilog-remote
# cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json 

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-plot-time-vs-latency-throughput --directory=$RESULT_DIR --result-file=$RESULT_DIR/time-vs-latency-throughput.png
$BENCHMARK_SCRIPT generate-plot-time-vs-cpu-memory --directory=$RESULT_DIR --result-file=$RESULT_DIR/time-vs-cpu-memory.png
