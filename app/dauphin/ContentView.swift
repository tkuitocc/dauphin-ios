//
//  ContentView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/14/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @AppStorage("isFirstTime") private var isFirstTime: Bool = true

    var body: some View {
        switch horizontalSizeClass {
        case .compact:
            MainScreen()
                .fullScreenCover(isPresented: $isFirstTime) {
                    IntroScreen()
                        .preferredColorScheme(colorScheme)
                        .interactiveDismissDisabled()
                }
        default:
            MainScreen()
                .sheet(isPresented: $isFirstTime) {
                    IntroScreen()
                        .preferredColorScheme(colorScheme)
                        .interactiveDismissDisabled()
                }
        }
    }
}

#Preview {
    ContentView()
}
