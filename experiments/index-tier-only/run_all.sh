#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

COLLECTION_DIR=$BASE_DIR/results/collection
rm -rf $COLLECTION_DIR
mkdir -p $COLLECTION_DIR $COLLECTION_DIR/indilog

# Machine config 1
# cp $BASE_DIR/machines_eng2-st2-seq3-ix2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog 2-2-true $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24-point-hit.json
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24-point-miss.json

# # Machine config 2
# cp $BASE_DIR/machines_eng2-st2-seq3-ix3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix3-is3-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24-point-hit.json
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix3-is3-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24-point-miss.json

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-plot --directory=$COLLECTION_DIR --file=$BASE_DIR/results/throughput-vs-latency.csv --result-file=$COLLECTION_DIR/throughput-vs-latency.png