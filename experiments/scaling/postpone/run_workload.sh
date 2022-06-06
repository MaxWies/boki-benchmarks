#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

WORKLOAD=$1
export WORKLOAD

if [[ $WORKLOAD == empty-tag ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=100,0
    export SEQNUM_READ_PERCENTAGES=100,0,0,0,0
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,0,0,0,0,100
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == one-tag-only ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=0,0,0,0,100
    export TAG_APPEND_PERCENTAGES=0,0,100
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
    export SHARED_TAGS_CAPACITY=1
elif [[ $WORKLOAD == new-tags-always ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=0,0,0,0,100
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
    export SHARED_TAGS_CAPACITY=20
else 
    exit 1
fi

RESULT_DIR=$BASE_DIR/results/$WORKLOAD
# rm -rf $RESULT_DIR
# mkdir -p $RESULT_DIR

# # Boki skewed
# cp $MACHINE_SPEC_DIR/boki/machines_eng3-st3-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-skewed $CONTROLLER_SPEC_DIR/boki/eng3-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf3.json

# # Indilog postpone caching
# cp $MACHINE_SPEC_DIR/indilog/machines_eng3-st3-seq3-ix1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-postpone-caching $CONTROLLER_SPEC_DIR/indilog/eng3-st3-seq3-ix1-is1-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3.json

# # Indilog postpone registering
# cp $MACHINE_SPEC_DIR/indilog/machines_eng3-st3-seq3-ix1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-postpone-registering $CONTROLLER_SPEC_DIR/indilog/eng3-st3-seq3-ix1-is1-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf3.json

# Benchmark collected csv file
for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $BASE_DIR/specs/exp-cf3.json); do
    export $s
done

$BENCHMARK_SCRIPT generate-plot-boki-vs-indilog \
    --file=$RESULT_DIR/time-vs-throughput-latency.csv \
    --relative-scale-ts=$RELATIVE_SCALE_TS \
    --engines-before=1 \
    --engines-after=3 \
    --workload=$WORKLOAD \
    --result-file=$RESULT_DIR/boki-vs-indilog_scaling-time-vs-latency-throughput.png

$BENCHMARK_SCRIPT generate-plot-postpone-caching-vs-registration \
    --file=$RESULT_DIR/time-vs-throughput-latency.csv \
    --relative-scale-ts=$RELATIVE_SCALE_TS \
    --result-file=$RESULT_DIR/caching-vs-registration_scaling-time-vs-latency-throughput.png
