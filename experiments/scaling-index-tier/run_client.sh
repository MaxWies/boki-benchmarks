#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`

SLOG=$1
INDEX_TIER_CONFIG=$2
EXP_SPEC_FILE=$3
EXP_DIR=$4

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks
BENCHMARK_ROOT_SCRIPT=$ROOT_DIR/scripts/benchmark_helper

export APPEND_TIMES=1
export READ_TIMES=19
export RECORD_LENGTH=1024
export ENGINE_STAT_THREAD_INTERVAL=10
export DURATION=60

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
ENGINE_NODES=$(wc -w <<< $ALL_ENGINE_HOSTS)

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

# activiate statistic thread on engines
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL \
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
    --engine_nodes=$ENGINE_NODES \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --concurrency_operation=$CONCURRENCY_OPERATION \
    --operation_semantics_percentages=$OPERATION_SEMANTICS_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    >$EXP_DIR/results.log

sleep $((ENGINE_STAT_THREAD_INTERVAL+5))

# get complete latency files from engines
mkdir -p $EXP_DIR/stats/latencies
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/all-latencies-*.csv $EXP_DIR/stats/latencies
done

# compute throughput
THROUGHPUT=`$BENCHMARK_ROOT_SCRIPT compute-throughput --exp-duration=$DURATION --directory=$EXP_DIR/stats/latencies`

# merge read latencies of all engines
$BENCHMARK_ROOT_SCRIPT concatenate-csv \
    --directory=$EXP_DIR/stats/latencies \
    --filter=read \
    --result-file=$BASE_DIR/results/latencies-read_$INDEX_TIER_CONFIG.csv

LATENCY_AVG=`$BENCHMARK_ROOT_SCRIPT large-file-compute-column-average --file=$BASE_DIR/results/latencies-read_$INDEX_TIER_CONFIG.csv --index=0`

echo $LATENCY_AVG

# add row to results
$BENCHMARK_SCRIPT add-row \
    --slog=$SLOG \
    --index-tier-config=$INDEX_TIER_CONFIG \
    --throughput=$THROUGHPUT \
    --latency-avg=$LATENCY_AVG \
    --is-point-hit=$IS_POINT_HIT \
    --read-latency-file=$BASE_DIR/results/latencies-read_$INDEX_TIER_CONFIG.csv \
    --result-file=$BASE_DIR/results/throughput-vs-latency.csv
