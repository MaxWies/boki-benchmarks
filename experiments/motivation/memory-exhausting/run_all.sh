#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

#./run_workload.sh empty-tag
#./run_workload.sh new-tags-always

BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks
RESULT_DIR=$BASE_DIR/results

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-plot-all-time-vs-memory \
    --directories=$RESULT_DIR/empty-tag,$RESULT_DIR/new-tags-always \
    --result-file=$RESULT_DIR/time-vs-memory.pdf