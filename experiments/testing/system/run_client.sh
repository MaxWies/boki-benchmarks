#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

EXP_SPEC_FILE=$1
EXP_DIR=$2

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$ROOT_DIR/scripts/benchmark/summarize_benchmarks

export COLLECT_CONTAINER_LOGS=false
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
    --read_times=$READ_TIMES \
    --engine_nodes=$ENGINE_NODES \
    --storage_nodes=$STORAGE_NODES \
    --sequencer_nodes=$SEQUENCER_NODES \
    --index_nodes=$INDEX_NODES \
    --concurrency_client=$CONCURRENCY_CLIENT \
    >$EXP_DIR/results.log

sleep 10

if [ $COLLECT_CONTAINER_LOGS == 'true' ]; then
    $HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
fi