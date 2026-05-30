import Foundation
import SwiftUI

@MainActor
class StorageAnalyzer: ObservableObject {
    @Published var isScanning = false
    @Published var rootItem: FileItem?
    @Published var selectedPath: String = ""
    @Published var errorMessage: String?
    
    func scanDirectory(at url: URL) async {
        isScanning = true
        errorMessage = nil
        selectedPath = url.path
        
        do {
            let item = try await FileScanner.scanDirectory(at: url)
            
            // 计算百分比
            var itemsWithPercentage = item.children?.map { child in
                var updatedChild = child
                updatedChild.percentage = item.size > 0 ? Double(child.size) / Double(item.size) * 100 : 0
                return updatedChild
            }
            
            var updatedRoot = item
            updatedRoot.children = itemsWithPercentage
            
            rootItem = updatedRoot
        } catch {
            errorMessage = "扫描失败: \(error.localizedDescription)"
        }
        
        isScanning = false
    }
}
