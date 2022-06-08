#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

APPEND_TIMES=1
READ_TIMES=1
export APPEND_TIMES=$APPEND_TIMES
export READ_TIMES=$READ_TIMES
WORKLOAD=$APPEND_TIMES-$READ_TIMES
RESULT_DIR=$BASE_DIR/results/$APPEND_TIMES-$READ_TIMES

#rm -rf $RESULT_DIR
#mkdir -p $RESULT_DIR

# Boki-Local
# cp $MACHINE_SPEC_DIR/boki/machines_eng2-st2-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf80.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf160.json

# Boki-Remote
#cp $MACHINE_SPEC_DIR/boki/machines_eng2-ei2-st2-seq3.json $BASE_DIR/machines.json
#$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
#./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
#./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf80.json
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf160.json

# Indilog-Local
# cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2.json $BASE_DIR/machines.json
#  $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-local $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf1.json
# ./run_build.sh indilog-local $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh indilog-local $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh indilog-local $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf80.json
# ./run_build.sh indilog-local $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf160.json

# Indilog-Remote
#cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2.json $BASE_DIR/machines.json
#$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
#./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf1.json
#./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf80.json
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf160.json

# Indilog-Remote-Point
# cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-remote-point $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf1.json
# ./run_build.sh indilog-remote-point $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf80.json
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf160.json

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-plot-append --file=$RESULT_DIR/throughput-vs-latency.csv --result-file=$RESULT_DIR/throughput-vs-latency-append.png
$BENCHMARK_SCRIPT generate-plot-read-local --file=$RESULT_DIR/throughput-vs-latency.csv --result-file=$RESULT_DIR/throughput-vs-latency-read-local.png
$BENCHMARK_SCRIPT generate-plot-read-remote --file=$RESULT_DIR/throughput-vs-latency.csv --result-file=$RESULT_DIR/throughput-vs-latency-read-remote.png
