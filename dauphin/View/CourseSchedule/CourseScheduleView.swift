//
//  CourseScheduleView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/14/24.
//

import Foundation
import SwiftUI

struct CourseScheduleView: View {
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @ObservedObject var authViewModel: AuthViewModel
  @StateObject var viewModel = CourseViewModel()

  var body: some View {
    ZStack {
      Group {
        if authViewModel.isLoggedIn {
          if horizontalSizeClass == .compact {
            DayScheduleView(courseViewModel: viewModel, authViewModel: authViewModel)
              .refreshable {
                if !authViewModel.ssoStuNo.isEmpty {
                  Task {
                    // Manual refresh - force update from network
                    await viewModel.fetchCourses(with: authViewModel.ssoStuNo, forceRefresh: true)
                  }
                }
              }
              .onAppear {
                // Hide the default spinner by setting its tintColor to clear
                UIRefreshControl.appearance().tintColor = .clear
                if !authViewModel.ssoStuNo.isEmpty {
                  Task {
                    // Normal load - will only fetch from network on first launch
                    await viewModel.fetchCourses(with: authViewModel.ssoStuNo)
                  }
                }
              }
          } else {
            WeekScheduleView(courseViewModel: viewModel)
              .padding(
                [.horizontal], 15
              )
              .refreshable {
                if !authViewModel.ssoStuNo.isEmpty {
                  Task {
                    // Manual refresh - force update from network
                    await viewModel.fetchCourses(with: authViewModel.ssoStuNo, forceRefresh: true)
                  }
                }
              }
              .onAppear {
                // Hide the default spinner by setting its tintColor to clear
                UIRefreshControl.appearance().tintColor = .clear
                if !authViewModel.ssoStuNo.isEmpty {
                  Task {
                    // Normal load - will only fetch from network on first launch
                    await viewModel.fetchCourses(with: authViewModel.ssoStuNo)
                  }
                }
              }
          }

        } else {
          AnyView(LibSSOLoginView(viewModel: authViewModel))
        }
      }

      // Floating notification overlay
      CacheUpdateNotificationView(
        message: viewModel.cacheUpdateMessage,
        isUpdating: viewModel.isUpdatingCache
      )
    }
  }
}

#Preview {
  CourseScheduleView(authViewModel: AuthViewModel())
}
