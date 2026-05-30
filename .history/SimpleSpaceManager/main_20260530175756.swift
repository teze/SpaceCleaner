import Cocoa
import Foundation

// 文件扫描器
class FileScanner {
    static func scanDirectory(at url: URL) -> (size: Int64, items: [(name: String, size: Int64, isDir: Bool)]) {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        var items: [(name: String, size: Int64, isDir: Bool)] = []
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (0, [])
        }
        
        for case let fileURL as URL in enumerator {
            enumerator.skipDescendants()
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                let isDirectory = resourceValues.isDirectory ?? false
                var itemSize: Int64 = 0
                
                if isDirectory {
                    itemSize = calculateDirectorySize(at: fileURL)
                } else {
                    itemSize = Int64(resourceValues.fileSize ?? 0)
                }
                
                totalSize += itemSize
                items.append((
                    name: fileURL.lastPathComponent,
                    size: itemSize,
                    isDir: isDirectory
                ))
            } catch {
                continue
            }
        }
        
        items.sort { $0.size > $1.size }
        return (totalSize, items)
    }
    
    static func calculateDirectorySize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if resourceValues.isDirectory == false {
                    totalSize += Int64(resourceValues.fileSize ?? 0)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    static func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// 主窗口控制器
class MainWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "空间管理工具"
        window.center()
        
        self.init(window: window)
        
        let viewController = MainViewController()
        window.contentViewController = viewController
    }
}

// 主视图控制器
class MainViewController: NSViewController {
    var textView: NSTextView!
    var scanButton: NSButton!
    var progressIndicator: NSProgressIndicator!
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.wantsLayer = true
        
        // 扫描按钮
        scanButton = NSButton(frame: NSRect(x: 20, y: view.bounds.height - 50, width: 120, height: 32))
        scanButton.title = "选择文件夹"
        scanButton.bezelStyle = .rounded
        scanButton.target = self
        scanButton.action = #selector(selectFolder)
        scanButton.autoresizingMask = [.minYMargin]
        view.addSubview(scanButton)
        
        // 进度指示器
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 150, y: view.bounds.height - 45, width: 20, height: 20))
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        progressIndicator.autoresizingMask = [.minYMargin]
        view.addSubview(progressIndicator)
        
        // 滚动视图和文本视图
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: view.bounds.width - 40, height: view.bounds.height - 90))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .bezelBorder
        
        textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.autoresizingMask = [.width, .height]
        
        scrollView.documentView = textView
        view.addSubview(scrollView)
        
        // 显示欢迎信息
        showWelcomeMessage()
    }
    
    func showWelcomeMessage() {
        textView.string = """
        ╔═══════════════════════════════════════════════════════════╗
        ║                    空间管理工具 v1.0                        ║
        ╚═══════════════════════════════════════════════════════════╝
        
        点击 "选择文件夹" 按钮开始扫描...
        
        功能：
        • 扫描目录空间占用
        • 显示文件和文件夹大小
        • 按大小排序显示
        
        """
    }
    
    @objc func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "选择要分析的文件夹"
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.scanDirectory(at: url)
        }
    }
    
    func scanDirectory(at url: URL) {
        scanButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        
        textView.string = "正在扫描: \(url.path)\n\n请稍候...\n"
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = FileScanner.scanDirectory(at: url)
            
            DispatchQueue.main.async {
                self?.displayResults(url: url, totalSize: result.size, items: result.items)
                self?.scanButton.isEnabled = true
                self?.progressIndicator.stopAnimation(nil)
                self?.progressIndicator.isHidden = true
            }
        }
    }
    
    func displayResults(url: URL, totalSize: Int64, items: [(name: String, size: Int64, isDir: Bool)]) {
        var output = """
        ╔═══════════════════════════════════════════════════════════╗
        ║                      扫描结果                              ║
        ╚═══════════════════════════════════════════════════════════╝
        
        路径: \(url.path)
        总大小: \(FileScanner.formatSize(totalSize))
        项目数: \(items.count)
        
        ═══════════════════════════════════════════════════════════
        
        """
        
        for (index, item) in items.prefix(50).enumerated() {
            let icon = item.isDir ? "📁" : "📄"
            let percentage = totalSize > 0 ? Double(item.size) / Double(totalSize) * 100 : 0
            let bar = createProgressBar(percentage: percentage)
            
            output += String(format: "%2d. %@ %-40s %10s %5.1f%%\n    %s\n\n",
                           index + 1,
                           icon,
                           String(item.name.prefix(40)),
                           FileScanner.formatSize(item.size),
                           percentage,
                           bar)
        }
        
        if items.count > 50 {
            output += "\n... 还有 \(items.count - 50) 个项目未显示\n"
        }
        
        textView.string = output
    }
    
    func createProgressBar(percentage: Double) -> String {
        let barLength = 40
        let filled = Int(percentage / 100.0 * Double(barLength))
        let empty = barLength - filled
        
        let color: String
        if percentage > 20 {
            color = "🔴"
        } else if percentage > 10 {
            color = "🟠"
        } else {
            color = "🟢"
        }
        
        return color + " [" + String(repeating: "█", count: filled) + String(repeating: "░", count: empty) + "]"
    }
}

// 应用委托
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = MainWindowController()
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// 主程序入口
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
