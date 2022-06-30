#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

AWS_REGION=eu-west-1
AWS_ACCESS_KEY_ID=DUMMYIDEXAMPLE
AWS_SECRET_ACCESS_KEY=DUMMYEXAMPLEKEY

SLOG=$1
EXP_SPEC_FILE=$2
EXP_DIR=$3

QPS=50

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks
BENCHMARK_HELPER_SCRIPT=$ROOT_DIR/scripts/benchmark_helper
WRK_DIR=/usr/local/bin

export ENGINE_STAT_THREAD_INTERVAL=10

for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $EXP_SPEC_FILE); do
    export $s
done

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

# activiate statistic thread on engines
$ROOT_DIR/../zookeeper/bin/zkCli.sh -server $MANAGER_IP:2181 \
    create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL \
    >/dev/null

scp -q $ROOT_DIR/workloads/workflow/boki/benchmark/hotel/workload.lua $CLIENT_HOST:/tmp

# run warmup
ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 30 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS >$EXP_DIR/wrk_warmup.log

sleep 10

# run benchmark
ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 150 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS 2>/dev/null >$EXP_DIR/wrk.log

sleep 10

scp -q $MANAGER_HOST:/mnt/inmem/store/async_results $EXP_DIR
$ROOT_DIR/scripts/compute_latency.py --async-result-file $EXP_DIR/async_results >$EXP_DIR/latency.txt

DYNAMODB_ENDPOINT=http://`$HELPER_SCRIPT get-machine-ip-with-label --base-dir=$BASE_DIR --machine-label=dynamodb_node`:8000
echo $DYNAMODB_ENDPOINT
echo "Clean cayon"

ssh -q $CLIENT_HOST -- DYNAMODB_ENDPOINT=$DYNAMODB_ENDPOINT TABLE_PREFIX=$TABLE_PREFIX AWS_REGION=$AWS_REGION AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY  \
    /tmp/hotel/init clean cayon

sleep $((ENGINE_STAT_THREAD_INTERVAL+10))

RESULT_DIR=$BASE_DIR/results/$SLOG

# operations stat
i=0
mkdir -p $EXP_DIR/stats/op
for HOST in $ALL_ENGINE_HOSTS; do
    scp -r -q $HOST:/mnt/inmem/slog/stats/op-stat-*.csv $EXP_DIR/stats/op
    # single engine result
    SINGLE_HOST_RESULT_DIR=$EXP_DIR/stats/op/host$i
    mkdir -p $SINGLE_HOST_RESULT_DIR
    scp -r -q $HOST:/mnt/inmem/slog/stats/op-stat-*.csv $SINGLE_HOST_RESULT_DIR
    $BENCHMARK_HELPER_SCRIPT create-operation-statistics \
        --directory=$SINGLE_HOST_RESULT_DIR \
        --slog=$SLOG \
        --result-directory=$SINGLE_HOST_RESULT_DIR
    ((i=i+1))
done
# sum up operations across nodes
$BENCHMARK_HELPER_SCRIPT create-operation-statistics \
    --directory=$EXP_DIR/stats/op \
    --slog=$SLOG \
    --result-directory=$RESULT_DIR