package main

import (
	"faas-micro/client"
	"faas-micro/operations"
	"faas-micro/utils"
	"fmt"
	"log"
	"time"

	"github.com/montanaflynn/stats"
)

func printFnResult(fnName string, duration time.Duration, results []*utils.FaasCall) {
	total := 0
	succeeded := 0
	latencies := make([]float64, 0, 128)
	for _, result := range results {
		if result.FnName == FLAGS_fn_prefix+fnName {
			total++
			if result.Result.Success {
				succeeded++
			}
			if result.Result.StatusCode == 200 {
				d := result.Result.Duration
				latencies = append(latencies, float64(d.Microseconds()))
			}
		}
	}
	if total == 0 {
		return
	}
	failed := total - succeeded
	fmt.Printf("[%s]\n", fnName)
	fmt.Printf("Throughput: %.1f requests per sec\n", float64(total)/duration.Seconds())
	if failed > 0 {
		ratio := float64(failed) / float64(total)
		fmt.Printf("Failed requests: %d (%.2f%%)\n", failed, ratio*100.0)
	}
	if len(latencies) > 0 {
		median, _ := stats.Median(latencies)
		p99, _ := stats.Percentile(latencies, 99.0)
		fmt.Printf("Latency: median = %.3fms, tail (p99) = %.3fms\n", median/1000.0, p99/1000.0)
	}
}

func clientBenchmark(functionName string, functionBuilder func() utils.JSONValue) {
	client := utils.NewFaasClient(FLAGS_faas_gateway, FLAGS_concurrency_client)
	startTime := time.Now()
	for {
		if time.Since(startTime) > time.Duration(FLAGS_duration)*time.Second {
			break
		}
		client.AddJsonFnCall(FLAGS_fn_prefix+functionName, functionBuilder())
	}
	results := client.WaitForResults()
	elapsed := time.Since(startTime)
	fmt.Printf("Benchmark runs for %v, %.1f request per sec\n", elapsed, float64(len(results))/elapsed.Seconds())
	printFnResult(functionName, elapsed, results)
}

func clientLoopBenchmark(functionName string, requestInputBuilder func() utils.JSONValue) {
	log.Printf("[INFO] Run loop functions. Function mode: %s. Concurrency: %d. Duration: %d", FLAGS_benchmark_type, FLAGS_concurrency_client, FLAGS_duration)
	c := 0
	client := client.NewFaasClient(FLAGS_faas_gateway, FLAGS_concurrency_client, &client.CallSync{})
	for c < FLAGS_concurrency_client {
		client.AddJsonFnCall(FLAGS_fn_prefix+functionName, requestInputBuilder())
		c++
	}
	faasCalls := client.WaitForHttpResults()
	for _, faasCall := range faasCalls {
		if faasCall.HttpResult.Success {
			appendLoopOutput := faasCall.HttpResult.Result.(operations.Benchmark)
			fmt.Printf("Calls Total: %d", appendLoopOutput.Calls)
			fmt.Printf("Calls Success: %d", appendLoopOutput.Success)
			fmt.Printf("Calls Failure: %d", appendLoopOutput.Calls-appendLoopOutput.Success)
			fmt.Printf("Throughput: %.2f [Op/s] using %d bytes records", appendLoopOutput.Throughput, FLAGS_record_length)
		}
	}
}
