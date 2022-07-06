### About ###

Evaluates the scalability of the compute tier. Scaling is done after 30 seconds. We look at the append & read latencies and the total throughput after scaling happened. This benchmark has an extension to evaluate IndiLog's registration protocol. 

### Competitors ###

* IndiLog: Starts with one compute node and scales to four
* IndiLog with registration: Starts with one compute node and scales to four. New compute nodes must register first
* Boki-Hybrid: One compute node maintains a complete local index. The other compute nodes must send remote index look-ups

### Important Notes ###

* Since Boki cannot dynamically scale, it is already started in the 4-node configuration where it would end up if it was able to dynamically scale
* No log record caches
* Statistics are collected by the log engines
* For scaling, IndiLog receives a Zookeeper command that triggers IndiLog to activate|register the additional compute nodes
