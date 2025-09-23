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
            CourseScheduleByDayView(courseViewModel: viewModel, authViewModel: authViewModel)
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
            CourseScheduleByWeekView(courseViewModel: viewModel)
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
      if let message = viewModel.cacheUpdateMessage {
        VStack {
          HStack {
            if viewModel.isUpdatingCache {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.8)
                .padding(.trailing, 4)
            } else {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .padding(.trailing, 4)
            }
            Text(message)
              .font(.footnote)
              .fontWeight(.medium)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(
            Capsule()
              .fill(.regularMaterial)
              .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
          )
          .padding(.top, 50)
          Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: message)
        .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
  }
}

#Preview {
  CourseScheduleView(authViewModel: AuthViewModel())
}
