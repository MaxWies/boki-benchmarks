#!/bin/bash

./run_workload.sh mix
./run_workload.sh mix-read-heavy
./run_workload.sh against-us
./run_workload.sh against-us-read-heavy
./run_workload.sh mix-low-concurrency
./run_workload.sh mix-with-registration
