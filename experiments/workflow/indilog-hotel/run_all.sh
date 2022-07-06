#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_HELPER_SCRIPT=$ROOT_DIR/scripts/benchmark_helper

RESULT_DIR=$BASE_DIR/results
rm -rf $RESULT_DIR
mkdir -p \
    $RESULT_DIR \
    $RESULT_DIR/boki \
    $RESULT_DIR/indilog \
    $RESULT_DIR/indilog-min-completion

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

# Boki-Local
cp $MACHINE_SPEC_DIR/boki/machines_eng4-st4-seq3-dy1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-dy1-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

# Indilog
cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg1-dy1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-dy1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf8.json
./run_build.sh indilog-min-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-dy1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf8.json

# Plotting
for FILE_TYPE in "pdf" "png";
do
    for SLOG in boki indilog indilog-min-completion; do
        $BENCHMARK_HELPER_SCRIPT generate-operation-statistics-plot \
            --file=$RESULT_DIR/$SLOG/operations.csv \
            --result-file=$RESULT_DIR/$SLOG/operations.$FILE_TYPE
    done
done
