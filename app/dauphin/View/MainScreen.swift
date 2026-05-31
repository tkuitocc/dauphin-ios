import SwiftUI

struct MainScreen: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        if #available(iOS 18.0, *) {
            TabView {
                Tab("Course", systemImage: "calendar.day.timeline.left") {
                    CourseScheduleView(authViewModel: viewModel)
                }

                Tab("Other", systemImage: "chart.line.text.clipboard") {
                    OtherView(authViewModel: viewModel)
                }

                Tab("Setting", systemImage: "gear") {
                    SettingView(viewModel: viewModel)
                }
            }
        } else {
            TabView {
                CourseScheduleView(authViewModel: viewModel)
                    .tabItem {
                        Label("Course", systemImage: "calendar.day.timeline.left")
                    }

                OtherView(authViewModel: viewModel)
                    .tabItem {
                        Label("Other", systemImage: "chart.line.text.clipboard")
                    }

                SettingView(viewModel: viewModel)
                    .tabItem {
                        Label("Setting", systemImage: "gear")
                    }
            }
        }
    }
}

#Preview {
    MainScreen()
}
