#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=$1
SLOG_CONFIG=$2
EXP_SPEC_FILE=$3
EXP_DIR=$4

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
SCALER_SCRIPT=$ROOT_DIR/scripts/scaler
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

export BENCHMARK_TYPE=scaling

# Set the workload semantics
export OPERATION_SEMANTICS_PERCENTAGES=70,30
export SEQNUM_READ_PERCENTAGES=40,30,20,0,10
export TAG_APPEND_PERCENTAGES=40,30,30
export TAG_READ_PERCENTAGES=10,30,20,20,10,10

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
EXP_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`

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

# get timestamp on exp engine
START_TS=$(date +%s)
SCALE_TS=$((START_TS+RELATIVE_SCALE_TS))

echo $START_TS
echo $SCALE_TS

# activiate statistic thread on engines
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL \
    >/dev/null

# run scaler in background if indilog
if [[ $SLOG == 'indilog' ]]; 
then
    ACTIVE_ENGINE_NODES=`$HELPER_SCRIPT get-num-active-service-replicas --base-dir=$BASE_DIR --service=slog-engine`
    # run
    ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --benchmark_type=$BENCHMARK_TYPE \
    --engine_nodes=$ACTIVE_ENGINE_NODES \
    --duration=$DURATION \
    --record_length=$RECORD_LENGTH \
    --append_times=$APPEND_TIMES \
    --read_times=$READ_TIMES \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --operation_semantics_percentages=$OPERATION_SEMANTICS_PERCENTAGES \
    --seqnum_read_percentages=$SEQNUM_READ_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    >$EXP_DIR/results.log
    # sleep
    sleep $RELATIVE_SCALE_TS
    $ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/ignore/dummy \
    >/dev/null
    DYNAMIC_HOSTS=`$HELPER_SCRIPT get-dynamic-hostnames --base-dir=$BASE_DIR --machine-label=engine_node`
    for HOST in $DYNAMIC_HOSTS; do
        $SCALER_SCRIPT node-join \
        --base-dir=$BASE_DIR \
        --hostname=$HOST
    done
    sleep 10
    # scale
    DYNAMIC_HOSTS=`$HELPER_SCRIPT get-dynamic-hostnames --base-dir=$BASE_DIR --machine-label=engine_node`
    DYNAMIC_ENGINE_NODES=$(wc -w <<< $DYNAMIC_HOSTS)
    ACTIVE_ENGINE_NODES=$((ACTIVE_ENGINE_NODES+DYNAMIC_ENGINE_NODES))
    #DYNAMIC_HOSTS_LIST=`$HELPER_SCRIPT get-dynamic-hostnames-as-list --base-dir=$BASE_DIR --machine-label=engine_node`
    $SCALER_SCRIPT engine-scale-out \
    --base-dir=$BASE_DIR \
    --service=slog-engine \
    --replicas=$ACTIVE_ENGINE_NODES
    sleep 10
    SCALED_TS=$(date +%s)
    echo $SCALED_TS
    # run
    ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --benchmark_type=$BENCHMARK_TYPE \
    --engine_nodes=$DYNAMIC_ENGINE_NODES \
    --duration=$DURATION \
    --record_length=$RECORD_LENGTH \
    --append_times=$APPEND_TIMES \
    --read_times=$READ_TIMES \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --operation_semantics_percentages=$OPERATION_SEMANTICS_PERCENTAGES \
    --seqnum_read_percentages=$SEQNUM_READ_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    >$EXP_DIR/results.log
    echo $((SCALED_TS-START_TS)) > $BASE_DIR/results/collection/ts_scaled
    sleep $((DURATION-SCALED_TS+START_TS))
else
    #ALL_INDEX_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=index_engine_node`
    ACTIVE_ENGINE_NODES=$(wc -w <<< $ALL_ENGINE_HOSTS)
    #INDEX_ENGINE_NODES=$(wc -w <<< $ALL_INDEX_ENGINE_HOSTS)
    #ACTIVE_ENGINE_NODES=$((ENGINE_NODES+INDEX_ENGINE_NODES))
    # run experiment
    ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --benchmark_description=$BENCHMARK_DESCRIPTION \
    --benchmark_type=$BENCHMARK_TYPE \
    --engine_nodes=$ACTIVE_ENGINE_NODES \
    --duration=$DURATION \
    --record_length=$RECORD_LENGTH \
    --append_times=$APPEND_TIMES \
    --read_times=$READ_TIMES \
    --concurrency_worker=$CONCURRENCY_WORKER \
    --operation_semantics_percentages=$OPERATION_SEMANTICS_PERCENTAGES \
    --seqnum_read_percentages=$SEQNUM_READ_PERCENTAGES \
    --tag_append_percentages=$TAG_APPEND_PERCENTAGES \
    --tag_read_percentages=$TAG_READ_PERCENTAGES \
    >$EXP_DIR/results.log
    # sleep
    sleep $DURATION
    SCALED_TS=$((START_TS+RELATIVE_SCALE_TS))
fi

sleep 5
END_TS=$(date +%s)

# get latency files from engines
mkdir -p $EXP_DIR/stats/latencies
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/latencies*.csv $EXP_DIR/stats
done
# if [[ $SLOG_CONFIG == boki-remote ]]; then
#     ALL_INDEX_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=index_engine_node`
#     for HOST in $ALL_INDEX_ENGINE_HOSTS; do
#         scp -r -q $HOST:/mnt/inmem/slog/stats/latencies*.csv $EXP_DIR/stats
#     done
# fi

sleep 10
# combine
$BENCHMARK_SCRIPT combine-csv-files \
    --directory=$EXP_DIR/stats \
    --slog=$SLOG \
    --slog-config=$SLOG_CONFIG \
    --interval=$ENGINE_STAT_THREAD_INTERVAL \
    --scale-ts=$SCALED_TS \
    --result-file=$BASE_DIR/results/collection/$SLOG/time-vs-throughput-latency.csv

# make time in csv data relative and finally store data in main collection folder
$BENCHMARK_SCRIPT make-time-relative \
    --file=$BASE_DIR/results/collection/$SLOG/time-vs-throughput-latency.csv \
    --start-ts=$START_TS \
    --end-ts=$END_TS \
    --result-file=$BASE_DIR/results/collection/time-vs-throughput-latency.csv
