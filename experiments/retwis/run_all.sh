#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

COLLECTION_DIR=$BASE_DIR/results/collection
rm -rf $COLLECTION_DIR
mkdir -p \
    $COLLECTION_DIR \
    $COLLECTION_DIR/boki-local \
    $COLLECTION_DIR/boki-remote \
    $COLLECTION_DIR/indilog

# Boki-Local
cp $BASE_DIR/machines_eng2-st2-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

ssh -q $MANAGER_HOST -- docker stack rm boki-experiment
sleep 20

# Boki-Remote
cp $BASE_DIR/machines_eng2-ei1-st2-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei1-st2-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

ssh -q $MANAGER_HOST -- docker stack rm boki-experiment
sleep 20

# Indilog
cp $BASE_DIR/machines_eng2-st2-seq3-ix1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog indilog $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix1-is1-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json

# Plotting
for SLOG_CONFIG in boki-local boki-remote indilog; do
    $BENCHMARK_SCRIPT generate-plot \
        --op-stats-csv-file=$BASE_DIR/results/collection/$SLOG_CONFIG/op-stats.csv \
        --client-csv-file=$BASE_DIR/results/collection/$SLOG_CONFIG/client-results.csv \
        --result-file=$BASE_DIR/results/collection/$SLOG_CONFIG/op-stats.png
done
