package test

import "time"

type ContextMock struct {
}

func (c *ContextMock) Deadline() (deadline time.Time, ok bool) {
	return time.Now(), true
}

func (c *ContextMock) Done() <-chan struct{} {
	return nil
}

func (c *ContextMock) Err() error {
	return nil
}

func (c *ContextMock) Value(key interface{}) interface{} {
	return nil
}
