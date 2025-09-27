//
//  PulsingAnimation.swift
//  dauphin
//
//  Custom ViewModifier for continuous pulsing animation
//

import SwiftUI

struct PulsingAnimation: ViewModifier {
    @State private var isAnimating = false
    let finalScale: CGFloat
    var initialScale: CGFloat = 1.0
    var finalOpacity: Double = 1.0
    var initialOpacity: Double = 0.6
    let duration: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? finalScale : initialScale)
            .opacity(isAnimating ? finalOpacity : initialOpacity)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}