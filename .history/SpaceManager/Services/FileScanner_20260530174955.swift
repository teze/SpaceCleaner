import Foundation

class FileScanner {
    static func scanDirectory(at url: URL, maxDepth: Int = 2, currentDepth: Int = 0) async throws -> FileItem {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw NSError(domain: "FileScanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法访问目录"])
        }
        
        var totalSize: Int64 = 0
        var children: [FileItem] = []
        
        // 只扫描当前层级
        for case let fileURL as URL in enumerator {
            enumerator.skipDescendants()
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey])
                let isDirectory = resourceValues.isDirectory ?? false
                
                var itemSize: Int64 = 0
                
                if isDirectory {
                    // 递归计算目录大小
                    itemSize = try calculateDirectorySize(at: fileURL)
                } else {
                    itemSize = Int64(resourceValues.fileSize ?? 0)
                }
                
                totalSize += itemSize
                
                let item = FileItem(
                    url: fileURL,
                    name: fileURL.lastPathComponent,
                    size: itemSize,
                    isDirectory: isDirectory
                )
                
                children.append(item)
            } catch {
                // 跳过无法访问的文件
                continue
            }
        }
        
        // 按大小排序
        children.sort { $0.size > $1.size }
        
        return FileItem(
            url: url,
            name: url.lastPathComponent,
            size: totalSize,
            isDirectory: true,
            children: children
        )
    }
    
    private static func calculateDirectorySize(at url: URL) throws -> Int64 {
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
}
