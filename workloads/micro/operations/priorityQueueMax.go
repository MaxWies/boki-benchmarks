package operations

import (
	"container/heap"
	"errors"
	"faas-micro/merge"
	"log"
)

type PriorityQueueMax struct {
	Items []*OperationCallItem `json:"items"`
	Limit int                  `json:"limit"`
}

func (pq PriorityQueueMax) Len() int { return len(pq.Items) }

func (pq PriorityQueueMax) Less(i, j int) bool {
	return pq.Items[i].Latency < pq.Items[j].Latency
}

func (pq PriorityQueueMax) Swap(i, j int) {
	pq.Items[i], pq.Items[j] = pq.Items[j], pq.Items[i]
	//pq.Items[i].Index = i
	//pq.Items[j].Index = j
}

func (pq *PriorityQueueMax) Push(x interface{}) {
	//n := len(pq.Items)
	item := x.(*OperationCallItem)
	//item.Index = n
	pq.Items = append(pq.Items, item)
}

func (pq *PriorityQueueMax) Pop() interface{} {
	old := pq.Items
	n := len(old)
	item := old[n-1]
	old[n-1] = &OperationCallItem{} // avoid memory leak
	//item.Index = -1 // for safety
	pq.Items = old[0 : n-1]
	return item
}

func (pq *PriorityQueueMax) Peek() (*OperationCallItem, error) {
	if len(pq.Items) <= 0 {
		return &OperationCallItem{}, errors.New("Queue empty")
	}
	return pq.Items[0], nil
}

func (pq *PriorityQueueMax) Remove() (*OperationCallItem, error) {
	if len(pq.Items) <= 0 {
		return &OperationCallItem{}, errors.New("Queue empty")
	}
	return heap.Pop(pq).(*OperationCallItem), nil
}

func (pq *PriorityQueueMax) Shrink() {
	removeCounter := len(pq.Items) - pq.Limit
	if removeCounter < 0 {
		removeCounter = 0
	}
	for 0 < removeCounter {
		heap.Pop(pq)
		removeCounter--
	}
}

func (pq *PriorityQueueMax) Add(item *OperationCallItem) {
	if pq.Limit == 0 {
		return
	}
	if len(pq.Items) == 0 {
		pq.Items = append(pq.Items, item)
		heap.Init(pq)
		return
	}
	lowest, _ := pq.Peek()
	if len(pq.Items) < pq.Limit {
		heap.Push(pq, item)
	} else if lowest.Latency < item.Latency {
		// remove lowest and add new item
		heap.Pop(pq)
		heap.Push(pq, item)
	}
}

func (pq *PriorityQueueMax) Merge(object interface{}) {
	other := (object).(merge.Mergable).(*PriorityQueueMax)
	if pq.Limit != other.Limit {
		log.Print("Cannot merge priority queues. Limits are not equal")
		return
	}
	for _, e := range other.Items {
		pq.Add(e)
	}
}
