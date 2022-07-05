package main

import (
	"flag"
	"fmt"
	"log"
	"math/rand"
	"time"

	"faas-micro/constants"
	"faas-micro/utils"
)

var FLAGS_faas_gateway string
var FLAGS_fn_prefix string
var FLAGS_fn_merge_prefix string
var FLAGS_rand_seed int
var FLAGS_benchmark_type string
var FLAGS_benchmark_description string

var FLAGS_duration int
var FLAGS_append_times int
var FLAGS_read_times int
var FLAGS_record_length int

var FLAGS_latency_bucket_lower int
var FLAGS_latency_bucket_upper int
var FLAGS_latency_bucket_granularity int
var FLAGS_latency_head_size int
var FLAGS_latency_tail_size int
var FLAGS_snapshot_interval int
var FLAGS_statistics_at_container bool
var FLAGS_read_direction int
var FLAGS_use_tags bool

var FLAGS_operation_semantics_percentages string
var FLAGS_seqnum_read_percentages string
var FLAGS_tag_append_percentages string
var FLAGS_tag_read_percentages string
var FLAGS_suffix_seqnums_capacity int
var FLAGS_popular_seqnums_capacity int
var FLAGS_own_tags_capacity int
var FLAGS_shared_tags_capacity int

var FLAGS_engine_nodes int
var FLAGS_concurrency_client int
var FLAGS_concurrency_worker int
var FLAGS_concurrency_operation int

var FLAGS_wait_until_load_end bool

var FLAGS_csv_result_file string

func init() {
	// main settings
	flag.StringVar(&FLAGS_faas_gateway, "faas_gateway", "127.0.0.1:8081", "")
	flag.StringVar(&FLAGS_fn_prefix, "fn_prefix", "", "")
	flag.StringVar(&FLAGS_fn_merge_prefix, "fn_merge_prefix", "", "")
	flag.IntVar(&FLAGS_rand_seed, "rand_seed", 23333, "")
	flag.StringVar(&FLAGS_benchmark_type, "benchmark_type", constants.BenchmarkAppend, "")
	flag.StringVar(&FLAGS_benchmark_description, "benchmark_description", "", "An optional description")

	// basic workload settings
	flag.IntVar(&FLAGS_duration, "duration", 10, "")
	flag.IntVar(&FLAGS_record_length, "record_length", 1024, "")
	flag.IntVar(&FLAGS_append_times, "append_times", 1, "")
	flag.IntVar(&FLAGS_read_times, "read_times", 1, "")

	// container-level benchmarks
	flag.IntVar(&FLAGS_latency_bucket_lower, "latency_bucket_lower", 300, "")            //microsec
	flag.IntVar(&FLAGS_latency_bucket_upper, "latency_bucket_upper", 10000, "")          //microsec
	flag.IntVar(&FLAGS_latency_bucket_granularity, "latency_bucket_granularity", 10, "") //microsec
	flag.IntVar(&FLAGS_latency_head_size, "latency_head_size", 20, "")
	flag.IntVar(&FLAGS_latency_tail_size, "latency_tail_size", 20, "")
	flag.IntVar(&FLAGS_read_direction, "read_direction", 1, "")
	flag.BoolVar(&FLAGS_use_tags, "use_tags", true, "")
	flag.IntVar(&FLAGS_snapshot_interval, "snapshot_interval", 0, "")
	flag.BoolVar(&FLAGS_statistics_at_container, "statistics_at_container", false, "")

	// configuration for random operations
	flag.StringVar(&FLAGS_operation_semantics_percentages, "operation_semantics_percentages", "50,50", "opWithoutTags,opWithTags")
	flag.StringVar(&FLAGS_seqnum_read_percentages, "seqnum_read_percentages", "30,30,20,10,10", "readOwn,readPopular,readSuffix,readHead,readTail")
	flag.StringVar(&FLAGS_tag_append_percentages, "tag_append_percentages", "30,40,30", "appendNewTag,appendToOwnTag,appendToSharedTag")
	flag.StringVar(&FLAGS_tag_read_percentages, "tag_read_percentages", "10,30,20,20,10,10", "readGap,readDirectly,readFromLeft,readFromRight,readFromHead,readFromTail")
	flag.IntVar(&FLAGS_suffix_seqnums_capacity, "suffix_seqnums_capacity", 100, "Length of suffix from which seqnums are taken")
	flag.IntVar(&FLAGS_popular_seqnums_capacity, "popular_seqnums_capacity", 30, "Popular seqnums reused")
	flag.IntVar(&FLAGS_own_tags_capacity, "own_tags_capacity", 20, "Number of tags reused only at one engine")
	flag.IntVar(&FLAGS_shared_tags_capacity, "shared_tags_capacity", 20, "Number of tags reused across engines")

	// load setting
	flag.IntVar(&FLAGS_engine_nodes, "engine_nodes", 1, "Number of engine nodes in system")
	flag.IntVar(&FLAGS_concurrency_client, "concurrency_client", 1, "Number of clients sending requests")
	flag.IntVar(&FLAGS_concurrency_worker, "concurrency_worker", 1, "Number of function worker per engine")
	flag.IntVar(&FLAGS_concurrency_operation, "concurrency_operation", 1, "Number of concurrent operations per worker")

	flag.BoolVar(&FLAGS_wait_until_load_end, "wait_until_load_end", true, "Client holds until load ends")

	flag.StringVar(&FLAGS_csv_result_file, "csv_result_file", "", "")

	rand.Seed(int64(FLAGS_rand_seed))
}

func buildAppendRequest() utils.JSONValue {
	return utils.JSONValue{
		"use_tags": FLAGS_use_tags,
	}
}

func buildMicrobenchmarkRequest() utils.JSONValue {
	record := utils.CreateRecord(FLAGS_record_length)
	return utils.JSONValue{
		"record":                          record,
		"append_times":                    FLAGS_append_times,
		"read_times":                      FLAGS_read_times,
		"read_direction":                  FLAGS_read_direction,
		"use_tags":                        FLAGS_use_tags,
		"loop_duration":                   FLAGS_duration,
		"snapshot_interval":               FLAGS_snapshot_interval,
		"latency_bucket_lower":            FLAGS_latency_bucket_lower,
		"latency_bucket_upper":            FLAGS_latency_bucket_upper,
		"latency_bucket_granularity":      FLAGS_latency_bucket_granularity,
		"latency_head_size":               FLAGS_latency_head_size,
		"latency_tail_size":               FLAGS_latency_tail_size,
		"statistics_at_container":         FLAGS_statistics_at_container,
		"benchmark_type":                  FLAGS_benchmark_type,
		"concurrent_operations":           FLAGS_concurrency_operation,
		"suffix_seqnums_capacity":         FLAGS_suffix_seqnums_capacity,
		"popular_seqnums_capacity":        FLAGS_popular_seqnums_capacity,
		"own_tags_capacity":               FLAGS_own_tags_capacity,
		"shared_tags_capacity":            FLAGS_shared_tags_capacity,
		"operation_semantics_percentages": FLAGS_operation_semantics_percentages,
		"seqnum_read_percentages":         FLAGS_seqnum_read_percentages,
		"tag_append_percentages":          FLAGS_tag_append_percentages,
		"tag_read_percentages":            FLAGS_tag_read_percentages,
	}
}

func buildTestSystemRequest() utils.JSONValue {
	return utils.JSONValue{
		"record":     utils.CreateRandomRecord(FLAGS_record_length),
		"read_times": FLAGS_read_times,
		"tag":        utils.CreateEmptyTagOrRandomTag(),
	}
}

func buildWarmupRequest() utils.JSONValue {
	return utils.JSONValue{
		"record":     utils.CreateRecord(1024),
		"read_times": 1,
		"tag":        utils.CreateEmptyTagOrRandomTag(),
	}
}

func buildReadRequest() utils.JSONValue {
	return utils.JSONValue{
		"record": FLAGS_use_tags,
	}
}

func runClientLevelBenchmark() {
	log.Printf("[INFO] Run client level benchmark")
	switch FLAGS_benchmark_type {
	case constants.BenchmarkAppend:
		builder := buildAppendRequest
		clientLoop(constants.FunctionAppend, builder, FLAGS_csv_result_file)
		break
	case constants.BenchmarkRead:
		builder := buildReadRequest
		clientLoop(constants.FunctionRead, builder, FLAGS_csv_result_file)
		break
	case constants.BenchmarkTestSystem:
		rand.Seed(time.Now().UnixNano())
		builder := buildTestSystemRequest
		clientLoop(constants.FunctionTestSystem, builder, FLAGS_csv_result_file)
		break
	case constants.BenchmarkWarmup:
		builder := buildWarmupRequest
		clientWarmup(constants.FunctionTestSystem, builder)
		break
	default:
		fmt.Printf("Unknown argument %s", FLAGS_benchmark_type)
		break
	}
}

func runContainerLevelBenchmark() {
	log.Printf("[INFO] Run container level benchmark")
	builder := buildMicrobenchmarkRequest
	var function string
	switch FLAGS_benchmark_type {
	case constants.BenchmarkContainerAppendLoad:
		function = constants.FunctionAppendLoopAsync
		break
	case constants.BenchmarkContainerAppendAndReadLoad:
		function = constants.FunctionAppendAndReadLoopAsync
		break
	case constants.BenchmarkContainerRandomLoad:
		function = constants.FunctionRandomAppendAndReadLoopAsync
		break
	default:
		fmt.Printf("Unknown argument %s", FLAGS_benchmark_type)
		break
	}
	containerLoop(function, builder)
	time.Sleep((time.Duration(FLAGS_duration) + 5) * time.Second)
	mergeContainerResults(function)
}

func runLogEngineLevelBenchmark() {
	log.Printf("[INFO] Run log engine level benchmark")
	log.Printf("[INFO] Operation semantics percentages: %s", FLAGS_operation_semantics_percentages)
	log.Printf("[INFO] Seqnum read percentages: %s", FLAGS_seqnum_read_percentages)
	log.Printf("[INFO] Tag append percentages: %s", FLAGS_tag_append_percentages)
	log.Printf("[INFO] Tag read percentages: %s", FLAGS_tag_read_percentages)
	log.Printf("[INFO] Suffix seqnums capacity percentages: %d", FLAGS_suffix_seqnums_capacity)
	log.Printf("[INFO] Popular seqnums capacity percentages: %d", FLAGS_popular_seqnums_capacity)
	log.Printf("[INFO] Own tags capacity percentages: %d", FLAGS_own_tags_capacity)
	log.Printf("[INFO] Shared tags capacity percentages: %d", FLAGS_shared_tags_capacity)
	builder := buildMicrobenchmarkRequest
	var function string
	switch FLAGS_benchmark_type {
	case constants.BenchmarkEngineRandomLoad:
		function = constants.FunctionRandomAppendAndReadLoopAsync
		containerLoop(function, builder)
		if FLAGS_wait_until_load_end {
			time.Sleep((time.Duration(FLAGS_duration) + 5) * time.Second)
			log.Printf("[INFO] Loop finished")
		} else {
			log.Printf("[INFO] Sent requests to %d engine nodes", FLAGS_engine_nodes)
		}
		break
	default:
		fmt.Printf("Unknown argument %s", FLAGS_benchmark_type)
		break
	}
}

func main() {
	flag.Parse()
	log.Printf("[INFO] Faas gateway: %s", FLAGS_faas_gateway)
	log.Printf("[INFO] Benchmark type: %s", FLAGS_benchmark_type)
	log.Printf("[INFO] Seed: %d", FLAGS_rand_seed)
	switch FLAGS_benchmark_type {
	case
		constants.BenchmarkAppend,
		constants.BenchmarkRead,
		constants.BenchmarkTestSystem,
		constants.BenchmarkWarmup:
		runClientLevelBenchmark()
		break
	case
		constants.BenchmarkContainerAppendLoad,
		constants.BenchmarkContainerAppendAndReadLoad,
		constants.BenchmarkContainerRandomLoad:
		runContainerLevelBenchmark()
		break
	case
		constants.BenchmarkEngineRandomLoad:
		runLogEngineLevelBenchmark()
		break
	default:
		log.Printf("[INFO] Unknown argument %s", FLAGS_benchmark_type)
		fmt.Printf("Unknown argument %s", FLAGS_benchmark_type)
		break
	}
}
