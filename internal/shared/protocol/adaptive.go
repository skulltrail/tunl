package protocol

import (
	"sync/atomic"
	"time"

	"drip/internal/shared/pool"
)

// AdaptivePoolManager dynamically adjusts buffer pool usage based on load
type AdaptivePoolManager struct {
	activeConnections           atomic.Int64
	currentThreshold            atomic.Int64
	highLoadConnectionThreshold int64
	midLoadConnectionThreshold  int64
	midLoadThreshold            int64
	highLoadThreshold           int64
}

var globalAdaptiveManager = NewAdaptivePoolManager()

func NewAdaptivePoolManager() *AdaptivePoolManager {
	m := &AdaptivePoolManager{
		highLoadConnectionThreshold: 300,
		midLoadConnectionThreshold:  150,
		midLoadThreshold:            int64(pool.SizeLarge),
		highLoadThreshold:           int64(pool.SizeMedium),
	}

	m.currentThreshold.Store(m.midLoadThreshold)
	go m.monitor()

	return m
}

func (m *AdaptivePoolManager) monitor() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		connections := m.activeConnections.Load()

		if connections >= m.highLoadConnectionThreshold {
			m.currentThreshold.Store(m.highLoadThreshold)
		} else if connections < m.midLoadConnectionThreshold {
			m.currentThreshold.Store(m.midLoadThreshold)
		}
		// Hysteresis zone (150-300): maintain current threshold
	}
}

func (m *AdaptivePoolManager) GetThreshold() int {
	return int(m.currentThreshold.Load())
}

func (m *AdaptivePoolManager) RegisterConnection() {
	m.activeConnections.Add(1)
}

func (m *AdaptivePoolManager) UnregisterConnection() {
	m.activeConnections.Add(-1)
}

func (m *AdaptivePoolManager) GetActiveConnections() int64 {
	return m.activeConnections.Load()
}

func GetAdaptiveThreshold() int {
	return globalAdaptiveManager.GetThreshold()
}

func RegisterConnection() {
	globalAdaptiveManager.RegisterConnection()
}

func UnregisterConnection() {
	globalAdaptiveManager.UnregisterConnection()
}

func GetActiveConnections() int64 {
	return globalAdaptiveManager.GetActiveConnections()
}
