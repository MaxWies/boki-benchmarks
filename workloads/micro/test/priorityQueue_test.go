package test

import (
	"container/heap"
	"faas-micro/operations"
	"math"
	"testing"
)

func TestPriorityQueueMax(t *testing.T) {
	items := []int64{
		7,
		math.MaxInt64,
		10000,
		0,
	}
	pq := operations.PriorityQueueMax{
		Limit: 10,
		Items: make([]*operations.OperationCallItem, len(items)),
	}
	for i, p := range items {
		pq.Items[i] = &operations.OperationCallItem{
			Latency:           p,
			RelativeTimestamp: int64(i),
		}
	}
	heap.Init(&pq)
	heap.Push(&pq, &operations.OperationCallItem{
		Latency:           16,
		RelativeTimestamp: 4,
	})
	sortedItems := []int64{
		0,
		7,
		16,
		10000,
		math.MaxInt64,
	}
	for i := range sortedItems {
		item := heap.Pop(&pq).(*operations.OperationCallItem)
		if item.Latency != sortedItems[i] {
			t.Error("Wrong priority")
		}
	}
}

func TestPriorityQueueMin(t *testing.T) {
	items := []int64{
		7,
		math.MaxInt64,
		10000,
		0,
	}
	pq := operations.PriorityQueueMin{
		Limit: 10,
		Items: make([]*operations.OperationCallItem, len(items)),
	}
	for i, p := range items {
		pq.Items[i] = &operations.OperationCallItem{
			Latency:           p,
			RelativeTimestamp: int64(i),
		}
	}
	heap.Init(&pq)
	heap.Push(&pq, &operations.OperationCallItem{
		Latency:           16,
		RelativeTimestamp: 4,
	})
	sortedItems := []int64{
		math.MaxInt64,
		10000,
		16,
		7,
		0,
	}
	for i := range sortedItems {
		item := heap.Pop(&pq).(*operations.OperationCallItem)
		if item.Latency != sortedItems[i] {
			t.Error("Wrong priority")
		}
	}
}

func TestPriorityQueueMax_Shrinking(t *testing.T) {
	items := []int64{
		7,
		10000,
		0,
		5,
		99,
		1,
		1,
	}
	pq := operations.PriorityQueueMax{
		Limit: 1,
		Items: make([]*operations.OperationCallItem, len(items)),
	}
	for i, p := range items {
		pq.Items[i] = &operations.OperationCallItem{
			Latency:           p,
			RelativeTimestamp: int64(i),
		}
	}
	heap.Init(&pq)
	//heap.Fix(&pq)
	pq.Shrink()
	item := pq.Pop().(*operations.OperationCallItem)
	if item.Latency != 10000 {
		t.Error("Wrong priority")
	}
}

func TestPriorityQueueMax_Add(t *testing.T) {
	items := []int64{
		1000,
		10000,
	}
	pq := operations.PriorityQueueMax{
		Limit: 3,
		Items: make([]*operations.OperationCallItem, len(items)),
	}
	for i, p := range items {
		pq.Items[i] = &operations.OperationCallItem{
			Latency:           p,
			RelativeTimestamp: int64(i),
		}
	}
	heap.Init(&pq)
	pq.Add(&operations.OperationCallItem{
		Latency:           5,
		RelativeTimestamp: 2,
	})
	if item, _ := pq.Peek(); item.Latency != 5 {
		t.Error("Wrong priority")
	}
	pq.Add(&operations.OperationCallItem{
		Latency:           5000,
		RelativeTimestamp: 3,
	})
	if item, _ := pq.Peek(); item.Latency != 1000 {
		t.Error("Wrong priority")
	}
	pq.Limit = 2
	pq.Shrink()
	v := heap.Pop(&pq).(*operations.OperationCallItem)
	if v.Latency != 5000 {
		t.Error("Wrong priority")
	}
	v = heap.Pop(&pq).(*operations.OperationCallItem)
	if v.Latency != 10000 {
		t.Error("Wrong priority")
	}
}
