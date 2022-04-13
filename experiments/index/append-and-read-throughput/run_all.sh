#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

echo "Run benchmarks for engine:1 storage:1 sequencer:3 index:1"
cp $BASE_DIR/machines_eng1-st1-seq3-ix1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_once.sh $BASE_DIR/specs/eng1-st1-seq3-ix1.json $BASE_DIR/specs/exp-cf8-append-only.json
./run_once.sh $BASE_DIR/specs/eng1-st1-seq3-ix1.json $BASE_DIR/specs/exp-cf8-append-1-read-9.json