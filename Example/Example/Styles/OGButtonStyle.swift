import SwiftUI

struct OGButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color(red: 0, green: 0, blue: 0.2))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
