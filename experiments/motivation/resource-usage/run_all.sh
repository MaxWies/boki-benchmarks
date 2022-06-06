#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

RESULT_DIR=$BASE_DIR/results
rm -rf $RESULT_DIR
mkdir -p $RESULT_DIR

#Boki-local
#cp $MACHINE_SPEC_DIR/boki/machines_eng1-st1-seq3.json $BASE_DIR/machines.json
#$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf2.json
./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf4.json
./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf12.json
./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf16.json


# Benchmark collected csv file

for i in "engine" "storage";
do
    set -- $i
    COMPONENT=$1
    echo $COMPONENT
    $BENCHMARK_SCRIPT generate-plot-concurrency-vs-cpu \
        --file=$RESULT_DIR/concurrency-cpu-bandwidth.csv \
        --component=$COMPONENT \
        --result-file=$RESULT_DIR/$COMPONENT-concurrency-vs-cpu.png
    $BENCHMARK_SCRIPT generate-plot-concurrency-vs-bandwidth \
        --file=$RESULT_DIR/concurrency-cpu-bandwidth.csv \
        --component=$COMPONENT \
        --result-file=$RESULT_DIR/$COMPONENT-concurrency-vs-bandwidth.png
done
