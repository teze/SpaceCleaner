import Foundation
import CommonCrypto

class SystemScanner {
    
    // 扫描路径配置
    static let scanPaths: [CleanupCategory: [String]] = [
        .systemJunk: [
            "/Library/Caches",
            "/System/Library/Caches",
            "/private/var/folders"
        ],
        .userCache: [
            "~/Library/Caches"
        ],
        .appCache: [
            "~/Library/Application Support"
        ],
        .logs: [
            "~/Library/Logs",
            "/Library/Logs",
            "/private/var/log"
        ],
        .trash: [
            "~/.Trash"
        ],
        .downloads: [
            "~/Downloads"
        ],
        .developerJunk: [
            "~/Library/Developer/Xcode/DerivedData",
            "~/Library/Developer/Xcode/Archives",
            "~/Library/Caches/CocoaPods",
            "~/.cocoapods"
        ]
    ]
    
    // 扫描指定类别
    static func scan(category: CleanupCategory, progress: @escaping (Double, String) -> Void) -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        guard let paths = scanPaths[category] else { return items }
        
        for (index, pathPattern) in paths.enumerated() {
            let expandedPath = NSString(string: pathPattern).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            
            progress(Double(index) / Double(paths.count), "扫描: \(url.lastPathComponent)")
            
            let foundItems = scanDirectory(at: url, category: category, maxDepth: 3)
            items.append(contentsOf: foundItems)
        }
        
        return items
    }
    
    // 扫描大文件
    static func scanLargeFiles(in directory: URL? = nil, minSize: Int64 = 100 * 1024 * 1024, progress: @escaping (Double, String) -> Void) -> [CleanupItem] {
        var items: [CleanupItem] = []
        let scanURL = directory ?? FileManager.default.homeDirectoryForCurrentUser
        
        progress(0.0, "扫描大文件: \(scanURL.lastPathComponent)...")
        
        let foundItems = findLargeFiles(in: scanURL, minSize: minSize, maxDepth: 5)
        items.append(contentsOf: foundItems)
        
        return items
    }
    
    // 扫描旧文件
    static func scanOldFiles(in directory: URL? = nil, olderThan days: Int = 30, progress: @escaping (Double, String) -> Void) -> [CleanupItem] {
        var items: [CleanupItem] = []
        let scanURL = directory ?? FileManager.default.homeDirectoryForCurrentUser
        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))
        
        progress(0.0, "扫描旧文件: \(scanURL.lastPathComponent)...")
        
        let foundItems = findOldFiles(in: scanURL, olderThan: cutoffDate, maxDepth: 5)
        items.append(contentsOf: foundItems)
        
        return items
    }
    
    // MARK: - 私有方法
    
    private static func scanDirectory(at url: URL, category: CleanupCategory, maxDepth: Int, currentDepth: Int = 0) -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        guard currentDepth < maxDepth else { return items }
        guard FileManager.default.fileExists(atPath: url.path) else { return items }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in contents {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    
                    if isDirectory {
                        // 递归扫描子目录
                        let subItems = scanDirectory(at: fileURL, category: category, maxDepth: maxDepth, currentDepth: currentDepth + 1)
                        items.append(contentsOf: subItems)
                    } else {
                        let size = Int64(resourceValues.fileSize ?? 0)
                        let modifiedDate = resourceValues.contentModificationDate
                        
                        // 只添加有意义大小的文件
                        if size > 1024 { // > 1KB
                            let item = CleanupItem(
                                category: category,
                                path: fileURL.path,
                                name: fileURL.lastPathComponent,
                                size: size,
                                modifiedDate: modifiedDate,
                                isSelected: true
                            )
                            items.append(item)
                        }
                    }
                } catch {
                    continue
                }
            }
        } catch {
            // 无权限或其他错误，跳过
        }
        
        return items
    }
    
    private static func findLargeFiles(in url: URL, minSize: Int64, maxDepth: Int, currentDepth: Int = 0) -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        guard currentDepth < maxDepth else { return items }
        guard FileManager.default.fileExists(atPath: url.path) else { return items }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in contents {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    
                    if isDirectory {
                        let subItems = findLargeFiles(in: fileURL, minSize: minSize, maxDepth: maxDepth, currentDepth: currentDepth + 1)
                        items.append(contentsOf: subItems)
                    } else {
                        let size = Int64(resourceValues.fileSize ?? 0)
                        if size >= minSize {
                            let item = CleanupItem(
                                category: .largeFiles,
                                path: fileURL.path,
                                name: fileURL.lastPathComponent,
                                size: size,
                                modifiedDate: resourceValues.contentModificationDate,
                                isSelected: true
                            )
                            items.append(item)
                        }
                    }
                } catch {
                    continue
                }
            }
        } catch {
            // 跳过无权限的目录
        }
        
        return items
    }
    
    private static func findOldFiles(in url: URL, olderThan date: Date, maxDepth: Int, currentDepth: Int = 0) -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        guard currentDepth < maxDepth else { return items }
        guard FileManager.default.fileExists(atPath: url.path) else { return items }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in contents {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    
                    if isDirectory {
                        let subItems = findOldFiles(in: fileURL, olderThan: date, maxDepth: maxDepth, currentDepth: currentDepth + 1)
                        items.append(contentsOf: subItems)
                    } else {
                        if let modifiedDate = resourceValues.contentModificationDate, modifiedDate < date {
                            let size = Int64(resourceValues.fileSize ?? 0)
                            if size > 1024 * 1024 { // > 1MB
                                let item = CleanupItem(
                                    category: .oldFiles,
                                    path: fileURL.path,
                                    name: fileURL.lastPathComponent,
                                    size: size,
                                    modifiedDate: modifiedDate,
                                    isSelected: true
                                )
                                items.append(item)
                            }
                        }
                    }
                } catch {
                    continue
                }
            }
        } catch {
            // 跳过无权限的目录
        }
        
        return items
    }
    
    // MARK: - 清理功能
    
    /// 清理指定的项目（移到废纸篓）
    static func cleanup(items: [CleanupItem], progress: @escaping (Int, Int, String) -> Void) -> (success: Int, failed: Int, errors: [String]) {
        var successCount = 0
        var failedCount = 0
        var errors: [String] = []
        
        for (index, item) in items.enumerated() {
            let url = URL(fileURLWithPath: item.path)
            progress(index + 1, items.count, "清理: \(item.name)")
            
            do {
                // 移到废纸篓
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                successCount += 1
            } catch {
                failedCount += 1
                errors.append("\(item.name): \(error.localizedDescription)")
            }
        }
        
        return (successCount, failedCount, errors)
    }
    
    /// 批量清理（带确认）
    static func cleanupWithConfirmation(items: [CleanupItem], progress: @escaping (Int, Int, String) -> Void) -> (success: Int, failed: Int, errors: [String]) {
        return cleanup(items: items, progress: progress)
    }
    
    // MARK: - 重复文件扫描
    
    /// 扫描重复文件（基于 MD5 哈希）
    static func scanDuplicateFiles(in directories: [String]? = nil, minSize: Int64 = 1024 * 1024, progress: @escaping (Double, String) -> Void) -> [[CleanupItem]] {
        var filesByHash: [String: [CleanupItem]] = [:]
        var processedFiles = 0
        var totalFiles = 0
        
        // 确定扫描目录
        let scanDirs = directories ?? [
            FileManager.default.homeDirectoryForCurrentUser.path,
        ]
        
        progress(0.0, "准备扫描...")
        
        // 第一遍：收集所有文件
        var allFiles: [URL] = []
        for dirPath in scanDirs {
            let url = URL(fileURLWithPath: NSString(string: dirPath).expandingTildeInPath)
            let files = collectFiles(in: url, minSize: minSize, maxDepth: 5)
            allFiles.append(contentsOf: files)
        }
        
        totalFiles = allFiles.count
        progress(0.0, "找到 \(totalFiles) 个文件，开始计算哈希...")
        
        // 第二遍：计算哈希值
        for (index, fileURL) in allFiles.enumerated() {
            autoreleasepool {
                processedFiles += 1
                
                if processedFiles % 10 == 0 {
                    let progressValue = Double(processedFiles) / Double(totalFiles)
                    progress(progressValue, "处理中... (\(processedFiles)/\(totalFiles))")
                }
                
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                    let size = Int64(resourceValues.fileSize ?? 0)
                    
                    // 计算文件哈希
                    if let hash = calculateMD5(for: fileURL) {
                        let item = CleanupItem(
                            category: .duplicates,
                            path: fileURL.path,
                            name: fileURL.lastPathComponent,
                            size: size,
                            modifiedDate: resourceValues.contentModificationDate,
                            isSelected: false  // 重复文件默认不选中，让用户手动选择
                        )
                        
                        if filesByHash[hash] != nil {
                            filesByHash[hash]?.append(item)
                        } else {
                            filesByHash[hash] = [item]
                        }
                    }
                } catch {
                    // 跳过无法访问的文件
                }
            }
        }
        
        // 只返回有重复的文件组
        let duplicateGroups = filesByHash.values.filter { $0.count > 1 }
            .sorted { $0[0].size > $1[0].size }  // 按文件大小排序
        
        progress(1.0, "完成")
        return Array(duplicateGroups)
    }
    
    /// 收集文件列表
    private static func collectFiles(in url: URL, minSize: Int64, maxDepth: Int, currentDepth: Int = 0) -> [URL] {
        var files: [URL] = []
        
        guard currentDepth < maxDepth else { return files }
        guard FileManager.default.fileExists(atPath: url.path) else { return files }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in contents {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    
                    if isDirectory {
                        let subFiles = collectFiles(in: fileURL, minSize: minSize, maxDepth: maxDepth, currentDepth: currentDepth + 1)
                        files.append(contentsOf: subFiles)
                    } else {
                        let size = Int64(resourceValues.fileSize ?? 0)
                        if size >= minSize {
                            files.append(fileURL)
                        }
                    }
                } catch {
                    continue
                }
            }
        } catch {
            // 跳过无权限的目录
        }
        
        return files
    }
    
    /// 计算文件的 MD5 哈希值
    private static func calculateMD5(for url: URL) -> String? {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        
        defer {
            try? fileHandle.close()
        }
        
        var context = CC_MD5_CTX()
        CC_MD5_Init(&context)
        
        let bufferSize = 1024 * 1024  // 1MB buffer
        
        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: bufferSize)
            if data.count > 0 {
                data.withUnsafeBytes { bytes in
                    _ = CC_MD5_Update(&context, bytes.baseAddress, CC_LONG(data.count))
                }
                return true
            } else {
                return false
            }
        }) {}
        
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Final(&digest, &context)
        
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

// 导入 CommonCrypto 用于 MD5 计算
import CommonCrypto

extension SystemScanner {
    
    // MARK: - 应用卸载
    
    /// 扫描已安装的应用
    static func scanInstalledApps(progress: @escaping (Double, String) -> Void) -> [AppInfo] {
        var apps: [AppInfo] = []
        
        let appDirectories = [
            "/Applications",
            NSString(string: "~/Applications").expandingTildeInPath
        ]
        
        progress(0.0, "扫描应用...")
        
        for (index, dirPath) in appDirectories.enumerated() {
            let url = URL(fileURLWithPath: dirPath)
            
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
                
                for appURL in contents {
                    if appURL.pathExtension == "app" {
                        if let appInfo = getAppInfo(at: appURL) {
                            apps.append(appInfo)
                        }
                    }
                }
            } catch {
                continue
            }
            
            progress(Double(index + 1) / Double(appDirectories.count), "扫描: \(dirPath)")
        }
        
        return apps.sorted { $0.name < $1.name }
    }
    
    /// 获取应用信息
    private static func getAppInfo(at url: URL) -> AppInfo? {
        let infoPlistURL = url.appendingPathComponent("Contents/Info.plist")
        
        guard let infoDict = NSDictionary(contentsOf: infoPlistURL) else {
            return nil
        }
        
        let name = (infoDict["CFBundleName"] as? String) ?? url.deletingPathExtension().lastPathComponent
        let bundleId = infoDict["CFBundleIdentifier"] as? String ?? ""
        let version = infoDict["CFBundleShortVersionString"] as? String ?? "未知"
        
        // 计算应用大小
        let size = calculateDirectorySize(at: url)
        
        return AppInfo(
            name: name,
            bundleId: bundleId,
            version: version,
            path: url.path,
            size: size
        )
    }
    
    /// 查找应用相关文件
    static func findAppRelatedFiles(for app: AppInfo, progress: @escaping (Double, String) -> Void) -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        let searchPaths = [
            ("~/Library/Preferences", "\(app.bundleId)*.plist"),
            ("~/Library/Application Support", app.name),
            ("~/Library/Caches", app.bundleId),
            ("~/Library/Caches", app.name),
            ("~/Library/Logs", app.name),
            ("~/Library/Saved Application State", "\(app.bundleId).savedState"),
            ("~/Library/Containers", app.bundleId),
            ("~/Library/Group Containers", "*\(app.bundleId)*"),
        ]
        
        for (index, (pathPattern, namePattern)) in searchPaths.enumerated() {
            let expandedPath = NSString(string: pathPattern).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            
            progress(Double(index) / Double(searchPaths.count), "搜索: \(pathPattern)")
            
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                    options: []
                )
                
                for fileURL in contents {
                    let fileName = fileURL.lastPathComponent
                    
                    // 简单的模式匹配
                    if namePattern.contains("*") {
                        let pattern = namePattern.replacingOccurrences(of: "*", with: "")
                        if fileName.contains(pattern) {
                            items.append(createCleanupItem(from: fileURL, category: .appCache))
                        }
                    } else if fileName == namePattern || fileName.hasPrefix(namePattern) {
                        items.append(createCleanupItem(from: fileURL, category: .appCache))
                    }
                }
            } catch {
                continue
            }
        }
        
        progress(1.0, "完成")
        return items
    }
    
    /// 创建清理项目
    private static func createCleanupItem(from url: URL, category: CleanupCategory) -> CleanupItem {
        let size = calculateDirectorySize(at: url)
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey])
            return CleanupItem(
                category: category,
                path: url.path,
                name: url.lastPathComponent,
                size: size,
                modifiedDate: resourceValues.contentModificationDate,
                isSelected: true
            )
        } catch {
            return CleanupItem(
                category: category,
                path: url.path,
                name: url.lastPathComponent,
                size: size,
                modifiedDate: nil,
                isSelected: true
            )
        }
    }
    
    /// 计算目录大小
    private static func calculateDirectorySize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if !(resourceValues.isDirectory ?? false) {
                    totalSize += Int64(resourceValues.fileSize ?? 0)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    // MARK: - 隐私清理
    
    /// 扫描浏览器数据
    static func scanBrowserData(progress: @escaping (Double, String) -> Void) -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        // Safari
        let safariPaths = [
            "~/Library/Safari/History.db",
            "~/Library/Safari/History.db-shm",
            "~/Library/Safari/History.db-wal",
            "~/Library/Cookies/Cookies.binarycookies",
            "~/Library/Safari/Downloads.plist",
        ]
        
        progress(0.0, "扫描 Safari...")
        for path in safariPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            if FileManager.default.fileExists(atPath: url.path) {
                items.append(createCleanupItem(from: url, category: .userCache))
            }
        }
        
        // Chrome
        progress(0.3, "扫描 Chrome...")
        let chromePath = NSString(string: "~/Library/Application Support/Google/Chrome/Default").expandingTildeInPath
        let chromeFiles = ["History", "Cookies", "Web Data", "Visited Links"]
        for file in chromeFiles {
            let url = URL(fileURLWithPath: chromePath).appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: url.path) {
                items.append(createCleanupItem(from: url, category: .userCache))
            }
        }
        
        // Firefox
        progress(0.6, "扫描 Firefox...")
        let firefoxPath = NSString(string: "~/Library/Application Support/Firefox/Profiles").expandingTildeInPath
        if FileManager.default.fileExists(atPath: firefoxPath) {
            do {
                let profiles = try FileManager.default.contentsOfDirectory(atPath: firefoxPath)
                for profile in profiles {
                    let profilePath = (firefoxPath as NSString).appendingPathComponent(profile)
                    let firefoxFiles = ["places.sqlite", "cookies.sqlite", "formhistory.sqlite"]
                    for file in firefoxFiles {
                        let url = URL(fileURLWithPath: profilePath).appendingPathComponent(file)
                        if FileManager.default.fileExists(atPath: url.path) {
                            items.append(createCleanupItem(from: url, category: .userCache))
                        }
                    }
                }
            } catch {}
        }
        
        // 最近使用的文件
        progress(0.9, "扫描最近使用的文件...")
        let recentItemsPath = NSString(string: "~/Library/Application Support/com.apple.sharedfilelist").expandingTildeInPath
        if FileManager.default.fileExists(atPath: recentItemsPath) {
            let url = URL(fileURLWithPath: recentItemsPath)
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                for fileURL in contents {
                    if fileURL.lastPathComponent.contains("RecentItems") || fileURL.lastPathComponent.contains("RecentDocuments") {
                        items.append(createCleanupItem(from: fileURL, category: .userCache))
                    }
                }
            } catch {}
        }
        
        progress(1.0, "完成")
        return items
    }
}

// 应用信息结构
struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let bundleId: String
    let version: String
    let path: String
    let size: Int64
    var isSelected: Bool = false
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
