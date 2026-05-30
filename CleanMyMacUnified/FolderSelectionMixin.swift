import Cocoa

// 文件夹选择辅助函数
class FolderSelectionHelper {
    
    static func createPathLabel(yPosition: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: "扫描范围: 整个系统")
        label.frame = NSRect(x: 30, y: yPosition, width: 600, height: 16)
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = NSColor.tertiaryLabelColor
        label.autoresizingMask = [.minYMargin]
        return label
    }
    
    static func createSelectFolderButton(target: AnyObject, action: Selector) -> NSButton {
        let button = NSButton(frame: NSRect(x: 220, y: 20, width: 120, height: 32))
        button.title = "选择文件夹"
        button.bezelStyle = .rounded
        button.target = target
        button.action = action
        button.autoresizingMask = [.maxXMargin, .maxYMargin]
        return button
    }
    
    static func updatePathLabel(_ label: NSTextField, directory: URL?) {
        if let dir = directory {
            label.stringValue = "扫描范围: \(dir.path)"
            label.textColor = NSColor.systemBlue
        } else {
            label.stringValue = "扫描范围: 整个系统"
            label.textColor = NSColor.tertiaryLabelColor
        }
    }
}
