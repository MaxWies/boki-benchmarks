#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks

export BENCHMARK_TYPE=throughput-vs-latency
export COLLECT_CONTAINER_LOGS=false
export RECORD_LENGTH=1024
export DURATION=300
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

BENCHMARK_DESCRIPTION="Append-${APPEND_TIMES}-and-read-${READ_TIMES}-times"

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
MANAGER_IP=`$HELPER_SCRIPT get-docker-manager-ip --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=slog-gateway`

ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
ALL_STORAGE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=storage_node`
ALL_SEQUENCER_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=sequencer_node`
ALL_INDEX_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=index_node`

EXP_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`

ENGINE_NODES=$(wc -w <<< $ALL_ENGINE_HOSTS)
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

# run warmup
ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=warmup-system \
    --benchmark_type=warmup \
    >$EXP_DIR/results.log

# get timestamp on exp engine
EXP_ENGINE_START_TS=$(ssh -q $EXP_ENGINE_HOST -- date +%s)

# activiate resource usage script on engine running in background
scp -q $ROOT_DIR/scripts/resource_usage $ROOT_DIR/scripts/resource_usage.sh $EXP_ENGINE_HOST:/tmp
ssh -q -f $EXP_ENGINE_HOST -- "nohup /tmp/resource_usage monitor-resource-usage-by-name \
    --batches=15 \
    --sample-rate=1 \
    --samples=20 \
    --process-name=engine \
    > /dev/null 2>&1"

# activiate statistic thread on engine
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start \
    >/dev/null

# run experiment
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
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    >$EXP_DIR/results.log

sleep 10

SLOG_CONFIGURATION=$SLOG-eng$ENGINE_NODES-st$STORAGE_NODES-seq$SEQUENCER_NODES-ix$INDEX_NODES-cf$CONCURRENCY_WORKER

# get latency and index memory records from engine
mkdir -p $EXP_DIR/stats
scp -r -q $EXP_ENGINE_HOST:/mnt/inmem/slog/stats/latencies-*-*.csv $EXP_DIR/stats
scp -r -q $EXP_ENGINE_HOST:/mnt/inmem/slog/stats/index-memory-*-*.csv $EXP_DIR/stats

for file in $EXP_DIR/stats/latencies-append-*-*.csv; do
    $BENCHMARK_SCRIPT add-time-latency-index-memory-row \
    --directory=$EXP_DIR/stats \
    --file=$file \
    --slog=$SLOG \
    --slog-config=$SLOG_CONFIGURATION \
    --interval=$ENGINE_STAT_THREAD_INTERVAL \
    --result-file=$BASE_DIR/results/collection/$SLOG/time-latency-index-memory.csv
done

# convert index-memory from B to MiB
$BENCHMARK_SCRIPT update-column-by-division \
    --file=$BASE_DIR/results/collection/$SLOG/time-latency-index-memory.csv \
    --column=index_memory \
    --divisor=1048576 \
    --round-decimals=4

# get resource usage from engine
scp -q $EXP_ENGINE_HOST:/tmp/resource_usage_engine.csv $BASE_DIR/results/collection/$SLOG/time-cpu-memory.csv
$BENCHMARK_SCRIPT add-slog-info \
    --file=$BASE_DIR/results/collection/$SLOG/time-cpu-memory.csv \
    --slog=$SLOG \
    --slog-config=$SLOG_CONFIGURATION

# make time in csv data relative and finally store data in main collection folder
$BENCHMARK_SCRIPT make-time-relative \
    --directory=$BASE_DIR/results/collection/$SLOG \
    --reference-ts=$EXP_ENGINE_START_TS \
    --result-directory=$BASE_DIR/results/collection

if [ $COLLECT_CONTAINER_LOGS == 'true' ]; then
    $HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
fi

