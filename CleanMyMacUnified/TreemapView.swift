import Cocoa
import Foundation

// 树状图视图
class TreemapView: NSView {
    var rects: [TreemapRect] = []
    var hoveredRect: TreemapRect?
    var selectedNode: FileNode?
    var onNodeSelected: ((FileNode) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTrackingArea()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTrackingArea()
    }
    
    func setupTrackingArea() {
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    func setTreemapRects(_ rects: [TreemapRect]) {
        self.rects = rects
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 背景
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()
        
        // 绘制所有矩形
        for rect in rects {
            drawRect(rect, isHovered: rect.node.id == hoveredRect?.node.id)
        }
    }
    
    func drawRect(_ rect: TreemapRect, isHovered: Bool) {
        let nsRect = NSRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
        
        // 根据深度选择颜色
        let (r, g, b) = ColorScheme.colorForDepth(rect.node.depth)
        let alpha: CGFloat = isHovered ? 0.9 : 0.7
        let color = NSColor(red: r, green: g, blue: b, alpha: alpha)
        
        // 填充
        color.setFill()
        nsRect.fill()
        
        // 边框
        NSColor.white.withAlphaComponent(0.3).setStroke()
        let path = NSBezierPath(rect: nsRect.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = 1
        path.stroke()
        
        // 文字（如果空间足够）
        if rect.width > 60 && rect.height > 30 {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let name = rect.node.name
            let size = rect.node.formattedSize
            let text = "\(name)\n\(size)"
            
            let textRect = NSRect(x: rect.x + 4, y: rect.y + 4, width: rect.width - 8, height: rect.height - 8)
            text.draw(in: textRect, withAttributes: attrs)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        // 查找鼠标下的矩形
        hoveredRect = rects.first { $0.contains(point: point) }
        needsDisplay = true
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        if let rect = rects.first(where: { $0.contains(point: point) }) {
            selectedNode = rect.node
            onNodeSelected?(rect.node)
        }
    }
}
