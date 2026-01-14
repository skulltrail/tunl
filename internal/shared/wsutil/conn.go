package wsutil

import (
	"io"
	"net"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// Conn wraps a gorilla/websocket.Conn to implement net.Conn.
// It uses binary messages for data transfer, making it compatible
// with yamux and the existing frame protocol.
type Conn struct {
	ws         *websocket.Conn
	reader     io.Reader
	readMu     sync.Mutex
	writeMu    sync.Mutex
	localAddr  net.Addr
	remoteAddr net.Addr
	pingStop   chan struct{}
	pingOnce   sync.Once
}

// NewConn wraps a WebSocket connection as a net.Conn.
func NewConn(ws *websocket.Conn) *Conn {
	c := &Conn{
		ws:         ws,
		localAddr:  ws.LocalAddr(),
		remoteAddr: ws.RemoteAddr(),
		pingStop:   make(chan struct{}),
	}
	return c
}

// NewConnWithPing wraps a WebSocket connection and starts a ping loop
// to keep the connection alive through CDN/proxies.
func NewConnWithPing(ws *websocket.Conn, pingInterval time.Duration) *Conn {
	c := NewConn(ws)
	c.startPingLoop(pingInterval)
	return c
}

// Read reads data from the WebSocket connection.
// It handles WebSocket message boundaries transparently, presenting
// a continuous byte stream to the caller.
func (c *Conn) Read(p []byte) (int, error) {
	c.readMu.Lock()
	defer c.readMu.Unlock()

	for {
		if c.reader == nil {
			messageType, reader, err := c.ws.NextReader()
			if err != nil {
				return 0, err
			}
			// Only accept binary messages for tunnel data
			if messageType != websocket.BinaryMessage {
				// Skip non-binary messages (text, ping/pong handled by gorilla)
				continue
			}
			c.reader = reader
		}

		n, err := c.reader.Read(p)
		if err == io.EOF {
			// Current message exhausted, get next message
			c.reader = nil
			if n > 0 {
				return n, nil
			}
			continue
		}
		return n, err
	}
}

// Write writes data to the WebSocket connection as a binary message.
func (c *Conn) Write(p []byte) (int, error) {
	c.writeMu.Lock()
	defer c.writeMu.Unlock()

	err := c.ws.WriteMessage(websocket.BinaryMessage, p)
	if err != nil {
		return 0, err
	}
	return len(p), nil
}

// Close closes the WebSocket connection.
func (c *Conn) Close() error {
	c.pingOnce.Do(func() {
		close(c.pingStop)
	})

	// Send close message before closing
	c.writeMu.Lock()
	_ = c.ws.WriteMessage(websocket.CloseMessage,
		websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
	c.writeMu.Unlock()

	return c.ws.Close()
}

// LocalAddr returns the local network address.
func (c *Conn) LocalAddr() net.Addr {
	return c.localAddr
}

// RemoteAddr returns the remote network address.
func (c *Conn) RemoteAddr() net.Addr {
	return c.remoteAddr
}

// SetDeadline sets the read and write deadlines.
func (c *Conn) SetDeadline(t time.Time) error {
	if err := c.ws.SetReadDeadline(t); err != nil {
		return err
	}
	return c.ws.SetWriteDeadline(t)
}

// SetReadDeadline sets the read deadline.
func (c *Conn) SetReadDeadline(t time.Time) error {
	return c.ws.SetReadDeadline(t)
}

// SetWriteDeadline sets the write deadline.
func (c *Conn) SetWriteDeadline(t time.Time) error {
	return c.ws.SetWriteDeadline(t)
}

// startPingLoop starts a goroutine that sends periodic ping messages
// to keep the connection alive through CDN/proxies like Cloudflare.
func (c *Conn) startPingLoop(interval time.Duration) {
	if interval <= 0 {
		interval = 30 * time.Second
	}

	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		for {
			select {
			case <-c.pingStop:
				return
			case <-ticker.C:
				c.writeMu.Lock()
				err := c.ws.WriteControl(
					websocket.PingMessage,
					[]byte{},
					time.Now().Add(10*time.Second),
				)
				c.writeMu.Unlock()
				if err != nil {
					return
				}
			}
		}
	}()
}

// UnderlyingConn returns the underlying WebSocket connection.
// Use with caution as direct access bypasses the mutex protection.
func (c *Conn) UnderlyingConn() *websocket.Conn {
	return c.ws
}
