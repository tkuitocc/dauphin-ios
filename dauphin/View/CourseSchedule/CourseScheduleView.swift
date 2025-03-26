//
//  CourseScheduleView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/14/24.
//

import SwiftUI
import Foundation

struct CourseScheduleView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject var viewModel = CourseViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                if horizontalSizeClass == .compact {
                    CourseScheduleByDayView(courseViewModel: viewModel, authViewModel: authViewModel)
                        .refreshable {
                            if !authViewModel.ssoStuNo.isEmpty {
                                Task {
                                    await viewModel.fetchCourses(with: authViewModel.ssoStuNo)
                                }
                            }
                        }
                        .onAppear {
                            if !authViewModel.ssoStuNo.isEmpty {
                                Task {
                                    await viewModel.fetchCourses(with: authViewModel.ssoStuNo)
                                }
                            }
                        }
                } else {
                    CourseScheduleByWeekView(courseViewModel: viewModel)
                        .padding(20)
                        .refreshable {
                            if !authViewModel.ssoStuNo.isEmpty {
                                Task {
                                    await viewModel.fetchCourses(with: authViewModel.ssoStuNo)
                                }
                            }
                        }
                        .onAppear {
                            if !authViewModel.ssoStuNo.isEmpty {
                                Task {
                                    await viewModel.fetchCourses(with: authViewModel.ssoStuNo)
                                }
                            }
                        }
                }

            } else {
                AnyView(LibSSOLoginView(viewModel: authViewModel))
            }
        }
    }
}

#Preview {
    CourseScheduleView(authViewModel: AuthViewModel())
}
