#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=boki-hybrid
EXP_SPEC_FILE=/home/mrc/run/boki-benchmarks/experiments/scaling/postpone/specs/exp-cf3.json
EXP_DIR=/home/mrc/run/boki-benchmarks/experiments/scaling/postpone/results/boki-hybrid/eng2-eh1-st3-seq3-ir1-ur1-mr3/exp-cf3

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
export WORKLOAD=mix

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

# ts
START_TS=1654785102
SCALE_TS=1654785132
END_TS=1654785277

echo $START_TS
echo $SCALE_TS
echo $END_TS

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
    --result-file=$EXP_DIR/time-vs-throughput-latency.csv

# make time in csv data relative and finally store data in main collection folder
$BENCHMARK_SCRIPT make-time-relative \
    --file=$EXP_DIR/time-vs-throughput-latency.csv \
    --start-ts=$START_TS \
    --end-ts=$END_TS \
    --result-file=$BASE_DIR/results/$WORKLOAD/time-vs-throughput-latency.csv


# For boki
if [[ $SLOG == boki-hybrid ]]; then
    HYBRID_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=hybrid_engine_node`
    INDEX_LESS_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label-without-label --base-dir=$BASE_DIR --machine-label=engine_node --machine-label-without=hybrid_engine_node`

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
            --engine-type=$ENGINE_TYPE \
            --slog=$SLOG \
            --interval=$ENGINE_STAT_THREAD_INTERVAL \
            --result-file=$EXP_DIR/stats/latencies/$ENGINE_TYPE/time-vs-engine-type-latency.csv
        done
        # make time in csv data relative and finally store data in main folder
        $BENCHMARK_SCRIPT make-time-relative \
            --file=$EXP_DIR/stats/latencies/$ENGINE_TYPE/time-vs-engine-type-latency.csv \
            --start-ts=$START_TS \
            --end-ts=$END_TS \
            --result-file=$BASE_DIR/results/$WORKLOAD/time-vs-engine-type-latency.csv 
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
        --engine-type=$ENGINE_TYPE \
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
        --file=$EXP_DIR/stats/latencies/$ENGINE_TYPE/time-vs-engine-type-latency.csv \
        --start-ts=$START_TS \
        --end-ts=$END_TS \
        --result-file=$BASE_DIR/results/$WORKLOAD/time-vs-engine-type-latency.csv 
fi