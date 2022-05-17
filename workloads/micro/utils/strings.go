package utils

import (
	"fmt"
	"math/rand"
	"strings"
)

var letters = []byte("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func KbString() string {
	return strings.Repeat("A", 1024)
}

func CreateRecord(length int) []byte {
	return []byte(strings.Repeat("A", length))
}

func CreateRandomRecord(length int) []byte {
	record := make([]byte, length)
	for i := range record {
		record[i] = letters[rand.Intn(len(letters))]
	}
	return record
}

func HexStr0x(x uint64) string {
	return fmt.Sprintf("%016x", x)
}
