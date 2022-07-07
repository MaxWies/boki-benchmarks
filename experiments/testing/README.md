### About ###

Workloads that use a testing client which randomly mixes append and reads and checks if the responses are correct.
Wrong behavior of the system can be directly seen by looking at the client output.

### Competitors ###

* IndiLog

### Important Notes ###

* Log record caches are not enabled
* No collection of statistics
* Helpful for devleoping
* Subdirectory `system`: IndiLog runs with a fix number of active compute nodes
* Subdirectory `postpone`: Some of IndiLog's compute nodes are postponed and inactive at the beginning i.e., they register or build local indexes later