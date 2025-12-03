package protocol

import (
	"encoding/binary"
	"errors"

	"drip/internal/shared/pool"
)

// EncodeDataPayload encodes a data header and payload into a frame payload.
// Deprecated: Use EncodeDataPayloadPooled for better performance.
func EncodeDataPayload(header DataHeader, data []byte) ([]byte, error) {
	streamIDLen := len(header.StreamID)
	requestIDLen := len(header.RequestID)

	totalLen := binaryHeaderMinSize + streamIDLen + requestIDLen + len(data)
	payload := make([]byte, totalLen)

	flags := uint8(header.Type) & 0x07
	if header.IsLast {
		flags |= 0x08
	}
	payload[0] = flags

	binary.BigEndian.PutUint16(payload[1:3], uint16(streamIDLen))
	binary.BigEndian.PutUint16(payload[3:5], uint16(requestIDLen))

	offset := binaryHeaderMinSize
	copy(payload[offset:], header.StreamID)
	offset += streamIDLen
	copy(payload[offset:], header.RequestID)
	offset += requestIDLen
	copy(payload[offset:], data)

	return payload, nil
}

// EncodeDataPayloadPooled encodes with adaptive allocation based on load.
// Returns payload slice and pool buffer pointer (may be nil).
//
// Adaptive strategy:
// - Mid-load (<150 conn):   256KB threshold, pool disabled → max QPS
// - High-load (≥300 conn):  32KB threshold, pool enabled → stable latency
// - Transition (150-300):   Hysteresis to prevent flapping
func EncodeDataPayloadPooled(header DataHeader, data []byte) (payload []byte, poolBuffer *[]byte, err error) {
	streamIDLen := len(header.StreamID)
	requestIDLen := len(header.RequestID)
	totalLen := binaryHeaderMinSize + streamIDLen + requestIDLen + len(data)

	dynamicThreshold := GetAdaptiveThreshold()

	if totalLen < dynamicThreshold {
		regularPayload, err := EncodeDataPayload(header, data)
		return regularPayload, nil, err
	}

	if totalLen > pool.SizeLarge {
		regularPayload, err := EncodeDataPayload(header, data)
		return regularPayload, nil, err
	}

	poolBuffer = pool.GetBuffer(totalLen)
	payload = (*poolBuffer)[:totalLen]

	flags := uint8(header.Type) & 0x07
	if header.IsLast {
		flags |= 0x08
	}
	payload[0] = flags

	binary.BigEndian.PutUint16(payload[1:3], uint16(streamIDLen))
	binary.BigEndian.PutUint16(payload[3:5], uint16(requestIDLen))

	offset := binaryHeaderMinSize
	copy(payload[offset:], header.StreamID)
	offset += streamIDLen
	copy(payload[offset:], header.RequestID)
	offset += requestIDLen
	copy(payload[offset:], data)

	return payload, poolBuffer, nil
}

// DecodeDataPayload decodes a frame payload into header and data.
func DecodeDataPayload(payload []byte) (DataHeader, []byte, error) {
	if len(payload) < binaryHeaderMinSize {
		return DataHeader{}, nil, errors.New("invalid payload: too short")
	}

	var header DataHeader
	if err := header.UnmarshalBinary(payload); err != nil {
		return DataHeader{}, nil, err
	}

	headerSize := header.Size()
	if len(payload) < headerSize {
		return DataHeader{}, nil, errors.New("invalid payload: data missing")
	}

	data := payload[headerSize:]
	return header, data, nil
}

func GetPayloadHeaderSize(header DataHeader) int {
	return header.Size()
}
