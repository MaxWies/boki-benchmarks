#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

COLLECTION_DIR=$BASE_DIR/results/collection
#rm -rf $COLLECTION_DIR
#mkdir -p $COLLECTION_DIR $COLLECTION_DIR/boki $COLLECTION_DIR/indilog

# Machine config 1: Boki-Remote (only one engine has a complete index)
#cp $BASE_DIR/machines_eng3-st3-seq3.json $BASE_DIR/machines.json
#$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
#./run_build.sh boki boki-remote $CONTROLLER_SPEC_DIR/boki/eng3-st3-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# ssh -q $MANAGER_HOST -- docker stack rm boki-experiment
# sleep 20

# Boki
# cp $BASE_DIR/machines_eng1-st1-seq3-ix2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki $CONTROLLER_SPEC_DIR/boki/eng1-st1-seq3-ix2-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

# cp $BASE_DIR/machines_eng2-st1-seq3-ix2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki $CONTROLLER_SPEC_DIR/boki/eng2-st1-seq3-ix2-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

# cp $BASE_DIR/machines_eng4-st1-seq3-ix2.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki $CONTROLLER_SPEC_DIR/boki/eng4-st1-seq3-ix2-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

#Indilog 
cp $BASE_DIR/machines_eng1-st3-seq3-ix1-deng2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
rm -rf $COLLECTION_DIR/indilog
mkdir -p $COLLECTION_DIR/indilog
./run_build.sh indilog indilog $CONTROLLER_SPEC_DIR/indilog/eng1-st3-seq3-ix1-is1-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
#ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

# Benchmark collected csv file
for s in $(echo $values | jq -r ".exp_variables | to_entries | map(\"\(.key)=\(.value|tostring)\") | .[]" $BASE_DIR/specs/exp-cf24.json); do
    export $s
done

$BENCHMARK_SCRIPT generate-plot \
    --file=$BASE_DIR/results/collection/time-vs-throughput-latency.csv \
    --relative-scale-ts=$RELATIVE_SCALE_TS \
    --relative-scaled-ts=$(<$COLLECTION_DIR/ts_scaled) \
    --result-file=$COLLECTION_DIR/scaling-time-vs-latency-throughput.png
