package handlers

import (
	"context"
	"encoding/json"
	"faas-micro/merge"
	"faas-micro/response"
	"io/ioutil"
	"log"
	"path"
	"strings"

	"cs.utexas.edu/zjia/faas/types"
)

type MergeRequest struct {
	Directory string `json:"directory"`
	Function  string `json:"function"`
}

type MergeHandler struct {
}

func NewMergeHandler() types.FuncHandler {
	return &MergeHandler{}
}

func (h *MergeHandler) CreateMergable(mergerType string) (merge.Mergable, error) {
	// switch mergerType {
	// case MergeType_AppendLoopResponse:
	// 	return &response.Benchmark{
	// 		Message: "No Results",
	// 	}, nil
	// default:
	// 	return nil, fmt.Errorf("Unknown merger type %s", mergerType)
	// }
	return &response.Benchmark{
		Message: "No Results",
	}, nil
}

func (h *MergeHandler) CreateMergableFromJson(mergerType string, marshalled []byte) (merge.Mergable, error) {
	// switch mergerType {
	// case MergeType_AppendLoopResponse:
	// 	var appendLoopResponse response.Benchmark
	// 	err := json.Unmarshal(marshalled, &appendLoopResponse)
	// 	return &appendLoopResponse, err
	// default:
	// 	return nil, fmt.Errorf("Unknown merger type %s", mergerType)
	// }
	var benchmarkResponse response.Benchmark
	err := json.Unmarshal(marshalled, &benchmarkResponse)
	return &benchmarkResponse, err
}

func (h *MergeHandler) Call(ctx context.Context, input []byte) ([]byte, error) {
	log.Print("[INFO] Call Merge Result Handler")
	mergeRequest := &MergeRequest{}
	err := json.Unmarshal(input, mergeRequest)
	if err != nil {
		return nil, err
	}
	files, err := ioutil.ReadDir(mergeRequest.Directory)
	mergable, err := h.CreateMergable(mergeRequest.Function)
	if err != nil {
		return nil, err
	}
	merged := 0
	for i, file := range files {
		if !strings.Contains(file.Name(), mergeRequest.Function) {
			continue
		}
		marshalled, err := ioutil.ReadFile(path.Join(mergeRequest.Directory, file.Name()))
		if err != nil {
			return nil, err
		}
		mergeInput, err := h.CreateMergableFromJson(mergeRequest.Function, marshalled)
		if err != nil {
			return nil, err
		}
		if i == 0 {
			mergable = mergeInput
			merged++
			continue
		}
		mergable.Merge(mergeInput)
		merged++
	}

	if len(files) == 0 {
		emptyMergable, err := h.CreateMergable(mergeRequest.Function)
		mergable = emptyMergable
		if err != nil {
			return nil, err
		}
	}

	log.Printf("[INFO] Merged %d files", merged)
	return json.Marshal(mergable)
}
