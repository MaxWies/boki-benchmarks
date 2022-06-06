#!/bin/bash

NETWORK_INTERFACE=$1
DURATION=$2
OUTPUT_FILE=$3

bash -ic "{ /usr/sbin/nethogs -t $NETWORK_INTERFACE &> $OUTPUT_FILE; \
    kill 0; } | { sleep $DURATION; \
    kill 0; }" 3>&1 2>/dev/null