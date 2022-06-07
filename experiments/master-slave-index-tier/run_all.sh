#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

RESULT_DIR=$BASE_DIR/results
rm -rf $RESULT_DIR
mkdir -p $RESULT_DIR

#cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2.json $BASE_DIR/machines.json
#$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog 2-1-true $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3-point-hit.json
./run_build.sh indilog 2-1-false $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3-point-miss.json

# # Machine config 2
# cp $BASE_DIR/machines_eng2-st2-seq3-ix3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix3-is3-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24-point-hit.json
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix3-is3-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24-point-miss.json

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-plot --directory=$RESULT_DIR --file=$BASE_DIR/results/throughput-vs-latency.csv --result-file=$RESULT_DIR/throughput-vs-latency.png