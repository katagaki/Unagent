//
//  GradientBackground.swift
//  Unagent
//

import SwiftUI

struct GradientBackground: ViewModifier {
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
                .ignoresSafeArea()
            )
    }
}

extension View {
    func gradientBackground() -> some View {
        modifier(GradientBackground())
    }
}
