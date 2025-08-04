import SwiftUI
import AppKit

// MARK: - Main Content View

/// 主内容视图 - 简化版
struct ContentView: View {
    @StateObject private var sshConfig = SSHConfigReader()
    @StateObject private var monitorService = GPUMonitorService()
    
    @State private var selectedHosts: Set<UUID> = []
    @State private var isWindowPinned = false
    @AppStorage("refreshInterval") private var refreshInterval: Double = 5.0
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            mainContent
        }
        .navigationTitle("GPU Eye")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarButtons
            }
        }
        .onAppear {
            setupMonitoring()
            monitorService.setUpdateInterval(refreshInterval)
        }
        .onChange(of: selectedHosts) { _, _ in
            updateMonitoredHosts()
        }
        .onChange(of: refreshInterval) { _, newInterval in
            monitorService.setUpdateInterval(newInterval)
        }
        .onChange(of: isWindowPinned) { _, pinned in
            toggleWindowPin(pinned)
        }
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主机列表
            List(sshConfig.hosts, id: \.id, selection: $selectedHosts) { host in
                HostRowView(
                    host: host,
                    isSelected: selectedHosts.contains(host.id)
                )
            }
            .listStyle(.sidebar)
            
            // 简化的底部统计
            VStack(spacing: 8) {
                Divider()
                HStack {
                    Text("主机: \(sshConfig.hosts.count)")
                        .font(.caption)
                    Spacer()
                    Button("全选") {
                        selectedHosts = Set(sshConfig.hosts.map(\.id))
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("主机")
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        Group {
            if monitorService.hostStatuses.isEmpty {
                emptyStateView
            } else {
                monitoringView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "display.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("选择主机开始监控")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("从左侧列表中选择要监控的GPU主机")
                .font(.body)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var monitoringView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 主机卡片
                ForEach(monitorService.hostStatuses) { hostStatus in
                    if hostStatus.isConnected && hostStatus.hasGPUs {
                        HostCardView(hostStatus: hostStatus) {
                            Task {
                                await monitorService.refreshHost(hostStatus.host)
                            }
                        }
                    } else {
                        ErrorStateView(hostStatus: hostStatus) {
                            Task {
                                await monitorService.refreshHost(hostStatus.host)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await monitorService.refreshAll()
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbarButtons: some View {
        HStack {
            // 刷新频率调整
            Menu {
                ForEach([1.0, 3.0, 5.0, 10.0, 30.0], id: \.self) { interval in
                    Button("\(Int(interval))秒") {
                        refreshInterval = interval
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text("\(Int(refreshInterval))s")
                        .font(.caption)
                }
            }
            .help("调整刷新频率")
            
            Button {
                Task {
                    await monitorService.refreshAll()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("刷新所有主机")
            
            Button {
                if monitorService.isRunning {
                    monitorService.stopMonitoring()
                } else {
                    monitorService.startMonitoring()
                }
            } label: {
                Image(systemName: monitorService.isRunning ? "pause.fill" : "play.fill")
            }
            .help(monitorService.isRunning ? "暂停监控" : "开始监控")
            
            Button {
                isWindowPinned.toggle()
            } label: {
                Image(systemName: isWindowPinned ? "pin.fill" : "pin")
                    .foregroundColor(isWindowPinned ? .blue : .primary)
            }
            .help(isWindowPinned ? "取消置顶" : "窗口置顶")
        }
    }
    
    // MARK: - Helper Functions
    
    private func setupMonitoring() {
        // 初始选择所有主机
        selectedHosts = Set(sshConfig.hosts.map(\.id))
        updateMonitoredHosts()
    }
    
    private func updateMonitoredHosts() {
        let selectedHostObjects = sshConfig.hosts.filter { selectedHosts.contains($0.id) }
        monitorService.setHosts(selectedHostObjects)
        
        if !selectedHostObjects.isEmpty && !monitorService.isRunning {
            Task { @MainActor in
                monitorService.startMonitoring()
            }
        }
    }
    
    private func toggleWindowPin(_ pinned: Bool) {
        guard let window = NSApp.windows.first else { return }
        
        if pinned {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            window.level = .normal
            window.collectionBehavior = [.canJoinAllSpaces]
        }
    }
}

/// 主机行视图 - 简化版
struct HostRowView: View {
    let host: Host
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(host.displayName)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
            
            // 显示所有别名（如果有的话）
            if !host.aliases.isEmpty {
                Text("别名: \(host.aliases.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(host.connectionString)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 显示跳板机信息
            if let proxyJump = host.proxyJump {
                HStack(spacing: 4) {
                    Image(systemName: "network")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("跳板机: \(proxyJump)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}