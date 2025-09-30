import SwiftUI

struct DayScheduleView: View {
  @ObservedObject var courseViewModel: CourseViewModel
  @ObservedObject var authViewModel: AuthViewModel
  @State private var selectedDateIndex: Int = 0
  @State private var showBarcode = false
  @State private var selectedCourse: Course? = nil

  private func getFormattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM, yyyy" // Month and year format
    return formatter.string(from: Date())
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header Section
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 0) {
          Text("Hey, \(authViewModel.ssoStuNo)")
            .font(.title)
            .fontWeight(.bold)

          Spacer()

          Button(action: {
            showBarcode = true
          }) {
            HStack(spacing: 4) {
              Image(systemName: "books.vertical.fill")
                .font(.system(size: 10))
                .foregroundColor(.accentColor)
              Text("Library")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.accentColor)
            }
          }
          .buttonStyle(.borderless)
          .controlSize(.small)
          .sheet(isPresented: $showBarcode) {
            LibraryView(authViewModel: authViewModel)
              .presentationDragIndicator(.visible)
              .padding()
          }
        }
        .padding(.horizontal)

        Text(getFormattedDate())
          .font(.subheadline)
          .foregroundColor(.secondary)
          .padding(.horizontal)

        // Date Selector
        DateSelectorView(selectedIndex: $selectedDateIndex)
      }

      // Courses List
      ScrollView {
        let todaysCourses = courseViewModel.weekCourses.filter {
          $0.weekday == (selectedDateIndex + 1)
        }.sorted { $0.startTime < $1.startTime }

        if todaysCourses.isEmpty {
          // Empty state
          VStack(spacing: 16) {
            Spacer(minLength: 100)

            Image(systemName: "calendar.badge.exclamationmark")
              .font(.system(size: 60))
              .foregroundColor(.secondary)

            Text("No courses for Today")
              .font(.headline)
              .foregroundColor(.primary)

            Text("Enjoy your free day!")
              .font(.subheadline)
              .foregroundColor(.secondary)

            Spacer()
          }
          .frame(maxWidth: .infinity)
          .padding()
        } else {
          LazyVStack(spacing: 12) {
            ForEach(Array(todaysCourses.enumerated()), id: \.element.id) { index, course in
              CourseCardView(
                courseName: course.name,
                roomNumber: course.room,
                teacherName: course.teacher,
                StartTime: course.startTime,
                EndTime: course.endTime,
                stdNo: course.stdNo,
                weekday: course.weekday
              )
              .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
              .scaleEffect(1.0)
              .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
              .onTapGesture {
                selectedCourse = course
              }
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 12)
        }
      }
      .gesture(
        DragGesture()
          .onEnded { value in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              if value.translation.width < -50 {
                // Swipe left - next day
                selectedDateIndex = min(selectedDateIndex + 1, 7)
              } else if value.translation.width > 50 {
                // Swipe right - previous day
                selectedDateIndex = max(selectedDateIndex - 1, 0)
              }
            }
          }
      )
      .scrollIndicators(.hidden)
    }
    .background(Color(UIColor.systemGroupedBackground))
    .sheet(item: $selectedCourse) { course in
      CourseDetailView(course: course)
        .presentationDragIndicator(.visible)
        .presentationDetents([.fraction(0.75), .large])
    }
  }
}

#Preview {
  DayScheduleView(
    courseViewModel: CourseViewModel(mockData: mockData), authViewModel: AuthViewModel()
  )
}
