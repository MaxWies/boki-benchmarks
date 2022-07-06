### About ###

Evaluates the scalability of the compute tier. Scaling is done after 30 seconds. We look at the total throughput after scaling happened. 

### Competitors ###

* IndiLog: Starts with one compute node and scales to 2|4|6
* Boki-Hybrid: One compute node maintains a complete local index. The other compute nodes (1|3|5) must send remote index look-ups

### Important Notes ###

* Since Boki cannot dynamically scale, it is already started in the (2|4|6)-node configuration where it would end up if it was able to dynamically scale
* No log record caches
* Statistics are collected by the log engines
* For scaling, IndiLog receives a Zookeeper command that triggers IndiLog to activate the additional compute nodes
