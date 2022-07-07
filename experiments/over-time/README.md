### About ###

We evaluate the behavior of the system over a long period of time. We look at throughput and latencies over time.

### Competitors ###

* IndiLog: Default setting of IndiLog that uses distributed indexing
* Boki: Boki with complete local indexes

### Important Notes ###

* No log record caches
* Statistics are collected by the log engines
* This experiment produces a lot of data as benchmarks run over a long period. Be sure beforehand that your Manager VM is able to persist all benchmark data temporarily after the run as it processes and combines them for visualiztion. Depending on the workload and time the machine may need up to 10 GB.
* Boki can crash eventually due to out-of-memory in compute nodes, e.g., an index-heavy leads to a crash of Boki after 10 minutes
* Boki and IndiLog can crash eventually due to disc limits in storage nodes, e.g., for mixed workload storage nodes with 100GB disk space reach their capacity limits after 35 minutes  
