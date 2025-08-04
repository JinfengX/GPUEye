# GPUEye - A GPU Monitoring Application Written by AI

<div align="center">
  <img src="images/app_icon.png" alt="GPUEye Icon" width="128" height="128">
</div>

> [中文文档](README_CN.md) | English

GPUEye is an AI-written macOS utility for real-time remote GPU monitoring.
It connects to remote GPU servers via SSH and provides real-time monitoring of GPU status including temperature, utilization, memory usage, and power consumption.

## Screenshot

<div align="center">
  <img src="images/screenshot.png" alt="GPUEye Screenshot" width="800">
</div>

## Features

- **Real-time GPU Monitoring** - Temperature, utilization, memory, and power consumption
- **SSH Connection Management** - Automatically reads SSH configuration for multiple hosts
- **SSH ProxyJump Support** - Connect through jump servers to access internal GPU hosts
- **Multi-Host Aliases** - Display all host aliases from SSH configuration
- **Window Pinning** - Keep the application window always on top
- **Adjustable Refresh Rate** - Support for 1s, 3s, 5s, 10s, 30s intervals
- **Simplified Design** - Focus on stability and reliability

## System Requirements

- **macOS 14.0+**
- **SSH access** to target GPU hosts
- **nvidia-smi** tool installed on target hosts

## Quick Start

### 1. SSH Configuration

Ensure your SSH config file `~/.ssh/config` contains the GPU hosts you want to monitor:

#### Direct Connection
```ssh
Host gpu-server-01
    HostName 192.168.1.100
    User admin
    Port 22

Host gpu-server-02
    HostName 192.168.1.101
    User root
    Port 22
```

#### Through Jump Server (ProxyJump)
```ssh
# Jump server configuration (with multiple aliases)
Host server1 jump-server
    HostName 192.168.1.100
    User admin
    Port 22

# GPU servers accessible through jump server
Host gpu-server-01
    HostName 10.0.0.50
    User user1
    Port 22
    ProxyJump jump-server

Host gpu-server-02
    HostName 10.0.0.51
    User user2
    Port 22
    ProxyJump jump-server
```

### 2. Build and Run

1. Open `GPUEye.xcodeproj` in Xcode
2. Select Mac as target
3. Build and run

Or build from command line:
```bash
xcodebuild -project GPUEye.xcodeproj -scheme GPUEye -configuration Debug build
```

### 3. Usage

1. Launch the application - it will automatically read SSH configuration
2. Select hosts from the left sidebar
3. Monitor GPU information in real-time
4. Use toolbar controls to adjust refresh rate and window pinning

## Interface Overview

### Left Sidebar
- Lists all available SSH hosts
- Click to select hosts for monitoring
- "Select All" button for convenience

### Main Monitoring Area
- Displays GPU cards for connected hosts
- Shows GPU name, utilization, temperature, power, and memory usage

### Toolbar Controls
- **⏱️ Refresh Rate** - Choose monitoring frequency (1s-30s)
- **🔄 Manual Refresh** - Immediately update all host data
- **⏸️/▶️ Monitor Control** - Pause/resume monitoring
- **📌 Window Pin** - Toggle always-on-top (blue when pinned)

## Troubleshooting

### Connection Failed
1. Check SSH configuration and network connectivity
2. Verify SSH key authentication is set up correctly
3. For jump server connections, ensure the jump server is accessible
4. Use the "Retry" button on host cards

### No GPU Data
1. Confirm nvidia-smi is installed on target hosts
2. Check user permissions for executing nvidia-smi
3. Verify the host actually has NVIDIA GPU devices

### Jump Server Issues
1. Test jump server connectivity manually: `ssh jump-server`
2. Verify ProxyJump configuration in SSH config
3. Check if the jump server can reach the target GPU hosts

## Technical Stack

- **Swift 5.0+** with **SwiftUI**
- **AppKit** for macOS-specific features
- **SSH** for remote connections
- **nvidia-smi** for GPU information retrieval

## Project Structure

```
GPUEye/
├── GPUEyeApp.swift              # Application entry point
├── ContentView.swift            # Main interface
├── GPUCardView.swift            # GPU information cards
├── HostCardView.swift           # Host information cards
├── GPUMonitorService.swift      # Core monitoring logic
├── SSHService.swift             # SSH connection service
├── CoreModels.swift             # Data models
├── Assets.xcassets/             # Application resources
├── GPUEye.entitlements         # App permissions
├── GPUEye.xcodeproj/           # Xcode project
└── README.md                   # Documentation
```

## License

**Open Source - Free to Use**

This project is released under the MIT License. You are free to:
- Use, modify, and distribute this software
- Include it in personal or commercial projects
- Fork and contribute to the project

## Contributing

Contributions welcome! Feel free to fork, submit pull requests, or suggest improvements.

---

*This project was developed with AI assistance.*