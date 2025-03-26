//
//  CourseScheduleByWeekView.swift
//  dauphin
//
//  Created by \u8b19 on 11/19/24.
//


import SwiftUI

struct CourseScheduleByWeekView: View {
    @ObservedObject var courseViewModel: CourseViewModel

    var isSaturday: Int {
        courseViewModel.weekCourses.filter { $0.weekday == 6 }.count
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) { // Reduced spacing between time and timeline
                // Timeline
                VStack {
                    if isSaturday > 0 {
                        let days = ["Mo", "Tu", "We", "Th", "Fr", "Sa"]
                        let dayWidth = (geometry.size.width - 45) / CGFloat(days.count) - 10 // Adjust for time label width
                        let filteredCourses = (1...6).map { day in
                            courseViewModel.weekCourses.filter { $0.weekday == day }
                        }

                        WeekdaysView(
                            days: days,
                            width: dayWidth,
                            currentDay: Calendar.current.component(.weekday, from: Date()) // Pass current weekday
                        )
                            .padding(.horizontal)
                            .frame(height: 20)

                        ScrollView {
                            HStack(spacing: 1) {
                                // Time Labels
                                VStack(spacing: 0) {
                                    ForEach(8...22, id: \.self) { hour in
                                        Text("\(hour):00")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .frame(height: 99)
                                            .offset(y: -40)
                                    }
                                }
                                .frame(width: 45) // Reduced width for tighter layout
                                .background(Color(UIColor.systemBackground))

                                ForEach(filteredCourses.indices, id: \.self) { index in
                                    SingleTimeline(courses: .constant(filteredCourses[index]))
                                        .frame(width: dayWidth)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        let days = ["Mo", "Tu", "We", "Th", "Fr"]
                        let dayWidth = (geometry.size.width - 45) / CGFloat(days.count) - 10 // Adjust for time label width
                        let filteredCourses = (1...5).map { day in
                            courseViewModel.weekCourses.filter { $0.weekday == day }
                        }

                        WeekdaysView(
                            days: days,
                            width: dayWidth,
                            currentDay: Calendar.current.component(.weekday, from: Date()) // Pass current weekday
                        )
                            .padding(.horizontal)
                            .frame(height: 20)

                        ScrollView {
                            HStack(spacing: 1) {
                                // Time Labels
                                VStack(spacing: 0) {
                                    ForEach(8...22, id: \.self) { hour in
                                        Text("\(hour):00")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .frame(height: 99)
                                            .offset(y: -40)
                                    }
                                }
                                .frame(width: 45) // Reduced width for tighter layout
                                .background(Color(UIColor.systemBackground))

                                ForEach(filteredCourses.indices, id: \.self) { index in
                                    SingleTimeline(courses: .constant(filteredCourses[index]))
                                        .frame(width: dayWidth)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.top, 0)
        }
    }
}

struct WeekdaysView: View {
    let days: [String]
    let width: CGFloat
    let currentDay: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<days.count, id: \.self) { index in
                let dayIndex = index + 1
                let date = dateForDay(weekday: dayIndex)

                HStack(alignment: .bottom) {
                    Text(days[index])
                        .font(.title3)
                        .foregroundColor(.gray)

                    ZStack {
                        if dayIndex == currentDay-1 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 28, height: 28)
                        }

                        Text("\(date)")
                            .font(.title3)
                            .foregroundColor(dayIndex == currentDay-1 ? .white : .gray)
                    }
                }
                .frame(width: width, alignment: .center)
            }
        }
    }

    // Helper to get the date for a specific weekday
    private func dateForDay(weekday: Int) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let targetDay = calendar.date(byAdding: .day, value: weekday, to: weekStart)!
        return calendar.component(.day, from: targetDay)
    }

}
#Preview{
    let courseViewModel = CourseViewModel(mockData: mockData)
    CourseScheduleByWeekView(courseViewModel: courseViewModel)
}
