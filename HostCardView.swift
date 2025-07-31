import SwiftUI

// MARK: - Host Card View

/// 主机卡片视图 - 简化版显示主机及其GPU信息
struct HostCardView: View {
    @ObservedObject var hostStatus: HostStatus
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 主机头部
            hostHeader
            
            // GPU列表
            if hostStatus.hasGPUs {
                Divider()
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: adaptiveColumns),
                    spacing: 16
                ) {
                    ForEach(hostStatus.gpus) { gpu in
                        GPUCardView(gpu: gpu)
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Host Header
    
    private var hostHeader: some View {
        HStack(spacing: 12) {
            // 连接状态指示器
            Circle()
                .fill(connectionColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(hostStatus.host.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(hostStatus.host.connectionString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 统计信息
            if hostStatus.isConnected && hostStatus.hasGPUs {
                hostStatsView
            }
            
            // 刷新按钮
            Button {
                onRefresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var hostStatsView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 16) {
                StatView(
                    title: "GPUs",
                    value: "\(hostStatus.gpus.count)",
                    color: .blue
                )
                
                StatView(
                    title: "活跃",
                    value: "\(hostStatus.activeGPUCount)",
                    color: .green
                )
                
                StatView(
                    title: "平均利用率",
                    value: String(format: "%.0f%%", hostStatus.averageUtilization),
                    color: utilizationColor(hostStatus.averageUtilization)
                )
                
                if hostStatus.maxTemperature > 0 {
                    StatView(
                        title: "最高温度",
                        value: "\(hostStatus.maxTemperature)°C",
                        color: temperatureColor(hostStatus.maxTemperature)
                    )
                }
            }
            
            Text("更新于 \(formatTime(hostStatus.lastUpdate))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    

    
    // MARK: - Computed Properties
    
    private var connectionColor: Color {
        if hostStatus.isConnected {
            return .green
        } else {
            return .red
        }
    }
    
    private var adaptiveColumns: Int {
        let gpuCount = hostStatus.gpus.count
        if gpuCount <= 2 { return 1 }
        if gpuCount <= 4 { return 2 }
        return 3
    }
    
    // MARK: - Helper Functions
    
    private func utilizationColor(_ utilization: Double) -> Color {
        switch utilization {
        case 0..<30: return .green
        case 30..<70: return .orange
        default: return .red
        }
    }
    
    private func temperatureColor(_ temperature: Int) -> Color {
        switch temperature {
        case 0..<60: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Stat View

/// 统计信息视图
struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error State View

/// 错误状态视图 - 简化版
struct ErrorStateView: View {
    @ObservedObject var hostStatus: HostStatus
    let onRefresh: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("连接失败")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let error = hostStatus.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button("重试") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview {
    let sampleHost = Host(
        name: "example-server",
        hostname: "example.com",
        port: 22,
        user: "user"
    )
    
    let sampleGPUs = [
        GPU(index: 0, name: "RTX 4090", temperature: 65, powerUsage: 320, powerLimit: 450, memoryUsed: 8192, memoryTotal: 24576, gpuUtilization: 85, memoryUtilization: 75),
        GPU(index: 1, name: "RTX 4090", temperature: 68, powerUsage: 280, powerLimit: 450, memoryUsed: 12288, memoryTotal: 24576, gpuUtilization: 92, memoryUtilization: 50)
    ]
    
    let hostStatus = HostStatus(host: sampleHost)
    hostStatus.gpus = sampleGPUs
    hostStatus.isConnected = true
    
    return VStack {
        HostCardView(hostStatus: hostStatus) {
            print("Refresh requested")
        }
        
        ErrorStateView(hostStatus: HostStatus(host: sampleHost)) {
            print("Retry requested")
        }
    }
    .padding()
}