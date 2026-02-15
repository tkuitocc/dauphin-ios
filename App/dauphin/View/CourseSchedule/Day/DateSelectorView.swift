import SwiftUI

struct DateSelectorView: View {
  @Binding var selectedIndex: Int
  private let calendar = Calendar(identifier: .gregorian)
  private let items: [DateItem]

  init(selectedIndex: Binding<Int>) {
    self._selectedIndex = selectedIndex
    self.items = DateSelectorView.buildCurrentWeek()
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(items.indices, id: \.self) { index in
            let item = items[index]
            let isSelected = selectedIndex == index
            let isToday = calendar.isDateInToday(item.date)

            Button {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedIndex = index
                proxy.scrollTo(index, anchor: .center)
              }
            } label: {
              DateCell(
                dayOfMonth: calendar.component(.day, from: item.date),
                weekdayText: weekdayString(item.date),
                isSelected: isSelected,
                isToday: isToday
              )
            }
            .buttonStyle(.plain)
            .id(index)
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
      }
      .onAppear {
        if let idx = items.firstIndex(where: { calendar.isDateInToday($0.date) }) {
          selectedIndex = idx
          proxy.scrollTo(idx, anchor: .center)
        }
      }
    }
  }

  private func weekdayString(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = calendar
    f.locale = .current
    f.dateFormat = "EEE"  // Mon, Tue, ...
    return f.string(from: date)
  }

  /// Build Monday..Sunday of the current week. `day` is 1..7 for Mon..Sun.
  static func buildCurrentWeek(calendar: Calendar = Calendar(identifier: .gregorian)) -> [DateItem]
  {
    let today = calendar.startOfDay(for: Date())
    // Apple weekday: 1=Sun..7=Sat. We want Monday start.
    let weekday = calendar.component(.weekday, from: today)  // 1..7
    let daysFromMonday = (weekday + 5) % 7  // Mon->0, Sun->6
    let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!

    return (0..<7).map { offset in
      let d = calendar.date(byAdding: .day, value: offset, to: monday)!
      return DateItem(date: d, day: offset + 1)  // 1..7
    }
  }
}

// MARK: - Cell

private struct DateCell: View {
  let dayOfMonth: Int
  let weekdayText: String
  let isSelected: Bool
  let isToday: Bool

  var body: some View {
    VStack(spacing: 4) {
      Text("\(dayOfMonth)")
        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
        .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))

      Text(weekdayText)
        .font(.system(size: 14, weight: isSelected ? .medium : .regular))
        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
        .accessibilityHidden(true)
    }
    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(isSelected ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
              (!isSelected && isToday) ? Color.accentColor.opacity(0.3) : .clear, lineWidth: 2)
        )
        .shadow(
          color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: isSelected ? 4 : 0)
    )
    .scaleEffect(isSelected ? 1.05 : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    .accessibilityElement(children: .combine)
  }
}

#Preview("DateSelectorView") {
  @Previewable @State var selected: Int = 0
  return DateSelectorView(selectedIndex: $selected)
}
