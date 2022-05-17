package constants

import "math"

const (
	InvalidSeqNum     uint64 = math.MaxUint64
	UnknownSeqNum     uint64 = math.MaxUint64 - 1
	MaxSeqnum         uint64 = uint64(0xffff000000000000)
	TagEmpty          uint64 = 0
	TagEngineCacheHit uint64 = math.MaxUint64 - 1
	TagUnknown        uint64 = uint64(0xf000affe00000000)
	TagShared         uint64 = uint64(9) << 31 //first shared tag
	TagReserveBits    int    = 3
	ReadPrev          int    = 0
	ReadNext          int    = 1
)
