//
//  LaunchScreenView.swift
//  dauphin
//
//  Created by \u8b19 on 1/30/25.
//

import Lottie
import SwiftUI

struct LaunchScreenView: View {
    let errorMessage: String?
    let onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            if let errorMessage {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 48))
                    .foregroundColor(.orange)

                Text("Failed to load keys").font(.headline)

                Text(errorMessage).font(.callout).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button("Retry") { onRetry?() }.buttonStyle(.borderedProminent)
            } else {
                LottieView(animationFileName: "loading", loopMode: .loop).frame(
                    width: 200, height: 250)
                Text("Loading...").font(.callout)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(24).background(Color.white)
    }
}

struct LottieView: UIViewRepresentable {
    var animationFileName: String
    let loopMode: LottieLoopMode

    func updateUIView(_: UIViewType, context _: Context) {}

    func makeUIView(context _: Context) -> Lottie.LottieAnimationView {
        let animationView = LottieAnimationView(name: animationFileName)
        animationView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        animationView.loopMode = loopMode
        animationView.play()
        // animationView.contentMode = .center
        return animationView
    }
}

#Preview { LaunchScreenView(errorMessage: nil, onRetry: nil) }
