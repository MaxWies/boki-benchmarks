Benchmark workloads of [Indilog](https://github.com/MaxWies/IndiLog) and [Boki](https://github.com/ut-osa/boki)
==================================

This repository includes evaluation workloads of Indilog and Boki,
and scripts for running experiments.

### Structure of this repository ###

* `controller-spec`: Specifications for the controller in IndiLog and Boki which can be reused for different experiments.
* `dockerfiles`: Dockerfiles for building relevant Docker containers.
* `experiments`: setup scripts for running experiments of individual workloads and visualization scripts for the results.
* `machine-spec`: Specifications for the machines in IndiLog and Boki. This folder contains only a template for a machine configuration file. It is the directory to store machine configuration files for the experiments.
* `scripts`: helper scripts for building Docker containers, build experiment configurations and support the experiment flow.

### Hardware and software dependencies ###

For our experiments we use internally hosted VMs.

Our VMs use Ubuntu 20.04 with kernel version 5.10.0.

Our VMs that are used as nodes in Indilog and Boki respectively need a Docker installation and use the following packages: g++ make cmake pkg-config autoconf automake libtool curl unzip ca-certificates gnupg lsb-release iperf3 netperf iftop

Note that some of the packages are used for benchmarking the system.

A single 'Manager' VM is responsible for conducting experiments and combining the results. It uses the following packages: python3 python3-pip docker-compose default-jre

Python in the 'Manager' VM needs the following packages: numpy matplotlib pandas

### Environment setup ###

#### Setting up the Manager machine ####

### Experiment workflow ###

Each sub-directory within `experiments` corresponds to one experiment.

Within each experiment there are two subfolders: `config` and `compose`
* `config`: files in these directories are used to configure the experiment in a declarative way
* `compose`: files in these directories describe different docker compose configurations

Each experiment folder has a file called `functions.json`. It contains the serverless functions and their specifications for the experiment.

When an experiment is started the `config_maker` in the scripts directory builds the necessary configuration files: These include the docker-compose files for docker swarm, the service specification for docker swarm and the configuration of the serverless functions.

The workflow is in general the same for all experiments: 

* `run_all`: grabs the machine specification from `machine-spec` and starts the experiment. After the experiment it visualizes the results.
* `run_workload`: exists in some directories to setup finer grained workloads.
* `run_build` : creates the necessary configuration files from the template and builds the docker swarm
* `run_client`: runs the workload and combines (csv|json) result files from nodes
