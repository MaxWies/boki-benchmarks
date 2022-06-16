#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

RESULT_DIR=$BASE_DIR/results
# rm -rf $RESULT_DIR
# mkdir -p $RESULT_DIR

# this benchmark uses range queries only

# baseline two shards with single replication

# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-m1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog 2-1-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-m1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# # increase the shards

# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix4-m1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog 4-1-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix4-m1-is4-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix6-m1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog 6-1-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix6-m1-is6-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# increase the replication

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix4-m1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog 2-2-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix4-m1-is2-ir2-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix4-m2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog 2-2-2-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix4-m2-is2-ir2-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix6-m1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog 2-3-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix6-m1-is2-ir3-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-m1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog 2-1-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-m1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf4.json

# # increase the shards

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix4-m1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog 4-1-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix4-m1-is4-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf4.json


cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix4-m1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog 2-2-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix4-m1-is2-ir2-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf4.json

# # Benchmark collected csv file
# for FILE_TYPE in "png" "pdf";
# do
#     $BENCHMARK_SCRIPT generate-plot --directory=$RESULT_DIR --file=$BASE_DIR/results/throughput-vs-latency.csv --result-file=$RESULT_DIR/cumulated-latency.$FILE_TYPE
# done