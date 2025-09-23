//
//  CourseScheduleByWeekView.swift
//  dauphin
//
//  Created by \u8b19 on 11/19/24.
//

import SwiftUI

struct CourseScheduleByWeekView: View {
  @ObservedObject var courseViewModel: CourseViewModel
  @State private var selectedCourse: Course?

  // Cache computed values
  private var hasSaturdayCourses: Bool {
    courseViewModel.weekCourses.contains { $0.weekday == 6 }
  }

  private var dayCount: Int {
    hasSaturdayCourses ? 6 : 5
  }

  private var days: [String] {
    hasSaturdayCourses
      ? ["Mo", "Tu", "We", "Th", "Fr", "Sa"]
      : ["Mo", "Tu", "We", "Th", "Fr"]
  }

  var body: some View {
    GeometryReader { geometry in
      VStack {
        let dayWidth = (geometry.size.width - 45 - 8) / CGFloat(days.count)
        // Pre-group courses by weekday for O(n) performance
        let coursesByDay = Dictionary(grouping: courseViewModel.weekCourses) { $0.weekday }
        let filteredCourses = (1...dayCount).map { day in
          coursesByDay[day] ?? []
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

            ForEach(Array(filteredCourses.enumerated()), id: \.offset) { _, courses in
              SingleTimeline(
                courses: .constant(courses),
                onCourseTap: { course in
                  handleCourseTap(course)
                }
              )
            }
          }
        }
      }
    }
    .sheet(item: $selectedCourse) { course in
      CourseDetailView(course: course)
    }
  }

  // Separate function to handle tap with minimal state updates
  private func handleCourseTap(_ course: Course) {
    selectedCourse = course
  }
}

#Preview {
  let courseViewModel = CourseViewModel(mockData: mockData)
  CourseScheduleByWeekView(courseViewModel: courseViewModel)
}
