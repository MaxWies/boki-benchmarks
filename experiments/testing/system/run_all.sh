#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # # echo "Run benchmarks for engine:2 storage:2 sequencer:3 index-shards:2 index-replication:1"
cp $MACHINE_SPEC_DIR/indilog/machines_eng3-st3-seq3-ix4-m1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng3-st3-seq3-ix4-m1-is2-ir2-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json

