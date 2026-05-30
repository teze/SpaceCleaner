import Cocoa
import Foundation

// 主视图控制器
class CleanMyMacViewController: NSViewController {
    // UI 组件
    var sidebarTableView: NSTableView!
    var contentScrollView: NSScrollView!
    var contentTableView: NSTableView!
    var statusLabel: NSTextField!
    var scanButton: NSButton!
    var cleanButton: NSButton!
    var progressIndicator: NSProgressIndicator!
    var totalSizeLabel: NSTextField!
    var selectedSizeLabel: NSTextField!
    
    // 数据
    var categories: [CleanupCategory] = CleanupCategory.allCases
    var selectedCategory: CleanupCategory?
    var scanResult = ScanResult()
    var scanStatus: ScanStatus = .idle
    var isScanning = false
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 700))
        self.view.wantsLayer = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        // 顶部状态栏
        setupTopBar()
        
        // 侧边栏
        setupSidebar()
        
        // 内容区域
        setupContentArea()
        
        // 底部操作栏
        setupBottomBar()
    }
    
    func setupTopBar() {
        let topBar = NSView(frame: NSRect(x: 0, y: 650, width: 1000, height: 50))
        topBar.wantsLayer = true
        topBar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        totalSizeLabel = NSTextField(labelWithString: "总计: 0 B")
        totalSizeLabel.frame = NSRect(x: 20, y: 15, width: 200, height: 20)
        totalSizeLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        topBar.addSubview(totalSizeLabel)
        
        selectedSizeLabel = NSTextField(labelWithString: "已选: 0 B")
        selectedSizeLabel.frame = NSRect(x: 230, y: 15, width: 200, height: 20)
        selectedSizeLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        selectedSizeLabel.textColor = NSColor.systemBlue
        topBar.addSubview(selectedSizeLabel)
        
        statusLabel = NSTextField(labelWithString: "准备就绪")
        statusLabel.frame = NSRect(x: 450, y: 15, width: 400, height: 20)
        statusLabel.alignment = .center
        topBar.addSubview(statusLabel)
        
        view.addSubview(topBar)
    }
    
    func setupSidebar() {
        let sidebarScrollView = NSScrollView(frame: NSRect(x: 0, y: 60, width: 250, height: 590))
        sidebarScrollView.hasVerticalScroller = true
        sidebarScrollView.borderType = .noBorder
        
        sidebarTableView = NSTableView(frame: sidebarScrollView.bounds)
        sidebarTableView.headerView = nil
        sidebarTableView.rowHeight = 44
        sidebarTableView.backgroundColor = NSColor.controlBackgroundColor
        sidebarTableView.selectionHighlightStyle = .regular
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("category"))
        column.width = 250
        sidebarTableView.addTableColumn(column)
        
        sidebarTableView.delegate = self
        sidebarTableView.dataSource = self
        
        sidebarScrollView.documentView = sidebarTableView
        view.addSubview(sidebarScrollView)
        
        // 分隔线
        let separator = NSBox(frame: NSRect(x: 250, y: 60, width: 1, height: 590))
        separator.boxType = .separator
        view.addSubview(separator)
    }
    
    func setupContentArea() {
        contentScrollView = NSScrollView(frame: NSRect(x: 251, y: 60, width: 749, height: 590))
        contentScrollView.hasVerticalScroller = true
        contentScrollView.borderType = .noBorder
        
        contentTableView = NSTableView(frame: contentScrollView.bounds)
        contentTableView.rowHeight = 36
        contentTableView.usesAlternatingRowBackgroundColors = true
        
        // 列定义
        let checkColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("check"))
        checkColumn.title = ""
        checkColumn.width = 30
        contentTableView.addTableColumn(checkColumn)
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = "名称"
        nameColumn.width = 350
        contentTableView.addTableColumn(nameColumn)
        
        let sizeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("size"))
        sizeColumn.title = "大小"
        sizeColumn.width = 120
        contentTableView.addTableColumn(sizeColumn)
        
        let dateColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("date"))
        dateColumn.title = "修改日期"
        dateColumn.width = 180
        contentTableView.addTableColumn(dateColumn)
        
        let pathColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("path"))
        pathColumn.title = "路径"
        pathColumn.width = 300
        contentTableView.addTableColumn(pathColumn)
        
        contentTableView.delegate = self
        contentTableView.dataSource = self
        
        contentScrollView.documentView = contentTableView
        view.addSubview(contentScrollView)
    }
    
    func setupBottomBar() {
        let bottomBar = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 60))
        bottomBar.wantsLayer = true
        bottomBar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        scanButton = NSButton(frame: NSRect(x: 300, y: 15, width: 150, height: 32))
        scanButton.title = "开始扫描"
        scanButton.bezelStyle = .rounded
        scanButton.target = self
        scanButton.action = #selector(startScan)
        bottomBar.addSubview(scanButton)
        
        cleanButton = NSButton(frame: NSRect(x: 470, y: 15, width: 150, height: 32))
        cleanButton.title = "清理选中项"
        cleanButton.bezelStyle = .rounded
        cleanButton.target = self
        cleanButton.action = #selector(startCleanup)
        cleanButton.isEnabled = false
        bottomBar.addSubview(cleanButton)
        
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 640, y: 20, width: 20, height: 20))
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        bottomBar.addSubview(progressIndicator)
        
        view.addSubview(bottomBar)
    }
    
    @objc func startScan() {
        guard !isScanning else { return }
        
        isScanning = true
        scanButton.isEnabled = false
        cleanButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        statusLabel.stringValue = "正在扫描..."
        
        // 清空之前的结果
        scanResult = ScanResult()
        contentTableView.reloadData()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var allItems: [CleanupItem] = []
            
            // 扫描所有类别
            for category in CleanupCategory.allCases {
                let items = SystemScanner.scan(category: category) { progress, message in
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = message
                    }
                }
                allItems.append(contentsOf: items)
            }
            
            // 扫描大文件
            let largeFiles = SystemScanner.scanLargeFiles { progress, message in
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = message
                }
            }
            allItems.append(contentsOf: largeFiles)
            
            // 扫描旧文件
            let oldFiles = SystemScanner.scanOldFiles { progress, message in
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = message
                }
            }
            allItems.append(contentsOf: oldFiles)
            
            // 更新结果
            DispatchQueue.main.async {
                self.scanResult.items = allItems
                self.scanResult.totalSize = allItems.reduce(0) { $0 + $1.size }
                self.scanResult.itemCount = allItems.count
                
                self.updateUI()
                self.contentTableView.reloadData()
                self.sidebarTableView.reloadData()
                
                self.isScanning = false
                self.scanButton.isEnabled = true
                self.cleanButton.isEnabled = true
                self.progressIndicator.stopAnimation(nil)
                self.progressIndicator.isHidden = true
                self.statusLabel.stringValue = "扫描完成！找到 \(allItems.count) 个项目"
            }
        }
    }
    
    @objc func startCleanup() {
        let selectedItems = scanResult.items.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            showAlert(title: "提示", message: "请先选择要清理的项目")
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "确认清理"
        alert.informativeText = "将清理 \(selectedItems.count) 个项目，共 \(ByteCountFormatter.string(fromByteCount: scanResult.selectedSize, countStyle: .file))。文件将被移到废纸篓。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清理")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            performCleanup(items: selectedItems)
        }
    }
    
    func performCleanup(items: [CleanupItem]) {
        cleanButton.isEnabled = false
        scanButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var cleanedSize: Int64 = 0
            var cleanedCount = 0
            
            for item in items {
                do {
                    let url = URL(fileURLWithPath: item.path)
                    try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                    cleanedSize += item.size
                    cleanedCount += 1
                    
                    DispatchQueue.main.async {
                        self?.statusLabel.stringValue = "正在清理: \(item.name)"
                    }
                } catch {
                    print("清理失败: \(item.path) - \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self?.scanResult.items.removeAll { item in
                    items.contains { $0.id == item.id }
                }
                
                self?.updateUI()
                self?.contentTableView.reloadData()
                self?.sidebarTableView.reloadData()
                
                self?.cleanButton.isEnabled = true
                self?.scanButton.isEnabled = true
                self?.progressIndicator.stopAnimation(nil)
                self?.progressIndicator.isHidden = true
                
                let message = "已清理 \(cleanedCount) 个项目，释放 \(ByteCountFormatter.string(fromByteCount: cleanedSize, countStyle: .file))"
                self?.statusLabel.stringValue = message
                self?.showAlert(title: "清理完成", message: message)
            }
        }
    }
    
    func updateUI() {
        totalSizeLabel.stringValue = "总计: \(ByteCountFormatter.string(fromByteCount: scanResult.totalSize, countStyle: .file))"
        selectedSizeLabel.stringValue = "已选: \(ByteCountFormatter.string(fromByteCount: scanResult.selectedSize, countStyle: .file))"
    }
    
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    func getCurrentItems() -> [CleanupItem] {
        if let category = selectedCategory {
            return scanResult.items.filter { $0.category == category }
        }
        return scanResult.items
    }
}

// MARK: - TableView DataSource & Delegate
extension CleanMyMacViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == sidebarTableView {
            return categories.count + 1 // +1 for "All"
        } else {
            return getCurrentItems().count
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == sidebarTableView {
            let cell = NSTableCellView()
            let textField = NSTextField(labelWithString: "")
            textField.frame = NSRect(x: 40, y: 10, width: 180, height: 24)
            
            let imageView = NSImageView(frame: NSRect(x: 10, y: 10, width: 24, height: 24))
            
            if row == 0 {
                textField.stringValue = "全部"
                imageView.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
                
                let countByCategory = scanResult.itemsByCategory()
                let totalCount = scanResult.itemCount
                let badge = NSTextField(labelWithString: "\(totalCount)")
                badge.frame = NSRect(x: 200, y: 12, width: 40, height: 20)
                badge.alignment = .right
                badge.textColor = NSColor.secondaryLabelColor
                badge.font = NSFont.systemFont(ofSize: 11)
                cell.addSubview(badge)
            } else {
                let category = categories[row - 1]
                textField.stringValue = category.rawValue
                imageView.image = NSImage(systemSymbolName: category.icon, accessibilityDescription: nil)
                
                let countByCategory = scanResult.itemsByCategory()
                let count = countByCategory[category]?.count ?? 0
                if count > 0 {
                    let badge = NSTextField(labelWithString: "\(count)")
                    badge.frame = NSRect(x: 200, y: 12, width: 40, height: 20)
                    badge.alignment = .right
                    badge.textColor = NSColor.secondaryLabelColor
                    badge.font = NSFont.systemFont(ofSize: 11)
                    cell.addSubview(badge)
                }
            }
            
            cell.addSubview(imageView)
            cell.addSubview(textField)
            return cell
        } else {
            let items = getCurrentItems()
            guard row < items.count else { return nil }
            let item = items[row]
            
            let identifier = tableColumn?.identifier.rawValue ?? ""
            
            switch identifier {
            case "check":
                let cell = NSTableCellView()
                let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(checkboxToggled(_:)))
                checkbox.state = item.isSelected ? .on : .off
                checkbox.tag = row
                checkbox.frame = NSRect(x: 5, y: 8, width: 20, height: 20)
                cell.addSubview(checkbox)
                return cell
                
            case "name":
                let cell = NSTableCellView()
                let textField = NSTextField(labelWithString: item.name)
                textField.frame = NSRect(x: 5, y: 8, width: 340, height: 20)
                textField.lineBreakMode = .byTruncatingMiddle
                cell.addSubview(textField)
                return cell
                
            case "size":
                let cell = NSTableCellView()
                let textField = NSTextField(labelWithString: item.formattedSize)
                textField.frame = NSRect(x: 5, y: 8, width: 110, height: 20)
                textField.alignment = .right
                cell.addSubview(textField)
                return cell
                
            case "date":
                let cell = NSTableCellView()
                let textField = NSTextField(labelWithString: item.formattedDate)
                textField.frame = NSRect(x: 5, y: 8, width: 170, height: 20)
                cell.addSubview(textField)
                return cell
                
            case "path":
                let cell = NSTableCellView()
                let textField = NSTextField(labelWithString: item.path)
                textField.frame = NSRect(x: 5, y: 8, width: 290, height: 20)
                textField.lineBreakMode = .byTruncatingHead
                textField.textColor = NSColor.secondaryLabelColor
                textField.font = NSFont.systemFont(ofSize: 11)
                cell.addSubview(textField)
                return cell
                
            default:
                return nil
            }
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard notification.object as? NSTableView == sidebarTableView else { return }
        
        let row = sidebarTableView.selectedRow
        if row == 0 {
            selectedCategory = nil
        } else if row > 0 && row <= categories.count {
            selectedCategory = categories[row - 1]
        }
        
        contentTableView.reloadData()
    }
    
    @objc func checkboxToggled(_ sender: NSButton) {
        let row = sender.tag
        var items = getCurrentItems()
        guard row < items.count else { return }
        
        items[row].isSelected = sender.state == .on
        
        // 更新原始数据
        if let index = scanResult.items.firstIndex(where: { $0.id == items[row].id }) {
            scanResult.items[index].isSelected = sender.state == .on
        }
        
        updateUI()
    }
}

// 应用委托
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var viewController: CleanMyMacViewController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CleanMyMac - 系统清理工具"
        window.center()
        window.minSize = NSSize(width: 900, height: 600)
        
        viewController = CleanMyMacViewController()
        window.contentViewController = viewController
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
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
