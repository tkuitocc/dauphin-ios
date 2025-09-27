//
//  WeekdaysView.swift
//  dauphin
//
//  Extracted and redesigned weekday selector component
//

import SwiftUI

struct WeekdaysView: View {
  let days: [String]
  let width: CGFloat
  let currentDay: Int

  var body: some View {
    HStack(spacing: 0) {
      ForEach(0 ..< days.count, id: \.self) { index in
        let dayIndex = index + 1
        let date = dateForDay(weekday: dayIndex)
        let isToday = dayIndex == currentDay - 1
        let isWeekend = index >= 5

        HStack(spacing: 3) {
          Text(days[index])
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(
              isToday
                ? Color.blue
                : isWeekend ? Color(UIColor.systemRed).opacity(0.6) : Color(UIColor.tertiaryLabel)
            )

          Text("\(date)")
            .font(.system(size: 13, weight: isToday ? .semibold : .regular))
            .foregroundColor(
              isToday ? Color.blue : Color(UIColor.label).opacity(0.7)
            )
        }
        .frame(height: 20)
        .frame(width: width, height: 20)
      }
    }.background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(UIColor.gray).opacity(0.2))
    )
  }

  private func dateForDay(weekday: Int) -> Int {
    let calendar = Calendar.current
    let today = Date()
    let weekStart = calendar.date(
      from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
    let targetDay = calendar.date(byAdding: .day, value: weekday, to: weekStart)!
    return calendar.component(.day, from: targetDay)
  }
}

#Preview {
  VStack(spacing: 20) {
    WeekdaysView(
      days: ["Mo", "Tu", "We", "Th", "Fr"],
      width: 60,
      currentDay: 3
    )

    WeekdaysView(
      days: ["Mo", "Tu", "We", "Th", "Fr", "Sa"],
      width: 55,
      currentDay: 6
    )
  }
  .padding()
  .background(Color(UIColor.systemBackground))
}
