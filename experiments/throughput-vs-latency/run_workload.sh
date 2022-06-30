#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

WORKLOAD=$1
APPEND_TIMES=$2
READ_TIMES=$3

export WORKLOAD=$WORKLOAD
export APPEND_TIMES=$APPEND_TIMES
export READ_TIMES=$READ_TIMES

if [[ $WORKLOAD == mix ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=50,50
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=33,34,33
    export TAG_READ_PERCENTAGES=0,20,20,20,20,20
elif [[ $WORKLOAD == new-tags-read-min-always ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,0,0,0,100,0
else
    exit 1
fi

RESULT_DIR=$BASE_DIR/results/$WORKLOAD-$APPEND_TIMES-$READ_TIMES

# rm -rf $RESULT_DIR
# mkdir -p $RESULT_DIR

# Boki
# cp $MACHINE_SPEC_DIR/boki/machines_eng2-st2-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf80.json
# ./run_build.sh boki-local $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf160.json

# Boki-Remote
#cp $MACHINE_SPEC_DIR/boki/machines_eng2-ei2-st2-seq3.json $BASE_DIR/machines.json
#$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
#./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf1.json
#./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf80.json
# ./run_build.sh boki-remote $CONTROLLER_SPEC_DIR/boki/eng2-ei2-st2-seq3-ir2-ur1-mr3.json $BASE_DIR/specs/exp-cf160.json


# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Indilog
# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf1.json
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf2.json
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf4.json
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf12.json
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Indilog Min Seqnum Completion
# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-agg1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog-min-seqnum-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf1.json
# ./run_build.sh indilog-min-seqnum-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf2.json
# ./run_build.sh indilog-min-seqnum-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf4.json
# ./run_build.sh indilog-min-seqnum-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh indilog-min-seqnum-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf12.json
# ./run_build.sh indilog-min-seqnum-completion $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-agg1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# Indilog-Remote
#cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2.json $BASE_DIR/machines.json
#$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
#./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf1.json
#./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf8.json
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf24.json
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf80.json
# ./run_build.sh indilog-remote $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf160.json

# Benchmark collected csv file
for FILE_TYPE in "pdf" "png";
do
    # $BENCHMARK_SCRIPT generate-plot-boki-vs-indilog-append --file=$RESULT_DIR/throughput-vs-latency.csv --result-file=$RESULT_DIR/throughput-vs-latency-append-local.$FILE_TYPE
    # $BENCHMARK_SCRIPT generate-plot-boki-vs-indilog-read --file=$RESULT_DIR/throughput-vs-latency.csv --result-file=$RESULT_DIR/throughput-vs-latency-read-local.$FILE_TYPE
    # $BENCHMARK_SCRIPT generate-plot-boki-remote-vs-indilog-remote-read --file=$RESULT_DIR/throughput-vs-latency.csv --result-file=$RESULT_DIR/throughput-vs-latency-read-remote.$FILE_TYPE
    $BENCHMARK_SCRIPT generate-plot-indilog-vs-indilog-min-seqnum-completion-append --file=$RESULT_DIR/throughput-vs-latency.csv --result-file=$RESULT_DIR/throughput-vs-latency-append.$FILE_TYPE
    $BENCHMARK_SCRIPT generate-plot-indilog-vs-indilog-min-seqnum-completion-read --file=$RESULT_DIR/throughput-vs-latency.csv --result-file=$RESULT_DIR/throughput-vs-latency-read.$FILE_TYPE
done
