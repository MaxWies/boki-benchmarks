#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks
BENCHMARK_HELPER_SCRIPT=$ROOT_DIR/scripts/benchmark_helper

export BENCHMARK_TYPE=scaling
export APPEND_TIMES=1
export READ_TIMES=19
export RECORD_LENGTH=1024
export DURATION=180
export RELATIVE_SCALE_TS=30
export ENGINE_STAT_THREAD_INTERVAL=5

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

# ts
START_TS=$(date +%s)
SCALE_TS=$((START_TS+RELATIVE_SCALE_TS))
END_TS=$((START_TS+DURATION-ENGINE_STAT_THREAD_INTERVAL))

echo $START_TS
echo $SCALE_TS
echo $END_TS

# activiate statistic thread on engines
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL \
    >/dev/null

# run scaler in background if indilog
if [[ $SLOG == 'indilog-postpone-caching' ]] || [[ 'indilog-postpone-registering' ]]; 
then
    # run
    ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --benchmark_type=$BENCHMARK_TYPE \
    --engine_nodes=$ENGINE_NODES \
    --duration=$DURATION \
    --record_length=$RECORD_LENGTH \
    --append_times=$APPEND_TIMES \
    --read_times=$READ_TIMES \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --concurrency_operation=$CONCURRENCY_OPERATION \
    --operation_semantics_percentages=$OPERATION_SEMANTICS_PERCENTAGES \
    --seqnum_read_percentages=$SEQNUM_READ_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    --shared_tags_capacity=$SHARED_TAGS_CAPACITY \
    >$EXP_DIR/results.log

    # sleep
    sleep $RELATIVE_SCALE_TS
    if [[ $SLOG == 'indilog-postpone-caching' ]];
    then
        # activiate postponed engines
        $ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
            create /faas/activate/cache \
            >/dev/null
    else
        # activiate postponed engines
        $ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
            create /faas/activate/register \
            >/dev/null
    fi

    # sleep remaining time
    sleep $((DURATION-RELATIVE_SCALE_TS))
else
    # run
    ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --benchmark_type=$BENCHMARK_TYPE \
    --engine_nodes=$ENGINE_NODES \
    --duration=$DURATION \
    --record_length=$RECORD_LENGTH \
    --append_times=$APPEND_TIMES \
    --read_times=$READ_TIMES \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --concurrency_operation=$CONCURRENCY_OPERATION \
    --operation_semantics_percentages=$OPERATION_SEMANTICS_PERCENTAGES \
    --seqnum_read_percentages=$SEQNUM_READ_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    --shared_tags_capacity=$SHARED_TAGS_CAPACITY \
    >$EXP_DIR/results.log

    # sleep
    sleep $DURATION
fi

# get latency files from engines
mkdir -p $EXP_DIR/stats/latencies
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/latencies*.csv $EXP_DIR/stats
done

$BENCHMARK_SCRIPT discard-csv-files-after \
    --directory=$EXP_DIR/stats/latencies \
    --ts=$END_TS

# combine
$BENCHMARK_SCRIPT combine-csv-files \
    --directory=$EXP_DIR/stats \
    --slog=$SLOG \
    --interval=$ENGINE_STAT_THREAD_INTERVAL \
    --scale-ts=$SCALE_TS \
    --result-file=$BASE_DIR/results/$WORKLOAD/$SLOG/time-vs-throughput-latency.csv

# make time in csv data relative and finally store data in main collection folder
$BENCHMARK_SCRIPT make-time-relative \
    --file=$BASE_DIR/results/$SLOG/time-vs-throughput-latency.csv \
    --start-ts=$START_TS \
    --end-ts=$END_TS \
    --result-file=$BASE_DIR/results/$WORKLOAD/time-vs-throughput-latency.csv


# For boki
if [[ $SLOG == boki-hybrid ]]; then
    HYBRID_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=hybrid_engine_node`
    INDEX_LESS_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label-extended --base-dir=$BASE_DIR --machine-label=engine_node --machine-label-without=hybrid_engine_node`

    for i in "$HYBRID_ENGINE_HOST hybrid" "$INDEX_LESS_ENGINE_HOST index_less";
    do
        set -- $i
        HOST=$1
        ENGINE_TYPE=$2
        mkdir -p $EXP_DIR/stats/latencies/$ENGINE_TYPE
        scp -r -q $HOST:/mnt/inmem/slog/stats/latencies-*-*.csv $EXP_DIR/stats/latencies/$ENGINE_TYPE
        for FILE in $EXP_DIR/stats/latencies/$ENGINE_TYPE/latencies-append-*-*.csv; do
            $BENCHMARK_SCRIPT add-single-engine-row \
            --directory=$EXP_DIR/stats \
            --file=$FILE \
            --type=$ENGINE_TYPE
            --slog=$SLOG \
            --interval=$ENGINE_STAT_THREAD_INTERVAL \
            --result-file=$EXP_DIR/stats/latencies/$ENGINE_TYPE/time-vs-engine-type-latency.csv
        done
        # make time in csv data relative and finally store data in main folder
        $BENCHMARK_SCRIPT make-time-relative \
            --file=$EXP_DIR/stats/latencies/$ENGINE_TYPE/time-vs-engine-type-latency.csv \
            --start-ts=$START_TS \
            --end-ts=$END_TS \
            --result-directory=$BASE_DIR/results/$WORKLOAD
    done
else
    HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
    ENGINE_TYPE=indilog
    mkdir -p $EXP_DIR/stats/latencies/$ENGINE_TYPE
    scp -r -q $HOST:/mnt/inmem/slog/stats/latencies-*-*.csv $EXP_DIR/stats/latencies/$ENGINE_TYPE
    for FILE in $EXP_DIR/stats/latencies/$ENGINE_TYPE/latencies-append-*-*.csv; do
        $BENCHMARK_SCRIPT add-single-engine-row \
        --directory=$EXP_DIR/stats \
        --file=$FILE \
        --type=$ENGINE_TYPE
        --slog=$SLOG \
        --interval=$ENGINE_STAT_THREAD_INTERVAL \
        --result-file=$EXP_DIR/stats/latencies/$ENGINE_TYPE/time-vs-engine-type-latency.csv
    done
    # cut before scale ts
    $BENCHMARK_HELPER_SCRIPT discard-csv-entries-before \
        --file=$EXP_DIR/stats/latencies/$ENGINE_TYPE/time-vs-engine-type-latency.csv \
        --ts=$SCALE_TS

    # make time in csv data relative and finally store data in main folder
    $BENCHMARK_SCRIPT make-time-relative \
        --file=$BASE_DIR/results/$WORKLOAD/$SLOG/$ENGINE_TYPE/time-vs-engine-type-latency.csv \
        --start-ts=$START_TS \
        --end-ts=$END_TS \
        --result-directory=$BASE_DIR/results/$WORKLOAD
fi