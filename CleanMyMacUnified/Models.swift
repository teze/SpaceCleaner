import Foundation

// 清理项目类型
enum CleanupCategory: String, CaseIterable {
    case systemJunk = "系统垃圾"
    case userCache = "用户缓存"
    case appCache = "应用缓存"
    case logs = "日志文件"
    case trash = "废纸篓"
    case largeFiles = "大文件"
    case oldFiles = "旧文件"
    case duplicates = "重复文件"
    case downloads = "下载文件"
    case developerJunk = "开发者垃圾"
    
    var icon: String {
        switch self {
        case .systemJunk: return "gear"
        case .userCache: return "person.crop.circle"
        case .appCache: return "app.badge"
        case .logs: return "doc.text"
        case .trash: return "trash"
        case .largeFiles: return "doc.badge.plus"
        case .oldFiles: return "clock"
        case .duplicates: return "doc.on.doc"
        case .downloads: return "arrow.down.circle"
        case .developerJunk: return "hammer"
        }
    }
    
    var description: String {
        switch self {
        case .systemJunk: return "系统缓存和临时文件"
        case .userCache: return "用户应用缓存"
        case .appCache: return "应用程序缓存"
        case .logs: return "系统和应用日志"
        case .trash: return "废纸篓中的文件"
        case .largeFiles: return "大于 100MB 的文件"
        case .oldFiles: return "超过 30 天未使用"
        case .duplicates: return "重复的文件"
        case .downloads: return "下载文件夹"
        case .developerJunk: return "Xcode、CocoaPods 等"
        }
    }
}

// 清理项目
class CleanupItem: Identifiable, Hashable {
    let id = UUID()
    let category: CleanupCategory
    let path: String
    let name: String
    let size: Int64
    let modifiedDate: Date?
    var isSelected: Bool = true
    
    init(category: CleanupCategory, path: String, name: String, size: Int64, modifiedDate: Date?, isSelected: Bool = true) {
        self.category = category
        self.path = path
        self.name = name
        self.size = size
        self.modifiedDate = modifiedDate
        self.isSelected = isSelected
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        guard let date = modifiedDate else { return "未知" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func == (lhs: CleanupItem, rhs: CleanupItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// 扫描结果
struct ScanResult {
    var items: [CleanupItem] = []
    var totalSize: Int64 = 0
    var itemCount: Int = 0
    
    var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var selectedCount: Int {
        items.filter { $0.isSelected }.count
    }
    
    func itemsByCategory() -> [CleanupCategory: [CleanupItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }
}

// 扫描状态
enum ScanStatus {
    case idle
    case scanning(progress: Double, message: String)
    case completed
    case error(String)
}

// 清理状态
enum CleanupStatus {
    case idle
    case cleaning(progress: Double, message: String)
    case completed(cleaned: Int64, count: Int)
    case error(String)
}
