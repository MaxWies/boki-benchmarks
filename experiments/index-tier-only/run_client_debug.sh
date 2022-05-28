#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`

SLOG=$1
SLOG_INDEX_CONFIG=$2
EXP_SPEC_FILE=$3
EXP_DIR=$4

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

# Overwrite environment with spec file
for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

BENCHMARK_DESCRIPTION="Append-${APPEND_TIMES}-and-read-${READ_TIMES}-times"

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
MANAGER_IP=`$HELPER_SCRIPT get-docker-manager-ip --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=slog-gateway`

ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
ALL_STORAGE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=storage_node`
ALL_SEQUENCER_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=sequencer_node`
ALL_INDEX_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=index_node`


# compute throughput
THROUGHPUT=`$BENCHMARK_SCRIPT compute-throughput --exp-duration=$DURATION --directory=$EXP_DIR/stats/latencies`

# merge read latencies of all engines
$BENCHMARK_SCRIPT merge-csv \
    --directory=$EXP_DIR/stats/latencies \
    --filter=read \
    --result-file=$BASE_DIR/results/collection/latencies-read_$SLOG_INDEX_CONFIG.csv

# add row to collection
$BENCHMARK_SCRIPT add-row \
    --slog=$SLOG \
    --slog-config=$SLOG_INDEX_CONFIG \
    --throughput=$THROUGHPUT \
    --is-point-hit=$IS_POINT_HIT \
    --read-latency-file=$BASE_DIR/results/collection/latencies-read_$SLOG_INDEX_CONFIG.csv \
    --result-file=$BASE_DIR/results/throughput-vs-latency.csv
