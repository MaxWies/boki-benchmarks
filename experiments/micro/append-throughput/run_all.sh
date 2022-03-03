#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
CONFIG_DIR=`realpath $ROOT_DIR/..`

BENCHMARK=$(basename "$PWD")
HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

CONFIGURATION=$BENCHMARK-eng1-st1-seq3
echo "Run benchmarks for $CONFIGURATION"
cp $CONFIG_DIR/config_$CONFIGURATION.json $BASE_DIR/config.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
$BASE_DIR/run_once.sh $CONFIGURATION $BENCHMARK 320 20 1024
$BASE_DIR/run_once.sh $CONFIGURATION $BENCHMARK 640 20 1024

CONFIGURATION=$BENCHMARK-eng4-st1-seq3
echo "Run benchmarks for $CONFIGURATION"
cp $CONFIG_DIR/config_$CONFIGURATION.json $BASE_DIR/config.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
$BASE_DIR/run_once.sh $CONFIGURATION $BENCHMARK 320 20 1024
$BASE_DIR/run_once.sh $CONFIGURATION $BENCHMARK 640 20 1024