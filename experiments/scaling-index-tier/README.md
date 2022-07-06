### About ###

Evaluates the scalability of the index tier. We look at the cumulative distribution of latencies. 

### Competitors ###

* IndiLog with aggregator: IndiLog uses aggregator(s) to aggregate results from index nodes
* IndiLog using master-slave: No aggregators. An index node is the master the others are the slaves. The master aggregates results from the slave

### Important Notes ###

* Local Indexes in IndiLog are disabled
* No log record caches
* Statistics are collected by the log engines
* Workload has only type-3 reads i.e., index lookups for which the aggregator|master forwards the read request to the storage tier
* The benchmark uses the following encoding X-Y-Z-type2Read?. X is the number of index shards, Y the replication factor, Z the number of aggregators, Type2Read? is a boolean to determine whether the benchmark uses type-2 or type-3 reads. E.g. 6-1-2-false means 6 index shards, single replication (1), 2 aggregators and type-3 reads
