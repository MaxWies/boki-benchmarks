#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

EXP_DIR=$BASE_DIR/results/$1

CONCURRENCY=$2
DURATION=$3
MICROBENCHMARK_TYPE=$4
RECORD_LENGTH=$5

HELPER_SCRIPT=$ROOT_DIR/scripts/exp_helper

MANAGER_HOST=`$HELPER_SCRIPT get-docker-manager-host --base-dir=$BASE_DIR`
CLIENT_HOST=`$HELPER_SCRIPT get-client-host --base-dir=$BASE_DIR`
ENTRY_HOST=`$HELPER_SCRIPT get-service-host --base-dir=$BASE_DIR --service=boki-gateway`
ALL_HOSTS=`$HELPER_SCRIPT get-all-server-hosts --base-dir=$BASE_DIR`

$HELPER_SCRIPT generate-docker-compose --base-dir=$BASE_DIR
scp -q $BASE_DIR/docker-compose.yml $MANAGER_HOST:~
scp -q $BASE_DIR/docker-compose-generated.yml $MANAGER_HOST:~

ssh -q $MANAGER_HOST -- docker stack rm boki-experiment

sleep 40

scp -q $ROOT_DIR/scripts/zk_setup.sh $MANAGER_HOST:/tmp/zk_setup.sh
ssh $MANAGER_HOST -- sudo mkdir -p /mnt/inmem/store

for host in $ALL_HOSTS; do
    scp -q $BASE_DIR/nightcore_config.json $host:/tmp/nightcore_config.json
done

ALL_ENGINE_HOSTS=`$HELPER_SCRIPT get-machine-with-label --base-dir=$BASE_DIR --machine-label=engine_node`
for HOST in $ALL_ENGINE_HOSTS; do
    scp -q $BASE_DIR/run_launcher $HOST:/tmp/run_launcher
    ssh -q $HOST -- chmod +x /tmp/run_launcher
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki/output /mnt/inmem/boki/ipc
    ssh -q $HOST -- sudo cp /tmp/run_launcher /mnt/inmem/boki/run_launcher
    ssh -q $HOST -- sudo cp /tmp/nightcore_config.json /mnt/inmem/boki/func_config.json
done

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

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

ssh -q $CLIENT_HOST -- docker run \
    --pull always \
    -v /tmp:/tmp \
    maxwie/boki-microbench:latest \
    cp /microbench-bin/benchmark /tmp/benchmark

ssh -q $CLIENT_HOST -- /tmp/benchmark \
    --faas_gateway=$ENTRY_HOST:8080 \
    --duration=$DURATION \
    --concurrency=$CONCURRENCY \
    --microbenchmark_type=$MICROBENCHMARK_TYPE \
    >$EXP_DIR/results.log

sleep 10

$HELPER_SCRIPT collect-container-logs --base-dir=$BASE_DIR --log-path=$EXP_DIR/logs
