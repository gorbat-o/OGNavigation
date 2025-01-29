import SwiftUI
import OGNavigation

struct DataDetailView: View {
    @Environment(NavigationTabRouter<AppRoute>.self) var tabRouter
    @Environment(NavigationRouter<AppRoute>.self) var router
    let id: Int

    var body: some View {
        VStack(spacing: 20) {
            Text("Data Detail View \(id)")
                .font(.largeTitle)

            Button("Present Settings as Popover") {
                tabRouter.present(.accountTab, option: .sheet)
            }
            Button("Dismiss") {
                router.dismiss()
            }
        }
        .padding()
    }
}

