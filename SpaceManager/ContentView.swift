import SwiftUI

struct ContentView: View {
    @StateObject private var storageAnalyzer = StorageAnalyzer()
    @State private var selectedView: SidebarItem = .storage
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedView: $selectedView)
        } detail: {
            switch selectedView {
            case .storage:
                StorageView(analyzer: storageAnalyzer)
            case .duplicates:
                DuplicatesPlaceholderView()
            case .largeFiles:
                LargeFilesPlaceholderView()
            case .cleanup:
                CleanupPlaceholderView()
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

// 占位视图
struct DuplicatesPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("重复文件查找")
                .font(.title2)
                .padding(.top)
            Text("即将推出")
                .foregroundColor(.secondary)
        }
    }
}

struct LargeFilesPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("大文件扫描")
                .font(.title2)
                .padding(.top)
            Text("即将推出")
                .foregroundColor(.secondary)
        }
    }
}

struct CleanupPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "trash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("智能清理")
                .font(.title2)
                .padding(.top)
            Text("即将推出")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
