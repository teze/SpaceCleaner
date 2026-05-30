import Cocoa
import Foundation

// 树状图视图
class TreemapView: NSView {
    var rects: [TreemapRect] = []
    var hoveredRect: TreemapRect?
    var selectedNode: FileNode?
    var onNodeSelected: ((FileNode) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTrackingArea()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTrackingArea()
    }
    
    func setupTrackingArea() {
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    func setTreemapRects(_ rects: [TreemapRect]) {
        self.rects = rects
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 背景
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()
        
        // 绘制所有矩形
        for rect in rects {
            drawRect(rect, isHovered: rect.node.id == hoveredRect?.node.id)
        }
    }
    
    func drawRect(_ rect: TreemapRect, isHovered: Bool) {
        let nsRect = NSRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
        
        // 根据深度选择颜色
        let (r, g, b) = ColorScheme.colorForDepth(rect.node.depth)
        let alpha: CGFloat = isHovered ? 0.9 : 0.7
        let color = NSColor(red: r, green: g, blue: b, alpha: alpha)
        
        // 填充
        color.setFill()
        nsRect.fill()
        
        // 边框
        NSColor.white.withAlphaComponent(0.3).setStroke()
        let path = NSBezierPath(rect: nsRect.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = 1
        path.stroke()
        
        // 文字（如果空间足够）
        if rect.width > 60 && rect.height > 30 {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let name = rect.node.name
            let size = rect.node.formattedSize
            let text = "\(name)\n\(size)"
            
            let textRect = NSRect(x: rect.x + 4, y: rect.y + 4, width: rect.width - 8, height: rect.height - 8)
            text.draw(in: textRect, withAttributes: attrs)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        // 查找鼠标下的矩形
        hoveredRect = rects.first { $0.contains(point: point) }
        needsDisplay = true
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        if let rect = rects.first(where: { $0.contains(point: point) }) {
            selectedNode = rect.node
            onNodeSelected?(rect.node)
        }
    }
}

// 主视图控制器
class SpaceLensViewController: NSViewController {
    var treemapView: TreemapView!
    var pathLabel: NSTextField!
    var sizeLabel: NSTextField!
    var itemCountLabel: NSTextField!
    var scanButton: NSButton!
    var backButton: NSButton!
    var progressIndicator: NSProgressIndicator!
    var statusLabel: NSTextField!
    var breadcrumbLabel: NSTextField!
    
    var rootNode: FileNode?
    var currentNode: FileNode?
    var navigationStack: [FileNode] = []
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 700))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        // 顶部信息栏
        let topBar = NSView(frame: NSRect(x: 0, y: 650, width: 1000, height: 50))
        topBar.wantsLayer = true
        topBar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        pathLabel = NSTextField(labelWithString: "选择文件夹开始扫描")
        pathLabel.frame = NSRect(x: 20, y: 25, width: 600, height: 20)
        pathLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        topBar.addSubview(pathLabel)
        
        sizeLabel = NSTextField(labelWithString: "总大小: 0 B")
        sizeLabel.frame = NSRect(x: 20, y: 5, width: 200, height: 18)
        sizeLabel.font = NSFont.systemFont(ofSize: 12)
        sizeLabel.textColor = NSColor.secondaryLabelColor
        topBar.addSubview(sizeLabel)
        
        itemCountLabel = NSTextField(labelWithString: "项目: 0")
        itemCountLabel.frame = NSRect(x: 230, y: 5, width: 200, height: 18)
        itemCountLabel.font = NSFont.systemFont(ofSize: 12)
        itemCountLabel.textColor = NSColor.secondaryLabelColor
        topBar.addSubview(itemCountLabel)
        
        view.addSubview(topBar)
        
        // 面包屑导航
        breadcrumbLabel = NSTextField(labelWithString: "")
        breadcrumbLabel.frame = NSRect(x: 20, y: 610, width: 960, height: 30)
        breadcrumbLabel.font = NSFont.systemFont(ofSize: 12)
        breadcrumbLabel.textColor = NSColor.secondaryLabelColor
        breadcrumbLabel.lineBreakMode = .byTruncatingHead
        view.addSubview(breadcrumbLabel)
        
        // 树状图视图
        treemapView = TreemapView(frame: NSRect(x: 20, y: 60, width: 960, height: 540))
        treemapView.wantsLayer = true
        treemapView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        treemapView.layer?.cornerRadius = 8
        treemapView.onNodeSelected = { [weak self] node in
            self?.navigateToNode(node)
        }
        view.addSubview(treemapView)
        
        // 底部操作栏
        let bottomBar = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 60))
        bottomBar.wantsLayer = true
        bottomBar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        backButton = NSButton(frame: NSRect(x: 300, y: 15, width: 100, height: 32))
        backButton.title = "返回上级"
        backButton.bezelStyle = .rounded
        backButton.target = self
        backButton.action = #selector(goBack)
        backButton.isEnabled = false
        bottomBar.addSubview(backButton)
        
        scanButton = NSButton(frame: NSRect(x: 420, y: 15, width: 150, height: 32))
        scanButton.title = "选择文件夹"
        scanButton.bezelStyle = .rounded
        scanButton.target = self
        scanButton.action = #selector(selectFolder)
        bottomBar.addSubview(scanButton)
        
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 590, y: 20, width: 20, height: 20))
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        bottomBar.addSubview(progressIndicator)
        
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: 620, y: 22, width: 300, height: 18)
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = NSColor.secondaryLabelColor
        bottomBar.addSubview(statusLabel)
        
        view.addSubview(bottomBar)
    }
    
    @objc func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "选择要分析的文件夹"
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.scanDirectory(at: url)
            }
        }
    }
    
    func scanDirectory(at url: URL) {
        scanButton.isEnabled = false
        backButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        statusLabel.stringValue = "正在扫描..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let node = SpaceLensScanner.scanDirectory(at: url, maxDepth: 4) { message in
                DispatchQueue.main.async {
                    self?.statusLabel.stringValue = message
                }
            }
            
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
                self?.statusLabel.stringValue = "扫描完成"
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
        
        // 更新信息
        pathLabel.stringValue = node.url.path
        sizeLabel.stringValue = "总大小: \(node.formattedSize)"
        itemCountLabel.stringValue = "项目: \(node.children.count)"
        
        // 更新面包屑
        updateBreadcrumb()
        
        // 生成树状图
        let rect = CGRect(x: 0, y: 0, width: 960, height: 540)
        
        // 只显示直接子节点
        var rects: [TreemapRect] = []
        if !node.children.isEmpty {
            let sortedChildren = node.children.sorted { $0.size > $1.size }
            rects = TreemapLayout.layout(node: FileNode(url: node.url, name: node.name, size: node.size, isDirectory: true, children: sortedChildren), rect: rect)
        }
        
        treemapView.setTreemapRects(rects)
    }
    
    func updateBreadcrumb() {
        var path = ""
        for (index, node) in navigationStack.enumerated() {
            if index > 0 {
                path += " > "
            }
            path += node.name
        }
        if !navigationStack.isEmpty {
            path += " > "
        }
        path += currentNode?.name ?? ""
        
        breadcrumbLabel.stringValue = path
    }
}

// 应用委托
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var viewController: SpaceLensViewController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Space Lens - 空间透镜"
        window.center()
        window.minSize = NSSize(width: 900, height: 600)
        
        viewController = SpaceLensViewController()
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
