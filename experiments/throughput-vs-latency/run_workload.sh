#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks

APPEND_TIMES=$1
READ_TIMES=$2
export APPEND_TIMES=$APPEND_TIMES
export READ_TIMES=$READ_TIMES
WORKLOAD=$APPEND_TIMES-$READ_TIMES

END_RESULT_DIR=$BASE_DIR/results/workload-$WORKLOAD
mkdir -p $END_RESULT_DIR

COLLECTION_DIR=$BASE_DIR/results/collection

rm -rf $COLLECTION_DIR/indilog
mkdir -p $COLLECTION_DIR/indilog
rm -rf $COLLECTION_DIR/boki
mkdir -p $COLLECTION_DIR/boki

# Indilog
cp $BASE_DIR/machines_eng1-st1-seq3-ix1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng1-st1-seq3-ix1-is1-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf1.json 

# Boki
#cp $BASE_DIR/machines_eng1-st1-seq3.json $BASE_DIR/machines.json
#$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
#./run_build.sh boki $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json

# Benchmark collected csv file
$BENCHMARK_SCRIPT throughput-vs-latency-plot --file=$COLLECTION_DIR/throughput-vs-latency.csv --result-file=$END_RESULT_DIR/throughput-vs-latency.png