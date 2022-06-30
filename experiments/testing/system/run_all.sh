#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
./run_build.sh indilog-index-tier-only $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
./run_build.sh indilog-min-seqnum-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog-index-tier-only-master-slave $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json