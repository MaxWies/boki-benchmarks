#!/bin/bash

./run_workload.sh mix 1 1
#./run_workload.sh 19 1 mix  # write heavy
#./run_workload.sh 1 19 mix  # read heavy
./run_workload.sh new-tags-read-min-always 1 1
