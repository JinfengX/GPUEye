import Foundation
import Combine

// MARK: - GPU Monitor Service

/// GPU监控服务 - 简化版核心监控逻辑
@MainActor
class GPUMonitorService: ObservableObject {
    @Published var hostStatuses: [HostStatus] = []
    @Published var isRunning = false
    @Published var lastUpdateTime = Date()
    
    private var timer: Timer?
    private var updateInterval: TimeInterval = 5.0
    
    init() {
        print("🔧 GPUMonitorService 初始化")
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        print("🗑️ GPUMonitorService 已销毁")
    }
    
    /// 设置要监控的主机
    func setHosts(_ hosts: [Host]) {
        let validHosts = hosts.filter(\.isValid)
        hostStatuses = validHosts.map { HostStatus(host: $0) }
        
        print("📋 设置监控主机: \(validHosts.count) 个")
        
        // 如果有主机且监控未运行，自动开始监控
        if !validHosts.isEmpty && !isRunning {
            startMonitoring()
        }
    }
    
    /// 设置更新间隔
    func setUpdateInterval(_ interval: TimeInterval) {
        updateInterval = interval
        print("⏱️ 设置更新间隔为: \(interval)秒")
        
        // 如果监控正在运行，重新启动定时器
        if isRunning {
            restartTimer()
        }
    }
    
    /// 开始监控
    func startMonitoring() {
        guard !isRunning else { 
            print("⚠️ 监控已在运行，跳过启动")
            return 
        }
        
        guard !hostStatuses.isEmpty else {
            print("⚠️ 没有要监控的主机，跳过启动")
            return
        }
        
        print("🚀 开始启动监控服务，主机数量: \(hostStatuses.count)")
        isRunning = true
        
        startTimer()
        
        // 立即执行一次更新
        Task { @MainActor in
            await updateAllHosts()
        }
    }
    
    /// 启动定时器
    private func startTimer() {
        // 停止现有定时器
        timer?.invalidate()
        
        // 创建新的定时器
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isRunning else { return }
                await self.updateAllHosts()
            }
        }
        
        print("⏰ 定时器已启动，间隔: \(updateInterval)秒")
    }
    
    /// 重启定时器
    private func restartTimer() {
        guard isRunning else { return }
        startTimer()
    }
    
    /// 停止监控
    func stopMonitoring() {
        print("🛑 停止监控服务")
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    /// 刷新特定主机
    func refreshHost(_ host: Host) async {
        print("🔄 刷新主机: \(host.displayName)")
        
        do {
            let gpus = try await fetchGPUData(from: host)
            await MainActor.run {
                updateHostStatus(host, gpus: gpus, error: nil)
            }
        } catch {
            print("❌ 刷新主机失败: \(host.displayName) - \(error.localizedDescription)")
            await MainActor.run {
                updateHostStatus(host, gpus: [], error: error.localizedDescription)
            }
        }
    }
    
    /// 刷新所有主机
    func refreshAll() async {
        print("🔄 刷新所有主机")
        await updateAllHosts()
    }
    
    // MARK: - Private Methods
    
    private func updateAllHosts() async {
        guard isRunning, !hostStatuses.isEmpty else { 
            print("⚠️ 跳过更新 - 监控未运行或无主机")
            return 
        }
        
        print("📡 开始更新 \(hostStatuses.count) 个主机")
        
        // 简化的串行更新
        for hostStatus in hostStatuses {
            do {
                let gpus = try await fetchGPUData(from: hostStatus.host)
                await MainActor.run {
                    updateHostStatus(hostStatus.host, gpus: gpus, error: nil)
                }
            } catch {
                print("❌ 更新主机失败: \(hostStatus.host.displayName) - \(error.localizedDescription)")
                await MainActor.run {
                    updateHostStatus(hostStatus.host, gpus: [], error: error.localizedDescription)
                }
            }
        }
        
        // 更新最后更新时间
        await MainActor.run {
            lastUpdateTime = Date()
            objectWillChange.send()
        }
        
        print("✅ 所有主机更新完成")
    }
    
    private func fetchGPUData(from host: Host) async throws -> [GPU] {
        let command = "nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw,power.limit,memory.used,memory.total,utilization.gpu,utilization.memory --format=csv,noheader,nounits"
        
        let output = try await SSHService.shared.executeCommand(command, on: host)
        return parseGPUData(output)
    }
    
    private func parseGPUData(_ output: String) -> [GPU] {
        let lines = output.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var gpus: [GPU] = []
        
        for line in lines {
            let components = line.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            guard components.count >= 9 else { continue }
            
            guard let index = Int(components[0]),
                  let temperature = Int(components[2]),
                  let powerUsage = Double(components[3]),
                  let powerLimit = Double(components[4]),
                  let memoryUsed = Int(components[5]),
                  let memoryTotal = Int(components[6]),
                  let gpuUtilization = Int(components[7]),
                  let memoryUtilization = Int(components[8]) else {
                continue
            }
            
            let gpu = GPU(
                index: index,
                name: components[1],
                temperature: temperature,
                powerUsage: powerUsage,
                powerLimit: powerLimit,
                memoryUsed: memoryUsed,
                memoryTotal: memoryTotal,
                gpuUtilization: gpuUtilization,
                memoryUtilization: memoryUtilization
            )
            
            if gpu.isValid {
                gpus.append(gpu)
            }
        }
        
        return gpus.sorted { $0.index < $1.index }
    }
    
    private func updateHostStatus(_ host: Host, gpus: [GPU], error: String?) {
        guard let index = hostStatuses.firstIndex(where: { $0.host.id == host.id }) else {
            return
        }
        
        // 更新主机状态
        hostStatuses[index].gpus = gpus
        hostStatuses[index].isConnected = error == nil
        hostStatuses[index].lastUpdate = Date()
        hostStatuses[index].errorMessage = error
        
        // 触发UI更新
        hostStatuses[index].objectWillChange.send()
        objectWillChange.send()
    }
    

}

