#!/bin/bash

./run_workload.sh 1 1
./run_workload.sh 19 1      # write heavy
./run_workload.sh 1 19      # read heavy
