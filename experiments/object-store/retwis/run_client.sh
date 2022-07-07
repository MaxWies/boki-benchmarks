#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks
BENCHMARK_HELPER_SCRIPT=$ROOT_DIR/scripts/benchmark_helper

export DURATION=30
export CONCURRENCY_CLIENT=192
export NUM_USERS=10000
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
    maxwie/indilog-microbench:thesis-sub \
    cp /microbench-bin/benchmark /tmp/benchmark

ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=warmup-system \
    --benchmark_type=warmup \
    >$EXP_DIR/results.log

# activiate statistic thread on engines
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL \
    >/dev/null

# init
ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/boki-retwisbench:thesis-sub \
    cp /retwisbench-bin/init /tmp/init

ssh -q $CLIENT_HOST -- /tmp/init \
    --faas_gateway=$ENTRY_HOST:8080

# create users
ssh -q $CLIENT_HOST -- docker run \
    -v /tmp:/tmp \
    maxwie/boki-retwisbench:thesis-sub \
    cp /retwisbench-bin/create_users /tmp/create_users

ssh -q $CLIENT_HOST -- /tmp/create_users \
    --faas_gateway=$ENTRY_HOST:8080 \
    --num_users=$NUM_USERS \
    --concurrency=16

# run benchmark
ssh -q $CLIENT_HOST -- docker run \
    -v /tmp:/tmp \
    maxwie/boki-retwisbench:thesis-sub \
    cp /retwisbench-bin/benchmark /tmp/benchmark

ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --num_users=$NUM_USERS \
    --percentages=15,30,50,5 \
    --duration=$DURATION \
    --concurrency_client=$CONCURRENCY_CLIENT \
    --csv_result_file=/tmp/client-results.csv \
    >$EXP_DIR/results.log

sleep $((ENGINE_STAT_THREAD_INTERVAL+10))

RESULT_DIR=$BASE_DIR/results/$SLOG

# get client stats
scp -q $CLIENT_HOST:/tmp/client-results.csv $RESULT_DIR/client-results.csv 

# engines and index engine for boki remote
ENGINE_AND_INDEX_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-labels --base-dir=$BASE_DIR --machine-labels=engine_node,index_engine_node`

# operations stat
i=0
mkdir -p $EXP_DIR/stats/op
for HOST in $ENGINE_AND_INDEX_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/op-stat-*.csv $EXP_DIR/stats/op
    # single engine result
    SINGLE_HOST_RESULT_DIR=$EXP_DIR/stats/op/host$i
    mkdir -p $SINGLE_HOST_RESULT_DIR
    scp -r -q $HOST:/mnt/inmem/slog/stats/op-stat-*.csv $SINGLE_HOST_RESULT_DIR
    $BENCHMARK_HELPER_SCRIPT create-operation-statistics \
        --directory=$SINGLE_HOST_RESULT_DIR \
        --slog=$SLOG \
        --result-directory=$SINGLE_HOST_RESULT_DIR
    ((i=i+1))
done
# sum up operations across nodes
$BENCHMARK_HELPER_SCRIPT create-operation-statistics \
    --directory=$EXP_DIR/stats/op \
    --slog=$SLOG \
    --result-directory=$RESULT_DIR

