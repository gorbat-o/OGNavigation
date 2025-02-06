import SwiftUI
import OGNavigation

struct ContentView: View {
    @State private var tabRouter = NavigationTabRouter<AppRoute>(
        tabs: [.homeTab, .dataTab, .settingsTab],
        selected: .homeTab
    )

    @State private var isCustomTabBarActivated = true
    @State private var isCustomIconsActivated = true
    @State private var isCustomColorsActivated = true

    var body: some View {
        if isCustomTabBarActivated {
            NavigationTabView(
                router: tabRouter,
                isCustomIconsActivated: $isCustomIconsActivated,
                isCustomColorsActivated: $isCustomColorsActivated,
                selectedTintColor: .purple,
                unselectedTintColor: .gray,
                content: makeContent,
                tabItem: makeTabItem,
                customTabBar: makeCustomTabBar
            )
        } else {
            NavigationTabView(
                router: tabRouter,
                isCustomIconsActivated: $isCustomIconsActivated,
                isCustomColorsActivated: $isCustomColorsActivated,
                selectedTintColor: .purple,
                unselectedTintColor: .gray,
                content: makeContent,
                tabItem: makeTabItem
            )
        }
    }

    @ViewBuilder
    private func makeContent(_ route: AppRoute) -> some View {
        switch route {
        case .homeTab:
            HomeView(
                isCustomTabBarActivated: $isCustomTabBarActivated,
                isCustomIconsActivated: $isCustomIconsActivated,
                isCustomColorsActivated: $isCustomColorsActivated
            )
        case .dataTab:
            DataView()
        case .settingsTab:
            SettingsView()
        case .dataDetail(let id):
            DataDetailView(id: id)
        case .profile:
            ProfileView()
        }
    }

    @ViewBuilder
    private func makeTabItem(_ tab: AppRoute) -> some View {
        let selectedColor: Color = isCustomColorsActivated ? .purple : .blue
        let unselectedColor: Color = .gray

        switch tab {
        case .homeTab:
            if isCustomIconsActivated {
                Label {
                    Text("Home")
                } icon: {
                    Image(tabRouter.selected == tab ? "tabHomeIconSelected" : "tabHomeIconUnselected")
                        .renderingMode(.template)
                }
                .foregroundColor(tabRouter.selected == tab ? selectedColor : unselectedColor)
            } else {
                Label("Home", systemImage: tabRouter.selected == tab ? "house.fill" : "house")
                    .foregroundColor(tabRouter.selected == tab ? selectedColor : unselectedColor)
            }
        case .dataTab:
            if isCustomIconsActivated {
                Label {
                    Text("Data")
                } icon: {
                    Image(tabRouter.selected == tab ? "tabDataIconSelected" : "tabDataIconUnselected")
                        .renderingMode(.template)
                }
                .foregroundColor(tabRouter.selected == tab ? selectedColor : unselectedColor)
            } else {
                Label("Data", systemImage: tabRouter.selected == tab ? "folder.fill" : "folder")
                    .foregroundColor(tabRouter.selected == tab ? selectedColor : unselectedColor)
            }
        case .settingsTab:
            if isCustomIconsActivated {
                Label {
                    Text("Settings")
                } icon: {
                    Image(tabRouter.selected == tab ? "tabSettingsIconSelected" : "tabSettingsIconUnselected")
                        .renderingMode(.template)
                }
                .foregroundColor(tabRouter.selected == tab ? selectedColor : unselectedColor)
            } else {
                Label("Settings", systemImage: tabRouter.selected == tab ? "gear.circle.fill" : "gear")
                    .foregroundColor(tabRouter.selected == tab ? selectedColor : unselectedColor)
            }
        default:
            Label("Unknown", systemImage: "questionmark")
                .foregroundColor(unselectedColor)
        }
    }

    private func getTabIcon(tab: AppRoute, customSelectedIcon: String, customUnselectedIcon: String, systemSelectedIcon: String, systemUnselectedIcon: String) -> String {
        isCustomIconsActivated
        ? (tabRouter.selected == tab ? customSelectedIcon : customUnselectedIcon)
        : (tabRouter.selected == tab ? systemSelectedIcon : systemUnselectedIcon)
    }

    @ViewBuilder
    private func makeCustomTabBar(selected: Binding<AppRoute>, tabs: [AppRoute], isCustomIcons: Binding<Bool>, isCustomColors: Binding<Bool>) -> some View {
        let items: [(tab: AppRoute, item: TabItem)] = [
            (.homeTab, TabItem(
                title: "Home",
                icon: getTabIcon(
                    tab: .homeTab,
                    customSelectedIcon: "tabHomeIconSelected",
                    customUnselectedIcon: "tabHomeIconUnselected",
                    systemSelectedIcon: "house.fill",
                    systemUnselectedIcon: "house"
                )
            )),
            (.dataTab, TabItem(
                title: "Data",
                icon: getTabIcon(
                    tab: .dataTab,
                    customSelectedIcon: "tabDataIconSelected",
                    customUnselectedIcon: "tabDataIconUnselected",
                    systemSelectedIcon: "folder.fill",
                    systemUnselectedIcon: "folder"
                )
            )),
            (.settingsTab, TabItem(
                title: "Settings",
                icon: getTabIcon(
                    tab: .settingsTab,
                    customSelectedIcon: "tabSettingsIconSelected",
                    customUnselectedIcon: "tabSettingsIconUnselected",
                    systemSelectedIcon: "gear.circle.fill",
                    systemUnselectedIcon: "gear"
                )
            ))
        ]

        CustomTabBar(
            selected: selected,
            items: items,
            isCustomIconsActivated: isCustomIcons,
            isCustomColorsActivated: isCustomColors,
            selectedTintColor: .purple,
            unselectedTintColor: .gray
        )
        .padding(.bottom, 16)
    }
}

#Preview {
    ContentView()
}
