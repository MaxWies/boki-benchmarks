#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`

SLOG=$1
SLOG_CONFIG=$2
EXP_SPEC_FILE=$3
EXP_DIR=$4

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

export COLLECT_CONTAINER_LOGS=false
export DURATION=30
export CONCURRENCY_CLIENT=10
export NUM_USERS=1000
export ENGINE_STAT_THREAD_INTERVAL=10

for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
MANAGER_IP=`$HELPER_SCRIPT get-docker-manager-ip --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=slog-gateway`

ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

ssh -q $CLIENT_HOST -- rm -f /tmp/client-results.csv 

# run warmup
ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/indilog-microbench:latest \
    cp /microbench-bin/benchmark /tmp/benchmark

ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=warmup-system \
    --benchmark_type=warmup \
    >$EXP_DIR/results.log

# init
ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/boki-retwisbench:latest \
    cp /retwisbench-bin/init /tmp/init

ssh -q $CLIENT_HOST -- /tmp/init \
    --faas_gateway=$ENTRY_HOST:8080

# create users
ssh -q $CLIENT_HOST -- docker run \
    -v /tmp:/tmp \
    maxwie/boki-retwisbench:latest \
    cp /retwisbench-bin/create_users /tmp/create_users

ssh -q $CLIENT_HOST -- /tmp/create_users \
    --faas_gateway=$ENTRY_HOST:8080 \
    --num_users=$NUM_USERS \
    --concurrency=16

# activiate statistic thread on engines
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL \
    >/dev/null

# run benchmark
ssh -q $CLIENT_HOST -- docker run \
    -v /tmp:/tmp \
    maxwie/boki-retwisbench:latest \
    cp /retwisbench-bin/benchmark /tmp/benchmark

ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --num_users=$NUM_USERS \
    --percentages=15,30,50,5 \
    --duration=$DURATION \
    --concurrency_client=$CONCURRENCY_CLIENT \
    --csv_result_file=/tmp/client-results.csv \
    >$EXP_DIR/results.log

sleep 15

if [ $COLLECT_CONTAINER_LOGS == 'true' ]; then
    $HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
fi

# get operation stats
mkdir -p $EXP_DIR/stats/op
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/op-stat-* $EXP_DIR/stats/op
done
if [[ $SLOG_CONFIG == boki-remote ]]; then
    ALL_INDEX_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=index_engine_node`
    for HOST in $ALL_INDEX_ENGINE_HOSTS; do
        scp -r -q $HOST:/mnt/inmem/slog/stats/op-stat-* $EXP_DIR/stats/op
    done
fi

# get client stats
scp -q $CLIENT_HOST:/tmp/client-results.csv $BASE_DIR/results/collection/$SLOG_CONFIG/client-results.csv 

# merge operation stats of all engines and of all timestamps
$BENCHMARK_SCRIPT merge-csv \
    --directory=$EXP_DIR/stats/op \
    --filter="" \
    --slog=$SLOG \
    --slog-config=$SLOG_CONFIG \
    --result-file=$BASE_DIR/results/collection/$SLOG_CONFIG/op-stats.csv

