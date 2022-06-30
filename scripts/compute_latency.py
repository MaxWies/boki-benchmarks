#!/usr/bin/python3
import os
import json
import argparse

import numpy as np

def parse_async_results(file_path):
    results = []
    with open(file_path) as fin:
        for line in fin:
            results.append(json.loads(line.strip()))
    return results

def compute_latency(async_result_file_path, warmup_ratio=1.0/6, outlier_ratio=30):
    queueing_delays = []
    latencies = []
    results = parse_async_results(async_result_file_path)
    skip = int(len(results) * warmup_ratio)
    for entry in results[skip:]:
        recv_ts = entry['recvTs']
        dispatch_ts = entry['dispatchTs']
        finish_ts = entry['finishedTs']
        if dispatch_ts > recv_ts:
            queueing_delays.append(dispatch_ts - recv_ts)
        latencies.append(finish_ts - dispatch_ts)
    threshold = np.median(latencies) * outlier_ratio
    ignored = np.sum(np.array(latencies > threshold))
    filtered = list(filter(lambda x: x < threshold, latencies))
    p50 = np.percentile(filtered, 50) / 1000.0
    p99 = np.percentile(filtered, 99) / 1000.0
    return p50, p99

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--async-result-file', type=str, default=None)
    parser.add_argument('--warmup-ratio', type=float, default=1.0/6)
    parser.add_argument('--outlier-factor', type=int, default=30)
    parser.add_argument('--csv-output-file', type=str, default='')
    parser.add_argument('--slog', type=str, default='indilog')
    args = parser.parse_args()

    p50, p99 = compute_latency(args.async_result_file,
                               warmup_ratio=args.warmup_ratio,
                               outlier_ratio=args.outlier_factor)
    print('p50 latency: %.2f ms' % p50)
    print('p99 latency: %.2f ms' % p99)
    
    if args.csv_output_file != '':
        with open(args.csv_output_file, 'a', encoding='UTF8', newline='') as f:
            writer = csv.writer(f)
            if write_header:
                writer.writerow(['slog','latency_50', 'latency_99'])
            data = [
                args.slog,
                "%.2f" % p50,
                "%.2f" % p99,
            ]
            writer.writerow(data)
