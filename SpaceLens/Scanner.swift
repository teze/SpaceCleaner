import Foundation

class SpaceLensScanner {
    
    // 扫描目录并构建文件树
    static func scanDirectory(at url: URL, maxDepth: Int = 5, progress: @escaping (String) -> Void) -> FileNode? {
        progress("扫描: \(url.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            let isDirectory = resourceValues.isDirectory ?? false
            
            if isDirectory {
                return scanDirectoryRecursive(at: url, maxDepth: maxDepth, currentDepth: 0, progress: progress)
            } else {
                let size = Int64(resourceValues.fileSize ?? 0)
                return FileNode(url: url, name: url.lastPathComponent, size: size, isDirectory: false)
            }
        } catch {
            return nil
        }
    }
    
    private static func scanDirectoryRecursive(at url: URL, maxDepth: Int, currentDepth: Int, progress: @escaping (String) -> Void) -> FileNode? {
        
        guard currentDepth < maxDepth else {
            // 达到最大深度，只返回目录大小
            let size = calculateDirectorySize(at: url)
            return FileNode(url: url, name: url.lastPathComponent, size: size, isDirectory: true)
        }
        
        var children: [FileNode] = []
        
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
                        // 递归扫描子目录
                        if let childNode = scanDirectoryRecursive(at: fileURL, maxDepth: maxDepth, currentDepth: currentDepth + 1, progress: progress) {
                            children.append(childNode)
                        }
                    } else {
                        // 文件
                        let size = Int64(resourceValues.fileSize ?? 0)
                        let childNode = FileNode(url: fileURL, name: fileURL.lastPathComponent, size: size, isDirectory: false)
                        children.append(childNode)
                    }
                } catch {
                    continue
                }
            }
        } catch {
            // 无权限或其他错误
        }
        
        let node = FileNode(url: url, name: url.lastPathComponent, size: 0, isDirectory: true, children: children)
        
        // 设置父节点
        for child in children {
            child.parent = node
        }
        
        // 计算总大小
        _ = node.calculateTotalSize()
        
        return node
    }
    
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
                if resourceValues.isDirectory == false {
                    totalSize += Int64(resourceValues.fileSize ?? 0)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
}
