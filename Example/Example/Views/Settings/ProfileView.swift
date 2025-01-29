import SwiftUI
import OGNavigation

struct ProfileView: View {
    @Environment(NavigationRouter<AppRoute>.self) var router
    @Environment(NavigationTabRouter<AppRoute>.self) var tabRouter

    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)

            Button("Dismiss") {
                router.dismiss()
            }
        }
        .padding()
    }
}
