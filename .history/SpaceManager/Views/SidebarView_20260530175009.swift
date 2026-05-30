import SwiftUI

struct SidebarView: View {
    @Binding var selectedView: SidebarItem
    
    var body: some View {
        List(SidebarItem.allCases, id: \.self, selection: $selectedView) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationTitle("空间管理")
    }
}
