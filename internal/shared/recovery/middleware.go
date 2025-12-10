package recovery

import (
	"runtime/debug"

	"go.uber.org/zap"
)

type Recoverer struct {
	logger  *zap.Logger
	metrics MetricsCollector
}

type MetricsCollector interface {
	RecordPanic(location string, panicValue interface{})
}

func NewRecoverer(logger *zap.Logger, metrics MetricsCollector) *Recoverer {
	return &Recoverer{
		logger:  logger,
		metrics: metrics,
	}
}

func (r *Recoverer) WrapGoroutine(name string, fn func()) func() {
	return func() {
		defer func() {
			if p := recover(); p != nil {
				r.logger.Error("goroutine panic recovered",
					zap.String("goroutine", name),
					zap.Any("panic", p),
					zap.ByteString("stack", debug.Stack()),
				)

				if r.metrics != nil {
					r.metrics.RecordPanic(name, p)
				}
			}
		}()

		fn()
	}
}

func (r *Recoverer) SafeGo(name string, fn func()) {
	go r.WrapGoroutine(name, fn)()
}

func (r *Recoverer) Recover(location string) {
	if p := recover(); p != nil {
		r.logger.Error("panic recovered",
			zap.String("location", location),
			zap.Any("panic", p),
			zap.ByteString("stack", debug.Stack()),
		)

		if r.metrics != nil {
			r.metrics.RecordPanic(location, p)
		}
	}
}

func (r *Recoverer) RecoverWithCallback(location string, callback func(panicValue interface{})) {
	if p := recover(); p != nil {
		r.logger.Error("panic recovered with callback",
			zap.String("location", location),
			zap.Any("panic", p),
			zap.ByteString("stack", debug.Stack()),
		)

		if r.metrics != nil {
			r.metrics.RecordPanic(location, p)
		}

		if callback != nil {
			callback(p)
		}
	}
}
