import SwiftUI
import Combine

@main
struct RazerControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 不再显示默认窗口，只通过菜单栏打开
        Settings {
            EmptyView()
        }
        .commands {
            // 移除默认的命令，防止意外退出
            CommandGroup(replacing: .appInfo) {
                Button("About RazerControl") {
                    // 可以添加关于窗口
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button("Preferences...") {
                    appDelegate.showSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?
    private var shouldReallyQuit = false  // 标志控制真正的退出
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        
        // Start device discovery
        RazerDeviceManager.shared().startDeviceDiscovery()
        
        // Hide the app from dock and force it to stay hidden
        NSApp.setActivationPolicy(.accessory)
        
        // 禁用自动终止
        if #available(macOS 10.7, *) {
            NSApp.disableRelaunchOnLogin()
        }
    }
    
    
    // 防止应用在隐藏时退出
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showSettingsWindow()
        }
        return true
    }
  
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "Razer Control")
            button.action = #selector(showSettingsWindow)
            button.target = self
        }
        
        // Add right-click menu for additional options
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Settings", action: #selector(showSettingsWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: ""))
        statusItem?.menu = menu
    }
    
    @objc func showSettingsWindow() {
        if settingsWindow == nil {
            let contentView = ContentView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.contentView = NSHostingController(rootView: contentView).view
            settingsWindow?.title = "Razer Basilisk X HyperSpeed设置"
            settingsWindow?.center()
            
            // 设置窗口关闭时的行为 - 重要：隐藏而不是关闭
            settingsWindow?.delegate = self
            
            // 强制防止应用退出的重要设置
            NSApp.setActivationPolicy(.accessory)  // 确保应用不在Dock中显示
        }
        
        // 如果窗口已存在但被隐藏，直接显示
        if let window = settingsWindow {
            if !window.isVisible {
                window.center()  // 重新居中
            }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func quitApp() {
        shouldReallyQuit = true  // 设置标志允许退出
        NSApp.terminate(nil)
    }
}

// 添加窗口代理来处理窗口关闭事件
extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 点击关闭按钮时隐藏窗口而不是关闭
        if sender == settingsWindow {
            print("隐藏设置窗口而不是关闭")
            sender.orderOut(nil)  // 隐藏窗口
            return false  // 阻止窗口真正关闭
        }
        return false
    }
    
    func windowWillClose(_ notification: Notification) {
        // 这个方法现在不会被调用，因为窗口不会真正关闭
        if let window = notification.object as? NSWindow, window == settingsWindow {
            print("窗口关闭事件 - 但应该不会执行到这里")
        }
    }
    
    // 防止应用在失去焦点时退出
    func applicationDidResignActive(_ notification: Notification) {
        // 不做任何事，保持应用运行
    }
    
    // 防止应用因为隐藏而退出
    func applicationDidHide(_ notification: Notification) {
        // 不做任何事，保持应用运行
    }
}

struct ContentView: View {
    @StateObject private var deviceController = DeviceController()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "computermouse")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                
                Text("Razer Basilisk X HyperSpeed Driver")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Connection status
                HStack(spacing: 4) {
                    Circle()
                        .fill(deviceController.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(deviceController.isConnected ? "已连接" : "未连接")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if deviceController.isConnected {
                ScrollView {
                    VStack(spacing: 20) {
                        // Device Info
                        DeviceInfoView(deviceInfo: deviceController.deviceInfo)
                        
                        // DPI Control
                        DPIControlView(
                            currentDPI: deviceController.currentDPI,
                            onDPIChange: { dpi in
                                deviceController.setDPI(dpi)
                            }
                        )
                        
                        // Polling Rate Control
                        PollingRateView(
                            currentRate: deviceController.pollingRate,
                            onRateChange: { rate in
                                deviceController.setPollingRate(rate)
                            }
                        )
                        
                        // Battery Status
                        if let battery = deviceController.batteryLevel {
                            BatteryView(
                                level: battery,
                                isCharging: deviceController.isCharging
                            )
                        }
                    }
                    .padding()
                }
            } else {
                // No device connected view
                VStack(spacing: 20) {
                    Image(systemName: "computermouse.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        
                        // 设备未连接提示
                        VStack(spacing: 12) {
                            Text("未检测到Razer Basilisk X HyperSpeed")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("请检查输入监控设置中是否添加本软件")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("如果已添加依旧无法读取，请删除重新添加后重启软件")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("请通过USB连接您的设备")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("作者@liu5580 FROM github.com")
                                .font(.caption)
                                .foregroundColor(.secondary)


                             Text("参考openRazer开源项目遵守开源协议🈲严禁抄袭转发🈲")
                                 .font(.caption)
                                 .foregroundColor(.secondary)

                             Text("@https://github.com/openrazer/openrazer")
                                 .font(.caption)
                                 .foregroundColor(.secondary)
                        }
                    
                    
                    Button("重试连接") {
                        deviceController.retryConnection()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            deviceController.startMonitoring()
        }
    }
}

struct DeviceInfoView: View {
    let deviceInfo: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设备信息")
                .font(.headline)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "型号", value: deviceInfo["name"] as? String ?? "未知")
                    InfoRow(label: "固件版本", value: deviceInfo["firmware"] as? String ?? "未知")
                    InfoRow(label: "序列号", value: deviceInfo["serial"] as? String ?? "未知")
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.system(.body, design: .monospaced))
    }
}

struct DPIControlView: View {
    let currentDPI: Int
    let onDPIChange: (Int) -> Void
    
    @State private var selectedDPI: Double = 800
    @State private var isEditing = false
    
    let presetDPIs = [400, 800, 1600, 3200, 6400]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DPI 设置")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(selectedDPI))")
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            
            GroupBox {
                VStack(spacing: 16) {
                    // DPI Slider
                    VStack(spacing: 8) {
                        Slider(
                            value: $selectedDPI,
                            in: 100...16000,
                            step: 100,
                            onEditingChanged: { editing in
                                isEditing = editing
                                if !editing {
                                    onDPIChange(Int(selectedDPI))
                                }
                            }
                        )
                        
                        // Min/Max labels
                        HStack {
                            Text("100")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("16000")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Preset buttons
                    HStack(spacing: 8) {
                        ForEach(presetDPIs, id: \.self) { dpi in
                            Button(String(dpi)) {
                                selectedDPI = Double(dpi)
                                onDPIChange(dpi)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            selectedDPI = Double(currentDPI)
        }
    }
}

struct PollingRateView: View {
    let currentRate: Int
    let onRateChange: (Int) -> Void
    
    @State private var selectedRate: Int = 500
    
    let availableRates = [125, 500, 1000]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("轮询频率")
                .font(.headline)
            
            GroupBox {
                Picker("", selection: $selectedRate) {
                    ForEach(availableRates, id: \.self) { rate in
                        Text("\(rate) Hz").tag(rate)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedRate) { _, newRate in
                    onRateChange(newRate)
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            selectedRate = currentRate
        }
    }
}

struct BatteryView: View {
    let level: Int
    let isCharging: Bool
    
    var batteryColor: Color {
        if isCharging {
            return .green
        } else if level <= 20 {
            return .red
        } else if level <= 50 {
            return .orange
        } else {
            return .green
        }
    }
    
    var batteryIcon: String {
        if isCharging {
            return "battery.100.bolt"
        } else if level <= 25 {
            return "battery.25"
        } else if level <= 50 {
            return "battery.50"
        } else if level <= 75 {
            return "battery.75"
        } else {
            return "battery.100"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("电池状态")
                .font(.headline)
            
            GroupBox {
                HStack {
                    Image(systemName: batteryIcon)
                        .font(.title2)
                        .foregroundColor(batteryColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(level)%")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(isCharging ? "充电中" : "使用电池")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Battery level bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(batteryColor)
                                .frame(width: geometry.size.width * CGFloat(level) / 100, height: 8)
                        }
                    }
                    .frame(width: 100, height: 8)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct FooterView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("作者@liu5580 FROM github.com")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("参考openRazer开源项目遵守开源协议🈲严禁抄袭转发🈲")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("@https://github.com/openrazer/openrazer")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}



// Device Controller
class DeviceController: ObservableObject {
    @Published var isConnected = false
    @Published var deviceInfo: [String: Any] = [:]
    @Published var currentDPI = 800
    @Published var pollingRate = 500
    @Published var batteryLevel: Int?
    @Published var isCharging = false
    @Published var needsPermissions = false
    
    private var timer: Timer?
    private let deviceManager = RazerDeviceManager.shared()
    
    func startMonitoring() {
        updateDeviceStatus()
        
        // Poll device status every 3 seconds (more frequent for better responsiveness)
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateDeviceStatus()
            }
        }
    }
    
    func retryConnection() {
        // Stop current monitoring
        timer?.invalidate()
        timer = nil
        
        // Reset connection state
        DispatchQueue.main.async {
            self.isConnected = false
            self.deviceInfo = [:]
            self.currentDPI = 800
            self.pollingRate = 500
            self.batteryLevel = nil
            self.isCharging = false
            self.needsPermissions = false
        }
        
        // Restart device discovery
        deviceManager?.stopDeviceDiscovery()
        deviceManager?.startDeviceDiscovery()
        
        // Wait a moment for device discovery, then start monitoring again
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startMonitoring()
        }
    }
    
    func updateDeviceStatus() {
        guard let manager = deviceManager else { 
            print("DeviceManager is nil")
            return 
        }
        
        // Check for input monitoring permissions first
        if !manager.hasInputMonitoringPermission() {
            needsPermissions = true
            isConnected = false
            print("Input Monitoring permission required")
            return
        } else {
            needsPermissions = false
        }
        
        let wasConnected = isConnected
        isConnected = manager.currentDevice != nil
        
        if isConnected {
            print("Device is connected, updating status...")
            
            // Get device info
            if let info = manager.getDeviceInfo() as? [String: Any] {
                deviceInfo = info
                print("Device info updated: \(info)")
            }
            
            // Get current DPI
            if let dpiInfo = manager.getDPI(),
               let dpiX = dpiInfo["dpiX"] as? NSNumber {
                currentDPI = dpiX.intValue
                print("DPI updated: \(currentDPI)")
            }
            
            // Get polling rate
            if let rate = manager.getPollingRate() {
                pollingRate = rate.intValue
                print("Polling rate updated: \(pollingRate)")
            }
            
            // Get battery status
            if let battery = manager.getBatteryLevel() {
                batteryLevel = battery.intValue
                print("Battery level updated: \(batteryLevel?.description ?? "nil")")
            }
            
            isCharging = manager.isCharging()
            print("Charging status: \(isCharging)")
        } else {
            if wasConnected {
                print("Device disconnected")
            } else {
                print("No device found")
            }
        }
    }
    
    func setDPI(_ dpi: Int) {
        guard let manager = deviceManager else { return }
        
        if manager.setDPI(UInt16(dpi)) {
            currentDPI = dpi
            print("DPI set to: \(dpi)")
        } else {
            print("Failed to set DPI")
        }
    }
    
    func setPollingRate(_ rate: Int) {
        guard let manager = deviceManager else { return }
        
        if manager.setPollingRate(UInt16(rate)) {
            pollingRate = rate
            print("Polling rate set to: \(rate)")
        } else {
            print("Failed to set polling rate")
        }
    }
    
    deinit {
        timer?.invalidate()
    }
} 