package utils

import "strings"

func KbString() string {
	return strings.Repeat("A", 1024)
}

func CreateRecord(length int) []byte {
	return []byte(strings.Repeat("A", length))
}
