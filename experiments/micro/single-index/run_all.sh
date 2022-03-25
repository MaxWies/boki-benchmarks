#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

cp $BASE_DIR/machines_eng1-ei1-st1-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_once.sh $CONTROLLER_SPEC_DIR/eng1-ei1-st1-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json