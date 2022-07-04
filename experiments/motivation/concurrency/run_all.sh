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

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

# Boki-Local: look at local node
cp $MACHINE_SPEC_DIR/boki/machines_eng4-st4-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki-local local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
./run_build.sh boki-local local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf2.json
./run_build.sh boki-local local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf3.json
./run_build.sh boki-local local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf4.json
./run_build.sh boki-local local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
./run_build.sh boki-local local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf12.json
./run_build.sh boki-local local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf15.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 120

# Boki-Hybrid: look at hybrid node
cp $MACHINE_SPEC_DIR/boki/machines_eng3-eh1-st4-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki-hybrid hybrid $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
./run_build.sh boki-hybrid hybrid $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf2.json
./run_build.sh boki-hybrid hybrid $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf3.json
./run_build.sh boki-hybrid hybrid $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf4.json
./run_build.sh boki-hybrid hybrid $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
./run_build.sh boki-hybrid hybrid $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf12.json
./run_build.sh boki-hybrid hybrid $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf15.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 120

# Boki-Remote: look at node that does query
cp $MACHINE_SPEC_DIR/boki/machines_eng3-ei1-st3-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki-remote local $CONTROLLER_SPEC_DIR/boki/eng3-ei1-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
./run_build.sh boki-remote local $CONTROLLER_SPEC_DIR/boki/eng3-ei1-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf2.json
./run_build.sh boki-remote local $CONTROLLER_SPEC_DIR/boki/eng3-ei1-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf3.json
./run_build.sh boki-remote local $CONTROLLER_SPEC_DIR/boki/eng3-ei1-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf4.json
./run_build.sh boki-remote local $CONTROLLER_SPEC_DIR/boki/eng3-ei1-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
./run_build.sh boki-remote local $CONTROLLER_SPEC_DIR/boki/eng3-ei1-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf12.json
./run_build.sh boki-remote local $CONTROLLER_SPEC_DIR/boki/eng3-ei1-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf15.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 120

# Boki-Hybrid: look at node that does query
cp $MACHINE_SPEC_DIR/boki/machines_eng3-eh1-st4-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki-hybrid local $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
./run_build.sh boki-hybrid local $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf2.json
./run_build.sh boki-hybrid local $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf3.json
./run_build.sh boki-hybrid local $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf4.json
./run_build.sh boki-hybrid local $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
./run_build.sh boki-hybrid local $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf12.json
./run_build.sh boki-hybrid local $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf15.json

# Benchmark collected csv file
for FILE_TYPE in "pdf" "png";
do 
    $BENCHMARK_SCRIPT generate-plot --file=$RESULT_DIR/concurrency-vs-latency.csv --slog=boki-local-local --result-file=$RESULT_DIR/concurrency-vs-latency_local-locall.$FILE_TYPE
    $BENCHMARK_SCRIPT generate-plot --file=$RESULT_DIR/concurrency-vs-latency.csv --slog=boki-hybrid-hybrid --result-file=$RESULT_DIR/concurrency-vs-latency_hybrid-hybrid.$FILE_TYPE
    $BENCHMARK_SCRIPT generate-plot --file=$RESULT_DIR/concurrency-vs-latency.csv --slog=boki-remote-local --result-file=$RESULT_DIR/concurrency-vs-latency_remote-local.$FILE_TYPE
    $BENCHMARK_SCRIPT generate-plot --file=$RESULT_DIR/concurrency-vs-latency.csv --slog=boki-hybrid-local --result-file=$RESULT_DIR/concurrency-vs-latency_hybrid-local.$FILE_TYPE
done