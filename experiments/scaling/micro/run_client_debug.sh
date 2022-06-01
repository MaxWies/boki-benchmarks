#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=indilog
SLOG_CONFIG=indilog
EXP_SPEC_FILE=/home/mrc/run/boki-benchmarks/experiments/scaling/micro/specs/exp-cf24.json
EXP_DIR=/home/mrc/run/boki-benchmarks/experiments/scaling/micro/results/eng1-st3-seq3-ix1-is1-ir1-ur1-mr3-ssmx4/exp-cf24

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
SCALER_SCRIPT=$ROOT_DIR/scripts/scaler
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

export BENCHMARK_TYPE=scaling
export RECORD_LENGTH=1024
export DURATION=200
export APPEND_TIMES=1
export READ_TIMES=19
export ENGINE_STAT_THREAD_INTERVAL=10

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

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
MANAGER_IP=`$HELPER_SCRIPT get-docker-manager-ip --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=slog-gateway`

ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
EXP_ENGINE_HOST=`$HELPER_SCRIPT get-single-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`

# get timestamp on exp engine
START_TS=1653850145
SCALE_TS=1653850175
SCALED_TS=1653850195
END_TS=1653860000


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
