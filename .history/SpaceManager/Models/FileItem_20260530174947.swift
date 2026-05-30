import Foundation

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let isDirectory: Bool
    var children: [FileItem]?
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var percentage: Double = 0.0
    
    init(url: URL, name: String, size: Int64, isDirectory: Bool, children: [FileItem]? = nil) {
        self.url = url
        self.name = name
        self.size = size
        self.isDirectory = isDirectory
        self.children = children
    }
}

enum SidebarItem: String, CaseIterable {
    case storage = "存储分析"
    case duplicates = "重复文件"
    case largeFiles = "大文件"
    case cleanup = "智能清理"
    
    var icon: String {
        switch self {
        case .storage: return "chart.pie.fill"
        case .duplicates: return "doc.on.doc.fill"
        case .largeFiles: return "doc.text.magnifyingglass"
        case .cleanup: return "trash.fill"
        }
    }
}
