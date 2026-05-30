import Foundation

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
    static func scanLargeFiles(minSize: Int64 = 100 * 1024 * 1024, progress: @escaping (Double, String) -> Void) -> [CleanupItem] {
        var items: [CleanupItem] = []
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        
        progress(0.0, "扫描大文件...")
        
        let foundItems = findLargeFiles(in: homeURL, minSize: minSize, maxDepth: 5)
        items.append(contentsOf: foundItems)
        
        return items
    }
    
    // 扫描旧文件
    static func scanOldFiles(olderThan days: Int = 30, progress: @escaping (Double, String) -> Void) -> [CleanupItem] {
        var items: [CleanupItem] = []
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))
        
        progress(0.0, "扫描旧文件...")
        
        let foundItems = findOldFiles(in: homeURL, olderThan: cutoffDate, maxDepth: 5)
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
                                modifiedDate: modifiedDate
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
                                modifiedDate: resourceValues.contentModificationDate
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
                                    modifiedDate: modifiedDate
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
}
