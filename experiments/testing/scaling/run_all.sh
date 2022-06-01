#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

cp $BASE_DIR/machines_eng1-st3-seq3-ix1-deng2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng1-st3-seq3-ix1-is1-ir1-ur1-mr3-ssmx4-sr1.json $BASE_DIR/specs/exp-cf24.json