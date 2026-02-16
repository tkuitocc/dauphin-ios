//
//  ContentView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/14/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isFirstTime") private var isFirstTime: Bool = true

    var body: some View {
        if #available(iOS 18.0, *) {
            TabView {
                Tab("Course", systemImage: "calendar.day.timeline.left") {
                    CourseScheduleView(authViewModel: viewModel)
                }
                Tab("Other", systemImage: "chart.line.text.clipboard") {
                    OtherView(authViewModel: viewModel)
                }

                Tab("Setting", systemImage: "gear") { SettingView(viewModel: viewModel) }
            }.sheet(
                isPresented: $isFirstTime, content: { IntroScreen().interactiveDismissDisabled() })

        } else {
            TabView {
                CourseScheduleView(authViewModel: viewModel).tabItem {
                    Label("Course", systemImage: "calendar.day.timeline.left")
                }
                OtherView(authViewModel: viewModel).tabItem {
                    Label("Other", systemImage: "chart.line.text.clipboard")
                }
                SettingView(viewModel: viewModel).tabItem { Label("Setting", systemImage: "gear") }
            }.sheet(
                isPresented: $isFirstTime, content: { IntroScreen().interactiveDismissDisabled() })
        }
    }
}

#Preview { ContentView() }
