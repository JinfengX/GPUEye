import Foundation

// MARK: - SSH Service

/// SSH服务 - 简化版负责SSH连接和命令执行
class SSHService {
    static let shared = SSHService()
    
    private init() {}
    
    /// 执行SSH命令
    func executeCommand(_ command: String, on host: Host) async throws -> String {
        return try await performSSHCommand(command, on: host)
    }
    
    private func performSSHCommand(_ command: String, on host: Host) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            
            var arguments = [
                "-o", "ConnectTimeout=\(Int(AppConfig.connectionTimeout))",
                "-o", "ServerAliveInterval=5",
                "-o", "ServerAliveCountMax=3",
                "-o", "StrictHostKeyChecking=no",
                "-p", "\(host.port)"
            ]
            
            let connectionString = host.user != nil ? "\(host.user!)@\(host.hostname)" : host.hostname
            arguments.append(connectionString)
            arguments.append(command)
            
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let error = output.isEmpty ? "SSH connection failed" : output
                    continuation.resume(throwing: SSHError.connectionFailed(error))
                }
            } catch {
                continuation.resume(throwing: SSHError.executionFailed(error.localizedDescription))
            }
        }
    }
}

// MARK: - SSH Configuration Reader

/// SSH配置读取器
class SSHConfigReader: ObservableObject {
    @Published var hosts: [Host] = []
    @Published var isLoading = false
    
    private let configPaths = [
        "\(NSHomeDirectory())/.ssh/config",
        "/etc/ssh/ssh_config"
    ]
    
    init() {
        loadConfiguration()
    }
    
    func refresh() {
        loadConfiguration()
    }
    
    private func loadConfiguration() {
        isLoading = true
        
        Task {
            let allHosts = await loadHostsFromConfigs()
            
            await MainActor.run {
                self.hosts = Array(Set(allHosts)).sorted { $0.displayName < $1.displayName }
                self.isLoading = false
            }
        }
    }
    
    private func loadHostsFromConfigs() async -> [Host] {
        var allHosts: [Host] = []
        
        for configPath in configPaths {
            let hosts = await loadHostsFromConfig(at: configPath)
            allHosts.append(contentsOf: hosts)
        }
        
        return allHosts
    }
    
    private func loadHostsFromConfig(at path: String) async -> [Host] {
        guard FileManager.default.fileExists(atPath: path),
              let content = try? String(contentsOfFile: path) else {
            return []
        }
        
        return parseSSHConfig(content)
    }
    
    private func parseSSHConfig(_ content: String) -> [Host] {
        var hosts: [Host] = []
        var currentHost: String?
        var currentHostname: String?
        var currentPort = 22
        var currentUser: String?
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过注释和空行
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            let components = trimmedLine.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            guard components.count >= 2 else { continue }
            
            let keyword = components[0].lowercased()
            let value = components[1]
            
            switch keyword {
            case "host":
                // 保存之前的主机
                if let host = createHost(
                    name: currentHost,
                    hostname: currentHostname,
                    port: currentPort,
                    user: currentUser
                ) {
                    hosts.append(host)
                }
                
                // 重置为新主机
                currentHost = value
                currentHostname = nil
                currentPort = 22
                currentUser = nil
                
            case "hostname":
                currentHostname = value
                
            case "port":
                currentPort = Int(value) ?? 22
                
            case "user":
                currentUser = value
            
            default:
                break
            }
        }
        
        // 保存最后一个主机
        if let host = createHost(
            name: currentHost,
            hostname: currentHostname,
            port: currentPort,
            user: currentUser
        ) {
            hosts.append(host)
        }
        
        return hosts
    }
    
    private func createHost(name: String?, hostname: String?, port: Int, user: String?) -> Host? {
        guard let name = name,
              let hostname = hostname,
              !name.contains("*") && !name.contains("?") else {
            return nil
        }
        
        return Host(
            name: name,
            hostname: hostname,
            port: port,
            user: user
        )
    }
}

// MARK: - SSH Errors

enum SSHError: LocalizedError {
    case connectionFailed(String)
    case executionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .executionFailed(let message):
            return "Execution failed: \(message)"
        }
    }
}