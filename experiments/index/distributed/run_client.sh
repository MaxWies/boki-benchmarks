#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

EXP_SPEC_FILE=$1
EXP_DIR=$2

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks

export COLLECT_CONTAINER_LOGS=false
export RECORD_LENGTH=1024
export READ_TIMES=1
export USE_TAGS=true
export DURATION=20
export LATENCY_BUCKET_GRANULARITY=20
export LATENCY_BUCKET_LOWER=10
export LATENCY_BUCKET_UPPER=100000
export LATENCY_HEAD_SIZE=20
export LATENCY_TAIL_SIZE=20
export SNAPSHOT_INTERVAL=0
export CONCURRENCY_WORKER=1
export CONCURRENCY_OPERATION=1
export OPERATION_SEMANTICS_PERCENTAGES=50,50
export SEQNUM_READ_PERCENTAGES=30,30,20,10,10
export TAG_APPEND_PERCENTAGES=50,50
export TAG_READ_PERCENTAGES=40,30,30

for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

BENCHMARK_DESCRIPTION="Append-and-read-${READ_TIMES}-times"

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=boki-gateway`

ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
ALL_STORAGE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=storage_node`
ALL_SEQUENCER_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=sequencer_node`
ALL_INDEX_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=index_node`

ENGINE_NODES=`$HELPER_SCRIPT get-num-active-service-replicas --base-dir=$BASE_DIR --service=boki-engine`
STORAGE_NODES=$(wc -w <<< $ALL_STORAGE_HOSTS)
SEQUENCER_NODES=$(wc -w <<< $ALL_SEQUENCER_HOSTS)
INDEX_NODES=$(wc -w <<< $ALL_INDEX_HOSTS)

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
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --benchmark_type=$BENCHMARK_TYPE \
    --duration=$DURATION \
    --record_length=$RECORD_LENGTH \
    --read_times=$READ_TIMES \
    --use_tags=$USE_TAGS \
    --latency_bucket_lower=$LATENCY_BUCKET_LOWER \
    --latency_bucket_upper=$LATENCY_BUCKET_UPPER \
    --latency_bucket_granularity=$LATENCY_BUCKET_GRANULARITY \
    --latency_head_size=$LATENCY_HEAD_SIZE \
    --latency_tail_size=$LATENCY_TAIL_SIZE \
    --engine_nodes=$ENGINE_NODES \
    --storage_nodes=$STORAGE_NODES \
    --sequencer_nodes=$SEQUENCER_NODES \
    --index_nodes=$INDEX_NODES \
    --snapshot_interval=$SNAPSHOT_INTERVAL \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --concurrency_operation=$CONCURRENCY_OPERATION \
    --operation_semantics_percentages=$OPERATION_SEMANTICS_PERCENTAGES \
    --seqnum_read_percentages=$SEQNUM_READ_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    >$EXP_DIR/results.log

sleep 10

if [ $COLLECT_CONTAINER_LOGS == 'true' ]; then
    $HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
fi

mkdir -p $EXP_DIR/benchmark $EXP_DIR/stats/engine
scp -r -q $CLIENT_HOST:/tmp/boki/output/benchmark/$BENCHMARK_TYPE $EXP_DIR/benchmark
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/boki/stats/* $EXP_DIR/stats/engine
done
$BENCHMARK_SCRIPT benchmark-log-loop --directory=$EXP_DIR/benchmark/$BENCHMARK_TYPE
$BENCHMARK_SCRIPT benchmark-engine-stats --directory=$EXP_DIR/stats/engine
echo "Results published at $EXP_DIR"