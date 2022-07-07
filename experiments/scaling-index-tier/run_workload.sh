#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

WORKLOAD=$1
export WORKLOAD

if [[ $WORKLOAD == high-concurrency ]]; then
    CONCURRENCY=15
elif [[ $WORKLOAD == low-concurrency ]]; then
    CONCURRENCY=4
else
    exit 1
fi

RESULT_DIR=$BASE_DIR/results/$WORKLOAD
rm -rf $RESULT_DIR
mkdir -p $RESULT_DIR


$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog-aggregator 2-1-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf$CONCURRENCY.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog-aggregator 2-1-2-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf$CONCURRENCY.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix6-agg1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog-aggregator 6-1-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix6-agg1-is6-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf$CONCURRENCY.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix6-agg2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog-aggregator 6-1-2-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix6-agg2-is6-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf$CONCURRENCY.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog-master-slave 2-1-0-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf$CONCURRENCY.json
