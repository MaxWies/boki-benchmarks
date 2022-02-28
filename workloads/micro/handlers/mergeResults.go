package handlers

import (
	"context"
	"encoding/json"
	"faas-micro/merge"
	"fmt"
	"io/ioutil"
	"log"
	"path"

	"cs.utexas.edu/zjia/faas/types"
)

const (
	MergeType_AppendLoopResponse string = "AppendLoopResponse"
)

type MergeRequest struct {
	Directory    string `json:"Directory"`
	MergableType string `json:"MergableType"`
}

type MergeHandler struct {
}

func NewMergeHandler() types.FuncHandler {
	return &MergeHandler{}
}

func (h *MergeHandler) CreateMergable(mergerType string) (merge.Mergable, error) {
	switch mergerType {
	case MergeType_AppendLoopResponse:
		return AppendLoopResponse{}, nil
	default:
		return nil, fmt.Errorf("Unknown merger type %s", mergerType)
	}
}

func (h *MergeHandler) Call(ctx context.Context, input []byte) ([]byte, error) {
	log.Print("[INFO] Call Merge Result Handler")
	mergeRequest := &MergeRequest{}
	err := json.Unmarshal(input, mergeRequest)
	if err != nil {
		return nil, err
	}
	files, err := ioutil.ReadDir(mergeRequest.Directory)
	mergable, err := h.CreateMergable(mergeRequest.MergableType)
	for i, file := range files {
		marshalled, err := ioutil.ReadFile(path.Join(mergeRequest.Directory, file.Name()))
		if err != nil {
			return nil, err
		}
		var appendLoopResponse AppendLoopResponse
		err = json.Unmarshal(marshalled, &appendLoopResponse)
		if err != nil {
			return nil, err
		}
		if i == 0 {
			mergable = appendLoopResponse
			continue
		}
		mergable.Merge(appendLoopResponse)
	}

	if len(files) == 0 {
		mergable = &AppendLoopResponse{
			Message: "Empty. No results found!",
		}
	}

	log.Printf("[INFO] Merged %d files", len(files))
	return json.Marshal(mergable)
}
