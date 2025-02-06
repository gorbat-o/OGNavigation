import SwiftUI
import OGNavigation

struct DataView: View {
    @Environment(NavigationRouter<AppRoute>.self) var router
    @Environment(NavigationTabRouter<AppRoute>.self) var tabRouter

    @State private var items: [Int] = Array(0...20)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text("\(item)")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            router.present(.dataDetail(id: item), option: .navigation(inSheet: false))
                        }
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Items")
        .padding(.bottom, 88)
    }
}

#Preview {
    ContentView()
}
