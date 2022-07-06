### About ###

Evaluates the scalability of the compute tier. Scaling is done after 30 seconds. We look at the total throughput after scaling happened. 

### Competitors ###

* IndiLog: Starts with one compute node and scales to four
* Boki-Hybrid: One compute node maintains a complete local index. The other compute nodes must send remote index look-ups

### Important Notes ###

* Since Boki cannot dynamically scale, it is already started in the 4-node configuration where it would end up if it was able to dynamically scale
* No log record caches
* For scaling, IndiLog receives a Zookeeper command that triggers IndiLog to activate the additional compute nodes 