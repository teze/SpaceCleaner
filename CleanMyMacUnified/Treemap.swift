import Foundation
import Cocoa

class TreemapLayout {
    
    // 生成树状图布局
    static func layout(node: FileNode, rect: CGRect) -> [TreemapRect] {
        var rects: [TreemapRect] = []
        
        if node.children.isEmpty {
            // 叶子节点
            rects.append(TreemapRect(node: node, x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height))
        } else {
            // 有子节点，使用 squarified treemap 算法
            let sortedChildren = node.children.sorted { $0.size > $1.size }
            rects.append(contentsOf: squarify(children: sortedChildren, rect: rect))
        }
        
        return rects
    }
    
    // Squarified Treemap 算法
    private static func squarify(children: [FileNode], rect: CGRect) -> [TreemapRect] {
        var rects: [TreemapRect] = []
        
        if children.isEmpty {
            return rects
        }
        
        let totalSize = children.reduce(0) { $0 + $1.size }
        
        if totalSize == 0 {
            return rects
        }
        
        var remaining = children
        var currentRect = rect
        
        while !remaining.isEmpty {
            // 决定切分方向（横向或纵向）
            let isHorizontal = currentRect.width >= currentRect.height
            
            // 取出一组节点
            let (row, rest) = takeRow(from: remaining, rect: currentRect, isHorizontal: isHorizontal, totalSize: totalSize)
            
            // 布局这一组
            let rowRects = layoutRow(row: row, rect: currentRect, isHorizontal: isHorizontal, totalSize: totalSize)
            rects.append(contentsOf: rowRects)
            
            // 更新剩余区域
            if !rest.isEmpty {
                let rowSize = row.reduce(0) { $0 + $1.size }
                let ratio = CGFloat(rowSize) / CGFloat(totalSize)
                
                if isHorizontal {
                    let usedHeight = currentRect.height * ratio
                    currentRect = CGRect(x: currentRect.origin.x, y: currentRect.origin.y + usedHeight,
                                       width: currentRect.width, height: currentRect.height - usedHeight)
                } else {
                    let usedWidth = currentRect.width * ratio
                    currentRect = CGRect(x: currentRect.origin.x + usedWidth, y: currentRect.origin.y,
                                       width: currentRect.width - usedWidth, height: currentRect.height)
                }
            }
            
            remaining = rest
        }
        
        return rects
    }
    
    private static func takeRow(from nodes: [FileNode], rect: CGRect, isHorizontal: Bool, totalSize: Int64) -> ([FileNode], [FileNode]) {
        if nodes.isEmpty {
            return ([], [])
        }
        
        // 简化版：每次取前几个节点
        let count = min(nodes.count, 5)
        let row = Array(nodes.prefix(count))
        let rest = Array(nodes.dropFirst(count))
        
        return (row, rest)
    }
    
    private static func layoutRow(row: [FileNode], rect: CGRect, isHorizontal: Bool, totalSize: Int64) -> [TreemapRect] {
        var rects: [TreemapRect] = []
        
        let rowSize = row.reduce(0) { $0 + $1.size }
        
        if rowSize == 0 {
            return rects
        }
        
        var currentPos: CGFloat = 0
        
        for node in row {
            let ratio = CGFloat(node.size) / CGFloat(rowSize)
            
            let nodeRect: CGRect
            if isHorizontal {
                let width = rect.width * ratio
                nodeRect = CGRect(x: rect.origin.x + currentPos, y: rect.origin.y,
                                width: width, height: rect.height)
                currentPos += width
            } else {
                let height = rect.height * ratio
                nodeRect = CGRect(x: rect.origin.x, y: rect.origin.y + currentPos,
                                width: rect.width, height: height)
                currentPos += height
            }
            
            rects.append(TreemapRect(node: node, x: nodeRect.origin.x, y: nodeRect.origin.y,
                                    width: nodeRect.width, height: nodeRect.height))
        }
        
        return rects
    }
}
