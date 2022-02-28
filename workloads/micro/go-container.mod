module faas-micro

go 1.14

require (
	cs.utexas.edu/zjia/faas v0.0.0
	github.com/montanaflynn/stats v0.6.6
)

// for container
replace cs.utexas.edu/zjia/faas => /src/boki/worker/golang
replace cs.utexas.edu/zjia/faas/slib => /src/boki/slib