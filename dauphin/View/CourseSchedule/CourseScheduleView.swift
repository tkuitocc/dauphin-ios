import Foundation
import SwiftUI

struct CourseScheduleView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @ObservedObject var authViewModel: AuthViewModel
  @StateObject private var viewModel = CourseViewModel()

  var body: some View {
    ZStack {
      if authViewModel.isLoggedIn {
        scheduleContent
          .refreshable {
            guard !authViewModel.ssoStuNo.isEmpty else { return }
            await viewModel.fetchCourses(with: authViewModel.ssoStuNo, forceRefresh: true)
          }
          .task {
            guard !authViewModel.ssoStuNo.isEmpty else { return }
            await viewModel.fetchCourses(with: authViewModel.ssoStuNo)
          }
      } else {
        LibSSOLoginView(viewModel: authViewModel)
      }
    }
  }

  @ViewBuilder
  private var scheduleContent: some View {
    if horizontalSizeClass == .compact {
      DayScheduleView(courseViewModel: viewModel, authViewModel: authViewModel)
    } else {
      WeekScheduleView(courseViewModel: viewModel)
        .padding(.horizontal, 15)
    }
  }
}

#Preview {
  CourseScheduleView(authViewModel: AuthViewModel())
}
