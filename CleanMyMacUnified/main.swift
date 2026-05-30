import Cocoa
import Foundation

// 按钮样式辅助类
extension NSButton {
    static func createStyledButton(title: String, isPrimary: Bool = false) -> NSButton {
        let button = NSButton(frame: .zero)
        button.title = title
        button.bezelStyle = .rounded
        button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        
        if isPrimary {
            button.contentTintColor = NSColor.white
            button.bezelColor = NSColor.controlAccentColor
        }
        
        return button
    }
}

// 主视图控制器 - 整合所有功能
class UnifiedViewController: NSViewController {
    // UI 组件
    var sidebarTableView: NSTableView!
    var contentView: NSView!
    var statusLabel: NSTextField!
    var totalSizeLabel: NSTextField!
    
    // 当前视图
    var currentViewController: NSViewController?
    
    // 功能模块
    enum Module: String, CaseIterable {
        case smartScan = "智能扫描"
        case spaceLens = "空间透镜"
        case systemJunk = "系统垃圾"
        case largeFiles = "大文件"
        case oldFiles = "旧文件"
        case duplicates = "重复文件"
        case uninstaller = "应用卸载"
        case privacy = "隐私清理"
        
        var icon: String {
            switch self {
            case .smartScan: return "sparkles"
            case .spaceLens: return "chart.pie"
            case .systemJunk: return "trash"
            case .largeFiles: return "doc.badge.plus"
            case .oldFiles: return "clock"
            case .duplicates: return "doc.on.doc"
            case .uninstaller: return "xmark.app"
            case .privacy: return "hand.raised"
            }
        }
        
        var description: String {
            switch self {
            case .smartScan: return "一键扫描和清理"
            case .spaceLens: return "可视化磁盘空间"
            case .systemJunk: return "清理系统垃圾"
            case .largeFiles: return "查找大文件"
            case .oldFiles: return "查找旧文件"
            case .duplicates: return "查找重复文件"
            case .uninstaller: return "完全卸载应用"
            case .privacy: return "清理隐私数据"
            }
        }
    }
    
    var modules: [Module] = Module.allCases
    var selectedModule: Module = .smartScan
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1200, height: 750))
        self.view.autoresizingMask = [.width, .height]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showModule(.smartScan)
    }
    
    func setupUI() {
        // 顶部状态栏
        setupTopBar()
        
        // 侧边栏
        setupSidebar()
        
        // 内容区域
        setupContentArea()
    }
    
    func setupTopBar() {
        let topBar = NSView(frame: NSRect(x: 0, y: 700, width: 1200, height: 50))
        topBar.wantsLayer = true
        topBar.layer?.backgroundColor = NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.99, alpha: 1.0).cgColor
        topBar.autoresizingMask = [.width, .minYMargin]  // 固定在顶部，宽度自适应
        
        // 添加底部阴影
        topBar.shadow = NSShadow()
        topBar.layer?.shadowColor = NSColor.black.cgColor
        topBar.layer?.shadowOpacity = 0.05
        topBar.layer?.shadowOffset = NSSize(width: 0, height: -1)
        topBar.layer?.shadowRadius = 2
        
        // 应用图标 - 使用 SF Symbols
        let appIconView = NSImageView(frame: NSRect(x: 20, y: 10, width: 30, height: 30))
        let config = NSImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        if let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            appIconView.image = image
            appIconView.symbolConfiguration = config
            appIconView.contentTintColor = NSColor.controlAccentColor
        }
        topBar.addSubview(appIconView)
        
        let titleLabel = NSTextField(labelWithString: "SpaceCleaner")
        titleLabel.frame = NSRect(x: 58, y: 15, width: 200, height: 24)
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        topBar.addSubview(titleLabel)
        
        totalSizeLabel = NSTextField(labelWithString: "")
        totalSizeLabel.frame = NSRect(x: 900, y: 18, width: 280, height: 20)
        totalSizeLabel.alignment = .right
        totalSizeLabel.font = NSFont.systemFont(ofSize: 13)
        totalSizeLabel.textColor = NSColor.secondaryLabelColor
        totalSizeLabel.autoresizingMask = [.minXMargin]  // 固定在右侧
        topBar.addSubview(totalSizeLabel)
        
        view.addSubview(topBar)
    }
    
    func setupSidebar() {
        let sidebarScrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 250, height: 700))
        sidebarScrollView.hasVerticalScroller = true
        sidebarScrollView.borderType = .noBorder
        sidebarScrollView.wantsLayer = true
        sidebarScrollView.layer?.backgroundColor = NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.97, alpha: 1.0).cgColor
        sidebarScrollView.autoresizingMask = [.height]  // 高度自适应
        
        sidebarTableView = NSTableView(frame: sidebarScrollView.bounds)
        sidebarTableView.headerView = nil
        sidebarTableView.rowHeight = 60
        sidebarTableView.backgroundColor = NSColor.clear
        sidebarTableView.selectionHighlightStyle = .regular
        sidebarTableView.intercellSpacing = NSSize(width: 0, height: 4)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("module"))
        column.width = 250
        sidebarTableView.addTableColumn(column)
        
        sidebarTableView.delegate = self
        sidebarTableView.dataSource = self
        
        sidebarScrollView.documentView = sidebarTableView
        view.addSubview(sidebarScrollView)
        
        // 分隔线
        let separator = NSBox(frame: NSRect(x: 250, y: 0, width: 1, height: 700))
        separator.boxType = .separator
        separator.autoresizingMask = [.height]  // 高度自适应
        view.addSubview(separator)
    }
    
    func setupContentArea() {
        contentView = NSView(frame: NSRect(x: 251, y: 0, width: 949, height: 700))
        contentView.wantsLayer = true
        contentView.autoresizingMask = [.width, .height]  // 宽度和高度都自适应
        view.addSubview(contentView)
    }
    
    func showModule(_ module: Module) {
        selectedModule = module
        
        // 移除旧视图
        currentViewController?.view.removeFromSuperview()
        currentViewController = nil
        
        // 创建新视图
        let viewController: NSViewController
        
        switch module {
        case .smartScan:
            viewController = SmartScanViewController()
        case .spaceLens:
            viewController = SpaceLensViewController()
        case .systemJunk:
            viewController = CleanupViewController(category: .systemJunk)
        case .largeFiles:
            viewController = CleanupViewController(category: .largeFiles)
        case .oldFiles:
            viewController = CleanupViewController(category: .oldFiles)
        case .duplicates:
            viewController = DuplicateFilesViewController()
        case .uninstaller:
            viewController = UninstallerViewController()
        case .privacy:
            viewController = PrivacyViewController()
        }
        
        currentViewController = viewController
        viewController.view.frame = contentView.bounds
        viewController.view.autoresizingMask = [.width, .height]  // 关键：让子视图也自动缩放
        contentView.addSubview(viewController.view)
        
        sidebarTableView.reloadData()
    }
}

// MARK: - TableView DataSource & Delegate
extension UnifiedViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return modules.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTableCellView()
        let module = modules[row]
        
        // 背景视图
        let backgroundView = NSView(frame: NSRect(x: 8, y: 4, width: 234, height: 52))
        backgroundView.wantsLayer = true
        
        if selectedModule == module {
            backgroundView.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
            backgroundView.layer?.cornerRadius = 8
        } else {
            backgroundView.layer?.backgroundColor = NSColor.clear.cgColor
        }
        cell.addSubview(backgroundView)
        
        // 图标背景
        let iconBackground = NSView(frame: NSRect(x: 20, y: 16, width: 36, height: 36))
        iconBackground.wantsLayer = true
        iconBackground.layer?.cornerRadius = 8
        
        if selectedModule == module {
            iconBackground.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        } else {
            iconBackground.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
        }
        cell.addSubview(iconBackground)
        
        // 图标
        let imageView = NSImageView(frame: NSRect(x: 28, y: 24, width: 20, height: 20))
        if let image = NSImage(systemSymbolName: module.icon, accessibilityDescription: nil) {
            imageView.image = image
            imageView.contentTintColor = selectedModule == module ? NSColor.white : NSColor.controlAccentColor
            imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        }
        cell.addSubview(imageView)
        
        // 标题
        let titleLabel = NSTextField(labelWithString: module.rawValue)
        titleLabel.frame = NSRect(x: 65, y: 28, width: 170, height: 20)
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: selectedModule == module ? .semibold : .medium)
        titleLabel.textColor = selectedModule == module ? NSColor.labelColor : NSColor.secondaryLabelColor
        cell.addSubview(titleLabel)
        
        // 描述
        let descLabel = NSTextField(labelWithString: module.description)
        descLabel.frame = NSRect(x: 65, y: 10, width: 170, height: 16)
        descLabel.font = NSFont.systemFont(ofSize: 11)
        descLabel.textColor = NSColor.tertiaryLabelColor
        cell.addSubview(descLabel)
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = sidebarTableView.selectedRow
        if row >= 0 && row < modules.count {
            showModule(modules[row])
        }
    }
}

// 占位视图控制器
class PlaceholderViewController: NSViewController {
    let titleText: String
    let messageText: String
    
    init(title: String, message: String) {
        self.titleText = title
        self.messageText = message
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 949, height: 700))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageView = NSImageView(frame: NSRect(x: 400, y: 400, width: 150, height: 150))
        imageView.image = NSImage(systemSymbolName: "hammer.fill", accessibilityDescription: nil)
        imageView.contentTintColor = NSColor.secondaryLabelColor
        view.addSubview(imageView)
        
        let titleLabel = NSTextField(labelWithString: titleText)
        titleLabel.frame = NSRect(x: 300, y: 350, width: 350, height: 30)
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.alignment = .center
        view.addSubview(titleLabel)
        
        let messageLabel = NSTextField(labelWithString: messageText)
        messageLabel.frame = NSRect(x: 300, y: 320, width: 350, height: 20)
        messageLabel.font = NSFont.systemFont(ofSize: 14)
        messageLabel.textColor = NSColor.secondaryLabelColor
        messageLabel.alignment = .center
        view.addSubview(messageLabel)
    }
}

// 应用委托
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var viewController: UnifiedViewController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建窗口
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 750),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SpaceCleaner - 系统清理工具"
        window.center()
        window.minSize = NSSize(width: 1000, height: 650)
        window.maxSize = NSSize(width: 1600, height: 1000)
        
        // 设置窗口外观
        window.titlebarAppearsTransparent = false
        window.backgroundColor = NSColor.windowBackgroundColor
        
        // 设置窗口级别
        window.level = .normal
        
        viewController = UnifiedViewController()
        window.contentViewController = viewController
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// 主程序入口
autoreleasepool {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
