package utils

import (
	"faas-micro/constants"
	"log"
	"math/rand"
	"sync"
)

type Pair struct {
	tag, seqnum interface{}
}

type LogSuffix struct {
	lock   *sync.Mutex
	values []Pair
	limit  int
}

func CreateLogSuffix(limit int) LogSuffix {
	return LogSuffix{&sync.Mutex{}, make([]Pair, 0), limit}
}

func (s *LogSuffix) Append(tag uint64, seqnum uint64) {
	defer s.lock.Unlock()
	s.lock.Lock()
	s.values = append(s.values, Pair{tag, seqnum})
	if len(s.values) > s.limit {
		s.values = s.values[1:]
	}
	if len(s.values) > s.limit {
		log.Printf("[WARNING] Suffix exceeds capacity")
	}
}

func (s *LogSuffix) PickHead() (uint64, uint64) {
	defer s.lock.Unlock()
	s.lock.Lock()
	if len(s.values) < 1 {
		log.Printf("[WARNING] Read on empty suffix")
		return constants.TagEmpty, constants.InvalidSeqNum
	}
	return s.values[0].tag.(uint64), s.values[0].seqnum.(uint64)
}

func (s *LogSuffix) PickTail() (uint64, uint64) {
	defer s.lock.Unlock()
	s.lock.Lock()
	if len(s.values) < 1 {
		log.Printf("[WARNING] Read on empty suffix")
		return constants.TagEmpty, constants.InvalidSeqNum
	}
	return s.values[0].tag.(uint64), s.values[0].seqnum.(uint64)
}

func (s *LogSuffix) PickRandomTagAndSeqnum() (uint64, uint64) {
	defer s.lock.Unlock()
	s.lock.Lock()
	if len(s.values) < 1 {
		log.Printf("[WARNING] Read on empty suffix")
		return constants.TagEmpty, constants.InvalidSeqNum
	}
	i := rand.Int() % len(s.values)
	return s.values[i].tag.(uint64), s.values[i].seqnum.(uint64)
}

func (s *LogSuffix) PickRandomSeqnum() uint64 {
	defer s.lock.Unlock()
	s.lock.Lock()
	if len(s.values) < 1 {
		log.Printf("[WARNING] Read on empty suffix")
		return constants.InvalidSeqNum
	}
	i := rand.Int() % len(s.values)
	return s.values[i].seqnum.(uint64)
}

type SeqnumPool struct {
	lock    *sync.Mutex
	seqnums []uint64
	limit   int
}

func CreateEmptySeqnumPool(limit int) SeqnumPool {
	return SeqnumPool{
		&sync.Mutex{},
		make([]uint64, 0),
		limit,
	}
}

func (p *SeqnumPool) Append(seqNum uint64) {
	defer p.lock.Unlock()
	p.lock.Lock()
	if p.limit <= len(p.seqnums) {
		return
	}
	p.seqnums = append(p.seqnums, seqNum)
}

func (p *SeqnumPool) PickRandomSeqnum() uint64 {
	defer p.lock.Unlock()
	p.lock.Lock()
	if len(p.seqnums) < 1 {
		log.Printf("[WARNING] Read on empty pool")
		return constants.InvalidSeqNum
	}
	i := rand.Int() % len(p.seqnums)
	return p.seqnums[i]
}

type TagPool struct {
	lock           *sync.Mutex
	tags           []uint64
	maxSeqnumByTag map[uint64]uint64
	minSeqnumByTag map[uint64]uint64
	limit          int
}

func CreateTagPool(tags []uint64) TagPool {
	if len(tags) == 0 {
		log.Printf("[WARNING] Tag slice to initialize pool is empty")
	}
	p := TagPool{
		&sync.Mutex{},
		make([]uint64, 0),
		make(map[uint64]uint64),
		make(map[uint64]uint64),
		len(tags),
	}
	p.tags = append(p.tags, tags...)
	for i := 0; i < len(tags); i++ {
		p.maxSeqnumByTag[tags[i]] = 0
		p.minSeqnumByTag[tags[i]] = constants.MaxSeqnum
	}
	return p
}

func CreateEmptyTagPool(limit int) TagPool {
	return TagPool{
		&sync.Mutex{},
		make([]uint64, 0),
		make(map[uint64]uint64),
		make(map[uint64]uint64),
		limit,
	}
}

func (p *TagPool) Update(tag uint64, seqNum uint64) (uint64, uint64) {
	defer p.lock.Unlock()
	p.lock.Lock()
	seqnum_min := MinUnsigned(p.minSeqnumByTag[tag], seqNum)
	p.minSeqnumByTag[tag] = seqnum_min
	seqnum_max := MaxUnsigned(p.maxSeqnumByTag[tag], seqNum)
	p.maxSeqnumByTag[tag] = seqnum_max
	return seqnum_min, seqnum_max
}

func (p *TagPool) PickRandomTag() uint64 {
	defer p.lock.Unlock()
	p.lock.Lock()
	if len(p.tags) < 1 {
		log.Printf("[WARNING] Read on empty pool")
		return constants.TagEmpty
	}
	i := rand.Int() % len(p.tags)
	return p.tags[i]
}

func CreateEmptyTagOrRandomTag() uint64 {
	t := rand.Intn(3)
	if t == 0 {
		return constants.TagEmpty
	} else if t == 1 {
		return constants.TagShared
	} else {
		tag := rand.Uint64()
		for tag == constants.TagUnknown {
			tag = rand.Uint64()
		}
		return tag
	}
}
