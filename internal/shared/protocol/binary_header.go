package protocol

import (
	"encoding/binary"
	"errors"
)

// DataHeader represents a binary-encoded data header for data plane
// All data transmission uses pure binary encoding for performance
type DataHeader struct {
	Type      DataType
	IsLast    bool
	StreamID  string
	RequestID string
}

// DataType represents the type of data frame
type DataType uint8

const (
	DataTypeData         DataType = 0x00 // 000
	DataTypeResponse     DataType = 0x01 // 001
	DataTypeClose        DataType = 0x02 // 010
	DataTypeHTTPRequest  DataType = 0x03 // 011
	DataTypeHTTPResponse DataType = 0x04 // 100
)

// String returns the string representation of DataType
func (t DataType) String() string {
	switch t {
	case DataTypeData:
		return "data"
	case DataTypeResponse:
		return "response"
	case DataTypeClose:
		return "close"
	case DataTypeHTTPRequest:
		return "http_request"
	case DataTypeHTTPResponse:
		return "http_response"
	default:
		return "unknown"
	}
}

// FromString converts a string to DataType
func DataTypeFromString(s string) DataType {
	switch s {
	case "data":
		return DataTypeData
	case "response":
		return DataTypeResponse
	case "close":
		return DataTypeClose
	case "http_request":
		return DataTypeHTTPRequest
	case "http_response":
		return DataTypeHTTPResponse
	default:
		return DataTypeData
	}
}

// Binary format:
// +--------+--------+--------+--------+--------+
// | Flags  | StreamID Length | RequestID Len  |
// | 1 byte | 2 bytes         | 2 bytes        |
// +--------+--------+--------+--------+--------+
// | StreamID (variable)                       |
// +--------+--------+--------+--------+--------+
// | RequestID (variable)                      |
// +--------+--------+--------+--------+--------+
//
// Flags (8 bits):
// - Bit 0-2: Type (3 bits)
// - Bit 3: IsLast (1 bit)
// - Bit 4-7: Reserved (4 bits)

const (
	binaryHeaderMinSize = 5 // 1 byte flags + 2 bytes streamID len + 2 bytes requestID len
)

// MarshalBinary encodes the header to binary format
func (h *DataHeader) MarshalBinary() []byte {
	streamIDLen := len(h.StreamID)
	requestIDLen := len(h.RequestID)

	totalLen := binaryHeaderMinSize + streamIDLen + requestIDLen
	buf := make([]byte, totalLen)

	// Encode flags
	flags := uint8(h.Type) & 0x07 // Type uses bits 0-2
	if h.IsLast {
		flags |= 0x08 // IsLast uses bit 3
	}
	buf[0] = flags

	// Encode lengths (big-endian)
	binary.BigEndian.PutUint16(buf[1:3], uint16(streamIDLen))
	binary.BigEndian.PutUint16(buf[3:5], uint16(requestIDLen))

	// Encode StreamID
	offset := binaryHeaderMinSize
	copy(buf[offset:], h.StreamID)
	offset += streamIDLen

	// Encode RequestID
	copy(buf[offset:], h.RequestID)

	return buf
}

// UnmarshalBinary decodes the header from binary format
func (h *DataHeader) UnmarshalBinary(data []byte) error {
	if len(data) < binaryHeaderMinSize {
		return errors.New("invalid binary header: too short")
	}

	// Decode flags
	flags := data[0]
	h.Type = DataType(flags & 0x07)      // Bits 0-2
	h.IsLast = (flags & 0x08) != 0       // Bit 3

	// Decode lengths
	streamIDLen := int(binary.BigEndian.Uint16(data[1:3]))
	requestIDLen := int(binary.BigEndian.Uint16(data[3:5]))

	// Validate total length
	expectedLen := binaryHeaderMinSize + streamIDLen + requestIDLen
	if len(data) < expectedLen {
		return errors.New("invalid binary header: length mismatch")
	}

	// Decode StreamID
	offset := binaryHeaderMinSize
	h.StreamID = string(data[offset : offset+streamIDLen])
	offset += streamIDLen

	// Decode RequestID
	h.RequestID = string(data[offset : offset+requestIDLen])

	return nil
}

// Size returns the size of the binary-encoded header
func (h *DataHeader) Size() int {
	return binaryHeaderMinSize + len(h.StreamID) + len(h.RequestID)
}
