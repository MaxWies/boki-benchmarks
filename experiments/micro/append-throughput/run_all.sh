#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
CONFIG_DIR=`realpath $ROOT_DIR/..`

cp $CONFIG_DIR/config.json $BASE_DIR

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR

# <script> <target-directory> <concurrent-connections> <duration> <benchmark-op> <record-length-per-op>
$BASE_DIR/run_once.sh con2 2 20 AppendToLogLoopAsync 1024