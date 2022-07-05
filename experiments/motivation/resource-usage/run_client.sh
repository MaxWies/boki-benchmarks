#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks
BENCHMARK_ROOT_SCRIPT=$ROOT_DIR/scripts/benchmark_helper

export BENCHMARK_TYPE=engine-random-load
export RECORD_LENGTH=1024
export ENGINE_STAT_THREAD_INTERVAL=5
export DURATION=60
export APPEND_TIMES=1
export READ_TIMES=1

export OPERATION_SEMANTICS_PERCENTAGES=0,100
export SEQNUM_READ_PERCENTAGES=100,0,0,0,0
export TAG_APPEND_PERCENTAGES=100,0,0
export TAG_READ_PERCENTAGES=0,100,0,0,0,0

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

if [[ $SLOG == boki-local ]]; then
    EXP_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
elif [[ $SLOG == boki-remote ]]; then
    EXP_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=index_engine_node`
elif [[ $SLOG == boki-hybrid ]]; then
    EXP_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=hybrid_engine_node`
else
    exit 1
fi
EXP_STORAGE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=storage_node`

# timestamp on engine
EXP_ENGINE_START_TS=$(ssh -q $EXP_ENGINE_HOST -- date +%s)
EXP_ENGINE_END_TS=$((EXP_ENGINE_START_TS+DURATION-ENGINE_STAT_THREAD_INTERVAL))

# timestamp on storage
EXP_STORAGE_START_TS=$(ssh -q $EXP_STORAGE_HOST -- date +%s)
EXP_STORAGE_END_TS=$((EXP_STORAGE_START_TS+DURATION-ENGINE_STAT_THREAD_INTERVAL))

# activiate scripts in background
for i in "$EXP_ENGINE_HOST engine" "$EXP_STORAGE_HOST storage";
do
    set -- $i
    COMPONENT=$2
    ssh -q $1 -- sudo rm /tmp/resource_usage.sh /tmp/resource_usage
    scp -q $ROOT_DIR/scripts/resource_usage $ROOT_DIR/scripts/resource_usage.sh $1:/tmp

    ssh $1 "nohup /tmp/resource_usage monitor-resource-usage-by-name \
        --batches=$((DURATION / ENGINE_STAT_THREAD_INTERVAL)) \
        --sample-rate=1 \
        --samples=$ENGINE_STAT_THREAD_INTERVAL \
        --process-name=$COMPONENT \
        > /dev/null 2>&1 &"

    ssh $1 "nohup sudo /tmp/resource_usage run-iftop \
        --iftop-connections=20 \
        --iftop-duration=$DURATION \
        --iftop-output-file=/tmp/bandwidth.log \
        > /dev/null 2>&1 &"
done

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

for i in "$EXP_ENGINE_HOST $EXP_ENGINE_START_TS $EXP_ENGINE_END_TS engine" "$EXP_STORAGE_HOST $EXP_STORAGE_START_TS $EXP_STORAGE_END_TS storage";
do
    set -- $i
    HOST=$1
    START_TS=$2
    END_TS=$3
    COMPONENT=$4
    mkdir -p $EXP_DIR/$COMPONENT
    
    # CPU
    scp -q $HOST:/tmp/resource_usage_$COMPONENT.csv $EXP_DIR/$COMPONENT/time-cpu-memory.csv

    $BENCHMARK_ROOT_SCRIPT discard-csv-entries-before \
        --file=$EXP_DIR/$COMPONENT/time-cpu-memory.csv \
        --ts=$((START_TS+ENGINE_STAT_THREAD_INTERVAL))

    $BENCHMARK_ROOT_SCRIPT discard-csv-entries-after \
        --file=$EXP_DIR/$COMPONENT/time-cpu-memory.csv \
        --ts=$END_TS

    CPU_AVG=`$BENCHMARK_ROOT_SCRIPT compute-column-average \
        --file=$EXP_DIR/$COMPONENT/time-cpu-memory.csv \
        --column=cpu_avg`

    # Bandwidth
    scp -q $HOST:/tmp/bandwidth.log $EXP_DIR/$COMPONENT/bandwidth.log

    $BENCHMARK_ROOT_SCRIPT parse-iftop-log \
        --file=$EXP_DIR/$COMPONENT/bandwidth.log \
        --machine-file=$BASE_DIR/machines.json \
        --exp-duration=$DURATION \
        --result-file=$EXP_DIR/$COMPONENT/bandwidth.csv

    $BENCHMARK_SCRIPT add-row \
        --slog=$SLOG \
        --component=$COMPONENT \
        --concurrency=$((CONCURRENCY_WORKER*CONCURRENCY_OPERATION)) \
        --cpu-avg=$CPU_AVG \
        --bandwidth-file=$EXP_DIR/$COMPONENT/bandwidth.csv \
        --result-file=$BASE_DIR/results/concurrency-cpu-bandwidth.csv
done