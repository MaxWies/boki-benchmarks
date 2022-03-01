package merge

func merge_on_engine() {

}

func merge_on_client() {

}

type Mergable interface {
	Merge(other interface{})
}
