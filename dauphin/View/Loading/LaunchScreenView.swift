//
//  LaunchScreenView.swift
//  dauphin
//
//  Created by \u8b19 on 1/30/25.
//

import SwiftUI
import Lottie

struct LaunchScreenView: View {
    var body: some View {
        VStack {
            LottieView(animationFileName: "loading", loopMode: .loop)
                .frame(width: 200, height: 250)
            Text("Loading...")
                .font(.callout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct LottieView: UIViewRepresentable {

    var animationFileName: String
    let loopMode: LottieLoopMode

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }

    func makeUIView(context: Context) -> Lottie.LottieAnimationView {
        let animationView = LottieAnimationView(name: animationFileName)
        animationView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        animationView.loopMode = loopMode
        animationView.play()
        // animationView.contentMode = .center
        return animationView
    }
}

#Preview {
    LaunchScreenView()
}

