module faas-micro

go 1.14

require (
	cs.utexas.edu/zjia/faas v0.0.0
	github.com/google/uuid v1.3.0
	github.com/montanaflynn/stats v0.6.6
)

replace cs.utexas.edu/zjia/faas => ../../indilog/worker/golang

replace cs.utexas.edu/zjia/faas/slib => ../../indilog/slib
