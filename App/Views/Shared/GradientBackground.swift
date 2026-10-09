import SwiftUI

struct GradientBackground: ViewModifier {

    @Environment(\.colorScheme) private var colorScheme

    // Shades the gradient slightly so a sidebar column stands apart from the
    // detail column beside it.
    var isTinted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        Color("BackgroundGradientTop"),
                        Color("BackgroundGradientBottom")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay {
                    if isTinted {
                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.5)
                    }
                }
                .ignoresSafeArea()
            )
    }
}

extension View {
    func gradientBackground(isTinted: Bool = false) -> some View {
        modifier(GradientBackground(isTinted: isTinted))
    }
}
