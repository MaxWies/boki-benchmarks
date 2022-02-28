package utils

import (
	"io/ioutil"
	"os"
)

func CreateOutputDirectory(outputDirectoryPath string) error {
	_, err := os.Stat(outputDirectoryPath)
	if err == nil {
		os.RemoveAll(outputDirectoryPath)
	}
	return os.MkdirAll(outputDirectoryPath, os.ModePerm)
}

func WriteToFile(filePath string, data []byte) error {
	return ioutil.WriteFile(filePath, data, 0644)
}
