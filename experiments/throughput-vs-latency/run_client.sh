#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks

export BENCHMARK_TYPE=throughput-vs-latency
export COLLECT_CONTAINER_LOGS=false
export RECORD_LENGTH=1024
export DURATION=30

# Set the workload semantics
export OPERATION_SEMANTICS_PERCENTAGES=50,50
export SEQNUM_READ_PERCENTAGES=30,30,20,10,10
export TAG_APPEND_PERCENTAGES=50,50
export TAG_READ_PERCENTAGES=40,30,30

# Overwrite environment with spec file
for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

BENCHMARK_DESCRIPTION="Append-${APPEND_TIMES}-and-read-${READ_TIMES}-times"

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=slog-gateway`

ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
ALL_STORAGE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=storage_node`
ALL_SEQUENCER_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=sequencer_node`
ALL_INDEX_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=index_node`

ENGINE_NODES=`$HELPER_SCRIPT get-num-active-service-replicas --base-dir=$BASE_DIR --service=slog-engine`
STORAGE_NODES=$(wc -w <<< $ALL_STORAGE_HOSTS)
SEQUENCER_NODES=$(wc -w <<< $ALL_SEQUENCER_HOSTS)
INDEX_NODES=$(wc -w <<< $ALL_INDEX_HOSTS)

for HOST in $ALL_ENGINE_HOSTS; do
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/slog/output/benchmark/$BENCHMARK_TYPE
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/slog/output/benchmark/$BENCHMARK_TYPE
done

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/indilog-microbench:latest \
    cp /microbench-bin/benchmark /tmp/benchmark

ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --benchmark_type=$BENCHMARK_TYPE \
    --duration=$DURATION \
    --record_length=$RECORD_LENGTH \
    --append_times=$APPEND_TIMES \
    --read_times=$READ_TIMES \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --operation_semantics_percentages=$OPERATION_SEMANTICS_PERCENTAGES \
    --seqnum_read_percentages=$SEQNUM_READ_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    >$EXP_DIR/results.log

sleep 10

if [ $COLLECT_CONTAINER_LOGS == 'true' ]; then
    $HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
fi

$SLOG_CONFIGURATION=$SLOG-$ENGINE_NODES-$STORAGE_NODES-$SEQUENCER_NODES-$INDEX_NODES-$CONCURRENCY_WORKER

mkdir -p $EXP_DIR/stats/latencies
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/latencies-* $EXP_DIR/stats/latencies
done

$BENCHMARK_SCRIPT merge-csv \
    --directory=$EXP_DIR/stats/latencies \
    --filter=append \
    --result-file=$BASE_DIR/results/collection/$SLOG/latencies-append-$SLOG_CONFIGURATION.csv

$BENCHMARK_SCRIPT merge-csv \
    --directory=$EXP_DIR/stats/latencies \
    --filter=read \
    --result-file=$BASE_DIR/results/collection/$SLOG/latencies-read-$SLOG_CONFIGURATION.csv

$BENCHMARK_SCRIPT add-throughput-latency-row \
    --directory=$BASE_DIR/results/collection/$SLOG \
    --slog-config=$SLOG_CONFIGURATION \
    --exp-duration=$DURATION \
    --result-file=$BASE_DIR/results/collection/throughput-vs-latency.csv

