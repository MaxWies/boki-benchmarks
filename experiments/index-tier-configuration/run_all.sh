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

# this benchmark uses range queries only

cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2-m1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog 1-2-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-m1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3.json

cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2-m1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog 2-1-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-m1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3.json

cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix4-m1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog 2-2-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix4-m1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3.json

cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix4-m2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog 2-2-2-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix4-m2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3.json

# Benchmark collected csv file
for FILE_TYPE in "png" "pdf";
do
    $BENCHMARK_SCRIPT generate-plot --directory=$RESULT_DIR --file=$BASE_DIR/results/throughput-vs-latency.csv --result-file=$RESULT_DIR/cumulated-latency.$FILE_TYPE
done