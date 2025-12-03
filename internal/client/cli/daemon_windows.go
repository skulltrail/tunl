//go:build windows

package cli

import (
	"os"
	"os/exec"
	"syscall"
)

// getSysProcAttr returns platform-specific process attributes for daemonization
func getSysProcAttr() *syscall.SysProcAttr {
	return &syscall.SysProcAttr{
		CreationFlags: syscall.CREATE_NEW_PROCESS_GROUP,
	}
}

// isProcessRunningOS checks if a process is running using OS-specific method
func isProcessRunningOS(process *os.Process) bool {
	err := process.Signal(os.Signal(syscall.Signal(0)))
	if err != nil {
		return false
	}
	return true
}

// killProcessOS kills a process using OS-specific method
func killProcessOS(process *os.Process) error {
	// On Windows, use Kill() directly
	return process.Kill()
}

// setupDaemonCmd configures the command for daemon mode
func setupDaemonCmd(cmd *exec.Cmd) {
	cmd.SysProcAttr = getSysProcAttr()
}
