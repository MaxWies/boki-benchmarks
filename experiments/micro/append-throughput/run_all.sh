#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
CONFIG_DIR=`realpath $ROOT_DIR/..`

BENCHMARK=$(basename "$PWD")
HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

BOKI_SETTING="eng1-st1-seq3"
CONFIGURATION=$BENCHMARK-$BOKI_SETTING
echo "Run benchmarks for $CONFIGURATION"
cp $CONFIG_DIR/config_$CONFIGURATION.json $BASE_DIR/config.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
$BASE_DIR/run_once.sh $BOKI_SETTING $BENCHMARK 320 20 1024
# $BASE_DIR/run_once.sh $BOKI_SETTING $BENCHMARK 640 20 1024

BOKI_SETTING="eng4-st1-seq3"
CONFIGURATION=$BENCHMARK-$BOKI_SETTING
echo "Run benchmarks for $CONFIGURATION"
# cp $CONFIG_DIR/config_$CONFIGURATION.json $BASE_DIR/config.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# $BASE_DIR/run_once.sh $BOKI_SETTING $BENCHMARK 320 20 1024
# $BASE_DIR/run_once.sh $BOKI_SETTING $BENCHMARK 640 20 1024