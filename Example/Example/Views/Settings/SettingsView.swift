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
                Button("Trigger") {
                    tabRouter.present(.profile, option: .navigation(inSheet: false))
                }
                .buttonStyle(OGButtonStyle())

                Text("The following button will present a profile view as a sheet")
                    .font(.subheadline)
                Button("Trigger") {
                    tabRouter.present(.profile, option: .sheet)
                }
                .buttonStyle(OGButtonStyle())

                Text("The following button will present a profile view as popover")
                    .font(.subheadline)
                Button("Trigger") {
                    tabRouter.present(.profile, option: .popover)
                }
                .buttonStyle(OGButtonStyle())

                Text("The following button will present a profile view as fullscreenCover")
                    .font(.subheadline)
                Button("Trigger") {
                    tabRouter.present(.profile, option: .fullscreenCover)
                }
                .buttonStyle(OGButtonStyle())

                Text("The following button will present a profile view as a sheet and present a dataDetails view when dismissed")
                    .font(.subheadline)
                Button("Trigger") {
                    tabRouter.present(.profile, option: .sheet, onDismiss: {
                        tabRouter.present(.settingsTab, option: .sheet, onDismiss: {
                            tabRouter.present(.profile, option: .sheet)
                        })
                    })
                }
                .buttonStyle(OGButtonStyle())

                Text("The following button will present a profile view as a popover and present a dataDetails view when dismissed")
                    .font(.subheadline)
                Text("🚨Currently, this doesn't work.🚨")
                    .font(.subheadline)
                Button("Trigger") {
                    tabRouter.present(.profile, option: .popover, onDismiss: {
                        tabRouter.present(.dataDetail(id: 0), option: .popover, onDismiss: {
                            tabRouter.present(.profile, option: .popover)
                        })
                    })
                }
                .buttonStyle(OGButtonStyle())

                Text("The following button will present a profile view as a fullscreenCover and present a dataDetails view when dismissed")
                    .font(.subheadline)
                Button("Trigger") {
                    tabRouter.present(.profile, option: .fullscreenCover, onDismiss: {
                        tabRouter.present(.dataDetail(id: 0), option: .fullscreenCover)
                    })
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
