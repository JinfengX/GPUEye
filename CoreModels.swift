import Foundation

// MARK: - Core Data Models

/// SSH主机配置
struct Host: Identifiable, Hashable {
    var id = UUID()
    let name: String
    let hostname: String
    let port: Int
    let user: String?
    let proxyJump: String?
    let aliases: [String] // 支持多个别名
    
    var displayName: String {
        name.isEmpty ? hostname : name
    }
    
    var allNames: String {
        var names = [name]
        names.append(contentsOf: aliases)
        return names.filter { !$0.isEmpty }.joined(separator: ", ")
    }
    
    var connectionString: String {
        var result = ""
        if let user = user {
            result += "\(user)@"
        }
        result += hostname
        if port != 22 {
            result += ":\(port)"
        }
        if let proxyJump = proxyJump {
            result += " (via \(proxyJump))"
        }
        return result
    }
    
    var isValid: Bool {
        !hostname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        port > 0 && port < 65536
    }
}

/// GPU设备信息
struct GPU: Identifiable, Equatable {
    let index: Int
    let name: String
    let temperature: Int
    let powerUsage: Double
    let powerLimit: Double
    let memoryUsed: Int
    let memoryTotal: Int
    let gpuUtilization: Int
    let memoryUtilization: Int
    
    // 稳定的ID，基于GPU索引
    var id: String { "gpu-\(index)" }
    
    var memoryUsagePercent: Double {
        guard memoryTotal > 0 else { return 0 }
        return Double(memoryUsed) / Double(memoryTotal) * 100
    }
    
    var powerUsagePercent: Double {
        guard powerLimit > 0 else { return 0 }
        return powerUsage / powerLimit * 100
    }
    
    var formattedMemoryUsage: String {
        let usedGB = Double(memoryUsed) / 1024
        let totalGB = Double(memoryTotal) / 1024
        return String(format: "%.1f / %.1f GB", usedGB, totalGB)
    }
    
    var isValid: Bool {
        index >= 0 &&
        !name.isEmpty &&
        temperature >= 0 && temperature <= 200 &&
        powerUsage >= 0 && powerUsage <= 1000 &&
        memoryUsed >= 0 && memoryTotal > 0 &&
        gpuUtilization >= 0 && gpuUtilization <= 100 &&
        memoryUtilization >= 0 && memoryUtilization <= 100
    }
    
    // 实现Equatable协议，用于检测GPU数据变化
    static func == (lhs: GPU, rhs: GPU) -> Bool {
        return lhs.index == rhs.index &&
               lhs.name == rhs.name &&
               lhs.temperature == rhs.temperature &&
               lhs.powerUsage == rhs.powerUsage &&
               lhs.powerLimit == rhs.powerLimit &&
               lhs.memoryUsed == rhs.memoryUsed &&
               lhs.memoryTotal == rhs.memoryTotal &&
               lhs.gpuUtilization == rhs.gpuUtilization &&
               lhs.memoryUtilization == rhs.memoryUtilization
    }
}

/// 主机状态 - 简化版继承ObservableObject以支持UI更新
@MainActor
class HostStatus: ObservableObject, @preconcurrency Identifiable {
    var id: UUID { host.id }
    let host: Host
    
    @Published var gpus: [GPU] = []
    @Published var isConnected: Bool = false
    @Published var lastUpdate: Date = Date()
    @Published var errorMessage: String?
    
    init(host: Host) {
        self.host = host
    }
    
    var hasGPUs: Bool {
        !gpus.isEmpty
    }
    
    var activeGPUCount: Int {
        gpus.filter { $0.gpuUtilization > 10 }.count
    }
    
    var averageUtilization: Double {
        guard !gpus.isEmpty else { return 0 }
        return Double(gpus.reduce(0) { $0 + $1.gpuUtilization }) / Double(gpus.count)
    }
    
    var maxTemperature: Int {
        gpus.map(\.temperature).max() ?? 0
    }
}

// MARK: - Configuration

/// 应用配置
struct AppConfig {
    static let connectionTimeout: TimeInterval = 10.0
}