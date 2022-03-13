package operations

type Bucket struct {
	Lower       int64   `json:"lower"`
	Upper       int64   `json:"upper"`
	Interval    int64   `json:"interval"`
	Slots       []int64 `json:"slots"`
	SlotsAmount int64   `json:"slots_amount"`
}

func CreateBucket(lower int64, upper int64, interval int64) (bucket *Bucket) {
	slotsAmount := (upper - lower) / interval
	slots := make([]int64, slotsAmount)
	return &Bucket{
		Lower:       lower,
		Upper:       upper,
		Interval:    interval,
		Slots:       slots,
		SlotsAmount: slotsAmount,
	}
}

func (bucket *Bucket) Insert(value int64) {
	if value <= bucket.Lower {
		bucket.Slots[0]++
		return
	}
	if value >= bucket.Upper {
		bucket.Slots[bucket.SlotsAmount-1]++
		return
	}
	valueAdjusted := value - bucket.Lower
	slotIndex := valueAdjusted / bucket.Interval
	bucket.Slots[slotIndex]++
}
