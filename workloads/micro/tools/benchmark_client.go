package main

import (
	"faas-micro/utils"
	"fmt"
	"io/ioutil"
	"log"
	"time"

	"github.com/montanaflynn/stats"
)

func printFnResult(fnName string, duration time.Duration, results []*utils.FaasCall, csvResultFile string) {
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
	throughput := float64(total) / duration.Seconds()
	var fail_ratio float64
	var median_latency float64
	var p99_latency float64
	fmt.Printf("[%s]\n", fnName)
	fmt.Printf("Throughput: %.1f requests per sec\n", throughput)
	if failed > 0 {
		fail_ratio = float64(failed) / float64(total)
		fmt.Printf("Failed requests: %d (%.2f%%)\n", failed, fail_ratio*100.0)
	}
	if len(latencies) > 0 {
		median_latency, _ = stats.Median(latencies)
		p99_latency, _ = stats.Percentile(latencies, 99.0)
		fmt.Printf("Latency: median = %.3fms, tail (p99) = %.3fms\n", median_latency/1000.0, p99_latency/1000.0)
	}
	if csvResultFile == "" {
		return
	}
	var csvData string
	_ = fmt.Sprintf(csvData, "%s\n%.1f,%d,%.2f%%,%.3f,%.3f\n",
		"throughput,failed,failed_ratio,latency_50,latency99",
		float64(total)/duration.Seconds(),
		failed,
		fail_ratio,
		median_latency/1000.0,
		p99_latency/1000.0,
	)
	err := ioutil.WriteFile(csvResultFile, []byte(csvData), 0644)
	if err != nil {
		log.Printf("[ERROR] Failed to write result to file %s", csvResultFile)
	}
}

func clientLoop(functionName string, functionBuilder func() utils.JSONValue, csvResultFile string) {
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
	printFnResult(functionName, elapsed, results, csvResultFile)
}

func clientWarmup(functionName string, functionBuilder func() utils.JSONValue) {
	client := utils.NewFaasClient(FLAGS_faas_gateway, 4)
	startTime := time.Now()
	for {
		if time.Since(startTime) > time.Duration(5)*time.Second {
			break
		}
		client.AddJsonFnCall(FLAGS_fn_prefix+functionName, functionBuilder())
	}
	client.WaitForResults()
}
