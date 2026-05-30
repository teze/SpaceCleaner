# 文件夹选择功能实现说明

## 功能概述
为所有扫描功能（大文件、旧文件、重复文件）添加"选择文件夹"按钮，让用户可以选择扫描特定目录而不是整个系统。

## 已完成的修改

### 1. Scanner.swift ✅
已修改扫描函数，添加可选的目录参数：

```swift
// 大文件扫描
static func scanLargeFiles(in directory: URL? = nil, minSize: Int64 = 100 * 1024 * 1024, progress: @escaping (Double, String) -> Void) -> [CleanupItem]

// 旧文件扫描  
static func scanOldFiles(in directory: URL? = nil, olderThan days: Int = 30, progress: @escaping (Double, String) -> Void) -> [CleanupItem]

// 重复文件扫描
static func scanDuplicateFiles(in directories: [String]? = nil, minSize: Int64 = 1024 * 1024, progress: @escaping (Double, String) -> Void) -> [[CleanupItem]]
```

### 2. FolderSelectionMixin.swift ✅
创建了辅助类来简化UI创建：

```swift
class FolderSelectionHelper {
    static func createPathLabel(yPosition: CGFloat) -> NSTextField
    static func createSelectFolderButton(target: AnyObject, action: Selector) -> NSButton
    static func updatePathLabel(_ label: NSTextField, directory: URL?)
}
```

### 3. build-unified.sh ✅
已添加 FolderSelectionMixin.swift 到编译列表

## 待实现的修改

由于自动修改导致文件结构问题，以下是手动实现步骤：

### 对于 CleanupViewController（大文件、旧文件）

1. **添加属性**（在类定义开始处）：
```swift
var pathLabel: NSTextField!
var selectFolderButton: NSButton!
var selectedDirectory: URL?
```

2. **在 setupUI() 中添加UI**（在 selectionLabel 之后）：
```swift
// 文件夹选择
pathLabel = FolderSelectionHelper.createPathLabel(yPosition: view.bounds.height - 115)
view.addSubview(pathLabel)

selectFolderButton = FolderSelectionHelper.createSelectFolderButton(target: self, action: #selector(selectFolder))
view.addSubview(selectFolderButton)
```

3. **添加 selectFolder 方法**（在 updateSelectionLabel 之后）：
```swift
@objc func selectFolder() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.message = "选择要扫描的文件夹"
    panel.prompt = "选择"
    
    if let currentDir = selectedDirectory {
        panel.directoryURL = currentDir
    }
    
    panel.begin { [weak self] response in
        guard let self = self else { return }
        if response == .OK, let url = panel.url {
            self.selectedDirectory = url
            FolderSelectionHelper.updatePathLabel(self.pathLabel, directory: self.selectedDirectory)
        }
    }
}
```

4. **修改扫描调用**（在 startScan 方法中）：
```swift
// 对于大文件
scannedItems = SystemScanner.scanLargeFiles(in: self.selectedDirectory) { _, message in
    // ...
}

// 对于旧文件
scannedItems = SystemScanner.scanOldFiles(in: self.selectedDirectory) { _, message in
    // ...
}
```

### 对于 DuplicateFilesViewController（重复文件）

同样的步骤，但扫描调用略有不同：

```swift
let scanDirs = self.selectedDirectory != nil ? [self.selectedDirectory!.path] : nil
let groups = SystemScanner.scanDuplicateFiles(in: scanDirs, minSize: 1024 * 1024) { progress, message in
    // ...
}
```

## 使用效果

- 默认扫描整个系统（用户主目录）
- 点击"选择文件夹"按钮可以选择特定目录
- 路径标签显示当前扫描范围
- 选择目录后，标签变为蓝色并显示所选路径

## 注意事项

1. 确保在闭包外的属性访问不需要 `self.`
2. 在 `[weak self]` 闭包内需要使用 `self.` 或 `guard let self = self`
3. 保持类的括号匹配，每个类定义必须有对应的闭合括号
4. 新添加的方法应该在类内部，extension 之前

## 测试建议

1. 测试默认扫描（不选择文件夹）
2. 测试选择特定文件夹扫描
3. 测试取消选择对话框
4. 验证路径标签正确更新
5. 确认扫描结果只包含所选目录的文件
