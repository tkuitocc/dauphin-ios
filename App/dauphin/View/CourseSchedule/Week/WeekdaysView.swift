import SwiftUI

struct WeekdaysView: View {
    let days: [String]
    let weekdays: [Int]
    let width: CGFloat
    let currentWeekday: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days.indices, id: \.self) { index in weekdayCell(index: index) }
        }
    }

    private func dateForDay(weekday: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekdayIndex = (calendar.component(.weekday, from: today) + 5) % 7  // Monday = 0
        let monday = calendar.date(byAdding: .day, value: -weekdayIndex, to: today)!
        let targetDay = calendar.date(byAdding: .day, value: weekday - 1, to: monday)!
        return calendar.component(.day, from: targetDay)
    }
}

extension WeekdaysView {
    @ViewBuilder fileprivate func weekdayCell(index: Int) -> some View {
        let label = days[index]
        let weekdayValue = weekdays[index]
        let date = dateForDay(weekday: weekdayValue)
        let isToday = weekdayValue == normalizedToday

        HStack(spacing: 3) {
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(
                isToday ? Color.blue : Color(UIColor.tertiaryLabel))

            Text("\(date)").font(.system(size: 13, weight: isToday ? .semibold : .regular))
                .foregroundColor(isToday ? Color.blue : Color(UIColor.label).opacity(0.7))
        }.frame(height: 20).frame(width: width, height: 20)
    }
}

extension WeekdaysView {
    fileprivate var normalizedToday: Int {
        let sys = Calendar.current.component(.weekday, from: Date())
        return sys == 1 ? 7 : (sys - 1)
    }
}

#Preview {
    VStack(spacing: 20) {
        WeekdaysView(
            days: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"], weekdays: Array(1 ... 7), width: 55,
            currentWeekday: 6)
    }.padding().background(Color(UIColor.systemBackground))
}
