#!/bin/bash

PNAME="$1"
SAMPLE_RATE="$2"
SAMPLES="$3"
LOG_FILE="$4"
PID=$(pidof ${PNAME})

top -b -d $SAMPLE_RATE -n $SAMPLES -p $PID | awk \
    -v cpuLog="$LOG_FILE" -v pid="$PID" -v pname="$PNAME" '
    /^top -/{time = $3}
    $1+0>0 {printf "%s,%s,%s,%s,%d,%d\n", \
            strftime("%Y-%m-%d"), time, pname, pid, $9, $10 > cpuLog
            fflush(cpuLog)}'