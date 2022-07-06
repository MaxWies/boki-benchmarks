### About ###

Evaluates the index tier of IndiLog. We look at the cumulative distribution of latencies. We evaluate type-2 reads and type-3 reads.

* type-2 read: One of the index nodes has an exact match for the index lookup and can forward the read request to the storage tier
* type-3 read: None of the index nodes has an exact match for the index lookup and the aggregator takes the 'best' value to locate the storage shard to which it forwards the read request

### Competitors ###

* IndiLog: IndiLog uses aggregator(s) to aggregate results from index nodes
* Boki-Remote: Boki has two compute nodes with complete indexes that do not run functions. The other compute nodes run functions but maintain no local index and must do remote index look-ups.

### Important Notes ###

* Local Indexes in IndiLog are disabled
* Local Indexes in Boki are disabled for those compute nodes that run functions
* No log record caches
* Statistics are collected by the log engines 
* The benchmark uses the following encoding X-Y-Z-type2Read?. X is the number of index shards, Y the replication factor, Z the number of aggregators, Type2Read? is a boolean to determine whether the benchmark uses type-2 or type-3 reads. E.g. 2-1-1-true means 2 index shards, single replication (1), 1 aggregator and type-2 reads
