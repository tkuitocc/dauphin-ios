//
//  SingleTimelineView.swift
//  dauphin
//
//  Created by \u8b19 on 12/13/24.
//

import SwiftUI

struct SingleTimeline: View {
    @Binding var courses: [Course]

        let start = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Calendar.current.startOfDay(for: Date()))!
        let end = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Calendar.current.startOfDay(for: Date()))!

        var body: some View {
            GeometryReader { geometry in
                let totalHeight = CGFloat(1400)
                let numberOfSlots = 14
                // let currentTime = Date()
                // let currentYOffset = yPosition(for: currentTime, in: totalHeight) // Calculate Y position of current time

                ZStack(alignment: .top) {
                    // Grid
                    TimeSlotGrid(numberOfSlots: numberOfSlots, totalHeight: totalHeight)

                    // Courses
                    ForEach(courses) { course in
                        let adjustedStartTime = adjustedTime(for: course.startTime)
                        let adjustedEndTime = adjustedTime(for: course.endTime)

                        CourseView(
                            course: course,
                            height: heightForEvent(adjustedStartTime, adjustedEndTime, in: totalHeight),
                            yOffset: yPosition(for: adjustedStartTime, in: totalHeight)
                        )
                    }
                }
            }
        }

    // 調整時間到整點
    private func adjustedTime(for time: Date) -> Date {
        let baseDate = Calendar.current.startOfDay(for: Date())
        let calendar = Calendar.current
        return calendar.date(bySettingHour: calendar.component(.hour, from: time), minute: 0, second: 0, of: baseDate)!
    }

    // 計算課程的高度
    private func heightForEvent(_ startTime: Date, _ endTime: Date, in totalHeight: CGFloat) -> CGFloat {
        let totalDuration = end.timeIntervalSince(start)
        let eventDuration = endTime.timeIntervalSince(startTime)
        return CGFloat(eventDuration / totalDuration) * totalHeight
    }

    // 計算課程的垂直位置
    private func yPosition(for time: Date, in totalHeight: CGFloat) -> CGFloat {
        let totalDuration = end.timeIntervalSince(start)
        let eventOffset = time.timeIntervalSince(start)
        let relativePosition = eventOffset / totalDuration
        return CGFloat(relativePosition) * totalHeight
    }
}

struct TimeSlotGrid: View {
    let numberOfSlots: Int
    let totalHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<numberOfSlots, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    .frame(height: totalHeight / CGFloat(numberOfSlots))

            }
        }
    }
}

struct CourseView: View {
    let course: Course
    let height: CGFloat
    let yOffset: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.indigo)
            .frame(height: height*0.98)
            .overlay(
                VStack(alignment: .leading, spacing:0) {
                    HStack {
                        Text(course.name)
                            .font(.caption)
                            .bold()
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 10))
                        Text(": \(course.room)")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 2) {
                        Image(systemName: "graduationcap")
                            .font(.system(size: 10))
                        Text(": \(course.stdNo)")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(4),
                alignment: .topLeading
            )
            .offset(y: yOffset)
    }
}

#Preview{
    let courseViewModel = CourseViewModel(mockData: mockData)
    ScrollView {
        SingleTimeline(courses: Binding(
            get: { courseViewModel.weekCourses.filter { $0.weekday == 1 } },
            set: { newValue in
                // Update courseViewModel.weekCourses with the changes from newValue
                // This may require additional logic to ensure filtered courses are updated correctly
            }
        ))
    }
}
