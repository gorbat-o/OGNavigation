import SwiftUI
import OGNavigation

struct HomeView: View {
    @Environment(NavigationRouter<AppRoute>.self) var router
    @Environment(NavigationTabRouter<AppRoute>.self) var tabRouter

    @Binding var isCustomTabBarActivated: Bool
    @Binding var isCustomIconsActivated: Bool
    @Binding var isCustomColorsActivated: Bool

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                Text("Tab Switches")
                    .font(.title)
                Text("The following buttons will just switch to the corresponding tab.")
                    .font(.subheadline)
                Button("Switch to Data Tab") {
                    tabRouter.updateSelectedTab(.dataTab)
                }
                .buttonStyle(OGButtonStyle())
                Button("Switch to Settings") {
                    tabRouter.updateSelectedTab(.settingsTab)
                }
                .buttonStyle(OGButtonStyle())

                Text("Tab Switches + Action")
                    .font(.title)
                Text("The following button will present data detail (1) in data tab as a navigation")
                    .font(.subheadline)
                Button("Switch to Data Tab and Push Data Detail") {
                    tabRouter.present(.dataDetail(id: 1), inTab: .dataTab, option: .navigation(inSheet: false))
                }
                .buttonStyle(OGButtonStyle())
                Text("The following button will present data detail (3) in data tab as a sheet")
                    .font(.subheadline)
                Button("Switch to Data Tab and Sheet Data Detail") {
                    tabRouter.present(.dataDetail(id: 3), inTab: .dataTab, option: .sheet)
                }
                .buttonStyle(OGButtonStyle())
                Text("Tab Bar")
                    .font(.title)
                Text("Custom Tab Bar")
                    .font(.subheadline)
                Button(isCustomTabBarActivated ? "Deactivate" : "Activate") {
                    isCustomTabBarActivated.toggle()
                }
                .buttonStyle(OGButtonStyle())
                Text("Custom Icons")
                    .font(.subheadline)
                Button(isCustomIconsActivated ? "Deactivate" : "Activate") {
                    isCustomIconsActivated.toggle()
                }
                .buttonStyle(OGButtonStyle())
                Text("Custom Color")
                    .font(.subheadline)
                Button(isCustomColorsActivated ? "Deactivate" : "Activate") {
                    isCustomColorsActivated.toggle()
                }
                .buttonStyle(OGButtonStyle())
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Home")
        // FIXME: this adds padding to the tabbar zone for some reason.
//        .padding(.bottom, 88)
    }
}


#Preview {
    ContentView()
}
