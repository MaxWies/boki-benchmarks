#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

WORKLOAD=$1

if [[ $WORKLOAD == empty-tag ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=100,0
    export SEQNUM_READ_PERCENTAGES=100,0,0,0,0
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
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == mix ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=50,50
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=33,34,33
    export TAG_READ_PERCENTAGES=0,20,20,20,20,20
    export SHARED_TAGS_CAPACITY=20
else 
    exit 1
fi

export WORKLOAD=$WORKLOAD

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

RESULT_DIR=$BASE_DIR/results/$WORKLOAD
# rm -rf $RESULT_DIR
# mkdir -p $RESULT_DIR

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# Boki-local
# cp $MACHINE_SPEC_DIR/boki/machines_eng4-st4-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf3.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Boki-remote
# cp $MACHINE_SPEC_DIR/boki/machines_eng2-ei2-st2-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf3.json


# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# Boki-hybrid (index replication is 1)
#cp $MACHINE_SPEC_DIR/boki/machines_eng3-eh1-st4-seq3.json $BASE_DIR/machines.json
#$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
#./run_build.sh boki-hybrid $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf3.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

# Indilog-local
cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog-local $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3.json 

# # Indilog-remote
# cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3.json 

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-plot-time-vs-throughput --file=$RESULT_DIR/time-latency-index-memory.csv --workload=$WORKLOAD --result-file=$RESULT_DIR/time-vs-throughput.png
$BENCHMARK_SCRIPT generate-plot-time-vs-latency-append --file=$RESULT_DIR/time-latency-index-memory.csv --workload=$WORKLOAD --result-file=$RESULT_DIR/time-vs-latency-append.png
$BENCHMARK_SCRIPT generate-plot-time-vs-latency-read --file=$RESULT_DIR/time-latency-index-memory.csv --workload=$WORKLOAD --result-file=$RESULT_DIR/time-vs-latency-read.png
# $BENCHMARK_SCRIPT generate-plot-time-vs-latency-throughput --directory=$RESULT_DIR --workload=$WORKLOAD --result-file=$RESULT_DIR/time-vs-latency-throughput.png
$BENCHMARK_SCRIPT generate-plot-time-vs-cpu-memory --directory=$RESULT_DIR --workload=$WORKLOAD --result-file=$RESULT_DIR/time-vs-cpu-memory.png
