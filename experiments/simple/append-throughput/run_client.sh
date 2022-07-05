#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark_container

export RECORD_LENGTH=1024
export DURATION=30
export APPEND_TIMES=1
export LATENCY_BUCKET_GRANULARITY=10
export LATENCY_BUCKET_LOWER=300
export LATENCY_BUCKET_UPPER=10000
export LATENCY_HEAD_SIZE=20
export LATENCY_TAIL_SIZE=20
export STATISTICS_AT_CONTAINER=true

# Overwrite environment with spec file
for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

BENCHMARK_DESCRIPTION="Append-${APPEND_TIMES}-times"

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=slog-gateway`

ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
ENGINE_NODES=$(wc -w <<< $ALL_ENGINE_HOSTS)

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/indilog-microbench:thesis-sub \
    cp /microbench-bin/benchmark /tmp/benchmark

ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_type=$BENCHMARK_TYPE \
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --duration=$DURATION \
    --record_length=$RECORD_LENGTH \
    --append_times=$APPEND_TIMES \
    --engine_nodes=$ENGINE_NODES \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --concurrency_operation=$CONCURRENCY_OPERATION \
    --latency_bucket_lower=$LATENCY_BUCKET_LOWER \
    --latency_bucket_upper=$LATENCY_BUCKET_UPPER \
    --latency_bucket_granularity=$LATENCY_BUCKET_GRANULARITY \
    --latency_head_size=$LATENCY_HEAD_SIZE \
    --latency_tail_size=$LATENCY_TAIL_SIZE \
    --statistics_at_container=$STATISTICS_AT_CONTAINER \
    >$EXP_DIR/results.log

sleep 10

mkdir -p $EXP_DIR/benchmark
scp -r -q $CLIENT_HOST:/tmp/slog/output/benchmark/$BENCHMARK_TYPE $EXP_DIR/benchmark
$BENCHMARK_SCRIPT collect-container-results --directory=$EXP_DIR/benchmark/$BENCHMARK_TYPE
echo "Results published at $EXP_DIR/benchmark/$BENCHMARK_TYPE"