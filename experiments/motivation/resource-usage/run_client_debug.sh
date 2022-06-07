#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=boki-local
EXP_SPEC_FILE=/home/mrc/run/boki-benchmarks/experiments/motivation/resource-usage/specs/exp-cf2.json
EXP_DIR=/home/mrc/run/boki-benchmarks/experiments/motivation/resource-usage/results/boki-local/eng1-st1-seq3-ir1-ur1-mr3/exp-cftest

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks
BENCHMARK_ROOT_SCRIPT=$ROOT_DIR/scripts/benchmark_helper

export BENCHMARK_TYPE=throughput-vs-latency
export RECORD_LENGTH=1024
export ENGINE_STAT_THREAD_INTERVAL=2
export DURATION=10
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

rm -rf /home/mrc/run/boki-benchmarks/experiments/motivation/resource-usage/results/boki-local/eng1-st1-seq3-ir1-ur1-mr3/exp-cftest
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

EXP_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
EXP_STORAGE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=storage_node`

# # timestamp on engine
# EXP_ENGINE_START_TS=$(ssh -q $EXP_ENGINE_HOST -- date +%s)
# EXP_ENGINE_END_TS=$((EXP_ENGINE_START_TS+DURATION-ENGINE_STAT_THREAD_INTERVAL))

# # timestamp on storage
# EXP_STORAGE_START_TS=$(ssh -q $EXP_STORAGE_HOST -- date +%s)
# EXP_STORAGE_END_TS=$((EXP_STORAGE_START_TS+DURATION-ENGINE_STAT_THREAD_INTERVAL))

# activiate scripts in background
# for i in "$EXP_ENGINE_HOST engine" "$EXP_STORAGE_HOST storage";
# do
#     set -- $i
#     COMPONENT=$2
#     ssh -q $1 -- sudo rm /tmp/resource_usage.sh /tmp/resource_usage
#     scp -q $ROOT_DIR/scripts/resource_usage $ROOT_DIR/scripts/resource_usage.sh $1:/tmp

#     ssh $1 "nohup /tmp/resource_usage monitor-resource-usage-by-name \
#         --batches=6 \
#         --sample-rate=1 \
#         --samples=10 \
#         --process-name=$COMPONENT \
#         > /dev/null 2>&1 &"

#     ssh $1 "nohup sudo /tmp/resource_usage run-iftop \
#         --iftop-connections=20 \
#         --iftop-duration=$DURATION \
#         --iftop-output-file=/tmp/bandwidth.log \
#         > /dev/null 2>&1 &"
# done

# sleep $DURATION
# sleep 2

EXP_ENGINE_START_TS=1654521550
EXP_ENGINE_END_TS=1654521575
EXP_STORAGE_START_TS=1654521551
EXP_STORAGE_END_TS=1654521576

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
        --ts=$((START_TS+10))

    $BENCHMARK_ROOT_SCRIPT discard-csv-entries-after \
        --file=$EXP_DIR/$COMPONENT/time-cpu-memory.csv \
        --ts=$END_TS

    echo "Here"

    CPU_AVG=`$BENCHMARK_ROOT_SCRIPT compute-column-average \
        --file=$EXP_DIR/$COMPONENT/time-cpu-memory.csv \
        --column=cpu_avg`

    echo "Here2"

    # Bandwidth
    scp -q $HOST:/tmp/bandwidth.log $EXP_DIR/$COMPONENT/bandwidth.log

    $BENCHMARK_ROOT_SCRIPT parse-iftop-log \
        --file=$EXP_DIR/$COMPONENT/bandwidth.log \
        --machine-file=$BASE_DIR/machines.json \
        --exp-duration=$DURATION \
        --result-file=$EXP_DIR/$COMPONENT/bandwidth.csv

    echo "HERE3"

    $BENCHMARK_SCRIPT add-row \
        --slog=$SLOG \
        --component=$COMPONENT \
        --concurrency=$((CONCURRENCY_WORKER*CONCURRENCY_OPERATION)) \
        --cpu-avg=$CPU_AVG \
        --bandwidth-file=$EXP_DIR/$COMPONENT/bandwidth.csv \
        --result-file=$BASE_DIR/results/concurrency-cpu-bandwidth.csv
done