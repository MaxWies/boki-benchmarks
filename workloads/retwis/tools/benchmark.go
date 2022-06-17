package main

import (
	"errors"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"

	"cs.utexas.edu/zjia/faas-retwis/utils"

	"github.com/montanaflynn/stats"
)

var FLAGS_faas_gateway string
var FLAGS_fn_prefix string

var FLAGS_num_users int
var FLAGS_percentages string
var FLAGS_bodylen int
var FLAGS_rand_seed int

var FLAGS_duration int

var FLAGS_concurrency_client int
var FLAGS_concurrency_client_step_size int
var FLAGS_concurrency_client_step_interval int

var FLAGS_csv_result_file string

func init() {
	flag.StringVar(&FLAGS_faas_gateway, "faas_gateway", "127.0.0.1:8081", "")
	flag.StringVar(&FLAGS_fn_prefix, "fn_prefix", "", "")
	flag.IntVar(&FLAGS_num_users, "num_users", 1000, "")
	flag.IntVar(&FLAGS_concurrency_client, "concurrency_client", 1, "")
	flag.IntVar(&FLAGS_concurrency_client_step_size, "concurrency_client_step_size", 1, "")
	flag.IntVar(&FLAGS_concurrency_client_step_interval, "concurrency_client_step_interval", 0, "")
	flag.IntVar(&FLAGS_duration, "duration", 60, "")
	flag.StringVar(&FLAGS_percentages, "percentages", "25,25,25,25", "login,profile,postlist,post")
	flag.IntVar(&FLAGS_bodylen, "bodylen", 64, "")
	flag.IntVar(&FLAGS_rand_seed, "rand_seed", 23333, "")
	flag.StringVar(&FLAGS_csv_result_file, "csv_result_file", "", "")

	rand.Seed(int64(FLAGS_rand_seed))
}

func parsePercentages(s string) ([]int, error) {
	parts := strings.Split(s, ",")
	if len(parts) != 4 {
		return nil, fmt.Errorf("Need exactly four parts splitted by comma")
	}
	results := make([]int, 4)
	for i, part := range parts {
		if parsed, err := strconv.Atoi(part); err != nil {
			return nil, fmt.Errorf("Failed to parse %d-th part", i)
		} else {
			results[i] = parsed
		}
	}
	for i := 1; i < len(results); i++ {
		results[i] += results[i-1]
	}
	if results[len(results)-1] != 100 {
		return nil, fmt.Errorf("Sum of all parts is not 100")
	}
	return results, nil
}

func buildLoginRequest() utils.JSONValue {
	i := rand.Intn(FLAGS_num_users)
	return utils.JSONValue{
		"username": fmt.Sprintf("testuser_%d", i),
		"password": fmt.Sprintf("password_%d", i),
	}
}

func buildProfileRequest() utils.JSONValue {
	userId := rand.Intn(FLAGS_num_users)
	return utils.JSONValue{
		"userId": fmt.Sprintf("%08x", userId),
	}
}

func buildPostListRequest() utils.JSONValue {
	if rand.Intn(4) == 0 {
		return utils.JSONValue{}
	} else {
		userId := rand.Intn(FLAGS_num_users)
		return utils.JSONValue{
			"userId": fmt.Sprintf("%08x", userId),
		}
	}
}

func buildPostRequest() utils.JSONValue {
	body := utils.RandomString(FLAGS_bodylen)
	userId := rand.Intn(FLAGS_num_users)
	return utils.JSONValue{
		"userId": fmt.Sprintf("%08x", userId),
		"body":   body,
	}
}

const kTxnConflitMsg = "Failed to commit transaction due to conflicts"

func printFnResult(fnName string, duration time.Duration, results []*utils.FaasCall) {
	total := 0
	succeeded := 0
	txnConflit := 0
	latencies := make([]float64, 0, 128)
	for _, result := range results {
		if result.FnName == FLAGS_fn_prefix+fnName {
			total++
			if result.Result.Success {
				succeeded++
			} else if result.Result.Message == kTxnConflitMsg {
				txnConflit++
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
	failed := total - succeeded - txnConflit
	throughput := float64(total) / duration.Seconds()
	var transaction_fail_ratio float64
	var request_fail_ratio float64
	var median_latency float64
	var p99_latency float64
	fmt.Printf("[%s]\n", fnName)
	fmt.Printf("Throughput: %.1f requests per sec\n", throughput)
	if txnConflit > 0 {
		transaction_fail_ratio = float64(txnConflit) / float64(txnConflit+succeeded)
		fmt.Printf("Transaction conflicts: %d (%.2f%%)\n", txnConflit, transaction_fail_ratio*100.0)
	}
	if failed > 0 {
		request_fail_ratio = float64(failed) / float64(total)
		fmt.Printf("Failed request: %d (%.2f%%)\n", failed, request_fail_ratio*100.0)
	}
	if len(latencies) > 0 {
		median_latency, _ = stats.Median(latencies)
		p99_latency, _ = stats.Percentile(latencies, 99.0)
		fmt.Printf("Latency: median = %.3fms, tail (p99) = %.3fms\n", median_latency/1000.0, p99_latency/1000.0)
	}
	if FLAGS_csv_result_file != "" {
		var csvHeader string
		if _, err := os.Stat(FLAGS_csv_result_file); errors.Is(err, os.ErrNotExist) {
			csvHeader += "fn_name,throughput,request_fail,request_fail_ratio,transaction_fail,transaction_fail_ratio,latency_50,latency_99\n"
		}
		csvData := fmt.Sprintf("%s,%.1f,%d,%.4f,%d,%.4f,%.3f,%.3f\n",
			fnName,
			throughput,
			failed,
			request_fail_ratio,
			txnConflit,
			transaction_fail_ratio,
			median_latency/1000.0,
			p99_latency/1000.0,
		)
		f, err := os.OpenFile(FLAGS_csv_result_file, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			log.Fatal(err)
		}
		if _, err := f.Write([]byte(csvHeader + csvData)); err != nil {
			f.Close()
			log.Fatal(err)
		}
		if err := f.Close(); err != nil {
			log.Fatal(err)
		}
	}
}

// func scaleClients(time.Time* startTime, time.Time* scaleTime, *[]*utils.FaasClient clients) {
// 	if time.Since(*scaleTime) > time.Duration(FLAGS_concurrency_client_step_interval*steps)*time.Second {
// 		client := utils.NewFaasClient(FLAGS_faas_gateway, FLAGS_concurrency_client+steps*FLAGS_concurrency_client_step_size)
// 		clients = append(clients, client)
// 		steps++
// 		log.Printf("[INFO] Increase load by adding %d concurrency", FLAGS_concurrency_client_step_size)
// 		*scaleTime = time.Now()
// 	}
// }

func main() {
	flag.Parse()

	if FLAGS_concurrency_client_step_interval < 1 {
		FLAGS_concurrency_client_step_interval = 2 * FLAGS_duration
	}

	percentages, err := parsePercentages(FLAGS_percentages)
	if err != nil {
		log.Fatalf("[FATAL] Invalid \"percentages\" flag: %v", err)
	}

	log.Printf("[INFO] Start running for %d seconds. concurrency_start=%d, concurrency_step=%d, concurrency_interval=%d",
		FLAGS_duration,
		FLAGS_concurrency_client,
		FLAGS_concurrency_client_step_size,
		FLAGS_concurrency_client_step_interval,
	)

	// clients := make([]*utils.FaasClient, 0)
	client := utils.NewFaasClient(FLAGS_faas_gateway, FLAGS_concurrency_client)
	// clients = append(clients, client)
	// steps := 1
	startTime := time.Now()
	for {
		if time.Since(startTime) > time.Duration(FLAGS_duration)*time.Second {
			break
		}
		// if time.Since(scaleTime) > time.Duration(FLAGS_concurrency_client_step_interval*steps)*time.Second {
		// 	client := utils.NewFaasClient(FLAGS_faas_gateway, FLAGS_concurrency_client+steps*FLAGS_concurrency_client_step_size)
		// 	clients = append(clients, client)
		// 	steps++
		// 	log.Printf("[INFO] Increase load by adding %d concurrency", FLAGS_concurrency_client_step_size)
		// 	scaleTime = time.Now()
		// }
		k := rand.Intn(100)
		if k < percentages[0] {
			client.AddJsonFnCall(FLAGS_fn_prefix+"RetwisLogin", buildLoginRequest())
		} else if k < percentages[1] {
			client.AddJsonFnCall(FLAGS_fn_prefix+"RetwisProfile", buildProfileRequest())
		} else if k < percentages[2] {
			client.AddJsonFnCall(FLAGS_fn_prefix+"RetwisPostList", buildPostListRequest())
		} else {
			client.AddJsonFnCall(FLAGS_fn_prefix+"RetwisPost", buildPostRequest())
		}
	}
	// log.Printf("[INFO] Created %d clients", len(clients))
	// for i := 0; i < len(clients); i++ {
	// 	client = clients[i]
	results := client.WaitForResults()
	elapsed := time.Since(startTime)
	fmt.Printf("Benchmark runs for %v, %.1f request per sec\n", elapsed, float64(len(results))/elapsed.Seconds())

	printFnResult("RetwisLogin", elapsed, results)
	printFnResult("RetwisProfile", elapsed, results)
	printFnResult("RetwisPostList", elapsed, results)
	printFnResult("RetwisPost", elapsed, results)
	// /	}
}
