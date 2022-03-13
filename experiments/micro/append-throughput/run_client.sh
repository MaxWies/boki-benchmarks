#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

EXP_SPEC_FILE=$1
EXP_DIR=$2

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks

export COLLECT_CONTAINER_LOGS=false
export RECORD_LENGTH=1024
export DURATION=20
export LATENCY_BUCKET_GRANULARITY=10
export LATENCY_BUCKET_LOWER=300
export LATENCY_BUCKET_UPPER=10000
export LATENCY_HEAD_SIZE=20
export LATENCY_TAIL_SIZE=20
export SNAPSHOT_INTERVAL=0
export CONCURRENCY_WORKER=1
export CONCURRENCY_OPERATION=1

for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=boki-gateway`
ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`

NUM_ENGINES=$(wc -w <<< $ALL_ENGINE_HOSTS)
for HOST in $ALL_ENGINE_HOSTS; do
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/boki/output/benchmark/$BENCHMARK_TYPE
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki/output/benchmark/$BENCHMARK_TYPE
done

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/boki-microbench:latest \
    cp /microbench-bin/benchmark /tmp/benchmark

ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_type=$BENCHMARK_TYPE \
    --duration=$DURATION \
    --record_length=$RECORD_LENGTH \
    --latency_bucket_lower=$LATENCY_BUCKET_LOWER \
    --latency_bucket_upper=$LATENCY_BUCKET_UPPER \
    --latency_bucket_granularity=$LATENCY_BUCKET_GRANULARITY \
    --latency_head_size=$LATENCY_HEAD_SIZE \
    --latency_tail_size=$LATENCY_TAIL_SIZE \
    --num_engines=$NUM_ENGINES \
    --snapshot_interval=$SNAPSHOT_INTERVAL \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --concurrency_operation=$CONCURRENCY_OPERATION
    >$EXP_DIR/results.log

sleep 10

if [ $COLLECT_CONTAINER_LOGS == 'true' ]; then
    $HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
fi

mkdir -p $EXP_DIR/benchmark
scp -r -q $CLIENT_HOST:/tmp/boki/output/benchmark/$BENCHMARK_TYPE $EXP_DIR/benchmark
for engine_result in $EXP_DIR/benchmark/$BENCHMARK_TYPE/*; do
    $BENCHMARK_SCRIPT --result-file=$engine_result
done