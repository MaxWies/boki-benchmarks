#!/bin/bash

ROOT_DIR=`realpath $(dirname $0)/..`

# Use BuildKit as docker builder
export DOCKER_BUILDKIT=1

function build_boki {
    docker build -t maxwie/boki:latest \
        -f $ROOT_DIR/dockerfiles/Dockerfile.boki \
        $ROOT_DIR/boki
}

function build_microbench {
    docker build -t maxwie/indilog-microbench:latest \
        -f $ROOT_DIR/dockerfiles/Dockerfile.microbench \
        $ROOT_DIR/workloads/micro
}

function build_queuebench {
    docker build -t maxwie/boki-queuebench:latest \
        -f $ROOT_DIR/dockerfiles/Dockerfile.queuebench \
        $ROOT_DIR/workloads/queue
}

function build_retwisbench {
    docker build -t maxwie/boki-retwisbench:latest \
        -f $ROOT_DIR/dockerfiles/Dockerfile.retwisbench \
        $ROOT_DIR/workloads/retwis
}

function build_beldibench {
    docker build --no-cache -t maxwie/boki-beldibench:latest \
        -f $ROOT_DIR/dockerfiles/Dockerfile.beldibench \
        $ROOT_DIR/workloads/workflow
}

function push_microbench {
    docker push maxwie/indilog-microbench:latest
}

function push_retwisbench {
    docker push maxwie/boki-retwisbench:latest
}

function push_beldibench {
    docker push maxwie/boki-beldibench:latest
}

function build {
    build_boki
    build_microbench
    build_queuebench
    build_retwisbench
    build_beldibench
}

function push {
    docker push maxwie/boki:latest
    docker push maxwie/indilog-microbench:latest
    docker push maxwie/boki-queuebench:latest
    docker push maxwie/boki-retwisbench:latest
    docker push maxwie/boki-beldibench:latest
}

case "$1" in
build)
    build
    ;;
push)
    push
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
