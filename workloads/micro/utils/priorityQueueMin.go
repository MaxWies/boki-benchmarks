package utils

import (
	"container/heap"
	"faas-micro/merge"
	"log"
)

type PriorityQueueMin struct {
	Items []int64 `json:"items"`
	Limit int     `json:"limit"`
}

func (pq PriorityQueueMin) Len() int { return len(pq.Items) }

func (pq PriorityQueueMin) Less(i, j int) bool {
	return pq.Items[i] > pq.Items[j]
}

func (pq PriorityQueueMin) Swap(i, j int) {
	pq.Items[i], pq.Items[j] = pq.Items[j], pq.Items[i]
}

func (pq *PriorityQueueMin) Push(x interface{}) {
	item := x.(int64)
	pq.Items = append(pq.Items, item)
}

func (pq *PriorityQueueMin) Pop() interface{} {
	old := pq.Items
	n := len(old)
	item := old[n-1]
	old[n-1] = 0 // avoid memory leak
	pq.Items = old[0 : n-1]
	return item
}

func (pq *PriorityQueueMin) Peek() (int64, error) {
	if len(pq.Items) <= 0 {
		return -1, nil
	}
	return pq.Items[0], nil
}

func (pq *PriorityQueueMin) Shrink() {
	removeCounter := len(pq.Items) - pq.Limit
	if removeCounter < 0 {
		removeCounter = 0
	}
	for 0 < removeCounter {
		heap.Pop(pq)
		removeCounter--
	}
}

func (pq *PriorityQueueMin) Add(item int64) {
	if pq.Limit == 0 {
		return
	}
	if len(pq.Items) == 0 {
		pq.Items = append(pq.Items, item)
		heap.Init(pq)
		return
	}
	if len(pq.Items) < pq.Limit {
		heap.Push(pq, item)
		return
	}
	highest, _ := pq.Peek()
	if highest > item {
		heap.Pop(pq)
		heap.Push(pq, item)
	}
}

func (pq *PriorityQueueMin) Merge(object interface{}) {
	other := (object).(merge.Mergable).(*PriorityQueueMin)
	if pq.Limit != other.Limit {
		log.Print("Cannot merge priority queues. Limits are not equal")
		return
	}
	for _, e := range other.Items {
		pq.Add(e)
	}
}
