import Cocoa
import Foundation

// 智能扫描视图控制器
class SmartScanViewController: NSViewController {
    var scanButton: NSButton!
    var statusLabel: NSTextField!
    var resultLabel: NSTextField!
    var progressIndicator: NSProgressIndicator!
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 949, height: 700))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        // 标题
        let titleLabel = NSTextField(labelWithString: "智能扫描")
        titleLabel.frame = NSRect(x: 50, y: 620, width: 300, height: 40)
        titleLabel.font = NSFont.systemFont(ofSize: 32, weight: .bold)
        view.addSubview(titleLabel)
        
        let descLabel = NSTextField(labelWithString: "一键扫描系统垃圾、大文件和旧文件")
        descLabel.frame = NSRect(x: 50, y: 590, width: 500, height: 20)
        descLabel.font = NSFont.systemFont(ofSize: 14)
        descLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(descLabel)
        
        // 扫描按钮
        scanButton = NSButton(frame: NSRect(x: 375, y: 300, width: 200, height: 50))
        scanButton.title = "开始扫描"
        scanButton.bezelStyle = .rounded
        scanButton.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        scanButton.target = self
        scanButton.action = #selector(startScan)
        view.addSubview(scanButton)
        
        // 进度指示器
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 445, y: 260, width: 60, height: 60))
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        view.addSubview(progressIndicator)
        
        // 状态标签
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: 300, y: 220, width: 350, height: 20)
        statusLabel.alignment = .center
        statusLabel.font = NSFont.systemFont(ofSize: 13)
        view.addSubview(statusLabel)
        
        // 结果标签
        resultLabel = NSTextField(labelWithString: "")
        resultLabel.frame = NSRect(x: 200, y: 150, width: 550, height: 60)
        resultLabel.alignment = .center
        resultLabel.font = NSFont.systemFont(ofSize: 16)
        view.addSubview(resultLabel)
    }
    
    @objc func startScan() {
        scanButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        statusLabel.stringValue = "正在扫描..."
        resultLabel.stringValue = ""
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var allItems: [CleanupItem] = []
            var totalSize: Int64 = 0
            
            // 扫描各个类别
            for category in [CleanupCategory.systemJunk, .userCache, .appCache, .logs, .trash] {
                let items = SystemScanner.scan(category: category) { _, _ in }
                allItems.append(contentsOf: items)
                totalSize += items.reduce(0) { $0 + $1.size }
            }
            
            // 扫描大文件
            let largeFiles = SystemScanner.scanLargeFiles { _, _ in }
            allItems.append(contentsOf: largeFiles)
            totalSize += largeFiles.reduce(0) { $0 + $1.size }
            
            DispatchQueue.main.async {
                self?.scanButton.isEnabled = true
                self?.progressIndicator.stopAnimation(nil)
                self?.progressIndicator.isHidden = true
                self?.statusLabel.stringValue = "扫描完成！"
                
                let sizeStr = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                self?.resultLabel.stringValue = "找到 \(allItems.count) 个项目\n可释放 \(sizeStr) 空间"
            }
        }
    }
}

// Space Lens 视图控制器
class SpaceLensViewController: NSViewController {
    var treemapView: TreemapView!
    var pathLabel: NSTextField!
    var sizeLabel: NSTextField!
    var scanButton: NSButton!
    var backButton: NSButton!
    var progressIndicator: NSProgressIndicator!
    var breadcrumbLabel: NSTextField!
    
    var rootNode: FileNode?
    var currentNode: FileNode?
    var navigationStack: [FileNode] = []
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 949, height: 700))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        // 顶部信息
        pathLabel = NSTextField(labelWithString: "选择文件夹开始扫描")
        pathLabel.frame = NSRect(x: 20, y: 660, width: 600, height: 20)
        pathLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        view.addSubview(pathLabel)
        
        sizeLabel = NSTextField(labelWithString: "")
        sizeLabel.frame = NSRect(x: 20, y: 640, width: 300, height: 18)
        sizeLabel.font = NSFont.systemFont(ofSize: 12)
        sizeLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(sizeLabel)
        
        // 面包屑
        breadcrumbLabel = NSTextField(labelWithString: "")
        breadcrumbLabel.frame = NSRect(x: 20, y: 610, width: 909, height: 20)
        breadcrumbLabel.font = NSFont.systemFont(ofSize: 11)
        breadcrumbLabel.textColor = NSColor.tertiaryLabelColor
        view.addSubview(breadcrumbLabel)
        
        // 树状图
        treemapView = TreemapView(frame: NSRect(x: 20, y: 80, width: 909, height: 520))
        treemapView.wantsLayer = true
        treemapView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        treemapView.layer?.cornerRadius = 8
        treemapView.onNodeSelected = { [weak self] node in
            self?.navigateToNode(node)
        }
        view.addSubview(treemapView)
        
        // 底部按钮
        backButton = NSButton(frame: NSRect(x: 300, y: 20, width: 100, height: 32))
        backButton.title = "返回上级"
        backButton.bezelStyle = .rounded
        backButton.target = self
        backButton.action = #selector(goBack)
        backButton.isEnabled = false
        view.addSubview(backButton)
        
        scanButton = NSButton(frame: NSRect(x: 420, y: 20, width: 120, height: 32))
        scanButton.title = "选择文件夹"
        scanButton.bezelStyle = .rounded
        scanButton.target = self
        scanButton.action = #selector(selectFolder)
        view.addSubview(scanButton)
        
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 560, y: 25, width: 20, height: 20))
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        view.addSubview(progressIndicator)
    }
    
    @objc func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.scanDirectory(at: url)
            }
        }
    }
    
    func scanDirectory(at url: URL) {
        scanButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let node = SpaceLensScanner.scanDirectory(at: url, maxDepth: 4) { _ in }
            
            DispatchQueue.main.async {
                self?.rootNode = node
                self?.currentNode = node
                self?.navigationStack = []
                
                if let node = node {
                    node.setDepth(0)
                    node.calculatePercentages(rootSize: node.size)
                    self?.updateView()
                }
                
                self?.scanButton.isEnabled = true
                self?.progressIndicator.stopAnimation(nil)
                self?.progressIndicator.isHidden = true
            }
        }
    }
    
    func navigateToNode(_ node: FileNode) {
        if node.isDirectory && !node.children.isEmpty {
            navigationStack.append(currentNode!)
            currentNode = node
            updateView()
            backButton.isEnabled = true
        }
    }
    
    @objc func goBack() {
        if let previousNode = navigationStack.popLast() {
            currentNode = previousNode
            updateView()
            backButton.isEnabled = !navigationStack.isEmpty
        }
    }
    
    func updateView() {
        guard let node = currentNode else { return }
        
        pathLabel.stringValue = node.url.path
        sizeLabel.stringValue = "总大小: \(node.formattedSize) | 项目: \(node.children.count)"
        
        var path = ""
        for (index, n) in navigationStack.enumerated() {
            if index > 0 { path += " > " }
            path += n.name
        }
        if !navigationStack.isEmpty { path += " > " }
        path += node.name
        breadcrumbLabel.stringValue = path
        
        let rect = CGRect(x: 0, y: 0, width: 909, height: 520)
        var rects: [TreemapRect] = []
        if !node.children.isEmpty {
            let sortedChildren = node.children.sorted { $0.size > $1.size }
            rects = TreemapLayout.layout(node: FileNode(url: node.url, name: node.name, size: node.size, isDirectory: true, children: sortedChildren), rect: rect)
        }
        treemapView.setTreemapRects(rects)
    }
}

// 清理视图控制器
class CleanupViewController: NSViewController {
    let category: CleanupCategory
    var tableView: NSTableView!
    var scanButton: NSButton!
    var cleanButton: NSButton!
    var selectAllButton: NSButton!
    var deselectAllButton: NSButton!
    var progressIndicator: NSProgressIndicator!
    var statusLabel: NSTextField!
    var selectionLabel: NSTextField!
    var items: [CleanupItem] = []
    
    init(category: CleanupCategory) {
        self.category = category
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
        setupUI()
    }
    
    func setupUI() {
        // 标题
        let titleLabel = NSTextField(labelWithString: category.rawValue)
        titleLabel.frame = NSRect(x: 30, y: 650, width: 300, height: 30)
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        view.addSubview(titleLabel)
        
        let descLabel = NSTextField(labelWithString: category.description)
        descLabel.frame = NSRect(x: 30, y: 630, width: 500, height: 18)
        descLabel.font = NSFont.systemFont(ofSize: 13)
        descLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(descLabel)
        
        // 选择统计标签
        selectionLabel = NSTextField(labelWithString: "")
        selectionLabel.frame = NSRect(x: 30, y: 605, width: 500, height: 18)
        selectionLabel.font = NSFont.systemFont(ofSize: 12)
        selectionLabel.textColor = NSColor.systemBlue
        view.addSubview(selectionLabel)
        
        // 表格
        let scrollView = NSScrollView(frame: NSRect(x: 30, y: 80, width: 889, height: 510))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        
        tableView = NSTableView(frame: scrollView.bounds)
        tableView.rowHeight = 32
        tableView.usesAlternatingRowBackgroundColors = true
        
        // 勾选框列
        let checkColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("check"))
        checkColumn.title = "✓"
        checkColumn.width = 40
        tableView.addTableColumn(checkColumn)
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = "名称"
        nameColumn.width = 350
        tableView.addTableColumn(nameColumn)
        
        let sizeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("size"))
        sizeColumn.title = "大小"
        sizeColumn.width = 100
        tableView.addTableColumn(sizeColumn)
        
        let pathColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("path"))
        pathColumn.title = "路径"
        pathColumn.width = 380
        tableView.addTableColumn(pathColumn)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        scrollView.documentView = tableView
        view.addSubview(scrollView)
        
        // 底部按钮
        selectAllButton = NSButton(frame: NSRect(x: 30, y: 20, width: 80, height: 32))
        selectAllButton.title = "全选"
        selectAllButton.bezelStyle = .rounded
        selectAllButton.target = self
        selectAllButton.action = #selector(selectAllItems)
        selectAllButton.isEnabled = false
        view.addSubview(selectAllButton)
        
        deselectAllButton = NSButton(frame: NSRect(x: 120, y: 20, width: 80, height: 32))
        deselectAllButton.title = "取消全选"
        deselectAllButton.bezelStyle = .rounded
        deselectAllButton.target = self
        deselectAllButton.action = #selector(deselectAllItems)
        deselectAllButton.isEnabled = false
        view.addSubview(deselectAllButton)
        
        scanButton = NSButton(frame: NSRect(x: 350, y: 20, width: 120, height: 32))
        scanButton.title = "开始扫描"
        scanButton.bezelStyle = .rounded
        scanButton.target = self
        scanButton.action = #selector(startScan)
        view.addSubview(scanButton)
        
        cleanButton = NSButton(frame: NSRect(x: 490, y: 20, width: 120, height: 32))
        cleanButton.title = "清理选中项"
        cleanButton.bezelStyle = .rounded
        cleanButton.target = self
        cleanButton.action = #selector(startClean)
        cleanButton.isEnabled = false
        view.addSubview(cleanButton)
        
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 630, y: 25, width: 20, height: 20))
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        view.addSubview(progressIndicator)
        
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: 660, y: 27, width: 250, height: 18)
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        view.addSubview(statusLabel)
    }
    
    @objc func selectAllItems() {
        for i in 0..<items.count {
            items[i].isSelected = true
        }
        tableView.reloadData()
        updateSelectionLabel()
    }
    
    @objc func deselectAllItems() {
        for i in 0..<items.count {
            items[i].isSelected = false
        }
        tableView.reloadData()
        updateSelectionLabel()
    }
    
    func updateSelectionLabel() {
        let selectedItems = items.filter { $0.isSelected }
        let selectedSize = selectedItems.reduce(0) { $0 + $1.size }
        let sizeStr = ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
        selectionLabel.stringValue = "已选择 \(selectedItems.count) 个项目，共 \(sizeStr)"
        
        cleanButton.isEnabled = !selectedItems.isEmpty
    }
    
    @objc func startScan() {
        scanButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        statusLabel.stringValue = "正在扫描..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var scannedItems: [CleanupItem] = []
            
            // 根据类别选择不同的扫描方法
            switch self.category {
            case .largeFiles:
                scannedItems = SystemScanner.scanLargeFiles { _, message in
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = message
                    }
                }
            case .oldFiles:
                scannedItems = SystemScanner.scanOldFiles { _, message in
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = message
                    }
                }
            default:
                scannedItems = SystemScanner.scan(category: self.category) { _, message in
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = message
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.items = scannedItems
                self.tableView.reloadData()
                self.scanButton.isEnabled = true
                self.cleanButton.isEnabled = !scannedItems.isEmpty
                self.selectAllButton.isEnabled = !scannedItems.isEmpty
                self.deselectAllButton.isEnabled = !scannedItems.isEmpty
                self.progressIndicator.stopAnimation(nil)
                self.progressIndicator.isHidden = true
                
                let totalSize = scannedItems.reduce(0) { $0 + $1.size }
                let sizeStr = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                self.statusLabel.stringValue = "找到 \(scannedItems.count) 个项目，共 \(sizeStr)"
                self.updateSelectionLabel()
            }
        }
    }
    
    @objc func startClean() {
        let selectedItems = items.filter { $0.isSelected }
        
        if selectedItems.isEmpty {
            let alert = NSAlert()
            alert.messageText = "没有选中项目"
            alert.informativeText = "请先选择要清理的项目"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "好的")
            alert.runModal()
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "确认清理"
        let totalSize = selectedItems.reduce(0) { $0 + $1.size }
        let sizeStr = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        alert.informativeText = "将清理 \(selectedItems.count) 个项目，释放约 \(sizeStr) 空间\n\n文件将被移到废纸篓，可以恢复。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清理")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // 执行清理
            cleanButton.isEnabled = false
            scanButton.isEnabled = false
            selectAllButton.isEnabled = false
            deselectAllButton.isEnabled = false
            progressIndicator.isHidden = false
            progressIndicator.startAnimation(nil)
            statusLabel.stringValue = "清理中..."
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                let result = SystemScanner.cleanup(items: selectedItems) { current, total, message in
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = "清理中... (\(current)/\(total))"
                    }
                }
                
                DispatchQueue.main.async {
                    self.progressIndicator.stopAnimation(nil)
                    self.progressIndicator.isHidden = true
                    self.scanButton.isEnabled = true
                    
                    if result.failed == 0 {
                        // 全部成功
                        let successAlert = NSAlert()
                        successAlert.messageText = "清理完成"
                        successAlert.informativeText = "成功清理 \(result.success) 个项目"
                        successAlert.alertStyle = .informational
                        successAlert.addButton(withTitle: "好的")
                        successAlert.runModal()
                        
                        // 移除已清理的项目
                        self.items.removeAll { $0.isSelected }
                        self.tableView.reloadData()
                        self.selectAllButton.isEnabled = !self.items.isEmpty
                        self.deselectAllButton.isEnabled = !self.items.isEmpty
                        self.updateSelectionLabel()
                        
                        if self.items.isEmpty {
                            self.statusLabel.stringValue = "所有项目已清理"
                        } else {
                            let remainingSize = self.items.reduce(0) { $0 + $1.size }
                            let sizeStr = ByteCountFormatter.string(fromByteCount: remainingSize, countStyle: .file)
                            self.statusLabel.stringValue = "剩余 \(self.items.count) 个项目，共 \(sizeStr)"
                        }
                    } else {
                        // 部分失败
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "清理完成（部分失败）"
                        errorAlert.informativeText = "成功: \(result.success) 个\n失败: \(result.failed) 个\n\n失败原因：\n\(result.errors.prefix(5).joined(separator: "\n"))"
                        errorAlert.alertStyle = .warning
                        errorAlert.addButton(withTitle: "好的")
                        errorAlert.runModal()
                        
                        // 重新扫描以更新列表
                        self.startScan()
                    }
                }
            }
        }
    }
}

extension CleanupViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < items.count else { return nil }
        let item = items[row]
        
        let identifier = tableColumn?.identifier.rawValue ?? ""
        
        if identifier == "check" {
            // 勾选框
            let cell = NSTableCellView()
            let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(checkboxToggled(_:)))
            checkbox.frame = NSRect(x: 10, y: 6, width: 20, height: 20)
            checkbox.state = item.isSelected ? .on : .off
            checkbox.tag = row
            cell.addSubview(checkbox)
            return cell
        }
        
        let cell = NSTableCellView()
        let textField = NSTextField(labelWithString: "")
        textField.frame = NSRect(x: 5, y: 6, width: tableColumn?.width ?? 100 - 10, height: 20)
        
        switch identifier {
        case "name":
            textField.stringValue = item.name
        case "size":
            textField.stringValue = item.formattedSize
            textField.alignment = .right
        case "path":
            textField.stringValue = item.path
            textField.textColor = NSColor.secondaryLabelColor
            textField.font = NSFont.systemFont(ofSize: 11)
        default:
            break
        }
        
        cell.addSubview(textField)
        return cell
    }
    
    @objc func checkboxToggled(_ sender: NSButton) {
        let row = sender.tag
        if row < items.count {
            items[row].isSelected = (sender.state == .on)
            updateSelectionLabel()
        }
    }
}
