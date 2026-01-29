package pool

import (
	"bufio"
	"sync"
)

// BufioReaderPool provides a pool of bufio.Reader instances.
var BufioReaderPool = sync.Pool{
	New: func() interface{} {
		return bufio.NewReaderSize(nil, 32*1024)
	},
}

// BufioWriterPool provides a pool of bufio.Writer instances.
var BufioWriterPool = sync.Pool{
	New: func() interface{} {
		return bufio.NewWriterSize(nil, 4096)
	},
}

// GetReader gets a bufio.Reader from the pool and resets it to read from r.
func GetReader(r interface{}) *bufio.Reader {
	reader := BufioReaderPool.Get().(*bufio.Reader)
	if resetter, ok := r.(interface{ Reset(interface{}) }); ok {
		resetter.Reset(r)
	}
	return reader
}

// PutReader returns a bufio.Reader to the pool.
func PutReader(reader *bufio.Reader) {
	BufioReaderPool.Put(reader)
}

// GetWriter gets a bufio.Writer from the pool and resets it to write to w.
func GetWriter(w interface{}) *bufio.Writer {
	writer := BufioWriterPool.Get().(*bufio.Writer)
	if resetter, ok := w.(interface{ Reset(interface{}) }); ok {
		resetter.Reset(w)
	}
	return writer
}

// PutWriter returns a bufio.Writer to the pool.
func PutWriter(writer *bufio.Writer) {
	BufioWriterPool.Put(writer)
}
