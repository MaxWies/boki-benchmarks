#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

echo "Run benchmarks for engine:1->4 storage:1 sequencer:3 index-shards:2 index-replication:1"
#cp $BASE_DIR/machines_eng4-st1-seq3-ix2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_once.sh $CONTROLLER_SPEC_DIR/ei1-st1-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24-avhosts3.json
