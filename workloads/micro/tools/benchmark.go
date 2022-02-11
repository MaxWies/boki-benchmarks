package main

import (
	"flag"
	"fmt"
	"log"
	"math/rand"
	"time"

	"cs.utexas.edu/zjia/faas-micro/utils"
)

var FLAGS_faas_gateway string
var FLAGS_fn_prefix string
var FLAGS_num_users int
var FLAGS_concurrency int
var FLAGS_duration int
var FLAGS_percentages string
var FLAGS_bodylen int
var FLAGS_rand_seed int
var FLAGS_microbenchmark_type string

const (
	Append        string = "append"
	AppendAndRead string = "appendAndRead"
	Read          string = "read"
)

func init() {
	flag.StringVar(&FLAGS_faas_gateway, "faas_gateway", "127.0.0.1:8081", "")
	flag.StringVar(&FLAGS_fn_prefix, "fn_prefix", "", "")
	flag.IntVar(&FLAGS_num_users, "num_users", 1000, "")
	flag.IntVar(&FLAGS_concurrency, "concurrency", 1, "")
	flag.IntVar(&FLAGS_duration, "duration", 10, "")
	flag.IntVar(&FLAGS_rand_seed, "rand_seed", 23333, "")
	flag.StringVar(&FLAGS_microbenchmark_type, "microbenchmark_type", "append", "")

	rand.Seed(int64(FLAGS_rand_seed))
}

func buildAppendToLogRequest() utils.JSONValue {
	return utils.JSONValue{}
}

func buildReadFromLogRequest() utils.JSONValue {
	return utils.JSONValue{}
}

func buildAppendToAndReadFromLogRequest() utils.JSONValue {
	return utils.JSONValue{}
}

func main() {
	flag.Parse()

	log.Printf("[INFO] Start running for %d seconds with concurrency of %d", FLAGS_duration, FLAGS_concurrency)

	// concurrency: how many concurrent faas workers (goroutines)
	client := utils.NewFaasClient(FLAGS_faas_gateway, FLAGS_concurrency)
	startTime := time.Now()
	for {
		if time.Since(startTime) > time.Duration(FLAGS_duration)*time.Second {
			break
		}
		// mapping ReadAndAppendFromLog to number
		switch FLAGS_microbenchmark_type {
		case Append:
			client.AddJsonFnCall(FLAGS_fn_prefix+"AppendToLog", buildAppendToLogRequest())
		case Read:
			client.AddJsonFnCall(FLAGS_fn_prefix+"ReadFromLog", buildReadFromLogRequest())
		case AppendAndRead:
			client.AddJsonFnCall(FLAGS_fn_prefix+"AppendToAndReadFromLog", buildAppendToAndReadFromLogRequest())
		default:
			fmt.Printf("Unknown argument %s", FLAGS_microbenchmark_type)
			break
		}
	}
	results := client.WaitForResults()
	elapsed := time.Since(startTime)
	fmt.Printf("Benchmark runs for %v, %.1f request per sec\n", elapsed, float64(len(results))/elapsed.Seconds())
}
