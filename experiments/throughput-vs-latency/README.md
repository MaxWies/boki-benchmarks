### About ###

Evaluates the latency as a function of throughput. Each competitor runs multiple times. Each time with a higher load (higher concurrency).

### Competitors ###

* IndiLog: Default setting of IndiLog that uses distributed indexing
* IndiLog-Remote: Compute nodes do not maintain local indexes and all lookups are handled by the index tier
* IndiLog-Min-Seqnum-Completion: Indilog uses distributed indexing and identifies new tags
* Boki: Boki with complete local indexes
* Boki-Remote: Some compute nodes with complete indexes but do not run functions. The other compute nodes run functions but have no local index and must do remote index look-ups.

### Important Notes ###

* No log record caches
* Statistics are collected by the log engines
* This experiments includes many competitors with many runs. Comment out those competitors and runs which are not of interest for you
