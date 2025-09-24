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
  @State private var selectedCourse: Course? = nil
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
    VStack(spacing: 0) {
      // Header Section
      VStack(alignment: .leading, spacing: 8) {
        Text("Hey, \(authViewModel.ssoStuNo).")
          .font(.largeTitle)
          .fontWeight(.bold)
          .padding(.horizontal)
          .onTapGesture {
            showSheet = true
          }

        Text(getFormattedDate())
          .font(.subheadline)
          .foregroundColor(.secondary)
          .padding(.horizontal)

        // Date Selector
        ScrollViewReader { proxy in
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              ForEach(dates.indices, id: \.self) { index in
                let date = dates[index]
                let isSelected = selectedDateIndex == index
                let isToday = date.day == Calendar.current.component(.day, from: Date())

                VStack(spacing: 6) {
                  Text("\(date.day)")
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))

                  Text(date.weekday)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }
                .frame(width: 65, height: 85)
                .background(
                  ZStack {
                    if isSelected {
                      RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                      RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .overlay(
                          RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isToday ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
                        )
                    }
                  }
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                .id(index)
                .onTapGesture {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedDateIndex = index
                  }
                }
              }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
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
      .background(Color(UIColor.systemGroupedBackground))

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

            Text("No courses for \(dates[selectedDateIndex].weekday)")
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
                stdNo: course.stdNo
              )
              .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
              .scaleEffect(1.0)
              .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
              .onTapGesture {
                selectedCourse = course
              }
            }
            .padding(.horizontal)
            .padding(.top, 12)
          }
        }
      }
      .background(Color(UIColor.systemBackground))
      .gesture(
        DragGesture()
          .onEnded { value in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              if value.translation.width < -50 {
                // Swipe left - next day
                selectedDateIndex = min(selectedDateIndex + 1, dates.count - 1)
              } else if value.translation.width > 50 {
                // Swipe right - previous day
                selectedDateIndex = max(selectedDateIndex - 1, 0)
              }
            }
          }
      )
      .scrollIndicators(.hidden)
    }
    .background(Color(UIColor.systemBackground))
    .sheet(item: $selectedCourse) { course in
      CourseDetailView(course: course)
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
  }
}

#Preview {
  CourseScheduleByDayView(courseViewModel: CourseViewModel(mockData: mockData), authViewModel: AuthViewModel())
}
