#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

echo "Run benchmarks for engine:1 storage:1 sequencer:3"
cp $BASE_DIR/machines_eng1-st1-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
$BASE_DIR/run_once.sh $BASE_DIR/specs/spec_eng1-st1-seq3_cf320.json
$BASE_DIR/run_once.sh $BASE_DIR/specs/spec_eng1-st1-seq3_cf640.json
$BASE_DIR/run_once.sh $BASE_DIR/specs/spec_eng1-st1-seq3_cf1280.json
$BASE_DIR/run_once.sh $BASE_DIR/specs/spec_eng1-st1-seq3_cf2560.json

echo "Run benchmarks for engine:3 storage:1 sequencer:3"
cp $BASE_DIR/machines_eng3-st1-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
$BASE_DIR/run_once.sh $BASE_DIR/specs/spec_eng3-st1-seq3_cf320.json
$BASE_DIR/run_once.sh $BASE_DIR/specs/spec_eng3-st1-seq3_cf640.json
$BASE_DIR/run_once.sh $BASE_DIR/specs/spec_eng3-st1-seq3_cf1280.json
$BASE_DIR/run_once.sh $BASE_DIR/specs/spec_eng3-st1-seq3_cf2560.json