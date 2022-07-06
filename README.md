Benchmark workloads of [Indilog](https://github.com/MaxWies/IndiLog) and [Boki](https://github.com/ut-osa/boki)
==================================

This repository includes evaluation workloads of Indilog and Boki,
and scripts for running experiments.

### Structure of this repository ###

* `controller-spec`: specifications for the controller in IndiLog and Boki which can be reused for different experiments.
* `dockerfiles`: dockerfiles for building relevant Docker containers.
* `experiments`: setup scripts for running experiments of individual workloads and visualization scripts for the results.
* `machine-spec`: specifications for the machines in IndiLog and Boki. This folder contains only templates for real machine configuration files.
* `scripts`: helper scripts to build Docker containers, generate experiment configurations and support the experiment flow.
* `workloads`: contains libraries and their workloads

## Setup ##

### Hardware and software dependencies ###

For our experiments we use internally hosted VMs.

Our VMs use Ubuntu 20.04 with kernel version 5.10.0. You must use a kernel version >= 5.10.0 because IndiLog and Boki use `io_uring`.

### Experiment VMs ###

Our VMs that are used as nodes in Indilog and Boki, respectively have installed Docker and use the following packages: g++ make cmake pkg-config autoconf automake libtool curl unzip ca-certificates gnupg lsb-release iperf3 netperf iftop

Note that some of the packages are used for benchmarking the system.

To avoid issues with io_uring due to memory bounds we changed the ulimit on the VMs and set `max locked memory` and `max memory size` to `unlimited`.

For the experiment `workflow` you need to install [wrk2](https://github.com/giltene/wrk2) on the client machines.

### Manager VM ###

A single Manager VM is responsible for conducting experiments and combining the results. It uses the following packages: python3 python3-pip docker-compose default-jre

Python in the Manager VM needs the following packages: numpy matplotlib pandas

### Environment setup ###

We use ssh with public/private key-pairs for authentication. The Manager VM can access all Experiment VMs via ssh. All Experiment machines use a user with sudo rights and with the same name. We setup ssh between the Manager VM and the Experiment VMs such that the Manager VM can run remote commands by running `ssh $IP-EXPERIMENT-VM_$USERNAME -- <command>`.

## Experiment workflow ##

Each sub-directory within `experiments` corresponds to one experiment.

Within each experiment there are two subfolders: `config` and `compose`
* `config`: files in these directories are used to configure the experiment in a declarative way
* `compose`: files in these directories describe different docker compose configurations

Each experiment folder has a file called `functions.json`. It contains the serverless functions with their specifications for the experiment.

The workflow is in general the same for all experiments: 

* `run_all.sh`: grabs the machine specification from `machine-spec`, builds the docker swarm and starts the experiment. After the experiment it visualizes the results.
* `run_workload.sh`: exists in some directories to setup finer grained workloads.
* `run_build.sh` : creates the necessary configuration files from the template and builds the docker stack
* `run_client.sh`: runs the workload and combines (csv|json) result files from nodes

When an experiment starts `scripts/config_maker` generates in `run_build.sh` the necessary configuration files: These include the final docker-compose file (`docker-compose.yaml`), the deployment specification of services in docker swarm (`docker-compose-generated.yaml`) and the configuration of the serverless functions in nightcore (`nightcore_config.json`).

`run_client` exports environment variables that are described in the provided specification file in `config`. This allows for finer-grained settings and to play around with different settings to play around without the need to add new benchmark code.

## Collecting Statistics ##

There are four different layers on which we can collect statistics: client, gateway, function containers, log engines.

On which layer we collect statistics depends on the experiment. For most of the experiments we collect statistics on the log engine level.

#### Client #### 
The client measures latencies and throughput.

#### Gateway ####
The gateway timestamps the start of a request and saves the duration when it receives the response from the system.

#### Function Containers ####
Function workers of containers collect metrics, e.g. successful calls, latencies etc. After the benchmark the metrics are merged across function workers and then merged across containers to get the final statistics.

#### Log Engine Level ####
Log engines collect statistics in csv format, e.g. latencies, append and read calls etc. After the benchmark the Manager VM gets the statistic files, combines them and finally visualize them. Note that log engines produce a lot of statistics data. The Manager VM must have enough disk space (multiple GB) to store the data. 

Log engines run a thread that continously writes data to files. A zookeeper command is send by the Manager VM to activate the thread on all log engines: `create /faas/stat/start $ENGINE_STAT_THREAD_INTERVAL`. The implementation for statistic collection in log engines uses pre-compile statements. If you extend IndiLog Or Boki and would like to use statistic collection compile the source code with the arguments in `config.mk`  

## Common Issues ##

### Docker Swarm ###

We encountered issues with docker swarm for IndiLog and Boki, respectively that lead to an invalid setup of the system. Moreover, we observed sometimes that processes that use io_uring are not cleaned up properly after termination. To minimize the likelihood of issues we reboot all VMs (`scripts/exp_helper reboot-machines --base-dir=$MACHINE_SPEC_DIR`) before starting an experiment. `$MACHINE_SPEC_DIR` specifies the directory location of the machine-spec file `machines.json`

If you run many experiments over several weeks on the same VMs consider to prune docker on all experiment VMs (`scripts/exp_helper prune-docker --base-dir=$MACHINE_SPEC_DIR`). This frees a lot of disk space.

In our setup we have a main machine-spec file `machine-spec/machines.json`. This file contains all our VMs. We use this file when we want to apply a command on all VMs.
