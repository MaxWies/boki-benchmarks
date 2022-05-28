#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`

COLLECTION_DIR=$BASE_DIR/results/collection
rm -rf $COLLECTION_DIR
mkdir -p $COLLECTION_DIR $COLLECTION_DIR/boki $COLLECTION_DIR/indilog

# Boki
cp $BASE_DIR/machines_eng1-st1-seq3-ix2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ix2-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

# cp $BASE_DIR/machines_eng2-st1-seq3-ix2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki $CONTROLLER_SPEC_DIR/boki/eng2-st1-seq3-ix2-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

# cp $BASE_DIR/machines_eng4-st1-seq3-ix2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki $CONTROLLER_SPEC_DIR/boki/eng4-st1-seq3-ix2-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

# Indilog -> we scale up to 4 compute nodes
cp $BASE_DIR/machines_eng1-st1-seq3-ix2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng1-st1-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-latency-plot --directory=$COLLECTION_DIR --result-file=$COLLECTION_DIR/latency.png
$BENCHMARK_SCRIPT generate-boki-index-engine-latency-plot --directory=$COLLECTION_DIR --result-file=$COLLECTION_DIR/index-engine-latency.png