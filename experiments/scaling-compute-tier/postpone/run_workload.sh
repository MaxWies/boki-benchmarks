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
    export APPEND_TIMES=1
    export READ_TIMES=1
    export OPERATION_SEMANTICS_PERCENTAGES=100,0
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,0,0,0,0,100
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == one-tag-only ]]; then
    export APPEND_TIMES=1
    export READ_TIMES=1
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=0,0,0,0,100
    export TAG_APPEND_PERCENTAGES=0,0,100
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
    export SHARED_TAGS_CAPACITY=1
elif [[ $WORKLOAD == new-tags-always ]]; then
    export APPEND_TIMES=1
    export READ_TIMES=1
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=0,0,0,0,100
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == mix ]]; then
    export APPEND_TIMES=1
    export READ_TIMES=1
    export OPERATION_SEMANTICS_PERCENTAGES=50,50
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=33,34,33
    export TAG_READ_PERCENTAGES=0,20,20,20,20,20
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == mix-test ]]; then
    export APPEND_TIMES=1
    export READ_TIMES=1
    export OPERATION_SEMANTICS_PERCENTAGES=50,50
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=33,34,33
    export TAG_READ_PERCENTAGES=0,20,20,20,20,20
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == against-us ]]; then
    export APPEND_TIMES=1
    export READ_TIMES=1
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,20,0,0,80,0
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == against-us-read-heavy ]]; then
    export APPEND_TIMES=1
    export READ_TIMES=19
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,20,0,0,80,0
    export SHARED_TAGS_CAPACITY=20
else
    exit 1
fi

RESULT_DIR=$BASE_DIR/results/$WORKLOAD
# rm -rf $RESULT_DIR
# mkdir -p $RESULT_DIR

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Boki (hybrid because index replication factor is 1)
# cp $MACHINE_SPEC_DIR/boki/machines_eng3-eh1-st4-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-hybrid $CONTROLLER_SPEC_DIR/boki/eng3-eh1-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf15.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Indilog postpone caching
# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-postpone-caching $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Indilog postpone registration
# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-postpone-registration $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# Benchmark collected csv file
for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $BASE_DIR/specs/exp-cf15.json); do
    export $s
done

for FILE_TYPE in "pdf" "png";
do
    $BENCHMARK_SCRIPT generate-plot-postpone-caching-vs-postpone-registration-throughput \
        --file=$RESULT_DIR/time-vs-throughput-latency.csv \
        --relative-scale-ts=$RELATIVE_SCALE_TS \
        --result-file=$RESULT_DIR/caching-vs-registration_scaling-time-vs-throughput.$FILE_TYPE
    
    $BENCHMARK_SCRIPT generate-plot-postpone-caching-vs-postpone-registration-old-node-throughput \
        --file=$RESULT_DIR/time-vs-engine-type-latency.csv \
        --relative-scale-ts=$RELATIVE_SCALE_TS \
        --result-file=$RESULT_DIR/caching-vs-registration_scaling-old-node-time-vs-throughput.$FILE_TYPE

    # $BENCHMARK_SCRIPT generate-plot-boki-vs-indilog-throughput \
    #     --file=$RESULT_DIR/time-vs-throughput-latency.csv \
    #     --relative-scale-ts=$RELATIVE_SCALE_TS \
    #     --engines-before=1 \
    #     --engines-after=4 \
    #     --workload=$WORKLOAD \
    #     --result-file=$RESULT_DIR/boki-vs-indilog_scaling-time-vs-throughput.$FILE_TYPE

    # $BENCHMARK_SCRIPT generate-plot-boki-vs-indilog-append-latency \
    #     --file=$RESULT_DIR/time-vs-engine-type-latency.csv \
    #     --relative-scale-ts=$RELATIVE_SCALE_TS \
    #     --engines-before=1 \
    #     --engines-after=4 \
    #     --workload=$WORKLOAD \
    #     --result-file=$RESULT_DIR/boki-vs-indilog_scaling-time-vs-append-latency.$FILE_TYPE

    # $BENCHMARK_SCRIPT generate-plot-boki-vs-indilog-read-latency \
    #     --file=$RESULT_DIR/time-vs-engine-type-latency.csv \
    #     --relative-scale-ts=$RELATIVE_SCALE_TS \
    #     --engines-before=1 \
    #     --engines-after=4 \
    #     --workload=$WORKLOAD \
    #     --result-file=$RESULT_DIR/boki-vs-indilog_scaling-time-vs-read-latency.$FILE_TYPE
done