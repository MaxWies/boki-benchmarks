#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

cp $ROOT_DIR/scripts/run_once.sh run_once.sh

echo "Run benchmarks for engine:1 storage:1 sequencer:3"
cp $BASE_DIR/machines_eng1-st1-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_once.sh $BASE_DIR/specs/eng1-st1-seq3.json $BASE_DIR/specs/exp-cf320.json
./run_once.sh $BASE_DIR/specs/eng1-st1-seq3.json $BASE_DIR/specs/exp-cf640.json
./run_once.sh $BASE_DIR/specs/eng1-st1-seq3.json $BASE_DIR/specs/exp-cf1280.json
./run_once.sh $BASE_DIR/specs/eng1-st1-seq3.json $BASE_DIR/specs/exp-cf2560.json

echo "Run benchmarks for engine:4 storage:1 sequencer:3"
cp $BASE_DIR/machines_eng4-st1-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_once.sh $BASE_DIR/specs/eng4-st1-seq3.json $BASE_DIR/specs/exp-cf320.json
./run_once.sh $BASE_DIR/specs/eng4-st1-seq3.json $BASE_DIR/specs/exp-cf640.json
./run_once.sh $BASE_DIR/specs/eng4-st1-seq3.json $BASE_DIR/specs/exp-cf1280.json
./run_once.sh $BASE_DIR/specs/eng4-st1-seq3.json $BASE_DIR/specs/exp-cf2560.json