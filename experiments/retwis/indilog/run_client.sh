#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

EXP_SPEC_FILE=$1
EXP_DIR=$2

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks

export COLLECT_CONTAINER_LOGS=false
export DURATION=30
export CONCURRENCY_CLIENT=10
export NUM_USERS=1000

for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=boki-gateway`

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/boki-retwisbench:latest \
    cp /retwisbench-bin/init /tmp/init

ssh -q $CLIENT_HOST -- /tmp/init \
    --faas_gateway=$ENTRY_HOST:8080

ssh -q $CLIENT_HOST -- docker run \
    -v /tmp:/tmp \
    maxwie/boki-retwisbench:latest \
    cp /retwisbench-bin/create_users /tmp/create_users

ssh -q $CLIENT_HOST -- /tmp/create_users \
    --faas_gateway=$ENTRY_HOST:8080 \
    --num_users=$NUM_USERS \
    --concurrency=16

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
    >$EXP_DIR/results.log

if [ $COLLECT_CONTAINER_LOGS == 'true' ]; then
    $HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
fi

mkdir -p $EXP_DIR/stats/engine
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/boki/stats/* $EXP_DIR/stats/engine
done
$BENCHMARK_SCRIPT benchmark-engine-stats --directory=$EXP_DIR/stats/engine
