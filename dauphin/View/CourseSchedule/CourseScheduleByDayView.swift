//  CourseScheduleByDayView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/17/24.
//

import SwiftUI

struct DateItem: Identifiable {
  let id = UUID()
  let day: Int
  let weekday: String
  let isSelected: Bool
}

struct CourseScheduleByDayView: View {
  @ObservedObject var courseViewModel: CourseViewModel
  @ObservedObject var authViewModel: AuthViewModel
  @State private var selectedDateIndex: Int = 0
  @State private var dates: [DateItem] = generateDates(includeSaturday: false)
  @State private var showSheet = false
  static func generateDates(includeSaturday: Bool = false) -> [DateItem] {
    let calendar = Calendar.current
    let today = Date()
    let weekdayFormatter = DateFormatter()
    weekdayFormatter.dateFormat = "EEE"

    // Calculate the start of the week (Monday)
    let weekday = calendar.component(.weekday, from: today)
    let daysFromMonday = (weekday == 1 ? 6 : weekday - 2)  // Adjust for Monday start
    guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
      return []
    }

    // Generate dates for Monday to Friday
    var dateItems = (0..<5).map { offset in
      let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
      let day = calendar.component(.day, from: date)
      let weekday = weekdayFormatter.string(from: date)
      return DateItem(day: day, weekday: weekday, isSelected: false)
    }

    // Add Saturday if needed
    if includeSaturday {
      if let saturday = calendar.date(byAdding: .day, value: 5, to: startOfWeek) {
        let day = calendar.component(.day, from: saturday)
        let weekday = weekdayFormatter.string(from: saturday)
        dateItems.append(DateItem(day: day, weekday: weekday, isSelected: false))
      }
    }
    return dateItems
  }

  private func getFormattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM, yyyy"  // Month and year format
    return formatter.string(from: Date())
  }

  var body: some View {
    VStack {
      VStack(alignment: .leading) {
        Text("Hey, \(authViewModel.ssoStuNo).")
          .padding(.top)
          .font(.title)
          .fontWeight(.bold)
          .padding(.horizontal)
          .onTapGesture {
            showSheet = true
          }

        Text(getFormattedDate())
          .foregroundColor(.gray)
          .padding(.horizontal)

        ScrollViewReader { proxy in
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
              ForEach(dates.indices, id: \.self) { index in
                let date = dates[index]
                VStack {
                  Text("\(date.day)")
                    .font(.headline)
                    .foregroundColor(selectedDateIndex == index ? .white : .primary)
                  Text(date.weekday)
                    .font(.subheadline)
                    .foregroundColor(selectedDateIndex == index ? .white : .gray)
                }
                .frame(width: 70, height: 90)
                .background(
                  RoundedRectangle(cornerRadius: 10)
                    .fill(
                      selectedDateIndex == index ? Color.accentColor : Color(UIColor.systemGray5)
                    )
                    .shadow(
                      color: selectedDateIndex == index ? .gray.opacity(0.4) : .clear, radius: 4)
                )
                .id(index)
                .onTapGesture {
                  selectedDateIndex = index
                }
              }
            }
            .padding(5)
          }
          .sheet(isPresented: $showSheet) {
            LibraryView(authViewModel: authViewModel)
              .padding()
          }
          .onAppear {
            let hasSaturdayCourses = courseViewModel.weekCourses.contains { $0.weekday == 6 }  // Assuming 6 = Saturday
            dates = Self.generateDates(includeSaturday: hasSaturdayCourses)

            if let todayIndex = dates.firstIndex(where: {
              $0.day == Calendar.current.component(.day, from: Date())
            }) {
              selectedDateIndex = todayIndex
              proxy.scrollTo(todayIndex, anchor: .center)
            } else {
              selectedDateIndex = 1  // Default to Monday if today is Sunday or Saturday
            }
          }
        }
      }

      ScrollView {
        let todaysCourses = courseViewModel.weekCourses.filter {
          $0.weekday == (selectedDateIndex + 1)
        }  // Map index to weekday
        if todaysCourses.isEmpty {
          // Show nothing while loading from cache, or "No courses" if truly empty
          if !courseViewModel.weekCourses.isEmpty || courseViewModel.isCacheEmpty {
            Text("No courses for \(dates[selectedDateIndex].weekday).")
              .foregroundColor(.gray)
          }
        } else {
          ForEach(todaysCourses) { course in
            CourseCardView(
              courseName: course.name,
              roomNumber: course.room,
              teacherName: course.teacher,
              StartTime: course.startTime,
              EndTime: course.endTime,
              stdNo: course.stdNo
            )
            .padding(2)
          }
        }
      }
      .gesture(
        DragGesture()
          .onEnded { value in
            if value.translation.width < -50 {
              // Swipe left
              selectedDateIndex = (selectedDateIndex + 1) % dates.count
            } else if value.translation.width > 50 {
              // Swipe right
              selectedDateIndex = (selectedDateIndex - 1 + dates.count) % dates.count
            }
          }
      )
      .scrollIndicators(.hidden)
      .presentationBackground(.thinMaterial)
    }
  }
}

#Preview {
  CourseScheduleByDayView(courseViewModel: CourseViewModel(mockData: mockData), authViewModel: AuthViewModel())
}
