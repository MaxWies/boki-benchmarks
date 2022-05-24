#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks

COLLECTION_DIR=$BASE_DIR/results/collection
# rm -rf $COLLECTION_DIR
# mkdir -p $COLLECTION_DIR $COLLECTION_DIR/boki $COLLECTION_DIR/indilog

# # # Boki
# cp $BASE_DIR/machines_eng1-st1-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# sleep 5

# # Indilog
rm -rf $COLLECTION_DIR/indilog
mkdir -p $COLLECTION_DIR/indilog
cp $BASE_DIR/machines_eng1-st1-seq3-ix1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng1-st1-seq3-ix1-is1-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json 

# Benchmark collected csv file
$BENCHMARK_SCRIPT time-vs-all-plot --directory=$COLLECTION_DIR --result-file=$COLLECTION_DIR/time-vs-all.png