import SwiftUI

enum MainScreenTabKey {
    case course
    case other
    case settings
}

struct MainScreen: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: MainScreenTabKey = .course
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Course", systemImage: "calendar.day.timeline.left", value: .course) {
                    CourseScheduleView(authViewModel: viewModel)
                }

                Tab("Other", systemImage: "chart.line.text.clipboard", value: .other) {
                    OtherView(authViewModel: viewModel)
                }

                Tab("Setting", systemImage: "gear", value: .settings) {
                    SettingView(viewModel: viewModel)
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                CourseScheduleView(authViewModel: viewModel)
                    .tabItem {
                        Label("Course", systemImage: "calendar.day.timeline.left")
                    }
                    .tag(MainScreenTabKey.course)

                OtherView(authViewModel: viewModel)
                    .tabItem {
                        Label("Other", systemImage: "chart.line.text.clipboard")
                    }
                    .tag(MainScreenTabKey.other)

                SettingView(viewModel: viewModel)
                    .tabItem {
                        Label("Setting", systemImage: "gear")
                    }
                    .tag(MainScreenTabKey.settings)
            }
        }
    }
}

#Preview {
    MainScreen()
}
