#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../../..`
CONFIG_DIR=$ROOT_DIR/..

cp $CONFIG_DIR/config.json BASE_DIR

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR

$BASE_DIR/run_once.sh con320 320 append
$BASE_DIR/run_once.sh con640 640 append
$BASE_DIR/run_once.sh con1280 1280 append
$BASE_DIR/run_once.sh con2560 2560 append