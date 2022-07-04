#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
CONFIG_DIR=`realpath $ROOT_DIR/..`

cp $CONFIG_DIR/config.json $BASE_DIR

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

cp $BASE_DIR/machines_eng1-st1-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_once.sh $ROOT_DIR/controller-spec/eng1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp.json
