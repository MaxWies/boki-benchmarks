#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

RESULT_DIR=$BASE_DIR/results

#rm -rf $RESULT_DIR
#mkdir -p $RESULT_DIR

# Boki-Local
# cp $MACHINE_SPEC_DIR/boki/machines_eng1-st1-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf80.json
#./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf160.json
#./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf320.json
#./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf480.json

# Boki-Full
# cp $MACHINE_SPEC_DIR/boki/machines_eng1-ef1-st2-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-full $CONTROLLER_SPEC_DIR/boki/eng1-ef1-st2-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
# ./run_build.sh boki-full $CONTROLLER_SPEC_DIR/boki/eng1-ef1-st2-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh boki-full $CONTROLLER_SPEC_DIR/boki/eng1-ef1-st2-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh boki-full $CONTROLLER_SPEC_DIR/boki/eng1-ef1-st2-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf80.json
# ./run_build.sh boki-full $CONTROLLER_SPEC_DIR/boki/eng1-ef1-st2-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf160.json

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-plot --file=$RESULT_DIR/concurrency-vs-latency.csv --slog=boki-local --result-file=$RESULT_DIR/concurrency-vs-latency.png
