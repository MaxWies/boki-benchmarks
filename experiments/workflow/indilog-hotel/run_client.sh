#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

AWS_REGION=eu-west-1
AWS_ACCESS_KEY_ID=DUMMYIDEXAMPLE
AWS_SECRET_ACCESS_KEY=DUMMYEXAMPLEKEY

SLOG=$1
SLOG_CONFIG=$2
EXP_SPEC_FILE=$3
EXP_DIR=$4
QPS=$5

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks
WRK_DIR=/usr/local/bin

export COLLECT_CONTAINER_LOGS=false

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

scp -q $ROOT_DIR/workloads/workflow/boki/benchmark/hotel/workload.lua $CLIENT_HOST:/tmp

# run warmup
ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 30 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS >$EXP_DIR/wrk_warmup.log

sleep 10

# activiate statistic thread on engines
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL \
    >/dev/null

# run benchmark
ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 150 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS 2>/dev/null >$EXP_DIR/wrk.log

sleep 10

scp -q $MANAGER_HOST:/mnt/inmem/store/async_results $EXP_DIR
$ROOT_DIR/scripts/compute_latency.py --async-result-file $EXP_DIR/async_results >$EXP_DIR/latency.txt

echo $DYNAMODB_ENDPOINT
echo "Clean cayon"

ssh -q $CLIENT_HOST -- DYNAMODB_ENDPOINT=$DYNAMODB_ENDPOINT TABLE_PREFIX=$TABLE_PREFIX AWS_REGION=$AWS_REGION AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY  \
    /tmp/hotel/init clean cayon

if [ $COLLECT_CONTAINER_LOGS == 'true' ]; then
    $HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
fi

# get operation stats
mkdir -p $EXP_DIR/stats/op
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/op-stat-* $EXP_DIR/stats/op
done
if [[ $SLOG_CONFIG == boki-remote ]]; then
    ALL_INDEX_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=index_engine_node`
    for HOST in $ALL_INDEX_ENGINE_HOSTS; do
        scp -r -q $HOST:/mnt/inmem/slog/stats/op-stat-* $EXP_DIR/stats/op
    done
fi

# merge operation stats of all engines and of all timestamps
$BENCHMARK_SCRIPT merge-csv \
    --directory=$EXP_DIR/stats/op \
    --filter="" \
    --slog=$SLOG \
    --slog-config=$SLOG_CONFIG \
    --result-file=$BASE_DIR/results/collection/$SLOG_CONFIG/op-stats.csv

# compute client latencies
scp -q $MANAGER_HOST:/mnt/inmem/store/async_results $EXP_DIR
$ROOT_DIR/scripts/compute_latency.py \
    --async-result-file=$EXP_DIR/async_results \
    --csv-output-file=$BASE_DIR/results/collection/$SLOG_CONFIG/client-results.csv