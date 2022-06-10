#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

SLOG=$1
NODE_TARGET=$2
CONTROLLER_SPEC_FILE=$3
EXP_SPEC_FILE=$4

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper
CONFIG_MAKER_SCRIPT=$ROOT_DIR/scripts/config_maker

CONTROLLER_SPEC_FILE_NAME=$(basename $CONTROLLER_SPEC_FILE .json)
EXP_SPEC_FILE_NAME=$(basename $EXP_SPEC_FILE .json)
EXP_DIR=$BASE_DIR/results/$SLOG/$CONTROLLER_SPEC_FILE_NAME/$EXP_SPEC_FILE_NAME

$CONFIG_MAKER_SCRIPT generate-runtime-config \
    --base-dir=$BASE_DIR \
    --slog=$SLOG \
    --controller-spec-file=$CONTROLLER_SPEC_FILE \
    --exp-spec-file=$EXP_SPEC_FILE

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ALL_HOSTS=`$HELPER_SCRIPT get-all-server-hosts --base-dir=$BASE_DIR`

$HELPER_SCRIPT generate-docker-compose --base-dir=$BASE_DIR
scp -q $BASE_DIR/docker-compose.yml $MANAGER_HOST:~
scp -q $BASE_DIR/docker-compose-generated.yml $MANAGER_HOST:~

ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

sleep 20

scp -q $ROOT_DIR/scripts/zk_setup.sh $MANAGER_HOST:/tmp/zk_setup.sh
ssh $MANAGER_HOST -- sudo mkdir -p /mnt/inmem/store

for host in $ALL_HOSTS; do
    scp -q $BASE_DIR/nightcore_config.json $host:/tmp/nightcore_config.json
done

ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
for HOST in $ALL_ENGINE_HOSTS; do
    scp -q $BASE_DIR/run_launcher $HOST:/tmp/run_launcher
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/slog
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/slog/output /mnt/inmem/slog/ipc /mnt/inmem/slog/stats
    ssh -q $HOST -- sudo cp /tmp/run_launcher /mnt/inmem/slog/run_launcher
    ssh -q $HOST -- sudo cp /tmp/nightcore_config.json /mnt/inmem/slog/func_config.json
done

if [[ $SLOG == boki-remote ]]; then
    ALL_INDEX_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=index_engine_node`
    for HOST in $ALL_INDEX_ENGINE_HOSTS; do
        scp -q $BASE_DIR/nightcore_config_empty.json $HOST:/tmp/nightcore_config_empty.json
        scp -q $BASE_DIR/run_launcher $HOST:/tmp/run_launcher
        ssh -q $HOST -- sudo rm -rf /mnt/inmem/slog
        ssh -q $HOST -- sudo mkdir -p /mnt/inmem/slog
        ssh -q $HOST -- sudo mkdir -p /mnt/inmem/slog/output /mnt/inmem/slog/ipc /mnt/inmem/slog/stats
        ssh -q $HOST -- sudo cp /tmp/run_launcher /mnt/inmem/slog/run_launcher
        ssh -q $HOST -- sudo cp /tmp/nightcore_config_empty.json /mnt/inmem/slog/func_config_empty.json
    done
fi

ALL_STORAGE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=storage_node`
for HOST in $ALL_STORAGE_HOSTS; do
    ssh -q $HOST -- sudo rm -rf   /mnt/storage/logdata
    ssh -q $HOST -- sudo mkdir -p /mnt/storage/logdata
done

ssh -q $MANAGER_HOST -- docker stack deploy -c ~/docker-compose-generated.yml -c ~/docker-compose.yml --resolve-image always boki-experiment
sleep 60

for HOST in $ALL_ENGINE_HOSTS; do
    ENGINE_CONTAINER_ID=`$HELPER_SCRIPT get-container-id --base-dir=$BASE_DIR --service faas-engine --machine-host $HOST`
    echo 4096 | ssh -q $HOST -- sudo tee /sys/fs/cgroup/cpu,cpuacct/docker/$ENGINE_CONTAINER_ID/cpu.shares
done

sleep 10

$BASE_DIR/run_client.sh $SLOG $NODE_TARGET $EXP_SPEC_FILE $EXP_DIR
