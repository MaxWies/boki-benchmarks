module cs.utexas.edu/zjia/faas-retwis

go 1.14

require (
	cs.utexas.edu/zjia/faas v0.0.0
	cs.utexas.edu/zjia/faas/slib v0.0.0
	github.com/montanaflynn/stats v0.6.3
	go.mongodb.org/mongo-driver v1.4.6
)

// for container
replace cs.utexas.edu/zjia/faas => /src/slog/worker/golang
replace cs.utexas.edu/zjia/faas/slib => /src/slog/slib