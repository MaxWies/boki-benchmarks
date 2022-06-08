#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

WORKLOAD=$APPEND_TIMES-$READ_TIMES

export BENCHMARK_TYPE=throughput-vs-latency
export COLLECT_CONTAINER_LOGS=false
export RECORD_LENGTH=1024

# Set the workload semantics
export OPERATION_SEMANTICS_PERCENTAGES=50,50
export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
export TAG_APPEND_PERCENTAGES=33,34,33
export TAG_READ_PERCENTAGES=16,17,17,17,16,17

if [[ $SLOG == indilog-remote-point ]]; then
    # read tag directly
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
fi

# Overwrite environment with spec file
for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

export DURATION=60
export ENGINE_STAT_THREAD_INTERVAL=10

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

# activiate statistic thread on engine
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL \
    >/dev/null

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
    --operation_semantics_percentages=$OPERATION_SEMANTICS_PERCENTAGES \
    --seqnum_read_percentages=$SEQNUM_READ_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    >$EXP_DIR/results.log

sleep 3


mkdir -p $EXP_DIR/stats/latencies
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/all-latencies-*.csv $EXP_DIR/stats/latencies
done

THROUGHPUT_APPEND=`$BENCHMARK_SCRIPT compute-throughput \
    --directory=$EXP_DIR/stats/latencies \
    --filter=append \
    --exp-duration=$DURATION`

THROUGHPUT_READ=`$BENCHMARK_SCRIPT compute-throughput \
    --directory=$EXP_DIR/stats/latencies \
    --filter=read \
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
    --throughput-append=$THROUGHPUT_APPEND \
    --throughput-read=$THROUGHPUT_READ \
    --result-file=$BASE_DIR/results/$WORKLOAD/throughput-vs-latency.csv
