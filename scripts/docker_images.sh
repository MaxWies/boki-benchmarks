#!/bin/bash

ROOT_DIR=`realpath $(dirname $0)/..`

# Use BuildKit as docker builder
export DOCKER_BUILDKIT=1

function build_boki_deps {
    docker build -t maxwie/boki-deps:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.boki-deps \
        $ROOT_DIR/boki
}

function build_indilog_deps {
    docker build -t maxwie/indilog-deps:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.indilog-deps \
        $ROOT_DIR/indilog
}

function build_boki {
    cp $ROOT_DIR/config.mk $ROOT_DIR/boki
    docker build -t maxwie/boki:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.boki \
        $ROOT_DIR/boki
}

function build_indilog {
    cp $ROOT_DIR/config.mk $ROOT_DIR/indilog
    docker build -t maxwie/indilog:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.indilog \
        $ROOT_DIR/indilog
}

function build_boki_worker {
    docker build -t maxwie/boki-worker:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.boki-worker \
        $ROOT_DIR/boki
}

function build_indilog_worker {
    docker build -t maxwie/indilog-worker:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.indilog-worker \
        $ROOT_DIR/indilog
}

function build_microbench {
    docker build -t maxwie/indilog-microbench:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.microbench \
        $ROOT_DIR/workloads/micro
}

function build_queuebench {
    docker build -t maxwie/boki-queuebench:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.queuebench \
        $ROOT_DIR/workloads/queue
}

function build_retwisbench {
    docker build -t maxwie/boki-retwisbench:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.retwisbench \
        $ROOT_DIR/workloads/retwis
}

function build_beldibench {
    docker build --no-cache -t maxwie/boki-beldibench:thesis-sub \
        -f $ROOT_DIR/dockerfiles/Dockerfile.beldibench \
        $ROOT_DIR/workloads/workflow
}

function push_boki {
    docker push maxwie/boki:thesis-sub
}

function push_indilog {
    docker push maxwie/indilog:thesis-sub
}

function push_microbench {
    docker push maxwie/indilog-microbench:thesis-sub
}

function push_retwisbench {
    docker push maxwie/boki-retwisbench:thesis-sub
}

function push_beldibench {
    docker push maxwie/boki-beldibench:thesis-sub
}

function build {
    build_boki_deps
    build_indilog_deps
    build_boki
    build_indilog
    build_boki_worker
    build_indilog_worker
    build_microbench
    build_queuebench
    build_retwisbench
    build_beldibench
}

function push {
    docker push maxwie/boki:thesis-sub
    docker push maxwie/indilog:thesis-sub
    docker push maxwie/indilog-microbench:thesis-sub
    docker push maxwie/boki-queuebench:thesis-sub
    docker push maxwie/boki-retwisbench:thesis-sub
    docker push maxwie/boki-beldibench:thesis-sub
}

case "$1" in
build)
    build
    ;;
push)
    push
    ;;
deps)
    build_boki_deps
    build_indilog_deps
    ;;
boki)
    build_boki
    build_boki_worker
    push_boki
    ;;
indilog)
    build_indilog
    build_indilog_worker
    push_indilog
    ;;
micro)
    build_microbench
    push_microbench
    ;;
retwis)
    build_retwisbench
    push_retwisbench
    ;;
beldi)
    build_beldibench
    push_beldibench
esac
