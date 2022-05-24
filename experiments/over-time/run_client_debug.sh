#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`



HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks

export BENCHMARK_TYPE=throughput-vs-latency
export COLLECT_CONTAINER_LOGS=false
export RECORD_LENGTH=1024
export DURATION=60
export APPEND_TIMES=1
export READ_TIMES=1

# Set the workload semantics
export OPERATION_SEMANTICS_PERCENTAGES=0,100
export TAG_APPEND_PERCENTAGES=100,0,0
export TAG_READ_PERCENTAGES=100,0,0

# Overwrite environment with spec file
for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

ENGINE_NODES=`$HELPER_SCRIPT get-num-active-service-replicas --base-dir=$BASE_DIR --service=slog-engine`
STORAGE_NODES=$(wc -w <<< $ALL_STORAGE_HOSTS)
SEQUENCER_NODES=$(wc -w <<< $ALL_SEQUENCER_HOSTS)
INDEX_NODES=$(wc -w <<< $ALL_INDEX_HOSTS)

EXP_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`

EXP_ENGINE_START_TS=$(ssh -q $EXP_ENGINE_HOST -- date +%s)

SLOG=boki
SLOG_CONFIGURATION=$SLOG-eng$ENGINE_NODES-st$STORAGE_NODES-seq$SEQUENCER_NODES-ix$INDEX_NODES-cf$CONCURRENCY_WORKER

# get resource usage from engine
# scp -q $EXP_ENGINE_HOST:/tmp/resource_usage_engine.csv $BASE_DIR/results/collection/boki/time-cpu-memory.csv
# $BENCHMARK_SCRIPT add-slog-info \
#     --file=$BASE_DIR/results/collection/boki/time-cpu-memory.csv \
#     --slog=$SLOG \
#     --slog-config=$SLOG_CONFIGURATION

# # $BENCHMARK_SCRIPT update-column-by-division \
# #     --file=$BASE_DIR/results/collection/$SLOG/time-cpu-memor

# # make time in csv data relative and store data in main collection folder
# $BENCHMARK_SCRIPT make-time-relative \
#     --directory=$BASE_DIR/results/collection/boki \
#     --reference-ts=1000000000 \
#     --result-directory=$BASE_DIR/results/collection



# convert index-memory from B to MiB
$BENCHMARK_SCRIPT update-column-by-division \
    --file=$BASE_DIR/results/collection/$SLOG/time-latency-index-memory.csv \
    --column=index_memory \
    --divisor=1048576 \
    --round-decimals=4