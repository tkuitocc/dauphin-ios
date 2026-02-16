import Foundation
import SwiftUI

struct CourseScheduleView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject private var courseViewModel: CourseViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        _courseViewModel = ObservedObject(wrappedValue: authViewModel.courseViewModel)
    }

    var body: some View {
        ZStack {
            if authViewModel.isLoggedIn {
                scheduleContent.refreshable {
                    guard !authViewModel.ssoStuNo.isEmpty else { return }
                    await courseViewModel.fetchCourses(
                        with: authViewModel.ssoStuNo, forceRefresh: true)
                }.task {
                    guard !authViewModel.ssoStuNo.isEmpty else { return }
                    await courseViewModel.fetchCourses(with: authViewModel.ssoStuNo)
                }
            } else {
                LibSSOLoginView(viewModel: authViewModel)
            }
        }
    }

    @ViewBuilder private var scheduleContent: some View {
        if horizontalSizeClass == .compact {
            DayScheduleView(courseViewModel: courseViewModel, authViewModel: authViewModel)
        } else {
            WeekScheduleView(courseViewModel: courseViewModel).padding(.horizontal, 15)
        }
    }
}

#Preview { CourseScheduleView(authViewModel: AuthViewModel()) }
