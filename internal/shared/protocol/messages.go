package protocol

import json "github.com/goccy/go-json"

// RegisterRequest is sent by client to register a tunnel
type RegisterRequest struct {
	Token           string     `json:"token"`            // Authentication token
	CustomSubdomain string     `json:"custom_subdomain"` // Optional custom subdomain
	TunnelType      TunnelType `json:"tunnel_type"`      // http, tcp, udp
	LocalPort       int        `json:"local_port"`       // Local port to forward to
}

// RegisterResponse is sent by server after successful registration
type RegisterResponse struct {
	Subdomain string `json:"subdomain"`        // Assigned subdomain
	Port      int    `json:"port,omitempty"`   // Assigned TCP port (for TCP tunnels)
	URL       string `json:"url"`              // Full tunnel URL
	Message   string `json:"message"`          // Success message
}

// ErrorMessage represents an error
type ErrorMessage struct {
	Code    string `json:"code"`    // Error code
	Message string `json:"message"` // Error message
}

// Note: DataHeader is now defined in binary_header.go as a pure binary structure
// TCPData has been removed - use DataHeader + raw bytes directly

// Marshal helpers for control plane messages (JSON encoding)
func MarshalJSON(v interface{}) ([]byte, error) {
	return json.Marshal(v)
}

func UnmarshalJSON(data []byte, v interface{}) error {
	return json.Unmarshal(data, v)
}
