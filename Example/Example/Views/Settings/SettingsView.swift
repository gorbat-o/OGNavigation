import SwiftUI
import OGNavigation

struct SettingsView: View {
    @Environment(NavigationRouter<AppRoute>.self) var router
    @Environment(NavigationTabRouter<AppRoute>.self) var tabRouter

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                Button("Switch to Home") {
                    tabRouter.updateSelectedTab(.homeTab)
                }
                .buttonStyle(OGButtonStyle())

                Text("The following button will present a profile view as navigation")
                    .font(.subheadline)
                Button("Present Profile: Navigation") {
                    tabRouter.present(.profile, option: .navigation(inSheet: false))
                }
                .buttonStyle(OGButtonStyle())

                Button("Present Profile: Sheet") {
                    tabRouter.present(.profile, option: .sheet)
                }
                .buttonStyle(OGButtonStyle())
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Settings")
        .padding(.bottom, 88)
    }
}

#Preview {
    ContentView()
}
