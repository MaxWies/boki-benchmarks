package test

import (
	"container/heap"
	"faas-micro/utils"
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
	pq := utils.PriorityQueueMax{
		Limit: 10,
		Items: make([]*utils.OperationCallItem, len(items)),
	}
	for i, p := range items {
		pq.Items[i] = &utils.OperationCallItem{
			Latency:           p,
			Call:              int64(i + 1),
			RelativeTimestamp: int64(i),
		}
	}
	heap.Init(&pq)
	heap.Push(&pq, int64(16))
	sortedItems := []int64{
		0,
		7,
		16,
		10000,
		math.MaxInt64,
	}
	for i := range sortedItems {
		item := heap.Pop(&pq).(int64)
		if item != sortedItems[i] {
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
	pq := utils.PriorityQueueMin{
		Limit: 10,
		Items: make([]*utils.OperationCallItem, len(items)),
	}
	for i, p := range items {
		pq.Items[i] = &utils.OperationCallItem{
			Latency:           p,
			Call:              int64(i + 1),
			RelativeTimestamp: int64(i),
		}
	}
	heap.Init(&pq)
	heap.Push(&pq, &utils.OperationCallItem{
		Latency:           16,
		Call:              5,
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
		item := heap.Pop(&pq).(*utils.OperationCallItem)
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
	pq := utils.PriorityQueueMax{
		Limit: 1,
		Items: make([]*utils.OperationCallItem, len(items)),
	}
	for i, p := range items {
		pq.Items[i] = &utils.OperationCallItem{
			Latency:           p,
			Call:              int64(i + 1),
			RelativeTimestamp: int64(i),
		}
	}
	heap.Init(&pq)
	//heap.Fix(&pq)
	pq.Shrink()
	item := pq.Pop().(*utils.OperationCallItem)
	if item.Latency != 10000 {
		t.Error("Wrong priority")
	}
}

func TestPriorityQueueMax_Add(t *testing.T) {
	items := []int64{
		1000,
		10000,
	}
	pq := utils.PriorityQueueMax{
		Limit: 3,
		Items: make([]*utils.OperationCallItem, len(items)),
	}
	for i, p := range items {
		pq.Items[i] = &utils.OperationCallItem{
			Latency:           p,
			Call:              int64(i + 1),
			RelativeTimestamp: int64(i),
		}
	}
	heap.Init(&pq)
	pq.Add(&utils.OperationCallItem{
		Latency:           5,
		Call:              3,
		RelativeTimestamp: 2,
	})
	if item, _ := pq.Peek(); item.Latency != 5 {
		t.Error("Wrong priority")
	}
	pq.Add(&utils.OperationCallItem{
		Latency:           5000,
		Call:              4,
		RelativeTimestamp: 3,
	})
	if item, _ := pq.Peek(); item.Latency != 1000 {
		t.Error("Wrong priority")
	}
	pq.Limit = 2
	pq.Shrink()
	v := heap.Pop(&pq).(*utils.OperationCallItem)
	if v.Latency != 5000 {
		t.Error("Wrong priority")
	}
	v = heap.Pop(&pq).(*utils.OperationCallItem)
	if v.Latency != 10000 {
		t.Error("Wrong priority")
	}
}
