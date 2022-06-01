#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks
SCALER_SCRIPT=$ROOT_DIR/scripts/scaler

export READ_TIMES=1
export DURATION=20
export CONCURRENCY_CLIENT=4

for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

BENCHMARK_DESCRIPTION="test-sytem"

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

ENGINE_NODES=$(wc -w <<< $ALL_ENGINE_HOSTS)

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

echo $ENGINE_STAT_THREAD_INTERVAL

# activiate statistic thread on engines
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL

ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/indilog-microbench:latest \
    cp /microbench-bin/benchmark /tmp/benchmark

ACTIVE_ENGINE_NODES=`$HELPER_SCRIPT get-num-active-service-replicas --base-dir=$BASE_DIR --service=slog-engine`
NUM_ACTIVE_ENGINE_NODES=$(wc -w <<< $ACTIVE_ENGINE_NODES)

echo $NUM_ACTIVE_ENGINE_NODES

ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --benchmark_type=$BENCHMARK_TYPE \
    --duration=20 \
    --append_times=$APPEND_TIMES \
    --read_times=$READ_TIMES \
    --concurrency_client=$CONCURRENCY_CLIENT \
    > $EXP_DIR/results.log

DYNAMIC_HOSTS=`$HELPER_SCRIPT get-dynamic-hostnames --base-dir=$BASE_DIR --machine-label=engine_node`
NUM_DYNAMIC_ENGINE_NODES=$(wc -w <<< $DYNAMIC_HOSTS)

for HOST in $DYNAMIC_HOSTS; do
    $SCALER_SCRIPT node-join \
    --base-dir=$BASE_DIR \
    --hostname=$HOST
done

sleep 10

$SCALER_SCRIPT engine-scale-out \
    --base-dir=$BASE_DIR \
    --service=slog-engine \
    --replicas=$((NUM_ACTIVE_ENGINE_NODES+NUM_DYNAMIC_ENGINE_NODES)) \
    --dependencies-filter=test-system

ACTIVE_ENGINE_NODES=`$HELPER_SCRIPT get-num-active-service-replicas --base-dir=$BASE_DIR --service=slog-engine`
NUM_ACTIVE_ENGINE_NODES=$(wc -w <<< $ALL_ENGINE_HOSTS)
echo $NUM_ACTIVE_ENGINE_NODES


ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --benchmark_type=$BENCHMARK_TYPE \
    --duration=60 \
    --append_times=$APPEND_TIMES \
    --read_times=$READ_TIMES \
    --concurrency_client=$CONCURRENCY_CLIENT \
    > $EXP_DIR/results.log

# get latency files from engines
mkdir -p $EXP_DIR/stats/latencies
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/latencies*.csv $EXP_DIR/stats
done