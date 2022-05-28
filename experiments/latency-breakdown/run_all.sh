#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`

COLLECTION_DIR=$BASE_DIR/results/collection
rm -rf $COLLECTION_DIR
mkdir -p $COLLECTION_DIR

# Machine config 1: Boki-Local
cp $BASE_DIR/machines_eng2-st2-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki 'Boki-Local|NoTags' $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf4-no-tags.json
./run_build.sh boki 'Boki-Local|Tags' $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf4-tags.json

ssh -q $MANAGER_HOST -- docker stack rm boki-experiment
sleep 20

# Machine config 1: Boki-Remote
cp $BASE_DIR/machines_eng2-ei1-st2-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki 'Boki-Remote|NoTags' $CONTROLLER_SPEC_DIR/boki/eng2-ei1-st2-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf4-tags.json
./run_build.sh boki 'Boki-Remote|Tags' $CONTROLLER_SPEC_DIR/boki/eng2-ei1-st2-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf4-tags.json

ssh -q $MANAGER_HOST -- docker stack rm boki-experiment
sleep 20

# Machine config 3: Indilog
cp $BASE_DIR/machines_eng2-st2-seq3-ix1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog 'Indilog|NoTags' $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix1-is1-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf4-no-tags.json
./run_build.sh indilog 'Indilog|Tags' $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix1-is1-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf4-tags.json

# Benchmark collected csv file
$BENCHMARK_SCRIPT generate-plot --directory=$COLLECTION_DIR --file=$BASE_DIR/results/throughput-vs-latency.csv --result-file=$COLLECTION_DIR/latency-cdf.png