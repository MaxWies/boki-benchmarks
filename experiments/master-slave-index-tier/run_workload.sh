#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

WORKLOAD=$1
export WORKLOAD

if [[ $WORKLOAD == high-concurrency ]]; then
    CONCURRENCY=15
elif [[ $WORKLOAD == low-concurrency ]]; then
    CONCURRENCY=4
else
    exit 1
fi

RESULT_DIR=$BASE_DIR/results/$WORKLOAD
rm -rf $RESULT_DIR
mkdir -p $RESULT_DIR


$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

# Indilog
cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog 2-1-1-true $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf$CONCURRENCY-point-hit.json
./run_build.sh indilog 2-1-1-false $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf$CONCURRENCY-point-miss.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

# Boki-Remote
cp $MACHINE_SPEC_DIR/boki/machines_eng4-ei2-st4-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki-remote 1-2-0-boki $CONTROLLER_SPEC_DIR/boki/eng4-ei2-st4-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf$CONCURRENCY-point-hit.json

# Generate plot
for FILE_TYPE in "pdf";
do
    $BENCHMARK_SCRIPT generate-plot --directory=$RESULT_DIR --file=$RESULT_DIR/throughput-vs-latency.csv --result-file=$RESULT_DIR/cumulated-latency.$FILE_TYPE
done