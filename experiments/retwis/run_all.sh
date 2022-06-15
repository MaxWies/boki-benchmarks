#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

RESULT_DIR=$BASE_DIR/results
rm -rf $RESULT_DIR
mkdir -p \
    $RESULT_DIR \
    $RESULT_DIR/boki-local \
    $RESULT_DIR/boki-remote \
    $RESULT_DIR/indilog

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# Boki-Local
# cp $MACHINE_SPEC_DIR/boki/machines_eng4-st4-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Boki-Remote
# cp $MACHINE_SPEC_DIR/boki/machines_eng4-ei2-st4-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng4-ei2-st4-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# Indilog
cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog-no-min-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json

# Plotting
for SLOG in boki-local boki-remote indilog; do
    $BENCHMARK_SCRIPT generate-plot \
        --op-stats-csv-file=$RESULT_DIR/results/$SLOG/op-stats.csv \
        --client-csv-file=$BASE_DIR/results/$SLOG/client-results.csv \
        --result-file=$BASE_DIR/results/$SLOG/op-stats.png
done
