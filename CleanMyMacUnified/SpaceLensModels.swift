import Foundation

// 文件节点
class FileNode: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    var size: Int64
    var children: [FileNode]
    let isDirectory: Bool
    var parent: FileNode?
    
    // 计算属性
    var percentage: Double = 0.0
    var depth: Int = 0
    
    init(url: URL, name: String, size: Int64, isDirectory: Bool, children: [FileNode] = []) {
        self.url = url
        self.name = name
        self.size = size
        self.isDirectory = isDirectory
        self.children = children
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    // 计算总大小（包括子节点）
    func calculateTotalSize() -> Int64 {
        if !isDirectory {
            return size
        }
        
        var total: Int64 = 0
        for child in children {
            total += child.calculateTotalSize()
        }
        size = total
        return total
    }
    
    // 计算百分比
    func calculatePercentages(rootSize: Int64) {
        if rootSize > 0 {
            percentage = Double(size) / Double(rootSize) * 100.0
        }
        
        for child in children {
            child.calculatePercentages(rootSize: rootSize)
        }
    }
    
    // 设置深度
    func setDepth(_ d: Int) {
        depth = d
        for child in children {
            child.setDepth(d + 1)
        }
    }
    
    // 获取所有叶子节点
    func getLeafNodes() -> [FileNode] {
        if children.isEmpty {
            return [self]
        }
        
        var leaves: [FileNode] = []
        for child in children {
            leaves.append(contentsOf: child.getLeafNodes())
        }
        return leaves
    }
    
    // 获取最大的 N 个子节点
    func getTopChildren(count: Int) -> [FileNode] {
        return children.sorted { $0.size > $1.size }.prefix(count).map { $0 }
    }
    
    // Hashable
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// 树状图矩形
struct TreemapRect {
    let node: FileNode
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    
    var area: CGFloat {
        width * height
    }
    
    func contains(point: CGPoint) -> Bool {
        return point.x >= x && point.x <= x + width &&
               point.y >= y && point.y <= y + height
    }
}

// 颜色方案
struct ColorScheme {
    static func colorForDepth(_ depth: Int) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let colors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.2, 0.6, 1.0),   // 蓝色
            (0.3, 0.8, 0.5),   // 绿色
            (1.0, 0.7, 0.2),   // 橙色
            (0.9, 0.3, 0.5),   // 粉色
            (0.6, 0.4, 0.9),   // 紫色
            (0.2, 0.8, 0.8),   // 青色
        ]
        return colors[depth % colors.count]
    }
    
    static func colorForSize(_ size: Int64, maxSize: Int64) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let ratio = Double(size) / Double(maxSize)
        
        if ratio > 0.5 {
            // 大文件：红色
            return (1.0, 0.3, 0.3)
        } else if ratio > 0.2 {
            // 中等文件：橙色
            return (1.0, 0.7, 0.2)
        } else if ratio > 0.1 {
            // 小文件：黄色
            return (1.0, 0.9, 0.3)
        } else {
            // 很小的文件：绿色
            return (0.3, 0.8, 0.5)
        }
    }
}
