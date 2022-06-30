#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks
BENCHMARK_HELPER_SCRIPT=$ROOT_DIR/scripts/benchmark_helper

RESULT_DIR=$BASE_DIR/results
# rm -rf $RESULT_DIR
# mkdir -p \
#     $RESULT_DIR \
#     $RESULT_DIR/boki-local \
#     $RESULT_DIR/boki-remote \
#     $RESULT_DIR/indilog-normal-index \
#     $RESULT_DIR/indilog-small-index \
#     $RESULT_DIR/indilog-normal-index-min-completion \
#     $RESULT_DIR/indilog-small-index-min-completion

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Boki-Local
# cp $MACHINE_SPEC_DIR/boki/machines_eng4-st4-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir4-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Boki-Remote
# cp $MACHINE_SPEC_DIR/boki/machines_eng4-ei2-st4-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng4-ei2-st4-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# #Indilog
# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-normal-index $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh indilog-small-index $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh indilog-normal-index-min-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh indilog-small-index-min-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json

# Plotting
for FILE_TYPE in "pdf" "png";
do
    for SLOG in indilog-normal-index indilog-small-index; do
        # $BENCHMARK_SCRIPT generate-plot \
        #     --op-stats-csv-file=$RESULT_DIR/$SLOG/op-stats.csv \
        #     --client-csv-file=$BASE_DIR/$SLOG/client-results.csv \
        #     --result-file=$BASE_DIR/$SLOG/op-stats.png
        $BENCHMARK_HELPER_SCRIPT generate-operation-statistics-plot \
            --file=$RESULT_DIR/$SLOG/operations.csv \
            --result-file=$RESULT_DIR/$SLOG/operations.$FILE_TYPE
    done
done