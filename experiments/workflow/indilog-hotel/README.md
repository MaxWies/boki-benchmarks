### About ###

IndiLog hotel reuses the workload from [Beldi](https://github.com/ut-osa/boki-benchmarks/tree/main/workloads/workflow/beldi/internal/hotel) and [Boki](https://github.com/ut-osa/boki-benchmarks/tree/main/workloads/workflow/boki/internal/hotel). It provides functions to book hotels, rate services, etc.

### Competitors ###

* IndiLog: IndiLog with default settings similar to other experiments
* IndiLog-Min-Completion: Computes nodes of IndiLog identifiy new tags
* Boki: Boki with complete local indexes

### Important Notes ###

* Log record caches are enabled
* Statistics are collected by the log engines and by the gateway which timestamps incoming requests
* The experiment uses a local DynamoDB instance. It runs on an own VM
* The client needs to have installed wrk2 to produce a constant throughput load
