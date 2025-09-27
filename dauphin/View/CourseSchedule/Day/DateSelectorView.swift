//
//  DateSelectorView.swift
//  dauphin
//
//  Horizontal scrollable date selector component
//

import SwiftUI

struct DateSelectorView: View {
  @Binding var selectedDateIndex: Int
  let dates: [DateItem]

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(dates.indices, id: \.self) { index in
            let date = dates[index]
            let isSelected = selectedDateIndex == index
            let isToday = date.day == Calendar.current.component(.day, from: Date())

            VStack(spacing: 4) {
              Text("\(date.day)")
                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))

              Text(date.weekday)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .padding(
              EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            )
            .background(
              ZStack {
                if isSelected {
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 0)
                } else {
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                      RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                          isToday ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2
                        )
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
      .onAppear {
        if let todayIndex = dates.firstIndex(where: {
          $0.day == Calendar.current.component(.day, from: Date())
        }) {
          selectedDateIndex = todayIndex
          proxy.scrollTo(todayIndex, anchor: .center)
        } else {
          selectedDateIndex = 0 // Default to Monday if today is Sunday or Saturday
        }
      }
    }
  }
}
