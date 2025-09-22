//
//  CourseScheduleByWeekView.swift
//  dauphin
//
//  Created by \u8b19 on 11/19/24.
//

import SwiftUI

struct CourseScheduleByWeekView: View {
  @ObservedObject var courseViewModel: CourseViewModel
  @State private var selectedCourse: Course? = nil
  @State private var showingCourseDetail = false

  var isSaturday: Int {
    courseViewModel.weekCourses.filter { $0.weekday == 6 }.count
  }

  var body: some View {
    GeometryReader { geometry in
      VStack {
        let days =
          isSaturday > 0
          ? ["Mo", "Tu", "We", "Th", "Fr", "Sa"] : ["Mo", "Tu", "We", "Th", "Fr"]
        let dayWidth = (geometry.size.width - 45 - 8) / CGFloat(days.count)
        let filteredCourses = (1...(isSaturday > 0 ? 6 : 5)).map { day in
          courseViewModel.weekCourses.filter { $0.weekday == day }
        }

        HStack(spacing: 0) {
          Spacer()
            .frame(width: 45)  // Match time label width

          WeekdaysView(
            days: days,
            width: dayWidth,
            currentDay: Calendar.current.component(.weekday, from: Date())
          )
        }

        ScrollView {
          HStack(spacing: 0) {
            // Time Labels
            VStack(spacing: 0) {
              ForEach(8...22, id: \.self) { hour in
                Text("\(hour):00")
                  .font(.caption)
                  .foregroundColor(Color(UIColor.secondaryLabel))
                  .frame(height: 99)
                  .offset(y: -40)
              }
            }
            .frame(width: 45)  // Reduced width for tighter layout
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.systemBackground).opacity(0.8))
            )

            ForEach(filteredCourses.indices, id: \.self) { index in
              SingleTimeline(
                courses: .constant(filteredCourses[index]),
                onCourseTap: { course in
                  selectedCourse = course
                  showingCourseDetail = true
                }
              )
            }
          }
        }
      }
    }
    .sheet(isPresented: $showingCourseDetail) {
      if let course = selectedCourse {
        CourseDetailView(course: course)
      }
    }
  }
}

#Preview {
  let courseViewModel = CourseViewModel(mockData: mockData)
  CourseScheduleByWeekView(courseViewModel: courseViewModel)
}
