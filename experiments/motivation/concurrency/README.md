### About ###

Evaluates the latencies and the throughput for an increasing load in the system (higher concurrency).

### Competitors ###

* Boki: Boki with complete local indexes
* Boki-Hybrid: One compute node maintains a complete local index. The other compute nodes must send remote index look-ups
* Boki-Remote: Some compute nodes have complete indexes but do not run functions. The other compute nodes run functions but have no local index and must do remote index look-ups.

### Important Notes ###

* Log record caches are activated
* Statistics are collected by the log engines and by scripts on compute nodes and storage nodes that continously record CPU and RAM use
