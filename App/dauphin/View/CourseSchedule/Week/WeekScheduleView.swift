import SwiftUI

struct WeekScheduleView: View {
  @ObservedObject var courseViewModel: CourseViewModel
  @State private var selectedCourse: Course?

  // Cache computed values
  private var normalizedCurrentWeekday: Int {
    let sys = Calendar.current.component(.weekday, from: Date())
    return sys == 1 ? 7 : (sys - 1)
  }

  private let displayedWeekdays: [Int] = Array(1...7)

  private let dayLabels: [String] = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

  var body: some View {
    GeometryReader { geometry in
      VStack {
        let dayWidth = (geometry.size.width - 45 - 8) / CGFloat(displayedWeekdays.count)
        // Pre-group courses by weekday for O(n) performance
        let coursesByDay = Dictionary(grouping: courseViewModel.weekCourses) { $0.weekday }
        let filteredCourses = displayedWeekdays.map { day in
          coursesByDay[day] ?? []
        }

        HStack(spacing: 0) {
          Spacer()
            .frame(width: 45)  // Match time label width

          WeekdaysView(
            days: dayLabels,
            weekdays: displayedWeekdays,
            width: dayWidth,
            currentWeekday: normalizedCurrentWeekday
          )
        }

        ScrollView {
          HStack(spacing: 0) {
            // Time Labels
            VStack(spacing: 0) {
              ForEach(ScheduleLayout.startHour...ScheduleLayout.endHour, id: \.self) { hour in
                Text("\(hour):00")
                  .font(.caption)
                  .foregroundColor(Color(UIColor.secondaryLabel))
                  .frame(height: ScheduleLayout.slotHeight)
                  .offset(y: -ScheduleLayout.slotHeight * 0.4)
              }
            }
            .frame(width: 45)  // Reduced width for tighter layout
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.systemBackground).opacity(0.8))
            )

            ForEach(Array(filteredCourses.enumerated()), id: \.offset) { _, courses in
              TimelineView(
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
  WeekScheduleView(courseViewModel: courseViewModel)
}
