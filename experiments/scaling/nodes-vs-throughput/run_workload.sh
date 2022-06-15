#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`
MACHINE_SPEC_DIR=$ROOT_DIR/machine-spec
CONTROLLER_SPEC_DIR=$ROOT_DIR/controller-spec

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
BENCHMARK_SCRIPT=$BASE_DIR/summarize_benchmarks

WORKLOAD=$1
export WORKLOAD

if [[ $WORKLOAD == empty-tag ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=100,0
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,0,0,0,0,100
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == one-tag-only ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=0,0,0,0,100
    export TAG_APPEND_PERCENTAGES=0,0,100
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
    export SHARED_TAGS_CAPACITY=1
elif [[ $WORKLOAD == new-tags-always ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=0,100
    export SEQNUM_READ_PERCENTAGES=0,0,0,0,100
    export TAG_APPEND_PERCENTAGES=100,0,0
    export TAG_READ_PERCENTAGES=0,100,0,0,0,0
    export SHARED_TAGS_CAPACITY=20
elif [[ $WORKLOAD == mix ]]; then
    export OPERATION_SEMANTICS_PERCENTAGES=50,50
    export SEQNUM_READ_PERCENTAGES=25,25,25,0,25
    export TAG_APPEND_PERCENTAGES=33,34,33
    export TAG_READ_PERCENTAGES=0,20,20,20,20,20
    export SHARED_TAGS_CAPACITY=20
else
    exit 1
fi

RESULT_DIR=$BASE_DIR/results/$WORKLOAD
# rm -rf $RESULT_DIR
# mkdir -p $RESULT_DIR

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Boki (hybrid because index replication is 1)
# cp $MACHINE_SPEC_DIR/boki/machines_eng2-st2-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-hybrid $CONTROLLER_SPEC_DIR/boki/eng2-st2-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf15.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# cp $MACHINE_SPEC_DIR/boki/machines_eng4-st4-seq3.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh boki-hybrid $CONTROLLER_SPEC_DIR/boki/eng4-st4-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf15.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

cp $MACHINE_SPEC_DIR/boki/machines_eng6-st6-seq3.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh boki-hybrid $CONTROLLER_SPEC_DIR/boki/eng6-st6-seq3-ir1-ur1-mr3.json $BASE_DIR/specs/exp-cf15.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# # Indilog (docker compose: postpone caching flag is 2,3,4,5,6 --> only node 1 exists at beginning)
# cp $MACHINE_SPEC_DIR/indilog/machines_eng2-st2-seq3-ix2-m1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng2-st2-seq3-ix2-m1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

# $HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
# sleep 90

# cp $MACHINE_SPEC_DIR/indilog/machines_eng4-st4-seq3-ix2-m1.json $BASE_DIR/machines.json
# $HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
# ./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng4-st4-seq3-ix2-m1-is2-ir1-ur1-mr3-ssmx4.json $BASE_DIR/specs/exp-cf15.json

$HELPER_SCRIPT reboot-machines --base-dir=$MACHINE_SPEC_DIR
sleep 90

cp $MACHINE_SPEC_DIR/indilog/machines_eng6-st6-seq3-ix2-m1.json $BASE_DIR/machines.json
$HELPER_SCRIPT start-machines --base-dir=$BASE_DIR
./run_build.sh indilog $CONTROLLER_SPEC_DIR/indilog/eng6-st6-seq3-ix2-m1-is2-ir1-ur1-mr3-ssmx6.json $BASE_DIR/specs/exp-cf15.json

for FILE_TYPE in "pdf" "png";
do
    $BENCHMARK_SCRIPT generate-plot \
        --file=$RESULT_DIR/nodes-vs-throughput.csv \
        --workload=$WORKLOAD \
        --result-file=$RESULT_DIR/nodes-vs-throughput.$FILE_TYPE
done
