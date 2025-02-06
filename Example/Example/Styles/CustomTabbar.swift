import SwiftUI
import OGNavigation

public struct CustomTabBar<T: Equatable>: View {
    @Environment(NavigationTabRouter<AppRoute>.self) var tabRouter
    @Binding var selected: T
    @Binding var isCustomIconsActivated: Bool
    @Binding var isCustomColorsActivated: Bool
    let items: [(tab: T, item: TabItem)]
    
    let selectedTintColor: Color
    let unselectedTintColor: Color
    
    public init(
        selected: Binding<T>,
        items: [(tab: T, item: TabItem)],
        isCustomIconsActivated: Binding<Bool>,
        isCustomColorsActivated: Binding<Bool>,
        selectedTintColor: Color = .blue,
        unselectedTintColor: Color = .gray
    ) {
        self._selected = selected
        self.items = items
        self._isCustomIconsActivated = isCustomIconsActivated
        self._isCustomColorsActivated = isCustomColorsActivated
        self.selectedTintColor = selectedTintColor
        self.unselectedTintColor = unselectedTintColor
    }
    
    public var body: some View {
        ZStack {
            backgroundView
            HStack(spacing: 0) {
                tabButtons
            }
            indicatorView
        }
        .frame(height: 65)
        .padding(.horizontal, 16)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white)
            .shadow(color: Color.gray.opacity(0.2), radius: 8, x: 0, y: -2)
    }
    
    private var tabButtons: some View {
        ForEach(Array(items.enumerated()), id: \.offset) { _, tabItem in
            tabButton(for: tabItem)
        }
    }
    
    private func tabButton(for tabItem: (tab: T, item: OGNavigation.TabItem)) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                if selected == tabItem.tab {
                    if let tab = tabItem.tab as? AppRoute {
                        tabRouter.resetToRoot(for: tab)
                    }
                } else {
                    selected = tabItem.tab
                }
            }
        }) {
            tabButtonContent(for: tabItem)
        }
    }
    
    private func tabButtonContent(for tabItem: (tab: T, item: OGNavigation.TabItem)) -> some View {
        VStack(spacing: 4) {
            tabIcon(for: tabItem)
            Text(tabItem.item.title)
                .font(.caption)
                .foregroundColor(selected == tabItem.tab
                                 ? (isCustomColorsActivated ? selectedTintColor : .blue)
                                 : (isCustomColorsActivated ? unselectedTintColor : .gray)
                )
        }
        .frame(maxWidth: .infinity)
    }
    
    private func tabIcon(for tabItem: (tab: T, item: OGNavigation.TabItem)) -> some View {
        Group {
            if isCustomIconsActivated {
                Image(tabItem.item.icon)
                    .renderingMode(.template)
            } else {
                Image(systemName: tabItem.item.icon)
            }
        }
        .font(.system(size: 24))
        .foregroundColor(selected == tabItem.tab
                         ? (isCustomColorsActivated ? selectedTintColor : .blue)
                         : (isCustomColorsActivated ? unselectedTintColor : .gray)
        )
    }
    
    private var indicatorView: some View {
        GeometryReader { geometry in
            let tabWidth = geometry.size.width / CGFloat(items.count)
            let indicatorWidth: CGFloat = 40
            let indicatorOffset = (tabWidth * CGFloat(items.firstIndex(where: { $0.tab == selected }) ?? 0)) + (tabWidth - indicatorWidth) / 2
            
            (isCustomColorsActivated ? selectedTintColor : Color.blue)
                .frame(width: indicatorWidth, height: 4)
                .cornerRadius(2)
                .offset(x: indicatorOffset)
                .animation(.easeInOut(duration: 0.2), value: selected)
        }
    }
}

#Preview {
    ContentView()
}
