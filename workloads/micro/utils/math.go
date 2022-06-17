package utils

func Max(x, y int64) int64 {
	if x < y {
		return y
	}
	return x
}

func MaxUnsigned(x, y uint64) uint64 {
	if x < y {
		return y
	}
	return x
}

func Min(x, y int64) int64 {
	if x > y {
		return y
	}
	return x
}

func MinUnsigned(x, y uint64) uint64 {
	if x < y {
		return y
	}
	return x
}
