#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=$1-$2
EXP_SPEC_FILE=$3
EXP_DIR=$4

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

export BENCHMARK_TYPE=engine-random-load
export RECORD_LENGTH=1024
export APPEND_TIMES=1
export READ_TIMES=1

# Set the workload semantics
export OPERATION_SEMANTICS_PERCENTAGES=0,100
export SEQNUM_READ_PERCENTAGES=100,0,0,0,0
export TAG_APPEND_PERCENTAGES=100,0,0
export TAG_READ_PERCENTAGES=0,100,0,0,0,0
export DURATION=60
export ENGINE_STAT_THREAD_INTERVAL=5

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

EXP_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
if [[ $SLOG == boki-hybrid-hybrid ]]; then
    EXP_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=hybrid_engine_node`
fi

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/indilog-microbench:thesis-sub \
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
    >$EXP_DIR/results.log


mkdir -p $EXP_DIR/stats/latencies
scp -r -q $EXP_HOST:/mnt/inmem/slog/stats/all-latencies-*.csv $EXP_DIR/stats/latencies

THROUGHPUT=`$BENCHMARK_SCRIPT compute-throughput \
    --directory=$EXP_DIR/stats/latencies \
    --exp-duration=$DURATION`

for OP in append read;
do
$BENCHMARK_SCRIPT concatenate-csv \
    --directory=$EXP_DIR/stats/latencies \
    --filter=$OP \
    --result-file=$EXP_DIR/stats/latencies/all-latencies-$OP.csv
done

$BENCHMARK_SCRIPT add-row \
    --directory=$EXP_DIR/stats/latencies \
    --slog=$SLOG \
    --concurrency=$((CONCURRENCY_WORKER*CONCURRENCY_OPERATION)) \
    --throughput=$THROUGHPUT \
    --result-file=$BASE_DIR/results/concurrency-vs-latency.csv
