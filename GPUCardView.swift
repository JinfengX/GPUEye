import SwiftUI

// MARK: - GPU Card View

/// GPU卡片视图 - 简化版显示单个GPU的详细信息
struct GPUCardView: View {
    let gpu: GPU
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack {
                Text(gpu.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text("GPU \(gpu.index)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // 指标网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                MetricView(
                    title: "利用率",
                    value: "\(gpu.gpuUtilization)%",
                    color: utilizationColor(gpu.gpuUtilization)
                )
                
                MetricView(
                    title: "温度",
                    value: "\(gpu.temperature)°C",
                    color: temperatureColor(gpu.temperature)
                )
                
                MetricView(
                    title: "功耗",
                    value: String(format: "%.0f/%.0fW", gpu.powerUsage, gpu.powerLimit),
                    color: powerColor(gpu.powerUsagePercent)
                )
                
                MetricView(
                    title: "显存",
                    value: gpu.formattedMemoryUsage,
                    color: memoryColor(gpu.memoryUsagePercent)
                )
            }
            
            // 简化的进度条
            VStack(spacing: 6) {
                ProgressBarView(
                    title: "GPU利用率",
                    value: Double(gpu.gpuUtilization),
                    color: utilizationColor(gpu.gpuUtilization)
                )
                
                ProgressBarView(
                    title: "显存使用",
                    value: gpu.memoryUsagePercent,
                    color: memoryColor(gpu.memoryUsagePercent)
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Color Functions
    
    private func utilizationColor(_ utilization: Int) -> Color {
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
    
    private func powerColor(_ percent: Double) -> Color {
        switch percent {
        case 0..<70: return .green
        case 70..<90: return .orange
        default: return .red
        }
    }
    
    private func memoryColor(_ percent: Double) -> Color {
        switch percent {
        case 0..<70: return .green
        case 70..<90: return .orange
        default: return .red
        }
    }
}

// MARK: - Metric View

/// 指标显示视图
struct MetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Progress Bar View

/// 进度条视图 - 简化版
struct ProgressBarView: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.1f%%", value))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (value / 100), height: 4)
                }
            }
            .frame(height: 4)
            .cornerRadius(2)
        }
    }
}

// MARK: - Previews

#Preview {
    let sampleGPU = GPU(
        index: 0,
        name: "NVIDIA GeForce RTX 4090",
        temperature: 65,
        powerUsage: 320,
        powerLimit: 450,
        memoryUsed: 8192,
        memoryTotal: 24576,
        gpuUtilization: 85,
        memoryUtilization: 75
    )
    
    return GPUCardView(gpu: sampleGPU)
        .frame(width: 300)
        .padding()
}