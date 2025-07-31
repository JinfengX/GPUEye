# GPUEye - GPU Monitoring Application

A simplified GPU monitoring application for macOS that connects to remote GPU servers via SSH and provides real-time monitoring of GPU status including temperature, utilization, memory usage, and power consumption.

## Features

- **Real-time GPU Monitoring** - Temperature, utilization, memory, and power consumption
- **SSH Connection Management** - Automatically reads SSH configuration for multiple hosts
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
3. Use the "Retry" button on host cards

### No GPU Data
1. Confirm nvidia-smi is installed on target hosts
2. Check user permissions for executing nvidia-smi
3. Verify the host actually has NVIDIA GPU devices

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

© 2024 GPU Eye. All rights reserved.

---

*This project was developed with AI assistance.*