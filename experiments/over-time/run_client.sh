#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

export BENCHMARK_TYPE=throughput-vs-latency
export RECORD_LENGTH=1024
export ENGINE_STAT_THREAD_INTERVAL=60
export DURATION=600
export APPEND_TIMES=1
export READ_TIMES=1

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

if [[ $SLOG == boki-local ]] || [[ $SLOG == indilog-local ]] || [[ $SLOG == indilog-remote ]]; then
    EXP_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
elif [[ $SLOG == boki-remote ]]; then
    EXP_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=index_engine_node`
elif [[ $SLOG == boki-hybrid ]]; then
    EXP_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=hybrid_engine_node`
else
    exit 1
fi

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
EXP_ENGINE_START_TS=$(ssh -q $EXP_HOST -- date +%s)
EXP_ENGINE_END_TS=$((EXP_ENGINE_START_TS+DURATION-ENGINE_STAT_THREAD_INTERVAL))

# activiate resource usage script on engine running in background
ssh -q $EXP_HOST -- sudo rm /tmp/resource_usage.sh /tmp/resource_usage
scp -q $ROOT_DIR/scripts/resource_usage $ROOT_DIR/scripts/resource_usage.sh $EXP_HOST:/tmp
ssh -q -f $EXP_HOST -- "nohup /tmp/resource_usage monitor-resource-usage-by-name \
    --batches=$((DURATION / ENGINE_STAT_THREAD_INTERVAL)) \
    --sample-rate=1 \
    --samples=$ENGINE_STAT_THREAD_INTERVAL \
    --process-name=engine \
    > /dev/null 2>&1"

# activiate statistic thread on engine
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
    --seqnum_read_percentages=$SEQNUM_READ_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    --shared_tags_capacity=$SHARED_TAGS_CAPACITY \
    >$EXP_DIR/results.log

# get latency and index memory records from engine
mkdir -p $EXP_DIR/stats
scp -r -q $EXP_HOST:/mnt/inmem/slog/stats/latencies-*-*.csv $EXP_DIR/stats
scp -r -q $EXP_HOST:/mnt/inmem/slog/stats/index-memory-*-*.csv $EXP_DIR/stats
scp -r -q $EXP_HOST:/mnt/inmem/slog/stats/op-stat-*-*.csv $EXP_DIR/stats

# discard
$BENCHMARK_SCRIPT discard-csv-files-after \
    --directory=$EXP_DIR/stats \
    --ts=$EXP_ENGINE_END_TS

for file in $EXP_DIR/stats/latencies-append-*-*.csv; do
    $BENCHMARK_SCRIPT add-row \
    --directory=$EXP_DIR/stats \
    --file=$file \
    --slog=$SLOG \
    --interval=$ENGINE_STAT_THREAD_INTERVAL \
    --result-file=$BASE_DIR/results/$WORKLOAD/$SLOG/time-latency-index-memory.csv
done

# convert index-memory from B to MiB
$BENCHMARK_SCRIPT update-column-by-division \
    --file=$BASE_DIR/results/$WORKLOAD/$SLOG/time-latency-index-memory.csv \
    --column=index_memory \
    --divisor=1048576 \
    --round-decimals=4

# get resource usage from engine
scp -q $EXP_HOST:/tmp/resource_usage_engine.csv $BASE_DIR/results/$WORKLOAD/$SLOG/time-cpu-memory.csv

# discard
$BENCHMARK_SCRIPT discard-csv-entries-after \
    --file=$BASE_DIR/results/$WORKLOAD/$SLOG/time-cpu-memory.csv \
    --ts=$EXP_ENGINE_END_TS

# add slog info
$BENCHMARK_SCRIPT add-slog-info \
    --file=$BASE_DIR/results/$WORKLOAD/$SLOG/time-cpu-memory.csv \
    --slog=$SLOG

# make time in csv data relative and finally store data in main folder
$BENCHMARK_SCRIPT make-time-relative \
    --directory=$BASE_DIR/results/$WORKLOAD/$SLOG \
    --reference-ts=$EXP_ENGINE_START_TS \
    --result-directory=$BASE_DIR/results/$WORKLOAD
