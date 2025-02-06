import SwiftUI

struct OGButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(red: 0, green: 0, blue: 0.2))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
