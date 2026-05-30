import SwiftUI

struct StorageView: View {
    @ObservedObject var analyzer: StorageAnalyzer
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Button(action: selectFolder) {
                    Label("选择文件夹", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                
                if !analyzer.selectedPath.isEmpty {
                    Text(analyzer.selectedPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                if analyzer.isScanning {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("扫描中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 内容区域
            if let error = analyzer.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let rootItem = analyzer.rootItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 总览卡片
                        StorageSummaryCard(item: rootItem)
                        
                        // 文件列表
                        if let children = rootItem.children, !children.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("目录内容")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(children.prefix(20)) { child in
                                    FileItemRow(item: child, totalSize: rootItem.size)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                VStack {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("选择一个文件夹开始分析")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await analyzer.scanDirectory(at: url)
            }
        }
    }
}

struct StorageSummaryCard: View {
    let item: FileItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(item.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Text("总大小")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.formattedSize)
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                if let children = item.children {
                    VStack(alignment: .leading) {
                        Text("项目数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(children.count)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .padding(.horizontal)
    }
}

struct FileItemRow: View {
    let item: FileItem
    let totalSize: Int64
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundColor(item.isDirectory ? .blue : .gray)
                .frame(width: 20)
            
            Text(item.name)
                .lineLimit(1)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.formattedSize)
                    .font(.system(.body, design: .monospaced))
                
                Text(String(format: "%.1f%%", item.percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(colorForPercentage(item.percentage))
                        .frame(width: geometry.size.width * CGFloat(item.percentage / 100))
                }
            }
            .frame(width: 100, height: 6)
            .cornerRadius(3)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .padding(.horizontal)
    }
    
    private func colorForPercentage(_ percentage: Double) -> Color {
        if percentage > 20 {
            return .red
        } else if percentage > 10 {
            return .orange
        } else {
            return .blue
        }
    }
}
