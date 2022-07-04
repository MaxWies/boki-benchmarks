module github.com/eniac/Beldi

go 1.14

require (
	cs.utexas.edu/zjia/faas v0.0.0
	github.com/aws/aws-lambda-go v1.19.1
	github.com/aws/aws-sdk-go v1.34.6
	github.com/cespare/xxhash/v2 v2.1.1
	github.com/dgrijalva/jwt-go v3.2.0+incompatible
	github.com/google/uuid v1.1.1 // indirect
	github.com/hailocab/go-geoindex v0.0.0-20160127134810-64631bfe9711
	github.com/lithammer/shortuuid v3.0.0+incompatible
	github.com/mitchellh/mapstructure v1.3.3
	github.com/golang/snappy v0.0.2
)

// for container
replace cs.utexas.edu/zjia/faas => /src/slog/worker/golang