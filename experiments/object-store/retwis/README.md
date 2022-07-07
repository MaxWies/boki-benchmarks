### About ###

Retwis is a Twitter clone. It provides functions to login users, publish tweets, show timelines and see user profiles. 

### Competitors ###

* IndiLog: IndiLog with default settings similar to other experiments
* IndiLog-Small-Index: Local indexes are very small (around 0.2 MB is the limit)
* Boki: Boki with complete local indexes
* Boki-Remote: Boki has two compute nodes with complete indexes that do not run functions. The other compute nodes run functions but maintain no local index and must do remote index look-ups.

### Important Notes ###

* In Boki-Remote local indexes in Boki are disabled for those compute nodes that run functions
* Log record caches are enabled
* Statistics are collected by the log engines and by the client which sends HTTP requests to the gateway
* Before the workload starts the library is initialized and users are created
* Multiple requests during the workload may fail due to transaction conflicts
